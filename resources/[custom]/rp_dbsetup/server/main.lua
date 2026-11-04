-- ============================================================
--  rp_dbsetup - server side
--  Runs each .sql file listed in config.lua one time, in order.
--  What already ran is remembered in the rp_db_migrations table.
--  If a file fails partway, it is NOT marked done: fix the problem
--  and restart, and it runs again (the files we use are written so
--  a second run is safe).
-- ============================================================
local RESOURCE = GetCurrentResourceName()
local config = load(LoadResourceFile(RESOURCE, 'config.lua'), '@config.lua')()

local function say(text, ...)
    print(('^5[rp_dbsetup]^7 ' .. text):format(...))
end

local function warn(text, ...)
    print(('^1[rp_dbsetup]^7 ' .. text):format(...))
end

-- Statements we skip: session settings (they don't matter here, and oxmysql
-- reads @names as its own placeholders).
local function shouldSkip(statement)
    return statement:upper():match('^SET%s') ~= nil
end

-- Errors that mean "already done" when a file runs a second time.
local function isHarmless(message)
    message = tostring(message)
    return message:find('Duplicate entry', 1, true)
        or message:find('already exists', 1, true)
        or message:find('Duplicate column', 1, true)
        or message:find('Duplicate key name', 1, true)
end

-- ------------------------------------------------------------
-- Running the files
-- ------------------------------------------------------------
local function runFile(file)
    local text = LoadResourceFile(RESOURCE, 'sql/' .. file)
    if not text then
        warn('Missing file sql/%s. Check config.lua.', file)
        return false
    end

    local statements = SplitSql(text)
    local ran, skipped = 0, 0
    say('Setting up %s (%d steps)...', file, #statements)

    for index, statement in ipairs(statements) do
        if shouldSkip(statement) then
            skipped = skipped + 1
        else
            local ok, err = pcall(MySQL.query.await, statement)
            if ok then
                ran = ran + 1
            elseif isHarmless(err) then
                skipped = skipped + 1
            else
                warn('%s stopped at step %d: %s', file, index, tostring(err))
                warn('The step starts with: %s', statement:sub(1, 120):gsub('%s+', ' '))
                return false
            end
        end
    end

    say('%s done: %d steps run, %d skipped.', file, ran, skipped)
    return true
end

local function restart(resource)
    if not resource or GetResourceState(resource) ~= 'started' then return end
    local ok = pcall(function()
        StopResource(resource)
        Wait(1000)
        StartResource(resource)
    end)
    if ok then
        say('Restarted %s so it sees its new tables.', resource)
    else
        warn('Could not restart %s. Restart the server once so it sees its new tables.', resource)
    end
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_db_migrations` (
            `file`       VARCHAR(100) NOT NULL,
            `applied_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`file`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    local done = {}
    for _, row in ipairs(MySQL.query.await('SELECT `file` FROM `rp_db_migrations`') or {}) do
        done[row.file] = true
    end

    for _, migration in ipairs(config.migrations or {}) do
        if not done[migration.file] then
            if runFile(migration.file) then
                MySQL.insert.await('INSERT INTO `rp_db_migrations` (`file`, `applied_at`) VALUES (?, ?)', { migration.file, os.time() })
                TriggerEvent('rp_dbsetup:applied', migration.file)
                restart(migration.restart)
            else
                warn('Fix the problem above, then restart rp_dbsetup to try again.')
                break -- later files may depend on this one
            end
        end
    end
end)

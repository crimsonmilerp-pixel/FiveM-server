-- ============================================================
--  rp_goals - server side
--  Saves goals to the database and decides who can see what.
--  The server is the boss: it double-checks everything the
--  player's game sends, so nobody can cheat the rules.
-- ============================================================
local config = require 'config'

local VALID_CATEGORY = {}
for _, id in ipairs(config.categories) do
    VALID_CATEGORY[id] = true
end

local DAY = 86400 -- seconds in a day

-- ------------------------------------------------------------
-- Database tables (created automatically the first time)
-- ------------------------------------------------------------
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_character_goals` (
            `citizenid`     VARCHAR(50)  NOT NULL,
            `category`      VARCHAR(20)  NOT NULL,
            `goal`          VARCHAR(255) NOT NULL,
            `reason`        VARCHAR(400) NOT NULL,
            `first_step`    VARCHAR(255) NOT NULL,
            `created_at`    INT UNSIGNED NOT NULL,
            `changed_at`    INT UNSIGNED NOT NULL,
            `times_changed` INT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Old goals are kept here when a character changes theirs (useful for staff and stories).
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_character_goal_history` (
            `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `citizenid`   VARCHAR(50)  NOT NULL,
            `category`    VARCHAR(20)  NOT NULL,
            `goal`        VARCHAR(255) NOT NULL,
            `reason`      VARCHAR(400) NOT NULL,
            `first_step`  VARCHAR(255) NOT NULL,
            `set_at`      INT UNSIGNED NOT NULL,
            `replaced_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end)

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

---Removes spaces from the start and end of some text.
local function trim(text)
    if type(text) ~= 'string' then return '' end
    return (text:match('^%s*(.-)%s*$'))
end

---Counts characters (not bytes), so emojis and accents count as one.
local function textLength(text)
    return utf8.len(text) or #text
end

---Returns the citizen ID and full name of the character a player is using.
local function getCharacter(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local data = player.PlayerData
    return data.citizenid, ('%s %s'):format(data.charinfo.firstname, data.charinfo.lastname)
end

local function fetchGoal(citizenid)
    return MySQL.single.await('SELECT * FROM `rp_character_goals` WHERE `citizenid` = ?', { citizenid })
end

local function secondsUntilChangeAllowed(row)
    local readyAt = row.changed_at + config.changeCooldownDays * DAY
    return math.max(0, readyAt - os.time())
end

---Turns a database row into what the player's game needs.
local function toClient(row)
    local wait = secondsUntilChangeAllowed(row)
    return {
        category = row.category,
        goal = row.goal,
        reason = row.reason,
        firstStep = row.first_step,
        setOn = os.date('%b %d, %Y', row.changed_at),
        timesChanged = row.times_changed,
        canChange = wait == 0,
        daysLeft = math.ceil(wait / DAY),
    }
end

---Checks one answer's length. Returns an error name and the minimum, or nothing if fine.
local function checkLength(text, limits, shortError)
    local length = textLength(text)
    if length < limits.min then return shortError, limits.min end
    if length > limits.max then return 'too_long' end
end

-- ------------------------------------------------------------
-- Callbacks (the player's game asks, the server answers)
-- ------------------------------------------------------------

---Returns { loaded = is a character loaded?, goal = their goal, or false if none yet }
lib.callback.register('rp_goals:server:getMine', function(source)
    local citizenid = getCharacter(source)
    if not citizenid then return { loaded = false, goal = false } end

    local row = fetchGoal(citizenid)
    return { loaded = true, goal = row and toClient(row) or false }
end)

local lastSave = {}

---Saves a new goal, or changes an existing one. Returns: ok, errorName, extraInfo
lib.callback.register('rp_goals:server:save', function(source, input)
    local now = os.time()
    if lastSave[source] and now - lastSave[source] < 2 then return false, 'slow_down' end
    lastSave[source] = now

    local citizenid, name = getCharacter(source)
    if not citizenid or type(input) ~= 'table' then return false, 'save_failed' end

    local mode = input.mode == 'change' and 'change' or 'create'
    local category = input.category
    local goal = trim(input.goal)
    local reason = trim(input.reason)
    local firstStep = trim(input.firstStep)

    if not VALID_CATEGORY[category] then return false, 'pick_category' end

    local err, extra = checkLength(goal, config.limits.goal, 'goal_short')
    if not err then err, extra = checkLength(reason, config.limits.reason, 'reason_short') end
    if not err then err, extra = checkLength(firstStep, config.limits.firstStep, 'step_short') end
    if err then return false, err, extra end

    local existing = fetchGoal(citizenid)

    if existing and mode == 'create' then
        return false, 'already_set'
    end

    if existing then
        local wait = secondsUntilChangeAllowed(existing)
        if wait > 0 then return false, 'cooldown', math.ceil(wait / DAY) end

        MySQL.insert.await(
            'INSERT INTO `rp_character_goal_history` (`citizenid`, `category`, `goal`, `reason`, `first_step`, `set_at`, `replaced_at`) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { citizenid, existing.category, existing.goal, existing.reason, existing.first_step, existing.changed_at, now }
        )
        MySQL.update.await(
            'UPDATE `rp_character_goals` SET `category` = ?, `goal` = ?, `reason` = ?, `first_step` = ?, `changed_at` = ?, `times_changed` = `times_changed` + 1 WHERE `citizenid` = ?',
            { category, goal, reason, firstStep, now, citizenid }
        )
    else
        MySQL.insert.await(
            'INSERT INTO `rp_character_goals` (`citizenid`, `category`, `goal`, `reason`, `first_step`, `created_at`, `changed_at`) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { citizenid, category, goal, reason, firstStep, now, now }
        )
    end

    -- Shows up in the txAdmin console so staff can see new goals as they come in.
    lib.print.info(('%s (%s) %s their goal [%s]: %s'):format(name, citizenid, existing and 'changed' or 'set', category, goal))
    return true
end)

---Staff only: everyone online and their goal.
lib.callback.register('rp_goals:server:staffList', function(source)
    if not IsPlayerAceAllowed(source, config.staffAce) then return false end

    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local playerId = tonumber(id)
        local citizenid, name = getCharacter(playerId)
        if citizenid then
            local row = fetchGoal(citizenid)
            list[#list + 1] = {
                id = playerId,
                name = name,
                citizenid = citizenid,
                goal = row and toClient(row) or false,
            }
        end
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end)

AddEventHandler('playerDropped', function()
    lastSave[source] = nil
end)

-- ------------------------------------------------------------
-- Chat commands
-- ------------------------------------------------------------
lib.addCommand('goal', { help = locale('command.goal_help') }, function(source)
    TriggerClientEvent('rp_goals:client:openMine', source)
end)

lib.addCommand('goals', { help = locale('command.goals_help'), restricted = config.staffGroup }, function(source)
    TriggerClientEvent('rp_goals:client:openStaff', source)
end)

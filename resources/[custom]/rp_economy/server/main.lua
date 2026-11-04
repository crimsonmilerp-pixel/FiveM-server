-- ============================================================
--  rp_economy - server side
--  1. Income tax: PayIncome pays money earned from legal work with
--     the tax already taken off (brackets reset every tax week).
--  2. Treasury: every tax and upkeep dollar in, government paychecks out.
--     It's only a record: it never stops anyone's pay (decided Nov 4).
--  3. Weekly bills: charged once every real week, only while the player
--     is in the city: car loan payments (server/loans.lua) and luxury
--     upkeep for now; rent and mortgages plug in later.
-- ============================================================
local config = require 'config'
local loans = require 'server.loans'

local WEEK_SECONDS = 7 * 24 * 3600
local WEEK_ZERO = 345600 + config.weekStartUtcHour * 3600 -- Monday 5 Jan 1970 (UTC), plus the start hour
local BILL_SECONDS = math.floor(config.billEveryDays * 24 * 3600)

local ready = false
local treasuryBalance = 0
local income = {}     -- [citizenid] = { week, gross, tax } for the current tax week
local billState = {}  -- [source] = { citizenid, nextDue }
local running = {}    -- [source] = true while their bills are being charged

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function weekNumber(t)
    return math.floor(((t or os.time()) - WEEK_ZERO) / WEEK_SECONDS)
end

local function weekEnds(week)
    return WEEK_ZERO + (week + 1) * WEEK_SECONDS
end

local function money(n)
    n = math.floor(tonumber(n) or 0)
    return (n < 0 and '-$' or '$') .. lib.math.groupdigits(math.abs(n))
end

local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function notify(source, text, kind, duration, subTitle)
    exports.qbx_core:Notify(source, text, kind or 'inform', duration or 7000, subTitle)
end

---Text that came from a player (plates, names) can end up in menus that format Markdown. Make it harmless.
local function clean(text)
    text = tostring(text or ''):gsub('[<>]', ''):gsub('!%[', '! ['):gsub('%]%(', '] (')
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function charName(player)
    local info = player.PlayerData.charinfo or {}
    return clean(('%s %s'):format(info.firstname or '', info.lastname or ''))
end

-- ------------------------------------------------------------
-- Database (created automatically the first time)
-- ------------------------------------------------------------
local TABLES = {
    [[CREATE TABLE IF NOT EXISTS `rp_economy_income` (
        `citizenid` VARCHAR(50) NOT NULL,
        `week`      INT         NOT NULL,
        `gross`     BIGINT      NOT NULL DEFAULT 0,
        `tax`       BIGINT      NOT NULL DEFAULT 0,
        PRIMARY KEY (`citizenid`, `week`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
    [[CREATE TABLE IF NOT EXISTS `rp_treasury` (
        `week`   INT         NOT NULL,
        `kind`   VARCHAR(40) NOT NULL,
        `amount` BIGINT      NOT NULL DEFAULT 0,
        PRIMARY KEY (`week`, `kind`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
    [[CREATE TABLE IF NOT EXISTS `rp_bills` (
        `citizenid` VARCHAR(50)  NOT NULL,
        `next_due`  INT UNSIGNED NOT NULL,
        `last_run`  INT UNSIGNED NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
    [[CREATE TABLE IF NOT EXISTS `rp_bill_statements` (
        `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid`  VARCHAR(50)  NOT NULL,
        `created_at` INT UNSIGNED NOT NULL,
        `total`      BIGINT       NOT NULL,
        `details`    TEXT         NOT NULL,
        PRIMARY KEY (`id`),
        KEY `citizenid` (`citizenid`, `created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
}

for _, sql in ipairs(loans.TABLES) do TABLES[#TABLES + 1] = sql end

-- ------------------------------------------------------------
-- Treasury
-- ------------------------------------------------------------
---Records money going into (positive) or out of (negative) the government treasury.
local function addTreasury(kind, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 or type(kind) ~= 'string' then return end
    treasuryBalance = treasuryBalance + amount
    MySQL.query('INSERT INTO `rp_treasury` (`week`, `kind`, `amount`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `amount` = `amount` + VALUES(`amount`)',
        { weekNumber(), kind, amount })
end

exports('AddTreasury', addTreasury)

-- ------------------------------------------------------------
-- Income tax
-- ------------------------------------------------------------
---Total tax (whole dollars) on a week's income. Each bracket only taxes the part of the income inside it.
local function taxOn(weekIncome)
    local brackets, cents = config.incomeTax, 0
    for i = 1, #brackets do
        local bracket = brackets[i]
        local top = brackets[i + 1] and brackets[i + 1].over or math.huge
        if weekIncome > bracket.over then
            cents = cents + (math.min(weekIncome, top) - bracket.over) * bracket.rate
        end
    end
    return math.floor(cents / 100)
end

local function topRate(weekIncome)
    local rate = 0
    for _, bracket in ipairs(config.incomeTax) do
        if weekIncome > bracket.over then rate = bracket.rate end
    end
    return rate
end

---This tax week's income for a character (loaded from the database the first time).
local function getIncome(citizenid)
    local week = weekNumber()
    local entry = income[citizenid]
    if entry and entry.week == week then return entry end

    local row = MySQL.single.await('SELECT `gross`, `tax` FROM `rp_economy_income` WHERE `citizenid` = ? AND `week` = ?', { citizenid, week })
    entry = income[citizenid]
    if entry and entry.week == week then return entry end -- another payout loaded it while we waited

    entry = { week = week, gross = row and tonumber(row.gross) or 0, tax = row and tonumber(row.tax) or 0 }
    income[citizenid] = entry
    return entry
end

---Pays money earned from legal work with income tax taken off, and records it.
---Crime money, money from other players and rewards never go through here.
---@param source number
---@param gross number dollars before tax
---@param opts? { account?: string, reason?: string }
---@return { gross: integer, net: integer, tax: integer, note: string }? nil if nothing was paid
local function payIncome(source, gross, opts)
    opts = opts or {}
    gross = math.floor(tonumber(gross) or 0)
    if gross <= 0 then return nil end

    local player = getPlayer(source)
    if not player then return nil end
    local citizenid = player.PlayerData.citizenid

    local entry = getIncome(citizenid)
    player = getPlayer(source) -- still the same character after the database wait?
    if not player or player.PlayerData.citizenid ~= citizenid then return nil end

    local before = entry.gross
    local tax = math.min(gross, taxOn(before + gross) - taxOn(before))
    local net = gross - tax
    if net > 0 and not player.Functions.AddMoney(opts.account or 'bank', net, opts.reason or 'job-income') then
        return nil
    end

    entry.gross = before + gross
    entry.tax = entry.tax + tax
    MySQL.query('INSERT INTO `rp_economy_income` (`citizenid`, `week`, `gross`, `tax`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `gross` = `gross` + VALUES(`gross`), `tax` = `tax` + VALUES(`tax`)',
        { citizenid, entry.week, gross, tax })
    addTreasury('income_tax', tax)

    return { gross = gross, net = net, tax = tax, note = tax > 0 and locale('tax.note', money(tax)) or '' }
end

exports('PayIncome', payIncome)

---Paychecks from qbx_core (police, EMS, mechanics), with income tax taken off.
---Government paychecks are counted as treasury spending.
exports('PayPaycheck', function(source, payment)
    local player = getPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job and player.PlayerData.job.name

    local paid = payIncome(source, payment, { account = 'bank', reason = 'paycheck' })
    if not paid then return false end

    if job and config.governmentJobs[job] then
        addTreasury('pay_' .. job, -paid.gross)
    end
    if paid.tax > 0 then
        notify(source, locale('paycheck.taxed', money(paid.net), money(paid.tax)))
    else
        notify(source, locale('paycheck.plain', money(paid.net)))
    end
    return true
end)

-- ------------------------------------------------------------
-- Weekly bills
-- ------------------------------------------------------------
local vehicleList

local function vehicleData(model)
    vehicleList = vehicleList or exports.qbx_core:GetVehiclesByName() or {}
    return vehicleList[model]
end

loans.init({
    getPlayer = getPlayer,
    notify = notify,
    money = money,
    clean = clean,
    weekNumber = weekNumber,
    vehicleData = vehicleData,
})

local function sumLines(lines)
    local total = 0
    for _, line in ipairs(lines) do total = total + line.amount end
    return total
end

---Everything on a character's next weekly bill: { kind, label, amount } lines, biggest first.
local function billLines(citizenid)
    local lines, lux = {}, config.luxuryVehicles

    -- Luxury upkeep: owned vehicles priced above the line
    local owned = MySQL.query.await('SELECT `vehicle`, `plate` FROM `player_vehicles` WHERE `citizenid` = ?', { citizenid }) or {}
    for _, row in ipairs(owned) do
        local data = vehicleData(row.vehicle)
        local price = data and tonumber(data.price) or 0
        if price > lux.line then
            local amount = math.floor((price - lux.line) * lux.yearlyRate / lux.weeksPerYear)
            if amount > 0 then
                local name = clean(('%s %s'):format(data.brand or '', data.name or row.vehicle))
                lines[#lines + 1] = {
                    kind = 'luxury_upkeep',
                    label = locale('bill.vehicle_upkeep', name, clean(row.plate)),
                    amount = amount,
                }
            end
        end
    end

    table.sort(lines, function(a, b) return a.amount > b.amount end)
    return lines
end

---Charges a player's weekly bills now. Returns the total charged and how many lines the bill had, or nil if it didn't run.
---@param skipWait? boolean staff testing: also charge loans that are less than 3 days old
local function runBills(source, skipWait)
    local state = billState[source]
    if not state or running[source] then return nil end
    running[source] = true

    local ok, result, count = pcall(function()
        local player = getPlayer(source)
        if not player or player.PlayerData.citizenid ~= state.citizenid or billState[source] ~= state then return nil end

        -- Move the due date first, so a crash can never charge the same week twice.
        local now = os.time()
        state.nextDue = now + BILL_SECONDS
        MySQL.update.await('UPDATE `rp_bills` SET `next_due` = ?, `last_run` = ? WHERE `citizenid` = ?', { state.nextDue, now, state.citizenid })

        -- 1. Loan payments: only taken if the bank covers them, otherwise they're missed (late fee, credit hit).
        local loanLines, loanPaid = loans.charge(source, state.citizenid, now, skipWait)

        -- 2. Upkeep (worked out after the loans, so a car the bank just took back isn't billed).
        --    It always comes out of the bank, which can go below $0: that's the debt.
        local lines = billLines(state.citizenid)
        local upkeep = sumLines(lines)
        player = getPlayer(source)
        if not player or player.PlayerData.citizenid ~= state.citizenid then return loanPaid, #loanLines end
        if upkeep > 0 then
            player.Functions.RemoveMoney('bank', upkeep, 'weekly-bills')
            for _, line in ipairs(lines) do addTreasury(line.kind, line.amount) end
        end

        local all = {}
        for _, line in ipairs(loanLines) do all[#all + 1] = line end
        for _, line in ipairs(lines) do all[#all + 1] = line end
        local total = loanPaid + upkeep
        if #all == 0 then return 0, 0 end

        MySQL.insert.await('INSERT INTO `rp_bill_statements` (`citizenid`, `created_at`, `total`, `details`) VALUES (?, ?, ?, ?)',
            { state.citizenid, now, total, json.encode(all) })
        if total > 0 then
            notify(source, locale('bill.paid_title'), 'inform', 12000, locale('bill.paid', money(total)))
        end
        local bank = player.PlayerData.money and player.PlayerData.money.bank or 0
        if bank < 0 then
            notify(source, locale('bill.overdrawn', money(bank)), 'error', 15000)
        end
        return total, #all
    end)

    running[source] = nil
    if not ok then
        lib.print.error(('weekly bills failed for player %s: %s'):format(source, result))
        return nil
    end
    return result, count
end

---Starts tracking a character's bill date. New characters get their first bill a week from now.
local function setupBills(source, citizenid)
    local now = os.time()
    MySQL.query.await('INSERT IGNORE INTO `rp_bills` (`citizenid`, `next_due`) VALUES (?, ?)', { citizenid, now + BILL_SECONDS })
    local nextDue = tonumber(MySQL.scalar.await('SELECT `next_due` FROM `rp_bills` WHERE `citizenid` = ?', { citizenid })) or (now + BILL_SECONDS)

    local player = getPlayer(source)
    if not player or player.PlayerData.citizenid ~= citizenid then return end
    billState[source] = { citizenid = citizenid, nextDue = nextDue }
    -- If it's already due (it came due while they were away), the check loop charges it within a few minutes.
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if not ready or not player then return end -- the start-up thread picks up anyone who loaded earlier
    local source, citizenid = player.PlayerData.source, player.PlayerData.citizenid
    CreateThread(function() setupBills(source, citizenid) end)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    billState[source] = nil
end)

AddEventHandler('playerDropped', function()
    billState[source] = nil
end)

-- ------------------------------------------------------------
-- Start-up and the check loop
-- ------------------------------------------------------------
CreateThread(function()
    for _, sql in ipairs(TABLES) do MySQL.query.await(sql) end
    treasuryBalance = tonumber(MySQL.scalar.await('SELECT COALESCE(SUM(`amount`), 0) FROM `rp_treasury`')) or 0
    loans.start()
    ready = true

    -- Players already in the city (the resource was restarted)
    for source, player in pairs(exports.qbx_core:GetQBPlayers() or {}) do
        if player and player.PlayerData then setupBills(tonumber(source) or source, player.PlayerData.citizenid) end
    end

    while true do
        Wait(math.max(1, config.checkEveryMinutes) * 60000)
        local now, dueNow = os.time(), {}
        for source, state in pairs(billState) do
            if state.nextDue <= now then dueNow[#dueNow + 1] = source end
        end
        for _, source in ipairs(dueNow) do runBills(source) end
    end
end)

-- ------------------------------------------------------------
-- /finances (everyone)
-- ------------------------------------------------------------
lib.callback.register('rp_economy:server:finances', function(source)
    local player = getPlayer(source)
    if not player or not ready then return false end
    local citizenid = player.PlayerData.citizenid

    local entry = getIncome(citizenid)
    local lines = loans.estimate(citizenid)
    for _, line in ipairs(billLines(citizenid)) do lines[#lines + 1] = line end
    local credit = loans.financesData(citizenid)
    local last = MySQL.single.await('SELECT `created_at`, `total`, `details` FROM `rp_bill_statements` WHERE `citizenid` = ? ORDER BY `id` DESC LIMIT 1', { citizenid })

    player = getPlayer(source)
    if not player or player.PlayerData.citizenid ~= citizenid then return false end
    local now, state = os.time(), billState[source]

    return {
        bank = player.PlayerData.money.bank or 0,
        cash = player.PlayerData.money.cash or 0,
        week = {
            gross = entry.gross,
            tax = entry.tax,
            topRate = topRate(entry.gross),
            resetsIn = weekEnds(entry.week) - now,
        },
        bills = {
            dueIn = state and (state.nextDue - now) or BILL_SECONDS,
            lines = lines,
            total = sumLines(lines),
        },
        last = last and {
            ago = now - (tonumber(last.created_at) or now),
            total = tonumber(last.total) or 0,
            lines = json.decode(last.details or '[]') or {},
        } or nil,
        credit = credit.credit,
        loans = credit.loans,
        repoAfter = credit.repoAfter,
    }
end)

lib.addCommand('finances', { help = locale('command.finances_help') }, function(source)
    TriggerClientEvent('rp_economy:client:openFinances', source)
end)

-- ------------------------------------------------------------
-- /treasury and /billsnow (staff)
-- ------------------------------------------------------------
lib.callback.register('rp_economy:server:treasury', function(source)
    if not IsPlayerAceAllowed(source, config.staffAce) then return false end
    local week = weekNumber()
    local rows = MySQL.query.await('SELECT `week`, `kind`, `amount` FROM `rp_treasury` WHERE `week` IN (?, ?) ORDER BY `amount` DESC', { week, week - 1 }) or {}
    local thisWeek, lastWeek = {}, {}
    for _, row in ipairs(rows) do
        local list = tonumber(row.week) == week and thisWeek or lastWeek
        list[#list + 1] = { kind = row.kind, amount = tonumber(row.amount) or 0 }
    end
    return { balance = treasuryBalance, thisWeek = thisWeek, lastWeek = lastWeek }
end)

lib.addCommand('treasury', { help = locale('command.treasury_help'), restricted = config.staffGroup }, function(source)
    TriggerClientEvent('rp_economy:client:openTreasury', source)
end)

lib.addCommand('billsnow', {
    help = locale('command.billsnow_help'),
    restricted = config.staffGroup,
    params = { { name = 'id', type = 'playerId', help = locale('command.billsnow_arg'), optional = true } },
}, function(source, args)
    local target = args.id or source
    local player = getPlayer(target)
    if not player or not ready then return notify(source, locale('error.not_online'), 'error') end

    if not billState[target] then setupBills(target, player.PlayerData.citizenid) end
    local state = billState[target]
    if not state then return notify(source, locale('error.not_online'), 'error') end

    state.nextDue = 0
    local total, count = runBills(target, true)
    if total and (count or 0) > 0 then
        notify(source, locale('staff.bills_charged', charName(player), money(total)), 'success')
    else
        notify(source, locale('staff.bills_nothing', charName(player)), 'inform')
    end
end)

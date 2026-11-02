-- ============================================================
--  rp_jobmoments - server side
--  Decides when a moment happens, checks every choice, hands out
--  items and money, and keeps the case records police can read.
--  Jobs call exports.rp_jobmoments:OnTask(source, jobName) after
--  each finished task (a garbage stop, a taxi fare).
-- ============================================================
local config = require 'config'

local pending = {}    -- [source] = the moment waiting for this player's choice
local lastMoment = {} -- [source] = os.time() of their last moment
local nextId = 0

-- ------------------------------------------------------------
-- Database (tables are created automatically the first time)
-- ------------------------------------------------------------
CreateThread(function()
    -- Case records police can see with /cases and /serial
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_cases` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `kind`       VARCHAR(30)  NOT NULL,
            `status`     VARCHAR(20)  NOT NULL DEFAULT 'open',
            `serial`     VARCHAR(30)  NULL,
            `x`          FLOAT NOT NULL DEFAULT 0,
            `y`          FLOAT NOT NULL DEFAULT 0,
            `z`          FLOAT NOT NULL DEFAULT 0,
            `data`       LONGTEXT     NOT NULL,
            `created_at` INT UNSIGNED NOT NULL,
            `updated_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`id`),
            KEY `serial` (`serial`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Private log of every choice (staff only): who kept the gun, who took the cash, and so on
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_moment_log` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `case_id`    INT UNSIGNED NULL,
            `citizenid`  VARCHAR(50)  NOT NULL,
            `name`       VARCHAR(100) NOT NULL,
            `moment`     VARCHAR(30)  NOT NULL,
            `choice`     VARCHAR(30)  NOT NULL,
            `created_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`id`),
            KEY `case_id` (`case_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end)

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function charName(player)
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname, info.lastname)
end

local function isOnDutyPolice(player)
    local job = player.PlayerData.job
    return job.type == 'leo' and job.onduty
end

local function isStaff(source)
    return IsPlayerAceAllowed(source, config.staffAce)
end

---Street names come from the player's game (the server can't look them up). Keep them short and plain.
local function cleanStreet(street)
    if type(street) ~= 'string' then return '?' end
    -- Street names come from the player's game, and police/staff menus show them as formatted text,
    -- so strip anything that could turn into a link, image or HTML.
    street = (street:gsub('[%c<>%[%]%(%)!`*_#|\\]', '')):sub(1, 60)
    return street ~= '' and street or '?'
end

local LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local function generateSerial()
    local text = ''
    for _ = 1, 3 do
        local i = math.random(1, #LETTERS)
        text = text .. LETTERS:sub(i, i)
    end
    return ('%d%s%d'):format(math.random(100000, 999999), text, math.random(100000, 999999))
end

local function pickWeighted(list)
    local total = 0
    for _, entry in ipairs(list) do total += entry.weight end
    local roll = math.random() * total
    for _, entry in ipairs(list) do
        roll -= entry.weight
        if roll <= 0 then return entry.id end
    end
    return list[#list] and list[#list].id
end

local function createCase(kind, coords, data, serial)
    local now = os.time()
    return MySQL.insert.await(
        'INSERT INTO `rp_cases` (`kind`, `status`, `serial`, `x`, `y`, `z`, `data`, `created_at`, `updated_at`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { kind, 'open', serial, coords.x, coords.y, coords.z, json.encode(data), now, now }
    )
end

local function updateCase(caseId, status, extra)
    local row = MySQL.single.await('SELECT `data` FROM `rp_cases` WHERE `id` = ?', { caseId })
    if not row then return false end
    local data = json.decode(row.data) or {}
    for k, v in pairs(extra or {}) do data[k] = v end
    MySQL.update.await('UPDATE `rp_cases` SET `status` = ?, `data` = ?, `updated_at` = ? WHERE `id` = ?',
        { status, json.encode(data), os.time(), caseId })
    return true
end

local function logChoice(player, caseId, moment, choice)
    MySQL.insert('INSERT INTO `rp_moment_log` (`case_id`, `citizenid`, `name`, `moment`, `choice`, `created_at`) VALUES (?, ?, ?, ?, ?, ?)',
        { caseId, player.PlayerData.citizenid, charName(player), moment, choice, os.time() })
end

local function vehiclePlate(source)
    local veh = GetVehiclePedIsIn(GetPlayerPed(source), false)
    if veh == 0 then veh = GetVehiclePedIsIn(GetPlayerPed(source), true) end
    if veh == 0 then return '?' end
    local plate = (GetVehicleNumberPlateText(veh) or '?'):gsub('^%s+', ''):gsub('%s+$', '')
    return plate
end

local function policeAlert(source, text)
    -- qbx_police sends this to every on-duty officer, with a blip at the player's position
    TriggerEvent('police:server:policeAlert', text, nil, source)
end

-- ------------------------------------------------------------
-- Starting a moment (called by job resources)
-- ------------------------------------------------------------

---Decides whether a moment happens for this finished task.
---Returns true only if the moment takes over paying for this task
---(the taxi runner: the fare is paid later, if the driver catches them).
local function pickMoment(source, job, info)
    local list = config.jobs[job]
    if not list or not getPlayer(source) then return false end

    local now = os.time()
    local current = pending[source]
    if current and now > current.expires then pending[source], current = nil, nil end
    if current then return false end
    if lastMoment[source] and now - lastMoment[source] < config.cooldownMinutes * 60 then return false end
    if math.random(1, config.oneIn) ~= 1 then return false end

    local kind = pickWeighted(list)
    if not kind then return false end

    nextId += 1
    lastMoment[source] = now
    local moment = {
        id = nextId,
        job = job,
        kind = kind,
        coords = GetEntityCoords(GetPlayerPed(source)),
        expires = now + config.choiceSeconds,
        data = {},
    }
    pending[source] = moment

    if kind == 'runner' then
        moment.data.fare = math.floor(tonumber(info and info.fare) or 0)
        moment.data.plate = vehiclePlate(source)
        moment.expires = now + config.runner.seconds + 15
        TriggerClientEvent('rp_jobmoments:client:runner', source, moment.id, config.runner)
        return true
    end

    local show = {} -- details the player's screen needs
    if kind == 'bloody_bag' then
        moment.data.serial = generateSerial()
    elseif kind == 'lost_wallet' then
        local w = config.wallet
        moment.data.owner = ('%s %s'):format(w.firstNames[math.random(#w.firstNames)], w.lastNames[math.random(#w.lastNames)])
        moment.data.home = math.random(#w.homes)
        show.owner = moment.data.owner
        show.cash = w.cash
    elseif kind == 'left_bag' then
        moment.data.plate = vehiclePlate(source)
        show.cash = config.leftBag.dirtyCash
    elseif kind == 'tow_trunk' then
        moment.data.plate = info and type(info.plate) == 'string' and info.plate:gsub('^%s+', ''):gsub('%s+$', '') or '?'
        show.plate = moment.data.plate
    elseif kind == 'extra_package' then
        show.cash = config.extraPackage.dirtyCash
    end

    -- A short pause, so it doesn't pop up on top of the job's own messages.
    SetTimeout(2000, function()
        if pending[source] == moment then
            TriggerClientEvent('rp_jobmoments:client:moment', source, moment.id, kind, show)
        end
    end)
    return false
end

---Called by job resources after every finished task (a garbage stop, a taxi fare, a tow, a trucker delivery).
---Also tells other resources (rp_crews) that the task is done, unless a moment took over its pay.
local function OnTask(source, job, info)
    local takesOver = pickMoment(source, job, info)
    if not takesOver then
        TriggerEvent('rp_jobmoments:server:taskDone', source, job, info or {})
    end
    return takesOver
end
exports('OnTask', OnTask)

-- ------------------------------------------------------------
-- Choices
-- ------------------------------------------------------------
local handlers = {}

handlers.bloody_bag = function(source, player, moment, choice, street)
    local serial = moment.data.serial
    -- The shooting happened whatever the worker decides, so the case always exists.
    moment.data.caseId = moment.data.caseId or createCase('shooting', moment.coords, { street = street, weapon = 'pistol' }, serial)
    local caseId = moment.data.caseId

    if choice == 'turn_in' then
        local metadata = {
            caseId = caseId,
            description = locale('item.bloody_bag', serial, street),
        }
        if not exports.ox_inventory:CanCarryItem(source, 'found_evidence', 1, metadata) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, 'found_evidence', 1, metadata)
        updateCase(caseId, 'open', { found_by = charName(player) })
        logChoice(player, caseId, moment.kind, choice)
        return true, 'result.bloody_bag.turn_in'
    elseif choice == 'keep' then
        -- Unregistered, with the serial police have on file for this shooting.
        local metadata = { serial = serial, registered = false }
        if not exports.ox_inventory:CanCarryItem(source, config.bloodyBag.weapon, 1, metadata) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, config.bloodyBag.weapon, 1, metadata)
        logChoice(player, caseId, moment.kind, choice)
        return true, 'result.bloody_bag.keep'
    end

    logChoice(player, caseId, moment.kind, 'leave')
    return true, 'result.bloody_bag.leave'
end

handlers.lost_wallet = function(source, player, moment, choice)
    if choice == 'return' then
        local metadata = {
            owner = moment.data.owner,
            home = moment.data.home,
            description = locale('item.wallet', moment.data.owner),
        }
        if not exports.ox_inventory:CanCarryItem(source, 'lost_wallet', 1, metadata) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, 'lost_wallet', 1, metadata)
        logChoice(player, nil, moment.kind, choice)
        return true, 'result.lost_wallet.return', moment.data.home
    elseif choice == 'take_cash' then
        player.Functions.AddMoney('cash', config.wallet.cash, 'rp_jobmoments-wallet')
        logChoice(player, nil, moment.kind, choice)
        return true, 'result.lost_wallet.take_cash'
    end

    logChoice(player, nil, moment.kind, 'leave')
    return true, 'result.lost_wallet.leave'
end

handlers.left_bag = function(source, player, moment, choice, street)
    local amount = config.leftBag.dirtyCash
    -- The passenger reports their cash missing, with the cab's plate.
    moment.data.caseId = moment.data.caseId or createCase('lost_cash', moment.coords, { street = street, plate = moment.data.plate, amount = amount })
    local caseId = moment.data.caseId

    if choice == 'turn_in' then
        local metadata = {
            caseId = caseId,
            description = locale('item.left_bag', amount, moment.data.plate),
        }
        if not exports.ox_inventory:CanCarryItem(source, 'found_evidence', 1, metadata) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, 'found_evidence', 1, metadata)
        updateCase(caseId, 'open', { found_by = charName(player) })
        logChoice(player, caseId, moment.kind, choice)
        return true, 'result.left_bag.turn_in'
    elseif choice == 'keep' then
        if not exports.ox_inventory:CanCarryItem(source, 'black_money', amount) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, 'black_money', amount)
        logChoice(player, caseId, moment.kind, choice)
        return true, 'result.left_bag.keep'
    end

    logChoice(player, caseId, moment.kind, 'leave')
    return true, 'result.left_bag.leave'
end

handlers.tow_trunk = function(source, player, moment, choice, street)
    local plate = moment.data.plate

    if choice == 'turn_in' then
        local metadata = {
            description = locale('item.tow_trunk', plate),
        }
        if not exports.ox_inventory:CanCarryItem(source, 'found_evidence', 1, metadata) then return false, 'cant_carry' end
        moment.data.caseId = moment.data.caseId or createCase('drugs_found', moment.coords, { street = street, plate = plate, found_by = charName(player) })
        metadata.caseId = moment.data.caseId
        exports.ox_inventory:AddItem(source, 'found_evidence', 1, metadata)
        logChoice(player, moment.data.caseId, moment.kind, choice)
        return true, 'result.tow_trunk.turn_in'
    elseif choice == 'keep' then
        local item = config.towTrunk.item
        if not exports.ox_inventory:CanCarryItem(source, item, 1) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, item, 1)
        logChoice(player, nil, moment.kind, choice)
        return true, 'result.tow_trunk.keep'
    end

    logChoice(player, nil, moment.kind, 'leave')
    return true, 'result.tow_trunk.leave'
end

handlers.extra_package = function(source, player, moment, choice, street)
    local amount = config.extraPackage.dirtyCash

    if choice == 'turn_in' then
        local metadata = {
            description = locale('item.extra_package', amount, street),
        }
        if not exports.ox_inventory:CanCarryItem(source, 'found_evidence', 1, metadata) then return false, 'cant_carry' end
        moment.data.caseId = moment.data.caseId or createCase('found_shipment', moment.coords, { street = street, amount = amount, found_by = charName(player) })
        metadata.caseId = moment.data.caseId
        exports.ox_inventory:AddItem(source, 'found_evidence', 1, metadata)
        logChoice(player, moment.data.caseId, moment.kind, choice)
        return true, 'result.extra_package.turn_in'
    elseif choice == 'keep' then
        if not exports.ox_inventory:CanCarryItem(source, 'black_money', amount) then return false, 'cant_carry' end
        exports.ox_inventory:AddItem(source, 'black_money', amount)
        logChoice(player, nil, moment.kind, choice)

        -- Someone notices their box is missing...
        local citizenid = player.PlayerData.citizenid
        local delay = math.random(config.extraPackage.followUpMinutes.min, config.extraPackage.followUpMinutes.max) * 60000
        SetTimeout(delay, function()
            local later = exports.qbx_core:GetPlayerByCitizenId(citizenid)
            if later then
                TriggerClientEvent('rp_jobmoments:client:text', later.PlayerData.source, locale('followup.sender'), locale('followup.extra_package'))
            end
        end)
        return true, 'result.extra_package.keep'
    end

    logChoice(player, nil, moment.kind, 'leave')
    return true, 'result.extra_package.leave'
end

local VALID_CHOICES = {
    bloody_bag = { turn_in = true, keep = true, leave = true },
    lost_wallet = { ['return'] = true, take_cash = true, leave = true },
    left_bag = { turn_in = true, keep = true, leave = true },
    tow_trunk = { turn_in = true, keep = true, leave = true },
    extra_package = { turn_in = true, keep = true, leave = true },
}

---Returns: ok, localeKey, extra
lib.callback.register('rp_jobmoments:server:choose', function(source, momentId, choice, street)
    local moment = pending[source]
    if not moment or moment.id ~= momentId or not handlers[moment.kind] then return false, 'expired' end
    if os.time() > moment.expires then
        pending[source] = nil
        return false, 'expired'
    end
    if not VALID_CHOICES[moment.kind][choice] then return false, 'expired' end

    local player = getPlayer(source)
    if not player then return false, 'expired' end

    local ok, key, extra = handlers[moment.kind](source, player, moment, choice, cleanStreet(street))
    if ok then pending[source] = nil end -- on 'cant_carry' they can pick another choice
    return ok, key, extra
end)

-- ------------------------------------------------------------
-- Taxi runner: how the chase ended
-- ------------------------------------------------------------
lib.callback.register('rp_jobmoments:server:runnerResult', function(source, momentId, result, street)
    local moment = pending[source]
    if not moment or moment.kind ~= 'runner' or moment.id ~= momentId then return false end
    pending[source] = nil

    local player = getPlayer(source)
    if not player then return false end
    street = cleanStreet(street)
    local fare = moment.data.fare

    if result == 'noped' then
        -- Couldn't find the passenger (rare): pay the fare as normal.
        if fare > 0 then player.Functions.AddMoney('cash', fare, 'taxi-fare') end
        return true, 'runner.noped', fare
    end

    if os.time() > moment.expires then result = 'escaped' end

    if result == 'caught' then
        if #(GetEntityCoords(GetPlayerPed(source)) - moment.coords) > 400.0 then return false end
        local pay = math.floor(fare * (1 + config.runner.tipPercent / 100))
        if pay > 0 then player.Functions.AddMoney('cash', pay, 'taxi-fare') end
        logChoice(player, nil, 'runner', 'caught')
        return true, 'runner.caught', pay
    elseif result == 'reported' then
        local caseId = createCase('fare_evasion', moment.coords,
            { street = street, fare = fare, plate = moment.data.plate, reporter = charName(player) })
        policeAlert(source, locale('alert.runner'))
        logChoice(player, caseId, 'runner', 'reported')
        return true, 'runner.reported'
    elseif result == 'dead' then
        local caseId = createCase('pedestrian_down', GetEntityCoords(GetPlayerPed(source)),
            { street = street, plate = moment.data.plate })
        policeAlert(source, locale('alert.ped_down'))
        logChoice(player, caseId, 'runner', 'dead')
        return true, 'runner.dead'
    end

    logChoice(player, nil, 'runner', 'escaped')
    return true, 'runner.escaped'
end)

-- ------------------------------------------------------------
-- Police front desk: turning in found evidence
-- ------------------------------------------------------------
local function nearDesk(source)
    local pos = GetEntityCoords(GetPlayerPed(source))
    for _, desk in ipairs(config.desks) do
        if #(pos - desk.coords) <= desk.radius + 3.0 then return true end
    end
    return false
end

lib.callback.register('rp_jobmoments:server:turnIn', function(source)
    local player = getPlayer(source)
    if not player or not nearDesk(source) then return false, 'too_far' end

    local slots = exports.ox_inventory:Search(source, 'slots', 'found_evidence') or {}
    if #slots == 0 then return false, 'nothing' end

    local police = isOnDutyPolice(player)
    local name = charName(player)
    local count = 0
    for _, slot in ipairs(slots) do
        if exports.ox_inventory:RemoveItem(source, 'found_evidence', 1, nil, slot.slot) then
            count += 1
            local caseId = slot.metadata and slot.metadata.caseId
            if caseId then
                updateCase(caseId, 'recovered', {
                    turned_in_by = police and locale('cases.officer', name) or name,
                    turned_in_at = os.date('%b %d'),
                })
            end
        end
    end

    local reward = 0
    if not police and count > 0 then
        reward = count * config.evidenceReward
        player.Functions.AddMoney('cash', reward, 'rp_jobmoments-reward')
    end
    return true, count, reward, police
end)

-- ------------------------------------------------------------
-- Returning a lost wallet at the owner's front door
-- ------------------------------------------------------------
lib.callback.register('rp_jobmoments:server:returnWallet', function(source, home)
    local player = getPlayer(source)
    local homeCoords = config.wallet.homes[tonumber(home) or 0]
    if not player or not homeCoords then return false, 'no_wallet' end
    if #(GetEntityCoords(GetPlayerPed(source)) - homeCoords) > 8.0 then return false, 'too_far' end

    for _, slot in ipairs(exports.ox_inventory:Search(source, 'slots', 'lost_wallet') or {}) do
        if slot.metadata and slot.metadata.home == home then
            if exports.ox_inventory:RemoveItem(source, 'lost_wallet', 1, nil, slot.slot) then
                player.Functions.AddMoney('cash', config.wallet.returnReward, 'rp_jobmoments-wallet')
                logChoice(player, nil, 'lost_wallet', 'returned')
                return true, slot.metadata.owner, config.wallet.returnReward
            end
        end
    end
    return false, 'no_wallet'
end)

-- ------------------------------------------------------------
-- /cases and /serial (on-duty police, and staff)
-- ------------------------------------------------------------
local function canSeeCases(source)
    local player = getPlayer(source)
    return player and (isOnDutyPolice(player) or isStaff(source)), isStaff(source)
end

lib.callback.register('rp_jobmoments:server:cases', function(source)
    local allowed, staff = canSeeCases(source)
    if not allowed then return end

    -- Police only learn about found drugs or cash once someone turns them in. Staff see everything.
    local rows = MySQL.query.await(staff
        and 'SELECT * FROM `rp_cases` ORDER BY `id` DESC LIMIT 30'
        or "SELECT * FROM `rp_cases` WHERE NOT (`kind` IN ('drugs_found', 'found_shipment') AND `status` = 'open') ORDER BY `id` DESC LIMIT 30") or {}
    local cases = {}
    for i, row in ipairs(rows) do
        cases[i] = {
            id = row.id,
            kind = row.kind,
            status = row.status,
            serial = row.serial,
            coords = { x = row.x, y = row.y, z = row.z },
            data = json.decode(row.data) or {},
            date = os.date('%b %d', row.created_at),
        }
        if staff then
            -- Private: who made which choice. Never shown to police.
            cases[i].log = MySQL.query.await('SELECT `name`, `citizenid`, `choice` FROM `rp_moment_log` WHERE `case_id` = ?', { row.id })
        end
    end
    return cases, staff
end)

lib.addCommand('cases', { help = locale('command.cases_help') }, function(source)
    if not canSeeCases(source) then
        return exports.qbx_core:Notify(source, locale('error.no_permission'), 'error')
    end
    TriggerClientEvent('rp_jobmoments:client:openCases', source)
end)

lib.addCommand('serial', {
    help = locale('command.serial_help'),
    params = { { name = 'serial', type = 'string', help = locale('command.serial_param') } },
}, function(source, args)
    if not canSeeCases(source) then
        return exports.qbx_core:Notify(source, locale('error.no_permission'), 'error')
    end
    local serial = tostring(args.serial or ''):upper():gsub('%s', '')
    local row = MySQL.single.await('SELECT `id`, `kind`, `status` FROM `rp_cases` WHERE `serial` = ? ORDER BY `id` DESC LIMIT 1', { serial })
    if not row then
        return exports.qbx_core:Notify(source, locale('serial.none', serial), 'inform', 8000)
    end
    exports.qbx_core:Notify(source,
        locale('serial.match', serial, row.id, locale('kind.' .. row.kind), locale('status.' .. row.kind .. '.' .. row.status)),
        'warning', 12000)
end)

AddEventHandler('playerDropped', function()
    pending[source] = nil
    lastMoment[source] = nil
end)

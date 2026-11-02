-- ============================================================
--  rp_starter - server side
--  Keeps each character's tour progress, hands out the one free
--  starter vehicle, runs the kiosk, and stops starter vehicles
--  from being sold or traded.
-- ============================================================
local config = require 'config'

local STEP_INDEX = {}
for i, step in ipairs(config.steps) do STEP_INDEX[step.id] = i end

local ALLOWED_MODEL = {}
for _, v in ipairs(config.vehicles) do ALLOWED_MODEL[v.model] = true end

local starterIds, starterPlates = {}, {} -- every starter vehicle, kept in memory for fast checks
local claiming = {}                       -- [source] = true while a vehicle is being created

---The database hands back yes/no columns as true/false (not 1/0), so check both.
local function isYes(value)
    return value == true or value == 1
end

local function trimPlate(plate)
    return tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', ''):upper()
end

-- ------------------------------------------------------------
-- Database (created automatically the first time)
-- ------------------------------------------------------------
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_starter_progress` (
            `citizenid`  VARCHAR(50)  NOT NULL,
            `license`    VARCHAR(60)  NOT NULL,
            `step`       VARCHAR(20)  NOT NULL DEFAULT 'greet',
            `done`       TINYINT(1)   NOT NULL DEFAULT 0,
            `skipped`    TINYINT(1)   NOT NULL DEFAULT 0,
            `vehicle_id` INT UNSIGNED NULL,
            `plate`      VARCHAR(15)  NULL,
            `model`      VARCHAR(30)  NULL,
            `created_at` INT UNSIGNED NOT NULL,
            `updated_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`citizenid`),
            KEY `license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    for _, row in ipairs(MySQL.query.await('SELECT `vehicle_id`, `plate` FROM `rp_starter_progress` WHERE `vehicle_id` IS NOT NULL') or {}) do
        starterIds[row.vehicle_id] = true
        starterPlates[trimPlate(row.plate)] = true
    end

    -- Safety net: no ownership change for a starter vehicle, whatever tries it.
    exports.qbx_vehicles:registerHook('changeVehicleOwner', function(payload)
        if payload and starterIds[payload.vehicleId] then return false end
    end)

    -- The bus station kiosk
    exports.ox_inventory:RegisterShop('rp_starter_kiosk', {
        name = locale('kiosk.name'),
        inventory = config.kiosk.items,
        locations = { config.kiosk.coords.xyz },
    })
end)

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function near(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    return ped ~= 0 and #(GetEntityCoords(ped) - vec3(coords.x, coords.y, coords.z)) <= maxDistance
end

local function getRow(citizenid)
    return MySQL.single.await('SELECT * FROM `rp_starter_progress` WHERE `citizenid` = ?', { citizenid })
end

local function setStep(citizenid, step, done)
    MySQL.update.await('UPDATE `rp_starter_progress` SET `step` = ?, `done` = ?, `updated_at` = ? WHERE `citizenid` = ?',
        { step, done and 1 or 0, os.time(), citizenid })
end

---Can this player skip the tour? Staff always; players once another character of theirs has done (or skipped) it.
local function canSkip(source, player)
    if IsPlayerAceAllowed(source, config.staffAce) then return true end
    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM `rp_starter_progress` WHERE `license` = ? AND `citizenid` <> ? AND (`done` = 1 OR `skipped` = 1)',
        { player.PlayerData.license, player.PlayerData.citizenid })
    return (count or 0) > 0
end

local function statusFor(source, player, row)
    if not row then return nil end
    return {
        step = row.step,
        done = isYes(row.done),
        skipped = isYes(row.skipped),
        vehicleClaimed = row.vehicle_id ~= nil,
        model = row.model,
        plate = row.plate,
        canSkip = not isYes(row.done) and canSkip(source, player) or false,
    }
end

-- ------------------------------------------------------------
-- A brand-new character starts the tour
-- ------------------------------------------------------------
RegisterNetEvent('rp_starter:server:newCharacter', function()
    local source = source
    local player = getPlayer(source)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    if getRow(citizenid) then return end

    local now = os.time()
    MySQL.insert.await('INSERT IGNORE INTO `rp_starter_progress` (`citizenid`, `license`, `step`, `created_at`, `updated_at`) VALUES (?, ?, ?, ?, ?)',
        { citizenid, player.PlayerData.license, config.steps[1].id, now, now })
end)

lib.callback.register('rp_starter:server:status', function(source)
    local player = getPlayer(source)
    if not player then return end
    return statusFor(source, player, getRow(player.PlayerData.citizenid))
end)

-- ------------------------------------------------------------
-- Moving through the tour
-- ------------------------------------------------------------

---The player finished a step. Returns the new status, or nil if it wasn't their current step.
lib.callback.register('rp_starter:server:advance', function(source, stepId)
    local player = getPlayer(source)
    if not player then return end
    local row = getRow(player.PlayerData.citizenid)
    if not row or isYes(row.done) or row.step ~= stepId then return end

    local index = STEP_INDEX[stepId]
    local step = config.steps[index]
    if not step or stepId == 'vehicle' then return end -- the vehicle step finishes when they claim one

    -- Check they're really there.
    if stepId == 'greet' and not near(source, config.volunteer.coords, 8.0) then return end
    if stepId == 'kiosk' and not near(source, config.kiosk.coords, 8.0) then return end
    if step.coords and not near(source, step.coords, step.radius + 10.0) then return end

    local nextStep = config.steps[index + 1]
    local finished = stepId == 'goal' or not nextStep
    setStep(player.PlayerData.citizenid, finished and stepId or nextStep.id, finished)
    return statusFor(source, player, getRow(player.PlayerData.citizenid))
end)

lib.callback.register('rp_starter:server:skip', function(source)
    local player = getPlayer(source)
    if not player then return false, 'no_tour' end
    local row = getRow(player.PlayerData.citizenid)
    if not row or isYes(row.done) then return false, 'no_tour' end
    if not canSkip(source, player) then return false, 'first_character' end

    MySQL.update.await('UPDATE `rp_starter_progress` SET `done` = 1, `skipped` = 1, `updated_at` = ? WHERE `citizenid` = ?',
        { os.time(), player.PlayerData.citizenid })
    return true, row.vehicle_id ~= nil
end)

-- ------------------------------------------------------------
-- The free starter vehicle
-- ------------------------------------------------------------
lib.callback.register('rp_starter:server:claimVehicle', function(source, model)
    if claiming[source] then return false, 'busy' end
    if type(model) ~= 'string' or not ALLOWED_MODEL[model] then return false, 'bad_model' end

    local player = getPlayer(source)
    if not player then return false, 'no_tour' end
    local citizenid = player.PlayerData.citizenid
    local row = getRow(citizenid)
    if not row then return false, 'no_tour' end
    if row.vehicle_id then return false, 'already_claimed' end
    if not near(source, config.volunteer.coords, 8.0) then return false, 'too_far' end

    claiming[source] = true

    local plate
    repeat
        plate = trimPlate(qbx.generateRandomPlate())
    until not exports.qbx_vehicles:DoesPlayerVehiclePlateExist(plate)

    local vehicleId, err = exports.qbx_vehicles:CreatePlayerVehicle({
        model = model,
        citizenid = citizenid,
        props = { plate = plate },
    })
    if not vehicleId then
        claiming[source] = nil
        lib.print.error(('rp_starter: could not create starter vehicle for %s: %s'):format(citizenid, err and err.message or '?'))
        return false, 'failed'
    end

    -- Remember it before anything else can happen to it.
    starterIds[vehicleId] = true
    starterPlates[plate] = true
    MySQL.update.await('UPDATE `rp_starter_progress` SET `vehicle_id` = ?, `plate` = ?, `model` = ?, `updated_at` = ? WHERE `citizenid` = ?',
        { vehicleId, plate, model, os.time(), citizenid })

    -- Picking the vehicle also finishes the tour's first two steps.
    if not isYes(row.done) and (STEP_INDEX[row.step] or 1) <= STEP_INDEX.vehicle then
        setStep(citizenid, config.steps[STEP_INDEX.vehicle + 1].id, false)
    end

    local netId, vehicle = qbx.spawnVehicle({
        model = model,
        spawnSource = config.vehicleSpawn,
        warp = GetPlayerPed(source),
        props = { plate = plate },
    })
    claiming[source] = nil

    if vehicle and vehicle ~= 0 then
        Entity(vehicle).state:set('vehicleid', vehicleId, false)
        Entity(vehicle).state:set('fuel', config.startFuel, true)
        exports.qbx_vehiclekeys:GiveKeys(source, vehicle)
    end

    return true, plate, statusFor(source, player, getRow(citizenid))
end)

-- ------------------------------------------------------------
-- Starter vehicles can't be sold or traded
-- (qbx_vehiclesales and qbx_vehicleshop's /transfervehicle call these)
-- ------------------------------------------------------------
local function isStarterVehicle(vehicleId)
    return starterIds[tonumber(vehicleId) or -1] == true
end
exports('IsStarterVehicle', isStarterVehicle)

local function isStarterPlate(plate)
    return starterPlates[trimPlate(plate)] == true
end
exports('IsStarterPlate', isStarterPlate)

---Returns true (and tells the player why) if this vehicle is a starter vehicle and the sale must stop.
exports('BlockStarterSale', function(source, plate, vehicleId)
    if isStarterPlate(plate) or (vehicleId and isStarterVehicle(vehicleId)) then
        if source then
            exports.qbx_core:Notify(source, locale('vehicle.cant_sell'), 'error', 7000)
        end
        return true
    end
    return false
end)

-- ------------------------------------------------------------
-- Commands
-- ------------------------------------------------------------
lib.addCommand('tutorial', { help = locale('command.tutorial_help') }, function(source)
    TriggerClientEvent('rp_starter:client:showStep', source)
end)

lib.addCommand('skiptutorial', { help = locale('command.skip_help') }, function(source)
    TriggerClientEvent('rp_starter:client:skip', source)
end)

AddEventHandler('playerDropped', function()
    claiming[source] = nil
end)

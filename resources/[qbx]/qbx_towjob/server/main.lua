local config = require 'config.server'
local clientConfig = require 'config.client'
local sharedConfig = require 'config.shared'
local Bail = {}
local activeJobs = {}
local completedJobs = {}
local activeTrucks = {}
local spawning = {}

-- [OUR CHANGE] Job pay goes through rp_economy, which takes income tax off and records it.
-- If rp_economy isn't running, the full amount is paid like before. See docs/core-changes.md
local function payIncome(source, amount, account, reason)
    if GetResourceState('rp_economy') == 'started' then
        local ok, paid = pcall(function()
            return exports.rp_economy:PayIncome(source, amount, { account = account, reason = reason })
        end)
        if ok then return paid end
    end
    local player = exports.qbx_core:GetPlayer(source)
    if player and amount > 0 and player.Functions.AddMoney(account, amount, reason) then
        return { gross = amount, net = amount, tax = 0, note = '' }
    end
end

local function isTowDriver(player)
    return player and player.PlayerData.job.name == 'tow'
end

local function isAllowedTowTruck(model)
    if type(model) ~= 'string' then return false end
    for allowed in pairs(clientConfig.vehicles) do
        if model:lower() == allowed:lower() then return true end
    end
    return false
end

local function getCoords(coords)
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' and type(coords) ~= 'vector4' then return end
    local x = tonumber(coords.x or coords[1])
    local y = tonumber(coords.y or coords[2])
    local z = tonumber(coords.z or coords[3])
    if not x or not y or not z then return end
    return vec3(x, y, z)
end

local function getTowspot(model, coords)
    if type(model) ~= 'string' then return end
    for index, towspot in ipairs(sharedConfig.locations.towspots) do
        if model:lower() == towspot.model:lower() and #(coords - towspot.coords) <= 5.0 then
            return index, towspot
        end
    end
end

RegisterNetEvent('qb-tow:server:DoBail', function(takeBail, vehInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not isTowDriver(player) or type(takeBail) ~= 'boolean' then return end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - sharedConfig.locations.vehicle.coords.xyz) > 8.0 then return end

    local citizenid = player.PlayerData.citizenid
    if not takeBail then
        if not Bail[citizenid] then return end
        player.Functions.AddMoney('bank', Bail[citizenid], 'tow-bail-paid')
        Bail[citizenid] = nil
        local truck = activeTrucks[citizenid]
        if truck and DoesEntityExist(truck) then DeleteEntity(truck) end
        activeTrucks[citizenid] = nil
        TriggerClientEvent('ox_lib:notify', src, {
            id = 'bail_pay',
            title = 'Job Payment',
            description = locale('success.refund_to_cash', config.bailPrice),
            showDuration = true,
            position = 'center-right',
            icon = 'check',
            iconColor = '#49c530'
        })
        return
    end

    if Bail[citizenid] or not isAllowedTowTruck(vehInfo) then return end

    local paymentMethod
    if player.PlayerData.money.cash >= config.bailPrice then
        paymentMethod = 'cash'
    elseif player.PlayerData.money.bank >= config.bailPrice then
        paymentMethod = 'bank'
    else
        TriggerClientEvent('ox_lib:notify', src, {
            id = 'tow_pay',
            title = 'Job Payment',
            description = locale('error.no_deposit', config.bailPrice),
            showDuration = true,
            position = 'center-right',
            icon = 'ban',
            iconColor = '#C53030'
        })
        return
    end

    if not player.Functions.RemoveMoney(paymentMethod, config.bailPrice, 'tow-paid-bail') then return end
    Bail[citizenid] = config.bailPrice
    TriggerClientEvent('ox_lib:notify', src, {
        id = 'bail_pay',
        title = 'Job Payment',
        description = locale('success.paid_with_' .. paymentMethod, config.bailPrice),
        showDuration = true,
        position = 'center-right',
        icon = 'check',
        iconColor = '#49c530'
    })
    TriggerClientEvent('qb-tow:client:SpawnVehicle', src)
end)

RegisterNetEvent('qb-tow:server:11101110', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local drops = completedJobs[src] or 0
    if not isTowDriver(player) or drops < 1 then return end

    local playerPed = GetPlayerPed(src)
    if playerPed == 0 or #(GetEntityCoords(playerPed) - sharedConfig.locations.main.coords.xyz) > 6.0 then return end

    completedJobs[src] = nil
    drops = math.min(drops, 20)
    local bonus = 0
    local dropPrice = math.random(68, 78) -- [OUR CHANGE] was random(150, 170); Oct 27 80-95; Nov 2 68-78 after measuring tow distances. Aims for ~$660/hr. See docs/core-changes.md
    if drops > 5 then
        bonus = math.ceil((dropPrice / 10) * ((3 * (drops / 5)) + 2))
    end
    local price = (dropPrice * drops) + bonus
    local payment = price - math.ceil((price / 100) * config.paymentTax)

    player.Functions.AddJobReputation(1)
    -- [OUR CHANGE] Paid through rp_economy: income tax comes off (it replaced the 15% "tax", now 0 in config)
    local paid = payIncome(src, payment, 'bank', 'tow-salary')
    if not paid then return end
    TriggerClientEvent('ox_lib:notify', src, {
        id = 'tow_pay',
        title = 'Job Payment',
        description = locale('success.you_earned', paid.net) .. paid.note,
        showDuration = true,
        position = 'center-right',
        icon = 'check',
        iconColor = '#49c530'
    })
end)

lib.addCommand('npc', {help = locale('info.toggle_npc')}, function(source)
    TriggerClientEvent('jobs:client:ToggleNpc', source)
end)

lib.addCommand('tow', {help = locale('info.tow')}, function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'tow' and player.PlayerData.job.name ~= 'mechanic' then return end
    TriggerClientEvent('qb-tow:client:TowVehicle', source)
end)

lib.callback.register('qb-tow:server:spawnVehicle', function(source, model, coords, warp)
    local player = exports.qbx_core:GetPlayer(source)
    local spawnCoords = getCoords(coords)
    if not isTowDriver(player) or not spawnCoords or spawning[source] then return end

    if warp then
        if warp ~= true or not Bail[player.PlayerData.citizenid] or not isAllowedTowTruck(model) then return end
        if #(spawnCoords - sharedConfig.locations.vehicle.coords.xyz) > 5.0 then return end
        if #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.locations.vehicle.coords.xyz) > 8.0 then return end
        local citizenid = player.PlayerData.citizenid
        local truck = activeTrucks[citizenid]
        if truck and DoesEntityExist(truck) then return end

        spawning[source] = true
        local success, netId, vehicle = pcall(qbx.spawnVehicle, {model = model, spawnSource = sharedConfig.locations.vehicle.coords, warp = GetPlayerPed(source)})
        spawning[source] = nil
        if not success or not netId or not vehicle or vehicle == 0 then return end
        local currentPlayer = exports.qbx_core:GetPlayer(source)
        if not Bail[citizenid] or not currentPlayer or currentPlayer.PlayerData.citizenid ~= citizenid then
            DeleteEntity(vehicle)
            return
        end
        activeTrucks[citizenid] = vehicle
        return netId
    end

    local activeJob = activeJobs[source]
    if activeJob then
        local activeVehicle = NetworkGetEntityFromNetworkId(activeJob.netId)
        if activeJob.expiresAt > os.time() and DoesEntityExist(activeVehicle) then return end
        activeJobs[source] = nil
    end
    local towspotIndex, towspot = getTowspot(model, spawnCoords)
    if not towspot or #(GetEntityCoords(GetPlayerPed(source)) - towspot.coords) > 60.0 then return end

    spawning[source] = true
    local success, netId, vehicle = pcall(qbx.spawnVehicle, {model = towspot.model, spawnSource = towspot.coords})
    spawning[source] = nil
    if not success or not netId or netId == 0 or not vehicle or vehicle == 0 then return end
    local currentPlayer = exports.qbx_core:GetPlayer(source)
    if not currentPlayer or currentPlayer.PlayerData.citizenid ~= player.PlayerData.citizenid then
        DeleteEntity(vehicle)
        return
    end

    local tripDistance = #(towspot.coords - sharedConfig.locations.dropoff.coords)
    activeJobs[source] = {
        netId = netId,
        model = towspot.model,
        towspot = towspotIndex,
        earliestCompletion = os.time() + math.max(30, math.floor(tripDistance / 40)),
        expiresAt = os.time() + 1800,
    }
    return netId
end)

lib.callback.register('qb-tow:server:completeTow', function(source, netId)
    local player = exports.qbx_core:GetPlayer(source)
    local job = activeJobs[source]
    if not isTowDriver(player) or not job or math.type(netId) ~= 'integer' or netId ~= job.netId then return false end
    if os.time() < job.earliestCompletion or os.time() > job.expiresAt then return false end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local ped = GetPlayerPed(source)
    if not DoesEntityExist(vehicle) or ped == 0 then return false end
    if GetEntityModel(vehicle) ~= joaat(job.model) then return false end
    if #(GetEntityCoords(vehicle) - sharedConfig.locations.vehicle.coords.xyz) > 25.0 then return false end
    if #(GetEntityCoords(ped) - sharedConfig.locations.vehicle.coords.xyz) > 40.0 then return false end

    activeJobs[source] = nil
    completedJobs[source] = (completedJobs[source] or 0) + 1

    -- [OUR CHANGE] Job moments and crew bonus (rp_jobmoments, rp_crews). See docs/core-changes.md
    if GetResourceState('rp_jobmoments') == 'started' then
        exports.rp_jobmoments:OnTask(source, 'tow', { plate = GetVehicleNumberPlateText(vehicle) })
    end

    DeleteEntity(vehicle)
    return true
end)

AddEventHandler('playerDropped', function()
    activeJobs[source] = nil
    completedJobs[source] = nil
end)

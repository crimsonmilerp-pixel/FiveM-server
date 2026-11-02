local VEHICLES = exports.qbx_core:GetVehiclesByName()

local function generateOID()
    local num = math.random(1, 10) .. math.random(111, 999)
    return 'OC' .. num
end

lib.callback.register('qb-occasions:server:getVehicles', function()
    local result = MySQL.query.await('SELECT * FROM occasion_vehicles')
    if result[1] then
        return result
    end
end)

lib.callback.register('qb-occasions:server:getSellerInformation', function(_, citizenId)
    -- [OUR CHANGE] Only send the seller's character info (name, phone, account) the contract shows.
    -- It used to send the whole player row (money, inventory, everything). See docs/core-changes.md
    local result = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenId})
    if result then
        return { charinfo = result.charinfo }
    end
end)

-- [OUR CHANGE] The server remembers which car a player is allowed to spawn after buying or taking back a listing,
-- instead of trusting the car details their game sends (which allowed spawning any vehicle). See docs/core-changes.md
local pendingSpawn = {}
local MAX_LISTING_PRICE = 10000000

lib.callback.register('qb-vehiclesales:server:CheckModelName', function(_, plate)
    if plate then
        return MySQL.scalar.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', {plate})
    end
end)

lib.callback.register('qbx_vehiclesales:server:spawnVehicle', function (source, _, coords, warp)
    local vehicle = pendingSpawn[source]
    if not vehicle or os.time() > vehicle.expires then pendingSpawn[source] = nil return end
    if type(coords) ~= 'vector4' or #(GetEntityCoords(GetPlayerPed(source)) - coords.xyz) > 100.0 then return end
    pendingSpawn[source] = nil

    local vehmods = json.decode(vehicle.mods or '{}') or {}
    local netId, veh = qbx.spawnVehicle({model = vehicle.model, spawnSource = coords, warp = warp, props = vehmods})
    if not veh or veh == 0 then return end

    SetVehicleNumberPlateText(veh, vehicle.plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, vehicle.plate)
    return netId
end)

lib.callback.register('qbx_vehiclesales:server:checkVehicleOwner', function(source, plate)
    local player = exports.qbx_core:GetPlayer(source)
    -- [OUR CHANGE] Free starter vehicles (rp_starter) can't be sold. See docs/core-changes.md
    if GetResourceState('rp_starter') == 'started' and exports.rp_starter:BlockStarterSale(source, plate) then return false end
    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, player.PlayerData.citizenid})

    if result and result.id then
        local financeRow = MySQL.single.await('SELECT * FROM vehicle_financing WHERE vehicleId = ?', {result.id})
        return true, financeRow?.balance or 0
    end

    return false
end)

RegisterNetEvent('qb-occasions:server:ReturnVehicle', function(vehicleData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or type(vehicleData) ~= 'table' then return end -- [OUR CHANGE]
    local result = MySQL.query.await('SELECT * FROM occasion_vehicles WHERE plate = ? AND occasionid = ?', {vehicleData.plate, vehicleData.oid})

    if not result[1] then
        exports.qbx_core:Notify(src, locale('error.vehicle_does_not_exist'), 'error', 3500)
        return
    end

    if result[1].seller ~= player.PlayerData.citizenid then
        exports.qbx_core:Notify(src, locale('error.not_your_vehicle'), 'error', 3500)
        return
    end

    -- [OUR CHANGE] Use the listing's own model and mods (the game could send a different car). See docs/core-changes.md
    local listing = result[1]
    local removed = MySQL.update.await('DELETE FROM occasion_vehicles WHERE occasionid = ? AND plate = ?', {listing.occasionid, listing.plate})
    if not removed or removed < 1 then return end
    MySQL.insert.await('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {player.PlayerData.license, player.PlayerData.citizenid, listing.model, joaat(listing.model), listing.mods, listing.plate, 0})
    pendingSpawn[src] = { model = listing.model, mods = listing.mods, plate = listing.plate, expires = os.time() + 60 }
    TriggerClientEvent('qb-occasions:client:ReturnOwnedVehicle', src, result[1])
    TriggerClientEvent('qb-occasion:client:refreshVehicles', -1)
end)

RegisterNetEvent('qb-occasions:server:sellVehicle', function(vehiclePrice, vehicleData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    -- [OUR CHANGE] Free starter vehicles (rp_starter) can't be sold
    if GetResourceState('rp_starter') == 'started' and exports.rp_starter:BlockStarterSale(src, vehicleData and vehicleData.plate) then return end

    -- [OUR CHANGE] Security: it used to delete ANY car with that plate (even someone else's) and list it for the
    -- caller, at any price. Now: it must be your car, paid off, at a sane price, using the database's copy. See docs/core-changes.md
    local price = math.floor(tonumber(vehiclePrice) or 0)
    if not player or type(vehicleData) ~= 'table' or price < 1 or price > MAX_LISTING_PRICE then return end
    local owned = MySQL.single.await('SELECT id, vehicle, mods, plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', {vehicleData.plate, player.PlayerData.citizenid})
    if not owned then
        exports.qbx_core:Notify(src, locale('error.not_your_vehicle'), 'error', 3500)
        return
    end
    local finance = MySQL.single.await('SELECT balance FROM vehicle_financing WHERE vehicleId = ?', {owned.id})
    if finance and (tonumber(finance.balance) or 0) > 0 then
        exports.qbx_core:Notify(src, locale('error.finish_payments'), 'error', 3500)
        return
    end
    local description = tostring(vehicleData.desc or ''):sub(1, 250)

    MySQL.query.await('DELETE FROM player_vehicles WHERE id = ?', {owned.id})
    MySQL.insert('INSERT INTO occasion_vehicles (seller, price, description, plate, model, mods, occasionid) VALUES (?, ?, ?, ?, ?, ?, ?)',{player.PlayerData.citizenid, price, description, owned.plate, owned.vehicle, owned.mods, generateOID()})
    TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'Vehicle for Sale', 'red','**' .. GetPlayerName(src) .. '** has a ' .. owned.vehicle .. ' priced at ' .. price)
    TriggerClientEvent('qb-occasion:client:refreshVehicles', -1)
end)

RegisterNetEvent('qb-occasions:server:sellVehicleBack', function(vehData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    -- [OUR CHANGE] Free starter vehicles (rp_starter) can't be sold back
    if GetResourceState('rp_starter') == 'started' and exports.rp_starter:BlockStarterSale(src, vehData and vehData.plate) then return end
    -- [OUR CHANGE] Security: the price used to come from the model the game sent, so any car could be sold back
    -- at half a supercar's price. Now it's the database's model, and the car must be paid off. See docs/core-changes.md
    if not player or type(vehData) ~= 'table' then return end
    local plate = vehData.plate
    local owned = MySQL.single.await('SELECT id, vehicle FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, player.PlayerData.citizenid})
    if not owned then return end
    local finance = MySQL.single.await('SELECT balance FROM vehicle_financing WHERE vehicleId = ?', {owned.id})
    if finance and (tonumber(finance.balance) or 0) > 0 then
        exports.qbx_core:Notify(src, locale('error.finish_payments'), 'error', 3500)
        return
    end
    local price = VEHICLES[owned.vehicle] and tonumber(VEHICLES[owned.vehicle].price) or 0
    local payout = math.floor(price * 0.5) -- This will give you half of the cars value
    local success = MySQL.query.await('DELETE FROM player_vehicles WHERE id = ?', {owned.id})
    if success and success.affectedRows > 0 then -- only pay out after we delete the vehicle
        player.Functions.AddMoney('bank', payout)
        exports.qbx_core:Notify(src, (locale('success.sold_car_for_price'):format(payout)), 'success', 5500)
    end
end)

RegisterNetEvent('qb-occasions:server:buyVehicle', function(vehicleData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or type(vehicleData) ~= 'table' then return end -- [OUR CHANGE]
    local result = MySQL.query.await('SELECT * FROM occasion_vehicles WHERE plate = ? AND occasionid = ?',{vehicleData.plate, vehicleData.oid})
    if not result[1] or not next(result[1]) then return end
    if player.PlayerData.money.bank < result[1].price then
        exports.qbx_core:Notify(src, locale('error.not_enough_money'), 'error', 3500)
        return
    end

    -- [OUR CHANGE] Take the listing off first so two people can't buy the same car, and only then charge. See docs/core-changes.md
    local removed = MySQL.update.await('DELETE FROM occasion_vehicles WHERE plate = ? AND occasionid = ?', {result[1].plate, result[1].occasionid})
    if not removed or removed < 1 then return end
    if not player.Functions.RemoveMoney('bank', result[1].price, 'used-car-bought') then
        MySQL.insert.await('INSERT INTO occasion_vehicles (seller, price, description, plate, model, mods, occasionid) VALUES (?, ?, ?, ?, ?, ?, ?)', {result[1].seller, result[1].price, result[1].description, result[1].plate, result[1].model, result[1].mods, result[1].occasionid})
        exports.qbx_core:Notify(src, locale('error.not_enough_money'), 'error', 3500)
        return
    end
    pendingSpawn[src] = { model = result[1].model, mods = result[1].mods, plate = result[1].plate, expires = os.time() + 60 }

    local sellerCitizenId = result[1].seller
    local sellerData = exports.qbx_core:GetPlayerByCitizenId(sellerCitizenId)
    local newPrice = math.ceil((result[1].price / 100) * 77)
    MySQL.insert(
        'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            player.PlayerData.license,
            player.PlayerData.citizenid, result[1].model,
            GetHashKey(result[1].model),
            result[1].mods,
            result[1].plate,
            0
        })
    if sellerData then
        sellerData.Functions.AddMoney('bank', newPrice)
    else
        local buyerData = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?',{sellerCitizenId})
        if buyerData[1] then
            local buyerMoney = json.decode(buyerData[1].money)
            buyerMoney.bank = buyerMoney.bank + newPrice
            MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(buyerMoney), sellerCitizenId})
        end
    end
    TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'bought', 'green', '**' .. GetPlayerName(src) .. '** has bought for ' .. result[1].price .. ' (' .. result[1].plate ..') from **' .. sellerCitizenId .. '**')
    TriggerClientEvent('qb-occasions:client:BuyFinished', src, result[1])
    TriggerClientEvent('qb-occasion:client:refreshVehicles', -1)
    TriggerEvent('qb-phone:server:sendNewMailToOffline', sellerCitizenId, {
        sender = locale('mail.sender'),
        subject = locale('mail.subject'),
        message = (locale('mail.message'):format(newPrice, VEHICLES[result[1].model] and VEHICLES[result[1].model].name or result[1].model)) -- [OUR CHANGE] no error for unknown models
    })
end)

-- [OUR CHANGE]
AddEventHandler('playerDropped', function()
    pendingSpawn[source] = nil
end)

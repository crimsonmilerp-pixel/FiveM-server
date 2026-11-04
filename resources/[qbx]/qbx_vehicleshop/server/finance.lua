-- [OUR CHANGE] Nov 4, 2026: this whole file was rewritten. Financing now goes through rp_economy:
-- a real loan with interest from the buyer's credit score, an offer the buyer signs, weekly payments
-- taken with the weekly bills, and the bank taking the car back after 3 missed payments in a row.
-- Qbox's own payment timer, payment menu and repossession are gone. See docs/core-changes.md
local sharedConfig = require 'config.shared'

if not sharedConfig.finance.enable then return end

---Kept because server/main.lua still calls it. rp_economy keeps track of loans now.
function SetHasFinanced() end

-- [OUR CHANGE] Uses IsShopSalesperson (server/utils.lua): at npcFallback shops the dealer must be clocked in.
local function isAuthorizedSalesperson(source, shop)
    return IsShopSalesperson(source, shop)
end

local function economyRunning()
    return GetResourceState('rp_economy') == 'started'
end

---Asks rp_economy for a loan offer. Returns the offer, or nil after telling the player why not.
local function getOffer(notifySource, buyerSource, vehicle, downPayment, weeks)
    local quote = exports.rp_economy:QuoteCarLoan(buyerSource, {
        model = vehicle,
        price = COREVEHICLES[vehicle].price,
        down = downPayment,
        weeks = weeks,
    })
    if not quote or not quote.ok then
        exports.qbx_core:Notify(notifySource, quote and quote.reason or locale('error.finance_unavailable'), 'error', 12000)
        return nil
    end
    return quote
end

---Reads and checks the numbers the game sent. Returns downPayment, weeks or nil.
local function readNumbers(downPayment, weeks)
    downPayment, weeks = tonumber(downPayment), tonumber(weeks)
    if not downPayment or math.type(downPayment) ~= 'integer' or downPayment < 0 then return end
    if not weeks or math.type(weeks) ~= 'integer' or weeks < 1 then return end
    return downPayment, weeks
end

---@param downPayment number
---@param weeks number number of weekly payments
---@param vehicle string
---@param playerId string|number the buyer
RegisterNetEvent('qbx_vehicleshop:server:sellfinanceVehicle', function(downPayment, weeks, vehicle, playerId)
    local src = source
    if not economyRunning() then return exports.qbx_core:Notify(src, locale('error.finance_unavailable'), 'error') end
    -- [OUR CHANGE] No selling to yourself (that would pay you a commission on your own car)
    if tonumber(playerId) == src then
        return exports.qbx_core:Notify(src, locale('error.selfsale'), 'error')
    end
    local target = exports.qbx_core:GetPlayer(tonumber(playerId))
    if not target then
        return exports.qbx_core:Notify(src, locale('error.Invalid_ID'), 'error')
    end
    local buyer = target.PlayerData.source

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(buyer))) >= 3 then
        return exports.qbx_core:Notify(src, locale('error.playertoofar'), 'error')
    end

    local shopId = GetShopZone(buyer)
    local shop = sharedConfig.shops[shopId]
    if not shop or not isAuthorizedSalesperson(src, shop) then return end
    if not CheckVehicleList(vehicle, shopId) or not COREVEHICLES[vehicle] then
        return exports.qbx_core:Notify(src, locale('error.notallowed'), 'error')
    end

    downPayment, weeks = readNumbers(downPayment, weeks)
    if not downPayment then return end

    -- The buyer reads and signs the offer
    local quote = getOffer(src, buyer, vehicle, downPayment, weeks)
    if not quote then return end
    if not lib.callback.await('qbx_vehicleshop:client:confirmLoan', buyer, quote) then
        return exports.qbx_core:Notify(src, locale('error.buyerdeclined'), 'error')
    end

    -- Check again: things can change while they read it
    quote = getOffer(src, buyer, vehicle, downPayment, weeks)
    if not quote then return end
    local coords = GetClearSpawnArea(shop.vehicleSpawns)
    if not coords then
        return exports.qbx_core:Notify(src, locale('error.no_clear_spawn'), 'error')
    end

    -- Takes the down payment from the buyer and pays the dealer's commission on the full price
    if not SellShowroomVehicleTransact(src, target, quote.price, downPayment) then return end

    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
        model = vehicle,
        citizenid = target.PlayerData.citizenid,
    })
    if not vehicleId then
        target.Functions.AddMoney('bank', downPayment, 'vehicle-finance-refund')
        return exports.qbx_core:Notify(src, locale('error.finance_unavailable'), 'error')
    end
    exports.rp_economy:CreateCarLoan(buyer, vehicleId, quote)

    SpawnVehicle(buyer, {
        coords = coords,
        vehicleId = vehicleId
    })
end)

---@param downPayment number
---@param weeks number number of weekly payments
---@param vehicle string
RegisterNetEvent('qbx_vehicleshop:server:financeVehicle', function(downPayment, weeks, vehicle)
    local src = source
    if not economyRunning() then return exports.qbx_core:Notify(src, locale('error.finance_unavailable'), 'error') end

    local shopId = GetShopZone(src)
    local shop = sharedConfig.shops[shopId]
    if not shop then return end
    if not IsShopSelfService(shop, src) or not sharedConfig.enableFreeUseBuy then return end -- [OUR CHANGE] was shop.type ~= 'free-use'
    if not CheckVehicleList(vehicle, shopId) or not COREVEHICLES[vehicle] then
        return exports.qbx_core:Notify(src, locale('error.notallowed'), 'error')
    end

    downPayment, weeks = readNumbers(downPayment, weeks)
    if not downPayment then return end

    local quote = getOffer(src, src, vehicle, downPayment, weeks)
    if not quote then return end
    if not lib.callback.await('qbx_vehicleshop:client:confirmLoan', src, quote) then return end

    -- Check again: things can change while they read it
    quote = getOffer(src, src, vehicle, downPayment, weeks)
    if not quote then return end
    local coords = GetClearSpawnArea(shop.vehicleSpawns)
    if not coords then
        return exports.qbx_core:Notify(src, locale('error.no_clear_spawn'), 'error')
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if not RemoveMoney(src, downPayment, 'vehicle-financed-in-showroom') then
        return exports.qbx_core:Notify(src, locale('error.notenoughmoney'), 'error')
    end

    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
        model = vehicle,
        citizenid = player.PlayerData.citizenid,
    })
    if not vehicleId then
        player.Functions.AddMoney('bank', downPayment, 'vehicle-finance-refund')
        return exports.qbx_core:Notify(src, locale('error.finance_unavailable'), 'error')
    end
    exports.rp_economy:CreateCarLoan(src, vehicleId, quote)

    exports.qbx_core:Notify(src, locale('success.purchased'), 'success')
    SpawnVehicle(src, {
        coords = coords,
        vehicleId = vehicleId
    })
end)

---@param vehicleId integer
---@return boolean
local function isFinanced(vehicleId)
    return economyRunning() and exports.rp_economy:HasActiveLoan(vehicleId) == true
end
exports('IsFinanced', isFinanced)

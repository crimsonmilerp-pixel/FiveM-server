-- ============================================================
--  rp_buyers - server side
--  Works out what a player can sell, takes the items, and pays.
--  The server never trusts prices or amounts from the player's
--  game: everything comes from config.lua and the real inventory.
-- ============================================================
local config = require 'config'

local lastSale = {} -- [source] = time of last sale, stops spam-clicking

---Price in whole cents, so 0.10 + 0.20 doesn't turn into 0.30000000004.
local function toCents(price)
    return math.floor(price * 100 + 0.5)
end

---Is the player standing next to this buyer?
local function isNearBuyer(source, buyer)
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - buyer.coords.xyz) <= config.sellDistance + 1.0
end

---Finds the buyer and checks the player is allowed to deal with them right now.
local function getBuyer(source, buyerId)
    local buyer = type(buyerId) == 'string' and config.buyers[buyerId]
    if not buyer then return end
    if not exports.qbx_core:GetPlayer(source) then return end
    if not isNearBuyer(source, buyer) then return end
    return buyer
end

---What the player is carrying that this buyer wants.
local function buildOffer(source, buyer)
    local offer, totalCents = {}, 0
    for i, item in ipairs(buyer.items) do
        local count = exports.ox_inventory:GetItemCount(source, item.name) or 0
        local cents = toCents(item.price) * count
        offer[i] = { name = item.name, price = item.price, count = count, value = math.floor(cents / 100) }
        totalCents += cents
    end
    return offer, math.floor(totalCents / 100)
end

lib.callback.register('rp_buyers:server:getOffer', function(source, buyerId)
    local buyer = getBuyer(source, buyerId)
    if not buyer then return end

    local offer, total = buildOffer(source, buyer)
    return { items = offer, total = total }
end)

---Sells items. itemName = nil means "sell everything this buyer wants".
---Returns: true, amountPaid  or  false, errorKey
lib.callback.register('rp_buyers:server:sell', function(source, buyerId, itemName, amount)
    local now = GetGameTimer()
    if lastSale[source] and now - lastSale[source] < 1000 then return false, 'slow_down' end
    lastSale[source] = now

    local buyer = getBuyer(source, buyerId)
    if not buyer then return false, 'too_far' end

    -- Work out exactly what will be sold, using the real inventory.
    local toSell, totalCents = {}, 0
    for _, item in ipairs(buyer.items) do
        if not itemName or item.name == itemName then
            local have = exports.ox_inventory:GetItemCount(source, item.name) or 0
            local qty = have
            if itemName then
                qty = math.floor(tonumber(amount) or 0)
                if qty < 1 then return false, 'bad_amount' end
                if qty > have then return false, 'not_enough' end
            end
            if qty > 0 then
                toSell[#toSell + 1] = { name = item.name, qty = qty, cents = toCents(item.price) * qty }
            end
        end
    end

    if #toSell == 0 then return false, 'nothing_to_sell' end
    for _, sale in ipairs(toSell) do totalCents += sale.cents end
    if totalCents < 100 then return false, 'too_little' end -- under $1, so nobody loses items for $0

    -- Take the items. Only pay for what was actually removed.
    local paidCents = 0
    for _, sale in ipairs(toSell) do
        if exports.ox_inventory:RemoveItem(source, sale.name, sale.qty) then
            paidCents += sale.cents
        end
    end

    local pay = math.floor(paidCents / 100)
    if pay <= 0 then return false, 'nothing_to_sell' end

    local player = exports.qbx_core:GetPlayer(source)
    player.Functions.AddMoney(config.payAccount, pay, ('rp_buyers-%s'):format(buyerId))
    return true, pay
end)

AddEventHandler('playerDropped', function()
    lastSale[source] = nil
end)

-- ------------------------------------------------------------
-- /buyerhere (staff): copies your position, ready to paste into config.lua
-- ------------------------------------------------------------
lib.addCommand('buyerhere', { help = locale('command.buyerhere_help'), restricted = config.staffGroup }, function(source)
    TriggerClientEvent('rp_buyers:client:copyPosition', source)
end)

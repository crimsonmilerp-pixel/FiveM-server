-- ============================================================
--  rp_buyers - client side (runs in each player's game)
--  Spawns the buyer NPCs and shows the "sell" menu.
--  The server checks and pays for every sale.
-- ============================================================
local config = require 'config'

local peds = {} -- [buyerId] = ped handle, only while a player is nearby

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

---Money with cents only when needed: 4.7 -> "$4.70", 6 -> "$6".
local function money(amount)
    if amount % 1 == 0 then return ('$%d'):format(amount) end
    return ('$%.2f'):format(amount)
end

local function itemLabel(name)
    local item = exports.ox_inventory:Items(name)
    return item and item.label or name
end

local function buyerName(buyerId)
    return locale(('buyer.%s'):format(buyerId))
end

-- ------------------------------------------------------------
-- The sell menu
-- ------------------------------------------------------------
local openMenu

local function sell(buyerId, itemName, amount)
    local ok, result = lib.callback.await('rp_buyers:server:sell', false, buyerId, itemName, amount)
    if ok then
        lib.notify({
            title = buyerName(buyerId),
            description = locale('sold', money(result)),
            type = 'success',
            icon = 'hand-holding-dollar',
        })
    else
        lib.notify({ title = buyerName(buyerId), description = locale('error.' .. tostring(result)), type = 'error' })
        if result == 'too_far' then return end
    end
    openMenu(buyerId) -- show the updated menu
end

local function askAmount(buyerId, entry)
    local answer = lib.inputDialog(locale('amount.header', itemLabel(entry.name)), {
        {
            type = 'number',
            label = locale('amount.label'),
            description = locale('amount.desc', entry.count, money(entry.price)),
            default = entry.count,
            min = 1,
            max = entry.count,
            required = true,
        },
    })
    if not answer or not answer[1] then return openMenu(buyerId) end
    sell(buyerId, entry.name, math.floor(answer[1]))
end

openMenu = function(buyerId)
    local offer = lib.callback.await('rp_buyers:server:getOffer', false, buyerId)
    if not offer then
        return lib.notify({ title = buyerName(buyerId), description = locale('error.too_far'), type = 'error' })
    end

    local options = {}

    if offer.total > 0 then
        options[#options + 1] = {
            title = locale('menu.sell_all', money(offer.total)),
            description = locale('menu.sell_all_desc'),
            icon = 'sack-dollar',
            onSelect = function() sell(buyerId, nil) end,
        }
    end

    for _, entry in ipairs(offer.items) do
        local label = itemLabel(entry.name)
        if entry.count > 0 then
            options[#options + 1] = {
                title = locale('menu.item', label, money(entry.price)),
                description = locale('menu.item_have', entry.count, money(entry.value)),
                icon = 'box',
                onSelect = function() askAmount(buyerId, entry) end,
            }
        else
            -- Items they don't have are still listed, so players learn the prices.
            options[#options + 1] = {
                title = locale('menu.item', label, money(entry.price)),
                description = locale('menu.item_none'),
                icon = 'box-open',
                disabled = true,
            }
        end
    end

    lib.registerContext({
        id = 'rp_buyers_menu',
        title = buyerName(buyerId),
        options = options,
    })
    lib.showContext('rp_buyers_menu')
end

-- ------------------------------------------------------------
-- NPCs: spawn when a player comes near, remove when they leave
-- ------------------------------------------------------------

---Finds the ground under a spot, so outdoor buyers don't float or sink.
local function groundZ(coords)
    local fallback = coords.z - 1.0
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.5, false)
    if found and math.abs(z - fallback) < 3.0 then return z end
    return fallback
end

local function spawnBuyer(buyerId, buyer)
    if peds[buyerId] then return end

    local model = lib.requestModel(buyer.ped)
    if not model then return end

    local coords = buyer.coords
    local ped = CreatePed(0, model, coords.x, coords.y, groundZ(coords), coords.w, false, true)
    SetModelAsNoLongerNeeded(model)

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, true)
    if buyer.scenario then TaskStartScenarioInPlace(ped, buyer.scenario, 0, true) end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'rp_buyers_sell',
            icon = 'fa-solid fa-hand-holding-dollar',
            label = locale('target.sell'),
            distance = 2.5,
            onSelect = function() openMenu(buyerId) end,
        },
    })

    peds[buyerId] = ped
end

local function removeBuyer(buyerId)
    local ped = peds[buyerId]
    if not ped then return end
    if DoesEntityExist(ped) then
        exports.ox_target:removeLocalEntity(ped, 'rp_buyers_sell')
        DeleteEntity(ped)
    end
    peds[buyerId] = nil
end

for buyerId, buyer in pairs(config.buyers) do
    lib.points.new({
        coords = buyer.coords.xyz,
        distance = config.spawnDistance,
        onEnter = function() spawnBuyer(buyerId, buyer) end,
        onExit = function() removeBuyer(buyerId) end,
    })
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for buyerId in pairs(peds) do removeBuyer(buyerId) end
end)

-- ------------------------------------------------------------
-- /buyerhere (staff): copy your current spot for config.lua
-- ------------------------------------------------------------
RegisterNetEvent('rp_buyers:client:copyPosition', function()
    if GetInvokingResource() then return end -- only the server may trigger this
    local c = GetEntityCoords(cache.ped)
    local text = ('coords = vec4(%.2f, %.2f, %.2f, %.1f),'):format(c.x, c.y, c.z, GetEntityHeading(cache.ped))
    lib.setClipboard(text)
    lib.notify({ title = locale('copied.title'), description = locale('copied.description', text), type = 'inform', duration = 10000 })
end)

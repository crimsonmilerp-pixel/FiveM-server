local vehicles = {}
local blocklist = {}
local VEHICLES = exports.qbx_core:GetVehiclesByName()
local sharedConfig = require 'config.shared'.vehicles
local count = 0

-- [OUR CHANGE] Luxury cars ($100k+) go to the luxury shop and their own menu section. See docs/core-changes.md
local luxury = sharedConfig.luxury
local function isLuxury(vehicle)
    return luxury ~= nil and luxury.classes[vehicle.category] and (tonumber(vehicle.price) or 0) >= luxury.minPrice
end

local function insertVehicle(vehicleData, shopType, isLuxuryCar)
    count += 1
    vehicles[count] = {
        shopType = shopType,
        category = isLuxuryCar and luxury.category or vehicleData.category,
        model = vehicleData.model,
    }
end

for i = 1, #sharedConfig.blocklist do
    local blockveh = sharedConfig.blocklist[i]
    blocklist[blockveh] = true
end

for k, vehicle in pairs(VEHICLES) do
    local isLuxuryCar = not sharedConfig.models[k] and isLuxury(vehicle) -- [OUR CHANGE]
    local vehicleShop = sharedConfig.models[k] or (isLuxuryCar and luxury.shop) or sharedConfig.categories[vehicle.category] or sharedConfig.default

    if blocklist[k] then
        lib.print.debug('Vehicle is blocked. Skipping: ' .. k)
    elseif not vehicleShop then
        lib.print.debug('Vehicle not found in config. Skipping: ' .. k)
    else
        if type(vehicleShop) == 'table' then
            for i = 1, #vehicleShop do
                insertVehicle(vehicle, vehicleShop[i], isLuxuryCar)
            end
        else
            insertVehicle(vehicle, vehicleShop, isLuxuryCar)
        end
    end
end

return {
    vehicles = vehicles,
    count = count,
}

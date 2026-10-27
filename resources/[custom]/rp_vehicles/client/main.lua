-- ============================================================
--  rp_vehicles - client side
--  Applies the speed limit for the vehicle you're driving,
--  and gives emergency vehicles a small speed edge.
-- ============================================================
local config = require 'config'

local MPH_TO_MS = 0.44704 -- the game measures speed in meters per second
local EMERGENCY_CLASS = 18

local function applyLimits(vehicle)
    local class = GetVehicleClass(vehicle)
    local capMph = config.speedCapsMph[class]

    if class == EMERGENCY_CLASS and config.emergencyBoost > 0 then
        SetVehicleModKit(vehicle, 0)
        ModifyVehicleTopSpeed(vehicle, config.emergencyBoost)
    end

    if capMph then
        SetVehicleMaxSpeed(vehicle, capMph * MPH_TO_MS)
    end
end

-- Re-apply every couple of seconds while driving (the game can reset it when a car changes hands).
CreateThread(function()
    while true do
        local vehicle = cache.vehicle
        if vehicle and cache.seat == -1 then
            applyLimits(vehicle)
            Wait(2000)
        else
            Wait(1000)
        end
    end
end)

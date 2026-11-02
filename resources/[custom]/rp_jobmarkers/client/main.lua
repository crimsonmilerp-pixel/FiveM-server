-- ============================================================
--  rp_jobmarkers - client side (runs in each player's game)
--  Draws the "Work" markers and shows a sign-up hint near depots.
-- ============================================================
local config = require 'config'

local blips = {}       -- [job] = blip
local hinted = {}      -- [job] = true once the hint was shown this session

local function currentJob()
    return QBX and QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.name
end

local function refreshMarkers()
    local myJob = currentJob()
    for _, m in ipairs(config.markers) do
        local wanted = m.job ~= myJob -- the job's own script shows its marker to people who have it
        if wanted and not blips[m.job] then
            local blip = AddBlipForCoord(m.coords.x, m.coords.y, m.coords.z)
            SetBlipSprite(blip, m.sprite)
            SetBlipColour(blip, m.colour)
            SetBlipScale(blip, config.scale)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(locale('marker.' .. m.job))
            EndTextCommandSetBlipName(blip)
            blips[m.job] = blip
        elseif not wanted and blips[m.job] then
            RemoveBlip(blips[m.job])
            blips[m.job] = nil
        end
    end
end

-- A friendly hint when someone without the job shows up at a depot.
for _, m in ipairs(config.markers) do
    lib.points.new({
        coords = m.coords,
        distance = config.hintDistance,
        onEnter = function()
            if hinted[m.job] or currentJob() == m.job or not LocalPlayer.state.isLoggedIn then return end
            hinted[m.job] = true
            lib.notify({
                title = locale('hint.title'),
                description = locale('hint.text', locale('job.' .. m.job)),
                type = 'inform',
                icon = 'briefcase',
                duration = 12000,
            })
        end,
    })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() SetTimeout(1000, refreshMarkers) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function() SetTimeout(500, refreshMarkers) end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= cache.resource then return end
    refreshMarkers()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for _, blip in pairs(blips) do RemoveBlip(blip) end
end)

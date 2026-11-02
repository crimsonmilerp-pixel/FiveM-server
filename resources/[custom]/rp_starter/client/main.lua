-- ============================================================
--  rp_starter - client side (runs in each player's game)
--  The volunteer and kiosk NPCs, the vehicle picker, and the
--  guided tour (notification, GPS and map marker for each step).
--  The server checks and saves every step.
-- ============================================================
local config = require 'config'

local status        -- what the server last told us about this character's tour
local stepPoint     -- the "you've arrived" zone for the current 'visit' step
local stepBlip      -- map marker for the current step
local peds = {}     -- volunteer and kiosk NPCs, only while nearby

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function notify(description, kind, duration)
    lib.notify({ title = locale('title'), description = description, type = kind or 'inform', duration = duration or 10000, icon = 'route' })
end

local function stepConfig(id)
    for _, step in ipairs(config.steps) do
        if step.id == id then return step end
    end
end

local function stepNumber(id)
    for i, step in ipairs(config.steps) do
        if step.id == id then return i end
    end
    return 0
end

---Where the current step happens.
local function stepCoords(id)
    if id == 'greet' or id == 'vehicle' then return config.volunteer.coords end
    if id == 'kiosk' then return config.kiosk.coords end
    local step = stepConfig(id)
    return step and step.coords
end

local function clearStepMarkers()
    if stepPoint then stepPoint:remove() stepPoint = nil end
    if stepBlip and DoesBlipExist(stepBlip) then RemoveBlip(stepBlip) end
    stepBlip = nil
end

---Waits until nothing else is on screen (clothing editor, goal screen, loading, pause menu).
local function waitForClearScreen()
    local clearFor = 0
    while clearFor < 1500 do
        Wait(250)
        local busy = IsNuiFocused() or IsPauseMenuActive() or not IsScreenFadedIn() or IsPlayerSwitchInProgress()
            or not LocalPlayer.state.isLoggedIn
        clearFor = busy and 0 or clearFor + 250
    end
end

-- ------------------------------------------------------------
-- The tour
-- ------------------------------------------------------------
local showStep

local function advance(stepId)
    local newStatus = lib.callback.await('rp_starter:server:advance', false, stepId)
    if newStatus then
        status = newStatus
        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false)
        showStep()
    end
end

local finishShown = false -- the final screen shows once per session, no matter what

local function finishTour()
    if finishShown then return end
    finishShown = true
    clearStepMarkers()

    local mine = GetResourceState('rp_goals') == 'started' and lib.callback.await('rp_goals:server:getMine', false)
    local firstStep = mine and mine.goal and mine.goal.firstStep

    lib.alertDialog({
        header = locale('step.goal.title'),
        content = firstStep and locale('step.goal.text', firstStep) or locale('step.goal.text_nogoal'),
        centered = true,
        size = 'lg',
        labels = { confirm = locale('step.goal.button') },
    })
    local newStatus = lib.callback.await('rp_starter:server:advance', false, 'goal')
    status = newStatus or { done = true }
end

showStep = function()
    clearStepMarkers()
    if not status or status.done then return end

    local id = status.step
    if id == 'goal' then return finishTour() end

    local coords = stepCoords(id)
    local total = #config.steps

    notify(locale('step.progress', stepNumber(id), total) .. '\n' .. locale(('step.%s.text'):format(id)), 'inform', 15000)

    if coords then
        stepBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(stepBlip, 280)
        SetBlipColour(stepBlip, 5)
        SetBlipRoute(stepBlip, true)
        SetBlipRouteColour(stepBlip, 5)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(locale(('step.%s.blip'):format(id)))
        EndTextCommandSetBlipName(stepBlip)
    end

    -- 'visit' steps finish when you arrive.
    local step = stepConfig(id)
    if step and step.radius then
        stepPoint = lib.points.new({
            coords = step.coords,
            distance = step.radius,
            onEnter = function() advance(id) end,
        })
    end
end

local function refreshStatus()
    status = lib.callback.await('rp_starter:server:status', false)
    return status
end

---Starts or resumes the tour, if this character has one going.
local function startTour()
    for _ = 1, 5 do -- the server may still be saving a brand-new character
        if refreshStatus() then break end
        Wait(2000)
    end
    if not status or status.done then return end
    waitForClearScreen()
    showStep()
    if status.canSkip and status.step == 'greet' then
        notify(locale('skip.hint'), 'inform', 12000)
    end
end

-- A brand-new character: register them for the tour right away (while the clothing editor is open).
AddEventHandler('qb-clothes:client:CreateFirstCharacter', function()
    TriggerServerEvent('rp_starter:server:newCharacter')
end)

-- The tour starts once they've committed to their goal (rp_goals).
AddEventHandler('rp_goals:client:goalSaved', function(mode)
    if mode == 'create' then CreateThread(startTour) end
end)

-- Coming back to a character mid-tour (or rp_goals isn't running).
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(3000)
        if not refreshStatus() or status.done then return end
        if GetResourceState('rp_goals') == 'started' then
            local mine = lib.callback.await('rp_goals:server:getMine', false)
            if mine and mine.loaded and not mine.goal then return end -- goalSaved will start it
        end
        startTour()
    end)
end)

-- The server sends this one on logout, so it must be a RegisterNetEvent (AddEventHandler never heard it).
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    clearStepMarkers()
    status = nil
end)

RegisterNetEvent('rp_starter:client:showStep', function()
    if GetInvokingResource() then return end
    if not refreshStatus() or status.done then return notify(locale('error.no_tour'), 'inform') end
    showStep()
end)

RegisterNetEvent('rp_starter:client:skip', function()
    if GetInvokingResource() then return end
    local ok, result = lib.callback.await('rp_starter:server:skip', false)
    if not ok then return notify(locale('error.' .. tostring(result)), 'error') end
    clearStepMarkers()
    refreshStatus()
    notify(result and locale('skip.done') or locale('skip.done_no_vehicle'), 'success', 12000)
end)

-- ------------------------------------------------------------
-- The free starter vehicle
-- ------------------------------------------------------------
local function claimVehicle(model)
    local label = locale(('vehicle.%s.label'):format(model))
    local answer = lib.alertDialog({
        header = locale('vehicle.confirm_header', label),
        content = locale('vehicle.confirm_text', label),
        centered = true,
        cancel = true,
        labels = { confirm = locale('vehicle.confirm_yes'), cancel = locale('vehicle.confirm_no') },
    })
    if answer ~= 'confirm' then return end

    DoScreenFadeOut(300)
    Wait(400)
    local ok, plate, newStatus = lib.callback.await('rp_starter:server:claimVehicle', false, model)
    DoScreenFadeIn(500)

    if not ok then return notify(locale('error.' .. tostring(plate)), 'error') end
    notify(locale('vehicle.claimed', label, plate), 'success', 12000)
    if newStatus then
        status = newStatus
        Wait(3000)
        showStep()
    end
end

local function vehicleMenu()
    local options = {}
    for _, v in ipairs(config.vehicles) do
        options[#options + 1] = {
            title = locale(('vehicle.%s.label'):format(v.model)),
            description = locale(('vehicle.%s.desc'):format(v.model)),
            icon = v.kind == 'motorcycle' and 'motorcycle' or (v.kind == 'truck' and 'truck-pickup' or 'car'),
            onSelect = function() claimVehicle(v.model) end,
        }
    end
    lib.registerContext({ id = 'rp_starter_vehicles', title = locale('vehicle.menu_title'), options = options })
    lib.showContext('rp_starter_vehicles')
end

local function talkToVolunteer()
    refreshStatus()
    lib.alertDialog({
        header = locale('volunteer.header'),
        content = locale('volunteer.intro'),
        centered = true,
        size = 'lg',
        labels = { confirm = locale('volunteer.button') },
    })
    if status and not status.done and status.step == 'greet' then
        advance('greet')
    end
end

-- ------------------------------------------------------------
-- NPCs: spawn when someone comes near, remove when they leave
-- ------------------------------------------------------------
local function groundZ(coords)
    local fallback = coords.z - 1.0
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.5, false)
    if found and math.abs(z - fallback) < 3.0 then return z end
    return fallback
end

local function spawnNpc(key, npc, targetOptions)
    if peds[key] then return end
    local model = lib.requestModel(npc.ped)
    if not model then return end
    local c = npc.coords
    local ped = CreatePed(0, model, c.x, c.y, groundZ(c), c.w, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    FreezeEntityPosition(ped, true)
    if npc.scenario then TaskStartScenarioInPlace(ped, npc.scenario, 0, true) end
    exports.ox_target:addLocalEntity(ped, targetOptions)
    peds[key] = ped
end

local function removeNpc(key)
    local ped = peds[key]
    if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    peds[key] = nil
end

local volunteerOptions = {
    {
        name = 'rp_starter_talk',
        icon = 'fa-solid fa-comments',
        label = locale('volunteer.target_talk'),
        distance = 2.5,
        onSelect = talkToVolunteer,
    },
    {
        name = 'rp_starter_vehicle',
        icon = 'fa-solid fa-key',
        label = locale('volunteer.target_vehicle'),
        distance = 2.5,
        canInteract = function() return status ~= nil and not status.vehicleClaimed end,
        onSelect = vehicleMenu,
    },
}

local kioskOptions = {
    {
        name = 'rp_starter_kiosk',
        icon = 'fa-solid fa-basket-shopping',
        label = locale('kiosk.target'),
        distance = 2.5,
        onSelect = function()
            exports.ox_inventory:openInventory('shop', { type = 'rp_starter_kiosk', id = 1 })
            if status and not status.done and status.step == 'kiosk' then
                CreateThread(function() advance('kiosk') end)
            end
        end,
    },
}

lib.points.new({
    coords = config.volunteer.coords.xyz,
    distance = 60.0,
    onEnter = function()
        if not status then refreshStatus() end
        spawnNpc('volunteer', config.volunteer, volunteerOptions)
    end,
    onExit = function() removeNpc('volunteer') end,
})

lib.points.new({
    coords = config.kiosk.coords.xyz,
    distance = 60.0,
    onEnter = function() spawnNpc('kiosk', config.kiosk, kioskOptions) end,
    onExit = function() removeNpc('kiosk') end,
})

-- A permanent map marker for the bus station, so new players can always find their way back.
CreateThread(function()
    local c = config.volunteer.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, 513)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.75)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(locale('blip.station'))
    EndTextCommandSetBlipName(blip)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    clearStepMarkers()
    for key in pairs(peds) do removeNpc(key) end
end)

-- If the resource restarts while someone is playing, pick their tour back up.
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= cache.resource or not LocalPlayer.state.isLoggedIn then return end
    CreateThread(function()
        if refreshStatus() and not status.done then showStep() end
    end)
end)

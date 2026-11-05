-- ============================================================
--  rp_clothing_images - the photo tool (staff only, dev server)
--  /clothingphotos            photograph every clothing item, man and woman (about half an hour)
--  /clothingphotos male c11   only one body and one slot (see config.lua for the slot names)
--  /clothingphotos male all 5 quick test: only the first 5 items of every slot
--  /clothingphotos stop       stop after the current picture
--
--  The mannequin stands on a green floor in front of a green backdrop. For every slot we first
--  photograph the empty mannequin and the empty scene; each item photo is compared with those,
--  so only the item is kept. Pictures are packed into one sheet per slot (img/male_c11.webp)
--  and listed in img/index.json, which the clothing menus read.
-- ============================================================
local running, stopping = false, false
local cam
local backdrop -- { sphere = vector3, disc = vector3 }
local groundZ
local pedHeading -- the mannequin is held at this heading the whole time

local function log(text, ...)
    print(('[clothingphotos] ' .. text):format(...))
end

local function waitFrames(n)
    for _ = 1, n do Wait(0) end
end

-- ------------------------------------------------------------
-- Talking to our NUI page (it does the image work) and to screencapture
-- ------------------------------------------------------------
local nuiWaiting, nuiNext = {}, 0

RegisterNUICallback('result', function(data, cb)
    cb(1)
    local p = data and nuiWaiting[data.id]
    if p then
        nuiWaiting[data.id] = nil
        p:resolve(data.result or {})
    end
end)

local function nui(action, payload, timeoutMs)
    nuiNext += 1
    local id = nuiNext
    local p = promise.new()
    nuiWaiting[id] = p
    SendNUIMessage({ action = action, id = id, payload = payload })
    SetTimeout(timeoutMs or 20000, function()
        if nuiWaiting[id] then
            nuiWaiting[id] = nil
            p:resolve({ error = 'timeout' })
        end
    end)
    return Citizen.Await(p)
end

local function screenshot()
    local p, settled = promise.new(), false
    exports.screencapture:requestScreenshot({ encoding = 'png', maxWidth = Config.Width, maxHeight = Config.Height }, function(data)
        if settled then return end
        settled = true
        p:resolve(data)
    end)
    SetTimeout(10000, function()
        if settled then return end
        settled = true
        p:resolve(nil)
    end)
    local data = Citizen.Await(p)
    if type(data) ~= 'string' or not data:find('^data:image') then return nil end
    return data
end

-- ------------------------------------------------------------
-- Scene: frozen weather, green floor and backdrop, no HUD
-- ------------------------------------------------------------
local function sceneThread()
    CreateThread(function()
        while running do
            HideHudAndRadarThisFrame()
            DisableAllControlActions(0)
            local ped = PlayerPedId()
            -- clearing tasks every frame keeps the mannequin perfectly still (no breathing or idle moves);
            -- then its heading is put back, so the camera stays in front of it
            ClearPedTasksImmediately(ped)
            if pedHeading then SetEntityHeading(ped, pedHeading) end
            NetworkOverrideClockTime(Config.Hour, 0, 0)
            if backdrop then
                -- big green ball behind the mannequin (radius 10 m), and a flattened green ball on the ground
                -- under it (radius 4 m, 3 cm high) so shadows on the ground don't show
                DrawMarker(28, backdrop.sphere.x, backdrop.sphere.y, backdrop.sphere.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    10.0, 10.0, 10.0, 0, 255, 0, 255, false, false, 2, false, nil, nil, false)
                DrawMarker(28, backdrop.disc.x, backdrop.disc.y, backdrop.disc.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    4.0, 4.0, 0.03, 0, 255, 0, 255, false, false, 2, false, nil, nil, false)
            end
            Wait(0)
        end
    end)
end

local function setWeather()
    TriggerEvent('qb-weathersync:client:DisableSync')
    LocalPlayer.state:set('playerWeather', Config.Weather, false)
    Wait(300)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(Config.Weather)
    SetRainLevel(0.0)
    SetWind(0.0)
    NetworkOverrideClockMillisecondsPerGameMinute(99999999)
    NetworkOverrideClockTime(Config.Hour, 0, 0)
end

---Which way the mannequin's body really faces, worked out from its shoulders.
---(Holding it still with ClearPedTasksImmediately can leave the body turned away from where the game
---says the mannequin is facing, which is why earlier runs photographed the back.)
local function bodyFacing(ped)
    local l = GetPedBoneCoords(ped, 45509, 0.0, 0.0, 0.0) -- SKEL_L_UpperArm
    local r = GetPedBoneCoords(ped, 40269, 0.0, 0.0, 0.0) -- SKEL_R_UpperArm
    local rx, ry = r.x - l.x, r.y - l.y
    local len = math.sqrt(rx * rx + ry * ry)
    if len < 0.1 then
        local f = GetEntityForwardVector(ped)
        return f.x, f.y, 'game'
    end
    -- forward = the left-to-right shoulder line turned a quarter to the left
    return -ry / len, rx / len, 'shoulders'
end

---Camera in front of the mannequin's body, turned `yawDeg` degrees around it.
---The green ball goes on the opposite side.
local function setCamera(ped, slot, yawDeg)
    local base = GetEntityCoords(ped)
    local fx, fy, how = bodyFacing(ped)
    local yaw = math.rad(yawDeg or 0)
    local dx = fx * math.cos(yaw) - fy * math.sin(yaw)
    local dy = fx * math.sin(yaw) + fy * math.cos(yaw)
    local d = Config.CameraDistance
    local target = vector3(base.x, base.y, base.z + slot.z)
    local pos = vector3(target.x + dx * d, target.y + dy * d, target.z)

    if cam then DestroyCam(cam, false) end
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, slot.fov + 0.0, false, 0)
    PointCamAtCoord(cam, target.x, target.y, target.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    backdrop = {
        sphere = vector3(target.x - dx * 12.0, target.y - dy * 12.0, target.z),
        disc = vector3(base.x, base.y, groundZ),
    }
    if slot.key == Config.Slots[1].key and (yawDeg or 0) == 0 then
        log('body faces %.0f (by its %s), game says %.0f', (math.deg(math.atan(-fx, fy)) + 360) % 360, how, GetEntityHeading(ped))
    end
end

-- ------------------------------------------------------------
-- The mannequin
-- ------------------------------------------------------------
local ALL_COMPONENTS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
local ALL_PROPS = { 0, 1, 2, 6, 7 }

local function bareMannequin(ped)
    for _, id in ipairs(ALL_COMPONENTS) do SetPedComponentVariation(ped, id, -1, 0, 0) end
    for _, id in ipairs(ALL_PROPS) do ClearPedProp(ped, id) end
    SetPedHairColor(ped, 3, 3)
end

local function setModel(gender)
    local model = gender == 'male' and `mp_m_freemode_01` or `mp_f_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    SetPlayerModel(PlayerId(), model)
    Wait(300)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    if gender == 'male' then
        SetPedHeadBlendData(ped, 21, 0, 0, 21, 0, 0, 0.75, 0.5, 0.0, false)
    else
        SetPedHeadBlendData(ped, 21, 0, 0, 21, 0, 0, 0.25, 0.5, 0.0, false)
    end
    -- a few cm above the ground, so the shoes stand clear of the green floor
    SetEntityCoordsNoOffset(ped, Config.Spot.x, Config.Spot.y, groundZ + 1.05, false, false, false)
    ClearPedTasksImmediately(ped)
    pedHeading = Config.Spot.w
    SetEntityHeading(ped, pedHeading)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanPlayAmbientAnims(ped, false)
    SetPedCanPlayAmbientBaseAnims(ped, false)
    bareMannequin(ped)
    Wait(500)
    log('%s mannequin facing %.0f (asked for %.0f)', gender, GetEntityHeading(ped), pedHeading)
    return ped
end

---Numbers in a clothing pack we skip (police uniforms), as a set.
local function skipped(ped, slot)
    local out = {}
    for _, name in ipairs(Config.SkipCollections) do
        local count, first
        if slot.kind == 'p' then
            count = GetNumberOfPedCollectionPropDrawableVariations(ped, slot.id, name)
            first = GetPedPropGlobalIndexFromCollection(ped, slot.id, name, 0)
        else
            count = GetNumberOfPedCollectionDrawableVariations(ped, slot.id, name)
            first = GetPedDrawableGlobalIndexFromCollection(ped, slot.id, name, 0)
        end
        if count and count > 0 and first and first >= 0 then
            for d = first, first + count - 1 do out[d] = true end
        end
    end
    return out
end

local function putOn(ped, slot, drawable)
    local started = GetGameTimer()
    if slot.kind == 'p' then
        SetPedPreloadPropData(ped, slot.id, drawable, 0)
        while not HasPedPreloadPropDataFinished(ped) and GetGameTimer() - started < 4000 do Wait(0) end
        SetPedPropIndex(ped, slot.id, drawable, 0, true)
        ReleasePedPreloadPropData(ped)
    else
        SetPedPreloadVariationData(ped, slot.id, drawable, 0)
        while not HasPedPreloadVariationDataFinished(ped) and GetGameTimer() - started < 4000 do Wait(0) end
        SetPedComponentVariation(ped, slot.id, drawable, 0, 0)
        ReleasePedPreloadVariationData(ped)
    end
    waitFrames(5)
end

local function takeOff(ped, slot)
    if slot.kind == 'p' then ClearPedProp(ped, slot.id) else SetPedComponentVariation(ped, slot.id, -1, 0, 0) end
    waitFrames(5)
end

---Photos of the empty mannequin (5, a little apart, to see if anything moves by itself) and of the empty scene.
local function baselines(ped, view)
    nui('baselines_reset', { view = view })
    for _ = 1, 5 do
        waitFrames(8)
        local shot = screenshot()
        if shot then nui('baseline', { view = view, kind = 'A', image = shot }) end
        Wait(300)
    end
    SetEntityVisible(ped, false, false)
    waitFrames(8)
    local shot = screenshot()
    if shot then nui('baseline', { view = view, kind = 'B', image = shot }) end
    SetEntityVisible(ped, true, false)
    waitFrames(8)
end

-- ------------------------------------------------------------
-- Which tops come with matching arms (for the arms report)
-- ------------------------------------------------------------
local function armsReport(ped, gender, drawable, report)
    local hash = GetHashNameForComponent(ped, 11, drawable, 0)
    if not hash or hash == 0 then report.noName += 1 return end
    local n = GetShopPedApparelForcedComponentCount(hash)
    local found = false
    for i = 0, n - 1 do
        local nameHash, enumValue, componentId = GetForcedComponent(hash, i)
        if componentId == 3 then
            found = true
            if nameHash ~= 0 then report.byName += 1 elseif enumValue and enumValue >= 0 then report.byNumber += 1 else report.unknown += 1 end
        end
    end
    if not found then report.noArms += 1 end
end

-- ------------------------------------------------------------
-- Sending a finished picture sheet to the server
-- A sheet is a few MB. Sent in one go it overflows the game's event channel and the server
-- kicks you ("latent event packet overflow"), so it goes in small parts, each one confirmed.
-- ------------------------------------------------------------
local PART_SIZE = 64000   -- characters per part
local PART_BPS = 200000  -- bytes per second
local acks = {}

RegisterNetEvent('rp_clothing_images:client:ack', function(name, part)
    acks[('%s:%s'):format(name, part)] = true
end)

local function waitAck(name, part)
    local key = ('%s:%s'):format(name, part)
    local started = GetGameTimer()
    while not acks[key] do
        if GetGameTimer() - started > 30000 then return false end
        Wait(20)
    end
    acks[key] = nil
    return true
end

local function uploadSheet(name, data, metaJson)
    local total = math.ceil(#data / PART_SIZE)
    for i = 1, total do
        TriggerLatentServerEvent('rp_clothing_images:server:sheetPart', PART_BPS, name, i, total, data:sub((i - 1) * PART_SIZE + 1, i * PART_SIZE))
        if not waitAck(name, i) then return false, ('no answer from the server for part %d of %d'):format(i, total) end
    end
    TriggerLatentServerEvent('rp_clothing_images:server:sheetDone', PART_BPS, name, metaJson)
    if not waitAck(name, 0) then return false, 'the server did not save the sheet' end
    return true
end

-- ------------------------------------------------------------
-- One slot
-- ------------------------------------------------------------
local function photographSlot(ped, gender, slot, report, limit)
    local count = slot.kind == 'p' and GetNumberOfPedPropDrawableVariations(ped, slot.id) or GetNumberOfPedDrawableVariations(ped, slot.id)
    local skip = skipped(ped, slot)
    local name = ('%s_%s'):format(gender, slot.key)
    log('%s: %d items', name, count)
    nui('begin', { name = name, count = count, tile = Config.Tile, cols = Config.Columns, mode = slot.mode })

    -- most slots have one camera angle; earrings have two (left and right ear), and each item keeps the better one
    local views = slot.yaws or { slot.yaw or 0 }
    for view, yaw in ipairs(views) do
        if stopping then break end
        bareMannequin(ped)
        waitFrames(10)
        setCamera(ped, slot, yaw)
        waitFrames(30)
        baselines(ped, view)

        local done = 0
        for drawable = 0, count - 1 do
            if stopping or (limit and done >= limit) then break end
            if not skip[drawable] then
                if report and view == 1 and slot.key == 'c11' then armsReport(ped, gender, drawable, report) end
                putOn(ped, slot, drawable)
                local shot = screenshot()
                local result = shot and nui('shot', { view = view, drawable = drawable, image = shot }) or { empty = true }
                if result.empty then
                    -- maybe it had not loaded yet: one more try
                    Wait(600)
                    shot = screenshot()
                    if shot then result = nui('shot', { view = view, drawable = drawable, image = shot }) end
                end
                done += 1
                if done % 50 == 0 then log('%s: %d/%d', name, drawable + 1, count) end
                if done % 80 == 0 then
                    takeOff(ped, slot)
                    baselines(ped, view) -- light can drift a little over time
                end
            end
        end
        takeOff(ped, slot)
    end

    local sheet = nui('finish', {}, 60000)
    if sheet and sheet.data and sheet.meta and sheet.metaJson then
        local ok, err = uploadSheet(name, sheet.data, sheet.metaJson)
        if ok then
            log('%s saved: %d pictures, %d empty, %d broken', name, sheet.meta.count or 0, #(sheet.meta.empty or {}), #(sheet.meta.broken or {}))
        else
            log('%s FAILED to save: %s', name, err)
        end
        for kind, jpeg in pairs(sheet.debug or {}) do
            uploadSheet(('debug_%s_%s'):format(name, kind), jpeg, '{}')
        end
    else
        log('%s FAILED: %s', name, sheet and sheet.error or 'no picture sheet')
    end
end

-- ------------------------------------------------------------
-- Start / stop
-- ------------------------------------------------------------
RegisterNetEvent('rp_clothing_images:client:start', function(genderArg, slotArg, limitArg)
    local limit = tonumber(limitArg)
    if limit and limit < 1 then limit = nil end
    if running then return end
    if GetResourceState('screencapture') ~= 'started' then
        log('screencapture is not running, start it first')
        TriggerServerEvent('rp_clothing_images:server:done')
        return
    end
    running, stopping = true, false

    local ped = PlayerPedId()
    local startCoords, startHeading = GetEntityCoords(ped), GetEntityHeading(ped)
    local genders = (genderArg == 'male' or genderArg == 'female') and { genderArg } or { 'male', 'female' }
    local slots = {}
    for _, slot in ipairs(Config.Slots) do
        if not slotArg or slotArg == 'all' or slotArg == slot.key then slots[#slots + 1] = slot end
    end
    if #slots == 0 then
        log('unknown slot %s', tostring(slotArg))
        running = false
        TriggerServerEvent('rp_clothing_images:server:done')
        return
    end

    DoScreenFadeOut(500)
    Wait(600)
    DisplayRadar(false)
    DisplayHud(false)
    setWeather()
    RequestCollisionAtCoord(Config.Spot.x, Config.Spot.y, Config.Spot.z)
    SetEntityCoordsNoOffset(ped, Config.Spot.x, Config.Spot.y, Config.Spot.z, false, false, false)
    local t = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() - t < 5000 do Wait(0) end
    local found, z = GetGroundZFor_3dCoord(Config.Spot.x, Config.Spot.y, Config.Spot.z + 2.0, false)
    groundZ = found and z or Config.Spot.z
    sceneThread()
    Wait(500)
    DoScreenFadeIn(500)
    Wait(600)

    local started = GetGameTimer()
    local report = { noName = 0, byName = 0, byNumber = 0, unknown = 0, noArms = 0 }
    for _, gender in ipairs(genders) do
        if stopping then break end
        ped = setModel(gender)
        for _, slot in ipairs(slots) do
            if stopping then break end
            photographSlot(ped, gender, slot, report, limit)
        end
    end
    log('arms report (tops): %d with arms by name, %d by number, %d unknown, %d without arms, %d without a shop name',
        report.byName, report.byNumber, report.unknown, report.noArms, report.noName)
    if report.byName + report.byNumber + report.noArms + report.noName > 0 then
        TriggerServerEvent('rp_clothing_images:server:report', report)
    end

    -- put everything back
    running = false
    backdrop = nil
    pedHeading = nil
    Wait(100)
    RenderScriptCams(false, false, 0, true, false)
    if cam then DestroyCam(cam, false) cam = nil end
    DoScreenFadeOut(300)
    Wait(400)
    ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityCoordsNoOffset(ped, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityHeading(ped, startHeading)
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerServerEvent('rp_clothing_images:server:done')
    TriggerEvent('illenium-appearance:client:reloadSkin', true)
    DisplayRadar(true)
    DisplayHud(true)
    Wait(800)
    DoScreenFadeIn(500)
    log('finished in %d minutes%s. Restart rp_clothing_images to show the new pictures.', math.floor((GetGameTimer() - started) / 60000), stopping and ' (stopped early)' or '')
end)

RegisterNetEvent('rp_clothing_images:client:stop', function()
    if running then
        stopping = true
        log('stopping after this picture...')
    end
end)

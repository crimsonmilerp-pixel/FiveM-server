-- ============================================================
-- [OUR CHANGE] Nov 4, 2026: our character creator and the extras our menus need.
--
--  * AskIdentity(opts)      qbx_core calls this for a new character: name, birthday, nationality, man/woman.
--  * CreateAppearance(g)    right after the character exists: face, hair and clothes in one go.
--  * Arms are matched to the top automatically (the game knows which arms fit each top).
--  * Staff can hide clothing that clips or looks broken; hidden items disappear for everyone else.
--
-- The screens themselves are in web/dist (our own menus). See docs/core-changes.md
-- ============================================================
local client = client

local STAFF_REFRESH_MS = 60000

-- A friendly starting face and hair, so nobody starts bald with a blank face.
local STARTER_LOOK = {
    Male = {
        headBlend = { shapeFirst = 21, shapeSecond = 0, shapeThird = 0, skinFirst = 21, skinSecond = 0, skinThird = 0, shapeMix = 0.75, skinMix = 0.5, thirdMix = 0.0 },
        hair = { style = 4, texture = 0, color = 2, highlight = 2 },
    },
    Female = {
        headBlend = { shapeFirst = 21, shapeSecond = 0, shapeThird = 0, skinFirst = 21, skinSecond = 0, skinThird = 0, shapeMix = 0.25, skinMix = 0.5, thirdMix = 0.0 },
        hair = { style = 4, texture = 0, color = 2, highlight = 2 },
    },
}

local function genderKey(gender)
    if gender == 1 or gender == '1' or gender == 'Female' or gender == 'female' then return 'Female' end
    return 'Male'
end

-- ------------------------------------------------------------
-- Arms that fit the top
-- ------------------------------------------------------------
local shopNameCache = {} -- [model][componentId] = { [nameHash] = { drawable, texture } }

local function u32(value)
    return (value or 0) & 0xFFFFFFFF
end

---Every arms (3) or undershirt (8) item of this body, looked up by the game's own item name.
local function shopNames(ped, componentId)
    local model = GetEntityModel(ped)
    shopNameCache[model] = shopNameCache[model] or {}
    local map = shopNameCache[model][componentId]
    if map then return map end

    map = {}
    for drawable = 0, GetNumberOfPedDrawableVariations(ped, componentId) - 1 do
        local textures = math.max(GetNumberOfPedTextureVariations(ped, componentId, drawable), 1)
        for texture = 0, textures - 1 do
            local hash = u32(GetHashNameForComponent(ped, componentId, drawable, texture))
            if hash ~= 0 and not map[hash] then map[hash] = { drawable, texture } end
        end
    end
    shopNameCache[model][componentId] = map
    return map
end

---Puts on the arms (and undershirt, if needed) that the game says belong to the current top.
---Returns the changes so the menu can show them, e.g. { { component_id = 3, drawable = 4, texture = 0 } }.
function client.rpMatchTop(ped)
    ped = ped or cache.ped
    if not client.isPedFreemodeModel(ped) then return {} end

    local topHash = GetHashNameForComponent(ped, 11, GetPedDrawableVariation(ped, 11), GetPedTextureVariation(ped, 11))
    if not topHash or topHash == 0 then return {} end

    local changed = {}
    for i = 0, GetShopPedApparelForcedComponentCount(topHash) - 1 do
        local nameHash, enumValue, componentId = GetForcedComponent(topHash, i)
        if componentId == 3 or componentId == 8 then
            local hit
            if nameHash and nameHash ~= 0 then
                hit = shopNames(ped, componentId)[u32(nameHash)]
            elseif enumValue and enumValue >= 0 and enumValue < GetNumberOfPedDrawableVariations(ped, componentId) then
                hit = { enumValue, 0 } -- base game items are stored by number instead of by name
            end
            if hit then
                SetPedComponentVariation(ped, componentId, hit[1], hit[2], 0)
                changed[#changed + 1] = { component_id = componentId, drawable = hit[1], texture = hit[2] }
            end
        end
    end
    return changed
end

-- ------------------------------------------------------------
-- Clothing hidden by staff
-- ------------------------------------------------------------
local hiddenCache, hiddenAt = nil, -STAFF_REFRESH_MS

---{ staff = bool, male = { c11 = { 7, 8 } }, female = { ... } }
local function getHidden()
    if not hiddenCache or GetGameTimer() - hiddenAt > STAFF_REFRESH_MS then
        hiddenCache = lib.callback.await('illenium-appearance:server:rpHidden', false) or { staff = false }
        hiddenAt = GetGameTimer()
    end
    return hiddenCache
end

RegisterNetEvent('illenium-appearance:client:rpHiddenChanged', function()
    hiddenCache = nil
end)

---Called from game/customization.lua: adds the hidden items to the blacklist (not for staff, they see everything).
function client.rpAddHidden(blacklistSettings, kind, slotId)
    local hidden = getHidden()
    if hidden.staff then return blacklistSettings end
    local list = hidden[client.getPedDecorationType()]
    local items = list and list[kind .. slotId]
    if items then
        for i = 1, #items do
            blacklistSettings.drawables[#blacklistSettings.drawables + 1] = items[i]
        end
    end
    return blacklistSettings
end

RegisterNUICallback('rp_get_extras', function(_, cb)
    local conf = client.getConfig() or {}
    if conf.headBlend then
        RequestStreamedTextureDict('char_creator_portraits', false) -- the parent pictures
    end
    local hidden = getHidden()
    local gender = client.getPedDecorationType()
    cb({
        gender = gender,
        isStaff = hidden.staff == true,
        hidden = hidden.staff and hidden[gender] or {},
    })
end)

RegisterNUICallback('rp_hide_item', function(data, cb)
    local gender = client.getPedDecorationType()
    local result = lib.callback.await('illenium-appearance:server:rpHideItem', false, {
        gender = gender,
        kind = data and data.kind,
        slot = data and data.slot,
        drawable = data and data.drawable,
        hide = data and data.hide == true,
    })
    hiddenCache = nil
    if result then
        cb({ hidden = result[gender] or {} })
    else
        cb({})
    end
end)

-- ------------------------------------------------------------
-- Identity form (step 1 of the creator)
-- ------------------------------------------------------------
local identityPromise
local previewGender

local function setPreviewGender(gender)
    local key = genderKey(gender)
    if previewGender == key then return end
    previewGender = key
    SetInitialClothes(Config.InitialPlayerClothes[key])
    local ped = PlayerPedId()
    local look = STARTER_LOOK[key]
    client.setPedHeadBlend(ped, look.headBlend)
    client.setPedHair(ped, look.hair, {})
    SetPedHeadOverlay(ped, 2, 0, 1.0) -- eyebrows
    SetPedHeadOverlayColor(ped, 2, 1, look.hair.color, look.hair.color)
    client.rpMatchTop(ped)
end

local function finishIdentity(result)
    local p = identityPromise
    identityPromise = nil
    if p then p:resolve(result) end
end

---Shows the identity form and waits. Returns { firstname, lastname, nationality, birthdate, gender } or nil (went back).
---The form stays on screen ("Creating your character...") until CreateAppearance, AskIdentity again, or HideIdentity.
---opts: nationalities, dateMin, dateMax, defaultDate, prefill, errorKey, canCancel
local function askIdentity(opts)
    opts = opts or {}
    if identityPromise then finishIdentity(nil) end
    identityPromise = promise.new()
    local p = identityPromise

    setPreviewGender(opts.prefill and opts.prefill.gender or 0)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'rp_identity_show',
        payload = {
            nationalities = opts.nationalities,
            dateMin = opts.dateMin,
            dateMax = opts.dateMax,
            defaultDate = opts.defaultDate,
            prefill = opts.prefill,
            errorKey = opts.errorKey,
            canCancel = opts.canCancel ~= false,
        },
    })

    local result = Citizen.Await(p)
    if not result then
        SendNUIMessage({ type = 'rp_identity_hide' })
        SetNuiFocus(false, false)
        previewGender = nil
        return nil
    end
    return result
end

local function hideIdentity()
    if identityPromise then finishIdentity(nil) end
    SendNUIMessage({ type = 'rp_identity_hide' })
    SetNuiFocus(false, false)
    previewGender = nil
end

RegisterNUICallback('rp_identity_submit', function(data, cb)
    cb(1)
    if type(data) ~= 'table' then return finishIdentity(nil) end
    finishIdentity({
        firstname = tostring(data.firstname or ''),
        lastname = tostring(data.lastname or ''),
        nationality = tostring(data.nationality or ''),
        birthdate = tostring(data.birthdate or ''),
        gender = tonumber(data.gender) == 1 and 1 or 0,
    })
end)

RegisterNUICallback('rp_identity_cancel', function(_, cb)
    cb(1)
    finishIdentity(nil)
end)

RegisterNUICallback('rp_identity_gender', function(gender, cb)
    cb(1)
    setPreviewGender(tonumber(gender) == 1 and 1 or 0)
end)

-- ------------------------------------------------------------
-- The creator itself (face, hair, clothes)
-- ------------------------------------------------------------
local skipFirstCharacterUntil = 0

---qbx_core sends "create your first character" once the player spawns. Our creator already ran, so skip that once.
function RpConsumeCreatorSkip()
    if GetGameTimer() < skipFirstCharacterUntil then
        skipFirstCharacterUntil = 0
        return true
    end
    return false
end

local function creatorConfig()
    return {
        rpCreator = true,
        ped = false,
        headBlend = true,
        faceFeatures = true,
        headOverlays = true,
        components = true,
        props = true,
        tattoos = false,
        enableExit = false,
        hasTracker = false,
        automaticFade = Config.AutomaticFade,
        componentConfig = {
            masks = not Config.DisableComponents.Masks,
            upperBody = not Config.DisableComponents.UpperBody,
            lowerBody = not Config.DisableComponents.LowerBody,
            bags = not Config.DisableComponents.Bags,
            shoes = not Config.DisableComponents.Shoes,
            scarfAndChains = not Config.DisableComponents.ScarfAndChains,
            bodyArmor = not Config.DisableComponents.BodyArmor,
            shirts = not Config.DisableComponents.Shirts,
            decals = not Config.DisableComponents.Decals,
            jackets = not Config.DisableComponents.Jackets,
        },
        propConfig = {
            hats = not Config.DisableProps.Hats,
            glasses = not Config.DisableProps.Glasses,
            ear = not Config.DisableProps.Ear,
            watches = not Config.DisableProps.Watches,
            bracelets = not Config.DisableProps.Bracelets,
        },
    }
end

---Opens the creator for a character that was just made, waits until they finish, and saves it.
---gender: 0/1 or 'Male'/'Female'. Returns true when saved.
local function createAppearance(gender)
    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(0) end

    setPreviewGender(gender)
    previewGender = nil
    DisplayRadar(false)
    RequestStreamedTextureDict('char_creator_portraits', false)
    Wait(250)
    DoScreenFadeIn(500)

    local p = promise.new()
    TriggerServerEvent('illenium-appearance:server:ChangeRoutingBucket')
    client.startPlayerCustomization(function(appearance)
        TriggerServerEvent('illenium-appearance:server:ResetRoutingBucket')
        if appearance then
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
        p:resolve(appearance ~= nil)
    end, creatorConfig())

    local saved = Citizen.Await(p)
    skipFirstCharacterUntil = GetGameTimer() + 10 * 60000
    DisplayRadar(true)
    return saved
end

exports('AskIdentity', askIdentity)
exports('HideIdentity', hideIdentity)
exports('CreateAppearance', createAppearance)

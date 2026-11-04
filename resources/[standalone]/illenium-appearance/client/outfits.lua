local function typeof(var)
    local _type = type(var);
    if (_type ~= "table" and _type ~= "userdata") then
        return _type;
    end
    local _meta = getmetatable(var);
    if (_meta ~= nil and _meta._NAME ~= nil) then
        return _meta._NAME;
    else
        return _type;
    end
end

-- [OUR CHANGE] Nov 4: a piece with `collection` (like the rp_eup police uniforms) is set by its number
-- inside that clothing pack, so uniforms keep working when a game update moves the big menu numbers.
-- Pieces without `collection` work exactly as before. See docs/core-changes.md
local function setComponent(ped, componentId, piece)
    if piece.collection then
        SetPedCollectionComponentVariation(ped, componentId, piece.collection, piece.item, piece.texture, 0)
    else
        SetPedComponentVariation(ped, componentId, piece.item, piece.texture, 0)
    end
end

local function setCollectionProp(ped, propId, piece)
    if not piece.collection then
        return false
    end
    SetPedCollectionPropIndex(ped, propId, piece.collection, piece.item, piece.texture, true)
    return true
end

function LoadJobOutfit(oData)
    local ped = cache.ped

    local data = oData.outfitData

    if typeof(data) ~= "table" then
        data = json.decode(data)
    end

    -- Pants
    if data["pants"] ~= nil then
        setComponent(ped, 4, data["pants"])
    end

    -- Arms
    if data["arms"] ~= nil then
        setComponent(ped, 3, data["arms"])
    end

    -- T-Shirt
    if data["t-shirt"] ~= nil then
        setComponent(ped, 8, data["t-shirt"])
    end

    -- Vest
    if data["vest"] ~= nil then
        setComponent(ped, 9, data["vest"])
    end

    -- Torso 2
    if data["torso2"] ~= nil then
        setComponent(ped, 11, data["torso2"])
    end

    -- Shoes
    if data["shoes"] ~= nil then
        setComponent(ped, 6, data["shoes"])
    end

    -- Badge
    if data["decals"] ~= nil then
        setComponent(ped, 10, data["decals"])
    end

    -- Accessory
    local tracker = Config.TrackerClothingOptions

    if data["accessory"] ~= nil then
        if Framework.HasTracker() then
            SetPedComponentVariation(ped, 7, tracker.drawable, tracker.texture, 0)
        else
            setComponent(ped, 7, data["accessory"])
        end
    else
        if Framework.HasTracker() then
            SetPedComponentVariation(ped, 7, tracker.drawable, tracker.texture, 0)
        else
            local drawableId = GetPedDrawableVariation(ped, 7)
            
            if drawableId ~= -1 then
                local textureId = GetPedTextureVariation(ped, 7)
                if drawableId == tracker.drawable and textureId == tracker.texture then
                    SetPedComponentVariation(ped, 7, -1, 0, 2)
                end
            end
        end
    end

    -- Mask
    if data["mask"] ~= nil then
        setComponent(ped, 1, data["mask"])
    end

    -- Bag
    if data["bag"] ~= nil then
        setComponent(ped, 5, data["bag"])
    end

    -- Hat
    if data["hat"] ~= nil and not setCollectionProp(ped, 0, data["hat"]) then
        if data["hat"].item ~= -1 and data["hat"].item ~= 0 then
            SetPedPropIndex(ped, 0, data["hat"].item, data["hat"].texture, true)
        else
            ClearPedProp(ped, 0)
        end
    end

    -- Glass
    if data["glass"] ~= nil and not setCollectionProp(ped, 1, data["glass"]) then
        if data["glass"].item ~= -1 and data["glass"].item ~= 0 then
            SetPedPropIndex(ped, 1, data["glass"].item, data["glass"].texture, true)
        else
            ClearPedProp(ped, 1)
        end
    end

    -- Ear
    if data["ear"] ~= nil and not setCollectionProp(ped, 2, data["ear"]) then
        if data["ear"].item ~= -1 and data["ear"].item ~= 0 then
            SetPedPropIndex(ped, 2, data["ear"].item, data["ear"].texture, true)
        else
            ClearPedProp(ped, 2)
        end
    end

    local length = 0
    for _ in pairs(data) do
        length = length + 1
    end

    if Config.PersistUniforms and length > 1 then
        TriggerServerEvent("illenium-appearance:server:syncUniform", {
            jobName = oData.jobName,
            gender = oData.gender,
            label = oData.name
        })
    end
end

RegisterNetEvent("illenium-appearance:client:loadJobOutfit", LoadJobOutfit)

RegisterNetEvent("illenium-appearance:client:openOutfitMenu", function()
    OpenMenu(nil, "outfit")
end)

RegisterNetEvent("illenium-apearance:client:outfitsCommand", function(isJob)
    local outfits = GetPlayerJobOutfits(isJob)
    TriggerEvent("illenium-appearance:client:openJobOutfitsMenu", outfits)
end)

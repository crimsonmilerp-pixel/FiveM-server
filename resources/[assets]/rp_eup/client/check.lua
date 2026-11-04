-- ============================================================
--  rp_eup - /eupcheck
--  1. Shows how many uniform pieces the game knows about (from the .ymt list).
--  2. Then tries to really load one piece (an LSPD shirt). If the list is
--     known but the piece never loads, FiveM is blocking custom clothing,
--     which happens when the server has too many slots (see README).
-- ============================================================
local COLLECTION = 'rp_eup'

local COMPONENTS = {
    { 1, 'masks' }, { 4, 'pants' }, { 5, 'badges' }, { 6, 'shoes' }, { 7, 'accessories' },
    { 8, 'belts' }, { 9, 'radios and vests' }, { 10, 'insignia' }, { 11, 'tops' },
}
local PROPS = { { 0, 'hats' }, { 1, 'glasses' } }

local function say(text)
    -- F8 console line (always) + chat line + top-left notice, so the answer is seen somewhere
    print('[rp_eup] ' .. text)
    TriggerEvent('chat:addMessage', { args = { 'Uniforms', text } })
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

local function check()
    local ped = PlayerPedId()
    local parts, total = {}, 0
    for _, c in ipairs(COMPONENTS) do
        local count = GetNumberOfPedCollectionDrawableVariations(ped, c[1], COLLECTION)
        total = total + count
        parts[#parts + 1] = ('%s %d'):format(c[2], count)
    end
    for _, p in ipairs(PROPS) do
        local count = GetNumberOfPedCollectionPropDrawableVariations(ped, p[1], COLLECTION)
        total = total + count
        parts[#parts + 1] = ('%s %d'):format(p[2], count)
    end
    say(('%d pieces in the list: %s'):format(total, table.concat(parts, ', ')))
    if total == 0 then
        say('The list did not load. Check the txAdmin console for rp_eup errors.')
        return
    end

    -- Load test: ask the game to load one shirt without wearing it.
    local globalIndex = GetPedDrawableGlobalIndexFromCollection(ped, 11, COLLECTION, 0)
    if not globalIndex or globalIndex < 0 then
        say('Load test skipped: could not find the first shirt.')
        return
    end
    SetPedPreloadVariationData(ped, 11, globalIndex, 0)
    local started = GetGameTimer()
    while not HasPedPreloadVariationDataFinished(ped) and GetGameTimer() - started < 10000 do
        Wait(100)
    end
    local loaded = HasPedPreloadVariationDataFinished(ped)
    ReleasePedPreloadVariationData(ped)
    if loaded then
        say(('Load test passed: the clothes load (%.1f s).'):format((GetGameTimer() - started) / 1000))
    else
        say('Load test FAILED: the list is there but the clothes themselves never loaded. FiveM blocks custom clothing on servers with more than 8 slots (unless the owner has Element Club Argentum). Set Max Players to 8 and restart.')
    end
end

RegisterCommand('eupcheck', function()
    say('Checking the uniform pack...')
    CreateThread(function()
        local ok, err = pcall(check)
        if not ok then
            say('The check itself failed: ' .. tostring(err))
        end
    end)
end, false)

print('[rp_eup] loaded. Type /eupcheck in chat (or eupcheck in F8) to test the uniforms.')

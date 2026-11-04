-- ============================================================
--  rp_eup - /eupcheck
--  Shows how many uniform pieces the game loaded from this pack.
--  If every number is 0, the clothes did not load (see README).
-- ============================================================
local COLLECTION = 'rp_eup'

local COMPONENTS = {
    { 1, 'masks' }, { 4, 'pants' }, { 5, 'belts and bags' }, { 6, 'shoes' }, { 7, 'accessories' },
    { 8, 'undershirts' }, { 9, 'vests' }, { 10, 'badges and insignia' }, { 11, 'tops' },
}
local PROPS = { { 0, 'hats' }, { 1, 'glasses' } }

RegisterCommand('eupcheck', function()
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
    local text = ('%d pieces loaded: %s'):format(total, table.concat(parts, ', '))
    print('[rp_eup] ' .. text)
    TriggerEvent('chat:addMessage', { args = { 'Uniforms', text } })
end, false)

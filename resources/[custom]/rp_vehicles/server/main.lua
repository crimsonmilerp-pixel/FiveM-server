-- ============================================================
--  rp_vehicles - server side
--  Stops blocked vehicles (weaponized, armored, military, arena,
--  sci-fi) from ever appearing: not in traffic, not at the
--  military base, not spawned by anyone.
-- ============================================================
local config = require 'config'

local blocked = {}
for _, name in ipairs(config.blockedModels) do
    local hash = joaat(name)
    -- Store both the signed and unsigned form of the hash, so the check works either way.
    blocked[hash & 0xFFFFFFFF] = name
    blocked[(hash & 0xFFFFFFFF) - ((hash & 0x80000000) ~= 0 and 0x100000000 or 0)] = name
end

local function blockedName(entity)
    local model = GetEntityModel(entity)
    return blocked[model] or blocked[model & 0xFFFFFFFF]
end

-- Cancel before it's created (traffic, players' game requests)
AddEventHandler('entityCreating', function(entity)
    if blockedName(entity) then
        CancelEvent()
    end
end)

-- Safety net: delete anything that slipped through (for example, server-side spawns)
AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then return end
    local name = blockedName(entity)
    if name then
        DeleteEntity(entity)
        lib.print.info(('Blocked vehicle removed: %s'):format(name))
    end
end)

lib.print.info(('%d vehicle models blocked'):format(#config.blockedModels))

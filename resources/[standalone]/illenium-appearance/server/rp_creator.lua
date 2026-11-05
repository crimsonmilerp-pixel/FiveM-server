-- ============================================================
-- [OUR CHANGE] Nov 4, 2026: clothing hidden by staff.
-- Staff open any clothing menu, hover an item that clips or looks broken, and click the X.
-- It disappears for every player (staff still see it, greyed out, and can bring it back).
-- Kept in the database table rp_hidden_clothing. See docs/core-changes.md
-- ============================================================
local STAFF_ACE = 'admin'

local SLOTS = {
    c = { [1] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true },
    p = { [0] = true, [1] = true, [2] = true, [6] = true, [7] = true },
}

local hidden = { male = {}, female = {} } -- hidden[gender]['c11'][drawable] = true
local ready = false

local function isStaff(source)
    return IsPlayerAceAllowed(source, STAFF_ACE)
end

local function mark(gender, key, drawable, on)
    local list = hidden[gender][key]
    if not list then
        list = {}
        hidden[gender][key] = list
    end
    list[drawable] = on or nil
end

---{ male = { c11 = { 7, 8 } }, female = { ... } } in a shape the menus can read.
local function snapshot()
    local out = { male = {}, female = {} }
    for gender, slots in pairs(hidden) do
        for key, drawables in pairs(slots) do
            local list = {}
            for drawable in pairs(drawables) do list[#list + 1] = drawable end
            if #list > 0 then
                table.sort(list)
                out[gender][key] = list
            end
        end
    end
    return out
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_hidden_clothing` (
            `gender`    VARCHAR(6)  NOT NULL,
            `slot`      VARCHAR(4)  NOT NULL,
            `drawable`  INT         NOT NULL,
            `hidden_by` VARCHAR(80) NULL,
            `hidden_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`gender`, `slot`, `drawable`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    for _, row in ipairs(MySQL.query.await('SELECT `gender`, `slot`, `drawable` FROM `rp_hidden_clothing`') or {}) do
        if hidden[row.gender] then mark(row.gender, row.slot, tonumber(row.drawable), true) end
    end
    ready = true
end)

lib.callback.register('illenium-appearance:server:rpHidden', function(source)
    local out = snapshot()
    out.staff = isStaff(source)
    return out
end)

lib.callback.register('illenium-appearance:server:rpHideItem', function(source, data)
    if not ready or not isStaff(source) or type(data) ~= 'table' then return nil end

    local gender, kind = data.gender, data.kind
    local slot, drawable = tonumber(data.slot), tonumber(data.drawable)
    if not hidden[gender] or not SLOTS[kind] or not slot or not SLOTS[kind][slot] then return nil end
    if not drawable or drawable < 0 or drawable > 5000 or drawable % 1 ~= 0 then return nil end

    local key = kind .. slot
    if data.hide then
        MySQL.insert.await('INSERT IGNORE INTO `rp_hidden_clothing` (`gender`, `slot`, `drawable`, `hidden_by`, `hidden_at`) VALUES (?, ?, ?, ?, ?)', {
            gender, key, drawable, GetPlayerName(source), os.time(),
        })
        mark(gender, key, drawable, true)
    else
        MySQL.query.await('DELETE FROM `rp_hidden_clothing` WHERE `gender` = ? AND `slot` = ? AND `drawable` = ?', { gender, key, drawable })
        mark(gender, key, drawable, false)
    end

    lib.print.info(('%s %s %s item %s #%d'):format(GetPlayerName(source), data.hide and 'hid' or 'unhid', gender, key, drawable))
    TriggerClientEvent('illenium-appearance:client:rpHiddenChanged', -1)
    return snapshot()
end)

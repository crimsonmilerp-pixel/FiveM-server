-- ============================================================
--  rp_jobmoments - client side (runs in each player's game)
--  Shows the moment and its choices, runs the taxi chase, the
--  police front desk, the wallet owner at their door, and /cases.
--  The server checks and records every choice.
-- ============================================================
local config = require 'config'

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

---"Grove St / Forum Dr" for a spot on the map.
local function streetAt(coords)
    local street, cross = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local name = GetStreetNameFromHashKey(street)
    local crossName = cross ~= 0 and GetStreetNameFromHashKey(cross) or ''
    if crossName ~= '' then return ('%s / %s'):format(name, crossName) end
    return name
end

local function myStreet()
    return streetAt(GetEntityCoords(cache.ped))
end

---Finds the ground under a spot, so NPCs don't float or sink.
local function groundZ(coords)
    local fallback = coords.z - 1.0
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.5, false)
    if found and math.abs(z - fallback) < 3.0 then return z end
    return fallback
end

local function notify(description, kind, duration)
    lib.notify({ title = locale('title'), description = description, type = kind or 'inform', duration = duration or 8000, icon = 'clipboard-list' })
end

-- ------------------------------------------------------------
-- Lost wallets: the owner waits at their front door
-- ------------------------------------------------------------
local walletPoints = {} -- [homeIndex] = { point, ped }
local refreshWallets

local function removeOwner(home)
    local entry = walletPoints[home]
    if entry and entry.ped and DoesEntityExist(entry.ped) then
        exports.ox_target:removeLocalEntity(entry.ped, 'rp_jobmoments_wallet')
        DeleteEntity(entry.ped)
    end
    if entry then entry.ped = nil end
end

local function spawnOwner(home)
    local entry = walletPoints[home]
    if not entry or entry.ped then return end

    local peds = config.wallet.ownerPeds
    local model = lib.requestModel(peds[(home % #peds) + 1])
    if not model then return end

    local door = config.wallet.homes[home]
    local me = GetEntityCoords(cache.ped)
    local heading = GetHeadingFromVector_2d(me.x - door.x, me.y - door.y) -- face the player walking up
    local ped = CreatePed(0, model, door.x, door.y, groundZ(door), heading, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'rp_jobmoments_wallet',
            icon = 'fa-solid fa-wallet',
            label = locale('wallet.target'),
            distance = 2.5,
            onSelect = function()
                local ok, owner, reward = lib.callback.await('rp_jobmoments:server:returnWallet', false, home)
                if ok then
                    notify(locale('wallet.thanks', owner, reward), 'success', 10000)
                    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
                    SetTimeout(4000, refreshWallets)
                else
                    notify(locale('error.' .. tostring(owner)), 'error')
                end
            end,
        },
    })
    entry.ped = ped
end

---Makes sure there's a waiting owner for every wallet the player is carrying, and none for the rest.
refreshWallets = function()
    local wanted = {}
    local slots = exports.ox_inventory:Search('slots', 'lost_wallet') or {}
    for _, slot in pairs(slots) do
        local home = slot.metadata and slot.metadata.home
        if home and config.wallet.homes[home] then wanted[home] = true end
    end

    for home, entry in pairs(walletPoints) do
        if not wanted[home] then
            removeOwner(home)
            entry.point:remove()
            walletPoints[home] = nil
        end
    end

    for home in pairs(wanted) do
        if not walletPoints[home] then
            walletPoints[home] = {
                point = lib.points.new({
                    coords = config.wallet.homes[home],
                    distance = 40.0,
                    onEnter = function() spawnOwner(home) end,
                    onExit = function() removeOwner(home) end,
                }),
            }
        end
    end
end

local function gpsToHome(home)
    local door = config.wallet.homes[home]
    if not door then return end
    SetNewWaypoint(door.x, door.y)
    notify(locale('wallet.gps', streetAt(door)), 'inform')
end

-- Using the wallet item sets the GPS to the owner's address.
exports('useWallet', function(_, slot)
    local home = slot and slot.metadata and slot.metadata.home
    if home then gpsToHome(home) end
    refreshWallets()
end)

-- Using found evidence sets the GPS to the nearest police front desk.
exports('useEvidence', function()
    local pos, best, bestDist = GetEntityCoords(cache.ped), nil, math.huge
    for _, desk in ipairs(config.desks) do
        local dist = #(pos - desk.coords)
        if dist < bestDist then best, bestDist = desk, dist end
    end
    if best then
        SetNewWaypoint(best.coords.x, best.coords.y)
        notify(locale('desk.gps'), 'inform')
    end
end)

-- ------------------------------------------------------------
-- The moment and its choices
-- ------------------------------------------------------------
local CHOICES = {
    bloody_bag = {
        { id = 'turn_in', icon = 'shield-halved' },
        { id = 'keep', icon = 'hand' },
        { id = 'leave', icon = 'arrow-right' },
    },
    lost_wallet = {
        { id = 'return', icon = 'house' },
        { id = 'take_cash', icon = 'money-bill' },
        { id = 'leave', icon = 'arrow-right' },
    },
    left_bag = {
        { id = 'turn_in', icon = 'shield-halved' },
        { id = 'keep', icon = 'sack-dollar' },
        { id = 'leave', icon = 'arrow-right' },
    },
    tow_trunk = {
        { id = 'turn_in', icon = 'shield-halved' },
        { id = 'keep', icon = 'hand' },
        { id = 'leave', icon = 'arrow-right' },
    },
    extra_package = {
        { id = 'turn_in', icon = 'shield-halved' },
        { id = 'keep', icon = 'sack-dollar' },
        { id = 'leave', icon = 'arrow-right' },
    },
}

local showMoment

local function choose(momentId, kind, choice, show)
    local ok, key, extra = lib.callback.await('rp_jobmoments:server:choose', false, momentId, choice, myStreet())
    if ok then
        notify(locale(key), choice == 'keep' and 'warning' or 'success', 12000)
        if kind == 'lost_wallet' and choice == 'return' and extra then
            gpsToHome(extra)
            refreshWallets()
        end
    elseif key == 'cant_carry' then
        notify(locale('error.cant_carry'), 'error')
        showMoment(momentId, kind, show) -- pick again
    else
        notify(locale('error.' .. tostring(key)), 'error')
    end
end

showMoment = function(momentId, kind, show)
    local choices = CHOICES[kind]
    if not choices then return end

    local options = {
        {
            title = locale(('moment.%s.title'):format(kind)),
            description = locale(('moment.%s.story'):format(kind), show.owner or show.cash or show.plate or '', show.cash or ''),
            icon = 'circle-exclamation',
            readOnly = true,
        },
    }
    for _, c in ipairs(choices) do
        options[#options + 1] = {
            title = locale(('choice.%s.%s'):format(kind, c.id), show.cash or ''),
            description = locale(('choice.%s.%s_desc'):format(kind, c.id), show.cash or ''),
            icon = c.icon,
            onSelect = function() choose(momentId, kind, c.id, show) end,
        }
    end

    lib.registerContext({
        id = 'rp_jobmoments_choice',
        title = locale('title'),
        canClose = false, -- they have to pick (one of the choices is "leave it")
        options = options,
    })
    lib.showContext('rp_jobmoments_choice')
end

RegisterNetEvent('rp_jobmoments:client:moment', function(momentId, kind, show)
    if GetInvokingResource() then return end -- only the server may start a moment
    PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', false)
    showMoment(momentId, kind, show or {})
end)

-- ------------------------------------------------------------
-- Taxi: the passenger runs off without paying
-- ------------------------------------------------------------

---The passenger who just got out of the cab.
local function findPassenger()
    local veh = cache.vehicle or GetVehiclePedIsIn(cache.ped, true)
    if veh ~= 0 and DoesEntityExist(veh) then
        for seat = 0, 2 do
            local ped = GetPedInVehicleSeat(veh, seat)
            if ped ~= 0 and not IsPedAPlayer(ped) then return ped end
        end
    end

    local origin = (veh ~= 0 and DoesEntityExist(veh)) and GetEntityCoords(veh) or GetEntityCoords(cache.ped)
    local best, bestDist = nil, 8.0
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= cache.ped and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
            local dist = #(GetEntityCoords(ped) - origin)
            if dist < bestDist then best, bestDist = ped, dist end
        end
    end
    return best
end

RegisterNetEvent('rp_jobmoments:client:runner', function(momentId, runner)
    if GetInvokingResource() then return end

    Wait(500) -- let them finish stepping out
    local ped = findPassenger()
    if not ped then
        local _, key, fare = lib.callback.await('rp_jobmoments:server:runnerResult', false, momentId, 'noped', myStreet())
        if key then notify(locale(key, fare or 0), 'success') end
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    ClearPedTasksImmediately(ped)
    SetBlockingOfNonTemporaryEvents(ped, false)
    TaskSmartFleePed(ped, cache.ped, 300.0, -1, false, false)
    SetPedKeepTask(ped, true)

    local blip = AddBlipForEntity(ped)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.7)

    PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', false)
    notify(locale('runner.start', runner.seconds), 'warning', 10000)
    lib.showTextUI(locale('runner.help'), { position = 'left-center', icon = 'person-running' })

    local deadline = GetGameTimer() + runner.seconds * 1000
    local result = 'escaped'
    while true do
        Wait(0)
        if not DoesEntityExist(ped) then break end
        if IsPedDeadOrDying(ped, true) then result = 'dead' break end
        if GetGameTimer() > deadline then break end

        local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(ped))
        if dist > 250.0 then break end

        if dist <= runner.grabDistance and not cache.vehicle and IsControlJustPressed(0, 38) then -- E
            ClearPedTasksImmediately(ped)
            TaskHandsUp(ped, 5000, cache.ped, -1, true)
            result = 'caught'
            break
        end
        if IsControlJustPressed(0, 47) then -- G
            result = 'reported'
            break
        end
    end

    lib.hideTextUI()
    if DoesBlipExist(blip) then RemoveBlip(blip) end
    if DoesEntityExist(ped) then
        SetPedKeepTask(ped, false)
        SetEntityAsMissionEntity(ped, false, true)
        SetEntityAsNoLongerNeeded(ped)
    end

    local _, key, amount = lib.callback.await('rp_jobmoments:server:runnerResult', false, momentId, result, myStreet())
    if key then
        notify(locale(key, amount or 0), result == 'caught' and 'success' or (result == 'dead' and 'error' or 'inform'), 10000)
    end
end)

-- ------------------------------------------------------------
-- Police front desks: turning in found evidence
-- ------------------------------------------------------------
local function turnIn()
    local ok, count, reward, police = lib.callback.await('rp_jobmoments:server:turnIn', false)
    if not ok then return notify(locale('error.' .. tostring(count)), 'error') end
    if police then
        notify(locale('desk.logged', count), 'success')
    else
        notify(locale('desk.thanks', count, reward), 'success', 10000)
    end
end

for i, desk in ipairs(config.desks) do
    exports.ox_target:addSphereZone({
        name = ('rp_jobmoments_desk_%d'):format(i),
        coords = desk.coords,
        radius = desk.radius,
        options = {
            {
                name = 'rp_jobmoments_turnin',
                icon = 'fa-solid fa-box-archive',
                label = locale('desk.target'),
                items = 'found_evidence', -- only shows if you're carrying some
                onSelect = turnIn,
            },
        },
    })
end

-- ------------------------------------------------------------
-- /cases : the case files (on-duty police and staff)
-- ------------------------------------------------------------
local function caseDetail(case)
    local d = case.data
    local street = d.street or streetAt(case.coords)
    local text
    if case.kind == 'shooting' then
        text = locale('detail.shooting', street, case.serial or '?')
    elseif case.kind == 'lost_cash' then
        text = locale('detail.lost_cash', d.amount or 0, d.plate or '?', street)
    elseif case.kind == 'fare_evasion' then
        text = locale('detail.fare_evasion', d.fare or 0, street, d.reporter or '?', d.plate or '?')
    elseif case.kind == 'pedestrian_down' then
        text = locale('detail.pedestrian_down', street, d.plate or '?')
    elseif case.kind == 'drugs_found' then
        text = locale('detail.drugs_found', d.plate or '?')
    elseif case.kind == 'found_shipment' then
        text = locale('detail.found_shipment', d.amount or 0, street)
    else
        text = case.kind
    end
    if case.status == 'recovered' and d.turned_in_by then
        text = text .. '\n\n' .. locale('detail.recovered', d.turned_in_by, d.turned_in_at or '?')
    end
    return text
end

local function statusLabel(case)
    return locale(('status.%s.%s'):format(case.kind, case.status))
end

local openCases

local function openCase(case, staff)
    local options = {
        { title = statusLabel(case), description = caseDetail(case), icon = 'file-lines', readOnly = true },
        {
            title = locale('cases.gps'),
            icon = 'location-dot',
            onSelect = function()
                SetNewWaypoint(case.coords.x, case.coords.y)
                notify(locale('cases.gps_set'), 'inform')
            end,
        },
    }
    if staff then
        for _, entry in ipairs(case.log or {}) do
            options[#options + 1] = {
                title = locale('cases.staff_line', entry.name, locale('log.' .. entry.choice)),
                description = locale('cases.staff_only', entry.citizenid),
                icon = 'user-secret',
                readOnly = true,
            }
        end
    end

    lib.registerContext({
        id = 'rp_jobmoments_case',
        title = locale('cases.case_title', case.id, locale('kind.' .. case.kind)),
        menu = 'rp_jobmoments_cases',
        options = options,
    })
    lib.showContext('rp_jobmoments_case')
end

openCases = function()
    local cases, staff = lib.callback.await('rp_jobmoments:server:cases', false)
    if not cases then return notify(locale('error.no_permission'), 'error') end

    local options = {}
    for _, case in ipairs(cases) do
        options[#options + 1] = {
            title = locale('cases.row', case.id, locale('kind.' .. case.kind)),
            description = locale('cases.row_desc', case.date, case.data.street or streetAt(case.coords), statusLabel(case)),
            icon = case.status == 'open' and 'folder-open' or 'folder',
            onSelect = function() openCase(case, staff) end,
        }
    end
    if #options == 0 then options[1] = { title = locale('cases.empty'), readOnly = true } end

    lib.registerContext({ id = 'rp_jobmoments_cases', title = locale('cases.title'), options = options })
    lib.showContext('rp_jobmoments_cases')
end

-- A text from someone (moment follow-ups)
RegisterNetEvent('rp_jobmoments:client:text', function(sender, message)
    if GetInvokingResource() then return end
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', false)
    lib.notify({ title = sender, description = message, type = 'inform', icon = 'comment-sms', duration = 15000 })
end)

RegisterNetEvent('rp_jobmoments:client:openCases', function()
    if GetInvokingResource() then return end
    openCases()
end)

-- ------------------------------------------------------------
-- Keep wallet owners in sync
-- ------------------------------------------------------------
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(5000, refreshWallets)
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= cache.resource then return end
    if LocalPlayer.state.isLoggedIn then SetTimeout(2000, refreshWallets) end
end)

-- Wallets can also change hands (given to a friend, dropped), so check now and then.
CreateThread(function()
    while true do
        Wait(15000)
        if LocalPlayer.state.isLoggedIn then refreshWallets() end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for home in pairs(walletPoints) do removeOwner(home) end
end)

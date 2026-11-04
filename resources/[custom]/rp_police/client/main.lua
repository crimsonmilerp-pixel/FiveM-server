-- ============================================================
--  rp_police - client side (runs in each player's game)
--  Shows the menus: certifications, cadet training, the
--  department log and the penal code. It also tells qbx_police
--  which cars an officer may take. Every change is checked
--  again by the server.
-- ============================================================
local config = require 'config'
local penalCode = require 'data.penalcode'

local CERT_ICON = {}
for _, cert in ipairs(config.certs) do CERT_ICON[cert.id] = cert.icon end

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function notify(text, kind)
    exports.qbx_core:Notify(text, kind or 'inform', 7000)
end

local function showError(errorKey)
    notify(locale('error.' .. (errorKey or 'failed')), 'error')
end

local function certLabel(certId)
    return locale(('cert.%s.label'):format(certId))
end

local function rankName(department, level)
    local ranks = GlobalState.rp_police_ranks
    local list = ranks and ranks[department]
    return list and list[tostring(level)] or locale('rank_fallback', level)
end

local function myDepartment()
    local job = QBX.PlayerData.job
    if job and config.departments[job.name] then return job end
end

local function hasCert(certId)
    local licences = QBX.PlayerData.metadata and QBX.PlayerData.metadata.licences
    return type(licences) == 'table' and licences['police_' .. certId] == true
end

local function confirm(header, content)
    return lib.alertDialog({
        header = header,
        content = content,
        centered = true,
        cancel = true,
        labels = { confirm = locale('menu.yes'), cancel = locale('menu.no') },
    }) == 'confirm'
end

---What an officer needs for a vehicle, e.g. "Officer II · Traffic Division".
local function requirementText(department, entry)
    local text = rankName(department, entry.minGrade)
    if entry.cert then text = text .. ' · ' .. certLabel(entry.cert) end
    return text
end

-- ------------------------------------------------------------
-- Certifications (/certs)
-- ------------------------------------------------------------
local openCerts

local function changeCert(data, cert)
    local label = certLabel(cert.id)
    local value = not cert.has
    local header = locale(value and 'certs.grant_header' or 'certs.remove_header', label)
    local content = locale(value and 'certs.grant_text' or 'certs.remove_text', label, data.title)
    if not confirm(header, content) then return openCerts(data.target) end

    local ok, errorKey = lib.callback.await('rp_police:server:setCert', false, data.target, cert.id, value)
    if ok then
        notify(locale(value and 'certs.granted' or 'certs.removed', label, data.title), 'success')
    else
        showError(errorKey)
    end
    openCerts(data.target)
end

openCerts = function(targetId)
    local data, errorKey = lib.callback.await('rp_police:server:getCerts', false, targetId)
    if not data then return showError(errorKey) end

    local options = {}
    for _, cert in ipairs(data.certs) do
        local status
        if cert.has then
            status = locale('certs.status_has')
        elseif cert.eligible then
            status = locale('certs.status_can')
        else
            status = locale('certs.status_too_junior', cert.minRank)
        end

        options[#options + 1] = {
            title = certLabel(cert.id),
            description = ('%s · %s'):format(status, locale(('cert.%s.desc'):format(cert.id))),
            icon = cert.has and 'circle-check' or (CERT_ICON[cert.id] or 'certificate'),
            iconColor = cert.has and '#3fb950' or nil,
            disabled = not data.canManage or (not cert.has and not cert.eligible),
            onSelect = data.canManage and function() changeCert(data, cert) end or nil,
        }
    end

    if data.canManage then
        table.insert(options, 1, { title = locale('certs.manage_hint'), icon = 'circle-info', readOnly = true })
    end

    lib.registerContext({ id = 'rp_police_certs', title = locale('certs.title', data.title), options = options })
    lib.showContext('rp_police_certs')
end

RegisterNetEvent('rp_police:client:openCerts', function(targetId)
    openCerts(type(targetId) == 'number' and targetId or nil) -- the radial menu sends a table: open your own
end)

-- ------------------------------------------------------------
-- Cadet training (/training)
-- ------------------------------------------------------------
local openTraining

local function changeTraining(data, item)
    local label = locale(('training.%s.label'):format(item.id))
    local value = not item.signed
    local header = locale(value and 'training.sign_header' or 'training.unsign_header', label)
    local content = locale(value and 'training.sign_text' or 'training.unsign_text', label, data.title)
    if not confirm(header, content) then return openTraining(data.target) end

    local ok, errorKey = lib.callback.await('rp_police:server:setTraining', false, data.target, item.id, value)
    if not ok then showError(errorKey) end
    openTraining(data.target)
end

openTraining = function(targetId)
    local data, errorKey = lib.callback.await('rp_police:server:getTraining', false, targetId)
    if not data then return showError(errorKey) end

    local options = {}
    if data.done >= data.total then
        options[#options + 1] = { title = locale('training.complete', data.nextRank), icon = 'award', iconColor = '#3fb950', readOnly = true }
    elseif not data.isCadet then
        options[#options + 1] = { title = locale('training.not_cadet'), icon = 'circle-info', readOnly = true }
    elseif data.canSign then
        options[#options + 1] = { title = locale('training.sign_hint'), icon = 'circle-info', readOnly = true }
    end

    for _, item in ipairs(data.items) do
        local description = item.signed
            and locale('training.signed_by', item.by, item.on)
            or locale(('training.%s.desc'):format(item.id))
        options[#options + 1] = {
            title = locale(('training.%s.label'):format(item.id)),
            description = description,
            icon = item.signed and 'square-check' or 'square',
            iconColor = item.signed and '#3fb950' or nil,
            disabled = not data.canSign,
            onSelect = data.canSign and function() changeTraining(data, item) end or nil,
        }
    end

    lib.registerContext({
        id = 'rp_police_training',
        title = locale('training.title', data.title, data.done, data.total),
        options = options,
    })
    lib.showContext('rp_police_training')
end

RegisterNetEvent('rp_police:client:openTraining', function(targetId)
    openTraining(type(targetId) == 'number' and targetId or nil) -- the radial menu sends a table: open your own
end)

-- ------------------------------------------------------------
-- Department log (/policelog)
-- ------------------------------------------------------------
local LOG_ICON = {
    cert_granted = 'certificate',
    cert_removed = 'ban',
    certs_cleared = 'ban',
    training_signed = 'square-check',
    training_removed = 'square',
    training_done = 'award',
    armory = 'box-archive',
}

RegisterNetEvent('rp_police:client:openLog', function(targetId)
    if type(targetId) ~= 'number' then targetId = nil end
    local data, errorKey = lib.callback.await('rp_police:server:getLog', false, targetId)
    if not data then return showError(errorKey) end

    local options = {}
    if #data.entries == 0 then
        options[1] = { title = locale('log.empty'), icon = 'circle-info', readOnly = true }
    end
    for _, entry in ipairs(data.entries) do
        options[#options + 1] = {
            title = locale('log.' .. entry.action, entry.name, entry.detail),
            description = locale('log.by', entry.by, entry.on),
            icon = LOG_ICON[entry.action] or 'circle',
            readOnly = true,
        }
    end

    local heading = data.heading and locale('log.title_one', data.heading) or locale('log.title')
    lib.registerContext({ id = 'rp_police_log', title = heading, options = options })
    lib.showContext('rp_police_log')
end)

-- ------------------------------------------------------------
-- Penal code (/penalcode) - anyone can read it
-- ------------------------------------------------------------
local function jailText(minutes)
    return minutes > 0 and locale('penal.jail_minutes', minutes) or locale('penal.no_jail')
end

local function openCategory(category)
    local options = {}
    for _, charge in ipairs(category.charges) do
        options[#options + 1] = {
            title = ('%s  %s'):format(charge.id, charge.title),
            description = locale('penal.line', locale('penal.class_' .. charge.class), lib.math.groupdigits(charge.fine), jailText(charge.jail)),
            metadata = { { label = locale('penal.about'), value = charge.desc } },
            readOnly = true,
        }
    end
    lib.registerContext({
        id = 'rp_police_penal_category',
        title = locale('penal.category_' .. category.id),
        menu = 'rp_police_penal',
        options = options,
    })
    lib.showContext('rp_police_penal_category')
end

RegisterNetEvent('rp_police:client:openPenalCode', function()
    local options = {
        {
            title = locale('penal.how_title'),
            description = locale('penal.how_desc', penalCode.maxJail),
            icon = 'scale-balanced',
            readOnly = true,
        },
    }
    for _, category in ipairs(penalCode.categories) do
        options[#options + 1] = {
            title = locale('penal.category_' .. category.id),
            description = locale('penal.count', #category.charges),
            icon = 'book',
            arrow = true,
            onSelect = function() openCategory(category) end,
        }
    end
    lib.registerContext({ id = 'rp_police_penal', title = locale('penal.title'), options = options })
    lib.showContext('rp_police_penal')
end)

-- ------------------------------------------------------------
-- Station markers: a circle on the floor and a label at each police
-- spot (duty desk, lockers, armory, garage...), for officers only.
-- ------------------------------------------------------------
local MARKER_COLOUR = { r = 70, g = 130, b = 230, a = 110 }

local function canSeeMarker(job, show)
    if show == 'always' then return true end
    if show == 'duty' then return job.onduty == true end
    if show == 'boss' then return job.isboss == true end
    return false
end

---Finds the floor under a spot once (falls back to about 1 m below the spot).
local function floorZ(marker)
    if marker.floor then return marker.floor end
    local c = marker.coords
    local found, z = GetGroundZFor_3dCoord(c.x, c.y, c.z + 0.5, false)
    if found and z > c.z - 3.0 and z <= c.z + 0.5 then
        marker.floor = z
    else
        return c.z - 0.98 -- not cached: try again when the area has loaded
    end
    return marker.floor
end

local function drawLabel(x, y, z, text)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetTextCentre(true)
    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    local markers = config.stationMarkers or {}
    local drawDistance = config.markerDrawDistance or 25.0
    local labelDistance = config.markerLabelDistance or 8.0

    while true do
        local job = LocalPlayer.state.isLoggedIn and myDepartment()
        local nearby = {}

        if job then
            local coords = GetEntityCoords(cache.ped)
            for _, marker in ipairs(markers) do
                if canSeeMarker(job, marker.show) and #(coords - marker.coords) < drawDistance then
                    nearby[#nearby + 1] = marker
                end
            end
        end

        if #nearby == 0 then
            Wait(1500)
        else
            -- Draw every frame for a second, then check again who and what is nearby.
            local untilTime = GetGameTimer() + 1000
            while GetGameTimer() < untilTime do
                local coords = GetEntityCoords(cache.ped)
                for _, marker in ipairs(nearby) do
                    local c = marker.coords
                    local z = floorZ(marker)
                    DrawMarker(25, c.x, c.y, z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.0,
                        MARKER_COLOUR.r, MARKER_COLOUR.g, MARKER_COLOUR.b, MARKER_COLOUR.a, false, false, 2, false, nil, nil, false)
                    if #(coords - c) < labelDistance then
                        drawLabel(c.x, c.y, z + 1.0, locale('station.' .. marker.point))
                    end
                end
                Wait(0)
            end
        end
    end
end)

-- The captain's desk: rp_police opens the boss menu (qbx_management) itself, from the
-- same spot as the floor circle. Qbox's own spot was too thin from floor to ceiling
-- (half a meter of leeway), so pressing E often did nothing.
local function isBossHere()
    local job = myDepartment()
    return job ~= nil and job.isboss == true
end

for _, marker in ipairs(config.stationMarkers or {}) do
    if marker.point == 'boss' then
        lib.zones.box({
            coords = marker.coords,
            size = vec3(3.0, 3.0, 6.0),
            onEnter = function()
                if isBossHere() then lib.showTextUI(locale('station.boss_prompt')) end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if IsControlJustReleased(0, 38) and isBossHere() and GetResourceState('qbx_management') == 'started' then
                    lib.hideTextUI()
                    exports.qbx_management:OpenBossMenu('job')
                end
            end,
        })
    end
end

-- ------------------------------------------------------------
-- Police garage and helipad (the floor circles). rp_police runs these
-- itself and asks qbx_police's server to bring out the car, which
-- checks rank, division, duty and location again.
-- ------------------------------------------------------------

---Every garage car this server has, with `locked = true` on the ones this officer can't take yet.
local GARAGE_ENTRY = {}
for _, entry in ipairs(config.garage) do GARAGE_ENTRY[entry.model] = entry end

---Every police car must seat at least config.minSeats. 0 means the game doesn't know yet: allowed.
local function hasEnoughSeats(hash)
    local seats = GetVehicleModelNumberOfSeats(hash)
    return not config.minSeats or seats == 0 or seats >= config.minSeats
end

local function getGarageVehicles()
    local job = myDepartment()
    if not job then return nil end

    local list = {}
    for _, entry in ipairs(config.garage) do
        local hash = GetHashKey(entry.model)
        if IsModelInCdimage(hash) and hasEnoughSeats(hash) then
            local allowed = job.grade.level >= entry.minGrade and (not entry.cert or hasCert(entry.cert))
            list[#list + 1] = {
                model = entry.model,
                label = locale('vehicle.' .. entry.model),
                locked = not allowed,
                description = not allowed and locale('garage.needs', requirementText(job.name, entry)) or nil,
            }
        end
    end
    return list
end

---Checks the helipad rule and tells the officer why when they can't fly.
local function checkHelicopter()
    local job = myDepartment()
    if not job then return nil end

    local heli = config.helicopter
    if job.grade.level >= heli.minGrade and (not heli.cert or hasCert(heli.cert)) then return true end
    notify(locale('garage.heli_needs', requirementText(job.name, heli)), 'error')
    return false
end

-- Cars that can be parked back in the garage (only police cars, never someone's own car).
local PARKABLE = {}
for _, entry in ipairs(config.garage) do PARKABLE[GetHashKey(entry.model)] = true end
PARKABLE[GetHashKey(config.helicopter.model)] = true

local function onDutyOfficer()
    local job = myDepartment()
    return job ~= nil and job.onduty == true
end

---The officer's callsign as up to 5 single digits (from /callsign or the MDT).
local function callsignDigits()
    local raw = QBX.PlayerData.metadata and QBX.PlayerData.metadata.callsign
    local digits = {}
    for d in tostring(raw or ''):gmatch('%d') do
        digits[#digits + 1] = tonumber(d)
        if #digits == 5 then break end
    end
    return digits
end

---Fits the equipment from config.loadouts: livery, lightbar, interior, rank door tag, callsign numbers.
local function fitLoadout(vehicle, loadoutId, grade)
    local loadout = loadoutId and config.loadouts and config.loadouts[loadoutId]
    if not loadout then return end
    if not NetworkHasControlOfEntity(vehicle) then
        pcall(lib.waitFor, function()
            if NetworkHasControlOfEntity(vehicle) then return true end
            NetworkRequestControlOfEntity(vehicle)
        end, nil, 3000)
    end
    SetVehicleModKit(vehicle, 0)
    local function setMod(modType, index)
        if index < GetNumVehicleMods(vehicle, modType) then SetVehicleMod(vehicle, modType, index, false) end
    end
    for modType, index in pairs(loadout.mods or {}) do setMod(modType, index) end
    for extra, on in pairs(loadout.extras or {}) do
        if DoesExtraExist(vehicle, extra) then SetVehicleExtra(vehicle, extra, not on) end
    end
    if loadout.tagMod then
        local tag = loadout.tagByGrade and loadout.tagByGrade[grade]
        if tag then setMod(loadout.tagMod, tag) else RemoveVehicleMod(vehicle, loadout.tagMod) end
    end
    if loadout.callsignMods then
        local digits = callsignDigits()
        for i, modType in ipairs(loadout.callsignMods) do
            if digits[i] then setMod(modType, digits[i]) else RemoveVehicleMod(vehicle, modType) end
        end
    end
end

local function takeOut(model, marker, isHeli)
    lib.hideTextUI()
    local c = marker.coords
    local heading = marker.heading or 0.0
    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, model, vec4(c.x, c.y, c.z, heading), '', true)
    if not netId then return notify(locale('garage.failed'), 'error') end

    local ok, vehicle = pcall(lib.waitFor, function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            local entity = NetToVeh(netId)
            if entity ~= 0 then return entity end
        end
    end, nil, 10000)
    if not ok or not vehicle then return notify(locale('garage.failed'), 'error') end

    SetEntityHeading(vehicle, heading)
    SetVehicleFuelLevel(vehicle, 100.0)
    local entry = GARAGE_ENTRY[model]
    if entry and entry.loadout then
        local job = myDepartment()
        fitLoadout(vehicle, entry.loadout, job and job.grade.level or 0)
    end
    if isHeli then
        SetVehicleLivery(vehicle, 0)
        SetVehicleMod(vehicle, 0, 48, false)
    end
    SetVehicleEngineOn(vehicle, true, true, false)
end

local function openGarage(marker)
    local options = {}
    for _, vehicle in ipairs(getGarageVehicles() or {}) do
        options[#options + 1] = {
            title = vehicle.label,
            description = vehicle.description,
            icon = vehicle.locked and 'lock' or 'car',
            disabled = vehicle.locked,
            onSelect = function() takeOut(vehicle.model, marker, false) end,
        }
    end
    if #options == 0 then
        options[1] = { title = locale('garage.empty'), icon = 'circle-info', readOnly = true }
    end
    lib.registerContext({ id = 'rp_police_garage', title = locale('garage.title'), options = options })
    lib.showContext('rp_police_garage')
end

local function parkVehicle()
    local vehicle = cache.vehicle
    if not vehicle or GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then return end
    if not PARKABLE[GetEntityModel(vehicle)] then
        return notify(locale('garage.not_police'), 'error')
    end
    lib.hideTextUI()
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

for _, marker in ipairs(config.stationMarkers or {}) do
    if marker.point == 'garage' or marker.point == 'heli' then
        local isHeli = marker.point == 'heli'
        lib.zones.box({
            coords = marker.coords,
            size = isHeli and vec3(6.0, 6.0, 8.0) or vec3(3.0, 3.0, 6.0),
            onEnter = function()
                if not onDutyOfficer() then return end
                local key = cache.vehicle and 'station.park_prompt' or (isHeli and 'station.heli_prompt' or 'station.garage_prompt')
                lib.showTextUI(locale(key))
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if not IsControlJustReleased(0, 38) or not onDutyOfficer() then return end
                if cache.vehicle then return parkVehicle() end
                if isHeli then
                    if checkHelicopter() then
                        CreateThread(function() takeOut(config.helicopter.model, marker, true) end)
                    end
                else
                    openGarage(marker)
                end
            end,
        })
    end
end

-- ------------------------------------------------------------
-- Exports for other resources. Both return nil when the player isn't
-- in a department we manage.
-- ------------------------------------------------------------
exports('GetGarageVehicles', getGarageVehicles)
exports('CheckHelicopter', checkHelicopter)
exports('HasCert', hasCert)

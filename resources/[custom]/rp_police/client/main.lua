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
-- Exports for qbx_police (garage menu and helipad)
-- Both return nil when the player isn't in a department we manage,
-- so qbx_police falls back to its own rules.
-- ------------------------------------------------------------

---Every garage car this server has, with `locked = true` on the ones this officer can't take yet.
exports('GetGarageVehicles', function()
    local job = myDepartment()
    if not job then return nil end

    local list = {}
    for _, entry in ipairs(config.garage) do
        if IsModelInCdimage(GetHashKey(entry.model)) then
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
end)

---Checks the helipad rule and tells the officer why when they can't fly.
exports('CheckHelicopter', function()
    local job = myDepartment()
    if not job then return nil end

    local heli = config.helicopter
    if job.grade.level >= heli.minGrade and (not heli.cert or hasCert(heli.cert)) then return true end
    notify(locale('garage.heli_needs', requirementText(job.name, heli)), 'error')
    return false
end)

exports('HasCert', hasCert)

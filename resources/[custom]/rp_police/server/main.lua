-- ============================================================
--  rp_police - server side
--  The police structure behind the badge:
--    * division certifications (saved on the character as licences)
--    * the cadet training checklist (signed off by trainers)
--    * which cars and helicopter each officer may take
--    * the armory: clocked-in officers only, every sign-out logged
--    * a department log that command staff can read in game
--  The server is the boss: every request from a player's game is
--  checked again here, so nobody can give themselves a cert.
-- ============================================================
local config = require 'config'

local CERTS = {}     -- [certId] = { id, minGrade, icon }
for _, cert in ipairs(config.certs) do CERTS[cert.id] = cert end

local TRAINING = {}  -- [itemId] = position in the checklist
for i, item in ipairs(config.training) do TRAINING[item] = i end

local GARAGE = {}    -- [model] = { model, minGrade, cert }
for _, vehicle in ipairs(config.garage) do GARAGE[vehicle.model] = vehicle end

local LICENCE_PREFIX = 'police_' -- a cert called 'swat' is saved as the licence 'police_swat'

-- ------------------------------------------------------------
-- Database tables (created automatically the first time)
-- ------------------------------------------------------------
CreateThread(function()
    -- One row per signed training item.
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_police_training` (
            `citizenid`  VARCHAR(50)  NOT NULL,
            `item`       VARCHAR(30)  NOT NULL,
            `signed_by`  VARCHAR(100) NOT NULL,
            `signed_at`  INT UNSIGNED NOT NULL,
            PRIMARY KEY (`citizenid`, `item`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- The department log: certs granted or removed, training sign-offs, armory sign-outs.
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rp_police_log` (
            `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `citizenid`    VARCHAR(50)  NOT NULL,
            `name`         VARCHAR(100) NOT NULL,
            `action`       VARCHAR(30)  NOT NULL,
            `detail`       VARCHAR(255) NOT NULL,
            `by_name`      VARCHAR(100) NOT NULL,
            `created_at`   INT UNSIGNED NOT NULL,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`),
            KEY `created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end)

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function notify(source, text, kind)
    exports.qbx_core:Notify(source, text, kind or 'inform', 8000)
end

local function charName(player)
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname, info.lastname)
end

local function isStaff(source)
    return IsPlayerAceAllowed(source, config.staffAce)
end

---Is this character working (as their main job) in a department we manage?
local function isOfficer(player)
    local job = player and player.PlayerData.job
    return job ~= nil and config.departments[job.name] == true
end

local function gradeOf(player)
    return player.PlayerData.job.grade.level
end

local function shortDate(timestamp)
    return os.date('%b %d, %Y', timestamp)
end

-- Rank names come from qbx_core/shared/jobs.lua, so they're only written in one place.
local ranks = {} -- [department] = { ['0'] = 'Cadet', ... }

local function loadRanks()
    for department in pairs(config.departments) do
        local ok, job = pcall(function() return exports.qbx_core:GetJob(department) end)
        if ok and job and job.grades then
            local list = {}
            for level, grade in pairs(job.grades) do
                list[tostring(level)] = grade.name
            end
            ranks[department] = list
        end
    end
    GlobalState.rp_police_ranks = ranks -- players' games read rank names from here
end

local function rankName(department, level)
    local list = ranks[department]
    return list and list[tostring(level)] or locale('rank_fallback', level)
end

local function title(player)
    local job = player.PlayerData.job
    return ('%s %s'):format(rankName(job.name, job.grade.level), charName(player))
end

local function writeLog(target, action, detail, byName)
    MySQL.insert('INSERT INTO `rp_police_log` (`citizenid`, `name`, `action`, `detail`, `by_name`, `created_at`) VALUES (?, ?, ?, ?, ?, ?)', {
        target.PlayerData.citizenid, charName(target), action, detail:sub(1, 255), byName:sub(1, 100), os.time(),
    })
end

-- Command staff who are online (they hear about finished training and similar news).
local function tellCommand(department, text, except)
    for _, player in pairs(exports.qbx_core:GetQBPlayers()) do
        local job = player.PlayerData.job
        local src = player.PlayerData.source
        if src ~= except and job.name == department and job.grade.level >= config.certifyGrade then
            notify(src, text)
        end
    end
end

-- ------------------------------------------------------------
-- Certifications
-- ------------------------------------------------------------
local function hasCert(player, certId)
    local licences = player.PlayerData.metadata.licences
    return type(licences) == 'table' and licences[LICENCE_PREFIX .. certId] == true
end

local function setCert(player, certId, value)
    local licences = table.clone(player.PlayerData.metadata.licences or {})
    licences[LICENCE_PREFIX .. certId] = value and true or nil
    player.Functions.SetMetaData('licences', licences)
end

---Can `source` grant or remove certifications for `target`?
local function canManageCerts(source, caller, target)
    if isStaff(source) then return true end
    if not isOfficer(caller) or gradeOf(caller) < config.certifyGrade then return false end
    if caller.PlayerData.source == target.PlayerData.source then return false end -- nobody certifies themselves
    if caller.PlayerData.job.name ~= target.PlayerData.job.name then return false end
    return gradeOf(caller) > gradeOf(target) -- only officers below your rank
end

---Certs are tied to the badge: leaving the department removes them.
local function clearCertsIfGone(player)
    if not player then return end
    local jobs = player.PlayerData.jobs or { [player.PlayerData.job.name] = player.PlayerData.job.grade.level }
    for department in pairs(config.departments) do
        if jobs[department] then return end
    end

    local licences = table.clone(player.PlayerData.metadata.licences or {})
    local removed = {}
    for _, cert in ipairs(config.certs) do
        if hasCert(player, cert.id) then
            licences[LICENCE_PREFIX .. cert.id] = nil
            removed[#removed + 1] = locale(('cert.%s.label'):format(cert.id))
        end
    end
    if #removed == 0 then return end

    player.Functions.SetMetaData('licences', licences)
    writeLog(player, 'certs_cleared', table.concat(removed, ', '), locale('log.system'))
end

AddEventHandler('qbx_core:server:onGroupUpdate', function(source, groupName, grade)
    if grade == nil and config.departments[groupName] then
        clearCertsIfGone(getPlayer(source))
    end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    clearCertsIfGone(player)
end)

lib.callback.register('rp_police:server:getCerts', function(source, targetId)
    local caller = getPlayer(source)
    if not caller then return false end
    local target = targetId and getPlayer(targetId) or caller
    if not target then return false, 'not_online' end
    if not isOfficer(target) then return false, targetId and 'target_not_officer' or 'not_officer' end
    local isSelf = target.PlayerData.source == source
    if not isSelf and not isOfficer(caller) and not isStaff(source) then return false, 'not_officer' end

    local targetGrade = gradeOf(target)

    local list = {}
    for _, cert in ipairs(config.certs) do
        list[#list + 1] = {
            id = cert.id,
            icon = cert.icon,
            has = hasCert(target, cert.id),
            eligible = targetGrade >= cert.minGrade,
            minRank = rankName(target.PlayerData.job.name, cert.minGrade),
        }
    end

    return {
        target = target.PlayerData.source,
        title = title(target),
        certs = list,
        canManage = canManageCerts(source, caller, target),
    }
end)

lib.callback.register('rp_police:server:setCert', function(source, targetId, certId, value)
    local caller = getPlayer(source)
    local target = getPlayer(tonumber(targetId) or -1)
    local cert = CERTS[certId]
    if not caller or not target or not cert or type(value) ~= 'boolean' then return false, 'failed' end
    if not isOfficer(target) then return false, 'target_not_officer' end
    if not canManageCerts(source, caller, target) then return false, 'no_permission' end
    if value and gradeOf(target) < cert.minGrade then return false, 'too_junior' end
    if hasCert(target, certId) == value then return true end

    setCert(target, certId, value)

    local certLabel = locale(('cert.%s.label'):format(certId))
    local byName = isOfficer(caller) and title(caller) or charName(caller)
    writeLog(target, value and 'cert_granted' or 'cert_removed', certLabel, byName)
    notify(target.PlayerData.source, locale(value and 'certs.you_got' or 'certs.you_lost', certLabel), value and 'success' or 'inform')
    return true
end)

-- ------------------------------------------------------------
-- Cadet training
-- ------------------------------------------------------------
---Can this player sign off training? (FTO certification, Sergeant and up, or staff)
local function isTrainer(source, player)
    if isStaff(source) then return true end
    if not isOfficer(player) then return false end
    return gradeOf(player) >= config.trainGrade or hasCert(player, 'fto')
end

local function signedItems(citizenid)
    local rows = MySQL.query.await('SELECT `item`, `signed_by`, `signed_at` FROM `rp_police_training` WHERE `citizenid` = ?', { citizenid }) or {}
    local signed = {}
    for _, row in ipairs(rows) do
        if TRAINING[row.item] then signed[row.item] = row end
    end
    return signed
end

local function countSigned(signed)
    local count = 0
    for _ in pairs(signed) do count += 1 end
    return count
end

lib.callback.register('rp_police:server:getTraining', function(source, targetId)
    local caller = getPlayer(source)
    if not caller then return false end
    local target = targetId and getPlayer(targetId) or caller
    if not target then return false, 'not_online' end
    if not isOfficer(target) then return false, targetId and 'target_not_officer' or 'not_officer' end

    local isSelf = target.PlayerData.source == source
    local trainer = isTrainer(source, caller)
    if not isSelf and not trainer then return false, 'not_trainer' end

    local signed = signedItems(target.PlayerData.citizenid)
    local items = {}
    for _, itemId in ipairs(config.training) do
        local row = signed[itemId]
        items[#items + 1] = {
            id = itemId,
            signed = row ~= nil,
            by = row and row.signed_by or nil,
            on = row and shortDate(row.signed_at) or nil,
        }
    end

    return {
        target = target.PlayerData.source,
        title = title(target),
        items = items,
        done = countSigned(signed),
        total = #config.training,
        isCadet = gradeOf(target) < config.trainingDoneGrade,
        nextRank = rankName(target.PlayerData.job.name, config.trainingDoneGrade),
        canSign = trainer and not isSelf and gradeOf(target) < config.trainingDoneGrade,
    }
end)

lib.callback.register('rp_police:server:setTraining', function(source, targetId, itemId, value)
    local caller = getPlayer(source)
    local target = getPlayer(tonumber(targetId) or -1)
    if not caller or not target or not TRAINING[itemId] or type(value) ~= 'boolean' then return false, 'failed' end
    if not isOfficer(target) then return false, 'target_not_officer' end
    if not isTrainer(source, caller) then return false, 'not_trainer' end
    if target.PlayerData.source == source then return false, 'no_self' end
    if gradeOf(target) >= config.trainingDoneGrade then return false, 'not_cadet' end

    local citizenid = target.PlayerData.citizenid
    local itemLabel = locale(('training.%s.label'):format(itemId))
    local byName = isOfficer(caller) and title(caller) or charName(caller)

    if value then
        local added = MySQL.update.await('INSERT IGNORE INTO `rp_police_training` (`citizenid`, `item`, `signed_by`, `signed_at`) VALUES (?, ?, ?, ?)', {
            citizenid, itemId, byName:sub(1, 100), os.time(),
        })
        if not added or added == 0 then return true end -- already signed
        writeLog(target, 'training_signed', itemLabel, byName)
        notify(target.PlayerData.source, locale('training.you_signed', itemLabel, byName), 'success')
    else
        local removed = MySQL.update.await('DELETE FROM `rp_police_training` WHERE `citizenid` = ? AND `item` = ?', { citizenid, itemId })
        if not removed or removed == 0 then return true end -- wasn't signed
        writeLog(target, 'training_removed', itemLabel, byName)
        notify(target.PlayerData.source, locale('training.you_unsigned', itemLabel))
        return true
    end

    -- Was that the last item?
    if countSigned(signedItems(citizenid)) == #config.training then
        local nextRank = rankName(target.PlayerData.job.name, config.trainingDoneGrade)
        writeLog(target, 'training_done', nextRank, byName)
        notify(target.PlayerData.source, locale('training.you_finished', nextRank), 'success')
        tellCommand(target.PlayerData.job.name, locale('training.command_news', charName(target), nextRank), target.PlayerData.source)
    end
    return true
end)

-- ------------------------------------------------------------
-- Department log (/policelog)
-- ------------------------------------------------------------
lib.callback.register('rp_police:server:getLog', function(source, targetId)
    local caller = getPlayer(source)
    if not caller then return false end
    local staff = isStaff(source)
    if not staff and (not isOfficer(caller) or gradeOf(caller) < config.trainGrade) then return false, 'no_permission' end

    local rows, heading
    if targetId then
        local target = getPlayer(targetId)
        if not target then return false, 'not_online' end
        rows = MySQL.query.await('SELECT * FROM `rp_police_log` WHERE `citizenid` = ? ORDER BY `id` DESC LIMIT ?', { target.PlayerData.citizenid, config.logLimit })
        heading = charName(target)
    else
        rows = MySQL.query.await('SELECT * FROM `rp_police_log` ORDER BY `id` DESC LIMIT ?', { config.logLimit })
    end

    local list = {}
    for _, row in ipairs(rows or {}) do
        list[#list + 1] = {
            action = row.action,
            name = row.name,
            detail = row.detail,
            by = row.by_name,
            on = os.date('%b %d %H:%M', row.created_at),
        }
    end
    return { heading = heading, entries = list }
end)

-- ------------------------------------------------------------
-- Armory: clocked-in officers only, and every sign-out is logged
-- ------------------------------------------------------------
local armoryHandler -- the event handler below, kept so an ox_inventory restart doesn't add a second one

local function hookArmory()
    if GetResourceState('ox_inventory') ~= 'started' then return end

    local hookId = exports.ox_inventory:registerHook('buyItem', function(payload)
        local player = getPlayer(payload.source)
        if not player or not player.PlayerData.job.onduty then
            notify(payload.source, locale('armory.clock_in'), 'error')
            return false
        end
    end, { typeFilter = { [config.armoryShop] = true } })

    -- ox_inventory sends this event after the item is handed over.
    if armoryHandler then RemoveEventHandler(armoryHandler) end
    armoryHandler = AddEventHandler(hookId, function(success, payload)
        if not success then return end
        local player = getPlayer(payload.source)
        if not player then return end
        local item = exports.ox_inventory:Items(payload.itemName)
        local label = item and item.label or payload.itemName
        local serial = type(payload.metadata) == 'table' and payload.metadata.serial
        local detail = serial and locale('armory.log_serial', payload.count, label, serial) or locale('armory.log', payload.count, label)
        writeLog(player, 'armory', detail, isOfficer(player) and title(player) or charName(player))
    end)
end

AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' then hookArmory() end
    if resource == 'qbx_core' then loadRanks() end
end)

CreateThread(function()
    loadRanks()
    hookArmory()
end)

-- ------------------------------------------------------------
-- Commands
-- ------------------------------------------------------------
lib.addCommand('certs', {
    help = locale('command.certs_help'),
    params = { { name = 'id', type = 'playerId', help = locale('command.id_param'), optional = true } },
}, function(source, args)
    TriggerClientEvent('rp_police:client:openCerts', source, args.id)
end)

lib.addCommand('training', {
    help = locale('command.training_help'),
    params = { { name = 'id', type = 'playerId', help = locale('command.id_param'), optional = true } },
}, function(source, args)
    TriggerClientEvent('rp_police:client:openTraining', source, args.id)
end)

lib.addCommand('policelog', {
    help = locale('command.log_help'),
    params = { { name = 'id', type = 'playerId', help = locale('command.id_param'), optional = true } },
}, function(source, args)
    TriggerClientEvent('rp_police:client:openLog', source, args.id)
end)

lib.addCommand('penalcode', { help = locale('command.penalcode_help') }, function(source)
    TriggerClientEvent('rp_police:client:openPenalCode', source)
end)

-- ------------------------------------------------------------
-- Exports for other resources (qbx_police uses these)
-- Each returns nil when the player isn't in a department we manage,
-- so the other resource can fall back to its own rules.
-- ------------------------------------------------------------
local function vehicleVerdict(source, entry)
    local player = getPlayer(source)
    if not isOfficer(player) then return nil end
    if not entry or not player.PlayerData.job.onduty then return false end
    if gradeOf(player) < entry.minGrade then return false end
    if entry.cert and not hasCert(player, entry.cert) then return false end
    return true
end

exports('HasCert', function(source, certId)
    local player = getPlayer(source)
    return player ~= nil and hasCert(player, certId)
end)

exports('CanUseVehicle', function(source, model)
    return vehicleVerdict(source, GARAGE[model])
end)

exports('CanUseHelicopter', function(source)
    return vehicleVerdict(source, config.helicopter)
end)

-- ============================================================
--  rp_crews - server side
--  Crews live in memory: they end when everyone leaves, and on a
--  server restart. The bonus is paid each time a crew member
--  finishes a task (rp_jobmoments announces every finished task).
-- ============================================================
local config = require 'config'

local crews = {}    -- [crewId] = { id, leader, members = { [source] = true } }
local crewOf = {}   -- [source] = crewId
local invites = {}  -- [targetSource] = { from, crewId, expires }
local lastTask = {} -- [source] = { job, time }
local lastTip = {}  -- [source] = os.time() of the last "crews pay more" tip
local nextCrewId = 0

local BONUS_PCT = math.floor(config.bonusPerMate * 100 + 0.5)                   -- 10
local MAX_PCT = math.floor(config.bonusPerMate * config.maxMates * 100 + 0.5)   -- 30

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function charName(source)
    local player = getPlayer(source)
    if not player then return GetPlayerName(source) or ('#' .. source) end
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname, info.lastname)
end

local function notify(source, text, kind, duration)
    exports.qbx_core:Notify(source, text, kind or 'inform', duration or 7000)
end

local function memberList(crewId)
    local list = {}
    local crew = crews[crewId]
    if not crew then return list end
    for member in pairs(crew.members) do list[#list + 1] = member end
    table.sort(list)
    return list
end

local function crewSize(crewId)
    return #memberList(crewId)
end

local function tellCrew(crewId, text, except)
    for _, member in ipairs(memberList(crewId)) do
        if member ~= except then notify(member, text) end
    end
end

---Is this player working this job right now (finished a task in it recently)?
local function isWorking(source, job)
    local last = lastTask[source]
    if not last or last.job ~= job then return false end
    if os.time() - last.time > config.activeMinutes * 60 then return false end
    local player = getPlayer(source)
    return player ~= nil and player.PlayerData.job.name == job
end

local function leaveCrew(source, reasonKey)
    local crewId = crewOf[source]
    if not crewId then return end
    local crew = crews[crewId]
    crewOf[source] = nil
    if not crew then return end
    crew.members[source] = nil

    local left = memberList(crewId)
    if #left <= 1 then
        -- One person isn't a crew.
        for _, member in ipairs(left) do
            crewOf[member] = nil
            notify(member, locale('crew.disbanded'))
        end
        crews[crewId] = nil
        return
    end

    if crew.leader == source then
        crew.leader = left[1]
        notify(crew.leader, locale('crew.now_leader'))
    end
    tellCrew(crewId, locale(reasonKey or 'crew.member_left', charName(source)))
end

-- ------------------------------------------------------------
-- Invites
-- ------------------------------------------------------------
local function invite(source, target)
    target = tonumber(target)
    if not target or target == source then return false, 'bad_target' end
    if not getPlayer(target) then return false, 'bad_target' end
    if crewOf[target] then return false, 'target_in_crew' end

    local crewId = crewOf[source]
    if crewId and crewSize(crewId) >= config.maxSize then return false, 'crew_full' end

    invites[target] = { from = source, crewId = crewId, expires = os.time() + config.inviteSeconds }
    local inviterJob = getPlayer(source).PlayerData.job
    TriggerClientEvent('rp_crews:client:invited', target, charName(source), inviterJob.label or inviterJob.name)
    return true, charName(target)
end

lib.callback.register('rp_crews:server:invite', function(source, target)
    local ok, result = invite(source, target)
    if ok then notify(source, locale('crew.invite_sent', result), 'success') end
    return ok, result
end)

lib.callback.register('rp_crews:server:answerInvite', function(source, accept)
    local inv = invites[source]
    invites[source] = nil
    if not inv or os.time() > inv.expires then return false, 'invite_expired' end

    local inviter = inv.from
    if not getPlayer(inviter) then return false, 'invite_expired' end

    if not accept then
        notify(inviter, locale('crew.invite_declined', charName(source)))
        return true
    end
    if crewOf[source] then return false, 'target_in_crew' end

    -- Start a new crew if the inviter wasn't in one yet.
    local crewId = crewOf[inviter]
    if not crewId then
        nextCrewId += 1
        crewId = nextCrewId
        crews[crewId] = { id = crewId, leader = inviter, members = { [inviter] = true } }
        crewOf[inviter] = crewId
    end
    if crewSize(crewId) >= config.maxSize then return false, 'crew_full' end

    crews[crewId].members[source] = true
    crewOf[source] = crewId
    tellCrew(crewId, locale('crew.member_joined', charName(source)), source)
    notify(source, locale('crew.you_joined', BONUS_PCT, MAX_PCT), 'success', 10000)
    return true
end)

-- ------------------------------------------------------------
-- The crew menu
-- ------------------------------------------------------------
lib.callback.register('rp_crews:server:info', function(source)
    local crewId = crewOf[source]
    local info = { inCrew = crewId ~= nil, members = {}, maxSize = config.maxSize }
    if not crewId then return info end

    local crew = crews[crewId]
    info.isLeader = crew.leader == source
    for _, member in ipairs(memberList(crewId)) do
        local player = getPlayer(member)
        local job = player and player.PlayerData.job
        info.members[#info.members + 1] = {
            id = member,
            name = charName(member),
            job = job and (job.label or job.name) or '?',
            working = job and isWorking(member, job.name) or false,
            leader = crew.leader == member,
            me = member == source,
        }
    end
    return info
end)

---Names for the players standing near someone (for "Invite someone nearby").
lib.callback.register('rp_crews:server:names', function(source, ids)
    local names = {}
    if type(ids) ~= 'table' then return names end
    local myCoords = GetEntityCoords(GetPlayerPed(source))
    for i = 1, math.min(#ids, 16) do
        local id = tonumber(ids[i])
        local ped = id and GetPlayerPed(id)
        if ped and ped ~= 0 and id ~= source and getPlayer(id)
            and #(GetEntityCoords(ped) - myCoords) <= config.nearbyDistance + 5.0 then
            names[#names + 1] = { id = id, name = charName(id), inCrew = crewOf[id] ~= nil }
        end
    end
    return names
end)

lib.callback.register('rp_crews:server:leave', function(source)
    if not crewOf[source] then return false end
    leaveCrew(source)
    return true
end)

lib.callback.register('rp_crews:server:kick', function(source, target)
    local crewId = crewOf[source]
    target = tonumber(target)
    if not crewId or crews[crewId].leader ~= source or not target or crewOf[target] ~= crewId or target == source then return false end
    notify(target, locale('crew.you_were_removed'), 'error')
    leaveCrew(target, 'crew.member_removed')
    return true
end)

lib.addCommand('crew', {
    help = locale('command.crew_help'),
    params = { { name = 'id', type = 'playerId', help = locale('command.crew_param'), optional = true } },
}, function(source, args)
    if args.id then
        local ok, result = invite(source, args.id)
        if ok then
            notify(source, locale('crew.invite_sent', result), 'success')
        else
            notify(source, locale('error.' .. result), 'error')
        end
        return
    end
    TriggerClientEvent('rp_crews:client:openMenu', source)
end)

-- ------------------------------------------------------------
-- The bonus (and the "crews pay more" tip)
-- ------------------------------------------------------------
local function maybeTip(source)
    local now = os.time()
    if lastTip[source] and now - lastTip[source] < config.tipEveryMinutes * 60 then return end
    lastTip[source] = now
    notify(source, locale('tip.solo', BONUS_PCT, MAX_PCT), 'inform', 15000)
end

AddEventHandler('rp_jobmoments:server:taskDone', function(source, job, info)
    local jobConfig = config.jobs[job]
    if not jobConfig or not getPlayer(source) then return end

    local crewId = crewOf[source]
    local mates = 0
    if crewId then
        for _, member in ipairs(memberList(crewId)) do
            if member ~= source and isWorking(member, job) then mates += 1 end
        end
    end
    mates = math.min(mates, config.maxMates)
    lastTask[source] = { job = job, time = os.time() }

    if mates == 0 then
        if not crewId then maybeTip(source) end
        return
    end

    local value = jobConfig.useFare and (tonumber(info and info.fare) or 0) or jobConfig.taskValue
    local bonus = math.floor(value * config.bonusPerMate * mates + 0.5)
    if bonus < 1 then return end

    getPlayer(source).Functions.AddMoney(config.payAccount, bonus, 'crew-bonus')
    notify(source, locale('crew.bonus', bonus, mates, BONUS_PCT * mates), 'success', 5000)
end)

-- Tip when someone takes one of the crew jobs.
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    if not job or not config.jobs[job.name] or crewOf[source] then return end
    lastTip[source] = os.time()
    SetTimeout(4000, function()
        notify(source, locale('tip.new_job', job.label or job.name, BONUS_PCT, MAX_PCT), 'inform', 15000)
    end)
end)

AddEventHandler('playerDropped', function()
    local source = source
    leaveCrew(source, 'crew.member_left')
    invites[source] = nil
    lastTask[source] = nil
    lastTip[source] = nil
end)

-- ============================================================
--  rp_crews - client side (runs in each player's game)
--  The /crew menu and the invite pop-up. The server does the rest.
-- ============================================================
local config = require 'config'

local BONUS_PCT = math.floor(config.bonusPerMate * 100 + 0.5)
local MAX_PCT = math.floor(config.bonusPerMate * config.maxMates * 100 + 0.5)

local function notify(text, kind)
    lib.notify({ title = locale('title'), description = text, type = kind or 'inform', icon = 'people-group' })
end

local openMenu

local function sendInvite(target)
    local ok, result = lib.callback.await('rp_crews:server:invite', false, target)
    if not ok then notify(locale('error.' .. tostring(result)), 'error') end
end

---Players standing close by, for a quick invite.
local function inviteNearby()
    local myCoords = GetEntityCoords(cache.ped)
    local ids = {}
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= cache.playerId then
            local ped = GetPlayerPed(player)
            if #(GetEntityCoords(ped) - myCoords) <= config.nearbyDistance then
                ids[#ids + 1] = GetPlayerServerId(player)
            end
        end
    end

    local nearby = #ids > 0 and lib.callback.await('rp_crews:server:names', false, ids) or {}
    local options = {}
    for _, p in ipairs(nearby) do
        options[#options + 1] = {
            title = ('%s (%s)'):format(p.name, p.id),
            description = p.inCrew and locale('menu.already_in_crew') or locale('menu.tap_to_invite'),
            icon = 'user-plus',
            disabled = p.inCrew,
            onSelect = function() sendInvite(p.id) end,
        }
    end
    if #options == 0 then
        options[1] = { title = locale('menu.nobody_nearby'), description = locale('menu.nobody_nearby_desc'), readOnly = true }
    end

    lib.registerContext({ id = 'rp_crews_nearby', title = locale('menu.invite_nearby'), menu = 'rp_crews_menu', options = options })
    lib.showContext('rp_crews_nearby')
end

local function inviteById()
    local answer = lib.inputDialog(locale('menu.invite_by_id'), {
        { type = 'number', label = locale('menu.id_label'), description = locale('menu.id_desc'), required = true, min = 1 },
    })
    if answer and answer[1] then sendInvite(math.floor(answer[1])) end
end

local function memberMenu(member, isLeader)
    if member.me or not isLeader then return end
    local choice = lib.alertDialog({
        header = locale('menu.remove_header', member.name),
        content = locale('menu.remove_text', member.name),
        centered = true,
        cancel = true,
        labels = { confirm = locale('menu.remove_yes'), cancel = locale('menu.remove_no') },
    })
    if choice == 'confirm' then
        lib.callback.await('rp_crews:server:kick', false, member.id)
    end
    openMenu()
end

openMenu = function()
    local info = lib.callback.await('rp_crews:server:info', false)
    if not info then return end

    local options = {
        {
            title = locale('menu.how_title'),
            description = locale('menu.how_desc', BONUS_PCT, MAX_PCT, config.maxSize),
            icon = 'circle-info',
            readOnly = true,
        },
    }

    if info.inCrew then
        for _, m in ipairs(info.members) do
            local status = m.working and locale('menu.working', m.job) or locale('menu.not_working', m.job)
            options[#options + 1] = {
                title = ('%s%s (%s)'):format(m.leader and '★ ' or '', m.name, m.id) .. (m.me and locale('menu.you') or ''),
                description = status,
                icon = m.working and 'person-digging' or 'user',
                readOnly = m.me or not info.isLeader,
                onSelect = function() memberMenu(m, info.isLeader) end,
            }
        end
    end

    if #info.members < info.maxSize then
        options[#options + 1] = { title = locale('menu.invite_nearby'), icon = 'user-plus', onSelect = inviteNearby }
        options[#options + 1] = { title = locale('menu.invite_by_id'), description = locale('menu.invite_by_id_desc'), icon = 'hashtag', onSelect = inviteById }
    end

    if info.inCrew then
        options[#options + 1] = {
            title = locale('menu.leave'),
            icon = 'right-from-bracket',
            onSelect = function()
                lib.callback.await('rp_crews:server:leave', false)
                notify(locale('crew.you_left'))
            end,
        }
    end

    lib.registerContext({
        id = 'rp_crews_menu',
        title = info.inCrew and locale('menu.title_crew', #info.members, info.maxSize) or locale('menu.title_solo'),
        options = options,
    })
    lib.showContext('rp_crews_menu')
end

RegisterNetEvent('rp_crews:client:openMenu', function()
    if GetInvokingResource() then return end
    openMenu()
end)

RegisterNetEvent('rp_crews:client:invited', function(fromName, fromJob)
    if GetInvokingResource() then return end
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', false)
    local choice = lib.alertDialog({
        header = locale('invite.header'),
        content = locale('invite.text', fromName, fromJob, BONUS_PCT, MAX_PCT),
        centered = true,
        cancel = true,
        labels = { confirm = locale('invite.accept'), cancel = locale('invite.decline') },
    })
    local ok, err = lib.callback.await('rp_crews:server:answerInvite', false, choice == 'confirm')
    if not ok and err then notify(locale('error.' .. tostring(err)), 'error') end
end)

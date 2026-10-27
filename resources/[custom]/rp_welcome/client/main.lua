-- ============================================================
--  rp_welcome - client side
--  Shows a welcome pop-up (with our Discord link) that fades
--  away on its own, and adds /discord to copy the link.
-- ============================================================
local config = require 'config'

local shownThisSession = false

---The Discord link comes from server.cfg (setr qbx:discordLink), so it only lives in one place.
local function discordLink()
    local link = GetConvar('qbx:discordLink', '')
    if link == '' then return nil end
    if not link:find('^https?://') then link = 'https://' .. link end
    return link
end

local function showWelcome()
    if config.showOncePerSession and shownThisSession then return end
    shownThisSession = true

    local link = discordLink()
    lib.notify({
        title = locale('welcome.title'),
        description = link and locale('welcome.description', (link:gsub('^https?://', ''))) or locale('welcome.description_no_link'),
        type = 'inform',
        icon = 'city',
        duration = config.welcomeSeconds * 1000,
    })
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(config.delayAfterSpawn, showWelcome)
end)

-- /discord : copies the invite link so players can paste it in their browser or Discord
RegisterCommand('discord', function()
    local link = discordLink()
    if not link then
        return lib.notify({ description = locale('discord.no_link'), type = 'error' })
    end

    lib.setClipboard(link)
    lib.notify({
        title = locale('discord.title'),
        description = locale('discord.copied', link),
        type = 'success',
        icon = 'copy',
        duration = 8000,
    })
end, false)

TriggerEvent('chat:addSuggestion', '/discord', locale('discord.help'))

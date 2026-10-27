-- ============================================================
--  rp_welcome settings
--  The Discord link itself is set once in server.cfg:  setr qbx:discordLink "..."
--  All wording players see is in locales/en.json.
-- ============================================================
return {
    welcomeSeconds = 20,      -- how long the welcome pop-up stays on screen
    showOncePerSession = true, -- true = only the first time a player spawns after connecting
    delayAfterSpawn = 2000,   -- milliseconds to wait after spawning before showing it
}

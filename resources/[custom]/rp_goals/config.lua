-- ============================================================
--  rp_goals settings
--  Safe to tweak. Restart the resource after changing:
--  txAdmin Live Console ->  restart rp_goals
--  (All wording players see lives in locales/en.json, not here.)
-- ============================================================
return {
    -- Goal types players pick from. The names players see are in locales/en.json under "category".
    categories = { 'legal', 'criminal', 'service', 'personal' },

    -- Minimum and maximum length of each answer, in characters.
    limits = {
        goal      = { min = 15, max = 200 },
        reason    = { min = 15, max = 300 },
        firstStep = { min = 10, max = 120 },
    },

    -- How many days a character must wait before changing their goal.
    changeCooldownDays = 7,

    -- Remind players of their goal every time they spawn.
    reminderOnSpawn = true,
    reminderDuration = 12000, -- milliseconds the reminder stays on screen

    -- The goal screen waits for other menus (spawn picker, clothing editor) to close first.
    startDelay = 3000,       -- milliseconds to wait after spawning before checking
    clearScreenTime = 1500,  -- milliseconds the screen must stay free of other menus

    -- Who can use /goals to see everyone's goals (groups from permissions.cfg).
    -- 'support' includes mods and admins, because they inherit it.
    staffGroup = 'group.support',
    staffAce = 'support',
}

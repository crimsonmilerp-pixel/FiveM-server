-- ============================================================
--  rp_crews - settings
--  Players form a crew with /crew. Everyone still runs their own
--  route, but each task pays a bonus for every crewmate who's
--  also working the same job right now. All text: locales/en.json
-- ============================================================
return {
    maxSize = 4,           -- people in one crew, including the leader
    bonusPerMate = 0.10,   -- +10% for each crewmate working the same job...
    maxMates = 3,          -- ...counting up to 3 of them (so +30% at most)

    -- A crewmate counts as "working" if they finished a task in the same job within this many minutes.
    activeMinutes = 10,

    -- Which jobs get the crew bonus, and what one task is worth on average (the bonus is a share of this).
    -- Taxi uses the real fare instead.
    jobs = {
        garbage = { taskValue = 26 },  -- one stop
        tow     = { taskValue = 62 },  -- one tow, after the 15% "tax"
        trucker = { taskValue = 65 },  -- one store delivery, after the 15% "tax"
        taxi    = { useFare = true },
    },

    payAccount = 'bank',

    -- How often to remind someone working alone that crews pay more (minutes). They also get a tip when they take one of these jobs.
    tipEveryMinutes = 60,

    -- How long an invite stays open (seconds).
    inviteSeconds = 60,

    -- How close someone must be to show up in "Invite someone nearby" (meters).
    nearbyDistance = 10.0,
}

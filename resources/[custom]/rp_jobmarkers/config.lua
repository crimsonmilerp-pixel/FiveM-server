-- ============================================================
--  rp_jobmarkers - settings
--  "Work" map markers everyone can see, so new players know where
--  each job is before signing up at City Hall. A marker is hidden
--  for the job you already have (that job shows its own marker).
--  Names are in locales/en.json (marker.<job>).
-- ============================================================
return {
    markers = {
        { job = 'garbage', coords = vec3(-313.84, -1522.82, 27.56), sprite = 318, colour = 39 }, -- garbage depot
        { job = 'taxi',    coords = vec3(909.50, -177.35, 74.22),   sprite = 198, colour = 5 },  -- Downtown Cab Co.
        { job = 'tow',     coords = vec3(471.39, -1311.03, 29.21),  sprite = 477, colour = 15 }, -- tow yard
        { job = 'trucker', coords = vec3(153.00, -3211.68, 5.91),   sprite = 479, colour = 5 },  -- trucker shed
    },
    scale = 0.65,

    -- Walk or drive up to a depot without that job and get a hint about signing up (once per session per depot).
    hintDistance = 25.0,
}

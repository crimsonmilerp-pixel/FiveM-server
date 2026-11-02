-- ============================================================
--  rp_starter - settings
--  The starter area at the downtown bus station: the volunteer,
--  the free starter vehicle, the kiosk, and the short guided tour.
--  All text players see is in locales/en.json.
--
--  New characters arrive at qbx_core/config/shared.lua -> defaultSpawn.
--  To move anything here: stand on the spot in game, type /buyerhere
--  (it copies your position), and paste over the coords line.
-- ============================================================
return {
    -- The volunteer who greets new arrivals and hands out starter vehicles.
    volunteer = {
        ped = 'a_f_y_business_02',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        coords = vec4(457.00, -640.50, 28.90, 90.0),
    },

    -- The bus station kiosk (a small shop with the basics).
    kiosk = {
        ped = 'mp_m_shopkeep_01',
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        coords = vec4(454.50, -644.00, 28.90, 0.0),
        -- Same prices as the 24/7 stores (docs/economy.xlsx).
        items = {
            { name = 'water', price = 2 },
            { name = 'sprunk', price = 3 },
            { name = 'sandwich', price = 7 },
            { name = 'burger', price = 8 },
            { name = 'bandage', price = 6 },
            { name = 'painkillers', price = 12 },
            { name = 'repairkit', price = 150 },
        },
    },

    -- The free starter vehicle. One per character, and it can't be sold or traded.
    vehicles = {
        { model = 'asea',        kind = 'sedan' },
        { model = 'landstalker', kind = 'suv' },
        { model = 'pcj',         kind = 'motorcycle' },
        { model = 'chino',       kind = 'muscle' },
        { model = 'bobcatxl',    kind = 'truck' },
    },
    vehicleSpawn = vec4(462.22, -641.15, 28.45, 175.0), -- the bus depot's own vehicle spawn spot
    startFuel = 50.0, -- percent. Half a tank, so the tour's gas station stop means something.

    -- The guided tour, in order. 'visit' steps finish when you get close to the spot.
    steps = {
        { id = 'greet' },                                                     -- talk to the volunteer
        { id = 'vehicle' },                                                   -- pick your free vehicle
        { id = 'kiosk' },                                                     -- check out the kiosk
        { id = 'bank',     coords = vec3(149.97, -1040.75, 29.37), radius = 8.0 },   -- Fleeca, Legion Square
        { id = 'fuel',     coords = vec3(265.65, -1261.31, 29.29), radius = 20.0 },  -- gas station, Strawberry Ave
        { id = 'cityhall', coords = vec3(-265.00, -963.60, 31.20), radius = 10.0 },  -- City Hall (jobs and licenses)
        { id = 'goal' },                                                      -- your goal's first step
    },

    -- Staff can always skip the tour. Players can skip it on their 2nd and 3rd characters.
    staffAce = 'support',
}

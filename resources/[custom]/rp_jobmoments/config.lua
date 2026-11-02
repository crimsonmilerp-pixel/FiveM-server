-- ============================================================
--  rp_jobmoments - settings
--  Now and then, a small story event happens during a job and
--  hands the worker a choice. All text is in locales/en.json.
-- ============================================================
return {
    -- A moment happens on about 1 task in this many (a garbage stop or a taxi fare).
    oneIn = 20,

    -- At least this many minutes between two moments for the same player.
    cooldownMinutes = 10,

    -- Seconds a player has to pick a choice before the moment passes.
    choiceSeconds = 120,

    -- Staff who can see the private side of /cases (who kept what). 'support', 'mod' or 'admin'.
    staffAce = 'mod',

    -- Which moments each job can get. A higher weight = more common.
    jobs = {
        garbage = {
            { id = 'bloody_bag',  weight = 1 },
            { id = 'lost_wallet', weight = 2 },
        },
        taxi = {
            { id = 'left_bag', weight = 1 },
            { id = 'runner',   weight = 1 },
        },
        tow = {
            { id = 'tow_trunk', weight = 1 },
        },
        trucker = {
            { id = 'extra_package', weight = 1 },
        },
    },

    -- Doing the right thing (turning in evidence at a police front desk).
    -- On-duty police can log evidence too, but they don't get the reward.
    evidenceReward = 100,

    -- Police front desks where found evidence is turned in.
    -- They sit on the same spots as the police clock-in, so they're always reachable.
    desks = {
        { coords = vec3(440.085, -974.924, 30.689), radius = 1.5 },  -- Mission Row
        { coords = vec3(-449.811, 6012.909, 31.815), radius = 1.5 }, -- Paleto Bay
    },

    -- Garbage: a bag with a pistol and a bloody shirt
    bloodyBag = {
        weapon = 'WEAPON_PISTOL',
    },

    -- Garbage: a lost wallet
    wallet = {
        cash = 60,            -- cash inside, if they just take it
        returnReward = 100,   -- what the owner gives you for bringing it back
        ownerPeds = { 'a_f_m_downtown_01', 'a_m_m_eastsa_01', 'a_f_y_hipster_02', 'a_m_y_business_01', 'a_f_m_eastsa_01', 'a_m_m_mexlabor_01' },
        firstNames = { 'Maria', 'Dwayne', 'Lucy', 'Hector', 'Tamika', 'Gary', 'Rosa', 'Kevin', 'Alma', 'Terrence', 'Debbie', 'Luis' },
        lastNames = { 'Delgado', 'Fisher', 'Nguyen', 'Brooks', 'Ramirez', 'Kowalski', 'Washington', 'Patel', 'Hughes', 'Ortega' },
        -- Front doors of city homes (from qbx_houserobbery). The owner opens the door when you arrive.
        homes = {
            vec3(495.25, -1823.31, 28.87),
            vec3(311.99, -1956.12, 24.62),
            vec3(1193.67, -1656.54, 43.03),
            vec3(179.29, -1923.98, 21.37),
            vec3(-64.58, -1449.61, 32.52),
            vec3(-138.22, -1470.78, 36.99),
            vec3(-884.14, -1072.51, 2.53),
            vec3(-1134.11, -1050.19, 2.15),
            vec3(-1089.85, -1680.31, 4.67),
            vec3(960.01, -669.94, 58.45),
            vec3(1240.51, -601.62, 69.78),
            vec3(1098.57, -464.54, 67.32),
            vec3(69.43, -56.69, 73.02),
            vec3(-102.84, -11.91, 70.52),
            vec3(-332.97, 57.08, 54.43),
            vec3(-1009.5, 479.12, 79.59),
            vec3(-371.74, 343.46, 109.94),
            vec3(-174.65, 502.47, 137.42),
        },
    },

    -- Taxi: a passenger leaves a bag of cash in the back seat
    leftBag = {
        dirtyCash = 300, -- if kept, it's dirty money (needs laundering)
    },

    -- Tow: something in the trunk of the car you just towed
    towTrunk = {
        item = 'coke_brick', -- what they get if they keep it
    },

    -- Trucker: a box that isn't on the invoice, full of cash
    extraPackage = {
        dirtyCash = 400,                          -- if kept, it's dirty money (needs laundering)
        followUpMinutes = { min = 8, max = 15 },  -- when "someone" texts them about it
    },

    -- Taxi: the passenger runs off without paying
    runner = {
        seconds = 50,        -- how long you have to catch them
        grabDistance = 2.0,  -- how close you must be to grab them (meters)
        tipPercent = 25,     -- caught them? they pay the fare plus this much extra, out of embarrassment
    },
}

-- ============================================================
--  rp_vehicles settings (decided Oct 27, 2026)
--  Restart after changing:  restart rp_vehicles
-- ============================================================
return {
    -- Top speed limit for each kind of vehicle, in miles per hour. Leave a class out for no limit.
    -- Goal: police cars match or are a little faster than most cars citizens and criminals drive.
    -- These are starting values. Tune them after test drives.
    speedCapsMph = {
        [0]  = 100, -- Compacts
        [1]  = 105, -- Sedans
        [2]  = 100, -- SUVs
        [3]  = 110, -- Coupes
        [4]  = 115, -- Muscle
        [5]  = 110, -- Sports Classics
        [6]  = 120, -- Sports
        [7]  = 130, -- Super (rare and very expensive)
        [8]  = 120, -- Motorcycles
        [9]  = 95,  -- Off-road
        [10] = 70,  -- Industrial
        [11] = 75,  -- Utility
        [12] = 85,  -- Vans
        [17] = 75,  -- Service (buses, taxis)
        [18] = 125, -- Emergency: police, EMS, fire
        [20] = 75,  -- Commercial trucks
    },

    -- Extra top speed given to emergency vehicles so police cars can actually reach their limit.
    -- The limit above still applies, so this can never push them past 125 mph.
    emergencyBoost = 8.0,

    -- Vehicles that can never exist in the city: weaponized, armored, military, arena, and sci-fi.
    -- They are removed from dealerships (qbx_core/shared/vehicles.lua) AND blocked from spawning anywhere,
    -- including traffic and the military base. 152 models.
    blockedModels = {
        -- boats
        'avisa', 'dinghy5', 'kosatka', 'patrolboat', 'submersible', 'submersible2',
        -- commercial
        'cerberus', 'cerberus2', 'cerberus3', 'hauler2', 'mule4', 'phantom2',
        'phantom3', 'pounder2', 'terbyte',
        -- compacts
        'issi4', 'issi5', 'issi6',
        -- emergency
        'riot', 'riot2',
        -- helicopters
        'akula', 'annihilator', 'annihilator2', 'buzzard', 'cargobob', 'conada2',
        'hunter', 'savage', 'seasparrow', 'seasparrow2', 'seasparrow3', 'valkyrie',
        'valkyrie2',
        -- military
        'apc', 'barracks', 'barracks2', 'barracks3', 'barrage', 'chernobog',
        'crusader', 'halftrack', 'khanjali', 'minitank', 'rhino', 'scarab',
        'scarab2', 'scarab3', 'thruster', 'trailersmall2', 'vetir',
        -- motorcycles
        'deathbike', 'deathbike2', 'deathbike3', 'manchez3', 'oppressor', 'oppressor2',
        'rrocket', 'shotaro',
        -- muscle
        'dominator4', 'dominator5', 'dominator6', 'dukes2', 'impaler2', 'impaler3',
        'impaler4', 'imperator', 'imperator2', 'imperator3', 'ruiner2', 'slamvan4',
        'slamvan5', 'slamvan6', 'tampa3',
        -- offroad
        'blazer5', 'bruiser', 'bruiser2', 'bruiser3', 'brutus', 'brutus2',
        'brutus3', 'caracara', 'dune2', 'dune3', 'dune4', 'dune5',
        'insurgent', 'insurgent2', 'insurgent3', 'menacer', 'monster', 'monster3',
        'monster4', 'monster5', 'monstrociti', 'nightshark', 'patriot3', 'rcbandito',
        'technical', 'technical2', 'technical3', 'winky', 'zhaba',
        -- planes
        'alkonost', 'avenger', 'avenger2', 'avenger3', 'avenger4', 'besra',
        'bombushka', 'hydra', 'lazer', 'mogul', 'molotok', 'nokota',
        'pyro', 'raiju', 'rogue', 'starling', 'strikeforce', 'titan',
        'tula', 'volatol',
        -- sedans
        'cog552', 'cognoscenti2', 'limo2', 'schafter5', 'schafter6',
        -- service
        'brickade', 'brickade2', 'wastelander',
        -- sports
        'kuruma2', 'paragon2', 'zr380', 'zr3802', 'zr3803',
        -- sportsclassics
        'ardent', 'deluxo', 'jb7002', 'stromberg', 'toreador',
        -- super
        'champion', 'scramjet', 'vigilante', 'voltic2',
        -- suvs
        'baller5', 'baller6', 'squaddie', 'xls2',
        -- utility
        'trailerlarge',
        -- vans
        'boxville5', 'speedo4', 'speedo5',
    },
}

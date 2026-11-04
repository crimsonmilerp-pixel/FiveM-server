-- ============================================================
--  rp_police - settings
--  The police structure: which departments are open, who can do
--  what at which rank, the division certifications, the cadet
--  training checklist, and which vehicles each officer may take.
--  Ranks and pay live in qbx_core/shared/jobs.lua (police job):
--    0 Cadet, 1 Officer I, 2 Officer II, 3 Officer III,
--    4 Sergeant, 5 Lieutenant, 6 Captain, 7 Chief
--  All text players see: locales/en.json.  Penal code: data/penalcode.lua
-- ============================================================
return {
    -- Police jobs this resource manages. LSPD covers the whole map at launch; BCSO and SASP
    -- stay in jobs.lua for later, when there are enough officers to split (decided Nov 2).
    departments = { police = true },

    -- Staff with this ACE can do everything here (grant certifications, sign off training).
    staffAce = 'admin',

    -- Lowest rank that can grant or remove division certifications (5 = Lieutenant).
    certifyGrade = 5,

    -- Lowest rank that can sign off cadet training without the Field Training Officer certification (4 = Sergeant).
    trainGrade = 4,

    -- Division certifications. Each is saved on the character as the licence "police_<id>",
    -- which is also what the armory checks (ox_inventory shops.lua: license = 'police_swat').
    -- minGrade: lowest rank that can hold it.
    certs = {
        { id = 'traffic',   minGrade = 2, icon = 'gauge-high' },        -- Traffic Division: the pursuit cars
        { id = 'detective', minGrade = 3, icon = 'magnifying-glass' },  -- Detectives: unmarked cars, investigations
        { id = 'air',       minGrade = 2, icon = 'helicopter' },        -- Air Support: the police helicopter
        { id = 'swat',      minGrade = 3, icon = 'shield-halved' },     -- SWAT: heavy gear and SWAT vehicles
        { id = 'fto',       minGrade = 3, icon = 'chalkboard-user' },   -- Field Training Officer: trains cadets
    },

    -- Cadet training, signed off one item at a time by an FTO (or a Sergeant+).
    -- When every item is signed, command staff are told the cadet is ready for Officer I.
    training = {
        'orientation', 'radio', 'rideAlong1', 'rideAlong2', 'rideAlong3',
        'trafficStop', 'arrest', 'pursuit', 'test',
    },
    trainingDoneGrade = 1, -- the rank a cadet is ready for once training is complete (1 = Officer I)

    -- Police garage: which vehicles an officer may take out.
    --   minGrade = lowest rank, cert = division certification needed (optional),
    --   loadout = equipment fitted when the car comes out (see loadouts below).
    -- Officers see every car here; the ones they can't take yet show what they need (a goal to work toward).
    -- Cars missing from the server's game version are hidden automatically. Names: locales/en.json (vehicle.*).
    -- Sheriff and Park Ranger cars are left out on purpose: they belong to BCSO and the rangers when those open.
    -- Every police car seats at least 4 (two officers and two in the back). Anything smaller is hidden (minSeats).
    minSeats = 4,
    garage = {
        { model = 'police',        minGrade = 0 },                    -- Stanier cruiser
        { model = 'police5',       minGrade = 0 },                    -- Stanier LE cruiser
        { model = 'policet',       minGrade = 0 },                    -- Transport van (prisoner transport)
        { model = 'police2',       minGrade = 1 },                    -- Buffalo cruiser
        { model = 'polgreenwood',  minGrade = 1 },                    -- Greenwood cruiser
        { model = 'polcaracara',   minGrade = 1 },                    -- Caracara pursuit truck (rural and off-road)
        { model = 'police3',       minGrade = 2, cert = 'traffic' },  -- Interceptor
        { model = 'polimpaler5',   minGrade = 2, cert = 'traffic' },  -- Impaler SZ pursuit car
        { model = 'onx_polscout',  minGrade = 4, loadout = 'scout' }, -- Vapid Scout SUV: supervisors and command (resources/[onx_vehicles])
        { model = 'onx_polvstr',   minGrade = 6, loadout = 'vstr' },  -- Presidente VSTR command car: Captain and Chief only (resources/[onx_vehicles])
        { model = 'police4',       minGrade = 3, cert = 'detective' },-- Unmarked Stanier
        { model = 'fbi',           minGrade = 3, cert = 'detective' },-- Unmarked Buffalo
        { model = 'fbi2',          minGrade = 3, cert = 'swat' },     -- Unmarked Granger (SWAT)
        { model = 'polterminus',   minGrade = 3, cert = 'swat' },     -- Terminus patrol (SWAT)
    },

    -- Equipment fitted to a car when it leaves the garage. The numbers come from the car's
    -- carcols.meta (mod type = list position): see docs/police-vehicles.md for every option.
    -- Lightbars: the ONX cars' own lightbar is extra 1. Don't set mod 49 (lightbar) above 3: those
    -- lightbars come from ONX's paid companion pack, which we don't have, so the roof would be empty.
    loadouts = {
        scout = { -- ONX Vapid Scout (onx_polscout)
            mods = {
                [48] = 0,  -- livery: LSPD
                [10] = 0,  -- roof: city (metropolitan) antennas
                [32] = 0,  -- back: window bars (the back seats stay for prisoners)
                [28] = 7,  -- front console: LSPD laptop (MDW LSPD)
                [27] = 0,  -- cabin lights off (it has a lightbar)
                [30] = 1,  -- rifle rack on the divider
                [34] = 0,  -- dash radar
                [8]  = 0,  -- driver spotlight (controllable)
                [9]  = 0,  -- passenger spotlight
                [35] = 1,  -- push bar
                [26] = 0,  -- trunk badges
                [37] = 6,  -- trunk lockbox, tidy
            },
            extras = { [1] = true, [2] = false, [3] = false, [4] = false, [5] = false, [6] = false, [7] = false, [8] = false, [9] = false }, -- 1 = lightbar
            -- Door tag by rank: 0 = Supervisor, 1 = Command. Ranks not listed get no tag.
            tagMod = 46,
            tagByGrade = { [4] = 0, [5] = 0, [6] = 1, [7] = 1 },
            -- The 5 callsign number slots, left to right (number n = mod n). Filled from the officer's
            -- callsign (/callsign or the MDT). Officers without one get no numbers.
            callsignMods = { 5, 42, 43, 44, 45 },
        },
        vstr = { -- ONX Albany Presidente VSTR (onx_polvstr): the command car
            mods = {
                [48] = 0,  -- livery: LSPD
                [32] = 1,  -- back: window bars (the back seats stay for prisoners)
                [28] = 7,  -- front console: LSPD laptop (MDW LSPD)
                [27] = 0,  -- cabin lights off (it has a lightbar)
                [30] = 2,  -- rifle rack on the divider
                [34] = 0,  -- dash radar
                [8]  = 0,  -- driver spotlight (controllable)
                [9]  = 0,  -- passenger spotlight
            },
            extras = { [1] = true, [2] = false, [3] = false, [4] = false, [5] = false, [6] = false, [7] = false, [8] = false, [9] = false }, -- 1 = lightbar, 2 = push bar (off: command car)
            tagMod = 46,
            tagByGrade = { [6] = 1, [7] = 1 }, -- Command tag
            -- This car has 3 callsign number slots, so it shows the first 3 digits.
            callsignMods = { 5, 42, 43 },
        },
    },

    -- The police helicopter (taken at the helipad, not the garage).
    -- Keep the model the same as policeHelicopter in qbx_police/config/client.lua.
    helicopter = { model = 'polmav', minGrade = 2, cert = 'air' },

    -- The ox_inventory shop that hands out police gear (ox_inventory/data/shops.lua).
    -- Officers must be clocked in to sign gear out, and every sign-out is written to the department log.
    armoryShop = 'PoliceArmoury',

    -- How many entries /policelog shows.
    logLimit = 40,

    -- Floor markers with a label at the police station, so officers can find things.
    -- Only officers see them. They only SHOW where things are: the real spots are set
    -- in the file named on each line, so move a marker when you move the real spot.
    --   show = 'always' (every officer), 'duty' (clocked in only), 'boss' (Captain and Chief)
    --   point = which label to show (locales/en.json, station.*)
    stationMarkers = {
        -- qbx_police/config/shared.lua (locations.duty): stand here and press E to clock in or out
        { point = 'duty',    show = 'always', coords = vec3(440.09, -974.92, 30.69) },  -- Mission Row front desk
        { point = 'duty',    show = 'always', coords = vec3(-449.81, 6012.91, 31.82) }, -- Paleto Bay station
        -- illenium-appearance/shared/config.lua (Config.ClothingRooms): uniforms
        { point = 'locker',  show = 'always', coords = vec3(454.91, -990.89, 30.69) },
        -- The captain's desk. rp_police opens the boss menu here itself (qbx_management: hire, promote, fire)
        { point = 'boss',    show = 'boss',   coords = vec3(448.4, -973.2, 30.69) },
        -- ox_inventory/data/shops.lua (PoliceArmoury targets): hold Left Alt and click
        { point = 'armory',  show = 'duty',   coords = vec3(453.21, -980.03, 30.68) },
        -- Police cars: rp_police runs these spots itself (press E for the car list, or to park a police car).
        -- They must match qbx_police/config/shared.lua (locations.vehicle): its server checks the spot.
        { point = 'garage',  show = 'duty',   coords = vec3(452.0, -996.0, 26.0),   heading = 175.0 },
        { point = 'garage',  show = 'duty',   coords = vec3(447.0, -997.0, 26.0),   heading = 178.0 },
        { point = 'garage',  show = 'duty',   coords = vec3(463.0, -1019.0, 28.0),  heading = 87.0 },
        { point = 'garage',  show = 'duty',   coords = vec3(463.0, -1015.0, 28.0),  heading = 87.0 },
        -- qbx_police/config/shared.lua (locations.impound)
        { point = 'impound', show = 'duty',   coords = vec3(436.68, -1007.42, 27.32) },
        { point = 'impound', show = 'duty',   coords = vec3(-436.14, 5982.63, 31.34) },
        -- Helipads: rp_police runs these too. Must match qbx_police/config/shared.lua (locations.helicopter).
        { point = 'heli',    show = 'duty',   coords = vec3(449.17, -981.33, 43.69), heading = 87.23 },
        { point = 'heli',    show = 'duty',   coords = vec3(-475.43, 5988.35, 31.72), heading = 31.34 },
    },
    markerDrawDistance = 25.0, -- markers show within this many meters
    markerLabelDistance = 8.0, -- labels show within this many meters
}

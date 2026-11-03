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
        { id = 'traffic',   minGrade = 2, icon = 'gauge-high' },        -- Traffic Division: interceptors, motorcycles
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
    --   minGrade = lowest rank, cert = division certification needed (optional).
    -- Officers see every car here; the ones they can't take yet show what they need (a goal to work toward).
    -- Cars missing from the server's game version are hidden automatically. Names: locales/en.json (vehicle.*).
    -- Sheriff and Park Ranger cars are left out on purpose: they belong to BCSO and the rangers when those open.
    garage = {
        { model = 'police',        minGrade = 0 },                    -- Stanier cruiser
        { model = 'police5',       minGrade = 0 },                    -- Stanier LE cruiser
        { model = 'police2',       minGrade = 1 },                    -- Buffalo cruiser
        { model = 'polgreenwood',  minGrade = 1 },                    -- Greenwood cruiser
        { model = 'polimpaler5',   minGrade = 1 },                    -- Impaler SZ cruiser
        { model = 'polcaracara',   minGrade = 1 },                    -- Caracara pursuit truck (rural and off-road)
        { model = 'policet',       minGrade = 0 },                    -- Transport van (prisoner transport)
        { model = 'police3',       minGrade = 2, cert = 'traffic' },  -- Interceptor
        { model = 'polgauntlet',   minGrade = 2, cert = 'traffic' },  -- Gauntlet interceptor
        { model = 'poldominator10', minGrade = 2, cert = 'traffic' }, -- Dominator FX interceptor
        { model = 'policeb',       minGrade = 2, cert = 'traffic' },  -- Police motorcycle
        { model = 'police4',       minGrade = 3, cert = 'detective' },-- Unmarked Stanier
        { model = 'fbi',           minGrade = 3, cert = 'detective' },-- Unmarked Buffalo
        { model = 'fbi2',          minGrade = 3, cert = 'swat' },     -- Unmarked Granger (SWAT)
        { model = 'polterminus',   minGrade = 3, cert = 'swat' },     -- Terminus patrol (SWAT)
    },

    -- The police helicopter (taken at the helipad, not the garage).
    -- Keep the model the same as policeHelicopter in qbx_police/config/client.lua.
    helicopter = { model = 'polmav', minGrade = 2, cert = 'air' },

    -- The ox_inventory shop that hands out police gear (ox_inventory/data/shops.lua).
    -- Officers must be clocked in to sign gear out, and every sign-out is written to the department log.
    armoryShop = 'PoliceArmoury',

    -- How many entries /policelog shows.
    logLimit = 40,
}

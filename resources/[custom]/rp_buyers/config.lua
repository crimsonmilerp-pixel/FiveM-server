-- ============================================================
--  rp_buyers - settings
--  NPC buyers who pay for legal goods players gather or make.
--  Names players see are in locales/en.json (buyer.<id>).
-- ============================================================
return {
    -- Where the money goes: 'cash' or 'bank'
    payAccount = 'cash',

    -- How close (in meters) a player must be to the buyer to sell.
    sellDistance = 4.0,

    -- Staff group that can use /buyerhere (copies your position for moving a buyer).
    staffGroup = 'group.admin',

    -- NPCs only exist while a player is within this many meters (saves performance).
    spawnDistance = 60.0,

    buyers = {
        -- Scrap buyer at the Sandy Shores scrap yard, beside the yard's own NPC.
        -- Buys the materials you get from scrapping cars there.
        -- Prices: real US scrap-yard prices per pound (Oct 2026). One item = 1 lb.
        scrapyard = {
            ped = 's_m_m_dockwork_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            coords = vec4(2404.54, 3130.77, 48.15, 250.0),
            items = {
                { name = 'copper',     price = 4.70 },
                { name = 'aluminum',   price = 0.60 },
                { name = 'steel',      price = 0.10 },
                { name = 'iron',       price = 0.10 },
                { name = 'metalscrap', price = 0.10 },
                { name = 'plastic',    price = 0.10 },
                { name = 'glass',      price = 0.05 },
                { name = 'rubber',     price = 0.05 },
            },
        },

        -- Wine buyer, standing at the Marlowe Vineyard.
        -- Wholesale prices (the liquor store sells wine for $15).
        winery = {
            ped = 'a_m_m_farmer_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            coords = vec4(-1877.35, 2132.57, 127.93, 180.0),
            items = {
                { name = 'wine',       price = 6.00 },
                { name = 'grapejuice', price = 1.50 },
            },
        },
    },
}

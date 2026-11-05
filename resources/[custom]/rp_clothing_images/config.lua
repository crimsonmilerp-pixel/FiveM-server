-- ============================================================
--  rp_clothing_images - settings for the photo tool
--  Only staff use the tool (/clothingphotos). Players just see the pictures.
-- ============================================================
Config = {}

-- Where the mannequin stands while the photos are taken: open tarmac at the airport,
-- nothing tall nearby. The player is put in their own empty world (no traffic, no other players).
Config.Spot = vector4(-1224.22, -3349.63, 13.96, 180.0)

-- Frozen weather and time for even light
Config.Weather = 'EXTRASUNNY'
Config.Hour = 13

-- Screenshot size. Bigger is slower; 1280x720 is plenty for 128 px pictures.
Config.Width = 1280
Config.Height = 720

Config.Tile = 128     -- picture size in pixels
Config.Columns = 16   -- pictures per row in each picture sheet

-- Clothing packs we skip (the police uniforms are locked to police anyway)
Config.SkipCollections = { 'rp_eup' }

-- One entry per clothing slot, in the order they are photographed.
--   kind: 'c' clothing, 'p' prop (hats, glasses...)
--   mode: 'item' shows only the item; 'body' also shows the head under it (hair, hats, glasses, masks, earrings)
--   z: camera height from the hips (meters), fov: zoom (smaller = closer), yaw: camera angle around the body
--   yaws: two or more camera angles; each item keeps the angle where more of it shows
Config.Slots = {
    { key = 'c11', kind = 'c', id = 11, mode = 'item', z = 0.25, fov = 70, yaw = 0 },   -- tops
    { key = 'c8',  kind = 'c', id = 8,  mode = 'item', z = 0.25, fov = 65, yaw = 0 },   -- undershirts
    { key = 'c3',  kind = 'c', id = 3,  mode = 'item', z = 0.15, fov = 75, yaw = 0 },   -- arms and gloves
    { key = 'c4',  kind = 'c', id = 4,  mode = 'item', z = -0.45, fov = 70, yaw = 0 },  -- pants
    { key = 'c6',  kind = 'c', id = 6,  mode = 'item', z = -0.85, fov = 45, yaw = 35 }, -- shoes
    { key = 'c1',  kind = 'c', id = 1,  mode = 'body', z = 0.62, fov = 40, yaw = 15 },  -- masks
    { key = 'c7',  kind = 'c', id = 7,  mode = 'item', z = 0.35, fov = 55, yaw = 0 },   -- chains and ties
    { key = 'c5',  kind = 'c', id = 5,  mode = 'item', z = 0.20, fov = 70, yaw = 180 }, -- bags (from behind)
    { key = 'c2',  kind = 'c', id = 2,  mode = 'body', z = 0.68, fov = 35, yaw = 25 },  -- hair
    { key = 'p0',  kind = 'p', id = 0,  mode = 'body', z = 0.75, fov = 38, yaw = 20 },  -- hats
    { key = 'p1',  kind = 'p', id = 1,  mode = 'body', z = 0.66, fov = 25, yaw = 15 },  -- glasses
    { key = 'p2',  kind = 'p', id = 2,  mode = 'body', z = 0.64, fov = 20, yaws = { 55, -55 } }, -- earrings (both ears)
    { key = 'p6',  kind = 'p', id = 6,  mode = 'item', z = -0.05, fov = 22, yaw = 0 },  -- watches (both wrists in view)
    { key = 'p7',  kind = 'p', id = 7,  mode = 'item', z = -0.05, fov = 22, yaw = 0 },  -- bracelets
}

Config.CameraDistance = 1.2

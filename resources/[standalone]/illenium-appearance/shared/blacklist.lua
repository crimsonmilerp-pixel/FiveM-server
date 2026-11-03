-- ============================================================
-- [OUR CHANGE] Clothing blacklist (Pillar C: a grounded world). Generated, do not edit by hand:
-- change docs/clothing-blacklist/rules.py and ask Claude to rebuild it. See docs/core-changes.md
--
-- Hidden items are grouped by an ACE permission. Anyone who has the permission sees that group again:
--   clothing.festive    Christmas, Valentine's, Thanksgiving, New Year's (switch on in season)
--   clothing.halloween  horror and monster costumes (switch on in October)
--   clothing.costume    cartoon characters, mascots, sci-fi, glowing, apocalypse armor
--   clothing.racy       lingerie
-- Switch a group on for everyone in permissions.cfg (or live in the txAdmin console):
--   add_ace builtin.everyone clothing.festive allow
-- ============================================================
Config.Blacklist = {
    male = {
        hair = {},
        components = {
            masks = {
                { aces = { 'clothing.festive' }, drawables = { 8, 9, 10, 13, 33, 34, 74, 75, 76, 77, 78, 83, 84, 85, 86, 87, 88, 127, 131, 218, 228, 233 } },
                { aces = { 'clothing.halloween' }, drawables = { 7, 39, 40, 41, 42, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 103, 136, 190, 191, 192, 198, 199, 201, 202, 204, 205, 206, 207, 209, 210, 221, 222, 223, 224, 225, 230, 243, 244, 245, 246, 251 } },
                { aces = { 'clothing.halloween' }, drawables = { 14 }, textures = { 11, 12 } },
                { aces = { 'clothing.costume' }, drawables = { 3, 16, 43, 44, 45, 79, 80, 81, 82, 92, 93, 94, 98, 105, 106, 110, 124, 137, 138, 142, 143, 144, 145, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 164, 165, 170, 171, 172, 173, 176, 177, 179, 183, 188, 189, 193, 195, 196, 197, 203, 208, 213, 214, 234 } },
                { aces = { 'clothing.costume' }, drawables = { 175 }, textures = { 3 } },
            },
            upperBody = {},
            lowerBody = {
                { aces = { 'clothing.festive' }, drawables = { 19 } },
                { aces = { 'clothing.festive' }, drawables = { 32 }, textures = { 3 } },
                { aces = { 'clothing.festive' }, drawables = { 186 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 222 }, textures = { 2 } },
                { aces = { 'clothing.costume' }, drawables = { 107, 177 } },
                { aces = { 'clothing.costume' }, drawables = { 211 }, textures = { 0 } },
            },
            bags = {},
            shoes = {
                { aces = { 'clothing.festive' }, drawables = { 17 } },
                { aces = { 'clothing.costume' }, drawables = { 77, 84, 85, 86 } },
            },
            scarfAndChains = {
                { aces = { 'clothing.festive' }, drawables = { 18, 19, 194, 195 } },
                { aces = { 'clothing.festive' }, drawables = { 34 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 35 }, textures = { 1, 2 } },
                { aces = { 'clothing.costume' }, drawables = { 149, 150 } },
            },
            shirts = {
                { aces = { 'clothing.festive' }, drawables = { 19, 20 } },
                { aces = { 'clothing.festive' }, drawables = { 184 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 185 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 186 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 187 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 188 }, textures = { 0, 1 } },
            },
            bodyArmor = {},
            decals = {},
            jackets = {
                { aces = { 'clothing.festive' }, drawables = { 18, 19, 51, 194, 195, 196, 197, 198, 245, 288, 326, 430, 431, 432, 531, 559, 594 } },
                { aces = { 'clothing.festive' }, drawables = { 46 }, textures = { 1 } },
                { aces = { 'clothing.festive' }, drawables = { 52 }, textures = { 3 } },
                { aces = { 'clothing.festive' }, drawables = { 117 }, textures = { 3, 7, 9, 11, 12, 13, 14, 15 } },
                { aces = { 'clothing.festive' }, drawables = { 199 }, textures = { 1, 2, 3, 5 } },
                { aces = { 'clothing.festive' }, drawables = { 392 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 457 }, textures = { 3 } },
                { aces = { 'clothing.festive' }, drawables = { 514 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 515 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 607 }, textures = { 0 } },
                { aces = { 'clothing.halloween' }, drawables = { 407 } },
                { aces = { 'clothing.halloween' }, drawables = { 414 }, textures = { 0 } },
                { aces = { 'clothing.halloween' }, drawables = { 415 }, textures = { 0 } },
                { aces = { 'clothing.costume' }, drawables = { 275, 482, 560, 561 } },
            },
        },
        props = {
            hats = {
                { aces = { 'clothing.festive' }, drawables = { 22, 23, 24, 40, 41, 42, 97, 98, 99, 100, 101, 166, 167, 168, 171, 178, 186, 211, 212, 214, 217 } },
                { aces = { 'clothing.festive' }, drawables = { 44 }, textures = { 6, 7 } },
                { aces = { 'clothing.festive' }, drawables = { 45 }, textures = { 6, 7 } },
                { aces = { 'clothing.costume' }, drawables = { 1, 33, 35, 36, 37, 91, 92, 246 } },
            },
            glasses = {
                { aces = { 'clothing.festive' }, drawables = { 44 } },
                { aces = { 'clothing.costume' }, drawables = { 21, 22, 30 } },
            },
            ear = {},
            watches = {},
            bracelets = {},
        },
    },
    female = {
        hair = {},
        components = {
            masks = {
                { aces = { 'clothing.festive' }, drawables = { 8, 9, 10, 13, 33, 34, 74, 75, 76, 77, 78, 83, 84, 85, 86, 87, 88, 127, 131, 219, 229, 234 } },
                { aces = { 'clothing.halloween' }, drawables = { 7, 39, 40, 41, 42, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 103, 136, 191, 192, 193, 199, 200, 202, 203, 205, 206, 207, 208, 210, 211, 222, 223, 224, 225, 226, 231, 244, 245, 246, 247, 252 } },
                { aces = { 'clothing.halloween' }, drawables = { 14 }, textures = { 11, 12 } },
                { aces = { 'clothing.costume' }, drawables = { 3, 16, 43, 44, 45, 79, 80, 81, 82, 92, 93, 94, 98, 105, 106, 110, 124, 137, 138, 142, 143, 144, 145, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 164, 165, 170, 171, 172, 173, 176, 177, 179, 183, 188, 189, 194, 196, 197, 198, 204, 209, 214, 215, 235 } },
                { aces = { 'clothing.costume' }, drawables = { 175 }, textures = { 3 } },
            },
            upperBody = {},
            lowerBody = {
                { aces = { 'clothing.festive' }, drawables = { 18, 28 } },
                { aces = { 'clothing.festive' }, drawables = { 31 }, textures = { 3 } },
                { aces = { 'clothing.festive' }, drawables = { 200 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 235 }, textures = { 2 } },
                { aces = { 'clothing.costume' }, drawables = { 114, 191 } },
                { aces = { 'clothing.racy' }, drawables = { 19, 20, 62, 63 } },
            },
            bags = {},
            shoes = {
                { aces = { 'clothing.festive' }, drawables = { 17 } },
                { aces = { 'clothing.costume' }, drawables = { 81, 88, 89, 90 } },
            },
            scarfAndChains = {
                { aces = { 'clothing.festive' }, drawables = { 164, 165 } },
                { aces = { 'clothing.festive' }, drawables = { 17 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 18 }, textures = { 1, 2 } },
                { aces = { 'clothing.costume' }, drawables = { 118, 119 } },
            },
            shirts = {
                { aces = { 'clothing.festive' }, drawables = { 18, 19 } },
                { aces = { 'clothing.festive' }, drawables = { 222 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 223 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 224 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 225 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 226 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 227 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 228 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 229 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 230 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 231 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 232 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 233 }, textures = { 0, 1 } },
            },
            bodyArmor = {},
            decals = {},
            jackets = {
                { aces = { 'clothing.festive' }, drawables = { 19, 20, 39, 44, 196, 197, 198, 199, 200, 253, 301, 341, 460, 461, 462, 573, 604, 638 } },
                { aces = { 'clothing.festive' }, drawables = { 45 }, textures = { 3 } },
                { aces = { 'clothing.festive' }, drawables = { 109 }, textures = { 3, 7, 9, 11, 12, 13, 14, 15 } },
                { aces = { 'clothing.festive' }, drawables = { 201 }, textures = { 1, 2, 3, 5 } },
                { aces = { 'clothing.festive' }, drawables = { 413 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 414 }, textures = { 0, 1 } },
                { aces = { 'clothing.festive' }, drawables = { 491 }, textures = { 3 } },
                { aces = { 'clothing.festive' }, drawables = { 554 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 555 }, textures = { 1, 2 } },
                { aces = { 'clothing.festive' }, drawables = { 651 }, textures = { 0 } },
                { aces = { 'clothing.halloween' }, drawables = { 431, 432 } },
                { aces = { 'clothing.costume' }, drawables = { 288, 518, 613 } },
            },
        },
        props = {
            hats = {
                { aces = { 'clothing.festive' }, drawables = { 23, 24, 25, 39, 40, 41, 96, 97, 98, 99, 100, 165, 166, 167, 170, 185, 210, 211, 213, 216 } },
                { aces = { 'clothing.festive' }, drawables = { 43 }, textures = { 6, 7 } },
                { aces = { 'clothing.festive' }, drawables = { 44 }, textures = { 6, 7 } },
                { aces = { 'clothing.costume' }, drawables = { 32, 34, 35, 36, 90, 91, 245 } },
            },
            glasses = {
                { aces = { 'clothing.festive' }, drawables = { 46 } },
                { aces = { 'clothing.costume' }, drawables = { 22, 23, 32 } },
            },
            ear = {},
            watches = {},
            bracelets = {},
        },
    },
}

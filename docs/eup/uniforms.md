# LSPD rank uniforms

The police locker room (Mission Row, ground floor) gives each officer the uniforms for **their own rank only**. Pictures: `lookbook/ranks_men.png`, `lookbook/ranks_women.png` (every rank) and `lookbook/all_outfits_*.png` (every choice). The pictures are drawn by Claude from the pack's files, so they don't show heads, hands, boots or hats.

## How you tell the ranks apart

| Rank | Choices in the locker | Shirt | Badge says | Insignia |
|---|---|---|---|---|
| Cadet | Short Sleeve (only one, on purpose) | LSPD short sleeve | Police Officer | None |
| Officer I | Short Sleeve, Long Sleeve, Long Sleeve and Cap | LSPD | Police Officer | None |
| Officer II | same three | LSPD | Police Officer | Two sleeve stripes |
| Officer III | same three | LSPD | Police Officer | Two sleeve stripes and a star |
| Sergeant | same three | LSPD | Sergeant | Three sleeve stripes |
| Lieutenant | Command Uniform, Command Uniform and Cap | Long sleeve, closed collar, black tie | Lieutenant | One gold bar on each collar |
| Captain | same two | same | Captain | Two gold bars on each collar |
| Chief | same two | same | Chief | Four gold stars on each collar |

Everyone wears the same base: navy trousers, black lace-up boots, the LSPD shoulder patches, a duty belt (holster, yellow taser, cuffs, keys) and a **radio on the belt with its cord running up to a mic on the left shoulder**. The badge comes with a name tag. EUP printed made-up names on them (KINGSTON, DEVLIN...), the same for everyone of that rank.

**SWAT: Tactical Gear** (the old black tactical outfit) only shows for officers with the **SWAT certification** (`/certs`), Officer III and up.

**Civilian clothes** at the top of the locker menu puts your own clothes back on.

## Changing them (Claude does this)

- `tool/uniforms.py` lists every outfit: which pack piece and colour each slot uses. Pieces are numbered **inside the `rp_eup` pack** (see `mapping.json`), so a game update never breaks them.
- `python3 tool/gen_config.py <illenium shared/config.lua> <same file>` rewrites the `Config.Outfits["police"]` block from it (other jobs are left alone).
- `tool/lookbook2.py` and `tool/lookbook.py` redraw the pictures. `tool/fit.py` measures how a piece sits on another (that's how the sleeve stripes and collar pins were matched to the right shirts: short sleeves and long sleeves need different stripe models).
- Base game pieces: arms `0` (men, short sleeve), `1` (men, long sleeve), `14` (women), boots `51` (men) and `52` (women). These are the bare-hand versions of the arms the old Qbox uniforms used.

## Pieces used (numbers inside rp_eup)

| Slot | Men | Women |
|---|---|---|
| Shirt short / long / command (torso2) | 40 / 41 / 42, colour 1 (LSPD) | 36 / 37 / 39, colour 1 |
| Trousers (pants) | 6 | 5 |
| Duty belt (t-shirt) | 7, colour 0 | 7, colour 0 |
| Radio (vest) | 22 | 22 |
| Badge and name tag (bag) | 26: colour 0 Officer, 1 Sergeant, 2 Lieutenant, 3 Captain, 8 Chief | 21, same colours |
| Sleeve stripes (decals) | short sleeve 6, long sleeve 16: colour 0 two, 1 two and star, 2 three | short 5, long 15, same colours |
| Collar (decals) | 13: colour 6 gold bar, 7 two gold bars. Chief: 12 | 12: same colours. Chief: 11 |
| Service cap (hat) | 0 | 0 |

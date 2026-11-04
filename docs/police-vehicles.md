# Police vehicles

What's in the police garage and how the ONX cars (Scout SUV and Presidente Command Car) are fitted out. The car list itself is `resources/[custom]/rp_police/config.lua` → `garage`. Nothing here is uploaded.

## Rules

- **Every police car seats at least 4**: two officers and two people in the back. The garage hides anything smaller (`minSeats = 4`), so a 2-seater can never sneak in. Seat counts were checked against Rockstar's data (DurtyFree vehicle dump) on Nov 4, 2026.
- Removed on Nov 4 for that reason: Gauntlet Interceptor (`polgauntlet`, 2 seats), Dominator FX Interceptor (`poldominator10`, 2 seats), police motorcycle (`policeb`).

## The fleet

| Car | Model | Seats | Who |
|---|---|---|---|
| Stanier Cruiser | `police` | 4 | Everyone |
| Stanier LE Cruiser | `police5` | 4 | Everyone |
| Prisoner Transport Van | `policet` | 4 | Everyone |
| Buffalo Cruiser | `police2` | 4 | Officer I and up |
| Greenwood Cruiser | `polgreenwood` | 4 | Officer I and up |
| Caracara Pursuit Truck | `polcaracara` | 4 | Officer I and up |
| Interceptor | `police3` | 4 | Officer II + Traffic Division |
| Impaler SZ Pursuit | `polimpaler5` | 4 | Officer II + Traffic Division |
| **Scout SUV** | `onx_polscout` | 6 | **Sergeant and up** |
| **Presidente Command Car** | `onx_polvstr` | 4 | **Captain and Chief only** |
| Unmarked Stanier | `police4` | 4 | Officer III + Detective Bureau |
| Unmarked Buffalo | `fbi` | 4 | Officer III + Detective Bureau |
| Unmarked Granger | `fbi2` | 8 | Officer III + SWAT |
| Terminus Patrol | `polterminus` | 4 | Officer III + SWAT |
| Police Maverick (helipad) | `polmav` | 4 | Officer II + Air Support |

## The Scout SUV (ONX, free)

- From the official Cfx.re Marketplace ("ONX EVP Vapid Scout", free), claimed with Vinny's own Cfx.re account on Nov 4, 2026. It's **escrowed**: it only runs on a server whose license key belongs to that account. If the console says `You lack the required entitlement to use onx-evp-...`, the server key and the account don't match.
- Three resources in `resources/[onx_vehicles]`: `onx-evp-a-shared` (shared parts, names), `onx-evp-b-audio` (sirens), `onx-evp-d-polscout` (the SUV). Each has a `.fxap` file (the license lock): it must be uploaded too.
- Not on GitHub (licensed, about 126 MB). To get them again: portal.cfx.re → Assets → Granted Assets → download the three ONX items.
- Needs game build 3095 or newer (our server is newer).
- Size for players: about 126 MB, downloaded once.

### What the garage fits when it comes out (`loadouts.scout` in config.lua)

| Part | Mod type | Choice |
|---|---|---|
| Livery | 48 | 0 = LSPD |
| Lightbar | extra 1 | The car's own lightbar (extra 1 on, extras 2-9 off). Mod 49 is left alone, see below |
| Antennas | 10 | 0 = city |
| Back seats | 32 | 0 = window bars (the back seats stay for prisoners) |
| Console | 28 | 7 = LSPD laptop |
| Cabin lights | 27 | 0 = off |
| Gun rack | 30 | 1 = rifle rack on the divider |
| Radar | 34 | 0 |
| Spotlights | 8 / 9 | 0 / 0 |
| Push bar | 35 | 1 |
| Trunk badges / lockbox | 26 / 37 | 0 / 6 |
| **Door tag** | 46 | **0 = Supervisor** (Sergeant, Lieutenant), **1 = Command** (Captain, Chief) |
| **Callsign numbers** | 5, 42, 43, 44, 45 | Left to right, digit n = mod n. Taken from the officer's callsign |

Other choices the car has (to swap in config): liveries 0-21 (LSPD, LSSD, SAHP, BCSO, Del Perro, Davis, State Parks...; the odd numbers are single-colour versions), mod 49: 0 slicktop (no lightbar), 1-3 plate-reader (ALPR) cameras on top of the lightbar, door tags 2-7 (Warden, Paramedic, SWAT, Gang Unit, K9; 8-15 are the red reflective versions of 0-7), back seats 1-5 (no divider, K9 seats).

**Lightbars (found Nov 4):** the lightbar choices 4-19 in mod 49 are empty in our files. Their 3D models come in ONX's paid **EVP Companion** subscription, which we don't have, so picking one would leave the roof bare. Our cars use the lightbar built into the car (extra 1). If we ever buy the Companion, we can choose other lightbars.

## The Presidente Command Car (ONX, bought)

- "ONX Albany Presidente VSTR (2020)" from the official Cfx.re Marketplace, bought with Vinny's own Cfx.re account on Nov 4, 2026 ($5.99). Escrowed like the Scout, with the same `.fxap` lock and the same entitlement error if the key doesn't match.
- Resource `onx-evp-d-polvstr` in `resources/[onx_vehicles]`. It uses the same shared and audio resources as the Scout. About 7 MB more for players.
- **Captain and Chief only** (`minGrade = 6`), so the bosses drive something no one else can.

### What the garage fits (`loadouts.vstr` in config.lua)

| Part | Mod type | Choice |
|---|---|---|
| Livery | 48 | 0 = LSPD (1 = single-colour LSPD) |
| Lightbar | extra 1 | The car's own lightbar |
| Push bar | extra 2 | Off (a command car doesn't push) |
| Back seats | 32 | 1 = window bars (0 would remove the divider) |
| Console | 28 | 7 = LSPD laptop |
| Cabin lights | 27 | 0 = off |
| Gun rack | 30 | 2 = rifle rack on the divider |
| Radar | 34 | 0 |
| Spotlights | 8 / 9 | 0 / 0 |
| **Door tag** | 46 | **1 = Command** |
| **Callsign numbers** | 5, 42, 43 | Only **3** slots on this car: it shows the first 3 digits |

It also has its own body parts (front splitter, hoods, spoilers, exhausts: mod types 0-7) from the normal car. We leave those stock.

### Callsigns

Officers set theirs with **`/callsign 123`** (or in the MDT). The garage puts the digits on the Scout (up to 5) and the Command Car (up to 3), so **3-digit callsigns** look the same on both. Officers without a callsign get cars with no numbers.

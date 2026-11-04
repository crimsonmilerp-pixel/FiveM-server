# Police vehicles

What's in the police garage and how the Scout SUV is fitted out. The car list itself is `resources/[custom]/rp_police/config.lua` → `garage`. Nothing here is uploaded.

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
| Lightbar | 49 | 4 = Large Wisen Alliance (extra 1 switched on, extras 2-9 off) |
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

Other choices the car has (to swap in config): liveries 0-21 (LSPD, LSSD, SAHP, BCSO, Del Perro, Davis, State Parks...; the odd numbers are single-colour versions), lightbars 0 slicktop, 1-3 ALPR cameras, 4-13 light bars, door tags 2-7 (Warden, Paramedic, SWAT, Gang Unit, K9; 8-15 are the red reflective versions of 0-7), back seats 1-5 (no divider, K9 seats).

### Callsigns

Officers set theirs with **`/callsign 123`** (or in the MDT). The garage puts the digits on the Scout, up to 5. Officers without a callsign get a Scout with no numbers.

# rp_police: Police groundwork

The structure behind the badge: ranks, divisions, cadet training, which cars each officer may take, the armory log, and the penal code. It works alongside **qbx_police** (cuffing, evidence, impound, the garage itself) and doesn't replace it.

## The department (LSPD only for now)

LSPD covers the whole map at launch. BCSO and SASP are still in `qbx_core/shared/jobs.lua` for later, when there are enough officers to split.

| Grade | Rank | Pay (per 10 min on duty) | Notes |
|---|---|---|---|
| 0 | Cadet | $150 | In training. Rides with an FTO. |
| 1 | Officer I | $165 | Training finished. Solo patrol. |
| 2 | Officer II | $180 | Patrol rifle. Can join Traffic or Air Support. |
| 3 | Officer III | $195 | Can join Detectives, SWAT, or become an FTO. |
| 4 | Sergeant | $220 | Runs a shift. Signs off training. Reads the department log. |
| 5 | Lieutenant | $250 | Grants and removes division certifications. |
| 6 | Captain | $285 | Boss menu: hires, promotes, fires. |
| 7 | Chief | $330 | Boss menu and the department bank account. |

Ranks and pay live in `qbx_core/shared/jobs.lua`. If you rename a rank there, every rp_police menu follows.

## Joining: apply, then train

1. Police jobs are **not** on the City Hall job list. People apply (Discord or in character), and a Captain or the Chief hires them as a **Cadet** from the boss menu.
2. Cadets clock in at the station and ride with a **Field Training Officer**.
3. The FTO (or any Sergeant and up) types **`/training [cadet's ID]`** and ticks off each item as the cadet really does it: orientation, radio, three ride-alongs, a traffic stop, an arrest, the pursuit policy, and a final review.
4. When the last item is signed, the cadet and all online Lieutenants and up get a message. A Captain or the Chief promotes them to **Officer I**.

Cadets type **`/training`** to see their own checklist.

## Divisions (certifications)

| Division | From rank | Unlocks |
|---|---|---|
| Traffic Division | Officer II | The Interceptor and the Impaler SZ pursuit car |
| Air Support | Officer II | The police helicopter |
| Detective Bureau | Officer III | Unmarked cars |
| SWAT | Officer III | SWAT vehicles and SWAT gear at the armory |
| Field Training Officer | Officer III | Signing off cadet training |

- Lieutenants and up type **`/certs [officer's ID]`** and click a division to grant or remove it. You can only do this for officers **below your rank**, never for yourself.
- Anyone in the department types **`/certs`** to see their own.
- Certifications are saved on the character (as licences called `police_traffic`, `police_swat` and so on). **Leaving the department removes them.**
- Staff with the `admin` permission can do everything (for example, the Chief's own certs).

## Finding things at the station

Officers see a blue circle on the floor with a label at every police spot. Walk into the circle and press **E** (the armory is **hold Left Alt and click**).

| Spot | Where (Mission Row) | Who sees it |
|---|---|---|
| Duty desk (clock in or out) | Front desk, just inside the main doors. Also at Paleto Bay station | Every officer |
| Locker room (uniforms by rank) | Ground floor locker room | Every officer |
| Captain's desk (boss menu) | Captain's office | Captain and Chief |
| Armory | Ground floor | Clocked in |
| Police garage | Basement garage and the back lot | Clocked in |
| Impound lot | Behind the station. Also at Paleto Bay | Clocked in |
| Helipad | Roof. Also at Paleto Bay | Clocked in |

rp_police runs three of these spots itself: the **captain's desk** (opens Qbox's boss menu, qbx_management), the **garage** (its own car list; in a police car, E parks it) and the **helipads**. The car still comes from qbx_police's server, which checks duty, rank, division and location again.

The other spots are set in other resources (each line in `config.lua` → `stationMarkers` says which file). The markers only show where they are, so if a spot moves, move its marker too.

## Uniforms (locker room)

At the locker room, each officer only sees **their own rank's uniforms**. They're EUP pieces from `rp_eup`:

- **Cadet**: one plain short sleeve uniform.
- **Officer I to Sergeant**: short sleeve, long sleeve, or long sleeve with the service cap. Sleeve stripes show the rank: none for Officer I, two for Officer II, two and a star for Officer III, three for Sergeant.
- **Lieutenant, Captain, Chief**: the command uniform (closed collar and tie), with or without the cap. Gold collar insignia: one bar, two bars, four stars.
- The badge says the rank (Police Officer, Sergeant, Lieutenant, Captain, Chief). Everyone has the duty belt and the belt radio with its shoulder mic.
- **SWAT: Tactical Gear** shows only with the SWAT certification.

**Civilian clothes** at the top of the locker menu gives you your own clothes back. Pictures and details: `docs/eup/uniforms.md`. The outfits live in illenium-appearance's `shared/config.lua` (`Config.Outfits["police"]`). That file is generated, so ask Claude to change it.

## Garage and helicopter

Every police car **seats at least 4** (two officers and two people in the back); the garage hides anything smaller. The **Scout SUV** is for **Sergeant and up**: it comes out in LSPD colours with a lightbar and a shoulder-height divider, a **Supervisor** door tag for Sergeants and Lieutenants or a **Command** tag for the Captain and Chief, and **the officer's callsign** on it (set it with `/callsign 123`). Full fleet and options: `docs/police-vehicles.md`.

The police garage shows **every** police car. The ones an officer can't take yet are greyed out with what they need ("Needs: Officer II · Traffic Division"). That's on purpose: it shows people what to work toward. The list is in `config.lua` (`garage`). The helicopter needs Officer II and Air Support.

The server checks again when a car is taken out, so nobody can cheat their way into a car they haven't earned.

## Armory

The Police Armoury (ox_inventory) hands gear out for free, by rank and division. Officers must be **clocked in** to sign gear out, and **every sign-out is logged** with the gun's serial number. Guns from the armory are registered to the officer by name.

## Department log

Sergeants and up type **`/policelog`** (whole department) or **`/policelog [ID]`** (one officer) to see certifications, training sign-offs, and armory sign-outs.

## Penal code

Everyone (police, criminals, lawyers) can type **`/penalcode`** to read it. It lives in `data/penalcode.lua`: Claude drafted it from real California law, and Liam polishes the wording. Fines are in real-world dollars; jail is in minutes. Police can recommend up to 120 minutes in total; longer goes to a judge.

**NPC cases rule:** a crime the server made up (an NPC shooting behind a found gun, a runaway fare) is never charged against a player. Charge only what the player actually did: possession, keeping found property, lying, planting evidence.

## Police computer (ps-mdt)

The MDT's charge list is **our penal code**: every time the server starts, rp_police copies `data/penalcode.lua` into ps-mdt (charges, fines, jail time, categories) and removes ps-mdt's sample charges. Edit charges in `data/penalcode.lua`, not inside the MDT (MDT edits are replaced at the next start). The txAdmin console shows `Penal code copied into the police computer: 71 charges.`

## Needs

- **ox_lib**, **qbx_core**, **oxmysql** (the two tables `rp_police_training` and `rp_police_log` are created automatically)
- **qbx_police** asks rp_police which cars an officer may take
- **ox_inventory** for the armory rule and log
- **[onx_vehicles]** for the Scout SUV (free from ONX, locked to Vinny's Cfx.re account). Without it the Scout is simply hidden

## Settings and words

Numbers and lists are in **`config.lua`**: which ranks can do what, the divisions, the training checklist, the garage list. All text players see is in **`locales/en.json`** for Liam. Keep every `%s`.

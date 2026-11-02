# Core changes log

Any edit to a resource we didn't write (Qbox, ox_*, npwd, etc.) gets logged here. When we update that resource, we'll need to redo these changes.

| Date | Resource | File | What changed | Why | Who |
|---|---|---|---|---|---|
| 2026-10-26 | qbx_core | `shared/jobs.lua` | `unemployed` grade 0 `payment` 10 → 0 | No free paycheck for idling (Pillar B). Qbox skips paychecks of 0. | Claude |
| 2026-10-26 | qbx_core | `config/client.lua` | `discord.enabled` true → false | The Discord status showed Qbox's icon, app, and Discord button. Re-enable with our own Discord app ID, art, and invite once the server is named. | Claude |
| 2026-10-27 | qbx_core | `config/server.lua` | Starting bank 5000 → 2500. hungerRate 4.2 → 2.1, thirstRate 3.8 → 1.9 | Economy v2: start money, and slower hunger so food is RP flavor | Claude |
| 2026-10-27 | ox_fuel | `config.lua` | refillValue 0.50 → 1.5, priceTick 5 → 1 (~$67 full tank), petrol can 1000 → 35, refill 800 → 21 | Real gas prices | Claude |
| 2026-10-27 | ox_inventory | `data/shops.lua` | Real-world prices for 24/7, Liquor, YouTool, Ammu-Nation, Black Market, and vending. 'cola' → 'sprunk'. More items stocked. Ammo $1/round | Economy v2 | Claude |
| 2026-10-27 | ox_inventory | `data/licenses.lua` | Weapon license 5000 → 350 | Economy v2 | Claude |
| 2026-10-27 | (config) | `ox.cfg` | `inventory:randomprices` true → false | Fixed prices for quick math | Claude |
| 2026-10-27 | qbx_core | `shared/vehicles.lua` | Real-world prices for 692 vehicles (from docs/economy.xlsx). 152 weaponized/armored/military/arena/sci-fi vehicles removed | Economy + Pillar C. Regenerate from the sheet if Qbox updates this file | Claude |
| 2026-10-27 | qbx_vehicleshop | `config/shared.lua` | Added `predator` and `polmav` to the blocklist | Police boat/heli not for sale | Claude |
| 2026-10-27 | qbx_core | `shared/jobs.lua` | Job pay. Task jobs (taxi, bus, trucker, tow, garbage, vineyard), car dealer, real estate, lawyer, reporter, hotdog → paycheck 0. Police/BCSO/SASP 150–270, EMS 100–250, mechanic 50–80 per 10 min, and they now start **off duty** (clock in to get paid). Judge 375 but off duty until a courthouse clock-in exists | Economy v2: pay per hour = real wage × 30, and no pay for standing around (Pillar B) | Claude |
| 2026-10-27 | qbx_taxijob | `config/client.lua` | Meter $125/mile → **$15/mile + $5** to get in | ~$540/hr of NPC fares | Claude |
| 2026-10-27 | qbx_taxijob | `config/server.lua` | `maxFare` 2000 → 300. `chanceItemEnabled` → false | Blocks fake fares; cryptostick has no use | Claude |
| 2026-10-27 | qbx_garbagejob | `config/server.lua` | Bag worth $50–100 → **$6–9**. `giveItemReward` → false | ~$660/hr; cryptostick has no use | Claude |
| 2026-10-27 | qbx_truckerjob | `server/main.lua` | Per box `random(100,120)` → **`random(22,28)`**. Route bonuses +500/+400/+300/+100 → +100/+80/+60/+25 | ~$810/hr | Claude |
| 2026-10-27 | qbx_towjob | `server/main.lua` | Per tow `random(150,170)` → **`random(80,95)`** | ~$660/hr | Claude |
| 2026-10-27 | qbx_vehicleshop | `config/server.lua` | `commissionRate` 0.1 → **0.025** | 2.5% = $750 on a $30k car | Claude |
| 2026-10-27 | qbx_diving | `config/server.lua` | Coral prices $70–100 / $50–70 → **$16–22 / $11–15** | ~$720/hr | Claude |
| 2026-10-27 | qbx_recyclejob | `config/server.lua` | `maxItemsReceived` 5 → 3, `maxItemReceivedQty` 6 → 4, `chanceItem` cryptostick → copper | Materials now sell at real scrap prices (rp_buyers); ~$510/hr | Claude |
| 2026-10-27 | qbx_vineyard | `config/server.lua` | `grapeAmount` 8–12 → **1–2** per pick | Wine sells for $6 (rp_buyers); ~90 bottles ≈ $540/hr | Claude |
| 2026-10-27 | qbx_busjob, qbx_recyclejob | (whole resource) | **Disabled**: folders moved to `resources/[disabled]` so they don't start. Move a folder back into `[qbx]` to bring a job back | Jobs cut: nobody rides NPC buses, and recycling teleports you into a sealed warehouse where no one can run into you (RP-first jobs) | Claude + Vinny |
| 2026-10-27 | qbx_core | `shared/jobs.lua` | `bus` and `hotdog` jobs removed (no hot dog script exists). `qbx:cleanPlayerGroups` clears them from characters on the next start | Fewer, RP-focused jobs | Claude |
| 2026-10-27 | qbx_cityhall | `config/shared.lua` | Bus Driver removed from the City Hall job list | Job cut | Claude |
| 2026-10-27 | qbx_garbagejob | `server/main.lua` | Calls `exports.rp_jobmoments:OnTask(source, 'garbage')` after each finished stop (only if rp_jobmoments is running) | Job moments | Claude |
| 2026-10-27 | qbx_taxijob | `server/main.lua` | In `NpcPay`, calls `exports.rp_jobmoments:OnTask(src, 'taxi', { fare })` before paying. If it returns true (the runner moment), the fare is paid later by rp_jobmoments | Job moments | Claude |
| 2026-10-27 | ox_inventory | `data/items.lua` | Added `found_evidence` and `lost_wallet` items (reusing the paperbag and ID card images) | Job moments | Claude |
| 2026-11-02 | qbx_core | `config/client.lua` | `startingApartment` true → **false** | No free apartment. New characters arrive at the bus station and rp_starter takes over | Claude |
| 2026-11-02 | qbx_core | `config/shared.lua` | `defaultSpawn` → downtown bus station `vec4(454.50, -640.50, 28.90, 270.0)` | Starter area arrival point | Claude |
| 2026-11-02 | qbx_vehiclesales | `server/main.lua` | `checkVehicleOwner`, `sellVehicle`, and `sellVehicleBack` refuse free starter vehicles (`exports.rp_starter:BlockStarterSale`) | Starter vehicles can't be sold (the sell-back pays 50% of value) | Claude |
| 2026-11-02 | qbx_vehiclesales | `locales/en.json` | `not_your_vehicle` → "You can't sell this vehicle." | Fits both "not yours" and "starter vehicle" | Claude |
| 2026-11-02 | qbx_vehicleshop | `server/main.lua` | `/transfervehicle` refuses free starter vehicles | Starter vehicles can't be traded | Claude |
| 2026-11-02 | qbx_towjob | `server/main.lua` | Calls `exports.rp_jobmoments:OnTask(source, 'tow', { plate })` after each completed tow. Per-tow pay `random(80,95)` → **`random(68,78)`** (measured tow distances: ~10 tows/hr) | Job moments, crew bonus, ~$660/hr | Claude |
| 2026-11-02 | qbx_truckerjob | `server/main.lua` | Calls `exports.rp_jobmoments:OnTask(source, 'trucker')` after each store delivery. Per-store pay `random(22,28)` → **`random(58,72)`**: a "drop" is one store (1-3 boxes), not one box, so the Oct 27 number paid about a third of the target | Job moments, crew bonus, ~$810/hr | Claude |
| 2026-11-02 | qbx_cityhall | `config/shared.lua` | City Hall map marker renamed "City Services" → "City Hall (jobs and IDs)" | Easier for new players to find where to get a job | Claude |
| 2026-11-02 | qbx_towjob | `client/main.lua` | At login, the job is now read (it was never set, so tow drivers lost the tow yard markers after relogging). Markers aren't stacked twice and are removed when you leave the job | Bug fix | Claude |
| 2026-11-02 | qbx_cityhall | `config/shared.lua` | News Reporter removed from the City Hall job list (the job itself stays; staff can give it with `/setjob [ID] reporter 0`) | It pays $0 and has no tasks yet. Back on the list once pay per story exists (after LB Phone) | Claude |
| 2026-11-02 | qbx_vehiclesales | `server/main.lua` | **Security audit.** Listing a car now checks you own it (plate + your citizen ID), it's paid off, and the price is $1 to $10,000,000; the database's model and mods are used, and the description is capped at 250 characters. Selling back prices the database's model, not the one your game sends. Buying takes the listing off first, then charges (no double buys). Spawning a bought or taken-back car uses what the server remembers, near the lot only. The contract only gets the seller's character info, not their whole player row. Removed the now-unused `getVehPrice` | Anyone could list someone else's car, sell back any car at half a supercar's price, spawn any vehicle, or see another player's money and inventory | Claude |
| 2026-11-02 | qbx_police | `server/main.lua` | Money bag reads `item.metadata` (ox_inventory has no `item.info`). `police:server:SeizeCash` now requires on-duty police | Money bags could never be opened; anyone could trigger cash seizing | Claude |
| 2026-11-02 | qbx_storerobbery | `server/main.lua` | Safe pays Dirty Money (`black_money`) worth the same as the marked bills it used to give | Marked bills had no use anywhere; black_money is the one dirty cash (the black market takes it) | Claude |
| 2026-11-02 | qbx_core | `server/character.lua` | New characters' first name, last name and nationality have formatting symbols (like `<` `>` `[` `]` `(` `)` `!` `*`) and hidden characters stripped | Menus format text, so a name like `![x](link)` could load an outside image on staff screens and reveal their IP | Claude |
| 2026-11-02 | ox_inventory | `data/items.lua` | Added `markedbills`, `moneybag`, `iphone` ("iFruit Phone"), `samsungphone` ("Facade Phone"), `laptop`, `tablet`, `microwave` | Other Qbox scripts hand these out (drugs, robberies, police, pawn shop) but they didn't exist, so players got nothing | Claude |
| 2026-11-02 | ox_inventory | `data/shops.lua` | Medicine Cabinet (EMS): `medikit` (not a real item) → `firstaid` $30, bandage $5 → $6 | Same items and prices as the pharmacy | Claude |
| 2026-11-02 | ox_inventory | `data/crafting.lua` | Example "debug" workbench removed (`return {}`) | It put two public lockpick benches on the map | Claude |
| 2026-11-02 | ox_inventory | `web/images/` | 169 item pictures copied up from `web/images/images/` (they were one folder too deep, so the inventory couldn't find them). The `images/images` folder can be deleted | Most items (grapes, wine, copper, coke brick, first aid…) showed no picture | Claude |
| 2026-11-02 | (server config) | `ox.cfg` | Car glovebox loot `cola` → `sprunk` | `cola` isn't an item here | Claude |

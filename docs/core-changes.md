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

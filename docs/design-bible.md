# Server Design Bible & Roadmap

*Living plan for the project. Update it whenever we make a decision. Last updated: Oct 26, 2026.*

---

## 0. Team

| Person | Role |
|---|---|
| **Vinny** | Project lead and vision. Builds the server together with Claude, and owns the GitHub repo. New to coding, so explanations are in plain English. |
| **James** | **Co-owner** with full access to the server (Nodecraft, txAdmin, in-game admin). He isn't part of the Claude sessions. |
| **Liam** | Writer and story designer. Owns lore, setting, NPC characters, and in-game text. |
| **Claude** | Helps with design, code, explanations, and turning Liam's writing into in-game content. |

## 0.1 Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-10-26 | **Framework: Qbox + ox stack** (qbx_core, ox_lib, ox_inventory, ox_target, oxmysql) | Actively maintained successor to QBCore, lighter, and the cleanest base for heavy custom systems. |
| 2026-10-26 | ~~Develop on Vinny's PC~~ → **Rent a shared dev server now** (see section 0.2) | James needs co-owner access at any time, without depending on whose PC is on. The server can grow into the live server later. |
| 2026-10-26 | **Host: Nodecraft, Pro "Best Performance" plan (6 GB, 24/7, static IP), East Coast, monthly billing** ($20.99 the first month, then $29.98/mo) | Managed FiveM hosting with txAdmin built in, sub-users for James, MariaDB included, and DDoS protection. OVH's US VPS stock was sold out. Pro plans upgrade in place, with prorated billing. |
| 2026-10-26 | **Scripts: mix of premium and our own code** | Buy the systems that are huge to build but not unique (phone, MDT, housing interiors). Custom-build everything that makes us different. |
| 2026-10-26 | **Claude sessions are Vinny's only.** Vinny and Claude do the build together, with every step explained in plain English. | Claude accounts can't be shared. James keeps his co-owner server access. |
| 2026-10-26 | **Community Discord: discord.gg/ZjadxPYdYZ** (permanent invite). Used in the chat welcome and `qbx:discordLink`. | Qbox's built-in Discord status is off until we make our own Discord app with our art and a "Join our Discord" button. |
| 2026-10-26 | **Goal system:** a required goal right after character creation, with no rewards or milestones, view-only for staff, changeable once every 7 days. Public server for now; a Discord-application whitelist comes later. | It gives every player a reason to move, and keeping it simple keeps it low-friction while we build a player base. |
| 2026-10-26 | **All player-facing text lives in config or locale files, not hard-coded** | Liam can write and edit dialogue and UI text without touching code. |

## 0.2 Shared server and co-owner access

**The server:** Nodecraft managed FiveM hosting, on the Pro plan.

| Item | Value |
|---|---|
| Plan | Pro "Best Performance": 6 GB RAM, runs 24/7, static IP, AMD Ryzen 9 or EPYC CPU |
| Location | East Coast (Washington D.C. recommended) |
| Database | MariaDB, created in the NodePanel **Databases** tab. Qbox needs version 10.9+, so confirm it in the oxmysql startup line. |
| Control | NodePanel for files, console, and SFTP. **txAdmin** is enabled under Game Settings → Basic → txAdmin Launcher, and once enabled it overrides NodePanel's config options. |
| Upgrading | Billing → Manage → Plan/Addons. Prorated, about 5–10 minutes plus a restart. |
| File access | **FTPS**: WinSCP with File protocol FTP, Encryption TLS/SSL Explicit, port **121**. The temporary login comes from the Nodecraft **Overview** page and expires. |
| Server layout | The server data folder is the FTP root `/`. **`nodecraft_config.cfg`** is written by Nodecraft and holds the license key, max players, and startup settings; it's never committed. The server's name, description, and tags are set in the **Cfx.re Portal**, not `server.cfg`. |
| Local repo | `C:\Users\mrgri\FiveM\server` on Vinny's PC, connected to Claude |
| Later, for launch | Bigger plan, or a dedicated game server (e.g. OVH Game-1 with a Ryzen 9800X3D) at 64+ players |

**Co-owner access for James (and Vinny):**
1. **Nodecraft:** James creates a free Nodecraft account. Vinny adds him under Manage Instance → **User Permissions** with full permissions. No shared passwords.
2. **txAdmin:** Vinny is the master account. He adds James in **Admin Manager** with **all permissions**, so both can restart, view logs, ban, and edit `server.cfg` from the browser.
3. **In-game admin:** both are in `group.admin` through ACE permissions in `server.cfg` (`add_principal identifier.fivem:<id> group.admin`). That gives Qbox admin commands, noclip, and the admin menu.
4. **Database:** credentials come from the NodePanel Databases tab, which both owners can see.
5. **GitHub:** Vinny owns the private repo. James can be added as a collaborator if he wants to see or contribute code.
6. **Cfx.re:** the license key belongs to Vinny's Cfx.re account.

**Status (Oct 26):** ✅ James is set up as co-owner (Nodecraft, txAdmin, `group.admin`).

**How changes flow:** edit the code (on your PC, or with Claude), commit and push to GitHub, upload the changed resource over SFTP, then restart that resource in txAdmin. GitHub is the single source of truth, so nobody edits live files without committing them.

**Working with Claude:**
- This Claude account and project are Vinny's only, as Anthropic's terms require. If the team ever wants shared Claude access, a Team plan gives each person their own seat.
- A copy of this design bible lives in the repo at `docs/design-bible.md`, so anyone with repo access can see the plan.
- Claude writes files directly into Vinny's local repo folder. Vinny reviews them, commits in GitHub Desktop, and uploads with WinSCP.
- **Every time Claude changes files, it ends with a simple upload checklist:** for each file, the folders to double-click in WinSCP (the same path on both sides, starting from the `server` folder on the left and `/` on the right), then "drag → Yes", then which restart is needed. No long paths or tables. `docs/` files are never uploaded.

---

## 1. The pitch

> **It doesn't matter how much RP experience you have. Every character starts with a goal, and the server is designed so there's always something to do.**

What we're fixing in typical FiveM servers:

- People stand around doing nothing.
- Crime is so restricted that nobody commits any. Rules like "you need 4 cops online to rob a store" leave criminals waiting.
- Immersion breakers: neon katanas, meme outfits, and clothing that looks like costumes instead of people.
- Heavily structured, scripted RP instead of organic stories.

## 2. Design pillars

Every feature we build has to support at least one of these.

### Pillar A: Goal-driven characters
- **Right after a character is created** (once the clothing editor closes), the player must commit to a **simple, actionable goal** before they can move. They can't skip it.
- **Fields:** *Type* (Legal career / Criminal empire / Public service / Personal story), *Goal* (one sentence), *Why they want it*, and *First step* (what they'll do in their first session).
- **Commitment moment:** an explanation with good and bad examples, then a "Commit to this goal?" check with **I commit** or **Edit**.
- **No rewards and no milestones.** The goal isn't a quest log. It exists so the character has a reason to move.
- **Reminder on every spawn**, and `/goal` to view it. A character can change their goal once every 7 days, and old goals are kept in history.
- **Staff can view only** (`/goals` lists everyone online). There's no approval step, because approvals would make players wait.
- **Later, once the server is big:** move to a whitelist, with the goal included in a **Discord application**.
- **Built as `rp_goals`** in `resources/[custom]`. All text is in `locales/en.json` for Liam.

### Pillar B: Never a reason to stand still
- **No "minimum cops online" rules.** If no player cops respond, **NPC police respond instead**, so crime is always possible. This is the most important single idea in the design.
- **Bills on a clock**: rent, loan payments, taxes, and quotas all come due, so players need income.
- **No free paycheck for idling**: disable Qbox's unemployment paycheck. You earn by doing.
- **Opportunities feed** (phone app): available jobs, open calls, NPC "tips" for criminals, and nearby events. A player who opens it always finds something to do.
- **Dynamic world events**: random crashes, fires, shipments, and NPC disputes that create hooks.
- **NPC-driven content** for every role: cops can arrest NPCs, criminals can rob NPCs, and mechanics fix NPC tow-ins.
- **AFK handling**: input-based idle detection in public areas, with exceptions for active RP scenes.

### Pillar C: Grounded world standards
- **Curated clothing**: blacklist meme and sexualized items in the appearance menu, and add only lore-friendly clothing packs.
- **Curated weapons**: real-world weapons only, with no meme melee weapons, glowing skins, or tints.
- **Balanced vehicles**: real-world feel, capped speeds, and classes that make sense.
- **Rules philosophy**: fewer rules about *how* to RP and more systems with *consequences*.

### Pillar D: Consequences instead of restrictions
- Crime is open, but heat, evidence, warrants, prison, and debt make it risky.
- Legal life is open, but taxes, quotas, and loans make it demanding.

---

## 3. How a FiveM server works (plain English)

- **FiveM client**: the mod launcher players use to join. Everyone needs a legit copy of GTA V.
- **FXServer**: the server program. It runs on Windows or Linux and loads **resources**.
- **Resource**: a folder of code that adds one feature, such as fuel or police. Each one has an `fxmanifest.lua` file that tells the server what's inside.
- **Client vs. server scripts**:
  - *Client scripts* run on each player's PC. They handle visuals, UI, input, and spawning NPCs around the player.
  - *Server scripts* run on the server. They handle money, inventory, the database, and anti-cheat checks.
  - **Golden rule:** never trust the client with money or items. The server decides.
- **Lua**: the main programming language for FiveM scripts. It's beginner-friendly.
- **NUI**: in-game menus and HUDs, built with HTML, CSS, and JavaScript like a small webpage.
- **Natives**: built-in GTA functions we call from code, such as `SetVehicleFuelLevel` or `TaskCombatPed`.
- **Database (MariaDB)**: stores characters, money, vehicles, houses, loans, and warrants. `oxmysql` is the resource that connects scripts to it.
- **Framework (Qbox)**: the base layer for characters, jobs, money, and permissions. Our features plug into it.
- **txAdmin**: a web control panel that ships with FXServer. We use it to install, restart, ban, and view logs.
- **OneSync**: the networking mode that supports more than 32 players and server-side entities. It's required by Qbox.
- **server.cfg**: the main settings file. It sets which resources start, the license key, and the database connection.
- **Git / GitHub**: shared version history. James, Vinny, and Claude all work from the same repo, and any change can be undone.

## 4. Tech stack

| Layer | Choice |
|---|---|
| Server | FXServer on Nodecraft managed hosting (Pro 6 GB) + txAdmin |
| Framework | Qbox (`qbx_core`) |
| Core libraries | ox_lib, ox_inventory, ox_target, oxmysql |
| Database | MariaDB (Nodecraft-hosted). HeidiSQL on our PCs can connect if remote access is allowed. |
| Code editor | VS Code + Lua and FiveM natives extensions |
| Version control | Git + private GitHub repo (owned by James) |
| Our custom resources | Live in `resources/[custom]/` with a shared name prefix (TBD once we pick the server name) |
| Text and dialogue | Locale or config files per resource (e.g. `locales/en.json`), editable by Liam |

**Licensing and limits:**
- A free Cfx.re license key from the Cfx.re portal is required.
- Without Element Club Argentum or higher, servers are capped at **48 slots**.
- Monetization is **Tebex only**. No selling in-game money, no loot boxes or chance-based items, and the store must show the "not approved, sponsored, or endorsed by Rockstar Games" disclaimer. These rules come from the Creator PLA, effective Jan 12, 2026. Re-check them before we open a store.

---

## 5. Buy vs. build map

| Feature | Approach | Notes |
|---|---|---|
| Phone | **Buy (premium)** | Huge to build, not what makes us unique. Our apps (goals, opportunities feed, loans) plug into it. Choose one with a custom-app API. |
| MDT / police computer + dispatch | **Buy or free base**, extend | Must support custom case files, evidence, and warrants, or we build those parts. |
| Housing interiors / property system | **Buy (premium)** or free base | We add our own loan, tax, and foreclosure logic on top. |
| Clothing / appearance | Free (e.g. illenium-appearance) + **our blacklist** | Pillar C. |
| Fuel | Free base (ox_fuel) + **our UI and tuning**, or custom | A good first learning project. |
| Vehicle balance | **Custom** (handling.meta edits + speed caps) | Ours. |
| Character goals | **Custom** | Core identity. |
| Tutorial / starter area | **Custom** | |
| Legal jobs | **Custom** (borrowing ideas from free bases) | Tied to taxes and quotas. |
| Police overhaul + NPC police AI | **Custom** on top of Qbox police | Signature system. |
| Detective / forensics | **Custom** | |
| NPC interactions (police + criminal) | **Custom** | Signature system. |
| Prison | Free base or custom + **our parole and isolation** | |
| Warrants + judge | **Custom** (inside the MDT if possible) | |
| Loans, credit, repossession | **Custom** | |
| Taxes + treasury | **Custom** | |
| Quotas (legal and criminal) | **Custom** | |

---

## 6. Roadmap

Size key: S = days, M = 1–2 weeks, L = several weeks, XL = a month or more (part-time pace).

### Phase 0: Foundation (shared dev server)
1. ✅ Rent the server (Nodecraft Pro 6 GB).
2. ✅ Get a Cfx.re license key (portal.cfx.re → Servers → Server Registration Keys). The key was regenerated after appearing in a screenshot.
3. ✅ NodePanel: create the database (Databases tab), then enable txAdmin (Game Settings → Basic → txAdmin Launcher).
4. ✅ Start the server, open the txAdmin link and PIN from the Console tab, and link the Cfx.re account.
5. ✅ Deploy txAdmin **Popular Recipes → Qbox Framework** with the license key and database credentials.
6. ✅ Confirm the MariaDB version: **12.3.3**, which is compatible.
7. ✅ Vinny joined and tested spawn, inventory, saving, `/car`, and `/tx`. All work, and Vinny is in `group.admin`.
8. ✅ James co-owner access (section 0.2): Nodecraft sub-user, txAdmin admin with all permissions, and `add_principal identifier.fivem:<id> group.admin`.
9. ✅ Vinny installed GitHub Desktop, VS Code, and WinSCP, downloaded the server to `C:\Users\mrgri\FiveM\server`, and connected the folder to Claude.
10. ✅ Claude added the starter kit and moved the database string into `secrets.cfg`, and the server runs from it. The repo is published to GitHub as **private**: 3,955 files, no secrets, no nested `.git` folders.
11. ✅ Unemployed paycheck turned off (`qbx_core/shared/jobs.lua`, logged in `docs/core-changes.md`). The Qbox console banner, chat ad, and Discord link are removed. ⏳ Next: set the server name in the Cfx.re Portal (required since Oct 21, 2026), then the clothing and weapon blacklists.
12. ⏳ **Custom #1: `rp_goals`** is written (v1.0.0) and waiting for Vinny to upload and test it. It uses placeholder text that Liam can rewrite in `locales/en.json`.

**Included in the Qbox recipe (decide later whether to keep, replace, or extend):**
- **Phone and UI:** npwd (free phone), qbx_hud, qbx_radialmenu, scully_emotemenu, playerlist, and ox_inventory with 303 items.
- **Prison:** xt-prison, a starting point for #6.
- **Legal jobs** (starting points for #4): bus, garbage, taxi, tow, trucker, mechanic, news, recycling, and vineyard.
- **Crime** (starting points for #5): store, bank, house, jewelry, and truck robbery, plus drugs and weed.
- **Services:** police, ambulance and medical, and qbx_adminmenu.
- **Vehicles:** garages, vehicle shop, vehicle sales, customs, keys, carwash, **ox_fuel** (base for #2), and vehiclehandler.
- **Other:** Renewed-Banking (the bank our loans and taxes will plug into), illenium-appearance (clothing, where the blacklist goes), ox_doorlock, and minigames (mhacking, safecracker, ultra-voltlab).
- **Housing:** qbx_properties is present, but its `properties` table is missing. We'll decide on housing in Phase 2.

**Known harmless startup warnings:**
- `Table 'properties' does not exist`. Resolve this when we pick a housing system.
- `sv_projectName`/`sv_projectDesc` not set. Set these when the server is named.
- The Qbox welcome banner. Set `qbx:acknowledge true` to hide it.

### Phase 1: The first hour of play
- **Tutorial and starter area (#1)**: M
  - A guided intro walks the player through phone, inventory, bank, fuel, the job board, and the goal journal.
  - Pick 1 of 5 starter vehicles: SUV, Sedan, Motorcycle, Old Muscle Car, Truck. The vehicle is owned and modest, and you can't get a second free one.
  - Starter shop: phone, water, food, bandage, map, repair kit.
  - The tutorial ends by sending players straight to their goal's first step.
  - Needs Liam's arrival story and tutorial script.
- **Gas stations (#2)**: S/M
  - Fuel drains based on RPM and vehicle class.
  - Pumps at every station, plus jerry cans.
  - HUD gauge with a low-fuel warning.
  - Fuel prices include tax, which feeds the treasury.
  - Optional later: fuel delivery job, station ownership, and fuel quotas.
- **Vehicle balance (#7)**: M
  - Speed caps per class (handling `fInitialDriveMaxFlatVel` plus a script-enforced max).
  - Rebalanced acceleration and braking.
  - More realistic traction and weight.
  - Documented class tiers.
- **Legal jobs, first wave (#4)**: L
  - Delivery, Taxi (NPC fares), Mechanic (NPC tow-ins), Garbage, and Construction.
  - Each job has levels, uses a work vehicle, pays per task (taxed), and posts to the opportunities feed.
  - **Repo Agent** and **Tow Driver** jobs come later and connect to loans.

### Phase 2: Economy backbone
- **Tax system**: M
  - Income tax on job payouts (bracketed).
  - Sales tax at shops.
  - Weekly property tax.
  - Vehicle registration.
  - Business revenue tax.
  - All tax money goes to a **government treasury** that funds police, EMS, and court pay.
  - Large unexplained bank deposits get flagged, which creates the **money laundering** gameplay loop.
- **Properties (#10)**: L
  - Homes across the city, suburbs, Sandy Shores, Grapeseed, and Paleto.
  - Prices set by zone.
  - Renting or buying, plus storage.
  - Houses act as evidence locations for warrants.
- **Loans (#9)**: L
  - Bank loans for cars and homes.
  - **Credit score** per character, based on payment history, income, and defaults.
  - Interest rate = admin-adjustable base rate + a risk premium from the credit score.
  - Weekly payment plans with a choice of term length.
  - Missed payment → late fee → after N misses, default → **repossession**:
    - Cars are flagged for an NPC tow or the player Repo Agent job.
    - Houses go to foreclosure, then auction.
- **Quotas**: M/L
  - *Legal businesses* have weekly quotas, such as repairs completed, meals sold, or goods delivered.
    - Missing a quota escalates: warning → fine → license suspended → business repossessed and resold.
  - *Criminal organizations* answer to an NPC supplier or boss who expects a weekly volume of product or tribute.
    - Missing it escalates: debt → enforcers (NPC hit squads) → loss of supplier access and territory.
  - Quotas scale with group size.
  - Liam writes the supplier and boss characters.

### Phase 3: Crime and law
- **Heat and NPC police AI (#3, #5)**: XL. This is the signature system.
  - NPC **witnesses** see crimes and call them in. Players can intimidate or stop witnesses, which affects the outcome.
  - A **heat level** decides the response: a single patrol, then multiple units, a helicopter, and roadblocks.
  - Calls go to **player cops first**. If nobody accepts within X seconds, NPC units respond. NPC units back up players at high heat.
  - Better NPC behavior: real patrol routes, traffic stops, foot chases, surrender and arrest instead of instant shooting.
  - GTA's built-in wanted system is replaced by ours.
- **Player police overhaul (#3)**: L. Cuffing, searching, transport, the penal code, fines, an impound tie-in, and an MDT.
- **NPC interactions (#5)**: L
  - *Police:* stop and frisk ambient peds, check generated NPC IDs, question witnesses (gives detective clues), and arrest generated "wanted NPC" bounties.
  - *Criminals:* mug pedestrians (aim → hands up → loot, with a chance they resist), rob stores (register and safe), carjack (driver may flee or fight), burglarize NPC homes, sell drugs on corners.
  - Every NPC crime can generate heat and evidence.
- **Detective and forensics (#8)**: L
  - Evidence types:
    - Bullet casings, traced to a weapon serial.
    - Blood, matched by DNA to a character.
    - Fingerprints, left if the suspect wasn't wearing gloves.
    - Vehicle paint and fragments.
    - CCTV stills: partial plate and vehicle color.
  - Lab processing takes real time.
  - Case files in the MDT that link evidence, suspects, and witness statements.
  - Suspect tracking through plate readers and, with a warrant, phone pings.
- **Search warrants (#11)**: M
  - Warrant types: search (house, vehicle, person), arrest, and phone records.
  - Police submit a warrant with attached evidence in the MDT.
  - A **player Judge** approves or denies it. If no judge is online within X minutes, an **NPC judge** auto-decides using an evidence score threshold.
  - Evidence from a search without a warrant is flagged "inadmissible," which weakens the case.
- **Prison (#6)**: L
  - Bolingbroke.
  - Sentences are served in real minutes while online.
  - **Prison jobs** (kitchen, laundry, cleaning, electrical) shorten the sentence and earn commissary money.
  - A prison economy and inmate gangs, so prison isn't idle time.
  - **Isolation cells** for violations.
  - **Parole** = early release with conditions: a GPS ankle monitor, restricted zones, and check-ins with a parole officer (player or NPC). Violations send the player back.
  - Escape (optional): hard, multi-step, and gives max heat.

### Phase 4: Launch prep
- Upgrade the dev server for launch, or split into separate dev and live servers. Add DDoS protection, and get a dedicated machine at 64+ players.
- Discord, whitelist or application process (including the character goal), rules doc, and staff team plus story team.
- Tebex store, compliant with the Creator PLA (cosmetics, queue priority, character slots).
- Load testing, then closed beta, then open.

---

## 7. Economy map (money in and money out)

**Sources (money in):** legal jobs, business revenue, criminal activity (dirty cash), and government pay for police, EMS, and judges.

**Sinks (money out):** fuel, taxes, rent and mortgages, loan interest, repairs, fines, bail, medical bills, licenses, and supplier costs.

**Rule of thumb:** a full-time legal player should be able to cover rent, fuel, and a car loan, then save a little. Idling should slowly lose money. We tune numbers in a spreadsheet before going live.

---

## 8. Open questions
- Server name and brand. This also sets the code prefix for our resources. (Liam + Vinny)
- James's experience level with Lua and FiveM. This sets how detailed the code explanations are.
- Target player count at launch (48 or fewer means no Element Club needed).
- Staff team: who moderates, and who runs the story team?
- Whitelisted (application) or public?
- Budget for premium scripts (hosting is $29.98/mo on Nodecraft Pro 6 GB).
- Do sentences, loans, and taxes run on real-world time or in-game days?
- Death rules: permadeath only by consent, or something stricter?

---

## 9. Writing needs for Liam (in the order the build needs them)

Short and punchy beats long. Players skip walls of text in-game, so detail belongs in the lore doc and the in-game lines stay to one or two sentences.

1. **Setting one-pager**: server name, era, tone, and what kind of city this is (who runs it, what's broken, what people want). *Needed first; everything else hangs off it.*
2. **Goal screen text (Phase 0)**: the prompt players see when writing their goal, a short "what makes a good goal" guide, and 3 to 5 example goals per category (Legal career, Criminal empire, Public service, Personal story).
3. **Arrival story + tutorial script (Phase 1)**:
   - Why every new character arrives in the city, and where (bus, train, or airport).
   - The intro NPC's lines.
   - The text for each tutorial step.
   - The starter shop owner.
4. **Job flavor (Phase 1)**: a one-line pitch per legal job, dispatcher lines, and NPC customer lines for taxi and mechanic.
5. **Factions and NPC characters (Phases 2–3)**:
   - City hall, bank, and police department names.
   - Criminal suppliers and bosses who set quotas: name, personality, what they want, and how they escalate when you miss a quota.
   - Gangs and territories.
6. **Laws and penal code (Phase 3)**: charges, fines, and sentence lengths. Co-written with whoever designs police.
7. **World events and tips library (ongoing)**: short hooks for the opportunities feed, such as "A cargo truck broke down on Route 68 and the driver's looking for help, or for someone to look the other way."

**Format tip:** write in-game lines in a simple table with columns *ID / Who says it / Line*. Each row can then go straight into a locale file.

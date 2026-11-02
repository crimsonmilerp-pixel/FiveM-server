# Server Design Bible & Roadmap

*Living plan for the project. Update it whenever we make a decision. Last updated: Nov 2, 2026.*

---

## ▶ Where we left off (end of Nov 2, 2026 session)

**Live on the server:** Qbox, MariaDB 12.3.3, Vinny's permanent admin, secrets in `secrets.cfg`, Qbox ads removed, Discord link, **rp_goals**, **rp_welcome**, **economy v2** (real prices, fuel, start money, slower hunger, weapon license), **vehicles** (real prices, 152 removed and blocked, speed caps via **rp_vehicles**, tested), **job pay**, **rp_buyers**, and the **job cuts** (Oct 27). **rp_starter** (Nov 2, tested). **rp_jobmoments** (Oct 27; tow and trucker moments added Nov 2) and **rp_crews** (Nov 2) are built and waiting on Vinny's test.

**Next session, in order:**
1. ✅ rp_starter tested Nov 2 (tour works, NPC spots good). Still to check: the starter vehicle is refused at the used car lot.
2. Vinny tests `rp_buyers` and `rp_jobmoments` if not done yet. (For moments, set `oneIn = 1` and `cooldownMinutes = 0` while testing, then back to 20 and 10.)
3. Vinny tests **rp_crews** (two people, same job, `/crew`) and the new tow/trucker moments. Time one trucker route and a few tows so we can check the new pay.
   Next for jobs later: real player calls before NPC work, and **reporter pay per story** (Weazel News buys photos or footage of real events; then put the job back on the City Hall list). Both need the phone.
4. Then: luxury dealership, Pillar C clothing cleanup, LB Phone once bought (then add phone and job board steps to the tour), and the play-through checklist.

**Loose ends:**
- James's `fivem:` ID goes into `permissions.cfg`.
- Set the server name in the Cfx.re Portal.
- Liam rewrites `rp_goals`, `rp_welcome`, `rp_starter` (arrival story, volunteer, tour), and `rp_jobmoments` `locales/en.json`.
- Police armory and EMS cabinet prices.

**Working style:** plain English, and every change ends with a short WinSCP upload checklist (double-click path → drag → Yes → which restart). Claude writes directly into `C:\Users\mrgri\FiveM\server` (connected folder).

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
| 2026-10-26 | **Phone: LB Phone (lifetime license, official store lbscripts.com only)**, replacing the free npwd | The most widely recommended FiveM phone, with Qbox support (auto-detected), strong performance reports, and a custom-app API with a React/TS template for our goals, opportunities, and loan apps. Escrowed, so we can't edit its code, only its config, open files, and exports. Needs MariaDB 10.11+ (we have 12.3.3) and an upload service such as Fivemanage for photos. Bought on Vinny's Cfx.re account. |
| 2026-10-27 | **Economy (RP-first): real-world prices; pay = real wage × 30 per hour worked (a regular player works ~⅓ of playtime); only rent and loans are weekly bills (paused if inactive); small bills dropped; luxury upkeep on cars over $100k and homes over $750k; cheap food and slower hunger; crime ~2.5× legal with a 30% laundering cut; start with $500 cash + $2,500 bank** | Roleplay over grind. Quick real-world math. The rich pay to stay rich. See section 7 and `docs/economy.xlsx`. |
| 2026-10-27 | **Vehicles: keep realistic ones only. No weaponized or armored vehicles, period** (152 removed and blocked, including the police Riot/RCV). **Police cars match or slightly beat most civilian cars:** speed limits by class (police 125 mph; sports 120, muscle 115, sedans 105; only supercars at 130) plus a small boost for emergency vehicles (`rp_vehicles`) | Grounded world (Pillar C), with fair chases. Values to be tuned after test drives. |
| 2026-10-27 | **Job pay: you only get paid while working.** Task jobs (taxi, trucker, tow, garbage) have no paycheck and pay per fare, box, tow, or bag. Police, EMS, and mechanics start **off duty** and are paid every 10 minutes only after clocking in. Car dealers earn 2.5% commission. Jobs anyone can take with no clock-in (reporter) get no paycheck | Pillar B: no money for standing around. Payouts are first estimates aimed at real wage × 30 per hour, to be checked in play. |
| 2026-10-27 | **Fewer jobs, all RP-first.** Cut: bus (nobody rides NPC buses), recycling (it teleports you into a sealed warehouse where no one can run into you), and hot dog (no script). Police stays as is (LSPD, BCSO, SASP). Every job should leave room for RP: **real player calls before NPC work**, **job moments** (now and then a small event with a choice that leads into police, detective, or crime RP), and a **crew bonus** for working together | A small player base spread across fewer jobs means people run into each other, and that's where roleplay starts. |
| 2026-10-27 | **Job moments: 1 task in 20.** A kept pistol is real but **traceable** (its serial is on file for an open shooting case). Doing the right thing pays a **small reward (~$100) and is logged** for police and detectives | Moments should feel special, and choices should have consequences (Pillar D) that feed police and detective RP. |
| 2026-10-27 | **NPC cases rule:** police can only charge a player for what they actually did (possession, keeping found cash, lying, planting evidence), never for a crime the server made up. The system never attaches a player's name to an NPC case; the only link is physically finding the gun on someone and running its serial. The case file and `/serial` say the shooter is unknown | So nobody gets pinned for a crime that never involved a player. Players passing the gun around, or planting it, is real RP, and the staff log is the safety net. |
| 2026-11-02 | **Starter area:** new characters arrive at the **downtown bus station**. **No free apartment** (a home is something you work toward; until rent exists, you log out anywhere). Free starter vehicles are **plain used cars**: Asea, Landstalker, PCJ-600, Chino, Bobcat XL. **One per character, can't be sold or traded.** The tour is **required on your first character** and skippable after that | Grounded "starting from the bottom" feel, every character gets a fair start, and free cars can't be farmed for cash (the used-car lot buys back at 50%). |
| 2026-11-02 | **Crews: form a crew with `/crew` (2-4 people); everyone runs their own route; each task pays +10% per crewmate working the same job, up to +30%.** Players learn about it from a tip when they take a crew job, a reminder about once an hour while working alone, and the tour's City Hall step. **New moments:** tow (drugs in the trunk) and trucker (extra package of cash). Trucker pay fixed: a "drop" is one store, not one box | A shared route would mean rewriting every job; this works for all four task jobs now and still rewards working together. Vinny asked that players be told how to form a crew. |
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
- **NPC cases rule:** a crime the server made up (an NPC shooting behind a found gun, a runaway fare) can only lead to charges for what a player **actually did**: carrying an unregistered or evidence-linked weapon, keeping found cash, lying to police, planting evidence. Never the NPC crime itself. Being caught with a traced gun proves possession, not who fired it. The police handbook will spell this out, and staff can check the private choice log if someone says they were framed.

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

### 5.1 Rules for buying premium scripts
1. **Play-through first.** Only buy to fill a gap we've confirmed in-game, not to replace something that already works well enough.
2. **Buy the "hubs" before building on them.** The phone, MDT/dispatch, and housing are where our custom features plug in (goals and opportunities apps, warrants and evidence, loans and foreclosure). Pick each hub before starting the feature that depends on it.
3. **Never buy our identity.** Goals, the NPC police and heat system, quotas, taxes, loans, warrants, and evidence get built by us.
4. **It must say Qbox (or ox) support,** not just QBCore. ox_inventory and ox_target compatibility are required.
5. **Prefer open source, or an "open source" version of the script.** Most paid FiveM scripts are *escrowed* (locked code). We can only change their settings and use the hooks they offer, and Claude can't read or fix the locked parts.
6. **Must have documented exports/events** (and for the phone, a custom-app API), so our code can talk to it.
7. **Buy with Vinny's Cfx.re account.** Escrowed scripts only run on a server whose license key belongs to the account that bought them.
8. **Check before buying:** recent updates, an active Discord, a preview video, the performance cost (resmon), and the refund policy.
9. **Log every purchase** (name, price, version, escrowed or open, date) in `docs/purchases.md`.

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
12. ✅ **Custom #1: `rp_goals`** v1.0.0 is live and tested: goal at creation, reminder on spawn, `/goal`, and `/goals`. It uses placeholder text that Liam can rewrite in `locales/en.json`.
13. ✅ **Custom #2: `rp_welcome`** replaces the chat banner, which never went away, with a welcome pop-up that fades after 20 seconds (once per session), and adds `/discord` to copy the invite. The Discord link now lives only in `server.cfg` as `setr qbx:discordLink`.
14. ✅ **Custom #3: `rp_vehicles`**: speed caps per class, police speed edge, and the block on 152 weaponized/armored/military vehicles. Tested Oct 27.
15. ⏳ **Custom #4: `rp_buyers`** (Oct 27): NPC buyers for legal goods. A Scrap Buyer at the Sandy Shores scrap yard, for materials from scrapping cars (real scrap prices: copper $4.70/lb, aluminum $0.60, steel/iron/plastic $0.10, glass/rubber $0.05) and a Wine Buyer at the vineyard marker (wine $6, juice $1.50). Paid in cash. Staff can move a buyer with `/buyerhere`. Waiting on Vinny's upload and test.
16. ⏳ **Custom #5: `rp_jobmoments`** (Oct 27): job moments for garbage and taxi, about 1 task in 20 (10-minute cooldown). Garbage: a **bloody bag** with a pistol (turn in, keep, or leave; keeping gives a real unregistered pistol whose serial is on file for an open shooting case) and a **lost wallet** (return it to the owner's door for $100, or take the $60). Taxi: a **left-behind bag** of $300 (turn in, or keep it as dirty money; the passenger's report has the cab's plate) and a **runner** (grab them for the fare + 25% tip, call it in to police, or let them go; running them over becomes a pedestrian-death case). Evidence is turned in at the police clock-in spots (Mission Row, Paleto) for $100; on-duty police log it without reward. **`/cases`** and **`/serial`** for on-duty police and staff; staff (mod+) also see who kept what. The case file and `/serial` both say the shooter is unknown (NPC cases rule, Pillar D). Adds the `found_evidence` and `lost_wallet` items. Waiting on Vinny's upload and test.
17. ✅ **Custom #6: `rp_starter`** (Nov 2, tested the same day: tour runs end to end, and the volunteer and kiosk spots are good; two launch bugs fixed, see `resources/[custom]/README.md`): the starter area and new-arrival tour (see Phase 1, #1). Adds the `rp_starter_progress` table and blocks starter vehicle sales in qbx_vehiclesales and `/transfervehicle`. rp_goals now fires `rp_goals:client:goalSaved` so the tour starts right after the goal screen. Still to check: a starter vehicle is refused at the used car lot.
18. ⏳ **Custom #7: `rp_crews`** (Nov 2): crews via `/crew` (menu: invite someone nearby or by ID, see who's working, leave, leader can remove). Bonus paid to the bank per task: +10% per crewmate who finished a task in the same job in the last 10 minutes, up to +30%. Needs rp_jobmoments (it announces finished tasks). Also Nov 2: `rp_jobmoments` gained **tow: trunk find** (taped brick; turn in for $100, keep a `coke_brick`, or leave it) and **trucker: extra package** ($400 cash; turn in, keep as dirty money with a follow-up text from an unknown number, or leave it). Found drugs and cash only show up in police case files once turned in. Tow and trucker now call `OnTask`. Waiting on Vinny's upload and test.
19. ⏳ **Custom #8: `rp_jobmarkers`** (Nov 2): "Work:" map markers everyone can see for the garbage depot, taxi depot, tow yard, and trucker shed (Qbox only shows them after you take the job). Hidden for your own job so they don't double up. Walking up to a depot without the job shows a hint to sign up at City Hall. Also: City Hall's marker renamed to "City Hall (jobs and IDs)", and a Qbox bug fixed where tow drivers lost the tow yard markers after relogging. Waiting on Vinny's upload.

**Included in the Qbox recipe (decide later whether to keep, replace, or extend):**
- **Phone and UI:** npwd (free phone), qbx_hud, qbx_radialmenu, scully_emotemenu, playerlist, and ox_inventory with 303 items.
- **Prison:** xt-prison, a starting point for #6.
- **Legal jobs** (starting points for #4): garbage, taxi, tow, trucker, mechanic, news, car dealer, plus vineyard and diving as side gigs anyone can do. Bus and recycling are cut (disabled in `resources/[disabled]`), and hot dog is removed. News reporter is off the City Hall list (Nov 2) until it pays per story; staff can still give it.
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
- **Tutorial and starter area (#1)**: M. ⏳ **v1 built Nov 2 as `rp_starter`** (waiting on Vinny's test): arrival at the downtown bus station, the Fresh Start volunteer, 5 free starter vehicles (Asea, Landstalker, PCJ-600, Chino, Bobcat XL; one per character, half a tank, can't be sold or traded), a bus station kiosk, and a 7-step tour (volunteer → vehicle → kiosk → Fleeca Legion Square → gas on Strawberry Ave → City Hall → your goal's first step). Free starter apartments are off. First character must take the tour; later characters and staff can `/skiptutorial`. `/tutorial` repeats the current step. Text is placeholder for Liam. Still to come: phone and job board steps (after LB Phone).
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
  - ✅ Speed caps per class are live via `rp_vehicles` (script-enforced max, police edge). Vinny tested them on Oct 27 and confirmed they feel good. Retune later if chases feel off.
  - Rebalanced acceleration and braking.
  - More realistic traction and weight.
  - Documented class tiers.
- **Legal jobs, first wave (#4)**: L
  - Delivery, Taxi (NPC fares), Mechanic (NPC tow-ins), Garbage, and Construction.
  - Each job has levels, uses a work vehicle, pays per task (taxed), and posts to the opportunities feed.
  - **RP-first jobs** (decided Oct 27):
    - **Players before NPCs:** a real player's call for a cab, tow, or mechanic jumps ahead of NPC work. NPC work only fills the gaps.
    - **Job moments** (v1 built Oct 27 as `rp_jobmoments` for garbage and taxi, 1 task in 20; Vinny's picks: traceable pistol, small reward + police log; tow and trucker added Nov 2): now and then, a small event hands the worker a choice. Garbage: a bag with a pistol and a bloody shirt (turn it in to police, which gives the detective a case, or keep it). Taxi: "follow that car," or "wait out front, I'll be two minutes." Tow: something hidden in the trunk. Trucker: an extra package someone comes asking about later. Pay stays the same on average.
    - **Crew bonus** (✅ built Nov 2 as `rp_crews`): crews of 2–4 via `/crew`; each runs their own route and gets +10% per crewmate working the same job (max +30%). A shared ride-along route stays an idea for later.
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
  - Cases started by `rp_jobmoments` (NPC shootings, missing cash, fare evasion) follow the **NPC cases rule** in Pillar D: charges only for what a player actually did.
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

## 7. Economy model (decided Oct 27, 2026, RP-first)

**The full price list and calculator live in `docs/economy.xlsx`.** Edit the blue cells and everything recalculates.

**Philosophy:** roleplay comes first. Money matters for the big things and stays out of the way for the small things. Nobody should need to grind, and nobody should get stupid rich.

**The rules:**
1. **Prices mirror the real world** (US, Oct 2026), so quick math works. For example, $1,000 covers a pistol ($650) and ammo ($15/box). The weapon license is a one-time $350.
2. **Pay per hour of work = real hourly wage × 30.** Starter jobs pay about $510/hr, the median is about $735, police about $1,080. $1,000 is about 2 hours of starter work. **Target: a regular player works about ⅓ of their playtime**; the rest is roleplay.
3. **The only weekly bills are rent and loan payments**, charged once every real week and **paused if the player didn't log in**. Rent is the real monthly price (studio $1,264, 1BR $1,533).
4. **Felt when it happens, at real prices:** medical bills, fines, impound, repairs, guns, cars, homes.
5. **Background (cheap):** fuel ($4.26/gal, about $64 a tank, a few dollars an hour) and food/drink ($2–10). **Hunger and thirst drain at about half of Qbox's default.**
6. **Dropped:** phone bill (buy the phone once), car insurance (wrecks are a one-time repair or impound cost), utilities, sales tax (the sticker price is what you pay), and property tax or registration on normal cars and homes.
7. **Luxury upkeep (keeps the rich in check):** cars over **$100k** pay **6%/yr** on the value above the line, and homes over **$750k** pay **2%/yr** above the line, charged 1/12 each real week. A $3M hypercar costs about $14,500/week; a $5M mansion about $7,100/week.
8. **Crime pays about 2.5× entry pay per hour** (~$1,275/hr target), averaged over cooldowns and heat. Dirty money loses **30%** when laundered. The black market charges about 2.5× store price for guns. Fences pay 25% of retail.
9. **New characters:** $500 cash + $2,500 bank + a free starter vehicle.
10. **Income tax:** brackets rounded from US federal brackets ÷ 12, applied to each real week of job income. Loans use real rates (mortgage 6.86%, used car ~11%), with one payment per real week.

**Sanity check** (Life Math tab, one real week):

| Player | Week | Left over |
|---|---|---|
| Casual | 5 hrs played (2 working) | ~$90 |
| Regular | 12 played (4 working), 1BR | ~$600 |
| Dedicated | 25 played (8 working), 2BR + car loan | ~$1,850 |
| Grinder | 25 played (20 working) | ~$8,700, held back by luxury upkeep once they buy luxury |
| Criminal | 12 played (4 of crime) | ~$1,850 |
| Wealthy lawyer | $250k car + $2M home | ~$2,800/week upkeep |

**Implementation checklist:**
- ✅ (Oct 27) Starting bank 2,500, hunger/thirst at half speed (`qbx_core/config/server.lua`).
- ✅ (Oct 27) Store prices set to real-world (`ox_inventory/data/shops.lua`). Random price swings are off (`ox.cfg`), `cola` is fixed to `sprunk`, more items are stocked, and ammo is **$1/round** (simple quick math; ammo boxes optional later).
- ✅ (Oct 27) Weapon license 350 (`ox_inventory/data/licenses.lua`).
- ✅ (Oct 27) Fuel ~$67 a tank, petrol can $35, refill $21 (`ox_fuel/config.lua`).
- Not yet: police armory and EMS medicine cabinet prices (department gear, still to decide).
- ✅ (Oct 27) Vehicle prices from the sheet → `qbx_core/shared/vehicles.lua` (692 repriced). Boats and aircraft are hand-priced. **152 weaponized, armored, military, arena, and sci-fi vehicles removed and blocked from spawning anywhere** (`rp_vehicles`).
- Note: sports and super cars aren't sold anywhere yet, because Qbox's luxury dealership is commented out in `qbx_vehicleshop/config/shared.lua`. Qbox also has built-in dealership financing (10% down, 24 payments) to consider for Phase 2 loans.
- ✅ (Oct 27) **Job pay** (see the Jobs & Pay tab and `docs/core-changes.md`). Paychecks only for clocked-in police ($900–1,620/hr), EMS ($600–1,500/hr), and mechanics ($300–480/hr base + customers). Taxi $5 + $15/mile, garbage $6–9/bag, trucker $22–28/box, tow $80–95/tow, bus unchanged ($15–25/stop), coral $16–22 / $11–15, car dealer commission 2.5%. The useless cryptostick rewards are off. ⏳ Check each job's real hourly in play and retune.
- ✅ (Oct 27) **The vineyard pays** through `rp_buyers` (see section 6, Phase 0, item 15): grape picking gives 1–2 grapes (was 8–12), about 90 bottles of wine an hour ≈ $540. Scrap from the scrap yard sells at real prices to the Scrap Buyer. The recycling job was cut the same day.
- Later: reporter pay per story; judge clock-in at the courthouse (Phase 3); the trucker/tow 15% "tax" gets replaced by the real tax system (Phase 2).
- Later (Phase 2): weekly rent and loan billing (paused if inactive), luxury upkeep, the tax system, laundering, and loans.

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

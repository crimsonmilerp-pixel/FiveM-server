# [custom] resources

Everything we write ourselves lives in this folder. The square brackets mean FiveM treats it as a category folder rather than a single resource.

Rules:
- Each resource gets its own folder with an `fxmanifest.lua`.
- Every resource starts with the same name prefix, decided once the server is named. Until then, use `rp_`.
- All player-facing text goes in `locales/en.json`, so Liam can edit it without touching code.
- Settings an admin might tune (prices, timers, rates) go in `config.lua`.
- In `dependencies`, list only resources that also run in players' games. A server-only resource (like `qbx_vehicles`, marked `server_only 'yes'`) makes every player fail to load ours with "Couldn't load resource". This happened with rp_starter on Nov 2.
- Yes/no database columns (`TINYINT(1)`) come back from oxmysql as `true`/`false`, not `1`/`0`. Check them with a helper that accepts both. Comparing to `1` caused the rp_starter final screen to loop on Nov 2.
- Events the **server** sends to players' games (like `QBCore:Client:OnPlayerUnload` and `QBCore:Client:OnJobUpdate`) need `RegisterNetEvent`. `AddEventHandler` alone never hears them. (`QBCore:Client:OnPlayerLoaded` is fired inside the game, so either works.) Found in the Nov 2 audit.
- Anything a player types (names, goals, descriptions, street names their game sends) can end up in ox_lib menus and dialogs, which format text like Markdown. Clean it on the server first: strip `<` and `>`, and break up `![` and `](`, so nobody can sneak in an image that loads from the internet (it would reveal the viewer's IP address).

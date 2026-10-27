# [custom] resources

Everything we write ourselves lives in this folder. The square brackets mean FiveM treats it as a category folder rather than a single resource.

Rules:
- Each resource gets its own folder with an `fxmanifest.lua`.
- Every resource starts with the same name prefix, decided once the server is named. Until then, use `rp_`.
- All player-facing text goes in `locales/en.json`, so Liam can edit it without touching code.
- Settings an admin might tune (prices, timers, rates) go in `config.lua`.

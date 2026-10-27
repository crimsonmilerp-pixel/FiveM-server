# rp_welcome: Welcome Pop-up and /discord

- **Welcome pop-up:** when a player spawns, a pop-up shows our Discord link. It **fades away after 20 seconds** and appears once per session.
- **`/discord`:** copies our Discord invite link to the player's clipboard.

The Discord link is set **once** in `server.cfg` (`setr qbx:discordLink "..."`). To change it, edit only that line.
Wording is in `locales/en.json` (for Liam). Timing is in `config.lua`.

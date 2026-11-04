fx_version 'cerulean'

game "gta5"

author "Project Sloth & OK1ez"
version '3.0.0'

lua54 'yes'

ui_page 'html/index.html'
-- ui_page 'http://localhost:5173/' --for dev

client_script {
  -- [OUR CHANGE] Removed the three '@PolyZone/...' lines: this version uses ox_lib zones,
  -- and we don't run PolyZone (it would fail to load without it). See docs/core-changes.md
  'client/**',
}
server_script {
  "server/**",
}
shared_script {
  "shared/**",
  '@ox_lib/init.lua',
}

files {
  'html/**',
  'locales/*.json',
}

ox_lib 'locale' -- v3.8.0 or above

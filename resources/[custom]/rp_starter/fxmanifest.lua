fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_starter'
description 'Starter area: bus station arrival, the Fresh Start volunteer, a free starter vehicle, the kiosk, and the new-arrival tour'
version '1.0.0'

-- Loads ox_lib's locale module, so all player-facing text comes from locales/en.json
ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'config.lua',
    'locales/*.json',
}

-- qbx_vehicles is also needed, but it's server-only, so it can't be listed here:
-- players' games never receive it, and they'd refuse to load this resource.
dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'ox_inventory',
    'qbx_core',
    'qbx_vehiclekeys',
}

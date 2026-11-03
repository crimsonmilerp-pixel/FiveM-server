fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_police'
description 'Police groundwork: ranks and divisions, certifications, cadet training, vehicle access, and the penal code'
version '1.0.0'

-- Loads ox_lib's locale module, so all player-facing text comes from locales/en.json
ox_lib 'locale'

shared_script '@ox_lib/init.lua'

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'config.lua',
    'data/penalcode.lua',
    'locales/*.json',
}

-- Only list resources that also run in players' games (see resources/[custom]/README.md).
dependencies {
    'ox_lib',
    'qbx_core',
}

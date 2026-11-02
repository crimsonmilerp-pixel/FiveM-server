fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_jobmarkers'
description 'Work markers on the map for every job depot, so new players know where jobs are before signing up'
version '1.0.0'

-- Loads ox_lib's locale module, so all player-facing text comes from locales/en.json
ox_lib 'locale'

shared_script '@ox_lib/init.lua'

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

files {
    'config.lua',
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'qbx_core',
}

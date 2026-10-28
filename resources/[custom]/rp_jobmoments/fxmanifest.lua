fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_jobmoments'
description 'Job moments: now and then, a small story event during a job hands the worker a choice'
version '1.0.0'

-- Loads ox_lib's locale module, so all player-facing text comes from locales/en.json
ox_lib 'locale'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'config.lua',
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'ox_inventory',
    'qbx_core',
}

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_economy'
description 'Money engine: income tax taken off every paycheck and job payout, the government treasury, and weekly bills (luxury upkeep now; rent and loans later)'
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

-- Only list resources that also run in players' games (see resources/[custom]/README.md).
dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

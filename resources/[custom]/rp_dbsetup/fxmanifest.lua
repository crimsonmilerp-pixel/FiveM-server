fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_dbsetup'
description 'Runs the database setup files that bought or downloaded scripts come with, once each, so nobody needs a database tool'
version '1.0.0'

server_only 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/split.lua',
    'server/main.lua',
}

-- Server-only resource: it runs nothing in players' games.
dependencies {
    'oxmysql',
}

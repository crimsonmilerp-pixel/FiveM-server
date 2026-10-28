fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_buyers'
description 'NPC buyers who pay for legal goods: scrap materials and wine'
version '1.0.0'

-- Loads ox_lib's locale module, so all player-facing text comes from locales/en.json
ox_lib 'locale'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'config.lua',
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
}

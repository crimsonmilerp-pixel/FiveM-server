fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_vehicles'
description 'Speed limits per vehicle class, police speed edge, and a block on weaponized/armored/military vehicles'
version '1.0.0'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'config.lua',
}

dependencies {
    'ox_lib',
}

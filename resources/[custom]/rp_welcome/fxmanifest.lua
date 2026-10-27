fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_welcome'
description 'Welcome pop-up with our Discord link, and the /discord command'
version '1.0.0'

ox_lib 'locale'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'

files {
    'config.lua',
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'qbx_core',
}

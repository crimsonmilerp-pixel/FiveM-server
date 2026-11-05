fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_clothing_images'
description 'Pictures of every clothing item for our clothing menus, and the staff photo tool that makes them (/clothingphotos)'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua',
}

server_script 'server.js'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/shots.js',
    -- the pictures (made by /clothingphotos; restart this resource after a photo run)
    'img/*.json',
    'img/*.webp',
    'img/*.png',
}

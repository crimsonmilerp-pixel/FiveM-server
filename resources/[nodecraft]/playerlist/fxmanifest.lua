-- This resource is part of Nodecraft Pro, and is used to enhance the panel experience for our customers.
-- Altering or recreating for local use only is strongly discouraged.

version '1.0.1'
author 'Nodecraft <developers@nodecraft.com>'
description 'Manages player allowlist in Nodecraft Pro, and prints out connection and disconnection messages to the console. Do not disable!'
repository 'https://github.com/nodecraft/fivem-scripts'

server_script 'server.lua'

fx_version 'adamant'
games { 'gta5', 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

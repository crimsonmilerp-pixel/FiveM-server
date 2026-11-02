fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_crews'
description 'Crews: work a job alongside friends and each task pays a bonus per crewmate working the same job'
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

-- Finished tasks are announced by rp_jobmoments (started before this one in server.cfg).
-- Only list resources that also run in players' games (see resources/[custom]/README.md).
dependencies {
    'ox_lib',
    'qbx_core',
}

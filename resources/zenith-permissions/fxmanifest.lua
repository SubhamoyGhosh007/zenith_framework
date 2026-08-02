fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-permissions'
author 'Zenith'
version '0.1.0'
description 'DB groups and ace principal synchronizer for Zenith Framework'

dependencies {
    'zenith-player',
    'zenith-admin'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-player'
author 'Zenith'
version '0.1.0'
description 'Zenith Session and Player Identification Layer'

dependencies {
    'zenith-core'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

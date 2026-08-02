fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-admin'
author 'Zenith'
version '0.1.0'
description 'Zenith Administrator toolkit and logs'

dependencies {
    'zenith-player'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

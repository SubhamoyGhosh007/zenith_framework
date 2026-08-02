fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-characters'
author 'Zenith'
version '0.1.0'
description 'Multi-Character Slot Manager and Customization hook'

dependencies {
    'zenith-player'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

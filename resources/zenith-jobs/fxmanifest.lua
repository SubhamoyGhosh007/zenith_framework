fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-jobs'
author 'Zenith'
version '0.1.0'
description 'Job duty and grading registry for Zenith Framework'

dependencies {
    'zenith-player'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-money'
author 'Zenith'
version '0.1.0'
description 'Append-Only Money Ledger System'

dependencies {
    'zenith-player'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

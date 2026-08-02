fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-core'
author 'Zenith'
version '0.1.0'
description 'Zenith Core Bootstrap & Registry Hub'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

exports {
    'GetCoreObject'
}

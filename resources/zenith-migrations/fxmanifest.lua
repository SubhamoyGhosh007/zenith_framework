fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-migrations'
author 'Zenith'
version '0.1.0'
description 'Database migrations runner for Zenith Framework'

dependencies {
    'oxmysql'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    '../../sql/migrations/0001_initial.sql'
}

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zenith-nui'
author 'Zenith'
version '0.1.0'
description 'Zenith React NUI Interface overlay'

ui_page 'web/dist/index.html'

client_scripts {
    'client/nui.lua'
}

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css'
}

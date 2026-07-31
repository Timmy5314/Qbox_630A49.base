fx_version 'cerulean'
game 'gta5'

name 's4t4n667_elevators'
description 'Elevator system using ox_lib - Qbox port for Los Balos RP'
author 'Asgaard Developments | s4t4n667 (Qbox port: Los Balos RP)'
version '1.0.4-qbx'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'config.lua',
    'locales/*.json',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}

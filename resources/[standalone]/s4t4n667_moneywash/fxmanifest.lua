fx_version 'cerulean'
game 'gta5'

name 's4t4n667_moneywash'
description 'Criminal money laundering system - Qbox port for Los Balos RP'
author 'Asgaard Developments | s4t4n667 (Qbox port: Los Balos RP)'
version '2.0.0-qbx'

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
    'ox_inventory',
    'qbx_core',
    'renzu_shops',
}

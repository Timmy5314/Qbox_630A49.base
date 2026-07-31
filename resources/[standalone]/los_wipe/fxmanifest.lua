fx_version 'cerulean'
game 'gta5'

name 'los_wipe'
description 'Monthly wipe with dry run, snapshot and three safety locks'
author 'Los Balos RP'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'shared/config.lua',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
}

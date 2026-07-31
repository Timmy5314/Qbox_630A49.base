fx_version 'cerulean'
game 'gta5'

name 'los_discord'
description 'Discord logging and role state for Los Balos RP'
author 'Los Balos RP'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'shared/config.lua',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'qbx_core',
}

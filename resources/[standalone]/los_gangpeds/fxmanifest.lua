fx_version 'cerulean'
game 'gta5'

name 'los_gangpeds'
description 'Ambient gang peds recognise players of that gang'
author 'Los Balos RP'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'qbx_core',
}

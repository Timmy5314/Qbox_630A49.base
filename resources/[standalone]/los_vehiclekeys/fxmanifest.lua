fx_version 'cerulean'
game 'gta5'

name 'los_vehiclekeys'
description 'Vehicle keys as a real ox_inventory item, on top of qbx_vehiclekeys'
author 'Los Balos RP'
version '1.0.0'

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
    'shared/config.lua',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'qbx_vehiclekeys',
}

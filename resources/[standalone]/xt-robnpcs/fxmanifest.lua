fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 'xt-robnpcs'
author 'xT Development (Qbox port: Los Balos RP)'
description 'Rob NPCs - Qbox only'
version '1.1.1-qbx'
repository 'https://github.com/xT-Development/xt-robnpcs'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'configs/shared.lua',
}

client_scripts {
    'configs/client.lua',
    'client/utils.lua',
    'client/cl_main.lua',
}

server_scripts {
    'configs/server.lua',
    'server/sv_main.lua',
}

files {
    'locales/*.json',
}

-- Renewed-Lib is eruit; die resource draait niet op deze server.
dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
}

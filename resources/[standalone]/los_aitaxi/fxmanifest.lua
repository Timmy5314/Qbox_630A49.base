fx_version 'cerulean'
game 'gta5'

name 'los_aitaxi'
description 'Downtown Cab Co. - AI taxi you call with NPWD, only when no real drivers are on duty'
author 'Los Balos RP'
version '1.0.0'

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
    'shared/config.lua',
    'locales/*.json',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'qbx_core',
    'npwd',
}

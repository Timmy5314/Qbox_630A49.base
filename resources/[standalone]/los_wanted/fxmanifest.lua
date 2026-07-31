fx_version 'cerulean'
game 'gta5'

name 'los_wanted'
description 'AI police that scales with how many real officers are on duty'
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
}

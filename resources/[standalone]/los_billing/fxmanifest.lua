fx_version 'cerulean'
game 'gta5'

name 'los_billing'
description 'Invoices with insurance coverage, interest and an audit trail'
author 'Los Balos RP'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'shared/config.lua',
    'locales/*.json',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'oxmysql',
}

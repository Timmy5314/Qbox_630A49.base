fx_version 'cerulean'
game 'gta5'

name 'los_anticheat'
description 'Los Balos RP - server-authoritative anti-cheat'
author 'Los Balos RP'
version '0.1.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
    'shared/weapondamage.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'data/events.generated.lua',
    'server/score.lua',
    'server/modules/damage.lua',
    'server/modules/entities.lua',
    'server/modules/heartbeat.lua',
    'server/modules/inventory.lua',
    'server/modules/events.lua',
    'server/admin.lua',
}

client_scripts {
    'client/heartbeat.lua',
    'client/admin.lua',
}

files {
    'locales/*.json',
}

lua54 'yes'
dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

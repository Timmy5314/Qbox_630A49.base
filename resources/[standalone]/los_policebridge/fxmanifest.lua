fx_version 'cerulean'
game 'gta5'

name 'los_policebridge'
description 'Compat-brug: legacy police:server:policeAlert -> ps-dispatch, plus cop-count feed voor qbx_bankrobbery'
author 'Los Balos RP'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

lua54 'yes'

-- ps-dispatch bewust NIET als dependency: die start in [ps], ná [standalone].
-- De CustomAlert-aanroep gebeurt client-side tijdens een overval (runtime), dus
-- laadvolgorde maakt niet uit. qbx_core en ox_lib laden wel vóór [standalone].
dependencies {
    'ox_lib',
    'qbx_core',
}

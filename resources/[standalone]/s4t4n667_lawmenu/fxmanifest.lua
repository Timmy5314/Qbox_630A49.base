fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 's4t4n667_lawmenu'
author "Asgaard Developments | s4t4n667 (Qbox port: Los Balos RP)"
description 'Charges list, lawyer contacts and police contacts'
version '2.0.0-qbx'

ox_lib 'locale'

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'resource/client.lua',
    'resource/charges.lua',
}

server_scripts {
    'resource/server.lua',
}

files {
    'locales/*.json',
}

-- Deze resource had als enige uit _external geen framework-code: hij draait al
-- volledig op ox_lib en ox_target. Er viel niets te strippen.
dependencies {
    'ox_lib',
    'ox_target',
}

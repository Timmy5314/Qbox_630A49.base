fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 'stevo_chopshop'
author 'StevoScripts (Qbox port: Los Balos RP)'
description 'Simple Chop Shop - Qbox only'
version '1.0.4-qbx'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua',
    'bridge/main.lua',
}

client_scripts {
    'resource/client.lua',
    'bridge/client.lua',
    'bridge/editable_client.lua',
}

-- 'bridge/editable_server.lua' stond hier in het origineel, maar dat bestand
-- zit niet in de release. Dat levert bij elke start een warning op over een
-- ontbrekend script. Verwijderd.
--
-- oxmysql toegevoegd: bridge/server.lua gebruikt MySQL.insert en MySQL.single
-- maar het origineel laadde de library nergens.
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'resource/server.lua',
    'bridge/server.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
    'oxmysql',
}

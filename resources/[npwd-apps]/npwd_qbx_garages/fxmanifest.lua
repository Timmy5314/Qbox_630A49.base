fx_version 'cerulean'
game 'gta5'

description 'Garages app for NPWD — aangepast voor renzu_garage (Los Balos RP)'
version '1.2.0-losbalos'
repository 'https://github.com/Qbox-Project/npwd_qbx_garages'

-- renzu_garage vervangt qbx_garages op deze server. Zonder deze dependency
-- start de app voordat de garage-exports bestaan.
dependencies {
    'renzu_garage',
    'ox_lib',
    'qbx_core',
}

ox_lib 'locale'
shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

client_script 'client/client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

ui_page 'web/dist/index.html'

files {
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/**/*',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
provide 'npwd_qb_garage'
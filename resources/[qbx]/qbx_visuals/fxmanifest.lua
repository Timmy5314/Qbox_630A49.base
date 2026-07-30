fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_visuals'
author 'timwi'
version '4.1.0'
description 'Fotorealistische kleurcorrectie, visualsettings, populatiebeheer en verplicht first person voor Qbox'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_script 'server/permissions.lua'

-- Volgorde is belangrijk: core.lua zet de gedeelde state op, en
-- firstperson.lua definieert QV.setFieldOfView die commands.lua gebruikt.
client_scripts {
    'client/core.lua',
    'client/grading.lua',
    'client/firstperson.lua',
    'client/customcam.lua',
    'client/render.lua',
    'client/visualsettings.lua',
    'client/performance.lua',
    'client/commands.lua'
}

files {
    'data/timecycle_mods_photoreal.xml',
    -- Moet in files{} staan, anders kan de client hem niet met
    -- LoadResourceFile inlezen.
    'data/visualsettings.dat'
}

data_file 'TIMECYCLEMOD_FILE' 'data/timecycle_mods_photoreal.xml'


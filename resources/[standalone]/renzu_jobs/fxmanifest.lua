fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'renzu_jobs'
description 'Job utility suite for QBox (qbx_core) - boss menu, stashes, shops, crafting, armory, job garage, vehicle shop, duty and turf wars'
author 'Renzuzu - rewritten for qbx_core / ox_lib / ox_inventory / ox_target'
version '2.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/jobs.lua',
    'config/weapons.lua',
    'config/turfs.lua',
    'config/foodjobs.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/utils.lua',
    'client/nui.lua',
    'client/targets.lua',
    'client/boss.lua',
    'client/stash.lua',
    'client/shop.lua',
    'client/crafting.lua',
    'client/armory.lua',
    'client/garage.lua',
    'client/vehicleshop.lua',
    'client/duty.lua',
    'client/wardrobe.lua',
    'client/foodjob.lua',
    'client/turf.lua',
    'client/interaction.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/db.lua',
    'server/logs.lua',
    'server/accounts.lua',
    'server/boss.lua',
    'server/stash.lua',
    'server/shop.lua',
    'server/crafting.lua',
    'server/armory.lua',
    'server/garage.lua',
    'server/vehicleshop.lua',
    'server/duty.lua',
    'server/foodjob.lua',
    'server/turf.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}

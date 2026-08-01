fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'renzu_clothes'
description 'Item based clothing store, wardrobe and outfit system for QBox (qbx_core)'
author 'Renzuzu - v2 rewrite for qbx_core / ox_lib / ox_inventory'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_clothes'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
    'config/shops.lua',
}

client_scripts {
    'client/bridge.lua',
    -- NameHash-database van het originele renzu_clothes: koppelt
    -- model/component/drawable/texture -> NameHash (= bestandsnaam in
    -- carmap/clothes). Levert het globale `Components`. Groot (2,6 MB) maar
    -- laadt eenmalig; zonder deze regel vallen de grid-tegels terug op nummers.
    'legacy/components_old.lua',
    'client/wardrobe.lua',
    'client/nui.lua',
    'client/shop.lua',
    'client/outfits.lua',
    'client/radial.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/db.lua',
    'server/wardrobe.lua',
    'server/shop.lua',
    'server/outfits.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
}

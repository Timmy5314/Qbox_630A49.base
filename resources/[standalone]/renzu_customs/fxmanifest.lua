fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'renzu_customs'
description 'Advanced mechanic tuning shop - Qbox edition (ox_lib / ox_target / oxmysql)'
author 'renzuzu | Qbox rewrite'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_customs'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/state.lua',
    'client/utils.lua',
    'client/vehicle.lua',
    'client/performance.lua',
    'client/tuning.lua',
    'client/nui.lua',
    'client/parts.lua',
    'client/shops.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/fonts/*.woff2',
    'html/fonts/*.woff',
    'html/fonts/*.ttf',
    'html/img/*.svg',
    'html/audio/*.ogg',
    'handling.min.json',
    'data/carcols_gen9.meta',
    'data/carmodcols_gen9.meta',
    'data/carmodcols.ymt',
}

data_file 'CARCOLS_GEN9_FILE' 'data/carcols_gen9.meta'
data_file 'CARMODCOLS_GEN9_FILE' 'data/carmodcols_gen9.meta'
data_file 'FIVEM_LOVES_YOU_447B37BE29496FA0' 'data/carmodcols.ymt'

dependencies {
    '/onesync',
    'ox_lib',
    'ox_target',
    'oxmysql',
    'qbx_core',
}

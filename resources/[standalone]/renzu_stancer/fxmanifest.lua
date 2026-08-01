fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'
use_fxv2_oal 'yes'

name 'renzu_stancer'
description 'Vehicle stance/suspension tuning - Qbox edition (qbx_core / ox_lib / ox_inventory / oxmysql)'
author 'renzuzu | Qbox rewrite'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_stancer'

ui_page 'html/index.html'

shared_scripts {
	'@ox_lib/init.lua',
	"config.lua"
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
    'framework/sv_wrapper.lua',
	"server.lua"
}
client_scripts {
	"client.lua",
}

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
	'html/audio/*.ogg'
}

dependencies {
	'qbx_core',
	'ox_lib',
	'oxmysql',
	'ox_inventory',
}

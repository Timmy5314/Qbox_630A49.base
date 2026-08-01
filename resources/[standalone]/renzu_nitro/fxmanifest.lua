fx_version 'cerulean'
game 'gta5'
lua54 'on'
use_fxv2_oal 'on'

name 'renzu_nitro'
description 'Vehicle nitro/NOS system - Qbox edition (qbx_core / ox_inventory)'
author 'renzuzu | Qbox rewrite'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_nitro'

ui_page 'html/index.html'

shared_scripts {
	"config.lua"
}

server_scripts {
	"server.lua"
}
client_scripts {
	"client.lua",
}

files {
	'html/index.html',
	'html/script.js',
}

dependencies {
	'qbx_core',
	'ox_inventory',
}

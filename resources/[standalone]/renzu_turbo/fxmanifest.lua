fx_version 'cerulean'
game 'gta5'
lua54 'on'

name 'renzu_turbo'
description 'Vehicle turbo tuning - Qbox edition (qbx_core / ox_inventory)'
author 'renzuzu | Qbox rewrite'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_turbo'

ui_page 'html/index.html'

shared_scripts {
	"config.lua"
}

server_scripts {
	'framework/sv_wrapper.lua',
	"server.lua"
}
client_scripts {
	"client.lua",
}

files {
	'html/index.html',
	'html/script.js',
	'html/audio/*.ogg',
}

dependencies {
	'qbx_core',
	'ox_inventory',
}

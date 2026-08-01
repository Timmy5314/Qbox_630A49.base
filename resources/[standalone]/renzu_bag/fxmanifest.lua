fx_version 'cerulean'
game 'gta5'
lua54 'on'

name 'renzu_bag'
description 'Wearable/placeable storage bags - Qbox edition (qbx_core / ox_lib / ox_inventory)'
author 'renzuzu | Qbox rewrite'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_bag'

shared_script '@ox_lib/init.lua'

client_scripts {
	'config.lua',
	'client/main.lua'
}

server_scripts {
	'config.lua',
	'server/main.lua'
}

dependencies {
	'qbx_core',
	'ox_lib',
	'ox_inventory',
}

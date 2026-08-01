fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'renzu_itemback'
description 'Show carried items on the players back - Qbox edition (qbx_core / ox_lib / ox_inventory)'
author 'renzuzu | Qbox rewrite'
version '2.0.0'
repository 'https://github.com/renzuzu/renzu_itemback'

shared_script '@ox_lib/init.lua'

client_scripts {
	'config.lua',
	'components.lua',
	'client/main.lua',
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

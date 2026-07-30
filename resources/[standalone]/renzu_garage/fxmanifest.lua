fx_version   'cerulean'

lua54        'yes'
game         'gta5'


ui_page 'html/index.html'

shared_scripts {
	'@ox_lib/init.lua',	
	'conf/locale/*.lua',
	'conf/main.lua',
	'conf/*.lua',
	'vehicles.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'framework/sv_wrapper.lua',
	'server/*.lua'
}

client_scripts {
	'framework/cl_wrapper.lua',
	'client/*.lua'
}

dependencies {
    '/onesync',
    'qbx_core',
    'ox_lib',
    'oxmysql',
    'ox_inventory', -- moet VOOR renzu_garage starten, anders zijn de sleutel-items nog niet geladen
}
files {
	'html/design.css',
	'html/uikit.css',
	'html/forms.css',
	'html/index.html',
	'html/img/*.png',
	'html/script.js',
	'html/fonts/*',	
	'imgs/**.png',
	'imgs/uploads/*.jpg',
}

data_file 'DLC_ITYP_REQUEST' 'stream/garage.ytyp'
files {
    'stream/garage.ytyp'
}

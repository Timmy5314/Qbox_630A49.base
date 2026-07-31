return {
	General = { -- General Stores 24/7
		{ lvl = 1, name = 'burger', price = 110 , category = 'food', customise = {'cheese', 'lettuce', 'hotsauce', 'mayonaise', 'burgerpatty'}},
		{ lvl = 1, name = 'water', price = 20 , category = 'beverages', customise = {'mineralwater', 'purifiedwater'}},
		{ lvl = 1, name = 'cola', price = 65 , category = 'beverages'},
		{ lvl = 1, name = 'coffee', price = 65 , category = 'beverages'},
		{ lvl = 1, name = 'donut', price = 65 , category = 'food'},
		{ lvl = 1, name = 'sandwich', price = 65 , category = 'food'},
		{ lvl = 2, name = 'lighter', price = 20 , category = 'misc'},
		{ lvl = 2, name = 'redw', price = 1000 , category = 'TOBACCO'},
		{ lvl = 2, name = 'marlboro', price = 1000 , category = 'TOBACCO'},

		{ lvl = 2, name = 'phone', price = 1000 , category = 'gadget'},
		{ lvl = 2, name = 'radio', price = 1000 , category = 'gadget'},
		{ lvl = 2, name = 'latte', price = 280 , category = 'beverages'},

		{ lvl = 1, name = 'tomatosauce', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'burgerpatty', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'tacoshells', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'ground_beef', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'cheese', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'tomato', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'pasta', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'onion', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'mayonaise', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'hotsauce', price = 12 , category = 'ingredients'},
		{ lvl = 1, name = 'lettuce', price = 12 , category = 'ingredients'},
		{ lvl = 1, name = 'tacosauce', price = 15 , category = 'ingredients', disable = true}, -- disable tag, to disable the item from showing in shop UI. while this can be disable and enable tru store manage
		{ lvl = 1, name = 'fish', price = 12 , category = 'wet foods'},
		{ lvl = 1, name = 'beef', price = 12 , category = 'wet foods'},
		{ lvl = 1, name = 'chicken', price = 12 , category = 'wet foods'},
		{ lvl = 1, name = 'martini', price = 12 , category = 'liquor'},
		{ lvl = 1, name = 'bread', price = 35 , category = 'ingredients'},
		{ lvl = 1, name = 'hotdog', price = 55 , category = 'ingredients'},
		{ lvl = 1, name = 'fishingrod', price = 200 , category = 'fishing'},
		{ lvl = 1, name = 'fishbait', price = 50, category = 'fishing'},
		{ lvl = 1, name = 'garden_shovel', price = 1000 , category = 'seeds'},
		{ lvl = 1, name = 'garden_pitcher', price = 1000, category = 'seeds'},
		{ lvl = 1, name = 'pickle_seed', price = 100 , category = 'seeds'},
		{ lvl = 1, name = 'potato_seed', price = 100 , category = 'seeds'},
		{ lvl = 1, name = 'tomato_seed', price = 100 , category = 'seeds'},
		{ lvl = 1, name = 'wheat_seed', price = 100 , category = 'seeds'},
		{ lvl = 1, name = 'carrot_seed', price = 100 , category = 'seeds'},
		{ lvl = 1, name = 'corn_seed', price = 100 , category = 'seeds'},

		-- ── Tool shop ────────────────────────────────────────────────────
		-- Alles wat de md-drugs dealer verkocht en op zichzelf legaal is,
		-- staat nu hier. Een blunt draaien of wietkoekjes bakken hoeft geen
		-- ontmoeting met een crimineel te zijn.
		--
		-- BEWUST NIET HIER, die blijven bij de md-drugs NPC:
		--   isosafrole, mdp2p                 MDMA-precursors
		--   lysergic_acid, diethylamide       LSD-precursors
		--   tab_paper                         blotterpapier
		--   mdlean                            codeine
		--   cokeburner / crackburner / ...    prepaid telefoons voor deals
		--   lockpick                          inbraakgereedschap
		--
		-- Gegroepeerd per categorie, dus makkelijk uit te knippen als je hier
		-- later een losse YouTool-winkel van wilt maken.
		{ lvl = 1, name = 'bakingsoda',  price = 12 , category = 'household'},
		{ lvl = 1, name = 'flour',       price = 10 , category = 'household'},
		{ lvl = 1, name = 'chocolate',   price = 15 , category = 'household'},
		{ lvl = 1, name = 'mdbutter',    price = 18 , category = 'household'},

		{ lvl = 1, name = 'weedgrinder', price = 85 , category = 'smoke shop'},
		{ lvl = 1, name = 'mdwoods',     price = 8  , category = 'smoke shop'},
		{ lvl = 1, name = 'dabrig',      price = 240, category = 'smoke shop'},
		{ lvl = 1, name = 'leancup',     price = 6  , category = 'smoke shop'},

		{ lvl = 1, name = 'butane',      price = 22 , category = 'tools'},
		{ lvl = 1, name = 'butanetorch', price = 180, category = 'tools'},
		{ lvl = 1, name = 'emptyvial',   price = 9  , category = 'tools'},
		{ lvl = 1, name = 'needle',      price = 14 , category = 'tools'},
	
		
		{ lvl = 1, name = 'playerbooth', price = 50000 , category = 'misc', 
			metadata = { -- ox_inventory supported only
				name = 'marketbooth',
				label = 'Market Booth', -- custom label name to set from metadatas
				model = `ch_prop_ch_gazebo_01`,
				description = 'can be used for market booth',
				type = 'legal',
				blacklists = { -- blacklist the list of items here from appearing to shop
					['weapon_pistol'] = true, -- lowercase only
				},
			}
		},
		{ lvl = 1, name = 'playerbooth', price = 50000 , category = 'misc', 
			metadata = { -- ox_inventory supported only
				name = 'blackmarketbooth',
				label = 'Black Market Booth', -- custom label name to set from metadatas
				model = `ch_prop_ch_gazebo_01`,
				description = 'can be used for black market booth',
				type = 'illegal',
				whitelists = { -- if whitelist. only this items will appear on the shops
					['weapon_pistol'] = true, -- lowercase only
				}
			}
		},


		-- metadatas type item
		{ lvl = 1, name = 'burger', price = 170 , category = 'food', metadata = { -- ox_inventory supported only
				label = 'Cheese Burger', -- custom label name to set from metadatas
				cheese = true,
				name = 'cheeseburger', -- identifier important
				hunger = 500000,
				image = 'cheeseburger',
				description = 'Burger with Cheese',
				customrandomname = 'custom text'
			},
		},
		{ lvl = 1, name = 'burger', price = 45 , category = 'food', metadata = { -- ox_inventory supported only
				label = 'Angels Burger', -- custom label name to set from metadatas
				cheese = true,
				name = 'angelsburger', -- identifier important
				hunger = 100000,
				image = 'burger',
				description = 'Burger less patty',
				customrandomname = 'custom text'
			},
		},



	},
	Ammunation = { -- non-lethal only: no firearms/ammo sold here. Weapon
		-- attachments (auto-appended below from data/weaponcomponents.lua) are
		-- the actual product line - everything priced high on purpose.
		--
		-- Bewust NIET in een civiele wapenwinkel:
		--   WEAPON_KNIFE     - steekwapen over de toonbank, niet realistisch
		--   WEAPON_STUNGUN   - taser is politie-uitrusting, staat in PoliceArmoury
		--   WEAPON_NIGHTSTICK- wapenstok idem
		--   WEAPON_BZGAS     - traangas is geen consumentenartikel
		{ lvl = 1, name = 'WEAPON_FLASHLIGHT', category = 'tools', price = 3500 },
		{ lvl = 1, name = 'armour', category = 'protection', price = 20000 },
		{ lvl = 1, name = 'repairkit', category = 'tools', price = 8000 },
	},

	VehicleShop = MultiCategory(
		{
			['boats'] = true, -- blacklisted boats
			['planes'] = true, -- blacklisted planes
			['helicopters'] = true -- blacklisted helis
		},
		{}, -- whitelisted table
		{},
		AllVehicles -- all vehicles can be found /data/vehicles.lua
	),

	-- BlackMarketArms removed

	LiquorStore = {
		{ name = 'water', price = 350, category = 'drinks' },
		{ name = 'sanmig', price = 1011, category = 'drinks' },
		{ name = 'burger', price = 151, category = 'food' },
		{ name = 'panties', 500 , category = 'misc'},
		{ name = 'marlboro', price = 351, category = 'Cigarrete' },
		{ name = 'frog_grilled', price = 1251, category = 'food' },
		{ name = 'lapulapu_grilled', price = 1251, category = 'food' },
		{ name = 'galungong_grilled', price = 1251, category = 'food' },
	},

	PoliceArmoury = { -- PoliceArmoury
		{ category = 'ammo',  name = 'ammo-9', price = 2, },
		{ category = 'ammo',  name = 'ammo-rifle', price = 2, },
		{ category = 'ammo',  name = 'ammo-shotgun', price = 2, },
		{ category = 'ammo',  name = 'ammo-50', price = 2, },
		{ category = 'ammo',  name = 'ammo-rifle2', price = 2, },
		{ category = 'ammo',  name = 'ammo-45', price = 2, },
		{ category = 'throwable',  name = 'WEAPON_BZGAS', price = 300 },
		{ category = 'pistol',  name = 'WEAPON_PISTOL50', price = 300 },
		{ category = 'drink',  name = 'energy_drink', price = 300 },

		{ category = 'handheld',  name = 'WEAPON_FLASHLIGHT', price = 200 },
		{ category = 'handheld',  name = 'WEAPON_NIGHTSTICK', price = 100 },
		{ category = 'Pistol',  name = 'WEAPON_PISTOL', price = 500, metadata = { registered = true, serial = 'POL' }, },
		{ category = 'Rifle',  name = 'WEAPON_CARBINERIFLE', price = 800, grade = 5, metadata = { registered = true, serial = 'POL' },  grade = 3 },
		{ category = 'Rifle',  name = 'WEAPON_SPECIALCARBINE', price = 800, grade = 5, metadata = { registered = true, serial = 'POL' },  grade = 3 },
		{ category = 'handheld',  name = 'WEAPON_STUNGUN', price = 300, metadata = { registered = true, serial = 'POL'} },
		{ category = 'Shotguns',  name = 'WEAPON_PUMPSHOTGUN', price = 600, metadata = { registered = true, serial = 'POL'} },
		{ category = 'SMG',  name = 'WEAPON_COMBATPDW', price = 700 },
		{ lvl = 2, name = 'radio', category = 'handheld', price = 100, metadata = { description = 'pang pakunat' } },

		{ lvl = 2, name = 'armour', category = 'Tools', price = 100, metadata = { description = 'pang pakunat' } },
		{ lvl = 2, name = 'vision_helmet', category = 'Tools', price = 5000 },
		{ lvl = 2, name = 'thermal_helmet', category = 'Tools', price = 5000 },
		{ lvl = 2, name = 'gpstracker', category = 'Tools', price = 15000 },

		-- ── ND_Police uitrusting ─────────────────────────────────────────
		-- Deze stonden nergens te koop, terwijl ND_Police er volledig op
		-- draait. Zonder cuffs kon een agent letterlijk niemand aanhouden.
		-- De lockerroom van ND_Police geeft alleen kleding, geen items.
		{ lvl = 1, name = 'cuffs',       category = 'Restraints', price = 150 },
		{ lvl = 1, name = 'handcuffkey', category = 'Restraints', price = 75 },
		{ lvl = 1, name = 'zipties',     category = 'Restraints', price = 40 },
		{ lvl = 2, name = 'spikestrip',  category = 'Tools',      price = 1200, grade = 2 },
		{ lvl = 2, name = 'shield',      category = 'Tools',      price = 4500, grade = 3 },
		


	},

	-- ╔══════════════════════════════════════════════════════════════════╗
	-- ║  EmsSupply - medische uitrusting voor ND_Ambulance               ║
	-- ╠══════════════════════════════════════════════════════════════════╣
	-- ║  ND_Ambulance heeft zelf geen enkele winkel of locker met items. ║
	-- ║  EMS kon dus nergens een medbag of defib vandaan halen. De       ║
	-- ║  itemnamen hieronder komen exact uit ND_Ambulance/_INVENTORY.    ║
	-- ╚══════════════════════════════════════════════════════════════════╝
	EmsSupply = {
		{ lvl = 1, name = 'medbag',       category = 'Medical', price = 250 },
		{ lvl = 1, name = 'defib',        category = 'Medical', price = 1800, grade = 2 },
		{ lvl = 1, name = 'stretcher',    category = 'Medical', price = 900 },
		{ lvl = 1, name = 'gauze',        category = 'Supplies', price = 25 },
		{ lvl = 1, name = 'splint',       category = 'Supplies', price = 60 },
		{ lvl = 1, name = 'tourniquet',   category = 'Supplies', price = 85 },
		{ lvl = 1, name = 'burndressing', category = 'Supplies', price = 70 },
		{ lvl = 1, name = 'bandage',      category = 'Supplies', price = 20 },
		{ lvl = 1, name = 'armour',       category = 'Supplies', price = 400 },
		{ lvl = 1, name = 'radio',        category = 'Gear',    price = 300 },
	},

	MechanicSupply = { -- MechanicSupply
		{ category = 'Engine Parts',  name = 'transmition_clutch', price = 5000, },
		{ category = 'Engine Parts',  name = 'engine_flywheel', price = 3000, },
		{ category = 'Engine Parts',  name = 'engine_oil', price = 2000, },
		{ category = 'Engine Parts',  name = 'engine_sparkplug', price = 1000, },
		{ category = 'Engine Parts',  name = 'engine_gasket', price = 2000, },
		{ category = 'Engine Parts',  name = 'engine_airfilter', price = 2000, },
		{ category = 'Engine Parts',  name = 'engine_fuelinjector', price = 2000, },
		{ category = 'Engine Parts',  name = 'engine_pistons', price = 4000, },
		{ category = 'Engine Parts',  name = 'engine_connectingrods', price = 4000, },
		{ category = 'Engine Parts',  name = 'engine_valves', price = 2000, },
		{ category = 'Engine Parts',  name = 'engine_block', price = 5000, },
		{ category = 'Engine Parts',  name = 'engine_crankshaft', price = 5000, },
		{ category = 'Engine Parts',  name = 'engine_camshaft', price = 5000, },

		{ category = 'Engine Parts',  name = 'racing_clutch', price = 50001, },
		{ category = 'Engine Parts',  name = 'racing_flywheel', price = 30001, },
		{ category = 'Engine Parts',  name = 'racing_oil', price = 20001, },
		{ category = 'Engine Parts',  name = 'racing_sparkplug', price = 10001, },
		{ category = 'Engine Parts',  name = 'racing_gasket', price = 20001, },
		{ category = 'Engine Parts',  name = 'racing_airfilter', price = 20001, },
		{ category = 'Engine Parts',  name = 'racing_fuelinjector', price = 20001, },
		{ category = 'Engine Parts',  name = 'racing_pistons', price = 40001, },
		{ category = 'Engine Parts',  name = 'racing_connectingrods', price = 40001, },
		{ category = 'Engine Parts',  name = 'racing_valves', price = 20001, },
		{ category = 'Engine Parts',  name = 'racing_block', price = 50001, },
		{ category = 'Engine Parts',  name = 'racing_crankshaft', price = 50001, },
		{ category = 'Engine Parts',  name = 'racing_camshaft', price = 50001, },

		{ category = 'Tires',  name = 'street_tires', price = 20001, },
		{ category = 'Tires',  name = 'sports_tires', price = 40001, },
		{ category = 'Tires',  name = 'racing_tires', price = 60001, },
		{ category = 'Tires',  name = 'drag_tires', price = 80001, },
		{ category = 'Tires',  name = 'drift_tires', price = 50001, },

		{ category = 'Kits',  name = 'fixkit', price = 2000, },
		{ category = 'materials',  name = 'steel', price = 250, },
		{ category = 'Kits',  name = 'stancerkit', price = 2000, },
		{ category = 'engines',  name = 'enginegago', price = 50000, metadata = {
			handlingname = 'supra2jzgtett',
			description = 'Supra Engine - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'supra2jzgtett',
			label = 'Supra Engine Swap'
		}},
		{ category = 'engines',  name = 'enginegago', price = 50000, metadata = {
			handlingname = 'musv8',
			description = 'Mustang V8 Engine - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'musv8',
			label = 'Mustang V8 Engine Swap'
		}},
		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'b16b',
			description = 'Ek9 B16b Type R - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'musv8',
			label = 'B16b Type R Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'rx713b',
			description = 'Rx7 FC Engine - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'musv8',
			label = 'Rx7 Rotary Engine Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'f40v8',
			description = 'F40 V8 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'f40v8',
			label = 'F40 V8 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'f50v12',
			description = 'F50 V12 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'f50v12',
			label = 'F50 V12 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'ferrarif12',
			description = 'Ferarri F12 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'ferrarif12',
			label = 'Ferarri F12 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'f50v12',
			description = 'F50 V12 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'f50v12',
			label = 'F50 V12 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'diablov12',
			description = 'Diablo V12 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'diablov12',
			label = 'Diablo V12 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'k20a',
			description = 'k20A - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'k20a',
			label = 'k20A Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'r35sound',
			description = 'GTR35 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'r35sound',
			label = 'GTR35 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'r35sound',
			description = 'GTR35 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'r35sound',
			label = 'GTR35 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'murciev12',
			description = 'Murcielego v12 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'murciev12',
			label = 'Murcielego v12 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'sestov10',
			description = 'Sesto V10 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'sestov10',
			label = 'Sesto V10 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'gt3flat6',
			description = 'Gt3 Flat 6 - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'gt3flat6',
			label = 'Gt3 Flat 6 Engine Swap'
		}},

		{ category = 'engines',  name = 'enginegago', price = 30000, metadata = {
			handlingname = 'm158huayra',
			description = 'Huayra - Can be installed to any vehicles. ',
			image = 'engine',
			engine = 'm158huayra',
			label = 'Huayra Engine Swap'
		}},
		{ category = 'Turbo',  name = 'turbostreet', price = 15000, },
		{ category = 'Turbo',  name = 'turbosports', price = 30000, },
		{ category = 'Turbo',  name = 'turboracing', price = 50000, },
		{ category = 'Gadget',  name = 'vehiclecontroller', price = 150000, },



	},

	PondCafe = { -- PondCafe 
		{ category = 'Cupcake',  name = 'strawberry_cupcake', price = 1500, },
		{ category = 'Cupcake',  name = 'double_cupcake', price = 1500, },
		{ category = 'Cupcake',  name = 'vanilla_cupcake', price = 1500},
		{ category = 'Juice',  name = 'orangejuice', price = 1500},
		{ category = 'Juice',  name = 'mangojuice', price = 1500},
		{ category = 'Coffee',  name = 'cappuccino', price = 3500},
		{ category = 'Coffee',  name = 'latte', price = 3500},
		{ category = 'Coffee',  name = 'espresso', price = 3500},
		{ category = 'Tea',  name = 'milkteacafe', price = 2500},
		{ category = 'Tea',  name = 'milktea2', price = 2500},

	},

	['Balls8'] = { -- 8Balls 
		{ category = 'Meals',  name = 'sisig', price = 1500, },
		{ category = 'Meals',  name = 'liempo', price = 1500, },
		{ category = 'Meals',  name = 'barberq', price = 1500},
		{ category = 'Drinks',  name = 'red_horse', price = 1500},
		{ category = 'Drinks',  name = 'sprite', price = 1500},
		{ category = 'Drinks',  name = 'grapejuice', price = 3500},
		{ category = 'Drinks',  name = 'sanmig', price = 3500},

	},

	['ClothingShop'] = MultiCategory(
		{}, -- blacklist table
		{
			['torso'] = true,
		}, -- whitelisted table
		AllClothings -- all vehicles can be found /data/vehicles.lua
	),
}
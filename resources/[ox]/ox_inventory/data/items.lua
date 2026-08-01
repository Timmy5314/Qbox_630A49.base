return {
    ['testburger'] = {
        label = 'Test Burger',
        weight = 220,
        degrade = 60,
        client = {
            image = 'burger_chicken.png',
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            export = 'ox_inventory_examples.testburger'
        },
        server = {
            export = 'ox_inventory_examples.testburger',
            test = 'what an amazingly delicious burger, amirite?'
        },

        buttons = {
            {
                label = 'Lick it',
                action = function(slot)
                    print('You licked the burger')
                end
            },
            {
                label = 'Squeeze it',
                action = function(slot)
                    print('You squeezed the burger :(')
                end
            },
            {
                label = 'What do you call a vegan burger?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('A misteak.')
                end
            },
            {
                label = 'What do frogs like to eat with their hamburgers?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('French flies.')
                end
            },
            {
                label = 'Why were the burger and fries running?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('Because they\'re fast food.')
                end
            }
        },
        consume = 0.3
    },

['clothing_mask'] = {
    label = 'Mask',
    weight = 120,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_jacket'] = {
    label = 'Jacket',
    weight = 900,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_shirt'] = {
    label = 'Shirt',
    weight = 250,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_vest'] = {
    label = 'Vest',
    weight = 1800,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_decals'] = {
    label = 'Decals',
    weight = 50,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_pants'] = {
    label = 'Pants',
    weight = 600,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_shoes'] = {
    label = 'Shoes',
    weight = 800,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_bag'] = {
    label = 'Bag',
    weight = 500,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_chain'] = {
    label = 'Chain',
    weight = 150,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_hat'] = {
    label = 'Hat',
    weight = 200,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_glasses'] = {
    label = 'Glasses',
    weight = 80,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_ears'] = {
    label = 'Earrings',
    weight = 40,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_watch'] = {
    label = 'Watch',
    weight = 120,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_bracelet'] = {
    label = 'Bracelet',
    weight = 90,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},


["stretcher"] = {
    label = "Stretcher",
    weight = 15000,
    stack = false,
    consume = 1,
    server = {
        export = "ND_Ambulance.createStretcher"
    }
},
["defib"] = {
    label = "Monitor/defibrillator",
    weight = 8000,
    stack = false,
    consume = 1,
    client = {
        export = "ND_Ambulance.useDefib",
        add = function(total)
            if total > 0 then
                pcall(function()
                    return exports["ND_Ambulance"]:hasDefib(true)
                end)
            end
        end,
        remove = function(total)
            if total < 1 then
                pcall(function()
                    return exports["ND_Ambulance"]:hasDefib(false)
                end)
            end
        end
    }
},
["medbag"] = {
    label = "Trauma bag",
    weight = 1000,
    stack = false,
    consume = 1,
    server = {
        export = "ND_Ambulance.useBag"
    },
    client = {
        export = "ND_Ambulance.useBag",
        add = function(total)
            if total > 0 then
                pcall(function()
                    return exports["ND_Ambulance"]:bag(true)
                end)
            end
        end,
        remove = function(total)
            if total < 1 then
                pcall(function()
                    return exports["ND_Ambulance"]:bag(false)
                end)
            end
        end
    }
},
["burndressing"] = {
    label = "Burn Dressing",
    weight = 50,
    server = {
        export = "ND_Ambulance.treatment"
    },
    client = {
        anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
        prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
        disable = { move = true, car = true, combat = true },
        usetime = 2500
    }
},
["splint"] = {
    label = "Splint",
    weight = 500,
    server = {
        export = "ND_Ambulance.treatment"
    },
    client = {
        anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
        prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
        disable = { move = true, car = true, combat = true },
        usetime = 2500
    }
},
["gauze"] = {
    label = "Gauze",
    weight = 80,
    server = {
        export = "ND_Ambulance.treatment"
    },
    client = {
        anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
        prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
        disable = { move = true, car = true, combat = true },
        usetime = 2500
    }
},
["tourniquet"] = {
    label = "Tourniquet",
    weight = 85,
    server = {
        export = "ND_Ambulance.treatment"
    },
    client = {
        anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
        prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
        disable = { move = true, car = true, combat = true },
        usetime = 2500
    }
},



    ['bandage'] = {
        label = 'Bandage',
        weight = 115,
    },

-- General store: prepared food
['hotdogsandwich'] = {
    label = 'Hot Dog Sandwich',
    weight = 350,
    client = { status = { hunger = 200000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
},
['donut'] = { label = 'Donut', weight = 150 },

-- General store: drinks
['cola'] = { label = 'Cola', weight = 350 },
['latte'] = { label = 'Latte', weight = 250 },
['martini'] = { label = 'Martini', weight = 250 },
['energy_drink'] = { label = 'Energy Drink', weight = 250 },

-- General store: cooking ingredients
['bread'] = { label = 'Bread', weight = 100 },
['hotdog'] = { label = 'Hotdog', weight = 100 },
['tomatosauce'] = { label = 'Tomato Sauce', weight = 50 },
['burgerpatty'] = { label = 'Burger Patty', weight = 100 },
['tacoshells'] = { label = 'Taco Shells', weight = 50 },
['ground_beef'] = { label = 'Ground Beef', weight = 100 },
['cheese'] = { label = 'Cheese', weight = 50 },
['tomato'] = { label = 'Tomato', weight = 50 },
['pasta'] = { label = 'Pasta', weight = 50 },
['onion'] = { label = 'Onion', weight = 50 },
['mayonaise'] = { label = 'Mayonaise', weight = 50 },
['hotsauce'] = { label = 'Hot Sauce', weight = 50 },
['lettuce'] = { label = 'Lettuce', weight = 50 },
['tacosauce'] = { label = 'Taco Sauce', weight = 50 },
['fish'] = { label = 'Fish', weight = 100 },
['beef'] = { label = 'Beef', weight = 100 },
['chicken'] = { label = 'Chicken', weight = 100 },
['taco'] = { label = 'Taco', weight = 300 },

-- General store: misc / gadgets
['redw'] = { label = 'Red&White Cigarettes', weight = 20 },
['marlboro'] = { label = 'Marlboro Cigarettes', weight = 20 },
['fishingrod'] = { label = 'Fishing Rod', weight = 1500 },
['fishbait'] = { label = 'Fish Bait', weight = 50 },
['garden_shovel'] = { label = 'Garden Shovel', weight = 1000 },
['garden_pitcher'] = { label = 'Garden Pitcher', weight = 500 },
['pickle_seed'] = { label = 'Pickle Seed', weight = 10 },
['potato_seed'] = { label = 'Potato Seed', weight = 10 },
['tomato_seed'] = { label = 'Tomato Seed', weight = 10 },
['wheat_seed'] = { label = 'Wheat Seed', weight = 10 },
['carrot_seed'] = { label = 'Carrot Seed', weight = 10 },
['corn_seed'] = { label = 'Corn Seed', weight = 10 },

-- LiquorStore / Balls8
['sanmig'] = { label = 'San Miguel Beer', weight = 350 },
['frog_grilled'] = { label = 'Grilled Frog', weight = 300 },
['lapulapu_grilled'] = { label = 'Grilled Lapu-Lapu', weight = 300 },
['galungong_grilled'] = { label = 'Grilled Galunggong', weight = 300 },
['sisig'] = { label = 'Sisig', weight = 300 },
['liempo'] = { label = 'Liempo', weight = 300 },
['barberq'] = { label = 'BBQ Skewer', weight = 200 },
['red_horse'] = { label = 'Red Horse Beer', weight = 350 },
['sprite'] = { label = 'Sprite', weight = 350 },

-- PondCafe: ingredienten / tussenstappen
['bread_flour'] = { label = 'Bread Flour', weight = 50 },
['milk'] = { label = 'Milk', weight = 100 },
['coffeeseed'] = { label = 'Coffee Seed', weight = 20 },
['coffeepowder'] = { label = 'Coffee Powder', weight = 20 },
['chocolate'] = { label = 'Chocolate', weight = 50 },
['sugar'] = { label = 'Sugar', weight = 50 },
['mocha'] = { label = 'Mocha', weight = 50 },
['mangofruit'] = { label = 'Mango Fruit', weight = 100 },
['orangefruit'] = { label = 'Orange Fruit', weight = 100 },
['jetskiticket'] = { label = 'Jetski Ticket', weight = 10 },

-- PondCafe: eindproducten
['strawberry_cupcake'] = { label = 'Strawberry Cupcake', weight = 150 },
['double_cupcake'] = { label = 'Double Cupcake', weight = 150 },
['vanilla_cupcake'] = { label = 'Vanilla Cupcake', weight = 150 },
['orangejuice'] = { label = 'Orange Juice', weight = 350 },
['mangojuice'] = { label = 'Mango Juice', weight = 350 },
['cappuccino'] = { label = 'Cappuccino', weight = 250 },
['espresso'] = { label = 'Espresso', weight = 250 },
['milkteacafe'] = { label = 'Milk Tea', weight = 350 },
['milktea2'] = { label = 'Milk Tea (Fresh)', weight = 350 },

-- PoliceArmoury tools
['vision_helmet'] = { label = 'Night Vision Helmet', weight = 2000 },
['thermal_helmet'] = { label = 'Thermal Helmet', weight = 2000 },
['gpstracker'] = { label = 'GPS Tracker', weight = 200 },

-- MechanicSupply: motor-/tuning-onderdelen
['transmition_clutch'] = { label = 'Transmission Clutch', weight = 5000 },
['engine_flywheel'] = { label = 'Engine Flywheel', weight = 4000 },
['engine_oil'] = { label = 'Engine Oil', weight = 1000 },
['engine_sparkplug'] = { label = 'Spark Plug', weight = 200 },
['engine_gasket'] = { label = 'Engine Gasket', weight = 500 },
['engine_airfilter'] = { label = 'Air Filter', weight = 500 },
['engine_fuelinjector'] = { label = 'Fuel Injector', weight = 1000 },
['engine_pistons'] = { label = 'Pistons', weight = 3000 },
['engine_connectingrods'] = { label = 'Connecting Rods', weight = 3000 },
['engine_valves'] = { label = 'Valves', weight = 1000 },
['engine_block'] = { label = 'Engine Block', weight = 8000 },
['engine_crankshaft'] = { label = 'Crankshaft', weight = 5000 },
['engine_camshaft'] = { label = 'Camshaft', weight = 4000 },
['racing_clutch'] = { label = 'Racing Clutch', weight = 5000 },
['racing_flywheel'] = { label = 'Racing Flywheel', weight = 4000 },
['racing_oil'] = { label = 'Racing Oil', weight = 1000 },
['racing_sparkplug'] = { label = 'Racing Spark Plug', weight = 200 },
['racing_gasket'] = { label = 'Racing Gasket', weight = 500 },
['racing_airfilter'] = { label = 'Racing Air Filter', weight = 500 },
['racing_fuelinjector'] = { label = 'Racing Fuel Injector', weight = 1000 },
['racing_pistons'] = { label = 'Racing Pistons', weight = 3000 },
['racing_connectingrods'] = { label = 'Racing Connecting Rods', weight = 3000 },
['racing_valves'] = { label = 'Racing Valves', weight = 1000 },
['racing_block'] = { label = 'Racing Engine Block', weight = 8000 },
['racing_crankshaft'] = { label = 'Racing Crankshaft', weight = 5000 },
['racing_camshaft'] = { label = 'Racing Camshaft', weight = 4000 },
['street_tires'] = { label = 'Street Tires', weight = 8000 },
['sports_tires'] = { label = 'Sports Tires', weight = 8000 },
['racing_tires'] = { label = 'Racing Tires', weight = 8000 },
['drag_tires'] = { label = 'Drag Tires', weight = 8000 },
['drift_tires'] = { label = 'Drift Tires', weight = 8000 },
['fixkit'] = { label = 'Repair Kit (Tuning)', weight = 2000 },
['stancerkit'] = { label = 'Stance Kit', weight = 3000 },
['enginegago'] = { label = 'Engine Swap Kit', weight = 8000 },
['turbostreet'] = { label = 'Street Turbo', weight = 4000 },
['turbosports'] = { label = 'Sports Turbo', weight = 4000 },
['turboracing'] = { label = 'Racing Turbo', weight = 4000 },
['vehiclecontroller'] = { label = 'Vehicle Controller Module', weight = 500 },

-- Wapen-attachments/skins (Ammunation/BlackMarketArms)
['at_flashlight'] = { label = 'Tactical Flashlight', weight = 200 },
['at_suppressor_light'] = { label = 'Suppressor', weight = 200 },
['at_suppressor_heavy'] = { label = 'Tactical Suppressor', weight = 300 },
['at_grip'] = { label = 'Grip Tape', weight = 100 },
['at_barrel'] = { label = 'Extended Barrel', weight = 300 },
['at_compensator'] = { label = 'Compensator', weight = 200 },
['at_clip_drum_rifle'] = { label = 'Drum Magazine (Rifle)', weight = 500 },
['at_clip_drum_shotgun'] = { label = 'Drum Magazine (Shotgun)', weight = 500 },
['at_clip_drum_smg'] = { label = 'Drum Magazine (SMG)', weight = 500 },
['at_clip_extended_mg'] = { label = 'Extended Clip (MG)', weight = 400 },
['at_clip_extended_pistol'] = { label = 'Extended Clip (Pistol)', weight = 200 },
['at_clip_extended_rifle'] = { label = 'Extended Clip (Rifle)', weight = 400 },
['at_clip_extended_shotgun'] = { label = 'Extended Clip (Shotgun)', weight = 400 },
['at_clip_extended_smg'] = { label = 'Extended Clip (SMG)', weight = 300 },
['at_clip_extended_sniper'] = { label = 'Extended Clip (Sniper)', weight = 400 },
['at_muzzle_bell'] = { label = 'Muzzle Brake - Bell', weight = 100 },
['at_muzzle_fat'] = { label = 'Muzzle Brake - Fat', weight = 100 },
['at_muzzle_flat'] = { label = 'Muzzle Brake - Flat', weight = 100 },
['at_muzzle_heavy'] = { label = 'Muzzle Brake - Heavy', weight = 100 },
['at_muzzle_precision'] = { label = 'Muzzle Brake - Precision', weight = 100 },
['at_muzzle_slanted'] = { label = 'Muzzle Brake - Slanted', weight = 100 },
['at_muzzle_split'] = { label = 'Muzzle Brake - Split', weight = 100 },
['at_muzzle_squared'] = { label = 'Muzzle Brake - Squared', weight = 100 },
['at_muzzle_tactical'] = { label = 'Muzzle Brake - Tactical', weight = 100 },
['at_scope_advanced'] = { label = 'Advanced Scope', weight = 300 },
['at_scope_medium'] = { label = 'Medium Scope', weight = 250 },
['at_scope_nv'] = { label = 'Night Vision Scope', weight = 350 },
['at_scope_small'] = { label = 'Small Scope', weight = 150 },
['at_scope_thermal'] = { label = 'Thermal Scope', weight = 350 },
['at_scope_zoom'] = { label = 'Zoom Scope', weight = 250 },
['at_skin_boom'] = { label = 'Weapon Skin - Boom', weight = 10 },
['at_skin_brushstroke'] = { label = 'Weapon Skin - Brushstroke', weight = 10 },
['at_skin_camo'] = { label = 'Weapon Skin - Camo', weight = 10 },
['at_skin_geometric'] = { label = 'Weapon Skin - Geometric', weight = 10 },
['at_skin_gold'] = { label = 'Weapon Skin - Gold', weight = 10 },
['at_skin_leopard'] = { label = 'Weapon Skin - Leopard', weight = 10 },
['at_skin_patriotic'] = { label = 'Weapon Skin - Patriotic', weight = 10 },
['at_skin_perseus'] = { label = 'Weapon Skin - Perseus', weight = 10 },
['at_skin_sessanta'] = { label = 'Weapon Skin - Sessanta', weight = 10 },
['at_skin_skull'] = { label = 'Weapon Skin - Skull', weight = 10 },
['at_skin_woodland'] = { label = 'Weapon Skin - Woodland', weight = 10 },
['at_skin_zebra'] = { label = 'Weapon Skin - Zebra', weight = 10 },


['playerbooth'] = {
    label = 'Market Booth Stall',
    weight = 0,
    client = {
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        usetime = 2500,
        notification = 'Setup your Stall',
        export = 'renzu_shops.playerbooth'
    },
},
['item'] = { label = 'Default Item', weight = 50 },
['hotdogsandwich'] = {
    label = 'Hot Dog Sandwich',
    weight = 350,
    client = { status = { hunger = 200000 }, anim = 'eating', prop = 'burger', usetime = 2500 },
},
['latte'] = { label = 'Latte', weight = 250 },
['martini'] = { label = 'Martini', weight = 250 },
['bread'] = { label = 'Bread', weight = 100 },
['hotdog'] = { label = 'Hotdog', weight = 100 },
['tomatosauce'] = { label = 'Tomato Sauce', weight = 50 },
['burgerpatty'] = { label = 'Burger Patty', weight = 100 },
['tacoshells'] = { label = 'Taco Shells', weight = 50 },
['ground_beef'] = { label = 'Ground Beef', weight = 100 },
['cheese'] = { label = 'Cheese', weight = 50 },
['tomato'] = { label = 'Tomato', weight = 50 },
['pasta'] = { label = 'Pasta', weight = 50 },
['onion'] = { label = 'Onion', weight = 50 },
['mayonaise'] = { label = 'Mayonaise', weight = 50 },
['hotsauce'] = { label = 'Hot Sauce', weight = 50 },
['lettuce'] = { label = 'Lettuce', weight = 50 },
['tacosauce'] = { label = 'Taco Sauce', weight = 50 },
['fish'] = { label = 'Fish', weight = 100 },
['beef'] = { label = 'Beef', weight = 100 },
['chicken'] = { label = 'Chicken', weight = 100 },
['taco'] = { label = 'Taco', weight = 300 },
['cola'] = { label = 'Cola', weight = 350 },

-- Wapens/munitie: check dit eerst in je bestaande items.lua
['ammo-9'] = { label = '9mm Ammo', weight = 10 },
['ammo-rifle'] = { label = 'Rifle Ammo', weight = 10 },
['ammo-rifle2'] = { label = 'Heavy Rifle Ammo', weight = 10 },
['ammo-shotgun'] = { label = 'Shotgun Ammo', weight = 10 },
['ammo-50'] = { label = '.50 Cal Ammo', weight = 10 },
['ammo-45'] = { label = '.45 Ammo', weight = 10 },
['WEAPON_KNIFE'] = { label = 'Knife', weight = 500 },
['WEAPON_BAT'] = { label = 'Baseball Bat', weight = 2000 },
['WEAPON_PISTOL'] = { label = 'Pistol', weight = 1000 },
['WEAPON_APPISTOL'] = { label = 'AP Pistol', weight = 1000 },
['WEAPON_PISTOL50'] = { label = 'Pistol .50', weight = 1200 },
['WEAPON_BZGAS'] = { label = 'BZ Gas Grenade', weight = 500 },
['WEAPON_COMBATPDW'] = { label = 'Combat PDW', weight = 2000 },
['WEAPON_ASSAULTRIFLE'] = { label = 'Assault Rifle', weight = 3000 },
['WEAPON_ASSAULTSMG'] = { label = 'Assault SMG', weight = 2000 },
['WEAPON_FLASHLIGHT'] = { label = 'Flashlight', weight = 300 },
['WEAPON_NIGHTSTICK'] = { label = 'Nightstick', weight = 1000 },
['WEAPON_CARBINERIFLE'] = { label = 'Carbine Rifle', weight = 3000 },
['WEAPON_SPECIALCARBINE'] = { label = 'Special Carbine', weight = 3000 },
['WEAPON_STUNGUN'] = { label = 'Stun Gun', weight = 500 },
['WEAPON_PUMPSHOTGUN'] = { label = 'Pump Shotgun', weight = 3000 },


-- ['handcuffs'] stond hier dubbel: deze definitie werd verderop (rond regel
-- 1180) overschreven door een tweede met dezelfde sleutel. Lua neemt stil de
-- laatste. Deze weggehaald zodat er nog maar een definitie is.
-- Let op: het item dat ND_Police daadwerkelijk gebruikt heet 'cuffs', niet
-- 'handcuffs'. Dat laatste is een legacy-item dat niets aanstuurt.

['lockpick'] = {
    label = 'Lockpick',
    weight = 160,
    -- Had client.export = 'ars_policejob.breakCuffs'. Die resource bestaat niet
    -- op deze server, dus het gebruik van een lockpick riep een dode export
    -- aan. Lockpicks worden door qbx_vehiclekeys zelf afgehandeld (het script
    -- controleert op het item en verbruikt het), niet via een use-export.
},

['medicalbag'] = {
    label = 'Medical Bag',
    weight = 220,
    stack = true,
    description = "A comprehensive medical kit for treating injuries and ailments.",
},

['bandage'] = {
    label = 'Bandage',
    weight = 100,
    stack = true,
    description = "A simple bandage used to cover and protect wounds.",
},

['defibrillator'] = {
    label = 'Defibrillator',
    weight = 100,
    stack = true,
    description = "Used for reviving patients.",
},

['tweezers'] = {
    label = 'Tweezers',
    weight = 100,
    stack = true,
    description = "Precision tweezers for safely removing foreign objects, such as bullets, from wounds.",
},

['burncream'] = {
    label = 'Burn Cream',
    weight = 100,
    stack = true,
    description = "Specialized cream for treating and soothing minor burns and skin irritations.",
},

['suturekit'] = {
    label = 'Suture Kit',
    weight = 100,
    stack = true,
    description = "A kit containing surgical tools and materials for stitching and closing wounds.",
},

['icepack'] = {
    label = 'Ice Pack',
    weight = 200,
    stack = true,
    description = "An ice pack used to reduce swelling and provide relief from pain and inflammation.",
},

    ['burger'] = {
        label = 'Burger',
        weight = 220,
        client = {
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            notification = 'You ate a delicious burger'
        },
    },

    ['sprunk'] = {
        label = 'Sprunk',
        weight = 350,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            notification = 'You quenched your thirst with a sprunk'
        }
    },

    ['parachute'] = {
        label = 'Parachute',
        weight = 8000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 1500
        }
    },

    ['garbage'] = {
        label = 'Garbage',
    },

    ['paperbag'] = {
        label = 'Paper Bag',
        weight = 1,
        stack = false,
        close = false,
        consume = 0
    },

    ['panties'] = {
        label = 'Knickers',
        weight = 10,
        consume = 0,
        client = {
            status = { thirst = -100000, stress = -25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
            usetime = 2500,
        }
    },

    ['lockpick'] = {
        label = 'Lockpick',
        weight = 160,
    },

    ['phone'] = {
        label = 'Phone',
        weight = 190,
        stack = false,
        consume = 0,
        client = {
            add = function(total)
                if total > 0 then
                    pcall(function() return exports.npwd:setPhoneDisabled(false) end)
                end
            end,

            remove = function(total)
                if total < 1 then
                    pcall(function() return exports.npwd:setPhoneDisabled(true) end)
                end
            end
        }
    },

    ['mustard'] = {
        label = 'Mustard',
        weight = 500,
        client = {
            status = { hunger = 25000, thirst = 25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
            usetime = 2500,
            notification = 'You... drank mustard'
        }
    },

    ['water'] = {
        label = 'Water',
        weight = 500,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
            usetime = 2500,
            cancel = true,
            notification = 'You drank some refreshing water'
        }
    },

    ['armour'] = {
        label = 'Bulletproof Vest',
        weight = 3000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 3500
        }
    },

    ['clothing'] = {
        label = 'Clothing',
        consume = 0,
    },

    ['money'] = {
        label = 'Money',
    },

    ['black_money'] = {
        label = 'Dirty Money',
    },

    ['id_card'] = {
        label = 'Identification Card',
    },

    ['driver_license'] = {
        label = 'Drivers License',
    },

    ['weaponlicense'] = {
        label = 'Weapon License',
    },

    ['lawyerpass'] = {
        label = 'Lawyer Pass',
    },

    ['radio'] = {
        label = 'Radio',
        weight = 1000,
        allowArmed = true,
        consume = 0,
        client = {
            event = 'mm_radio:client:use'
        }
    },

    ['jammer'] = {
        label = 'Radio Jammer',
        weight = 10000,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:usejammer'
        }
    },

    ['radiocell'] = {
        label = 'AAA Cells',
        weight = 1000,
        stack = true,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:recharge'
        }
    },

    ['advancedlockpick'] = {
        label = 'Advanced Lockpick',
        weight = 500,
    },

    ['screwdriverset'] = {
        label = 'Screwdriver Set',
        weight = 500,
    },

    ['electronickit'] = {
        label = 'Electronic Kit',
        weight = 500,
    },

    ['cleaningkit'] = {
        label = 'Cleaning Kit',
        weight = 500,
    },

    ['repairkit'] = {
        label = 'Repair Kit',
        weight = 2500,
    },

    ['advancedrepairkit'] = {
        label = 'Advanced Repair Kit',
        weight = 4000,
    },

    ['diamond_ring'] = {
        label = 'Diamond',
        weight = 1500,
    },

    ['rolex'] = {
        label = 'Golden Watch',
        weight = 1500,
    },

    ['goldbar'] = {
        label = 'Gold Bar',
        weight = 1500,
    },

    ['goldchain'] = {
        label = 'Golden Chain',
        weight = 1500,
    },

    ['crack_baggy'] = {
        label = 'Crack Baggy',
        weight = 100,
    },

    ['cokebaggy'] = {
        label = 'Bag of Coke',
        weight = 100,
    },

    ['coke_brick'] = {
        label = 'Coke Brick',
        weight = 2000,
    },

    ['coke_small_brick'] = {
        label = 'Coke Package',
        weight = 1000,
    },

    ['xtcbaggy'] = {
        label = 'Bag of Ecstasy',
        weight = 100,
    },

    ['meth'] = {
        label = 'Methamphetamine',
        weight = 100,
    },

    ['oxy'] = {
        label = 'Oxycodone',
        weight = 100,
    },

    ['weed_ak47'] = {
        label = 'AK47 2g',
        weight = 200,
    },

    ['weed_ak47_seed'] = {
        label = 'AK47 Seed',
        weight = 1,
    },

    ['weed_skunk'] = {
        label = 'Skunk 2g',
        weight = 200,
    },

    ['weed_skunk_seed'] = {
        label = 'Skunk Seed',
        weight = 1,
    },

    ['weed_amnesia'] = {
        label = 'Amnesia 2g',
        weight = 200,
    },

    ['weed_amnesia_seed'] = {
        label = 'Amnesia Seed',
        weight = 1,
    },

    ['weed_og-kush'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_og-kush_seed'] = {
        label = 'OGKush Seed',
        weight = 1,
    },

    ['weed_white-widow'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_white-widow_seed'] = {
        label = 'White Widow Seed',
        weight = 1,
    },

    ['weed_purple-haze'] = {
        label = 'Purple Haze 2g',
        weight = 200,
    },

    ['weed_purple-haze_seed'] = {
        label = 'Purple Haze Seed',
        weight = 1,
    },

    ['weed_brick'] = {
        label = 'Weed Brick',
        weight = 2000,
    },

    ['weed_nutrition'] = {
        label = 'Plant Fertilizer',
        weight = 2000,
    },

    ['joint'] = {
        label = 'Joint',
        weight = 200,
    },

    ['rolling_paper'] = {
        label = 'Rolling Paper',
        weight = 0,
    },

    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
    },

    ['firstaid'] = {
        label = 'First Aid',
        weight = 2500,
    },

    ['ifaks'] = {
        label = 'Individual First Aid Kit',
        weight = 2500,
    },

    ['painkillers'] = {
        label = 'Painkillers',
        weight = 400,
    },

    ['firework1'] = {
        label = '2Brothers',
        weight = 1000,
    },

    ['firework2'] = {
        label = 'Poppelers',
        weight = 1000,
    },

    ['firework3'] = {
        label = 'WipeOut',
        weight = 1000,
    },

    ['firework4'] = {
        label = 'Weeping Willow',
        weight = 1000,
    },

    ['steel'] = {
        label = 'Steel',
        weight = 100,
    },

    ['rubber'] = {
        label = 'Rubber',
        weight = 100,
    },

    ['metalscrap'] = {
        label = 'Metal Scrap',
        weight = 100,
    },

    ['iron'] = {
        label = 'Iron',
        weight = 100,
    },

    ['copper'] = {
        label = 'Copper',
        weight = 100,
    },

    ['aluminum'] = {
        label = 'Aluminium',
        weight = 100,
    },

    ['plastic'] = {
        label = 'Plastic',
        weight = 100,
    },

    ['glass'] = {
        label = 'Glass',
        weight = 100,
    },

    ['gatecrack'] = {
        label = 'Gatecrack',
        weight = 1000,
    },

    ['cryptostick'] = {
        label = 'Crypto Stick',
        weight = 100,
    },

    ['trojan_usb'] = {
        label = 'Trojan USB',
        weight = 100,
    },

    ['toaster'] = {
        label = 'Toaster',
        weight = 5000,
    },

    ['small_tv'] = {
        label = 'Small TV',
        weight = 100,
    },

    ['security_card_01'] = {
        label = 'Security Card A',
        weight = 100,
    },

    ['security_card_02'] = {
        label = 'Security Card B',
        weight = 100,
    },

    ['drill'] = {
        label = 'Drill',
        weight = 5000,
    },

    ['thermite'] = {
        label = 'Thermite',
        weight = 1000,
    },

    ['diving_gear'] = {
        label = 'Diving Gear',
        weight = 30000,
    },

    ['diving_fill'] = {
        label = 'Diving Tube',
        weight = 3000,
    },

    ['antipatharia_coral'] = {
        label = 'Antipatharia',
        weight = 1000,
    },

    ['dendrogyra_coral'] = {
        label = 'Dendrogyra',
        weight = 1000,
    },

    ['jerry_can'] = {
        label = 'Jerrycan',
        weight = 3000,
    },

    ['nitrous'] = {
        label = 'Nitrous',
        weight = 1000,
    },

    ['wine'] = {
        label = 'Wine',
        weight = 500,
    },

    ['grape'] = {
        label = 'Grape',
        weight = 10,
    },

    ['grapejuice'] = {
        label = 'Grape Juice',
        weight = 200,
    },

    ['coffee'] = {
        label = 'Coffee',
        weight = 200,
    },

    ['vodka'] = {
        label = 'Vodka',
        weight = 500,
    },

    ['whiskey'] = {
        label = 'Whiskey',
        weight = 200,
    },

    ['beer'] = {
        label = 'Beer',
        weight = 200,
    },

    ['sandwich'] = {
        label = 'Sandwich',
        weight = 200,
    },

    ['walking_stick'] = {
        label = 'Walking Stick',
        weight = 1000,
    },

    ['lighter'] = {
        label = 'Lighter',
        weight = 200,
    },

    ['binoculars'] = {
        label = 'Binoculars',
        weight = 800,
    },

    ['stickynote'] = {
        label = 'Sticky Note',
        weight = 0,
    },

    ['empty_evidence_bag'] = {
        label = 'Empty Evidence Bag',
        weight = 200,
    },

    ['filled_evidence_bag'] = {
        label = 'Filled Evidence Bag',
        weight = 200,
    },

    ['harness'] = {
        label = 'Harness',
        weight = 200,
    },

    ['handcuffs'] = {
        label = 'Handcuffs',
        weight = 200,
    },
    ['weed_skunk_seed'] = {
        label = 'Skunk Seed',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_seed.png" 
         },
    },
    ['weed_ogkush_seed'] = {
        label = 'OG Kush Seed',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_seed.png" 
         },
    },
    ['weed_amnesia_seed'] = {
        label = 'Amensia Seed',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_seed.png" 
         },
    },
    ['weed_ak47_seed'] = {
        label = 'AK47 Seed',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_seed.png" 
         },
    },
    ['weed_purplehaze_seed'] = {
        label = 'Purple Haze Seed',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_seed.png" 
         },
    },
    ['weed_whitewidow_seed'] = {
        label = 'White Widow Seed',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_seed.png" 
         },
    },
    ['weed_whitewidow'] = {
        label = 'White Widow 2g',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_baggy.png" 
         },
    },
    ['weed_skunk'] = {
        label = 'Skunk 2g',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_baggy.png" 
         },
    },
     ['weed_purplehaze'] = {
        label = 'Purple Haze 2g',
        weight = 200,
        stack = true,
        close = false,
        client = { 
           image = "weed_baggy.png" 
         },
    },
    ['weed_ogkush'] = {
      label = 'OG Kush 2g',
      weight = 200,
      stack = true,
      close = false,
      client = { 
         image = "weed_baggy.png" 
       },
    },
    ['weed_amnesia'] = {
      label = 'Amnesia 2g',
      weight = 200,
      stack = true,
      close = false,
      client = { 
         image = "weed_baggy.png" 
       },
    },
    ['weed_ak47'] = {
      label = 'AK47 2g',
      weight = 200,
      stack = true,
      close = false,
      client = { 
         image = "weed_baggy.png" 
       },
    },
   ['coke'] = {
        label = 'Raw Cocaine',
        weight = 1000,
        stack = true,
        close = false,
        client = { 
           image = "coke.png" 
         },
    },
    ['coca_leaf'] = {
        label = 'Cocaine leaves',
        weight = 1500,
        stack = true,
        close = false,
        client = { 
           image = "coca_leaf.png" 
         },
    },
    ['bakingsoda'] = {
        label = 'Baking Soda',
        weight = 300,
        stack = true,
        close = false,
        client = { 
           image = "bakingsoda.png" 
         },
    },
    ['loosecoke'] = {
        label = 'Loose Coke',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'loosecoke.png' 
         },
    },
    ['loosecokestagetwo'] = {
        label = 'Loose Coke',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'loosecokestagetwo.png' 
         },
    },
    ['loosecokestagethree'] = {
        label = 'Loose Coke',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'loosecokestagethree.png' 
         },
    },
    ['cokebaggy'] = {
        label = 'Bag of Cocaine',
        weight = 0,
        stack = true,
        close = true,
        client = { 
           image = 'cocaine_baggy.png' 
         },
    },
    ['cokebaggystagetwo'] = {
        label = 'Bag Of Cocaine',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'cocaine_baggystagetwo.png' 
         },
    },
    ['cokebaggystagethree'] = {
        label = 'Bag Of Cocaine',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'cocaine_baggystagethree.png' 
         },
    },
    ['cokestagetwo'] = {
        label = 'Raw Cocaine',
        weight = 100,
        stack = true,
        close = false,
        client = { 
           image = "cokestagetwo.png" 
         },
    },
    ['cokestagethree'] = {
        label = 'Raw Cocaine',
        weight = 100,
        stack = true,
        close = false,
        client = { 
           image = "cokestagethree.png" 
         },
    },
    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
        stack = true,
        close = true,
        client = { 
           image = 'weed_baggy_empty.png' 
         },
    },
    ['bakingsoda'] = {
        label = 'Baking Soda',
        weight = 300,
        stack = true,
        close = false,
        client = { 
           image = "bakingsoda.png" 
         },
    },
    ['baggedcracked'] = {
        label = 'Bag Of Crack',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "crackbag1.png" 
         },
    },
    ['baggedcrackedstagetwo'] = {
        label = 'Better Bag Of Crack',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "crackbag2.png" 
         },
    },
    ['baggedcrackedstagethree'] = {
        label = 'Best Bag Of Crack',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "crackbag3.png" 
         },
    },
    ['crackrock'] = {
        label = 'Crack Rock',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "crackrock1.png" 
         },
    },
    ['crackrockstagetwo'] = {
        label = 'Better Crack Rock',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "crackrock2.png" 
         },
    },
    ['crackrockstagethree'] = {
        label = 'Best Crack Rock',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "crackrock3.png" 
         },
    },
    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
        stack = true,
        close = true,
        client = { 
           image = 'weed_baggy_empty.png' 
         },
    },
    ['bakingsoda'] = {
        label = 'Baking Soda',
        weight = 300,
        stack = true,
        close = false,
        client = { 
           image = "bakingsoda.png" 
         },
    },
    ['poppyresin'] = {
        label = 'Poppy resin',
        weight = 2000,
        stack = true,
        close = false,
        client = { 
           image = "poppyresin.png" 
         },
    },
    ['heroin'] = {
        label = 'Heroin Powder',
        weight = 500,
        stack = true,
        close = false,
        client = { 
           image = "heroinpowder.png" 
         },
    },
    ['heroinstagetwo'] = {
        label = 'Heroin Powder',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroinpowderstagetwo.png" 
         },
    },
    ['heroinstagethree'] = {
        label = 'Heroin Powder',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroinpowderstagethree.png" 
         },
    },
    ['heroincut'] = {
        label = 'Cut Heroin',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroincut.png" 
         },
    },
    ['heroincutstagetwo'] = {
        label = 'Cut Heroin',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroincut2.png" 
         },
    },
    ['heroincutstagethree'] = {
        label = 'Cut Heroin',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroincut3.png" 
         },
    },
    ['heroinlabkit'] = {
        label = 'Heroin Lab Kit',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "labkit.png" 
         },
    },
    ['heroinvial'] = {
        label = 'Vial Of Heroin',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroin.png" 
         },
    },
    ['heroinvialstagetwo'] = {
        label = 'Vial of Heroin',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroinstagetwo.png" 
         },
    },
    ['heroinvialstagethree'] = {
        label = 'Vial Of Heroin',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroinstagethree.png" 
         },
    },
    ['heroin_ready'] = {
        label = 'Heroin Syringe',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroin_ready.png" 
         },
    },
    ['heroin_readystagetwo'] = {
        label = 'Heroin Syringe',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroin_readystagetwo.png" 
         },
    },
    ['heroin_readystagethree'] = {
        label = 'Heroin Syringe',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "heroin_readystagethree.png" 
         },
    },
    ['emptyvial'] = {
        label = 'empty vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "emptyvial.png" 
         },
    },
    ['needle'] = {
        label = 'Syringe',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "syringe.png" 
         },
    },
    ['sprunk'] = {
        label = 'Sprunk',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "sprunk.png" 
         },
    },
    ['leancup'] = {
        label = 'Empty Cup',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "leancup.png" 
         },
    },
    ['cupoflean'] = {
        label = 'Lean Cup',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "cupoflean.png" 
         },
    },
    ['cupofdextro'] = {
        label = 'Dextro Cup',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "cupofdextro.png" 
         },
    },
    ['mdlean'] = {
        label = 'Sizzurup',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "Sizzurup.png" 
         },
    },
    ['mdreddextro'] = {
        label = 'Red Dextro',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "reddextro.png" 
         },
    },
    ['lysergic_acid'] = {
        label = 'Lysergic Acid',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lysergic_acid.png' 
         },
    },
    ['diethylamide'] = {
        label = 'Diethylamide',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'diethylamide.png' 
         },
    },
    ['lsd_one_vial'] = {
        label = 'Tier 1 LSD Vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lsd_one_vial.png' 
         },
    },
    ['lsd_vial_two'] = {
        label = 'Tier 2 LSD Vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lsd_vial_two.png' 
         },
    },
    ['lsd_vial_three'] = {
        label = 'Tier 3 LSD Vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lsd_vial_three.png' 
         },
    },
    ['lsd_vial_four'] = {
        label = 'Tier 4 LSD Vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lsd_vial_four.png' 
         },
    },
    ['lsd_vial_five'] = {
        label = 'Tier 5 LSD Vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lsd_vial_five.png' 
         },
    },
    ['lsd_vial_six'] = {
        label = 'Tier 6 LSD Vial',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'lsd_vial_six.png' 
         },
    },
    ['tab_paper'] = {
        label = 'Tab Paper',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'tab_paper.png' 
         },
    },
    ['smileyfacesheet'] = {
        label = 'Smiley Face Sheet',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'smileysheet.png' 
         },
    },
    ['wildcherrysheet'] = {
        label = 'Wild Cherry Sheet',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'wildcherrysheet.png' 
         },
    },
    ['yinyangsheet'] = {
        label = 'Yin and Yang Sheet',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'yinyangsheet.png' 
         },
    },
    ['pineapplesheet'] = {
        label = 'Pineapple Sheet',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'pineapplesheet.png' 
         },
    },
    ['bart_tabs'] = {
        label = 'Cluckin Tabs',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'bart_tabs.png' 
         },
    },
    ['bartsheet'] = {
        label = 'Cluckin Sheet',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'bartsheet.png' 
         },
    },
    ['gratefuldeadsheet'] = {
        label = 'Maze Sheet',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'gratefuldeadsheet.png' 
         },
    },
    ['smiley_tabs'] = {
        label = 'Smiley tabs',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'smiley_tabs.png' 
         },
    },
    ['wildcherry_tabs'] = {
        label = 'Wild Cherry Tabs',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'wildcherry_tabs.png' 
         },
    },
    ['yinyang_tabs'] = {
        label = 'Yin and Yang Tabs',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'yinyang_tabs.png' 
         },
    },
    ['pineapple_tabs'] = {
        label = 'Pineapple Tabs',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'pineapple_tabs.png' 
         },
    },
    ['gratefuldead_tabs'] = {
        label = 'Maze Tabs',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'gratefuldead_tabs.png' 
         },
    },
    ['lsdlabkit'] = {
        label = 'LSD Mixing Table',
        weight = 1000,
        stack = true,
        close = true,
        client = { 
           image = 'labkit.png' 
         },
    },
    ['cactusbulb'] = {
        label = 'Cactus Bulb',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "cactusbulb.png" 
         },
    },
    ['driedmescaline'] = {
        label = 'Mescaline',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "driedmescaline.png" 
         },
    },
    ['ephedrine'] = {
        label = 'Ephedrine',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "ephedrine.png" 
         },
    },
    ['acetone'] = {
        label = 'Acetone',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "acetone.png" 
         },
    },
    ['methbags'] = {
        label = 'Meth',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "methbags.png" 
         },
    },
    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
        stack = true,
        close = true,
        client = { 
           image = 'weed_baggy_empty.png' 
         },
    },
    ['prescription_pad'] = {
        label = 'Prescription Pad',
        weight = 10,
        stack = true,
        close = false,
        client = { 
           image = 'prescriptionpad.png' 
         },
    },
    ['vicodin_prescription'] = {
        label = 'Vicie Prescription',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "adderalprescription.png" 
         },
    },
    ['adderal_prescription'] = {
        label = 'Mdderal Prescription',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "adderalprescription.png" 
         },
    },
    ['morphine_prescription'] = {
        label = 'Morphin Prescription',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "adderalprescription.png" 
         },
    },
    ['xanax_prescription'] = {
        label = 'Zany Prescription',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "adderalprescription.png" 
         },
    },
    ['adderal'] = {
        label = 'Madderal',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'adderal.png' 
         },
    },
    ['vicodin'] = {
        label = 'Vicie',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'vicodin.png' 
         },
    },
    ['morphine'] = {
        label = 'Morphin',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'morphine.png' 
         },
    },
    ['xanax'] = {
        label = 'Zany',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'xanax.png' 
         },
    },
    ['adderalbottle'] = {
        label = 'Madderal Bottle',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'pillbottle.png' 
         },
    },
    ['vicodinbottle'] = {
        label = 'Vicie Bottle',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'pillbottle.png' 
         },
    },
    ['morphinebottle'] = {
        label = 'Morphin Bottle',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'pillbottle.png' 
         },
    },
    ['xanaxbottle'] = {
        label = 'Zany Bottle',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'pillbottle.png' 
         },
    },
    ['shrooms'] = {
        label = 'Shrooms',
        weight = 250,
        stack = true,
        close = false,
        client = { 
           image = "shrooms.png" 
         },
    },
    ['wetcannabis'] = {
        label = 'Wet Cannabis',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "wetcannabis.png" 
         },
    },
    ['drycannabis'] = {
        label = 'Dry Cannabis',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "driedcannabis.png" 
         },
    },
    ['weedgrinder'] = {
        label = 'Weed Grinder',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "weedgrinder.png" 
         },
    },
    ['mdbutter'] = {
        label = 'Butter',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "butter.png" 
         },
    },
    ['cannabutter'] = {
        label = 'Canna-Butter',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "cannabutter.png" 
         },
    },
    ['specialbrownie'] = {
        label = 'Special Brownie',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "specialbrownie.png" 
         },
    },
    ['specialcookie'] = {
        label = 'Special Cookie',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "specialcookie.png" 
         },
    },
    ['specialmuffin'] = {
        label = 'Special Muffin',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "specialmuffin.png" 
         },
    },
    ['specialchocolate'] = {
        label = 'Special Chocolate',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "specialchocolate.png" 
         },
    },
    ['grindedweed'] = {
        label = 'Keef',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "keef.png" 
         },
    },
    ['flour'] = {
        label = 'Flour',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "flour.png" 
         },
    },
    ['chocolate'] = {
        label = 'Chocolate',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "chocolate.png" 
         },
    },
    ['blunt'] = {
        label = 'Blunts',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "blunt.png" 
         },
    },
    ['butane'] = {
        label = 'Butane',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "butane.png" 
         },
    },
    ['butanetorch'] = {
        label = 'Butane Torch',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "butanetorch.png" 
         },
    },
    ['dabrig'] = {
        label = 'Dab Rig',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "dabrig2.png" 
         },
    },
    ['mdwoods'] = {
        label = 'MDWOODS',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "mdwoods.png" 
         },
    },
    ['ciggie'] = {
        label = 'Ciggie',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "ciggie.png" 
         },
    },
    ['tobacco'] = {
        label = 'Tobacco',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "tobacco.png" 
         },
    },
    ['shatter'] = {
        label = 'Shatter',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "shatter.png" 
         },
    },
    ['bluntwrap'] = {
        label = 'Blunt Wrap',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "bluntwrap.png" 
         },
    },
    ['leanbluntwrap'] = {
        label = 'Lean Blunt Wrap',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "leanbluntwrap.png" 
         },
    },
    ['dextrobluntwrap'] = {
        label = 'Dextro Blunt Wrap',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "dextrobluntwrap.png" 
         },
    },
    ['leanblunts'] = {
        label = 'Lean Blunts',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "leanblunts.png" 
         },
    },
    ['dextroblunts'] = {
        label = 'Dextro Blunts',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "dextroblunts.png" 
         },
    },
    ['chewyblunt'] = {
        label = 'Chewy',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "blunt.png" 
         },
    },
    ['cokeburner'] = {
        label = 'Coke Burner',
        weight = 100,
        stack = true,
        close = true,
        client = {
           image = "gta5phone.png"
         },
    },

    -- Ontbrak, terwijl md-drugs server/wholesale.lua over alle burners loopt en
    -- Config.Wholesale.Price er een prijs voor heeft. Zonder dit item was
    -- meth-wholesale stil kapot.
    ['methburner'] = {
        label = 'Meth Burner',
        weight = 100,
        stack = true,
        close = true,
        client = {
           image = "gta5phone.png"
         },
    },
    ['crackburner'] = {
        label = 'Crack Burner',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "gta5phone.png" 
         },
    },
    ['heroinburner'] = {
        label = 'Heroin Burner',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "gta5phone.png" 
         },
    },
    ['lsdburner'] = {
        label = 'LSD Burner',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "gta5phone.png" 
         },
    },
    ['xtcburner'] = {
        label = 'XTC Burner',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "gta5phone.png" 
         },
    },
    ['isosafrole'] = {
        label = 'isosafrole',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'isosafrole.png' 
         },
    },
    ['mdp2p'] = {
        label = 'mdp2p',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = 'mdp2p.png' 
         },
    },
    ['raw_xtc'] = {
        label = 'Raw XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "raw_xtc.png" 
         },
    },
    ['singlepress'] = {
        label = 'Single Pill Press',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "pillpress.png" 
         },
    },
    ['dualpress'] = {
        label = 'Dual Pill Press',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "pillpress.png" 
         },
    },
    ['triplepress'] = {
        label = 'Triple Pill Press',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "pillpress.png" 
         },
    },
    ['quadpress'] = {
        label = 'Quad Pill Press',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "pillpress.png" 
         },
    },
    ['white_xtc'] = {
        label = 'White XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_white.png" 
         },
    },
    ['white_xtc2'] = {
        label = 'White XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_white2.png" 
         },
    },
    ['white_xtc3'] = {
        label = 'White XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_white3.png" 
         },
    },
    ['white_xtc4'] = {
        label = 'White XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_white4.png" 
         },
    },
    ['red_xtc'] = {
        label = 'Red XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_red.png" 
         },
    },
    ['red_xtc2'] = {
        label = 'Red XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_red2.png" 
         },
    },
    ['red_xtc3'] = {
        label = 'Red XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_red3.png" 
         },
    },
    ['red_xtc4'] = {
        label = 'Red XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_red4.png" 
         },
    },
    ['orange_xtc'] = {
        label = 'Orange XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_orange.png" 
         },
    },
    ['orange_xtc2'] = {
        label = 'Orange XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_orange2.png" 
         },
    },
    ['orange_xtc3'] = {
        label = 'Orange XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_orange3.png" 
         },
    },
    ['orange_xtc4'] = {
        label = 'Orange XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_orange4.png" 
         },
    },
    ['blue_xtc'] = {
        label = 'Blue XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_blue.png" 
         },
    },
    ['blue_xtc2'] = {
        label = 'Blue XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_blue2.png" 
         },
    },
    ['blue_xtc3'] = {
        label = 'Blue XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_blue3.png" 
         },
    },
    ['blue_xtc4'] = {
        label = 'Blue XTC',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "unstamped_blue4.png" 
         },
    },
    ['white_playboys'] = {
        label = 'White Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_white.png" 
         },
    },
    ['white_playboys2'] = {
        label = 'White Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_white2.png" 
         },
    },
    ['white_playboys3'] = {
        label = 'White Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_white3.png" 
         },
    },
    ['white_playboys4'] = {
        label = 'White Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_white4.png" 
         },
    },
    ['blue_playboys'] = {
        label = 'blue Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_blue.png" 
         },
    },
    ['blue_playboys2'] = {
        label = 'blue Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_blue2.png" 
         },
    },
    ['blue_playboys3'] = {
        label = 'blue Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_blue3.png" 
         },
    },
    ['blue_playboys4'] = {
        label = 'blue Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_blue4.png" 
         },
    },
    ['red_playboys'] = {
        label = 'red Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_red.png" 
         },
    },
    ['red_playboys2'] = {
        label = 'red Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_red2.png" 
         },
    },
    ['red_playboys3'] = {
        label = 'red Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_red3.png" 
         },
    },
    ['red_playboys4'] = {
        label = 'red Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_red4.png" 
         },
    },
    ['orange_playboys'] = {
        label = 'orange Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_orange.png" 
         },
    },
    ['orange_playboys2'] = {
        label = 'orange Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_orange2.png" 
         },
    },
    ['orange_playboys3'] = {
        label = 'orange Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_orange3.png" 
         },
    },
    ['orange_playboys4'] = {
        label = 'orange Fruit',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "playboy_orange4.png" 
         },
    },
    ['white_aliens'] = {
        label = 'White aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_white.png" 
         },
    },
    ['white_aliens2'] = {
        label = 'White aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_white2.png" 
         },
    },
    ['white_aliens3'] = {
        label = 'White aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_white3.png" 
         },
    },
    ['white_aliens4'] = {
        label = 'White aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_white4.png" 
         },
    },
    ['blue_aliens'] = {
        label = 'blue aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_blue.png" 
         },
    },
    ['blue_aliens2'] = {
        label = 'blue aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_blue2.png" 
         },
    },
    ['blue_aliens3'] = {
        label = 'blue aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_blue3.png" 
         },
    },
    ['blue_aliens4'] = {
        label = 'blue aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_blue4.png" 
         },
    },
    ['red_aliens'] = {
        label = 'red aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_red.png" 
         },
    },
    ['red_aliens2'] = {
        label = 'red aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_red2.png" 
         },
    },
    ['red_aliens3'] = {
        label = 'red aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_red3.png" 
         },
    },
    ['red_aliens4'] = {
        label = 'red aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_red4.png" 
         },
    },
    ['orange_aliens'] = {
        label = 'orange aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_orange.png" 
         },
    },
    ['orange_aliens2'] = {
        label = 'orange aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_orange2.png" 
         },
    },
    ['orange_aliens3'] = {
        label = 'orange aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_orange3.png" 
         },
    },
    ['orange_aliens4'] = {
        label = 'orange aliens',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "alien_orange4.png" 
         },
    },
    ['white_pl'] = {
        label = 'White pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_white.png" 
         },
    },
    ['white_pl2'] = {
        label = 'White pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_white2.png" 
         },
    },
    ['white_pl3'] = {
        label = 'White pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_white3.png" 
         },
    },
    ['white_pl4'] = {
        label = 'White pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_white4.png" 
         },
    },
    ['blue_pl'] = {
        label = 'blue pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_blue.png" 
         },
    },
    ['blue_pl2'] = {
        label = 'blue pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_blue2.png" 
         },
    },
    ['blue_pl3'] = {
        label = 'blue pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_blue3.png" 
         },
    },
    ['blue_pl4'] = {
        label = 'blue pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_blue4.png" 
         },
    },
    ['red_pl'] = {
        label = 'red pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_red.png" 
         },
    },
    ['red_pl2'] = {
        label = 'red pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_red2.png" 
         },
    },
    ['red_pl3'] = {
        label = 'red pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_red3.png" 
         },
    },
    ['red_pl4'] = {
        label = 'red pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_red4.png" 
         },
    },
    ['orange_pl'] = {
        label = 'orange pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_orange.png" 
         },
    },
    ['orange_pl2'] = {
        label = 'orange pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_orange2.png" 
         },
    },
    ['orange_pl3'] = {
        label = 'orange pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_orange3.png" 
         },
    },
    ['orange_pl4'] = {
        label = 'orange pl',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "PL_orange4.png" 
         },
    },
    ['white_trolls'] = {
        label = 'White trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_white.png" 
         },
    },
    ['white_trolls2'] = {
        label = 'White trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_white2.png" 
         },
    },
    ['white_trolls3'] = {
        label = 'White trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_white3.png" 
         },
    },
    ['white_trolls4'] = {
        label = 'White trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_white4.png" 
         },
    },
    ['blue_trolls'] = {
        label = 'blue trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_blue.png" 
         },
    },
    ['blue_trolls2'] = {
        label = 'blue trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_blue2.png" 
         },
    },
    ['blue_trolls3'] = {
        label = 'blue trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_blue3.png" 
         },
    },
    ['blue_trolls4'] = {
        label = 'blue trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_blue4.png" 
         },
    },
    ['red_trolls'] = {
        label = 'red trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_red.png" 
         },
    },
    ['red_trolls2'] = {
        label = 'red trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_red2.png" 
         },
    },
    ['red_trolls3'] = {
        label = 'red trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_red3.png" 
         },
    },
    ['red_trolls4'] = {
        label = 'red trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_red4.png" 
         },
    },
    ['orange_trolls'] = {
        label = 'orange trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_orange.png" 
         },
    },
    ['orange_trolls2'] = {
        label = 'orange trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_orange2.png" 
         },
    },
    ['orange_trolls3'] = {
        label = 'orange trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_orange3.png" 
         },
    },
    ['orange_trolls4'] = {
        label = 'orange trolls',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "troll_orange4.png" 
         },
    },
    ['white_cats'] = {
        label = 'White cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_white.png" 
         },
    },
    ['white_cats2'] = {
        label = 'White cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_white2.png" 
         },
    },
    ['white_cats3'] = {
        label = 'White cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_white3.png" 
         },
    },
    ['white_cats4'] = {
        label = 'White cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_white4.png" 
         },
    },
    ['blue_cats'] = {
        label = 'blue cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_blue.png" 
         },
    },
    ['blue_cats2'] = {
        label = 'blue cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_blue2.png" 
         },
    },
    ['blue_cats3'] = {
        label = 'blue cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_blue3.png" 
         },
    },
    ['blue_cats4'] = {
        label = 'blue cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_blue4.png" 
         },
    },
    ['red_cats'] = {
        label = 'red cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_red.png" 
         },
    },
    ['red_cats2'] = {
        label = 'red cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_red2.png" 
         },
    },
    ['red_cats3'] = {
        label = 'red cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_red3.png" 
         },
    },
    ['red_cats4'] = {
        label = 'red cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_red4.png" 
         },
    },
    ['orange_cats'] = {
        label = 'orange cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_orange.png" 
         },
    },
    ['orange_cats2'] = {
        label = 'orange cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_orange2.png" 
         },
    },
    ['orange_cats3'] = {
        label = 'orange cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_orange3.png" 
         },
    },
    ['orange_cats4'] = {
        label = 'orange cats',
        weight = 100,
        stack = true,
        close = true,
        client = { 
           image = "kitty_orange4.png" 
         },
    },
    ["blue_uninflated_balloon"] = { 
    label = 'Blue Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'blue_uninflated_balloon.png' } 
},
["cracker"] = { 
    label = 'Cracker', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'cracker.png' } 
},
["green_uninflated_balloon"] = { 
    label = 'Green Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'green_uninflated_balloon.png' } 
},
["orange_uninflated_balloon"] = { 
    label = 'Orange Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'orange_uninflated_balloon.png' } 
},
["purple_uninflated_balloon"] = { 
    label = 'Purple Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'purple_uninflated_balloon.png' } 
},
["red_uninflated_balloon"] = { 
    label = 'Red Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'red_uninflated_balloon.png' } 
},
["whipped_cream_cannister"] = { 
    label = 'Whipped Cream Cannister', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'whipped_cream_cannister.png' } 
},
["white_uninflated_balloon"] = { 
    label = 'White Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'white_uninflated_balloon.png' } 
},
["yellow_uninflated_balloon"] = { 
    label = 'Yellow Uninflated Balloon', 
    description = "", 
    weight = 100, 
    stack = true, 
    close = true, 
    client = { image = 'yellow_uninflated_balloon.png' } 
},

   ["shield"] = {
        label = "Police shield",
        weight = 8000,
        stack = false,
        consume = 0,
        client = {
            export = "ND_Police.useShield",
            add = function(total)
                if total > 0 then
                        pcall(function() return exports["ND_Police"]:hasShield(true) end)
                    end
                end,
            remove = function(total)
                if total < 1 then
                    pcall(function() return exports["ND_Police"]:hasShield(false) end)
                end
            end
        }
    },
    ["spikestrip"] = {
        label = "Spikestrip",
        weight = 500,
        client = {
            export = "ND_Police.deploySpikestrip"
        }
    },
    ["cuffs"] = {
        label = "Handcuffs",
        weight = 150,
        client = {
            export = "ND_Police.cuff"
        }
    },
    ["zipties"] = {
        label = "Zipties",
        weight = 10,
        client = {
            export = "ND_Police.ziptie"
        }
    },
    ["tools"] = {
	label = "Tools",
        description = "Can be used to hotwire vehicles.",
	weight = 800,
	consume = 1,
        stack = true,
        close = true,
		client = {
            export = "ND_Core.hotwire",
            event = "ND_Police:unziptie"
		}
	},
    ["handcuffkey"] = {
        label = "Handcuff key",
        weight = 10,
        client = {
            export = "ND_Police.uncuff"
        }
    },
    -- stevo_cayocrates. Nodig om een kratdrop aan te vragen op de laptop.
    ["crate_usb"] = {
        label = "Crate USB",
        description = "Someone's flight schedule. Worth more to the wrong people.",
        weight = 100,
        stack = false
    },

    -- s4t4n667_moneywash
    ["moneywash_key"] = {
        label = "Laundromat Key",
        weight = 20,
        stack = false,
        description = "Opens the back room of a laundromat. Not the kind you ask about."
    },
    ["moneywash_token"] = {
        label = "Laundromat Token",
        weight = 5,
        stack = true,
        description = "One wash cycle."
    },
    ["wet_bills"] = {
        label = "Wet Bills",
        weight = 1,
        stack = true,
        description = "Freshly washed. Needs drying and counting before it spends."
    },

    ["casing"] = {
        label = "Bullet Casing"
    },
    ["projectile"] = {
        label = "Projectile"
    },

    -- Voertuigsleutel (los_vehiclekeys). Uniek per auto: de metadata draagt het
    -- kenteken, dus stack = false. Je krijgt hem bij aankoop, levert hem in bij
    -- het parkeren en krijgt hem terug bij het uithalen. Job- en gangvoertuigen
    -- geven een tijdelijke variant met een `expires` in de metadata.
    --
    -- Geen eigen afbeelding: key.png staat er al.
    ["vehiclekey"] = {
        label = "Vehicle Key",
        weight = 30,
        stack = false,
        close = true,
        description = "Hoort bij een bepaald voertuig.",
        client = { image = "key.png" }
    },

    -- Tas/opbergitem (renzu_bag). Uniek per stuk: de metadata draagt het
    -- serienummer, aantal slots, model en label. Gebruik het item om de tas op
    -- de grond te plaatsen (wordt een aparte stash) of te dragen. stack = false
    -- omdat elke tas een eigen inhoud/serienummer heeft.
    ['bag'] = {
        label = 'Bag',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Een draagbare opbergtas.',
        client = {
            image = 'bag.png',
            export = 'renzu_bag.useItem',
        },
    },

    -- Nitro-shots (renzu_nitro). Gebruik in een voertuig om nitro te installeren
    -- (verbruikt). Zwaardere shot = meer boost. Bijvullen met een nitro_bottle.
    ['nitro50shot'] = {
        label = 'Nitro 50 Shot',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Nitro-installatiekit, 50 shot.',
        client = { image = 'nitro50shot.png' },
    },
    ['nitro100shot'] = {
        label = 'Nitro 100 Shot',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Nitro-installatiekit, 100 shot.',
        client = { image = 'nitro100shot.png' },
    },
    ['nitro200shot'] = {
        label = 'Nitro 200 Shot',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Nitro-installatiekit, 200 shot.',
        client = { image = 'nitro200shot.png' },
    },
    -- Nitro-flessen (renzu_nitro): bepalen de voorraad/hervulcapaciteit.
    ['nitro_bottle'] = {
        label = 'Nitro Bottle 10LB',
        weight = 500,
        stack = true,
        close = true,
        description = 'Nitro-fles, 10 lb.',
        client = { image = 'nitro_bottle.png' },
    },
    ['nitro_bottle2'] = {
        label = 'Nitro Bottle 20LB',
        weight = 900,
        stack = true,
        close = true,
        description = 'Nitro-fles, 20 lb.',
        client = { image = 'nitro_bottle2.png' },
    },
    ['nitro_bottle3'] = {
        label = 'Nitro Bottle 30LB',
        weight = 1300,
        stack = true,
        close = true,
        description = 'Nitro-fles, 30 lb.',
        client = { image = 'nitro_bottle3.png' },
    },

    -- Turbo-kits (renzu_turbo). Gebruik het item in een voertuig om de turbo te
    -- installeren; wordt daarbij verbruikt. Zwaardere kit = meer vermogen.
    ['turbostreet'] = {
        label = 'Turbo Street',
        weight = 1050,
        stack = true,
        close = true,
        description = 'Instap-turbo. Lichte vermogenswinst.',
        client = { image = 'turbostreet.png' },
    },
    ['turbosports'] = {
        label = 'Turbo Sports',
        weight = 1100,
        stack = true,
        close = true,
        description = 'Sport-turbo. Merkbare vermogenswinst.',
        client = { image = 'turbosports.png' },
    },
    ['turboracing'] = {
        label = 'Turbo Racing',
        weight = 1120,
        stack = true,
        close = true,
        description = 'Race-turbo. Flinke vermogenswinst.',
        client = { image = 'turboracing.png' },
    },
    ['turboultimate'] = {
        label = 'Turbo Ultimate',
        weight = 1140,
        stack = true,
        close = true,
        description = 'Topturbo. Maximale vermogenswinst.',
        client = { image = 'turboultimate.png' },
    },

    -- Stancekit (renzu_stancer). Gebruik het item in een voertuig om de
    -- stance/vering aanpasbaar te maken; wordt daarbij verbruikt. Daarna open
    -- je de stance-editor met het commando /stance.
    ['stancerkit'] = {
        label = 'Stance Kit',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Maakt de vering/stance van een voertuig aanpasbaar.',
    },

    -- Deelbare motelsleutel (renzu_motels). De metadata draagt het motel, het
    -- deurnummer (serial) en de eigenaar; daarom stack = false (twee sleutels
    -- voor verschillende kamers zijn niet inwisselbaar). Wordt gegenereerd via
    -- de callback renzu_motels:motelkey en gelezen met ox_inventory:Search.
    -- Geen eigen afbeelding: key.png staat er al.
    ['keys'] = {
        label = 'Motel Key',
        weight = 30,
        stack = false,
        close = true,
        description = 'Geeft toegang tot een gehuurde motelkamer.',
        client = { image = 'key.png' }
    },

    -- ============================================================
    --  murderface-pets
    --  Elk huisdier is een uniek item met metadata (naam, level, XP,
    --  vachtkleur). Vandaar stack = false: twee honden zijn niet
    --  inwisselbaar.
    --
    --  consume = 0 op alles. De handlers in murderface-pets geven
    --  `false` terug en verwijderen het item zelf pas als de handeling
    --  ook echt is afgerond. Zonder consume = 0 vult ox_inventory die
    --  standaard op 1 en wordt het item twee keer weggehaald.
    --
    --  De riem-items (murderface_leash*) staan hier BEWUST niet: hun
    --  props zitten in een streaming-resource die deze server niet heeft.
    --  Config.leash.enabled staat daarom op false.
    -- ============================================================

    -- Honden
    ["murderface_husky"] = {
        label = "Husky",
        weight = 1000,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_husky" }
    },
    ["murderface_shepherd"] = {
        label = "Police K9",
        weight = 1000,
        stack = false,
        consume = 0,
        description = "Politiehond. Alleen bruikbaar door de politie.",
        server = { export = "murderface-pets.murderface_shepherd" }
    },
    ["murderface_rottweiler"] = {
        label = "Rottweiler",
        weight = 1000,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_rottweiler" }
    },
    ["murderface_retriever"] = {
        label = "Golden Retriever",
        weight = 1000,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_retriever" }
    },
    ["murderface_chop"] = {
        label = "Chop",
        weight = 1000,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_chop" }
    },
    ["murderface_westy"] = {
        label = "Westie",
        weight = 600,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_westy" }
    },
    ["murderface_pug"] = {
        label = "Pug",
        weight = 600,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_pug" }
    },
    ["murderface_poodle"] = {
        label = "Poodle",
        weight = 600,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_poodle" }
    },

    -- Katten en wild
    ["murderface_cat"] = {
        label = "House Cat",
        weight = 600,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_cat" }
    },
    ["murderface_panther"] = {
        label = "Black Panther",
        weight = 1500,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_panther" }
    },
    ["murderface_mtlion"] = {
        label = "Mountain Lion",
        weight = 1500,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_mtlion" }
    },
    ["murderface_coyote"] = {
        label = "Coyote",
        weight = 1000,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_coyote" }
    },

    -- Klein spul
    ["murderface_hen"] = {
        label = "Chicken",
        weight = 400,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_hen" }
    },
    ["murderface_rabbit"] = {
        label = "Rabbit",
        weight = 400,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_rabbit" }
    },
    ["murderface_chimp"] = {
        label = "Chimpanzee",
        weight = 1200,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_chimp" }
    },
    ["murderface_rhesus"] = {
        label = "Rhesus Monkey",
        weight = 800,
        stack = false,
        consume = 0,
        server = { export = "murderface-pets.murderface_rhesus" }
    },

    -- Benodigdheden
    ["murderface_food"] = {
        label = "Pet Food",
        weight = 200,
        stack = true,
        consume = 0,
        description = "Voer voor je huisdier. Werkt ook om een zwerfdier vertrouwen te geven.",
        server = { export = "murderface-pets.murderface_food" }
    },
    ["murderface_collar"] = {
        label = "Pet Collar",
        weight = 100,
        stack = true,
        consume = 0,
        description = "Zet een huisdier op naam van iemand anders.",
        server = { export = "murderface-pets.murderface_collar" }
    },
    ["murderface_nametag"] = {
        label = "Name Tag",
        weight = 50,
        stack = true,
        consume = 0,
        description = "Geef je huisdier een naam.",
        server = { export = "murderface-pets.murderface_nametag" }
    },
    ["murderface_firstaid"] = {
        label = "Pet First Aid Kit",
        weight = 500,
        stack = true,
        consume = 0,
        description = "Verzorgt een gewond huisdier.",
        server = { export = "murderface-pets.murderface_firstaid" }
    },
    ["murderface_groomingkit"] = {
        label = "Grooming Kit",
        weight = 800,
        stack = true,
        consume = 0,
        server = { export = "murderface-pets.murderface_groomingkit" }
    },
    ["murderface_waterbottle"] = {
        label = "Portable Water Bottle",
        weight = 500,
        stack = false,
        consume = 0,
        description = "Bij te vullen met water.",
        server = { export = "murderface-pets.murderface_waterbottle" }
    },
    ["murderface_doghouse"] = {
        label = "Dog House",
        weight = 5000,
        stack = true,
        consume = 0,
        description = "Neerzetten geeft huisdieren in de buurt rust. Nodig om te fokken.",
        server = { export = "murderface-pets.murderface_doghouse" }
    },

}
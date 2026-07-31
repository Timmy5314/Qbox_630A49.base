---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job definitions

    IMPORTANT: the job NAME used as the table key must exist in
    qbx_core/shared/jobs.lua, otherwise qbx_core cannot assign it.
    Grades here are qbx grade LEVELS (the numeric key in the qbx grades table).

    Every feature block supports:
        grade   = <number>   minimum grade level required
        coord   = vector3/4  where the point sits
        label   = <string>   text shown in ox_target / textUI
        icon    = <string>   fontawesome name for ox_target
        ped     = false | { model=, scenario=, heading= }
                             false  -> no ped, a zone is used instead
                             table  -> overrides Config.DefaultPed
        webhook = <string>   optional per-feature discord webhook

    Access flags per grade live in ['grades'] and control the boss menu:
        fire, hire, withdraw, deposit, gradechange, givebonus, salarychange
]]

Config.Jobs = {

    -- ─────────────────────────────────────────────────────────────────────────
    ['police'] = {
        label = 'Los Santos Police Department',
        maxSalary = 1000000,

        ['bossmenu'] = {
            grade = 9,
            coord = vec4(448.00, -973.38, 30.68, 88.0),
            label = 'Boss Action',
            icon  = 'briefcase',
            ped   = { model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        },

        ['stashes'] = {
            ['Boss'] = {
                grade  = 9,
                coord  = vec3(452.18, -973.28, 30.68),
                label  = 'Boss Storage',
                icon   = 'box-archive',
                slots  = 100,
                weight = 500000,
                ped    = false,
            },
            ['Personal'] = {
                grade    = 0,
                coord    = vec3(456.55, -988.57, 30.68),
                label    = 'Personal Locker',
                icon     = 'lock',
                slots    = 30,
                weight   = 100000,
                personal = true, -- one stash per employee
                ped      = false,
            },
            ['Armory'] = {
                grade  = 0,
                coord  = vec3(461.86, -983.11, 30.68),
                label  = 'Police Armory',
                icon   = 'gun',
                slots  = 50,
                weight = 250000,
                ped    = false,
            },
        },

        -- Stashes anyone can open, regardless of job. Handy for trays/counters.
        ['publicStashes'] = {},

        ['armory'] = {
            grade = 0,
            coord = vec4(458.64, -979.16, 30.68, 268.0),
            label = 'Weapon Armory',
            icon  = 'gun',
            ped   = { model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_GUARD_STAND' },
        },

        ['wardrobe'] = {
            grade = 0,
            coord = vec3(449.90, -993.20, 30.68),
            label = 'Wardrobe',
            icon  = 'shirt',
            ped   = false,
        },

        ['shops'] = {
            [1] = {
                grade  = 0,
                public = false, -- false = paid from the job treasury, employees only
                label  = 'Supply',
                icon   = 'basket-shopping',
                coord  = vec4(452.36, -980.29, 30.68, 178.0),
                ped    = { model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
                items  = {
                    { name = 'WEAPON_ADVANCEDRIFLE',  label = 'Advanced Rifle', price = 0 },
                    { name = 'WEAPON_PISTOL',         label = 'Pistol',         price = 0 },
                    { name = 'WEAPON_SMG',            label = 'SMG',            price = 0 },
                    { name = 'WEAPON_SMOKEGRENADE',   label = 'Smoke Grenade',  price = 0 },
                    { name = 'WEAPON_STUNGUN',        label = 'Stun Gun',       price = 0 },
                    { name = 'WEAPON_NIGHTSTICK',     label = 'Night Stick',    price = 0 },
                    { name = 'bread',                 label = 'Bread',          price = 0 },
                    { name = 'water',                 label = 'Water',          price = 0 },
                    { name = 'ammo-rifle',            label = '5.56mm Ammo',    price = 0 },
                    { name = 'ammo-9',                label = '9mm Ammo',       price = 0 },
                    { name = 'armour',                label = 'Body Armour',    price = 0 },
                },
            },
        },

        ['crafting'] = {
            grade = 0,
            coord = vec4(439.15, -993.43, 30.68, 88.0),
            label = 'Police Workbench',
            icon  = 'screwdriver-wrench',
            ped   = false,
            recipes = {
                ['bandage'] = {
                    label = 'Bandage',
                    seconds = 10,
                    amount = 1,
                    requirements = {
                        { name = 'cloth', amount = 2 },
                    },
                },
                ['WEAPON_PISTOL'] = {
                    label = 'Pistol',
                    seconds = 30,
                    amount = 1,
                    requirements = {
                        { name = 'steel',    amount = 5 },
                        { name = 'rubber',   amount = 2 },
                        { name = 'plastic',  amount = 2 },
                    },
                },
            },
        },

        ['vehicleshop'] = {
            grade = 4, -- who may spend job money on new vehicles
            label = 'Fleet Purchase',
            icon  = 'cart-shopping',
            coord = vec4(444.59, -1014.30, 28.58, 0.0),
            ped   = { model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
            vehicles = {
                { model = 'police',  label = 'Police Cruiser',   price = 10000, grade = 0 },
                { model = 'police2', label = 'Police Buffalo',   price = 5000,  grade = 0 },
                { model = 'police3', label = 'Police Interceptor', price = 5000, grade = 0 },
            },
        },

        ['garage'] = {
            grade = 0,
            label = 'Job Garage',
            icon  = 'warehouse',
            coord = vec4(438.91, -1013.64, 28.63, 0.0),
            spawn = vec4(435.22, -1027.35, 28.45, 5.98),
            ped   = { model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
            --- Vehicle types allowed in this garage (car / air / sea).
            vehicleType = 'car',
        },

        ['duty'] = {
            grade = 0,
            coord = vec4(441.31, -981.95, 30.68, 88.0),
            label = 'Duty Clock',
            icon  = 'clock',
            ped   = false,
        },

        ['interaction'] = {
            ['Citizen Interaction'] = {
                -- 3 en 4 (Handcuff/Uncuff) weggehaald: dat gaat via de items
                -- cuffs en handcuffkey, niet via een menuknop.
                { index = 1,  grade = 0, type = 'citizen_interaction' },
                { index = 2,  grade = 0, type = 'citizen_interaction' },
                { index = 5,  grade = 0, type = 'citizen_interaction' },
                { index = 6,  grade = 0, type = 'citizen_interaction' },
                { index = 7,  grade = 0, type = 'citizen_interaction' },
                { index = 8,  grade = 0, type = 'citizen_interaction' },
                { index = 9,  grade = 0, type = 'citizen_interaction' },
                { index = 10, grade = 0, type = 'citizen_interaction' },
                { index = 11, grade = 0, type = 'citizen_interaction' },
                { index = 12, grade = 0, type = 'citizen_interaction' },
            },
            ['Vehicle Interaction'] = {
                { index = 1, grade = 0, type = 'vehicle_interaction' },
                { index = 2, grade = 0, type = 'vehicle_interaction' },
                { index = 3, grade = 0, type = 'vehicle_interaction' },
                { index = 4, grade = 0, type = 'vehicle_interaction' },
            },
        },

        ['grades'] = {
            [0] = {},
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
            [6] = { gradechange = true },
            [7] = { gradechange = true, withdraw = true, deposit = true },
            [8] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true },
            [9] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true, salarychange = true },
        },
    },

    -- ─────────────────────────────────────────────────────────────────────────
    ['mechanic'] = {
        label = 'Bennys Motorworks',
        maxSalary = 1000000,

        ['bossmenu'] = {
            grade = 7,
            coord = vec4(-605.43, -918.86, 23.88, 90.0),
            label = 'Boss Action',
            icon  = 'briefcase',
            ped   = { model = 's_m_y_xmech_02', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        },

        ['stashes'] = {
            ['Boss'] = {
                grade = 7, coord = vec3(-606.87, -921.40, 23.88),
                label = 'Boss Storage', icon = 'box-archive', slots = 100, weight = 500000, ped = false,
            },
            ['Personal'] = {
                grade = 0, coord = vec3(-605.22, -922.26, 23.88),
                label = 'Personal Locker', icon = 'lock', slots = 30, weight = 100000, personal = true, ped = false,
            },
            ['Workshop'] = {
                grade = 0, coord = vec3(-583.92, -929.00, 23.88),
                label = 'Workshop Storage', icon = 'toolbox', slots = 50, weight = 250000, ped = false,
            },
        },

        ['publicStashes'] = {},

        ['wardrobe'] = {
            grade = 0, coord = vec3(-599.78, -914.76, 23.88),
            label = 'Wardrobe', icon = 'shirt', ped = false,
        },

        ['shops'] = {
            [1] = {
                grade = 0, public = false,
                label = 'Supply Shop', icon = 'basket-shopping',
                coord = vec4(-593.89, -935.77, 28.14, 0.0),
                ped = { model = 's_m_y_xmech_02', scenario = 'WORLD_HUMAN_CLIPBOARD' },
                items = {
                    { name = 'repairkit',  label = 'Repair Kit',  price = 2500 },
                    { name = 'advancedrepairkit', label = 'Advanced Repair Kit', price = 25000 },
                },
            },
            [2] = {
                grade = 0, public = true, -- anyone can buy, income goes to the job
                label = 'Parts Shop', icon = 'basket-shopping',
                coord = vec4(-591.22, -930.75, 23.88, 0.0),
                ped = { model = 's_m_y_xmech_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
                items = {
                    { name = 'repairkit',  label = 'Repair Kit',  price = 5000 },
                    { name = 'advancedrepairkit', label = 'Advanced Repair Kit', price = 50000 },
                },
            },
        },

        ['crafting'] = {
            grade = 0,
            coord = vec4(-584.04, -938.95, 23.88, 90.0),
            label = 'Tuning Bench', icon = 'screwdriver-wrench', ped = false,
            recipes = {
                ['repairkit'] = {
                    label = 'Repair Kit', seconds = 20, amount = 1,
                    requirements = {
                        { name = 'steel',   amount = 5 },
                        { name = 'plastic', amount = 3 },
                    },
                },
            },
        },

        ['vehicleshop'] = {
            grade = 5,
            label = 'Fleet Purchase', icon = 'cart-shopping',
            coord = vec4(-205.29, -1326.24, 30.89, 0.0),
            ped = { model = 's_m_y_xmech_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
            vehicles = {
                { model = 'flatbed', label = 'Flatbed Tow Truck', price = 45000, grade = 0 },
                { model = 'towtruck', label = 'Tow Truck',        price = 25000, grade = 0 },
                { model = 'sadler',  label = 'Sadler',            price = 15000, grade = 0 },
            },
        },

        ['garage'] = {
            grade = 0,
            label = 'Job Garage', icon = 'warehouse',
            coord = vec4(-210.30, -1309.28, 31.29, 0.0),
            spawn = vec4(-220.96, -1291.41, 30.62, 219.47),
            ped   = { model = 's_m_y_xmech_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
            vehicleType = 'car',
        },

        ['duty'] = {
            grade = 0, coord = vec4(-588.63, -931.27, 23.88, 90.0),
            label = 'Duty Clock', icon = 'clock', ped = false,
        },

        ['interaction'] = {
            ['Vehicle Interaction'] = {
                { index = 5, grade = 0, type = 'vehicle_interaction' },
                { index = 6, grade = 0, type = 'vehicle_interaction' },
                { index = 7, grade = 0, type = 'vehicle_interaction' },
                { index = 8, grade = 0, type = 'vehicle_interaction' },
                { index = 9, grade = 0, type = 'vehicle_interaction' },
            },
        },

        ['grades'] = {
            [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
            [6] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true },
            [7] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true, salarychange = true },
        },
    },

    -- ─────────────────────────────────────────────────────────────────────────
    ['ambulance'] = {
        label = 'Emergency Medical Services',
        maxSalary = 1000000,

        ['bossmenu'] = {
            grade = 4,
            coord = vec4(307.3697, -600.0419, 29.5014, 154.7936),
            label = 'Boss Action', icon = 'briefcase',
            ped = { model = 's_m_m_doctor_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        },

        ['stashes'] = {
            ['Boss'] = {
                grade = 10, coord = vec3(-503.55, -297.99, 69.52),
                label = 'Boss Storage', icon = 'box-archive', slots = 100, weight = 500000, ped = false,
            },
            ['Personal'] = {
                grade = 0, coord = vec3(309.64, -597.01, 42.26),
                label = 'Personal Locker', icon = 'lock', slots = 30, weight = 100000, personal = true, ped = false,
            },
            ['Supplies'] = {
                grade = 0, coord = vec3(-445.16, -309.66, 35.34),
                label = 'Medical Supplies', icon = 'suitcase-medical', slots = 50, weight = 250000, ped = false,
            },
        },

        ['publicStashes'] = {},

        ['wardrobe'] = {
            grade = 0, coord = vec3(309.64, -597.01, 42.26),
            label = 'Wardrobe', icon = 'shirt', ped = false,
        },

        ['shops'] = {
            [1] = {
                grade = 0, public = false,
                label = 'Supply Shop', icon = 'basket-shopping',
                coord = vec4(-456.96, -309.54, 34.91, 0.0),
                ped = { model = 's_m_m_doctor_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
                items = {
                    { name = 'medikit',  label = 'Medkit',   price = 2500 },
                    { name = 'bandage',  label = 'Bandage',  price = 1000 },
                    { name = 'painkillers', label = 'Painkillers', price = 1000 },
                },
            },
            [2] = {
                grade = 0, public = true,
                label = 'Pharmacy', icon = 'prescription-bottle-medical',
                coord = vec4(-492.23, -340.81, 42.32, 0.0),
                ped = { model = 's_f_y_scrubs_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
                items = {
                    { name = 'bandage',     label = 'Bandage',     price = 2000 },
                    { name = 'painkillers', label = 'Painkillers', price = 2000 },
                },
            },
        },

        ['garage'] = {
            grade = 0,
            label = 'Job Garage', icon = 'warehouse',
            coord = vec4(-449.85, -344.30, 34.35, 88.0),
            spawn = vec4(-458.00, -337.00, 34.20, 260.0),
            ped   = { model = 's_m_m_doctor_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
            vehicleType = 'car',
        },

        ['vehicleshop'] = {
            grade = 8,
            label = 'Fleet Purchase', icon = 'cart-shopping',
            coord = vec4(-452.00, -348.00, 34.35, 88.0),
            ped   = false,
            vehicles = {
                { model = 'ambulance', label = 'Ambulance', price = 30000, grade = 0 },
            },
        },

        ['duty'] = {
            grade = 0, coord = vec4(309.64, -597.01, 42.26, 341.26),
            label = 'Duty Clock', icon = 'clock', ped = false,
        },

        ['interaction'] = {
            ['Citizen Interaction'] = {
                -- 14 t/m 17 (Revive, Drag Patient, Treat) weggehaald: dat gaat
                -- via de items defibrillator, bag, stretcher en de
                -- behandelitems, niet via een menuknop.
                { index = 13, grade = 0, type = 'citizen_interaction' },
                { index = 18, grade = 0, type = 'citizen_interaction' },
            },
            ['Vehicle Interaction'] = {
                { index = 10, grade = 0, type = 'vehicle_interaction' },
                { index = 11, grade = 0, type = 'vehicle_interaction' },
            },
        },

        ['grades'] = {
            [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
            [6] = {}, [7] = {}, [8] = {}, [9] = {},
            [10] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true },
            [11] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true },
            [12] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true, salarychange = true },
        },
    },

    -- ─────────────────────────────────────────────────────────────────────────
    -- Add this job to qbx_core/shared/jobs.lua before using it.
    ['burgershot'] = {
        label = 'Burger Shot',
        maxSalary = 1000000,

        ['bossmenu'] = {
            grade = 4,
            coord = vec4(-1192.21, -902.21, 13.99, 30.0),
            label = 'Boss Action', icon = 'briefcase',
            ped = { model = 'a_m_m_business_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        },

        ['stashes'] = {
            ['Boss'] = {
                grade = 4, coord = vec3(-1191.17, -903.51, 13.99),
                label = 'Boss Storage', icon = 'box-archive', slots = 100, weight = 500000, ped = false,
            },
            ['Food Stock'] = {
                grade = 0, coord = vec3(-1203.00, -895.44, 13.99),
                label = 'Food Stock', icon = 'burger', slots = 50, weight = 250000, ped = false,
            },
            ['Cups'] = {
                grade = 0, coord = vec3(-1190.10, -904.84, 13.99),
                label = 'Cups', icon = 'cup-straw', slots = 30, weight = 100000, ped = false,
            },
            ['Ready Meals'] = {
                grade = 0, coord = vec3(-1197.04, -893.88, 13.99),
                label = 'Ready Meals', icon = 'bell-concierge', slots = 30, weight = 100000, ped = false,
            },
        },

        ['publicStashes'] = {
            ['Tray 1'] = {
                coord = vec3(-1195.24, -892.13, 14.41),
                label = 'Tray 1', icon = 'bell-concierge', slots = 10, weight = 50000, ped = false,
            },
            ['Tray 2'] = {
                coord = vec3(-1193.89, -894.16, 14.43),
                label = 'Tray 2', icon = 'bell-concierge', slots = 10, weight = 50000, ped = false,
            },
        },

        ['wardrobe'] = {
            grade = 0, coord = vec3(-1201.04, -890.86, 13.99),
            label = 'Wardrobe', icon = 'shirt', ped = false,
        },

        ['crafting'] = {
            grade = 0,
            coord = vec4(-1199.41, -898.62, 13.99, 318.0),
            label = 'Kitchen', icon = 'utensils', ped = false,
            recipes = {
                ['burger'] = {
                    label = 'Burger', seconds = 8, amount = 1,
                    requirements = {
                        { name = 'bread',  amount = 1 },
                        { name = 'meat',   amount = 1 },
                    },
                },
            },
        },

        ['duty'] = {
            grade = 0, coord = vec4(-1178.30, -891.86, 13.79, 30.0),
            label = 'Duty Clock', icon = 'clock', ped = false,
        },

        ['grades'] = {
            [0] = {}, [1] = {}, [2] = {},
            [3] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true },
            [4] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true, salarychange = true },
        },
    },

    -- ─────────────────────────────────────────────────────────────────────────
    ['coffeebean'] = {
        label = 'Bean Machine',
        maxSalary = 1000000,

        ['bossmenu'] = {
            grade = 4,
            coord = vec4(-635.92, 234.18, 81.88, 0.0),
            label = 'Boss Action', icon = 'briefcase',
            ped = { model = 'a_f_y_business_02', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        },

        ['stashes'] = {
            ['Stocks'] = {
                grade = 0, coord = vec3(-631.93, 228.02, 81.88),
                label = 'Stocks', icon = 'box-archive', slots = 50, weight = 250000, ped = false,
            },
            ['Storage'] = {
                grade = 0, coord = vec3(-634.28, 225.67, 81.88),
                label = 'Storage', icon = 'box-archive', slots = 50, weight = 250000, ped = false,
            },
        },

        ['publicStashes'] = {
            ['Coffee Tray'] = {
                coord = vec3(-634.66, 235.37, 82.54),
                label = 'Coffee Tray', icon = 'mug-saucer', slots = 10, weight = 50000, ped = false,
            },
        },

        ['wardrobe'] = {
            grade = 0, coord = vec3(-634.89, 227.97, 81.88),
            label = 'Wardrobe', icon = 'shirt', ped = false,
        },

        ['duty'] = {
            grade = 0, coord = vec4(-618.49, 239.50, 81.88, 0.0),
            label = 'Duty Clock', icon = 'clock', ped = false,
        },

        ['grades'] = {
            [0] = {}, [1] = {}, [2] = {},
            [3] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true },
            [4] = { gradechange = true, withdraw = true, deposit = true, fire = true, hire = true, givebonus = true, salarychange = true },
        },
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Interaction menu entries (used by the /interaction command)
--
-- LET OP - gecontroleerd juli 2026: alle achttien entries hieronder vuurden
-- events af waar NIETS in de hele server naar luisterde. Het complete menu was
-- dood. Er was dus ook geen conflict met ND_Police of ND_Ambulance, er was
-- domweg geen implementatie.
--
-- BOEIEN, ZIPTIES EN MEDISCHE HANDELINGEN HOREN NIET IN DIT MENU.
-- Ze zijn al volledig item-based via ox_inventory en dat blijft zo:
--
--   cuffs        -> ND_Police.cuff          zipties -> ND_Police.ziptie
--   handcuffkey  -> ND_Police.uncuff        tools   -> ND_Police:unziptie
--   defibrillator/bag/behandelitems -> ND_Ambulance.useDefib/useBag/treatment
--   stretcher    -> ND_Ambulance.createStretcher
--
-- Een menuknop ernaast maakt het item betekenisloos: je hoeft dan niets meer
-- bij je te hebben. Op een RP-server is het bezit van het middel juist de
-- beperking. Daarom staan ze hier bewust NIET in.
--
-- Wat hier wel thuishoort zijn handelingen zonder voorwerp: identiteit
-- controleren, fouilleren, iemand meenemen. Die moeten nog gebouwd worden en
-- staan tot die tijd op `unimplemented = true`, waardoor client/interaction.lua
-- ze verbergt. Een knop die niets doet is slechter dan geen knop.
-- ─────────────────────────────────────────────────────────────────────────────

Config.Interactions = {
    citizen_interaction = {
        -- Nog te bouwen. Unpaid Bills hoort bij het billing-systeem, Manage
        -- License bij cityhall, Vehicle Information en Search Plate bij ps-mdt.
        [1]  = { label = 'Check ID',            event = 'police:identity_card',  icon = 'id-badge',                description = 'Check the nearest person their identification', unimplemented = true },
        [2]  = { label = 'Search',              event = 'police:search',         icon = 'magnifying-glass-dollar', description = 'Search the nearest person', unimplemented = true },
        [5]  = { label = 'Drag',                event = 'police:drag',           icon = 'person-walking',          description = 'Escort the nearest person', unimplemented = true },
        [6]  = { label = 'Put in Vehicle',      event = 'police:put_in_vehicle', icon = 'car-side',                description = 'Put the nearest person in a vehicle', unimplemented = true },
        [7]  = { label = 'Pull from Vehicle',   event = 'police:out_the_vehicle',icon = 'car-burst',               description = 'Pull the nearest person out of a vehicle', unimplemented = true },
        [8]  = { label = 'Unpaid Bills',        event = 'police:unpaid_bills',   icon = 'money-bill-trend-up',     description = 'Check outstanding fines', unimplemented = true },
        [9]  = { label = 'Manage License',      event = 'police:managelicense',  icon = 'file-lines',              description = 'Manage licenses', unimplemented = true },
        [10] = { label = 'Gunshot Residue',     event = 'police:gsrtest',        icon = 'person-rifle',            description = 'Test for gunshot residue', unimplemented = true },
        [11] = { label = 'Drug Swab Test',      event = 'police:drugtest',       icon = 'capsules',                description = 'Run a drug swab test', unimplemented = true },
        [12] = { label = 'Breathalyser',        event = 'police:breathalizer',   icon = 'wind',                    description = 'Check the alcohol level', unimplemented = true },
        [13] = { label = 'Check Vitals',        event = 'ems:checkvitals',       icon = 'heart-pulse',             description = 'Check vital signs', unimplemented = true },
        [18] = { label = 'Search Area',         event = 'ems:searchdeadinarea',  icon = 'magnifying-glass',        description = 'Scan the area for casualties', unimplemented = true },
    },
    vehicle_interaction = {
        [1]  = { label = 'Vehicle Information', event = 'police:vehicle_infos',  icon = 'file-invoice',      description = 'Look up the vehicle' },
        [2]  = { label = 'Hijack',              event = 'police:hijack',         icon = 'car-burst',         description = 'Force the vehicle open' },
        [3]  = { label = 'Impound',             event = 'police:impound',        icon = 'car-tunnel',        description = 'Impound the vehicle' },
        [4]  = { label = 'Search Plate',        event = 'police:searchdatabase', icon = 'magnifying-glass',  description = 'Search the plate in the database' },
        [5]  = { label = 'Hijack',              event = 'mechanic:hijack',       icon = 'car-burst',         description = 'Force the vehicle open' },
        [6]  = { label = 'Clean',               event = 'mechanic:clean',        icon = 'soap',              description = 'Clean the vehicle' },
        [7]  = { label = 'Scan ECU',            event = 'mechanic:scanecu',      icon = 'microchip',         description = 'Scan the vehicle computer' },
        [8]  = { label = 'Repair Engine',       event = 'mechanic:repair',       icon = 'screwdriver-wrench',description = 'Repair up to 50%' },
        [9]  = { label = 'Full Repair',         event = 'mechanic:repair2',      icon = 'wrench',            description = 'Repair up to 100%' },
        [10] = { label = 'Put in Vehicle',      event = 'ems:putinvehicle',      icon = 'car-side',          description = 'Put a person in the vehicle' },
        [11] = { label = 'Pull from Vehicle',   event = 'ems:dragoutvehicle',    icon = 'car-burst',         description = 'Pull a person from the vehicle' },
    },
}

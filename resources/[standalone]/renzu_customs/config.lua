--[[
    renzu_customs 2.0 - Qbox edition
    Dependencies: qbx_core, ox_lib, ox_target, oxmysql
    This file is a shared_script: it is loaded on both the client and the server.
]]

Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  MAIN
-- ─────────────────────────────────────────────────────────────────────────────
Config.Debug = false -- draws the ox_target zones so you can align your coordinates

Config.DisableRepair = false -- true = skip the repair screen before the tuning menu opens
Config.OwnedVehiclesOnly = false -- true = only vehicles present in `player_vehicles` can be modified
Config.PlateSpace = true -- true = keep the trailing/leading spaces of the plate (GTA pads plates to 8 chars)
-- note: mod slots with nothing to fit are always hidden, there is no option for it anymore

Config.MoneyType = 'cash' -- 'cash' or 'bank' - account the customer pays from
Config.RepairCost = 1500 -- price of a full repair

-- ─────────────────────────────────────────────────────────────────────────────
--  TARGET / INTERACTION (ox_target)
-- ─────────────────────────────────────────────────────────────────────────────
Config.Target = {
    distance = 2.5, -- max interaction distance for the shop zones
    modBaySize = vec3(6.0, 8.0, 3.0), -- size of the "drive in here to tune" box
    stationSize = vec3(1.6, 1.6, 2.0), -- size of stockroom / inventory / paint stations
}

Config.Blips = {
    enabled = true,
    sprite = 446,
    color = 68,
    scale = 0.8,
    display = 4,
}

-- ─────────────────────────────────────────────────────────────────────────────
--  JOB / PERMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────
Config.DefaultJobGradePermmission = 0 -- fallback minimum grade when a shop has no `min_grade`
Config.JobPermissionAll = true -- true = only the shop's job may use the tuning menu at all
                               -- false = anyone can tune, the job only owns the extra features
-- /freecustoms is gated by the `group.admin` ace, managed through your permissions setup

Config.InteractiveFeature = { -- turn the extra (roleplay) features on/off globally
    garage_inventory = true, -- store & take parts out of the shop stock
    stockroom = true, -- browse every part that fits the cars parked in the shop
    paintmenu = true, -- manual spray can painting
    vehicle_parts = true, -- walk up to a car and pull parts off it
}

-- ─────────────────────────────────────────────────────────────────────────────
--  SOCIETY / PAYOUT
-- ─────────────────────────────────────────────────────────────────────────────
Config.UseSociety = true -- pay the shop's society account (via Renewed-Banking's qb-management exports)
Config.SocietyResource = 'qb-management' -- Renewed-Banking exposes society accounts onder deze exportnaam (GetAccount / AddMoney / RemoveMoney)
Config.SocietyPrefix = '' -- some setups use 'mechanic', others 'society_mechanic'

-- ─────────────────────────────────────────────────────────────────────────────
--  PRICING
-- ─────────────────────────────────────────────────────────────────────────────
Config.VehicleValuetoFormula = false -- true = derive the price of every part from the vehicle's value
Config.VehicleValuePercent = 0.1 -- 0.1 = 10% of the vehicle value feeds the formula
Config.VehicleValueList = { -- extra vehicles that are not in the shared vehicle list
    { model = 'zentorno', value = 100000 },
}
Config.FreeUpgradeToClass = { -- vehicle classes that never pay
    [18] = true, -- emergency
    [19] = true, -- military
}
Config.EnableDiscounts = false
Config.JobDiscounts = { -- global per-job discount, 0.2 = 20% off
    mechanic = 0.2,
    ambulance = 0.1,
    police = 0.15,
}

-- ─────────────────────────────────────────────────────────────────────────────
--  CUSTOM PERFORMANCE FEATURES
-- ─────────────────────────────────────────────────────────────────────────────
Config.DefaultProp = 'hei_prop_heist_box' -- prop carried when a part has no `prop` set

Config.UseCustomTurboUpgrade = true
Config.useturbosound = true -- blow-off valve sound
Config.turbosoundSync = true -- true = everyone nearby hears it, false = only the driver

Config.UseCustomEngineUpgrade = true -- engine swap (copies sound + drivetrain handling)
Config.UseCustomTireUpgrade = true -- tire compounds (traction handling)

-- ─────────────────────────────────────────────────────────────────────────────
--  SHOPS
-- ─────────────────────────────────────────────────────────────────────────────
-- job              = job name that owns this shop
-- min_grade        = minimum grade needed for the shop features
-- radius           = radius of the whole shop (used for the "are you at this shop" check)
-- shopcoord        = center of the shop (blip position)
-- mod              = one or more tuning bays, drive in and target the marker
-- stockroom        = browse every compatible part of the cars parked around
-- paintmenu        = spray can painting station
-- garage_inventory = part storage of the shop
-- A single job can own multiple shops.
Config.Customs = {

    ['Bennys'] = { -- Benny's IPL
        label = "Benny's Original Motor Works",
        job = 'mechanic',
        min_grade = 0,
        radius = 30.0,
        shopcoord = vec4(-212.58, -1325.01, 30.89, 157.28),
        stockroom = { coord = vec4(-227.70, -1322.98, 30.89, 90.90), grade = 0 },
        paintmenu = { coord = vec4(-228.27, -1333.40, 30.89, 0.0), grade = 0 },
        garage_inventory = { coord = vec4(-200.87, -1317.69, 31.08, 267.89), grade = 0 },
        mod = {
            { coord = vec4(-224.20, -1329.81, 30.21, 87.27) },
            { coord = vec4(-213.22, -1331.54, 30.21, 356.69) },
        },
    },

    ['Custom Garage'] = { -- free Tuner Auto Shop MLO
        label = 'Tuner Auto Shop',
        job = 'mechanic',
        min_grade = 0,
        radius = 30.0,
        shopcoord = vec4(818.54, -953.44, 26.10, 305.57),
        stockroom = { coord = vec4(818.46, -969.87, 26.10, 269.27), grade = 0 },
        paintmenu = { coord = vec4(809.76, -959.36, 26.10, 0.0), grade = 0 },
        garage_inventory = { coord = vec4(807.99, -979.44, 26.30, 165.16), grade = 0 },
        mod = {
            { coord = vec4(823.82, -944.92, 25.44, 94.50) },
            { coord = vec4(830.01, -953.10, 25.44, 97.93) },
        },
    },

}

-- PAINT COLORS AND INDEX NAME
Config.Metallic = {
    ['Black'] = 0,
    ['Carbon Black'] = 147,
    ['Graphite'] = 1,
    ['Anhracite Black'] = 11,
    ['Black Steel'] = 2,
    ['Dark Steel'] = 3,
    ['Silver'] = 4,
    ['Bluish Silver'] = 5,
    ['Rolled Steel'] = 6,
    ['Shadow Silver'] = 7,
    ['Stone Silver'] = 8,
    ['Midnight Silver'] = 9,
    ['Cast Iron Silver'] = 10,
    ['Red'] = 27,
    ['Torino Red'] = 28,
    ['Formula Red'] = 29,
    ['Lava Red'] = 150,
    ['Blaze Red'] = 30,
    ['Grace Red'] = 31,
    ['Garnet Red'] = 32,
    ['Sunset Red'] = 33,
    ['Cabernet Red'] = 34,
    ['Wine Red'] = 143,
    ['Candy Red'] = 35,
    ['Hot Pink'] = 135,
    ['Pfsiter Pink'] = 137,
    ['Salmon Pink'] = 136,
    ['Sunrise Orange'] = 36,
    ['Orange'] = 38,
    ['Bright Orange'] = 138,
    ['Gold'] = 99,
    ['Bronze'] = 90,
    ['Yellow'] = 88,
    ['Race Yellow'] = 89,
    ['Dew Yellow'] = 91,
    ['Dark Green'] = 49,
    ['Racing Green'] = 50,
    ['Sea Green'] = 51,
    ['Olive Green'] = 52,
    ['Bright Green'] = 53,
    ['Gasoline Green'] = 54,
    ['Lime Green'] = 92,
    ['Midnight Blue'] = 141,
    ['Galaxy Blue'] = 61,
    ['Dark Blue'] = 62,
    ['Saxon Blue'] = 63,
    ['Blue'] = 64,
    ['Mariner Blue'] = 65,
    ['Harbor Blue'] = 66,
    ['Diamond Blue'] = 67,
    ['Surf Blue'] = 68,
    ['Nautical Blue'] = 69,
    ['Racing Blue'] = 73,
    ['Ultra Blue'] = 70,
    ['Light Blue'] = 74,
    ['Chocolate Brown'] = 96,
    ['Bison Brown'] = 101,
    ['Creeen Brown'] = 95,
    ['Feltzer Brown'] = 94,
    ['Maple Brown'] = 97,
    ['Beechwood Brown'] = 103,
    ['Sienna Brown'] = 104,
    ['Saddle Brown'] = 98,
    ['Moss Brown'] = 100,
    ['Woodbeech Brown'] = 102,
    ['Straw Brown'] = 99,
    ['Sandy Brown'] = 105,
    ['Bleached Brown'] = 106,
    ['Schafter Purple'] = 71,
    ['Spinnaker Purple'] = 72,
    ['Midnight Purple'] = 142,
    ['Bright Purple'] = 145,
    ['Cream'] = 107,
    ['Ice White'] = 111,
    ['Frost White'] = 112,
}

Config.Matte = {
    ['Black'] = 12,
    ['Gray'] = 13,
    ['Light Gray'] = 14,
    ['Ice White'] = 131,
    ['Blue'] = 83,
    ['Dark Blue'] = 82,
    ['Midnight Blue'] = 84,
    ['Midnight Purple'] = 149,
    ['Schafter Purple'] = 148,
    ['Red'] = 39,
    ['Dark Red'] = 40,
    ['Orange'] = 41,
    ['Yellow'] = 42,
    ['Lime Green'] = 55,
    ['Green'] = 128,
    ['Forest Green'] = 151,
    ['Foliage Green'] = 155,
    ['Olive Darb'] = 152,
    ['Dark Earth'] = 153,
    ['Desert Tan'] = 154,
}

Config.Metals = {
    ['Brushed Steel'] = 117,
    ['Brushed Black Steel'] = 118,
    ['Brushed Aluminum'] = 119,
    ['Pure Gold'] = 158,
    ['Brushed Gold'] = 159,
}

Config.Chameleon = { -- labels to be followed
 ['	RED ORANGE FLIP'] = 190,
 ['	ANOD PURPLE'] = 163,
 ['	TURQ PURP FLIP'] = 178,
 ['	MAGEN CYAN FLIP'] = 187,
 ['	PURP GREEN FLIP'] = 183,
 ['	BLACK PRISMA'] = 218,
 ['	YKTA CHRISTMAS'] = 237,
 ['	YKTA NITE DAY'] = 224,
 ['	YKTA FOUR SEASO'] = 229,
 ['	CREAM PEARL'] = 210,
 ['	RED PRISMA'] = 216,
 ['	GREEN BLUE FLIP'] = 171,
 ['	YKTA MONOCHROME'] = 223,
 ['	YKTA THE SEVEN'] = 234,
 ['	RAINBOW PRISMA'] = 220,
 ['	ORANG BLUE FLIP'] = 192,
 ['	DARKTEALPEARL'] = 197,
 ['	YKTA VERLIERER2'] = 225,
 ['	OIL SLIC PRISMA'] = 219,
 ['	YKTA M9 THROWBA'] = 230,
 ['	YKTA FUBUKI'] = 242,
 ['	DARKBLUEPEARL'] = 198,
 ['	WHITE HOLO'] = 222,
 ['	ANOD WINE'] = 162,
 ['	ANOD BRONZE'] = 168,
 ['	LIT BLUE PEARL'] = 202,
 ['	ANOD RED'] = 161,
 ['	GREEN PURP FLIP'] = 175,
 ['	GREEN TURQ FLIP'] = 174,
 ['	BLUE GREEN FLIP'] = 181,
 ['	LIT PURP PEARL'] = 203,
 ['	LIT PINK PEARL'] = 204,
 ['	GREEN BROW FLIP'] = 173,
 ['	YKTA ELECTRO'] = 240,
 ['	TEAL PURP FLIP'] = 176,
 ['	GREEN PRISMA'] = 217,
 ['	YKTA SYNTHWAVE'] = 228,
 ['	BLUE PEARL'] = 209,
 ['	YELLOW PEARL'] = 207,
 ['	DARKBLUEPRISMA'] = 213,
 ['	OIL SLICK PEARL'] = 200,
 ['	DARKGREENPEARL'] = 196,
 ['	ANOD COPPER'] = 167,
 ['	GREEN PEARL'] = 208,
 ['	ORANG PURP FLIP'] = 191,
 ['	ANOD GOLD'] = 170,
 ['	DARKPURPPRISMA'] = 214,
 ['	WHITE PRISMA'] = 211,
 ['	TURQ RED FLIP'] = 177,
 ['	CYAN PURP FLIP'] = 179,
 ['	MAGEN ORAN FLIP'] = 189,
 ['	MAGEN GREE FLIP'] = 184,
 ['	DARKPURPLEPEARL'] = 199,
 ['	YKTA FULL RBOW'] = 232,
 ['	ANOD GREEN'] = 165,
 ['	PURP RED FLIP'] = 182,
 ['	WHITE PURP FLIP'] = 193,
 ['	HOT PINK PRISMA'] = 215,
 ['	YKTA BUBBLEGUM'] = 231,
 ['	MAGEN YELL FLIP'] = 185,
 ['	BLUE PINK FLIP'] = 180,
 ['	BURG GREEN FLIP'] = 186,
 ['	LIT GREEN PEARL'] = 201,
 ['	ANOD LIME'] = 166,
 ['	OFFWHITE PRISMA'] = 205,
 ['	RED RAINBO FLIP'] = 194,
 ['	COPPE PURP FLIP'] = 188,
 ['	YKTA HSW'] = 239,
 ['	ANOD CHAMPAGNE'] = 169,
 ['	YKTA KAMENRIDER'] = 235,
 ['	YKTA MONIKA'] = 241,
 ['	YKTA SPRUNK EX'] = 226,
 ['	YKTA VICE CITY'] = 227,
 ['	BLACK HOLO'] = 221,
 ['	BLU RAINBO FLIP'] = 195,
 ['	GRAPHITE PRISMA'] = 212,
 ['	GREEN RED FLIP'] = 172,
 ['	PINK PEARL'] = 206,
 ['	YKTA SUNSETS'] = 233,
 ['	ANOD BLUE'] = 164,
 ['	YKTA CHROMABERA'] = 236,
 ['	YKTA TEMPERATUR'] = 238,
}

Config.Crome = { ['Chrome'] = 120 }

-- every non-chameleon colour merged into one list (used for the wheel colour picker)
Config.AllColors = {}
for _, group in ipairs({ Config.Metallic, Config.Matte, Config.Metals }) do
	for name, index in pairs(group) do
		Config.AllColors[name] = index
	end
end
local allcolors = Config.AllColors -- kept so the tables below stay readable

-- VEHICLE MODS , you can change parts value / cost here
-- FAQ
-- multicost  = if true cost will multiple the level from the original cost
-- camera angles (you can customize this as i dont have a proper test to perfect the angles yet)
-- type = Menu Main title
-- bone = bone target for camera (obsolete)
-- index = MOD index name
-- cost = the cost of vehicle mod in all lvls (unless multicost)
-- job_grade = MINIMUM job_grade lvl permmision to access the upgrade type (if no indicated, Config.DefaultJobGradePermmission will be used as default) (THIS WILL ONLY WORK if Config.JobPermissionAll = true)
-- discount = This is Persistent config!, it means Config.JobDiscounts will be ignored as long as this job ex. mechanic is here and job ex. mechanic is in Config.JobDiscounts too. , any unlisted jobs here will be using the default listed here Config.JobDiscounts (if its registered)
Config.VehicleMod = {
    ----------Liveries--------
	[48] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 1.0, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Liveries',
		name = 'liveries',
        index = 48,
		cost = 15000,
		percent_cost = 7,
		bone = 'chassis',
        type = 'Exterior',
		camera = {val = 'front', x = -2.1, y = 0.6,z = 1.1},
	},
	
----------Windows--------
	[46] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Windows',
		name = 'windows',
        index = 46,
		cost = 15000,
		percent_cost = 2,
		bone = 'window_lf1',
		camera = {val = 'right', x = 0.8, y = 0.8,z = 0.8},
        type = 'Exterior',
	},
	
----------Tank--------
	[45] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Intercooler',
		name = 'tank',
        index = 45,
		cost = 15000,
		percent_cost = 4,
		bone = 'chassis',
        type = 'Exterior',
		camera = {val = 'front', x = 0.2, y = 0.3,z = 0.1},
	},
	
----------Trim--------
	[44] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Trim',
		name = 'trim',
        index = 44,
		cost = 15000,
		percent_cost = 2,
		bone = 'boot',
		camera = {val = 'middle', x = 2.1, y = 2.1,z = -0.1},
        type = 'cosmetic',
	},
	
----------Aerials--------
	[43] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Aerials',
		name = 'aerials',
        index = 43,
		cost = 15000,
		percent_cost = 2,
		camera = {val = 'front', x = 0.5, y = 0.6,z = 0.4},
        type = 'cosmetic',
	},

----------Arch cover--------
	[42] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Arch cover',
		name = 'archcover',
        index = 42,
		cost = 15000,
		percent_cost = 2.5,
		bone = 'engine',
		action = 'openhood',
        type = 'cosmetic',
	},

----------Struts--------
	[41] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Struts',
		name = 'struts',
        index = 41,
		cost = 15000,
		percent_cost = 2.5,
		bone = 'engine',
		action = 'openhood',
        type = 'Performance Parts',
	},
	
----------Air filter--------
	[40] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Air filter',
		name = 'airfilter',
        index = 40,
		cost = 15000,
		percent_cost = 3.5,
		bone = 'engine',
		action = 'openhood',
        type = 'Performance Parts',
	},
	
----------Engine block--------
	[39] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Engine block',
		name = 'engineblock',
        index = 39,
		cost = 15000,
		percent_cost = 3.5,
		bone = 'engine',
		action = 'openhood',
        type = 'Performance Parts',
	},

----------Hydraulics--------
	[38] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Hydraulics',
		name = 'hydraulics',
        index = 38,
		cost = 15000,
		percent_cost = 7,
		bone = 'wheel_rf',
        type = 'cosmetic',
	},
	
----------Trunk--------
	[37] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Trunk',
		name = 'trunk',
        index = 37,
		cost = 15000,
		percent_cost = 4,
        type = 'Exterior',
		bone = 'boot',
		camera = {val = 'back', x = 0.5, y = -1.6,z = 1.3},
        prop = 'imp_prop_impexp_trunk_01a',
	},

----------Speakers--------
	[36] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Speakers',
		name = 'speakers',
        index = 36,
		cost = 15000,
		percent_cost = 3,
		bone = 'door_dside_f',
        type = 'Interior',
	},

----------Plaques--------
	[35] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Plaques',
		name = 'plaques',
        index = 35,
		cost = 15000,
		percent_cost = 3,
		camera = {val = 'left', x = -0.2, y = -0.5,z = 0.9},
		bone = 'steeseat_dside_fring',
        type = 'Interior',
	},
	
----------Shift leavers--------
	[34] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Shift leavers',
		name = 'shiftleavers',
        index = 34,
		camera = {val = 'left', x = -0.2, y = -0.5,z = 0.9},
		bone = 'steeseat_dside_fring',
		cost = 15000,
		percent_cost = 3,
        type = 'Interior',
	},
	
----------Steeringwheel--------
	[33] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Steeringwheel',
		name = 'steeringwheel',
        index = 33,
		bone = 'seat_dside_f',
		cost = 15000,
		percent_cost = 3,
		camera = {val = 'left', x = -0.2, y = -0.5,z = 0.9},
        type = 'Interior',
	},
	
----------Seats--------
	[32] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Seats',
		name = 'seats',
        index = 32,
		cost = 15000,
		percent_cost = 5,
        type = 'Interior',
		bone = 'seat_dside_f',
        prop = 'prop_car_seat',
	},
	
----------Door speaker--------
	[31] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Door speaker',
		name = 'doorspeaker',
        index = 31,
		percent_cost = 3,
		bone = 'door_dside_f',
		cost = 15000,
        type = 'Interior',
	},

----------Dial--------
	[30] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Dial',
		name = 'dial',
        index = 30,
		cost = 15000,
		percent_cost = 3,
		bone = 'seat_dside_f',
		camera = {val = 'left', x = -0.2, y = -0.5,z = 0.9},
        type = 'Interior',
	},
----------Dashboard--------
	[29] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Dashboard',
		name = 'dashboard',
        index = 29,
		cost = 15000,
		percent_cost = 5,
		bone = 'seat_dside_f',
        type = 'interior',
	},
	
----------Ornaments--------
	[28] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Ornaments',
		name = 'ornaments',
        index = 28,
		cost = 15000,
		percent_cost = 4,
		bone = 'seat_dside_f',
        type = 'cosmetic',
	},
	
----------Trim--------
	[27] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Trim',
		name = 'trim',
        index = 27,
		cost = 15000,
		percent_cost = 3,
		bone = 'bumper_f',
        type = 'cosmetic',
	},
	
----------Vanity plates--------
	[26] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Vanity plates',
		name = 'vanityplates',
        index = 26,
		cost = 15000,
		percent_cost = 2,
		bone = 'exhaust',
		camera = {val = 'front', x = 0.1, y = 0.6,z = 0.4},
        type = 'cosmetic',
        prop = 'p_num_plate_01',
	},
	
----------Plate holder--------
	[25] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Plate holder',
		name = 'plateholder',
        index = 25,
		cost = 15000,
		percent_cost = 3,
		bone = 'exhaust',
		camera = {val = 'front', x = 0.1, y = 0.6,z = 0.4},
        type = 'cosmetic',
	},
---------Back Wheels---------
	[24] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Back Wheels',
		name = 'backwheels',
        index = 24,
		cost = 15000,
		percent_cost = 4,
        type = 'Wheel Parts',
		camera = {val = 'middle', x = 2.1, y = 2.1,z = -0.1},
		bone = 'wheel_lr',
        prop = 'imp_prop_impexp_wheel_03a',
	},
---------Front Wheels---------
	[23] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Front Wheels',
		name = 'frontwheels',
        index = 23,
		cost = 15000,
		percent_cost = 5,
		bone = 'wheel_rf',
        type = 'Wheel Parts',
		camera = {val = 'middle', x = 2.1, y = 2.1,z = -0.1},
        prop = 'imp_prop_impexp_wheel_03a',
		list = {WheelType = {Sport = 0, Muscle = 1, Lowrider = 2, SUV = 3, Offroad = 4,Tuner = 5, BikeWheel = 6, HighEnd = 7 , BennysWheel = 8, BespokeWheel = 9, Dragster = 10, Street = 11 } , WheelColor = allcolors, Accessories = { CustomTire = 1, BulletProof = 1, SmokeColor = 1, DriftTires = 1} } -- BennysWheel = 8, BespokeWheel = 9
	},
-- NOTE: native mod index 22 (xenon headlights) is handled by the ['headlight']
-- entry further down, which also exposes the xenon colours.

----------Turbo---------
	[18] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Turbo',
		name = 'turbo',
        index = 18,
		cost = 15000,
		percent_cost = 20,
		bone = 'engine',
        type = 'Performance Parts',
		list = {Default = 0, Turbo = 1}
	},
	
-----------Armor-------------
	[16] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Armor',
		name = 'armor',
        index = 16,
		cost = 15000,
		percent_cost = 25,
		bone = 'bodyshell',
		multicostperlvl = true,
        type = 'Shell',
	},

---------Suspension-----------
	[15] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Suspension',
		name = 'suspension',
        index = 15,
		cost = 15000,
		percent_cost = 6,
		bone = 'wheel_rf',
		multicostperlvl = true,
        type = 'Performance Parts',
	},
-----------Horn----------
    [14] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
        label = 'Horn',
		name = 'horn',
        index = 14,
		cost = 15000,
		percent_cost = 3,
		bone = 'bumper_f',
		camera = {val = 'middle', x = 2.1, y = 2.1,z = -0.1},
        type = 'cosmetic',
    },
-----------Transmission-------------
    [13] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
        label = 'Transmission',
		name = 'transmission',
        index = 13,
		cost = 15000,
		percent_cost = 8,
		bone = 'engine',
		multicostperlvl = true,
        type = 'Performance Parts',
        prop = 'imp_prop_impexp_gearbox_01',
	},
	
-----------Brakes-------------
	[12] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
        label = 'Brakes',
		name = 'brakes',
        index = 12,
		cost = 15000,
		percent_cost = 5,
		bone = 'wheel_rf',
		multicostperlvl = true,
        type = 'Performance Parts',
        prop = 'imp_prop_impexp_brake_caliper_01a',
	},
	
------------Engine----------
	[11] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
        label = 'Engine',
		name = 'engine',
        index = 11,
		cost = 15000,
		percent_cost = 10,
		bone = 'engine',
		action = 'openhood',
		multicostperlvl = true,
        type = 'Performance Parts',
        prop = 'prop_car_engine_01',
	},
    ---------Roof----------
	[10] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Roof',
		name = 'roof',
        index = 10,
		cost = 15000,
		percent_cost = 5,
		bone = 'roof',
		camera = {val = 'front-top', x = 0.5, y = -2.6,z = 1.5},
        type = 'exterior',
	},
	
------------Fenders---------
	[8] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Fenders',
		name = 'fenders',
        index = 8,
		cost = 15000,
		percent_cost = 5,
        type = 'cosmetic',
		bone = 'wheel_rf',
        prop = 'imp_prop_impexp_car_panel_01a'
	},
	
------------Hood----------
	[7] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Hood',
		name = 'Hood',
        index = 7,
		cost = 15000,
		percent_cost = 8,
        type = 'cosmetic',
		bone = 'bumper_f',
		camera = {val = 'front', x = 0.1, y = 0.8,z = 0.8},
        prop = 'imp_prop_impexp_bonnet_02a',
	},
	
----------Grille----------
	[6] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Grille',
		name = 'grille',
        index = 6,
		percent_cost = 3,
		cost = 15000,
		bone = 'bumper_f',
		camera = {val = 'front', x = 0.1, y = 0.6,z = 0.4},
        type = 'cosmetic',
	},
	
----------Roll cage----------
	[5] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Roll cage',
		name = 'rollcage',
        index = 5,
		cost = 15000,
		percent_cost = 7,
        type = 'interior',
		bone = 'seat_dside_f',
		camera = {val = 'front-top', x = 0.1, y = -1.5,z = 0.5},
        prop = 'imp_prop_impexp_rear_bars_01b'
	},
	
----------Exhaust----------
	[4] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Exhaust',
		name = 'exhaust',
        index = 4,
		cost = 15000,
		percent_cost = 6,
        type = 'exterior',
		bone = 'exhaust',
		camera = {val = 'back', x = 0.5, y = -1.6,z = 0.4},
        prop = 'imp_prop_impexp_exhaust_01',
	},
	
----------Skirts----------
	[3] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Skirts',
		name = 'skirts',
        index = 3,
		cost = 15000,
		percent_cost = 3,
		bone = 'neon_r',
        type = 'cosmetic',
        prop = 'imp_prop_impexp_rear_bumper_01a',
	},
	
-----------Rear bumpers----------
	[2] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
			--['all'] = 0, -- all jobs?
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Rear bumpers',
		name = 'rearbumpers',
        index = 2,
		cost = 15000,
		percent_cost = 3,
		bone = 'bumper_r',
		camera = {val = 'back', x = 0.5, y = -1.6,z = 0.4},
        type = 'cosmetic',
        prop = 'imp_prop_impexp_rear_bumper_03a',
	},
	
----------Front bumpers----------
	[1] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
			['ambulance'] = 0,-- police is sample only change this!
			--['all'] = 0, -- all jobs?
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Front bumpers',
		name = 'frontbumpers',
        index = 1,
		cost = 15000,
		percent_cost = 4,
		bone = 'bumper_f',
		camera = {val = 'front', x = 0.1, y = 0.6,z = 0.4},
        type = 'cosmetic',
        prop = 'imp_prop_impexp_front_bumper_01a',
	},
	
----------Spoiler----------
	[0] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Spoiler',
		name = 'spoiler',
        index = 0,
		cost = 15000,
		percent_cost = 5,
		bone = 'boot',
		camera = {val = 'back', x = 0.5, y = -1.6,z = 1.3},
        type = 'cosmetic',
        prop = 'imp_prop_impexp_spoiler_04a',
	},

	['paint1'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Primary Color',
		name = 'paint1',
        index = 99,
		cost = 15000,
		percent_cost = 8,
		bone = 'boot',
        type = 'Primary Color',
        prop = 'imp_prop_impexp_spoiler_04a',
		list = {Chameleon = Config.Chameleon, Metallic = Config.Metallic, Matte = Config.Matte, Metals = Config.Metals, Crome = Config.Crome, Pearlescent = Config.Metallic}
	},
	['paint2'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Secondary Color',
		name = 'paint2',
        index = 100,
		cost = 15000,
		percent_cost = 5,
		bone = 'boot',
        type = 'Secondary Color',
        prop = 'imp_prop_impexp_spoiler_04a',
		list = {Metallic = Config.Metallic, Matte = Config.Matte, Metals = Config.Metals, Crome = Config.Crome}
	},
	['headlight'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Headlights',
		name = 'headlight',
        index = 101,
		cost = 15000,
		percent_cost = 3,
		bone = 'boot',
        type = 'Headlights',
		camera = {val = 'front', x = 0.1, y = 0.6,z = 0.4},
        prop = 'imp_prop_impexp_spoiler_04a',
		list = {Default = false, XenonLights = true, 
		XenonColor = {
				Default = -1,
				White = 0,
				Blue = 1,
				ElectricBlue = 2,
				MintGreen = 3,
				LimeGreen = 4,
				Yellow = 5,
				GoldenShower = 6,
				Orange = 7,
				Red = 8,
				PonyPink = 9,
				HotPink = 10,
				Purple = 11,
			},
		}
	},
	['plate'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Plate',
		name = 'plate',
        index = 102,
		cost = 15000,
		percent_cost = 2,
		camera = {val = 'back', x = 0.5, y = -1.6,z = 1.3},
		bone = 'boot',
        type = 'Plate',
        prop = 'imp_prop_impexp_spoiler_04a',
		list = {BlueWhite = 0, YellowBlack = 1, YellowBlue = 2,BlueWhite1 = 3,BlueWhite2 = 4,Yankton = 5}
	},
	['neon'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Neon Lights',
		name = 'neon',
        index = 103,
		cost = 15000,
		percent_cost = 3,
		bone = 'boot',
        type = 'Neon Lights',
		camera = {val = 'middle', x = 2.1, y = 2.1,z = -0.1},
        prop = 'imp_prop_impexp_spoiler_04a',
		list = {Default = 0, NeonKit = 1, NeonColor = 2}
	},
	['window'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Window Tints',
		name = 'window',
        index = 104,
		cost = 15000,
		percent_cost = 5,
        type = 'Window Tints',
		bone = 'boot',
		camera = {val = 'left', x = -0.3, y = -0.3,z = 0.9},
        prop = 'imp_prop_impexp_spoiler_04a',
		list = {
			['None'] = 0,
			['Pure Black'] = 1,
			['Dark Smoke'] = 2,
			['Light Smoke'] = 3,
			['Stock'] = 4,
			['Limo'] = 5,
			['Green'] = 6,
		}
	},
	['extra'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Vehicle Extra',
		name = 'extra',
        index = 105,
		percent_cost = 5,
		cost = 15000,
        type = 'Extras',
		bone = 'boot',
		camera = {val = 'left', x = -0.3, y = -0.3,z = 0.9},
        prop = 'imp_prop_impexp_spoiler_04a',
		-- the available extras are read from the vehicle at runtime
		list = {},
	},

}

-- CUSTOM UPGRADE START
-- Turbo Stats Modification
-- Power = Level of Boost Pressure
-- Torque = Level of Torque to add
-- value = Cost
if Config.UseCustomTurboUpgrade then
	Config.VehicleMod['custom_turbo'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Custom Turbo',
		name = 'custom_turbo',
		index = 107,
		cost = 25000,
		percent_cost = 25,
		bone = 'bumper_f',
		type = 'Custom Turbo',
		prop = 'imp_prop_impexp_spoiler_04a',
		list = {
			Default = {}, -- needed for uninstall
			Street = {Power = 1.2, Torque = 1.3, value = 25000},
			Sports = {Power = 1.4, Torque = 1.5, value = 55000},
			Racing = {Power = 2.2, Torque = 2.3, value = 125000},
		}
	}
end

-- Engine Stat Modification
-- Adding New Engine is easy
-- ex Elegy = {model = 'elegy', value = 25000},
-- just insert this line from the inside of list = {} (table)
-- Engien upgrades Copy Both Sound and Original Handling (Fmass is excluded and tractions handling) (only related to Vehicle Engine power)
if Config.UseCustomEngineUpgrade then
	Config.VehicleMod['custom_engine'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Custom Engine',
		name = 'custom_engine',
		index = 106,
		cost = 25000,
		percent_cost = 30,
		bone = 'bumper_f',
		type = 'Custom Engine',
		prop = 'imp_prop_impexp_spoiler_04a',
		list = { -- table
			Default = {}, -- needed for uninstall
			Adder = {model = 'adder', value = 25000},
			FMJ = {model = 'fmj', value = 25000},
			Ruston = {model = 'ruston', value = 25000},
			RT3000 = {model = 'rt3000', value = 25000},
			Stinger = {model = 'stingergt', value = 25000},
		} -- table end
	}
end

-- Custom Tire Modification
-- Preconfigured Variations
-- You can tuned the Spec of the each handling
-- the value for each handling name is Not perfect, but can be used in more use cases and realistic.
if Config.UseCustomTireUpgrade then
	Config.VehicleMod['custom_tires'] = {
		job_grade = { -- default job grade to access this Upgrade Feature (this option will work only if Config.JobPermissionAll is true
			['mechanic'] = 0,
			['police'] = 0,-- police is sample only change this!
		},
		discount = {
			['mechanic'] = 0.2, -- 20%
			['ambulance'] = 0.1, -- 10%
			['police'] = 0.15, -- 15%
		},
		label = 'Custom Tires',
		name = 'custom_tires',
		index = 108,
		cost = 25000,
		percent_cost = 15,
		bone = 'bumper_f',
		type = 'Custom Tires',
		prop = 'imp_prop_impexp_spoiler_04a',
		list = {
			Default = {}, -- needed for uninstall
			Street = {fLowSpeedTractionLossMult = 1.1,fTractionLossMult = 1.1,fTractionCurveMin = 1.2, fTractionCurveMax = 1.0, fTractionCurveLateral = 0.8, value = 25000},
			Sports = {fLowSpeedTractionLossMult = 0.9,fTractionLossMult = 0.9,fTractionCurveMin = 1.1, fTractionCurveMax = 1.1, fTractionCurveLateral = 1.1, value = 35000},
			Racing = {fLowSpeedTractionLossMult = 0.65,fTractionLossMult = 0.7,fTractionCurveMin = 1.25, fTractionCurveMax = 1.35, fTractionCurveLateral = 1.25, value = 45000},
			Drag = {fLowSpeedTractionLossMult = 0.1,fTractionLossMult = 0.1,fTractionCurveMin = 2.2, fTractionCurveMax = 0.1, fTractionCurveLateral = 1.1, value = 55000},
		}
	}
end

-- RGB color for Spray Cans
-- do not rename and edit custom
Config.Pilox = {
    ['white'] = {255, 255, 255},
    ['red'] =  {246, 75, 60},
    ['pink'] = {253, 226, 226},
    ['blue'] = {0, 168, 204},
    ['yellow'] = {245, 252, 193},
    ['green'] = {99, 154, 103},
    ['orange'] = {255, 164, 27},
    ['brown'] = {156, 85, 24},
    ['purple'] =  {190, 121, 223},
    ['grey'] = {50, 50, 50},
    ['black'] = {0, 0, 0},
	['custom'] = {0, 0, 0}, -- do not change this is a custom for RGB
}
-- The tuner DLC (build 2372) added Bennys/Bespoke wheels and drift tyres.
-- On older builds those options are stripped so the menu never shows something broken.
if not IsDuplicityVersion() and GetGameBuildNumber() < 2372 then
	local wheels = Config.VehicleMod[23].list
	wheels.WheelType.BennysWheel = nil
	wheels.WheelType.BespokeWheel = nil
	wheels.WheelType.Dragster = nil
	wheels.WheelType.Street = nil
	wheels.Accessories.DriftTires = nil
end
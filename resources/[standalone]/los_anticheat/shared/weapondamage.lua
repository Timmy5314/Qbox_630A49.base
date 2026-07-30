---Wapenschade-referentie voor de damage-validator.
---
---WAAROM DIT BESTAND BESTAAT
---weaponDamageEvent geeft ons `weaponDamage` en `overrideDefaultDamage`. Om te
---beoordelen of een waarde te hoog is, moet de server weten wat het wapen maximaal
---kan doen. Er staat op deze server geen enkele weapons.meta met damage-overrides
---(alleen ND_GunAnims/weaponanimations.meta, dat is animatie), dus de baseline
---hieronder is vanilla GTA V.
---
---ALS JE CUSTOM WAPENS TOEVOEGT: zet de base damage uit jouw weapons.meta hier
---neer, anders scoort de validator legitieme treffers als te hoog. Een wapen dat
---hier niet in staat wordt NIET op schade gecontroleerd (alleen op bezit), zodat
---een vergeten entry nooit tot een onterechte ban leidt.
---
---HANDWAPENS VS VOERTUIGWAPENS ZIJN GESCHEIDEN
---Een turret of raket komt van een voertuig, niet uit de inventory van de speler.
---Die mogen dus nooit door de inventory-check heen. Ze staan in VehicleWeapons en
---worden apart beoordeeld: klopt het dat de speler in een voertuig zit dat dit
---wapen heeft.

local Weapons = {}

---Tolerantie op de basisschade. Headshots, afstandsval en damage modifiers van
---attachments zitten hier ruim binnen. Alleen echte damage-hacks gaan hier
---overheen. 3.0 = drie keer de basisschade is nog toegestaan.
Weapons.tolerance = 3.0

---Basisschade per handwapen (vanilla GTA V weapons.meta).
---@type table<string, number>
Weapons.handheld = {
    -- Pistolen
    WEAPON_PISTOL             = 26,
    WEAPON_PISTOL_MK2         = 27,
    WEAPON_COMBATPISTOL       = 27,
    WEAPON_APPISTOL           = 27,
    WEAPON_STUNGUN            = 0,
    WEAPON_PISTOL50           = 51,
    WEAPON_SNSPISTOL          = 20,
    WEAPON_SNSPISTOL_MK2      = 22,
    WEAPON_HEAVYPISTOL        = 40,
    WEAPON_VINTAGEPISTOL      = 34,
    WEAPON_FLAREGUN           = 30,
    WEAPON_MARKSMANPISTOL     = 90,
    WEAPON_REVOLVER           = 97,
    WEAPON_REVOLVER_MK2       = 97,
    WEAPON_DOUBLEACTION       = 78,
    WEAPON_CERAMICPISTOL      = 25,
    WEAPON_NAVYREVOLVER       = 92,
    WEAPON_GADGETPISTOL       = 46,

    -- SMG's
    WEAPON_MICROSMG           = 21,
    WEAPON_SMG                = 22,
    WEAPON_SMG_MK2            = 22,
    WEAPON_ASSAULTSMG         = 23,
    WEAPON_COMBATPDW          = 24,
    WEAPON_MACHINEPISTOL      = 20,
    WEAPON_MINISMG            = 21,
    WEAPON_RAYCARBINE         = 25,

    -- Shotguns (waarde per pellet)
    WEAPON_PUMPSHOTGUN        = 32,
    WEAPON_PUMPSHOTGUN_MK2    = 34,
    WEAPON_SAWNOFFSHOTGUN     = 37,
    WEAPON_ASSAULTSHOTGUN     = 26,
    WEAPON_BULLPUPSHOTGUN     = 14,
    WEAPON_MUSKET             = 97,
    WEAPON_HEAVYSHOTGUN       = 31,
    WEAPON_DBSHOTGUN          = 62,
    WEAPON_AUTOSHOTGUN        = 32,
    WEAPON_COMBATSHOTGUN      = 33,

    -- Rifles
    WEAPON_ASSAULTRIFLE       = 30,
    WEAPON_ASSAULTRIFLE_MK2   = 32,
    WEAPON_CARBINERIFLE       = 32,
    WEAPON_CARBINERIFLE_MK2   = 34,
    WEAPON_ADVANCEDRIFLE      = 34,
    WEAPON_SPECIALCARBINE     = 34,
    WEAPON_SPECIALCARBINE_MK2 = 36,
    WEAPON_BULLPUPRIFLE       = 32,
    WEAPON_BULLPUPRIFLE_MK2   = 34,
    WEAPON_COMPACTRIFLE       = 30,
    WEAPON_MILITARYRIFLE      = 34,
    WEAPON_HEAVYRIFLE         = 34,
    WEAPON_TACTICALRIFLE      = 32,

    -- LMG
    WEAPON_MG                 = 34,
    WEAPON_COMBATMG           = 37,
    WEAPON_COMBATMG_MK2       = 39,
    WEAPON_GUSENBERG          = 34,

    -- Sniper
    WEAPON_SNIPERRIFLE        = 101,
    WEAPON_HEAVYSNIPER        = 216,
    WEAPON_HEAVYSNIPER_MK2    = 216,
    WEAPON_MARKSMANRIFLE      = 65,
    WEAPON_MARKSMANRIFLE_MK2  = 70,
    WEAPON_PRECISIONRIFLE     = 101,

    -- Heavy
    WEAPON_RPG                = 250,
    WEAPON_GRENADELAUNCHER    = 175,
    WEAPON_MINIGUN            = 20,
    WEAPON_FIREWORK           = 150,
    WEAPON_RAILGUN            = 250,
    WEAPON_HOMINGLAUNCHER     = 250,
    WEAPON_COMPACTLAUNCHER    = 175,
    WEAPON_RAYMINIGUN         = 20,

    -- Melee
    WEAPON_UNARMED            = 5,
    WEAPON_KNIFE              = 25,
    WEAPON_NIGHTSTICK         = 10,
    WEAPON_HAMMER             = 25,
    WEAPON_BAT                = 25,
    WEAPON_GOLFCLUB           = 20,
    WEAPON_CROWBAR            = 25,
    WEAPON_BOTTLE             = 21,
    WEAPON_DAGGER             = 25,
    WEAPON_HATCHET            = 25,
    WEAPON_KNUCKLE            = 20,
    WEAPON_MACHETE            = 25,
    WEAPON_FLASHLIGHT         = 10,
    WEAPON_SWITCHBLADE        = 25,
    WEAPON_BATTLEAXE          = 40,
    WEAPON_POOLCUE            = 22,
    WEAPON_WRENCH             = 25,
    WEAPON_STONE_HATCHET      = 25,

    -- Throwables
    WEAPON_GRENADE            = 175,
    WEAPON_STICKYBOMB         = 175,
    WEAPON_MOLOTOV            = 55,
    WEAPON_PROXMINE           = 175,
    WEAPON_PIPEBOMB           = 175,
    WEAPON_BZGAS              = 0,
    WEAPON_SMOKEGRENADE       = 0,
    WEAPON_FLARE              = 25,
    WEAPON_SNOWBALL           = 5,
    WEAPON_BALL               = 5,

    -- Overig
    WEAPON_PETROLCAN          = 5,
    WEAPON_FIREEXTINGUISHER   = 2,
    WEAPON_HAZARDCAN          = 5,
    WEAPON_FERTILIZERCAN      = 5,
}

---Voertuig- en turretwapens. Deze komen NOOIT uit de spelersinventory, dus de
---bezitscheck mag er niet op los. Ze worden apart gevalideerd: zit de speler in
---een voertuig, en is dat voertuig bewapend.
---@type table<string, number>
Weapons.vehicle = {
    VEHICLE_WEAPON_ROTORS               = 100,
    VEHICLE_WEAPON_TANK                 = 250,
    VEHICLE_WEAPON_SPACE_ROCKET         = 250,
    VEHICLE_WEAPON_PLANE_ROCKET         = 250,
    VEHICLE_WEAPON_PLAYER_LASER         = 60,
    VEHICLE_WEAPON_PLAYER_BULLET        = 40,
    VEHICLE_WEAPON_PLAYER_BUZZARD       = 40,
    VEHICLE_WEAPON_PLAYER_HUNTER        = 40,
    VEHICLE_WEAPON_PLAYER_LAZER         = 60,
    VEHICLE_WEAPON_ENEMY_LASER          = 60,
    VEHICLE_WEAPON_SEARCHLIGHT          = 0,
    VEHICLE_WEAPON_RADAR                = 0,
    VEHICLE_WEAPON_TURRET_INSURGENT     = 40,
    VEHICLE_WEAPON_TURRET_TECHNICAL     = 40,
    VEHICLE_WEAPON_TURRET_LIMO          = 40,
    VEHICLE_WEAPON_TURRET_BOXVILLE      = 40,
    VEHICLE_WEAPON_WATER_CANNON         = 5,
    VEHICLE_WEAPON_NOSE_TURRET_VALKYRIE = 40,
    VEHICLE_WEAPON_TURRET_VALKYRIE      = 40,
    VEHICLE_WEAPON_TURRET_TECHNICAL2    = 40,
    VEHICLE_WEAPON_TURRET_TECHNICAL3    = 40,
    VEHICLE_WEAPON_MOGUL_TURRET         = 40,
    VEHICLE_WEAPON_HALFTRACK_QUADMOUNT  = 40,
    VEHICLE_WEAPON_APC_TURRET           = 60,
    VEHICLE_WEAPON_TAMPA_MORTAR         = 250,
    VEHICLE_WEAPON_TAMPA_MISSILE        = 250,
    VEHICLE_WEAPON_DUNE_MINIGUN         = 40,
    VEHICLE_WEAPON_DUNE_GRENADE         = 175,
    VEHICLE_WEAPON_OPPRESSOR_MISSILE    = 250,
    VEHICLE_WEAPON_KHANJALI_CANNON      = 250,
    VEHICLE_WEAPON_AVENGER_CANNON       = 250,
}

---Wapens die op deze server helemaal niet horen te bestaan. Zien we ze in een
---weaponDamageEvent, dan is dat geen sync-fout maar een menu.
---@type table<string, boolean>
Weapons.blacklist = {
    WEAPON_RAILGUN         = true,
    WEAPON_RAYPISTOL       = true,
    WEAPON_RAYMINIGUN      = true,
    WEAPON_RAYCARBINE      = true,
    WEAPON_HOMINGLAUNCHER  = true,
    WEAPON_MINIGUN         = true,
    WEAPON_RPG             = true,
    WEAPON_GRENADELAUNCHER = true,
    WEAPON_GRENADELAUNCHER_SMOKE = true,
    WEAPON_FIREWORK        = true,
    WEAPON_BZGAS           = true,
    WEAPON_PROXMINE        = true,
    WEAPON_AIRSTRIKE_ROCKET = true,
    WEAPON_PASSENGER_ROCKET = true,
    WEAPON_VEHICLE_ROCKET   = true,
}

-- =========================================================================
--  Hash-lookups. joaat() is beschikbaar in shared scripts.
-- =========================================================================

---@type table<number, {name: string, damage: number, kind: 'handheld'|'vehicle'}>
Weapons.byHash = {}

for name, damage in pairs(Weapons.handheld) do
    Weapons.byHash[joaat(name)] = { name = name, damage = damage, kind = 'handheld' }
end

for name, damage in pairs(Weapons.vehicle) do
    Weapons.byHash[joaat(name)] = { name = name, damage = damage, kind = 'vehicle' }
end

---@type table<number, boolean>
Weapons.blacklistByHash = {}
for name in pairs(Weapons.blacklist) do
    Weapons.blacklistByHash[joaat(name)] = true
end

---Zoekt een wapen op hash.
---@param hash number
---@return {name: string, damage: number, kind: 'handheld'|'vehicle'}?
function Weapons.get(hash)
    return Weapons.byHash[hash]
end

---Maximaal toegestane schade voor dit wapen, inclusief tolerantie.
---Geeft nil als het wapen onbekend is: dan slaan we de schadecheck bewust over.
---@param hash number
---@return number?
function Weapons.maxDamage(hash)
    local weapon = Weapons.byHash[hash]
    if not weapon or weapon.damage == 0 then return end
    return weapon.damage * Weapons.tolerance
end

---Shared scripts delen globals, geen returnwaarden. Zonder deze regel is de tabel
---niet bereikbaar vanuit server/modules/damage.lua.
WeaponData = Weapons

return Weapons

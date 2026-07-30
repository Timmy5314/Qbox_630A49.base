---Los Balos RP anti-cheat configuratie.
---
---ONTWERPUITGANGSPUNT: dit is een server-side autoriteitslaag, geen client-detectie.
---Een betaald menu draait onder elke Lua-detectie die we hier kunnen schrijven. Wat
---hier staat kan een cheat niet omzeilen omdat het aan de serverkant beslist wordt:
---weaponDamageEvent, explosionEvent en entityCreating zijn de enige echt cancelbare
---security-events die FiveM biedt. De heuristieken (movement, health) zijn scoring,
---geen harde blokkade.

Config = {}

---Zet op true om ALLES alleen te loggen en nooit te kicken/bannen.
---Laat dit de eerste dagen aan staan. Zonder echte speeldata kicken we op dag een
---eerlijke spelers eruit op false positives.
Config.dryRun = true

---Print elke flag ook naar de serverconsole.
Config.verbose = true

---Discord webhook voor flags. Leeg = uit. Zet dit NIET in git; gebruik een convar.
---  set los_anticheat:webhook "https://discord.com/api/webhooks/..."
Config.webhookConvar = 'los_anticheat:webhook'

---Ace permission die toegang geeft tot het review-menu (/acflags).
Config.adminAce = 'group.admin'

-- =========================================================================
--  SCORING
-- =========================================================================
-- Elke detectie levert punten op. Punten vervallen langzaam, zodat een speler
-- die een half jaar geleden een keer door een sync-hik werd geflagd niet
-- alsnog gebanned wordt.

Config.score = {
    ---Punten die per minuut vervallen.
    decayPerMinute = 2,

    ---Drempels. Wordt van hoog naar laag geevalueerd; eerste match wint.
    thresholds = {
        { points = 100, action = 'ban',  banMinutes = 0 },  -- 0 = permanent
        { points = 60,  action = 'kick' },
        { points = 30,  action = 'warn' },                  -- alleen admins zien dit
    },
}

---Gewicht per detectietype. Verlaag een waarde naar 0 om een check uit te zetten
---zonder code te wijzigen.
---
---Toelichting bij de lage gewichten: threadMismatch, kvpTamper en resourceCount
---zijn client-gerapporteerde signalen. Een executor bepaalt zelf wat hij
---rapporteert, dus deze zijn per definitie te vervalsen. Ze staan er alleen in
---omdat ze gratis meeliften op de heartbeat en soms een amateur vangen. Ze mogen
---nooit zwaar genoeg wegen om alleen een kick te veroorzaken.
Config.weights = {
    -- Hard bewijs: server heeft de actie zelf geweigerd.
    damageOverride      = 60,   -- overrideDefaultDamage = true, dit is een damage modifier
    damageTooHigh       = 40,   -- meer schade dan het wapen maximaal kan doen
    weaponNotOwned      = 45,   -- schoot met een wapen dat niet in de inventory zit
    blacklistedWeapon   = 80,   -- wapen dat op deze server niet bestaat
    explosionBlocked    = 50,   -- explosietype dat geen enkel script gebruikt
    illegalEntitySpawn  = 35,   -- client spawnde een voertuig zonder server-registratie
    restrictedItem      = 55,   -- bezit van een item dat op deze server niet uitgegeven wordt
    ammoSync            = 40,   -- bleef vuren zonder munitie te verbruiken
    moneyJump           = 35,   -- geldsprong zonder aangemelde bron

    -- Sterke heuristiek: server meet zelf, maar sync kan liegen.
    teleport            = 25,
    speedHack           = 20,
    healthRegen         = 30,
    armorRegen          = 30,
    godmode             = 45,

    -- Zwakke signalen, client-gerapporteerd. Bewust laag.
    eventSpam           = 10,
    heartbeatMissing    = 5,
    threadMismatch      = 2,
    resourceCount       = 2,
    kvpTamper           = 2,
}

-- =========================================================================
--  MOVEMENT
-- =========================================================================

Config.movement = {
    ---Interval (ms) waarop de server posities bemonstert.
    ---Lager = gevoeliger, maar duurder. 3000ms is genoeg om teleports te zien.
    interval = 3000,

    ---Afstand (m) in een enkel interval die als teleport telt.
    ---Bewust ruim: een vliegtuig op topsnelheid haalt ~150 m/s.
    maxDistancePerTick = 600.0,

    ---Maximale snelheid (m/s) te voet. Sprinten is ~7 m/s.
    maxFootSpeed = 12.0,

    ---Zones waar teleport legitiem is (interiors, apartementen, jail).
    ---Binnen deze straal wordt movement niet gescoord.
    ignoreZones = {
        vec4(0.0, 0.0, 0.0, 25.0),          -- wereldnulpunt: interior-laadmoment
        vec4(1855.0, 2585.0, 45.0, 120.0),  -- Bolingbroke / xt-prison
    },

    ---Seconden na spawn/respawn/teleport-by-script waarin niet gescoord wordt.
    graceSeconds = 12,
}

-- =========================================================================
--  HEALTH / ARMOR
-- =========================================================================

Config.health = {
    interval = 5000,

    ---Health die per interval mag stijgen zonder bron. Bandages en de
    ---ND_Ambulance revive gaan hier ruim overheen, dus die melden zichzelf via
    ---de export los_anticheat:ExpectHeal (zie README).
    maxRegenPerTick = 25,

    ---Armor die per interval mag stijgen zonder dat er een vest-item gebruikt is.
    maxArmorGainPerTick = 5,

    ---Aantal opeenvolgende metingen waarin een speler schade opliep maar de
    ---health niet daalde, voordat godmode wordt gescoord.
    godmodeSamples = 4,
}

-- =========================================================================
--  ENTITY / VOERTUIGEN
-- =========================================================================

Config.entities = {
    ---Blokkeer voertuigen die door een client worden aangemaakt zonder dat een
    ---server-side script ze heeft aangemeld.
    ---
    ---LET OP: zet dit pas op true nadat je alle spawn-paden hebt omgezet naar
    ---qbx_core:SpawnVehicle of los_anticheat:RegisterSpawn. renzu_garage,
    ---renzu_vehicleshop en md-drugs spawnen op dit moment nog client-side.
    ---Op true zonder die omzetting kun je geen auto meer uit de garage halen.
    blockUnregisteredVehicles = false,

    ---Modellen die nooit door een speler gespawnd mogen worden, ook niet via
    ---een script. Hash of modelnaam.
    blacklistedModels = {
        'rhino', 'khanjali', 'hydra', 'lazer', 'savage', 'valkyrie',
        'akula', 'annihilator', 'cargoplane', 'jet', 'titan',
    },

    ---Seconden dat een server-registratie geldig blijft voordat hij vervalt.
    registrationTtl = 20,
}

-- =========================================================================
--  EXPLOSIES
-- =========================================================================

---Explosietypes die op deze server door geen enkel script gebruikt worden.
---Nummers: https://docs.fivem.net/natives/?_0xE3AD2BDBAEE269AC
Config.blockedExplosions = {
    [2] = true,   -- STICKYBOMB via exploit
    [4] = true,   -- ROCKET
    [7] = true,   -- TANKSHELL
    [8] = true,   -- HI_OCTANE
    [22] = true,  -- BOMB_STANDARD (vliegtuigbom)
    [24] = true,  -- BOMB_WATER
    [30] = true,  -- BOMB_CLUSTER
    [33] = true,  -- BOMB_GAS
    [34] = true,  -- BOMB_INCENDIARY
    [35] = true,  -- BOMB_STANDARD_WIDE
}

-- =========================================================================
--  EVENT RATE LIMITING
-- =========================================================================

Config.events = {
    ---Standaard: hoeveel keer per venster een speler hetzelfde net event mag
    ---triggeren voordat het als spam telt.
    defaultLimit = 20,
    windowMs = 10000,

    ---Uitzonderingen. Events die legitiem vaak vuren.
    limits = {
        ['ox_inventory:updateWeapon'] = 200,
        ['ox_inventory:requestOpenInventory'] = 60,
        ['ps-dispatch:server:notify'] = 40,
        ['qbx_core:server:onPlayerLoaded'] = 5,
    },

    ---Events die we bewust niet bemonsteren (te hoge frequentie, geen risico).
    ignore = {
        ['__cfx_internal:httpResponse'] = true,
        ['playerPing'] = true,
    },
}

-- =========================================================================
--  HEARTBEAT
-- =========================================================================

Config.heartbeat = {
    ---Interval (ms) waarop de client zijn state meldt.
    interval = 15000,

    ---Zoveel gemiste heartbeats voordat er gescoord wordt. Een laadscherm,
    ---een interior-transitie of pakketverlies kost er makkelijk een.
    missedBeforeFlag = 4,
}

return Config

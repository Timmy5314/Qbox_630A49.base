---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - turf wars

    How a war works:
      1. At a scheduled hour (or via /startturf) a war opens on one territory.
      2. Any gang member standing on the capture point earns points for their gang.
      3. If a member of a different gang is inside `contestRadius` of the capture
         point, the point is CONTESTED and nobody scores until one side is alone.
      4. When the timer runs out the gang with the most points owns the territory
         until the next war on that territory.
      5. The owning gang can open the vault once per war for the reward, plus they
         get the turf stash, turf garage and turf wardrobe.
]]

Config.TurfWar = {
    enabled = true,

    --- How long a war lasts, in seconds.
    duration = 1800,

    --- Radius of the capture point itself. Stand inside it to score.
    captureRadius = 4.0,

    --- Enemies within this distance of the capture point block all scoring.
    contestRadius = 25.0,

    --- Points earned per second by each gang member standing on the point.
    --- Multiple members of the same gang stack, capped by `maxStack`.
    pointsPerSecond = 1,
    maxStack = 3,

    --- Jobs that may never take part in a turf war.
    blacklistedJobs = {
        ['police']    = true,
        ['ambulance'] = true,
        ['mechanic']  = true,
        ['unemployed']= true,
    },

    --- Announce the remaining time to everybody every N seconds. 0 disables.
    announceInterval = 300,

    --- Announce a lead change (with a cooldown so it cannot be spammed).
    announceLeadChange = true,
    leadChangeCooldown = 30,

    --- Die inside a war zone and you respawn just outside it after this delay.
    respawn = {
        enabled = true,
        delay   = 15,   -- seconds before you are moved
        offset  = 120.0, -- how far outside the zone you land
    },

    --- Blip drawn for an active war.
    activeBlip = {
        sprite = 310,
        color  = 1,
        alpha  = 80,
        scale  = 1.0,
    },

    --- Seconds a gang must wait before it can claim the vault again.
    vaultCooldown = 3600,
}

--- Blip colour per owning gang. Falls back to 0 (white).
Config.TurfColors = {
    ['ballas'] = 27, -- purple
    ['triads'] = 2,  -- green
    ['lostmc'] = 6,  -- red
    ['families']= 25, -- green
    ['vagos']  = 5,  -- yellow
    ['marabunta'] = 3,  -- blue
    ['mafia']  = 40, -- dark grey
}

--[[
    LET OP - er zijn maar drie turfs gedefinieerd (ballas, triads, lostmc).
    families, vagos, marabunta en mafia hebben er nog geen.

    Een turf toevoegen vraagt vijf opgemeten coordinaten: zone, capture, vault,
    stash, wardrobe en garage (met spawnpunt). Die zijn niet uit de code of uit
    een repo te halen, alleen in-game op te meten. Gok je ze, dan komt de kluis
    in een muur te staan.

    Wil je turfs voor de overige gangs: loop de plek in-game af, noteer de
    coordinaten en kopieer het ballas-blok hieronder. De rest van het systeem
    (oorlogen, scores, blips, beloningen) werkt dan meteen mee.
]]

Config.Turfs = {

    ['ballas'] = {
        label    = 'Forum Drive',
        schedule = { 16 }, -- 16:00 server time

        zone = {
            coord  = vec3(-2.65, -1822.13, 29.54),
            radius = 200.0,
        },

        --- The point that actually has to be held.
        capture = vec3(4.34, -1816.15, 29.15),

        --- Interaction points that only the owner may use.
        points = {
            vault = {
                label = 'Open Vault',
                coord = vec3(-1.55, -1811.77, 29.15),
                type  = 'vault',
            },
            stash = {
                label = 'Turf Stash',
                coord = vec3(2.59, -1818.27, 29.15),
                type  = 'stash',
                slots = 100,
                weight = 2000000,
            },
            wardrobe = {
                label = 'Wardrobe',
                coord = vec3(-2.65, -1822.13, 29.54),
                type  = 'wardrobe',
            },
            garage = {
                label = 'Turf Garage',
                coord = vec3(18.04, -1820.95, 24.93),
                type  = 'garage',
                spawn = vec4(9.06, -1829.44, 24.26, 53.12),
            },
        },

        reward = function()
            return {
                { item = 'black_money',      amount = math.random(50000, 250000) },
                { item = 'WEAPON_PISTOL50',  amount = math.random(1, 5) },
                { item = 'WEAPON_COMBATPDW', amount = math.random(1, 3) },
            }
        end,
    },

    ['triads'] = {
        label    = 'Little Seoul',
        schedule = { 22 },

        zone = {
            coord  = vec3(-651.07, -1235.50, 10.55),
            radius = 200.0,
        },

        capture = vec3(-652.87, -1227.10, 11.41),

        points = {
            vault = {
                label = 'Open Vault',
                coord = vec3(-644.42, -1244.62, 11.99),
                type  = 'vault',
            },
            stash = {
                label = 'Turf Stash',
                coord = vec3(-653.27, -1230.42, 11.97),
                type  = 'stash',
                slots = 100,
                weight = 2000000,
            },
            wardrobe = {
                label = 'Wardrobe',
                coord = vec3(-644.57, -1240.74, 10.55),
                type  = 'wardrobe',
            },
            garage = {
                label = 'Turf Garage',
                coord = vec3(-639.03, -1216.97, 10.76),
                type  = 'garage',
                spawn = vec4(-645.62, -1214.71, 10.75, 307.67),
            },
        },

        reward = function()
            return {
                { item = 'black_money',         amount = math.random(50000, 250000) },
                { item = 'WEAPON_ASSAULTRIFLE', amount = math.random(1, 3) },
                { item = 'WEAPON_PISTOL50',     amount = math.random(1, 5) },
            }
        end,
    },

    ['lostmc'] = {
        label    = 'Mirror Park Clubhouse',
        schedule = { 10 },

        zone = {
            coord  = vec3(980.27, -100.72, 75.27),
            radius = 200.0,
        },

        capture = vec3(985.09, -89.70, 74.21),

        points = {
            vault = {
                label = 'Open Vault',
                coord = vec3(977.24, -104.55, 75.04),
                type  = 'vault',
            },
            stash = {
                label = 'Turf Stash',
                coord = vec3(987.21, -93.18, 74.17),
                type  = 'stash',
                slots = 100,
                weight = 2000000,
            },
            wardrobe = {
                label = 'Wardrobe',
                coord = vec3(971.17, -98.62, 74.74),
                type  = 'wardrobe',
            },
            garage = {
                label = 'Turf Garage',
                coord = vec3(969.64, -114.96, 73.35),
                type  = 'garage',
                spawn = vec4(956.90, -134.17, 73.87, 331.28),
            },
        },

        reward = function()
            return {
                { item = 'black_money',        amount = math.random(50000, 250000) },
                { item = 'WEAPON_HEAVYPISTOL', amount = math.random(1, 5) },
                { item = 'WEAPON_PISTOL50',    amount = math.random(1, 5) },
            }
        end,
    },
}

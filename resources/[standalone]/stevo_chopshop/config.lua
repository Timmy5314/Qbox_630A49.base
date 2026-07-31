return {
    locale = 'en',
    interaction = 'target', -- 'target' or 'textui'

    -- Expliciet vastgezet in plaats van 'auto'. Deze server draait ox_target en
    -- ox_lib, en met 'auto' bepaalde de opstartvolgorde welke tak won. De
    -- qb-target- en ps-ui-fallbacks in bridge/editable_client.lua zijn daarmee
    -- onbereikbaar per config in plaats van per toeval.
    target = 'ox_target',
    textUI = 'ox_lib',
    notify = 'ox_lib',

    dropCheaters = true, -- If cheaters should be dropped/kicked from the server for exploiting events

    globalCooldown = 5, -- Time in minutes for global cooldown (Set to false for no cooldown)

    -- Aantal agenten ON DUTY dat nodig is om te mogen slopen. 0 = geen eis.
    --
    -- Was `false`, en resource/server.lua las bovendien `config.policeRequirement`
    -- - een naam die nergens bestaat. Daardoor sloeg de check altijd over en
    -- werkte de eis nooit. Nu een getal, en de servercode leest de juiste naam.
    policeRequired = 0,
    policeJob = 'police',

    policeDispatch = function(ped, vehicle)
        -- Stond volledig uitgecommentarieerd, dus een chopshop-melding kwam
        -- nooit binnen bij de politie.
        --
        -- Bewust CustomAlert en niet VehicleTheft: die laatste neemt geen
        -- argumenten en leest cache.vehicle, oftewel de auto waar je IN zit.
        -- Bij een chopshop sta je ernaast, dus dat is nil.
        if GetResourceState('ps-dispatch') ~= 'started' then return end

        exports['ps-dispatch']:CustomAlert({
            coords = GetEntityCoords(ped),
            message = 'Chop shop activity',
            dispatchCode = 'chopshop',
            code = '10-35',
            icon = 'fas fa-car-burst',
            priority = 2,
            radius = 0,
            sprite = 227,
            color = 1,
            scale = 1.0,
            length = 3,
            -- ps-dispatch matcht op job TYPE, niet op jobnaam:
            -- client/main.lua doet lib.table.contains(data.jobs, PlayerData.job.type).
            -- police, bcso en sasp hebben allemaal type 'leo' in qbx_core.
            jobs = { 'leo' },
        })
    end,

    chopShops = {
        lsia = {
            securityCoords = vec3(-425.2410, -1687.6906, 19.0291), -- Put in the middle of the chopping zone
            blip = false,
            zonePoints = {
                vec3(-426.0, -1674.0, 19),
                vec3(-434.0, -1697.0, 19),
                vec3(-423.0, -1700.0, 19),
                vec3(-411.0, -1680.0, 19)
            }
        },
        sandy = {
            securityCoords = vec3(2340.4993, 3052.4824, 48.1473), -- Put in the middle of the chopping zone
            blip = {
                coords = vec3(2340.4993, 3052.4824, 48.1473),
                sprite = 225, -- https://docs.fivem.net/docs/game-references/blips/#blips
                color = 59, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
                scale = 0.8, -- float
                name = 'Chop Shop'

            }, zonePoints = {
                vec3(2343.0, 3049.0, 48.0),
                vec3(2338.0, 3049.0, 48.0),
                vec3(2337.0, 3058.0, 48.0),
                vec3(2344.0, 3059.0, 48.0),
            }
        }
    },

    blockedVehicleTypes = { -- Its advised you dont change this unless you know what your doing. (Removing it may break the script as bikes cannot be chopped)
        'bike',
        'heli',
        'boat'
    },

    rewards = { -- Add rewards for each part.

        ["stevo_chopshop:1"] = { -- Bonnet
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 250, max = 450},
        },

        ["stevo_chopshop:2"] = { -- Front dri Door
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 200, max = 350},
        },

        ["stevo_chopshop:3"] = { -- Front pas door
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 200, max = 350},
        },

        ["stevo_chopshop:4"] = { -- Back dri Door
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 200, max = 350},
        },

        ["stevo_chopshop:5"] = { -- Back pas Door
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 200, max = 350},
        },

        ["stevo_chopshop:6"] = { -- Boot
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 250, max = 450},
        },

        ["stevo_chopshop:7"] = { -- Front dri wheel
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 150, max = 275},
        },

        ["stevo_chopshop:8"] = { -- Front pas wheel
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 150, max = 275},
        },

        ["stevo_chopshop:9"] = {-- Back dri wheel
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 150, max = 275},
        },

        ["stevo_chopshop:10"] = {-- Back pas wheel
            {item = 'plastic', amount = 1},
            {item = 'black_money', min = 150, max = 275},
        },

        ["stevo_chopshop:11"] = { -- Whole chassis
            {item = 'plastic', amount = 1},
            {item = 'steel', amount = 1},
            {item = 'black_money', min = 1500, max = 2800},
        },

    },

    skillchecks = {
        ["stevo_chopshop:1"] = {'easy', 'easy'}, -- Bonnet
        ["stevo_chopshop:2"] = {'easy', 'easy'}, -- Front dri Door
        ["stevo_chopshop:3"] = {'easy', 'easy'}, -- Front pas Door
        ["stevo_chopshop:4"] = {'easy', 'easy'}, -- Back dri Door
        ["stevo_chopshop:5"] = {'easy', 'easy'}, -- Back pas Door
        ["stevo_chopshop:6"] = {'easy', 'easy'}, -- Boot
        ["stevo_chopshop:7"] = {'easy', 'easy'}, -- Front dri wheel
        ["stevo_chopshop:8"] = {'easy', 'easy'}, -- Front pas wheel
        ["stevo_chopshop:9"] = {'easy', 'easy'}, -- Back dri wheel
        ["stevo_chopshop:10"] = {'easy', 'easy'}, -- Back pas wheel
        ["stevo_chopshop:11"] = {'easy', 'easy'}, -- Whole chassis
    },

    
    duration = {
        ["stevo_chopshop:1"] = 2000, -- Bonnet
        ["stevo_chopshop:2"] = 3000, -- Front dri Door
        ["stevo_chopshop:3"] = 3000, -- Front pas Door
        ["stevo_chopshop:4"] = 3000, -- Back dri Door
        ["stevo_chopshop:5"] = 3000, -- Back pas Door
        ["stevo_chopshop:6"] = 2000, -- Boot
        ["stevo_chopshop:7"] = 2500, -- Front dri wheel
        ["stevo_chopshop:8"] = 2500, -- Front pas wheel
        ["stevo_chopshop:9"] = 2500, -- Back dri wheel
        ["stevo_chopshop:10"] = 2500, -- Back pas wheel
        ["stevo_chopshop:11"] = 5000, -- Whole chassis
    },

    debug = false, -- Enabling debug prints and zones.
    
}
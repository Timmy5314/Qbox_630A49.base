--[[
    s4t4n667_elevators - Qbox-versie voor Los Balos RP.

    Wat er in het origineel kapot was en hier gefixt is:
      1. `config.travelTime` bestond niet; de waarde staat onder
         `settings.travelTime`. lib.progressBar kreeg duration = nil.
      2. `coords` mocht vector3 of vec4 zijn, maar de code las altijd
         `coords.w`. Bij de Mission Row-verdiepingen (vector3 + los `heading`
         veld) was dat nil en brak het neerzetten van de speler.
      3. exports["qb-core"]:GetCoreObject() - die resource draait hier niet.
      4. InteractSound_SV:PlayWithinDistance - die resource staat niet op deze
         server, dus dat event ging nergens heen.
      5. Job- en item-sloten werden alleen client-side gecontroleerd.

    Coordinaten mogen nu vec3 met los `heading`, of vec4. Beide werken.
]]

return {
    debug = false,

    settings = {
        targetDistance = 2.0,
        targetIcon = 'fa-solid fa-bell',
        travelTime = 2000,

        -- Emote tijdens het indrukken. Leeg laten = geen emote.
        -- scully_emotemenu levert /e. Zet op '' als je dat niet wilt.
        animation = 'atm',
    },

    elevators = {
        ['Mission Row Police Station'] = {
            {
                floorTitle = 'Ground Floor',
                label = 'Access the ground floor.',
                coords = vec3(463.72, -985.37, 34.3),
                heading = 87.83,
                joblock = { police = 0 },
            },
            {
                floorTitle = 'Helipad',
                label = 'Access the helicopter pad.',
                coords = vec3(468.49, -983.95, 43.69),
                heading = 91.48,
                joblock = { police = 0 },
            },
        },

        ['Mount Zonah Hospital'] = {
            {
                floorTitle = 'Main Floor',
                label = 'Access the main hospital floor.',
                icon = 'fa-solid fa-hospital',
                coords = vec4(-436.0963, -359.8023, 34.9475, 356.0672),
            },
            {
                floorTitle = 'Car Park',
                label = 'Access the hospital car park.',
                icon = 'fa-solid fa-car',
                coords = vec4(-418.9, -344.81, 24.23, 106.67),
            },
        },

        -- ── Appartementstorens ───────────────────────────────────────────
        -- Coordinaten uit qbx_properties (config/shared.lua). Die resource
        -- draait hier niet meer, maar de appartementsdata klopt: elk
        -- appartement heeft een entry op straatniveau en een exit op de
        -- verdieping. Dat zijn precies de twee haltes van een lift.
        --
        -- LET OP: de hoge coordinaten komen uit de appartementdefinitie, niet
        -- uit een opgemeten liftbordes. Controleer in-game of je op de gang
        -- uitkomt en niet in iemands woonkamer. Dat kan ik niet zien.
        ['Del Perro Heights'] = {
            {
                floorTitle = 'Lobby',
                label = 'Ground floor.',
                icon = 'fa-solid fa-door-open',
                coords = vec3(-1447.35, -537.84, 34.74),
                heading = 125.0,
            },
            {
                floorTitle = 'Floor 4',
                label = 'Apartment 7.',
                coords = vec3(-1458.5, -520.89, 56.93),
                heading = 35.0,
            },
            {
                floorTitle = 'Floor 7',
                label = 'Apartment 4.',
                coords = vec4(-1453.02, -539.5, 74.04, 35.33),
            },
        },

        ['4 Integrity Way'] = {
            {
                floorTitle = 'Lobby',
                label = 'Ground floor.',
                icon = 'fa-solid fa-door-open',
                coords = vec3(-59.4, -616.29, 37.36),
                heading = 250.0,
            },
            {
                floorTitle = 'Floor 28',
                label = 'Apartment 28.',
                coords = vec4(-30.58, -595.4, 80.03, 246.95),
            },
            {
                floorTitle = 'Floor 30',
                label = 'Apartment 30.',
                coords = vec4(-17.41, -588.17, 90.11, 338.23),
            },
        },

        ['Richard Majestic'] = {
            {
                floorTitle = 'Lobby',
                label = 'Ground floor.',
                icon = 'fa-solid fa-door-open',
                coords = vec3(-936.15, -378.91, 38.96),
                heading = 115.0,
            },
            {
                floorTitle = 'Apartment 2',
                label = 'Top floor.',
                coords = vec4(-913.99, -365.81, 114.27, 115.17),
            },
        },

        ['Tinsel Towers'] = {
            {
                floorTitle = 'Lobby',
                label = 'Ground floor.',
                icon = 'fa-solid fa-door-open',
                coords = vec3(-614.58, 46.52, 43.59),
                heading = 91.0,
            },
            {
                floorTitle = 'Apartment 42',
                label = 'Top floor.',
                coords = vec4(-604.06, 58.99, 98.2, 91.45),
            },
        },
    },

    -- ── ps-housing appartementen ─────────────────────────────────────────
    -- LET OP: de torens hierboven (Del Perro Heights, 4 Integrity Way,
    -- Richard Majestic, Tinsel Towers) komen uit qbx_properties en staan LOS
    -- van ps-housing. Ze werken ook als ps-housing niet draait.
    --
    -- ps-housing gebruikt op deze server heel andere gebouwen: Integrity Way
    -- op (269.73, -640.75, 42.02), South Rockford Drive, Morningwood Blvd.
    -- Dat zijn niet dezelfde panden als de qbx_properties-appartementen, dus
    -- die coordinaten zijn hier niet te hergebruiken.
    --
    -- Wil je ook liften bij de ps-housing panden, vul dan `floors` hieronder
    -- en zet enabled op true. De structuur is identiek aan `elevators`.
    psHousing = {
        enabled = false,
        floors = {},
    },
}

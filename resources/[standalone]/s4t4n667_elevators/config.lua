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

        -- ── APPARTEMENTSTOREN-LIFTEN VERWIJDERD (aug 2026) ──────────────────
        -- Del Perro Heights, 4 Integrity Way, Richard Majestic en Tinsel Towers
        -- kwamen uit qbx_properties en gaven IEDEREEN via ox_target een gratis lift
        -- naar appartementverdiepingen - los van eigendom. Dat was precies de
        -- "ik kan met de lift naar een appartement dat ik niet bezit"-bug.
        -- ps-housing regelt de toegang tot zijn eigen panden zelf (ox_target ->
        -- teleport, alleen voor de eigenaar/keyholder), dus deze losse liften
        -- moesten weg. Alleen de publieke/utility-liften (Mission Row Police
        -- Station, Mount Zonah Hospital) hierboven blijven. Wil je later liften bij
        -- de ECHTE ps-housing-panden, gebruik dan de psHousing-sectie hieronder.
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

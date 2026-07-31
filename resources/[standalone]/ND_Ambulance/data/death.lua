return {
    timer = 300, -- time in seconds.
    keybind = "R", -- respawn keybind.
    dropInventory = true, -- drop player items when respawn.
    damage = 2, -- amount of damage that will be taken every damageInterval when knocked down injured (Must be a whole number).
    damageInterval = 4, -- interavall in seconds player will take damage when knocked down injured.
    prices = {
        selfHeal = 2000,
        otherHeal = 3000,

        -- Ontbrak, terwijl client/main.lua en server/main.lua hem op vijf
        -- plekken gebruiken. Gevolg: het scherm toonde "for $nil" en de
        -- server sloeg het afschrijven over (`if price and price > 0`),
        -- waardoor respawnen gratis was.
        --
        -- Bewust stevig: respawnen hoort de dure uitweg te zijn, wachten op
        -- EMS de goedkope.
        respawn = 5000
    },

    --[[
        AI-DOKTER

        De dokter-peds in het ziekenhuis konden altijd al iemand oplappen en
        zelfs reviven. Dat ondermijnt de EMS-job: waarom zou je op een
        ambulance wachten als de NPC het ook doet?

        Met aiDoctor.requireNoEms aan mag de NPC alleen nog REVIVEN als er nul
        EMS on duty is. Levende spelers oplappen blijft gewoon mogelijk - dat is
        een doktersbezoek, geen reanimatie.
    ]]
    aiDoctor = {
        requireNoEms = true,

        -- Jobs die als EMS tellen. Namen uit qbx_core/shared/jobs.lua.
        emsJobs = {"ambulance"},
    },
    
    -- locations player will respawn if they get respawned at mourge.
    mourgeRespawn = {
        vec4(358.4108, -593.1266, 43.2835, 347.0706),
        vec4(355.1182, -591.4466, 43.2843, 332.8464),
        vec4(352.0425, -591.1185, 43.2843, 342.0975)
    },

    -- doctor peds for hospitals.
    hospitalPeds = {  
        vec4(306.6618, -597.3710, 43.2611, 24.0384), 
        vec4(343.8627, -583.6595, 28.7475, 4.8358)
    },

    hospitalRespawns = {
        vec4(349.3248, -584.9066, 43.2843, 175.4754), 
        vec4(353.1953, -585.7901, 43.2843, 146.8586),
        vec4(356.7096, -587.0601, 43.2843, 165.6794)
    }
}

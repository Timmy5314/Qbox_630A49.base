--[[
    los_aidoctor - een AI-ambulance die naar je toe komt.

    Concept van hh_aidoc, opnieuw gebouwd voor deze server. Het origineel is
    QBCore, gebruikt een eigen death-systeem en kent ps-dispatch niet.

    HOE HET LOOPT
      1. Speler gaat neer en stuurt een noodsignaal (G in ND_Ambulance).
      2. Zijn er medics on duty, dan gebeurt hier niets - die krijgen de melding
         via ps-dispatch en het is aan hen.
      3. Is er niemand, dan rijdt er na `responseDelay` een ambulance uit het
         dichtstbijzijnde ziekenhuis naar de speler.
      4. De dokter stapt uit, loopt naar de speler, reanimeert hem.
      5. De rekening gaat naar de verzekering. Is die er niet, dan betaalt de
         speler zelf - en duurder.

    DE ZIEKENHUIS-NPC BLIJFT LOSSTAAN
    Wie zelf naar het ziekenhuis weet te komen wordt daar altijd geholpen,
    ongeacht hoeveel EMS online is. Dat zit in ND_Ambulance en daar raakt deze
    resource niet aan.
]]

Config = {}

Config.debug = false

--- Jobs die als EMS tellen. Is er hiervan iemand on duty, dan komt de AI niet.
Config.emsJobs = { 'ambulance' }

--- Seconden tussen het noodsignaal en het uitrijden van de ambulance.
--- Bewust geen nul: het hoort te voelen als wachten op hulp.
Config.responseDelay = 25

--- Seconden waarna een rit wordt afgebroken als de ambulance er niet komt
--- (vast in het verkeer, speler verplaatst, wat dan ook).
Config.rideTimeout = 180

--- Hoe dicht de ambulance moet zijn voordat de dokter uitstapt.
Config.arriveDistance = 12.0

--- Hoe dicht de dokter bij de speler moet staan om te reanimeren.
Config.treatDistance = 2.5

--- Zo dicht bij het wegknooppunt naast de speler telt ook als aangekomen. Naar
--- een speler die binnen of naast de weg ligt bestaat geen autoroute; de dokter
--- parkeert dan zo dichtbij als het wegennet toelaat en loopt het laatste stuk.
Config.nodeArriveDistance = 12.0

--- Zoveel meter mag de speler verplaatst worden voordat de ambulance een nieuwe
--- rijopdracht krijgt (brancard, gedragen worden).
Config.retaskDistance = 30.0

--- Staat de ambulance zo lang stil, dan krijgt hij een nieuwe rijopdracht.
Config.stuckSeconds = 8

--- Eén rit tegelijk per server. Meerdere AI-ambulances door elkaar wordt rommelig.
Config.oneAtATime = true

Config.models = {
    vehicle = `ambulance`,
    doctor  = `s_m_m_paramedic_01`,
}

--- Ziekenhuizen waar de ambulance vandaan komt. De dichtstbijzijnde wint.
--- Coordinaten uit ND_Ambulance/data/death.lua (hospitalPeds), dus geldig.
Config.stations = {
    vec4(306.6618, -597.3710, 43.2611, 24.0384),
    vec4(343.8627, -583.6595, 28.7475, 4.8358),
}

-- ── Kosten ───────────────────────────────────────────────────────────────
Config.billing = {
    -- Eigen bijdrage voor een verzekerde speler. 0 = de rit is gratis, de
    -- verzekeraar betaalt alles.
    insured = 0,

    -- Wat het kost zonder verzekering. Komt rechtstreeks bij de speler terecht.
    uninsured = 750,

    -- Rekening op de bank in plaats van contant.
    account = 'bank',

    --[[
        Verzekering.

        De verzekeringsresource bestaat nog niet; die staat verderop in de
        planning. Tot die tijd geldt iedereen als onverzekerd en betaalt de
        speler zelf.

        Zodra hij er is hoeft alleen `resource` te kloppen. Verwacht wordt een
        server-export:

            exports[resource]:hasMedicalInsurance(src) -> boolean
            exports[resource]:claimMedical(src, amount) -> boolean

        Levert claimMedical false op, dan valt het terug op de speler.
    ]]
    insurance = {
        resource = 'los_insurance',
        enabled = true,
    },
}

-- ox_lib require geeft de returnwaarde van dit bestand terug. Zonder deze
-- regel krijgt `local config = require "shared.config"` de boolean true, en
-- crasht de eerste `config.<iets>` met "attempt to index a boolean value".
return Config

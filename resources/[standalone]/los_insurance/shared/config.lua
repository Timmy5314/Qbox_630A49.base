--[[
    los_insurance - zorg- en autoverzekering voor Los Balos RP.

    Concept van Muhaddil/muhaddil_insurance, opnieuw gebouwd. Dat origineel doet
    alleen zorgverzekering, draait op een ander framework en kent ps-mdt niet.

    WAT DIT LEVERT
      - zorgverzekering: ND_Ambulance en los_aidoctor rekenen ermee af
      - autoverzekering: per kenteken, gekoppeld aan player_vehicles
      - politie kan beide controleren via een radial menu en via ps-mdt
      - onverzekerde spelers krijgen periodiek een SMS van de overheid

    De verzekeraar is een NPC. Polissen lopen af en moeten verlengd worden;
    daar zit de terugkerende kostenpost.
]]

Config = {}

Config.debug = false

--- Rekening waarvan premies worden afgeschreven.
Config.account = 'bank'

--[[
    Polissen.

    GEEN BEDRAG INEENS MEER. Je sluit een polis af en de premie wordt daarna bij
    elke loonuitbetaling ingehouden, net als in het echt. Zolang je betaalt loop
    je door; stopt de betaling, dan verloopt de polis vanzelf.

    qbx_core betaalt elke `paycheckTimeout` minuten uit (standaard 10). De
    lonen op deze server liggen tussen $50 en $150 per uitbetaling, met een
    enkele uitschieter naar $500.

    De bedragen hieronder zijn VASTE bedragen per loonstrook, geen percentages.
    Bij een gemiddeld loon van $100 komt dat neer op ongeveer 20% voor beide
    verzekeringen samen, zoals gevraagd. Een vast bedrag is voorspelbaar: je
    weet wat je betaalt, ook als je die week meer verdient.

    Er wordt nooit meer ingehouden dan er binnenkomt - zie Config.deductions.
]]
Config.policies = {
    medical = {
        label = 'Medical insurance',
        premium = 12,
        description = 'Covers ambulance callouts and hospital treatment.',
    },

    vehicle = {
        label = 'Vehicle insurance',
        premium = 8,
        description = 'Covers recovery and repair costs for one vehicle.',

        -- Deel van de schade dat de verzekeraar dekt.
        coverage = 0.75,
    },
}

--[[
    Inhoudingen op het loon.

    Alles hieronder wordt afgeboekt zodra qbx_core een loonstrook heeft
    uitbetaald. De melding komt kort na de loonmelding, zodat je eerst ziet wat
    je verdient en daarna wat eraf gaat.

    RICHTLIJN bij een loon van $100 met een auto op naam:
        zorgverzekering      $12
        autoverzekering      $8
        inkomstenbelasting   $8   (8%)
        motorrijtuigenbel.   $3   per voertuig
        ------------------------------
        totaal               $31  oftewel ongeveer 30%

    HARDE GRENS: de inhouding is nooit hoger dan het loon zelf. Wie weinig
    verdient betaalt naar rato en houdt altijd iets over.
]]
Config.deductions = {
    enabled = true,

    -- Seconden na de loonmelding voordat de inhouding zichtbaar wordt.
    delaySeconds = 6,

    --[[
        Maximaal deel van het loon dat in totaal ingehouden mag worden.

        Vaste premies pakken laag inkomen relatief zwaarder: bij een loon van
        $50 zou de volle inhouding 54% zijn, bij $500 nog maar 13%. Dit plafond
        vangt de onderkant af. Op 0.35 betaalt niemand meer dan een derde:

            loon $50   ->  $17  (35%, afgetopt)
            loon $100  ->  $31  (31%)
            loon $150  ->  $35  (23%)
            loon $500  ->  $63  (13%)
    ]]
    maxShareOfPaycheck = 0.35,

    tax = {
        enabled = true,

        -- Percentage inkomstenbelasting over de loonstrook.
        incomeRate = 0.08,

        -- Vast bedrag per voertuig op naam, per loonstrook.
        perVehicle = 3,

        -- Voertuigbelasting alleen over de eerste zoveel auto's, zodat een
        -- verzamelaar niet onbetaalbaar uitkomt.
        maxVehiclesTaxed = 5,
    },
}

--[[
    Hoe lang een polis geldig blijft na een betaling.

    Elke ingehouden premie schuift de einddatum op met deze tijd. Met een
    loonstrook per 10 minuten en 3 uur speling loopt een werkende speler nooit
    tegen een verlopen polis aan, terwijl iemand die stopt met werken er na een
    paar uur uit valt.

    ECHTE UREN, geen in-game uren.
]]
Config.policyExtendHours = 3

-- ── Verzekeringskantoor ──────────────────────────────────────────────────
Config.office = {
    ped = `a_m_y_business_02`,
    coords = vec4(-806.31, -1128.28, 10.99, 130.0),
    scenario = 'WORLD_HUMAN_CLIPBOARD',

    blip = {
        enabled = true,
        sprite = 498,
        colour = 3,
        scale = 0.7,
        label = 'Insurance office',
    },
}

-- ── Politiecontrole ──────────────────────────────────────────────────────
Config.police = {
    -- Job types die mogen controleren. ps-dispatch en qbx werken met types,
    -- niet met jobnamen: police, bcso en sasp hebben allemaal type 'leo'.
    jobTypes = { 'leo' },

    -- Radial menu voor de agent.
    radial = {
        enabled = true,
        id = 'los_insurance_check',
        label = 'Check insurance',
        icon = 'file-shield',
    },
}

-- ── Waarschuwingen van de overheid ───────────────────────────────────────
-- Alle tijden hieronder zijn ECHTE tijd, geen in-game tijd.
Config.warnings = {
    enabled = true,

    -- Nummer waarvandaan de SMS komt.
    senderNumber = '1500',

    -- Minuten tussen twee rondes langs de online spelers.
    intervalMinutes = 15,

    -- Minimale tijd tussen twee berichten aan dezelfde speler, in uren.
    -- Op 1 krijgt een onverzekerde speler dus elk echt uur een herinnering.
    cooldownHours = 1,

    -- Speler moet minstens zo lang online zijn voordat hij iets krijgt, zodat
    -- iemand die net inlogt niet meteen een boodschap krijgt.
    minMinutesOnline = 10,
}

-- ox_lib require geeft de returnwaarde van dit bestand terug. Zonder deze
-- regel krijgt `local config = require "shared.config"` de boolean true, en
-- crasht de eerste `config.<iets>` met "attempt to index a boolean value".
return Config

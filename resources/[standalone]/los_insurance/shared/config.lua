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

    LOOPTIJD IS IN ECHTE DAGEN, geen in-game dagen. De code rekent met
    os.time() + days * 86400, dus dat is kloktijd. Een polis van 7 dagen loopt
    een echte week, ongeacht hoe vaak de in-game zon opkomt.

    PREMIE. Een verzekering hoort goedkoper te zijn dan waar hij tegen
    beschermt, anders sluit niemand hem af. Ter vergelijking op deze server:
        ziekenhuisbehandeling  $2000
        AI-dokter onverzekerd  $750
        respawnen              $1000
    Een weekpremie van een paar honderd is dan logisch: je bent na een of twee
    incidenten al uit de kosten.
]]
Config.policies = {
    medical = {
        label = 'Medical insurance',
        premium = 450,
        days = 7,
        description = 'Covers ambulance callouts and hospital treatment.',
    },

    vehicle = {
        label = 'Vehicle insurance',
        premium = 300,
        days = 7,
        description = 'Covers recovery and repair costs for one vehicle.',

        -- Deel van de schade dat de verzekeraar dekt.
        coverage = 0.75,
    },
}

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

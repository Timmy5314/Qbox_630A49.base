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

-- ── Polissen ─────────────────────────────────────────────────────────────
Config.policies = {
    medical = {
        label = 'Medical insurance',
        premium = 2500,

        -- Looptijd in dagen.
        days = 7,

        description = 'Covers ambulance callouts and hospital treatment.',
    },

    vehicle = {
        label = 'Vehicle insurance',
        premium = 1800,
        days = 7,
        description = 'Covers recovery and repair costs for one vehicle.',

        -- Percentage van de dagwaarde dat de verzekeraar dekt bij schade.
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
Config.warnings = {
    enabled = true,

    -- Nummer waarvandaan de SMS komt.
    senderNumber = '1500',

    -- Minuten tussen twee controles. Iedere onverzekerde speler die online is
    -- krijgt dan hooguit een bericht.
    intervalMinutes = 45,

    -- Niet vaker dan dit per speler, in uren. Anders wordt het spam.
    cooldownHours = 6,

    -- Speler moet minstens zo lang online zijn voordat hij iets krijgt.
    minMinutesOnline = 10,
}

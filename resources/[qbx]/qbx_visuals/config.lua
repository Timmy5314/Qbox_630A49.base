Config = {}

-- ===========================================================================
--  ALGEMEEN
-- ===========================================================================

Config.Enabled        = true        -- standaard aan voor nieuwe spelers
Config.DefaultPreset  = 'cinematic' -- zie Config.Presets
Config.DefaultProfile = 'auto'      -- ultra | balanced | performance | auto
Config.SavePreference = true        -- keuze per speler onthouden (KVP)

Config.Command  = 'gfx'             -- /gfx opent het menu
Config.Keybind  = ''                -- leeg = speler bindt zelf via instellingen

Config.UpdateInterval = 2000        -- ms tussen context-checks

-- ===========================================================================
--  FIRST PERSON
--
--  LEES DIT over de FOV, want hier zit een harde grens:
--
--  Er bestaat GEEN native om het blikveld van de gameplay-camera te zetten.
--  De natives-lijst heeft alleen GET_GAMEPLAY_CAM_FOV, geen SET. SetCamFov
--  werkt uitsluitend op een camera die je zelf met CreateCam hebt gemaakt.
--
--  Daarom kan een server de FOV niet afdwingen. De enige twee routes:
--
--  1. De client-instelling 'profile_fpsFieldOfView' (wat hieronder gebeurt).
--     Dat is de eigen instelling van de speler; wij zetten hem voor deze
--     sessie. Werkt, maar de speler kan hem zelf weer aanpassen.
--
--  2. Een eigen camera met CreateCam + SetCamFov. Dat geeft volledige
--     controle over de FOV, MAAR: het spel haalt dan je hoofd niet meer weg.
--     Dat is precies waarom je bij je huidige opzet je eigen gezicht in beeld
--     krijgt tijdens het rijden. Daarom doen we dat hier bewust niet.
--
--  Met het echte first-person standpunt hieronder verdwijnt dat gezicht dus
--  vanzelf: GTA verwijdert het hoofd zelf in die modus.
-- ===========================================================================

Config.FirstPerson = {
    enabled = true,

    -- ACE-namen uit je permissions.cfg. Wie hier aan voldoet mag vrij de
    -- camera wisselen. De controle gebeurt server-side.
    exemptAces = { 'admin', 'mod' },

    -- Per cameracontext. Zet er gerust een paar uit als first person daar
    -- onprettig is.
    contexts = {
        onFoot      = true,
        inVehicle   = true,
        onBike      = true,
        inBoat      = true,
        inAircraft  = true,
        inSubmarine = true,
        inHeli      = true,
        inTurret    = false, -- in een geschutskoepel is first person naar
    },

    -- Blokkeert de camera-wisseltoets. Zonder dit flitst de speler eerst
    -- even naar derde persoon voor wij hem terugzetten.
    blockViewToggle = true,

    -- Hoe vaak het standpunt opnieuw wordt bevestigd (ms).
    enforceInterval = 1000,

    fov = {
        -- Zet profile_fpsFieldOfView bij het joinen, alleen voor deze sessie.
        autoApply = true,

        -- LET OP: de schaal van deze convar is niet officieel gedocumenteerd.
        -- Hoger = breder. Test live met /gfx fov <getal> voor je hem vastzet.
        value = 85,

        -- Eenmalige melding met het console-commando, voor als autoApply het
        -- op jouw build niet doet.
        notify = false,
    },

    -- ------------------------------------------------------------------
    --  EIGEN CAMERA - wel volledige FOV-controle, hoofd zelf wegwerken
    --
    --  TEST EERST /gfx fov 85. Werkt dat, dan heb je dit niet nodig en houd
    --  je alle voordelen van de echte first-person modus.
    --
    --  Wat je hiermee inlevert: richten en drive-by werken niet goed op een
    --  zelfgemaakte camera. Daarom staat hij standaard alleen in voertuigen
    --  aan en springt hij terug zodra je richt.
    -- ------------------------------------------------------------------
    customCam = {
        enabled = false, -- aan/uit te testen met /gfx cam

        fov = 90.0,

        -- Zo verdwijnt het hoofd: alles dichter bij de camera dan deze
        -- afstand wordt weggeknipt. 0.12 - 0.20 werkt meestal. Te hoog en je
        -- kijkt door het stuur of het dashboard heen.
        nearClip = 0.15,

        -- Positie ten opzichte van de hoofdbot. Iets naar voren (y) zet de
        -- camera bij de ogen in plaats van midden in de schedel.
        offset = { x = 0.0, y = 0.07, z = 0.0 },

        -- Alternatief voor de near clip: je hele ped lokaal onzichtbaar
        -- maken. Werkt gegarandeerd, maar dan zie je ook je eigen armen op
        -- het stuur niet meer.
        hidePed = false,

        -- Waar de eigen camera geldt. Te voet standaard uit, want daar werkt
        -- de echte modus prima en wil je richten niet slopen.
        contexts = { onFoot = false, inVehicle = true },

        -- Terug naar de echte camera zodra je richt of een drive-by doet.
        -- Uitzetten wordt afgeraden.
        releaseWhenAiming = true,
    },
}

-- ===========================================================================
--  POPULATIE  (ped- en voertuigdichtheid)
--
--  LEES DIT EERST als je je afvraagt waarom 0.1 geen peds oplevert:
--
--  1. 'peds' regelt alleen de RONDLOPENDE peds. De peds die ergens staan
--     (bushalte, bankje, rokend tegen een muur) zijn SCENARIO-peds en die
--     hebben hun eigen instelling hieronder. Zet je allebei laag, dan is de
--     stad compleet leeg.
--  2. Een multiplier stopt alleen NIEUWE spawns. Alles wat al gespawnd is
--     blijft gewoon rondrijden of staan.
--  3. Geparkeerde auto's komen grotendeels uit 'vehicle generators', een
--     apart systeem dat maar half naar de multiplier luistert. Daarom staat
--     disableLowPriorityGenerators hieronder.
--  4. Draait er nog een ander density-script, dan vechten die twee elke
--     frame om dezelfde instelling en wint willekeurig de laatste. Zet er
--     dus altijd maar EEN aan.
-- ===========================================================================

Config.Population = {
    -- Zet dit op false als je je bestaande density-script wilt blijven
    -- gebruiken. Allebei aan werkt gegarandeerd niet goed.
    enabled = true,

    -- Rondlopende peds. 0.0 = niemand, 1.0 = normaal.
    -- 0.1 is in de praktijk bijna nul: het aantal per zone is toch al laag,
    -- dus je houdt afgerond niemand over. 0.3 - 0.4 geeft rustige maar
    -- levende straten.
    peds = 0.35,

    -- Scenario-peds: de peds op vaste plekken. Dit zijn de peds waar je
    -- gameplay op wilt bouwen, want ze staan waar je ze verwacht.
    scenarioPeds = { interior = 1.0, exterior = 1.0 },

    -- Straal waarbinnen rondlopende peds spawnen. Lager = dichter om je
    -- heen, wat leger voelt maar ook goedkoper is.
    ambientPedRange = 1.0,

    -- Rijdend verkeer. Twee aparte knoppen, je hebt ze allebei nodig.
    --
    -- Let op: dit remt alleen NIEUWE spawns af. Auto's die al rijden blijven
    -- rijden tot ze normaal despawnen, dus na een wijziging duurt het een
    -- paar minuten voor je het volle effect ziet. Rijd een stuk weg en terug
    -- als je het sneller wilt zien.
    --
    -- Voertuigen van andere spelers tellen hier niet in mee; die kan een
    -- client-script niet wegnemen.
    vehicles       = 0.05,
    randomVehicles = 0.05,

    -- Geparkeerde auto's.
    parkedVehicles = 0.05,

    -- Zonder dit blijft er ondanks parkedVehicles = 0.1 nog van alles staan,
    -- omdat generators buiten de multiplier om plaatsen.
    disableLowPriorityGenerators = true,

    -- SET_NUMBER_OF_PARKED_VEHICLES. -1 = niet aanraken (aanrader),
    -- 0 = geen enkele. De native-docs beschrijven de waarde niet, dus dit is
    -- experimenteel; test het voor je het gebruikt.
    numberOfParkedVehicles = -1,

    -- Eenmalig de populatie vullen na het spawnen, zodat je meteen ziet wat
    -- je instellingen doen in plaats van een paar minuten te wachten.
    instantFillOnSpawn = true,
}

-- ===========================================================================
--  VISUALSETTINGS
--
--  Overschrijft waardes uit visualsettings.dat via SET_VISUAL_SETTING_FLOAT
--  (hash 0xD1D31681). Dit gaat NIET via data_file - dat type bestaat niet
--  voor visualsettings. Het bestand wordt op de client ingelezen en regel
--  voor regel toegepast.
--
--  Alleen de regels die in het bestand staan worden overschreven; al het
--  andere houdt zijn standaardwaarde. Een onvolledig bestand is dus veilig.
-- ===========================================================================

Config.VisualSettings = {
    enabled = true,
    file    = 'data/visualsettings.dat',

    -- Deze sleutel rommelt met de lengte van een weer-cyclus en hoort thuis
    -- bij je weathersync, niet hier.
    ignore = { ['weather.CycleDuration'] = true },
}

-- ===========================================================================
--  KLEURCORRECTIE
-- ===========================================================================

Config.Grading = {
    -- Snelheid van de ingebouwde overgang. GTA vloeit zelf over, dus er
    -- draait geen blend-thread. Rond 1.0 = ongeveer een seconde.
    transitionSpeed = 1.0,

    -- Gebruikt een ander script de timecycle-slot, dan blijven we er af.
    -- Zoveel ms wachten we voor we opnieuw proberen.
    yieldTime = 15000,

    -- Constante laag in de tweede timecycle-slot. Die slot heeft GEEN
    -- sterkte-native, dus hij staat altijd op vol. Een altijd-aan laag op
    -- volle sterkte was precies wat het beeld eerder grijs trok, vandaar
    -- standaard uit. Aanzetten kan, maar houd 'pr_film' dan heel subtiel.
    extraLayer    = false,
    extraLayerMod = 'pr_film',

    -- Boven deze hoogte (meter boven de grond) de lucht-look.
    aerialHeight = 120.0,
}

Config.Presets = {
    cinematic = { label = 'Cinematic', mods = 'full',    strength = 0.90 },
    heavy     = { label = 'Heavy',     mods = 'full',    strength = 1.00 },
    neutral   = { label = 'Neutraal',  mods = 'neutral', strength = 0.60 },
}

Config.ModSets = {
    full = {
        day        = 'pr_day',
        overcast   = 'pr_overcast',
        dawn       = 'pr_dawn',
        dusk       = 'pr_dusk',
        night      = 'pr_night',
        rain_day   = 'pr_rain_day',
        rain_night = 'pr_rain_night',
        fog        = 'pr_fog',
        snow       = 'pr_snow',
        aerial     = 'pr_aerial',
        interior   = 'pr_interior',
    },
    neutral = {
        day        = 'pr_neutral',
        overcast   = 'pr_neutral',
        dawn       = 'pr_neutral',
        dusk       = 'pr_neutral',
        night      = 'pr_neutral',
        rain_day   = 'pr_neutral',
        rain_night = 'pr_neutral',
        fog        = 'pr_neutral',
        snow       = 'pr_neutral',
        aerial     = 'pr_neutral',
        interior   = 'pr_neutral',
    },
}

-- Eindsterkte = preset.strength * deze waarde. Ontbreekt een context, dan 1.0.
Config.ContextStrength = {
    interior   = 0.75,
    aerial     = 0.70,
    fog        = 0.85,
    snow       = 0.85,
    night      = 1.00,
    rain_night = 1.00,
}

Config.Time = {
    dawn  = 5,  -- 05:00 - 08:00
    day   = 8,  -- 08:00 - 18:00
    dusk  = 18, -- 18:00 - 21:00
    night = 21, -- 21:00 - 05:00
}

-- ===========================================================================
--  KWALITEITSPROFIELEN
--
--  Deze raken bewust NIET aan de populatie. Dichtheid hoort bij je gameplay,
--  niet bij een framerate-schuif die achter je rug om verandert hoeveel
--  peds er voor je diefstal-script beschikbaar zijn.
-- ===========================================================================

Config.Profiles = {
    ultra = {
        label = 'Ultra',

        shadows = true,
        -- Kleiner = de shadow map over een kleiner gebied verdeeld, dus
        -- scherper. Kost niets extra. Te klein en schaduwen poppen in de verte.
        shadowBoundsScale = 0.55,
        -- FALSE = schaduwen tekenen vanaf verder weg (mooier, iets duurder).
        shadowEntityTracker = false,
        shadowTrackerScale  = 1.0,
        shadowSampleType    = 'CSM_ST_POISSON16_RPDB_GNORM',

        -- Extended distance scaling. Dit kost wel echt iets; op nil zetten
        -- als je ultra puur gratis wilt.
        lodScale = 1.25,

        distantCars       = true,
        reduceModelBudget = false,
        lowPopulation     = false,
    },

    balanced = {
        label = 'Gebalanceerd',

        shadows             = true,
        shadowBoundsScale   = 0.70,
        shadowEntityTracker = false,
        shadowTrackerScale  = 1.0,
        shadowSampleType    = 'CSM_ST_SOFT16',

        lodScale = nil, -- niets overschrijven

        distantCars       = true,
        reduceModelBudget = false,
        lowPopulation     = false,
    },

    performance = {
        label = 'Performance',

        shadows             = true,
        shadowBoundsScale   = 0.90,
        shadowEntityTracker = true,
        shadowTrackerScale  = 1.0,
        shadowSampleType    = 'CSM_ST_BOX4x4',

        lodScale = 0.75,

        distantCars       = false,
        reduceModelBudget = true,
        lowPopulation     = true, -- vraagt Config.AllowPopulationBudget
    },
}

-- Streaming-budget voor ped- en voertuigmodellen (0-3, 3 = normaal). Dit is
-- geheugen, geen aantallen: je ziet minder variatie, niet minder peds.
Config.AllowPopulationBudget = false
Config.PopulationBudget      = { ped = 2, vehicle = 2 }

-- Renderafstand van lichten. De native-docs zeggen niets over de richting
-- van deze waarde, dus uit tot je het zelf getest hebt (probeer 0.0 en 2.0).
Config.LightCutoff = { enabled = false, value = 0.0 }

-- Natte bandensporen en voetstappen bij regen en sneeuw.
Config.WetTracks = true

-- ===========================================================================
--  AUTOMATISCH PROFIEL
-- ===========================================================================

Config.Auto = {
    sampleInterval = 500,
    sampleCount    = 12,
    downThreshold  = 45,
    upThreshold    = 75,
    cooldown       = 20000,
    order          = { 'performance', 'balanced', 'ultra' },
    start          = 'balanced',
    notify         = false,
}

-- ===========================================================================
--  DEBUG
-- ===========================================================================

-- Print contextwissels en het aantal toegepaste visualsettings naar F8.
Config.Debug = false

Config, Bridge, targets = {}, exports.community_bridge:Bridge(), {} 

----------------------------------- TierSystem levels ** ONLY IN USE IF CONFIG.TIERSYTEM IS TRUE
Config.TierSystem = true -- allows for three tiers of certain drugs ( coke, heroin, crack, lsd)
Config.Tier1 = 100 -- amount to hit for level 2
Config.Tier2 = 300 -- amount to hit for level 3


--- Customizations
Config.Dispatch = 'ps' -- either 'ps', 'cd', 'core', 'aty'
Config.Minigames = {
    ps_circle =     {amount = 2,     speed = 8,},
    ps_maze =       {timelimit = 15},
    ps_scrambler =  {type = 'numeric', time = 15, mirrored = 0},
    ps_var =        {numBlocks = 5, time = 10},
    ps_thermite =   {time = 10, gridsize = 5, incorrect = 3},
    ox =            {'easy', 'easy'},   --easy medium or hard each one corresponds to how many skillchecks and the difficulty
    blcirprog =     {amount = 2, speed = 50},       -- speed = 1-100
    blprog =        {amount = 1, speed = 50},       -- speed = 1-100
    blkeyspam =     {amount = 1, difficulty = 50}, -- difficulty = 1-100
    blkeycircle =   {amount = 1, difficulty = 50, keynumbers = 3},
    blnumberslide = {amount = 1, difficulty = 50, keynumbers = 3},
    blrapidlines =  {amount = 1, difficulty = 50, numberofline = 3},
    blcircleshake = {amount = 1, difficulty = 50, stages = 3},
    glpath =        {gridSize = 19,  lives = 3,     timelimit = 10000},
    glspot =        {gridSize = 6, timeLimit = 999999, charSet = "alphabet", required = 10},
    glmath =        {timeLimit = 300000},
}
Config.minigametype = 'ps' -- look above for options or choose none if you dont want any minigames 
Config.Emotes = 'rpemotes' -- this is if you want to use emotes, you can pass the string of the emote name instead of the animDict and animClip like below
Config.DefaultAnimation = {
    dict = "mp_arresting",
    clip = "a_uncuff",
    flag = 49,
}

Config.ProgressBar = {
    Disables = {
        move = true,             -- Disable movement
        car = true,              -- Disable vehicle movement
        combat = true,           -- Disable combat
        mouse = false            -- Disable mouse
    }
}

-- Drug System Configs
Config.Drugs = { -- want a drug turn on? keep it true, want it turned off, mark it false
    cocaine = true,
    consumables = true,
    cornerselling = true,
    crack = true,
    deliveries = true,
    heroin = true,
    lean = true,
    lsd = true,
    mescaline = true,
    meth = true,
    oxyruns = true,
    pharma = true,
    shrooms = true,
    TravellingMerchant = true,
    weed = true,
    wholesale = true,
    whippit = true,
    xtc = true,
}

-- ==========================================================================
--  GANG-VERWERKING
-- ==========================================================================
-- Plukken en oogsten mag IEDEREEN. Verwerken tot verkoopbaar product mag alleen
-- de gang die die drug toegewezen heeft gekregen.
--
-- De gangnamen moeten exact overeenkomen met de sleutels in
-- qbx_core/shared/gangs.lua. marabunta en mafia zijn daar toegevoegd; ballas,
-- vagos en families bestonden al.
--
-- LET OP: de verdeling hieronder is een voorstel, geen opdracht. Alleen
-- "cocaine exclusief voor de mafia" lag vast. Pas aan naar wat je wilt.
Config.GangProcessing = {
    enabled = true,

    ---@type table<string, string[]> drug -> gangs die mogen verwerken
    drugs = {
        cocaine = { 'mafia' },       -- exclusief, expliciet zo gevraagd
        crack   = { 'ballas' },
        weed    = { 'families' },
        meth    = { 'marabunta' },
        heroin  = { 'vagos' },

        -- Nog niet toegewezen. Elke erkende gang mag deze verwerken.
        lsd     = { 'ballas', 'families', 'marabunta', 'vagos', 'mafia' },
        xtc     = { 'ballas', 'families', 'marabunta', 'vagos', 'mafia' },
        lean    = { 'ballas', 'families', 'marabunta', 'vagos', 'mafia' },
    },

    ---Welk server-event hoort bij welke drug. Alleen events die hier in staan
    ---worden gegate; al het andere (plukken, oogsten, verkopen, consumeren)
    ---blijft voor iedereen open.
    ---Alle namen hieronder zijn geverifieerd tegen de daadwerkelijke
    ---RegisterServerEvent/RegisterNetEvent declaraties in server/. Een naam die
    ---niet bestaat gate stilzwijgend niets, dus wijzig ze niet op gevoel.
    ---
    ---Bewust NIET gegate (mag iedereen):
    ---  get*/steal*/buy*     grondstoffen halen en kopen
    ---  give*/fill*          uitgifte en toedienen
    ---  fail*/*back/stop     mislukking en opruimen
    ---  dryplant/dryoutweed  drogen valt onder oogsten
    ---@type table<string, string>
    events = {
        -- cocaine (cocaine.lua)
        ['md-drugs:server:makepowder']       = 'cocaine',
        ['md-drugs:server:cutcokeone']       = 'cocaine',
        ['md-drugs:server:bagcoke']          = 'cocaine',

        -- crack (crack.lua)
        ['md-drugs:server:makecrackone']     = 'crack',
        ['md-drugs:server:bagcrack']         = 'crack',

        -- weed (weed.lua)
        ['md-drugs:server:MakeWeedItems']    = 'weed',
        ['md-drugs:server:RollBlunt']        = 'weed',

        -- heroin (heroin.lua)
        ['md-drugs:server:cutheroin']        = 'heroin',
        ['md-drugs:server:heatliquidheroin'] = 'heroin',

        -- lsd (lsd.lua)
        ['md-drugs:server:heatliquid']       = 'lsd',
        ['md-drugs:server:refinequalityacid']= 'lsd',
        ['md-drugs:server:maketabpaper']     = 'lsd',

        -- xtc (xtc.lua)
        ['md-drugs:server:makextc']          = 'xtc',
        ['md-drugs:server:makingrawxtc']     = 'xtc',
        ['md-drugs:server:stamp']            = 'xtc',

        -- lean (lean.lua) - makeLean gate staat expliciet in server/lean.lua
        ['md-drugs:server:makeLean']         = 'lean',

        -- meth: meth.lua kent alleen get*/give* events. De verwerking zit
        -- client-side achter een minigame en heeft geen eigen server-event.
        -- Zonder server-event valt er niets te gaten. Zie BACKLOG.
    },
}

-- ==========================================================================
--  JUNKIES
-- ==========================================================================
-- Verlengstuk van cornerselling, geen aparte resource. Cornerselling regelt al
-- het verkopen aan wereld-peds; dit voegt gedrag en een drop toe.
--
-- Er wordt NIETS gespawnd: bestaande ambient peds krijgen een scenario. Ze
-- vallen niemand aan - dat is bewust, een NPC die willekeurig agressief wordt
-- verpest de RP.
Config.Junkies = {
    enabled = true,

    -- Percentage van de geschikte peds in de buurt dat junkie-gedrag krijgt.
    chance = 12,

    scanInterval = 5000,    -- ms tussen scans
    scanRadius = 80.0,      -- alleen peds binnen deze straal bekijken
    maxPerScan = 6,         -- nooit meer dan dit per scan behandelen

    lootScanInterval = 2000,
    lootDistance = 3.0,     -- ook server-side afgedwongen

    playerCooldown = 30,    -- seconden tussen twee loots door dezelfde speler
    pedCooldown = 900,      -- seconden voordat hetzelfde lijk weer iets geeft

    -- Onrustig, niet gevaarlijk.
    scenarios = {
        'WORLD_HUMAN_DRUG_DEALER',
        'WORLD_HUMAN_SMOKING',
        'WORLD_HUMAN_STAND_IMPATIENT',
        'WORLD_HUMAN_BUM_STANDING',
        'WORLD_HUMAN_SMOKING_POT',
    },

    clipset = 'move_m@drunk@slightlydrunk',

    -- Kleine drop. Gewogen: geld vaak, drugs zelden. Bewust laag - een junkie
    -- neerschieten hoort geen verdienmodel te worden.
    drops = {
        { item = 'black_money',  min = 15, max = 60,  weight = 55 },
        { item = 'joint',        min = 1,  max = 2,   weight = 15 },
        { item = 'crack_baggy',  min = 1,  max = 1,   weight = 10 },
        { item = 'cokebaggy',    min = 1,  max = 1,   weight = 10 },
        { item = 'methbags',     min = 1,  max = 1,   weight = 10 },
    },
}

Config.Bzz = { -- if you have BZZZ props for these turn it on if you want
    cocaine = false,
    heroin =false,
    shrooms = false,
    weed = false,
}

--[[
    los_hygiene - douchen, plassen en poepen.

    Volledig nieuw voor Qbox. `_external/renzu_hygiene` is alleen als concept
    gebruikt: dat is ESX (esx_status, mysql-async, fx_version 'adamant') en had
    hoe dan ook helemaal herschreven moeten worden.

    DRIE STATUSSEN
      hygiene   loopt af; te laag en mensen ruiken je. Douchen zet hem vol.
      bladder   loopt OP; te vol en je krijgt aandrang. Plassen zet hem leeg.
      bowel     idem, langzamer.

    Blaas en darmen lopen omhoog in plaats van omlaag - dat leest natuurlijker
    ("blaas 80%" is vol) en scheelt overal een omkering.

    ALLES OPGESLAGEN IN METADATA
    Via qbx_core's SetMetaData, net als honger en dorst. Geen eigen tabel, geen
    extra SQL, en het overleeft een herstart omdat qbx_core de speler toch al
    wegschrijft.
]]

Config = {}

Config.debug = false

--[[
    ── ALLE VIJF DE DECAY-RATES OP EEN RIJ ──────────────────────────────────

    De opdracht vraagt om centraal instelbare rates. Honger en dorst horen bij
    qbx_core en die resource wordt hier niet herschreven, dus ze staan in
    `qbx_core/config/server.lua`. Dit overzicht houdt bij wat er waar staat.

    | status  | per tick | tick    | vol -> leeg  | waar                        |
    |---------|----------|---------|--------------|-----------------------------|
    | honger  | -1.4     | 5 min   | ~6 uur       | qbx_core/config/server.lua  |
    | dorst   | -1.3     | 5 min   | ~6,4 uur     | qbx_core/config/server.lua  |
    | hygiene | -1.0     | 5 min   | ~8,3 uur     | hieronder                   |
    | blaas   | +1.8     | 5 min   | ~4,6 uur vol | hieronder                   |
    | darmen  | +0.7     | 5 min   | ~12 uur vol  | hieronder                   |

    Alle vijf zijn bewust traag. Je merkt ze een paar keer per lange sessie, niet
    elk kwartier.
]]

--- Minuten tussen twee ticks. Gelijkgetrokken met qbx_core's updateInterval,
--- zodat alle statussen in hetzelfde ritme lopen.
Config.tickMinutes = 5

Config.rates = {
    hygiene = -1.0,
    bladder = 1.8,
    bowel = 0.7,
}

--- Metadata-sleutels. Kleine letters, net als qbx_core's `hunger` en `thirst`.
Config.keys = {
    hygiene = 'hygiene',
    bladder = 'bladder',
    bowel = 'bowel',
}

--- Startwaarden voor een character dat deze statussen nog niet heeft.
Config.defaults = {
    hygiene = 100,
    bladder = 0,
    bowel = 0,
}

-- ── Gevolgen ─────────────────────────────────────────────────────────────

Config.effects = {
    --- Onder deze hygiëne krijg je een waarschuwing en zien anderen het.
    dirtyBelow = 30,

    --- Boven deze blaas- of darmwaarde krijg je aandrang.
    urgeAbove = 80,

    --- Minuten tussen twee waarschuwingen, zodat het geen spam wordt.
    reminderMinutes = 8,

    --- Boven deze blaaswaarde loopt de speler zichtbaar ongemakkelijk.
    walkAbove = 90,
}

-- ── Handelingen ──────────────────────────────────────────────────────────

Config.actions = {
    shower = { duration = 12000, hygiene = 100 },
    washHands = { duration = 4000, hygiene = 15 },
    pee = { duration = 6000 },
    poo = { duration = 12000 },
}

--[[
    ── MODELLEN, NIET COORDINATEN ───────────────────────────────────────────

    Bewust ox_target op MODELLEN in plaats van vaste locaties. Dat werkt overal
    waar zo'n object staat - ook in appartementen van ps-housing en in interieurs
    die later bijkomen - en het scheelt een lijst coordinaten die iemand had
    moeten opmeten.

    LET OP: deze modelnamen zijn niet op deze server geverifieerd. Werkt een
    toilet of douche niet, gebruik dan `/hygienemodel`: dat commando meldt het
    model van het object waar je naar kijkt, zodat je hem hier kunt toevoegen.
    Zelfde aanpak als `/gangped` in los_gangpeds.
]]
Config.models = {
    toilet = {
        `prop_toilet_01`,
        `prop_toilet_02`,
        `prop_toilet_03`,
        `prop_toilet_04`,
        `v_res_mtoilet`,
        `hei_prop_heist_toilet`,
    },
    shower = {
        `v_res_shower`,
    },
    sink = {
        `prop_sink_05`,
        `prop_sink_06`,
        `v_res_mbsink`,
    },
}

return Config

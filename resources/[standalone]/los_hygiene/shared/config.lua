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
    | hygiene | -0.5     | 5 min   | ~16,6 uur    | hieronder                   |
    | blaas   | +0.9     | 5 min   | ~9,2 uur vol | hieronder                   |
    | darmen  | +0.35    | 5 min   | ~24 uur vol  | hieronder                   |

    De onderste drie stonden eerst twee keer zo snel (-1.0 / +1.8 / +0.7). Op
    verzoek van Tim gehalveerd: hygiëne, blaas en darmen horen achtergrondruis te
    zijn, niet iets waar je je sessie omheen plant. Honger en dorst zijn de twee
    die je nog wel regelmatig merkt.
]]

--- Minuten tussen twee ticks. Gelijkgetrokken met qbx_core's updateInterval,
--- zodat alle statussen in hetzelfde ritme lopen.
Config.tickMinutes = 5

Config.rates = {
    hygiene = -0.5,
    bladder = 0.9,
    bowel = 0.35,
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

    -- In het wild. Zelfde handeling, maar je wordt er vies van. Zie Config.wild.
    peeWild = { duration = 6000 },
    pooWild = { duration = 12000 },
}

--[[
    ── IN HET WILD (/pee en /poo) ───────────────────────────────────────────

    Werkt ALTIJD. De enige reden om te weigeren is dat er niets te legen valt:
    een blaas op 0 hoef je niet te legen.

    Geen hygiëneboete. Je behoefte doen kost je niets; alleen niet douchen
    maakt je vies, en dat loopt via de gewone verval-rate.

    De server controleert de voorwaarde opnieuw. De client checkt hem ook,
    maar puur om meteen een nette melding te kunnen geven in plaats van een
    stille weigering.
]]
Config.wild = {
    --- Onder deze waarde valt er niets te legen en weigert het commando.
    --- Op 1 betekent dat: alleen een volledig lege blaas of darm weigert.
    minimum = 1,

    --- Hygiëneverandering na afloop. 0 = geen effect, en dat is de bedoeling.
    --- Zet dit op een negatief getal als je het buiten toch wilt bestraffen.
    hygieneChange = 0,

    --- Niet vanuit een voertuig.
    blockInVehicle = true,
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

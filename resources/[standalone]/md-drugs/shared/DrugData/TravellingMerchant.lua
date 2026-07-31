if not Config.Drugs['TravellingMerchant'] then return end

Config.Merchant = {
    Locations = {
        Travellingmerchant = {
            vector4(-119.66, -977.43, 304.25, 88.21),
            vector4(-1522.93, 1476.01, 111.45, 41.25),
            vector4(-3278.98, 973.38, 5.35, 101.53),
        },
    },

    --[[
        ZWARTE MARKT

        De dealer verhuist elke `rotateMinutes` naar een andere plek uit de
        lijst hierboven. Spelers krijgen nooit coordinaten: ze sms'en het
        nummer hieronder en krijgen een omschrijving van de buurt terug.

        `hints` hoort op dezelfde index te staan als de bijbehorende locatie.
        De omschrijvingen zijn op de coordinaten geschat en NIET in-game
        gecontroleerd - loop ze een keer na en pas ze aan als ze niet kloppen.
        Ze zijn puur tekst, dus fout raden breekt niets, het stuurt alleen
        spelers de verkeerde kant op.
    ]]
    blackMarket = {
        enabled = true,

        -- Nummer dat spelers sms'en voor een tip. Vrij te kiezen zolang het
        -- geen bestaand spelersnummer is.
        number = '4040',

        -- Hoe vaak de dealer verkast. 0 = nooit verhuizen.
        rotateMinutes = 45,

        hints = {
            'Word is he set up on a rooftop somewhere in Downtown Los Santos.',
            'Somebody saw him parked up in the hills north-west of the city.',
            'He is out west, off the coast road past Chumash.',
        },

        replyPrefix = 'BLACKMARKET: ',
    },

    --[[
        LET OP: dit zijn PRIJZEN in contanten, geen voorraadaantallen.
        server/TravellingMerchant.lua doet:
            RemoveAccountBalance(src, 'cash', Config.Merchant.stores[item])

        De originele waarden ($1 tot $50) maakten alles vrijwel gratis: een
        lockpick voor $2, een prepaid telefoon voor $2. Hieronder staan bedragen
        die passen bij een zwarte markt.

        Alles loopt via deze NPC, legaal of niet.
    ]]
    stores = {
        -- LSD-precursors
        tab_paper           = 400,
        lysergic_acid       = 2200,
        diethylamide        = 2400,

        -- MDMA-precursors
        isosafrole          = 2600,
        mdp2p               = 2800,

        -- Codeine
        mdlean              = 850,

        -- Inbraakgereedschap
        lockpick            = 350,
        advancedlockpick    = 1200,

        -- Zipties. Handboeien zijn politie-uitrusting en zitten in de
        -- job-supply van renzu_jobs; zipties zijn het criminele equivalent en
        -- waren tot nu toe NERGENS te krijgen buiten die politiewinkel.
        -- Gangs binden er iemand mee vast, agenten knippen ze los met `tools`.
        zipties             = 150,

        -- Bereiding en gereedschap
        bakingsoda          = 45,
        flour               = 35,
        chocolate           = 60,
        mdbutter            = 75,
        weedgrinder         = 320,
        mdwoods             = 40,
        dabrig              = 900,
        leancup             = 30,
        butane              = 90,
        butanetorch         = 650,
        emptyvial           = 45,
        needle              = 60,

        -- Vluchtschema's voor een Cayo-kratdrop (stevo_cayocrates). Een krat
        -- levert rond de 10k op, dus dit mag geen fooi kosten.
        crate_usb           = 6500,

        -- Prepaid telefoons voor wholesale-deals
        cokeburner          = 750,
        crackburner         = 750,
        lsdburner           = 750,
        heroinburner        = 750,
        xtcburner           = 750,
        methburner          = 750,
    }
}

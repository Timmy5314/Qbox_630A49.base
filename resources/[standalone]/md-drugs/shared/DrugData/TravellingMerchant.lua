if not Config.Drugs['TravellingMerchant'] then return end
Config.Merchant = {
    Locations = {
        Travellingmerchant = {
            vector4(-119.66, -977.43, 304.25, 88.21),
            vector4(-1522.93, 1476.01, 111.45, 41.25),
            vector4(-3278.98, 973.38, 5.35, 101.53),
        },
    },
    -- Alles wat md-drugs nodig heeft loopt via deze NPC, legaal of niet. De
    -- getallen zijn voorraadaantallen, geen prijzen.
    stores = {
        -- LSD
        tab_paper           = 50,
        lysergic_acid       = 25,
        diethylamide        = 25,

        -- MDMA
        isosafrole          = 25,
        mdp2p               = 25,

        -- Codeine
        mdlean              = 50,

        -- Inbraakgereedschap
        lockpick            = 2,
        advancedlockpick    = 1,

        -- Zipties. Handboeien zijn politie-uitrusting en zitten in de
        -- job-supply van renzu_jobs; zipties zijn het criminele equivalent en
        -- waren tot nu toe NERGENS te krijgen buiten die politiewinkel.
        -- Gangs kunnen hiermee iemand vastbinden, agenten kunnen ze losknippen
        -- met `tools`.
        zipties             = 5,

        -- Bereiding en gereedschap
        bakingsoda          = 25,
        flour               = 25,
        chocolate           = 25,
        mdbutter            = 25,
        weedgrinder         = 25,
        mdwoods             = 2,
        dabrig              = 2,
        leancup             = 25,
        butane              = 25,
        butanetorch         = 2,
        emptyvial           = 2,
        needle              = 2,

        -- Prepaid telefoons voor wholesale-deals
        cokeburner          = 25,
        crackburner         = 2,
        lsdburner           = 2,
        heroinburner        = 2,
        xtcburner           = 25,
        methburner          = 2,
    }
}

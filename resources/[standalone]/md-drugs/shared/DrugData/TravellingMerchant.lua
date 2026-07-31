if not Config.Drugs['TravellingMerchant'] then return end
Config.Merchant = {
    Locations = {
        Travellingmerchant = {
            vector4(-119.66, -977.43, 304.25, 88.21),
            vector4(-1522.93, 1476.01, 111.45, 41.25),
            vector4(-3278.98, 973.38, 5.35, 101.53),
        },
    },
    -- Alleen illegale spullen: precursors, codeine, inbraakgereedschap en de
    -- prepaid telefoons. De legale spullen (bakingsoda, flour, chocolate,
    -- mdbutter, weedgrinder, mdwoods, dabrig, leancup, butane, butanetorch,
    -- emptyvial, needle) staan bij YouTool, de bouwmarkt.
    -- Zie renzu_shops/config/defaultshops.lua.
    --
    -- Wie wietkoekjes wil bakken hoeft daar geen dealer voor op te zoeken;
    -- wie een auto wil openbreken of MDMA wil persen wel.
    stores = {
        -- LSD-precursors
        tab_paper           = 50,
        lysergic_acid       = 25,
        diethylamide        = 25,

        -- MDMA-precursors
        isosafrole          = 25,
        mdp2p               = 25,

        -- Codeine
        mdlean              = 50,

        -- Inbraakgereedschap. Illegaal, dus hier en nergens anders.
        lockpick            = 2,
        advancedlockpick    = 1,

        -- Prepaid telefoons voor wholesale-deals
        cokeburner          = 25,
        crackburner         = 2,
        lsdburner           = 2,
        heroinburner        = 2,
        xtcburner           = 25,
        methburner          = 2,
    }
}
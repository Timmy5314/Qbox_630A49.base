--[[
    los_billing - rekeningen sturen en innen.

    Concept van ars_billing, nieuw gebouwd voor Qbox.

    WAT HET DOET
      Een bedrijf of hulpdienst stuurt een rekening. Is er een verzekering die
      hem dekt, dan betaalt die eerst; wat overblijft komt bij de speler. Die
      kan betalen, uitstellen of weigeren - behalve bij boetes en medische
      rekeningen, want die weiger je niet.

      Onbetaald blijven kost rente, en de deurwaarder stuurt een SMS die met de
      dag onvriendelijker wordt.

    ANTI-MISBRUIK
      Elke job heeft een maximumbedrag per rekening en een cooldown. Alles wat
      verstuurd wordt gaat in de log met afzender, ontvanger, bedrag en reden,
      en is met /billaudit terug te zien. Een agent die zichzelf rijk factureert
      valt daarmee direct op.
]]

Config = {}

Config.debug = false

--- Waar rekeningen van worden afgeschreven.
Config.account = 'bank'

--[[
    Wie mag factureren, tot welk bedrag, en hoe vaak.

    `maxAmount`   bovengrens per rekening
    `cooldown`    seconden tussen twee rekeningen van dezelfde afzender
    `minGrade`    laagste grade die mag factureren
    `unrefusable` true = de ontvanger kan hem niet weigeren
    `society`     rekening komt binnen op de societykas in plaats van privé
]]
Config.senders = {
    police = {
        label = 'LSPD',
        maxAmount = 5000,
        cooldown = 30,
        minGrade = 0,
        unrefusable = true,  -- boetes
        society = true,
    },
    bcso = {
        label = 'BCSO',
        maxAmount = 5000,
        cooldown = 30,
        minGrade = 0,
        unrefusable = true,
        society = true,
    },
    sasp = {
        label = 'SASP',
        maxAmount = 5000,
        cooldown = 30,
        minGrade = 0,
        unrefusable = true,
        society = true,
    },
    ambulance = {
        label = 'Pillbox Medical',
        maxAmount = 4000,
        cooldown = 30,
        minGrade = 0,
        unrefusable = true,  -- medisch
        society = true,
    },
    mechanic = {
        label = 'Mechanic',
        maxAmount = 15000,
        cooldown = 60,
        minGrade = 0,
        unrefusable = false,
        society = true,
    },
    realestate = {
        label = 'Makelaar',
        maxAmount = 50000,
        cooldown = 120,
        minGrade = 0,
        unrefusable = false,
        society = true,
    },
}

--- Rekeningen die de verzekering (los_insurance) mag dekken.
--- `medical` -> claimMedical, `vehicle` -> claimVehicle.
Config.insured = {
    ambulance = 'medical',
    mechanic = 'vehicle',
}

Config.overdue = {
    --- Uren voordat een onbetaalde rekening rente krijgt.
    afterHours = 24,

    --- Rente per periode, als deel van het openstaande bedrag.
    interest = 0.05,

    --- Maximale rente als deel van het oorspronkelijke bedrag.
    maxInterestShare = 1.0,

    --- Minuten tussen twee controles.
    checkMinutes = 30,

    --- Nummer waarmee de deurwaarder belt. 1500 = overheid (los_insurance),
    --- 4040 = black market, 4747 = taxi. Deze is vrij.
    senderNumber = '1600',
}

--- Toets voor het rekeningenoverzicht.
Config.menuKey = 'F7'

return Config

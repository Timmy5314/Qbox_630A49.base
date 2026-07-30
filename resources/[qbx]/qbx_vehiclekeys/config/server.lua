return {
    runClearCronMinutes = 5,
    distanceToHandKeys = 3,
    -- Maximaal toegestane afstand (m) tussen speler en voertuig bij elke sleutel-
    -- of slot-actie die door de client wordt aangevraagd. Ruim genomen omdat het
    -- entity-middelpunt van bussen/trailers ver van de speler kan liggen.
    -- Verlagen maakt strenger; te laag geeft false positives op grote voertuigen.
    maxInteractionDistance = 10.0,
    ---@type table<WeaponTypeGroup, number>
    carjackChance = {                    -- Probability of successful carjacking based on weapon used
        [WeaponTypeGroup.MELEE] = 0.0,
        [WeaponTypeGroup.HANDGUN] = 0.5,
        [WeaponTypeGroup.SMG] = 0.75,
        [WeaponTypeGroup.SHOTGUN] = 0.90,
        [WeaponTypeGroup.RIFLE] = 0.90,
        [WeaponTypeGroup.LMG] = 0.99,
        [WeaponTypeGroup.SNIPER] = 0.99,
        [WeaponTypeGroup.HEAVY] = 0.99,
        [WeaponTypeGroup.THROWABLE] = 0.0,
        [WeaponTypeGroup.MISC] = 0.0,
    },
}

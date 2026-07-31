return {
    -- Agenten ON DUTY die nodig zijn voordat je voorbijgangers kunt beroven.
    -- 0 = geen eis.
    --
    -- Het origineel las GlobalState.copCount, dat door Renewed-Lib wordt
    -- bijgehouden. Die resource draait hier niet, dus die state bestaat niet en
    -- de check zou altijd 0 zien. Nu wordt het per aanroep geteld via
    -- qbx_core:GetDutyCountJob over de jobs hieronder.
    requiredCops = 0,

    -- Welke jobs als politie tellen voor requiredCops. Zelfde lijst als
    -- ND_Police/data/config.lua policeGroups en de inventory:police convar.
    policeJobs = {
        'police',
        'bcso',
        'sasp',
    },

    -- Jobs en gangs die geen voorbijgangers mogen beroven. Server-side gecheckt.
    blacklistedJobs = {
        'police',
        'bcso',
        'sasp',
        'ambulance',
    },
}

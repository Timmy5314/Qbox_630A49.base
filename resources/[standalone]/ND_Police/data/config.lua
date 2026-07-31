return {
    -- qbx_core default job names (see qbx_core/shared/jobs.lua).
    policeGroups = {
        "police",
        "bcso",
        "sasp"
    },

    clearGSR = 15, -- time in minutes
    clearGSRinWater = 1, -- minutes

    -- Hoe lang een huls/projectiel op straat blijft liggen, in minuten.
    -- 0 = nooit opruimen (het oude gedrag; sporen bleven eeuwig staan).
    evidenceLifetime = 45,

    -- Assistentie-oproep (ps-dispatch 10-32 / 10-99).
    backup = true,
    backupKey = "F6",
    backupCooldown = 30, -- seconds between two calls by the same officer

    minImpoundPrice = 100,
    maxImpoundPrice = 500,
    defaultImpoundPrice = 200 -- this should be within max an min range.
}

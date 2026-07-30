return {
    -- qbx_core default job names (see qbx_core/shared/jobs.lua).
    policeGroups = {
        "police",
        "bcso",
        "sasp"
    },

    clearGSR = 15, -- time in minutes
    clearGSRinWater = 1, -- minutes

    minImpoundPrice = 100,
    maxImpoundPrice = 500,
    defaultImpoundPrice = 200 -- this should be within max an min range.
}

local options = lib.load("data.clothing")
local menus = {}

-- `groups` accepts qbx job names, gang names or citizenids.
-- e.g. change an outfit to groups = {"swat"} once you've added that job to qbx_core/shared/jobs.lua.


menus["police"] = {
    title = "Locker room",
    groups = {"police"},
    locations = {
        vec3(458.14, -990.82, 30.69)
    },
    options = {
        {
            title = "Patrol uniform (long sleeve)",
            groups = {"police"},
            clothing = options.lspd_patrol
        },
        {
            title = "Patrol uniform (short sleeve)",
            groups = {"police"},
            clothing = options.lspd_patrol2
        },
        {
            title = "Patrol uniform (vest) (long sleeve)",
            groups = {"police"},
            clothing = options.lspd_patrol3
        },
        {
            title = "Patrol uniform (vest) (short sleeve)",
            groups = {"police"},
            clothing = options.lspd_patrol4
        },
        {
            title = "K9 uniform",
            groups = {"police"},
            clothing = options.lspd_canine
        },
        {
            title = "SWAT (black)",
            groups = {"police"},
            clothing = options.lspd_swat
        },
        {
            title = "SWAT (tan)",
            groups = {"police"},
            clothing = options.lspd_swat2
        },
        {
            title = "SWAT Pilot",
            groups = {"police"},
            clothing = options.lspd_swat3
        },
    }
}




return menus

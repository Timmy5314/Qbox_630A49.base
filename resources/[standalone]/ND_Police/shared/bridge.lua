-- QBox (qbx_core) integration.
-- The original multi-framework bridge folder has been removed; this is the only
-- place where core-specific code lives.

lib.locale()

local qbx = exports.qbx_core

Bridge = {}

if IsDuplicityVersion() then
    ---@param src number
    ---@param info table ox_lib notify data
    function Bridge.notify(src, info)
        if not src then return end
        TriggerClientEvent("ox_lib:notify", src, info)
    end

    ---@param src number
    ---@param groups string[] job/gang names
    function Bridge.hasJobs(src, groups)
        if not groups then return false end

        local ok, result = pcall(function()
            return qbx:HasGroup(src, groups)
        end)

        return ok and result or false
    end

    ---@param src number
    ---@param location string street/zone text
    ---@param coords vector3
    function Bridge.shotSpotter(src, location, coords)
        if GetResourceState("ps-dispatch"):find("start") then
            return exports["ps-dispatch"]:CustomAlert({
                coords = coords,
                message = locale("shot_spotter"),
                dispatchCode = "10-71",
                description = location,
                radius = 0,
                sprite = 110,
                color = 1,
                scale = 1.0,
                length = 3,
                jobs = { "leo" }
            })
        end
    end

    return
end

function Bridge.notify(info)
    lib.notify(info)
end

---@param groups string[] job/gang names
function Bridge.hasGroup(groups)
    if not groups then return false end

    -- qbx_core checks job name, gang name, all held jobs/gangs and citizenid.
    local ok, result = pcall(function()
        return qbx:HasGroup(groups)
    end)

    return ok and result or false
end

function Bridge.getPlayer()
    local ok, player = pcall(function()
        return qbx:GetPlayerData()
    end)

    return ok and player or nil
end

---@param player table PlayerData
---@param job string job name or job type ("leo")
function Bridge.doesPlayerHaveJob(player, job)
    if not player or not player.job then return false end

    if player.job.name == job or player.job.type == job then
        return true
    end

    return player.jobs and player.jobs[job] ~= nil
end

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    TriggerEvent("ND_Police:playerUnloaded")
end)

RegisterNetEvent("qbx_core:client:playerLoggedOut", function()
    TriggerEvent("ND_Police:playerUnloaded")
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
    TriggerEvent("ND_Police:groupsUpdated")
end)

RegisterNetEvent("QBCore:Client:OnGangUpdate", function()
    TriggerEvent("ND_Police:groupsUpdated")
end)

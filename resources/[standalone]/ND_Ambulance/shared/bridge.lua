-- QBox (qbx_core) integration.
-- The original multi-framework bridge folder has been removed; this is the only
-- place where core-specific code lives.

local qbx = exports.qbx_core

Bridge = {}

---Shared job check. `jobs` is a list of job names, gang names or job types
---(e.g. "ambulance" or "ems"), see data/jobs.lua.
---@param playerData table? QBox PlayerData
---@param jobs string[]
---@return boolean
local function playerHasJobs(playerData, jobs)
    if not playerData or not playerData.job or not jobs then return false end

    for i = 1, #jobs do
        local name = jobs[i]

        if playerData.job.name == name or playerData.job.type == name then
            return true
        end

        if playerData.jobs and playerData.jobs[name] then
            return true
        end

        if playerData.gangs and playerData.gangs[name] then
            return true
        end
    end

    return false
end

if IsDuplicityVersion() then
    ---@param src number
    ---@return table? QBox player object
    function Bridge.getPlayer(src)
        return qbx:GetPlayer(src)
    end

    ---@param src number
    ---@param jobs string[]
    ---@return boolean
    function Bridge.hasJobs(src, jobs)
        local player = qbx:GetPlayer(src)
        return playerHasJobs(player and player.PlayerData, jobs)
    end

    ---@param src number
    ---@param data table ox_lib notify data
    function Bridge.notify(src, data)
        if not src then return end
        TriggerClientEvent("ox_lib:notify", src, data)
    end

    ---@param src number
    ---@param amount number
    ---@return boolean
    function Bridge.hasMoney(src, amount)
        local bank = qbx:GetMoney(src, "bank") or 0
        local cash = qbx:GetMoney(src, "cash") or 0

        return bank >= amount or cash >= amount
    end

    ---@param src number
    ---@param amount number
    function Bridge.deductMoney(src, amount)
        local bank = qbx:GetMoney(src, "bank") or 0
        local cash = qbx:GetMoney(src, "cash") or 0

        if bank >= amount then
            qbx:RemoveMoney(src, "bank", amount, "Hospital bill")
        elseif cash >= amount then
            qbx:RemoveMoney(src, "cash", amount, "Hospital bill")
        end
    end

    ---@param src number
    function Bridge.setDeadMetadata(src)
        -- qbx uses the lowercase key `isdead`; other qbx resources and the
        -- `canUseWeapons` statebag key off it.
        qbx:SetMetadata(src, "isdead", true)
    end

    ---Clear the dead flags without touching the client. Used by the respawn flow,
    ---which resets the client itself once the bill and the inventory drop landed.
    ---@param src number
    function Bridge.clearDeadMetadata(src)
        qbx:SetMetadata(src, "isdead", false)
        qbx:SetMetadata(src, "inlaststand", false)
    end

    ---@param src number
    function Bridge.revivePlayer(src)
        TriggerClientEvent("ND_Ambulance:revivePlayer", src)
        Bridge.clearDeadMetadata(src)
        -- server/main.lua listens for this to forget the player's respawn clock,
        -- otherwise their next death would allow an instant respawn.
        TriggerEvent("ND_Ambulance:playerRevived", src)
    end

    -- Exposed so other resources can revive without reaching into this one.
    -- los_aidoctor uses it; without an export it would have to copy the three
    -- steps above and would silently drift when they change.
    exports("revivePlayer", function(src)
        src = tonumber(src)
        if not src or not GetPlayerName(src) then return false end

        Bridge.revivePlayer(src)
        return true
    end)

    lib.addCommand("revive", {
        help = "Admin command, revive a player.",
        restricted = "group.admin",
        params = {
            {
                name = "target",
                type = "playerId",
                help = "Target player's server id"
            }
        }
    }, function(src, args, raw)
        -- revive the target, not the admin running the command.
        Bridge.revivePlayer(args.target or src)
    end)

    return
end

require("@qbx_core/modules/playerdata")

local peds = lib.load("client.modules.peds")

function Bridge.getDeathModule()
    -- qbx has no death system that plays nice with this script, so always load ours.
    lib.load("client.modules.death")
end

---@param jobs string[]
---@return boolean
function Bridge.hasJobs(jobs)
    return playerHasJobs(QBX and QBX.PlayerData, jobs)
end

---@param data table ox_lib notify data
function Bridge.notify(data)
    lib.notify(data)
end

function Bridge.createAiPed(info)
    return peds.createAiPed(info)
end

---@return boolean
function Bridge.isDead()
    return QBX and QBX.PlayerData and QBX.PlayerData.metadata and QBX.PlayerData.metadata.isdead or false
end

-- qbx triggers this locally on the client after the character is loaded.
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    TriggerEvent("ND_Ambulance:characterLoaded")
end)

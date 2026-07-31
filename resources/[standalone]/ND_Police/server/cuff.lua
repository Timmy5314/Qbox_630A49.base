-- lib.load, niet require: data/ zit in `files` in de manifest, niet in
-- server_scripts. server/main.lua doet hetzelfde.
local config = lib.load("data.config")

local cuffItems = {"cuffs", "zipties"}
local uncuffItems = {
    ["cuffs"] = "handcuffkey",
    ["zipties"] = "tools"
}

-- Handcuffs are police equipment. Gangs and civilians use zipties instead.
-- Enforced here rather than client-side because the client is not authority:
-- without this check anyone holding a `cuffs` item could restrain anyone.
local policeOnlyCuffTypes = {
    ["cuffs"] = true
}

---@param src number
---@param cuffType string
---@return boolean
local function mayUseCuffType(src, cuffType)
    if not policeOnlyCuffTypes[cuffType] then return true end
    return Bridge.hasJobs(src, config.policeGroups)
end

local function cuffCheck(src, target, cuffType)
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if GetVehiclePedIsIn(ped) ~= 0 or
        GetVehiclePedIsIn(targetPed) ~= 0 or
        #(GetEntityCoords(ped)-GetEntityCoords(targetPed)) > 5.0 or
        not lib.table.contains(cuffItems, cuffType) or
        not mayUseCuffType(src, cuffType) or
        Ox_inventory:GetItemCount(src, cuffType) == 0
        then return
    end

    local playerState = Player(src).state
    local targetState = Player(target).state

    -- Was one flat expression. Because `and` binds tighter than `or` in Lua it
    -- parsed as (all player checks AND target.handsUp) OR (cuffType == "cuffs"
    -- AND target checks) - so with handcuffs the cuffer's own state was never
    -- checked. A cuffed player could cuff someone else. Grouped explicitly now.
    local cufferReady = not playerState.handsUp
        and not playerState.gettingCuffed
        and not playerState.isCuffed
        and not playerState.isCuffing

    local targetReady = not targetState.gettingCuffed
        and not targetState.isCuffing
        and not targetState.isCuffed

    -- Zipties need the target's hands up; handcuffs do not.
    local targetWillingOrForced = targetState.handsUp or cuffType == "cuffs"

    return cufferReady and targetReady and targetWillingOrForced
end

local function uncuffCheck(src, target, cuffType)
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    
    if GetVehiclePedIsIn(ped) ~= 0 or
        GetVehiclePedIsIn(targetPed) ~= 0 or
        #(GetEntityCoords(ped)-GetEntityCoords(targetPed)) > 5.0 or
        not uncuffItems[cuffType] or
        Ox_inventory:GetItemCount(src, uncuffItems[cuffType]) == 0
        then return
    end

    local playerState = Player(src).state
    local targetState = Player(target).state
    return not playerState.handsUp and
        not playerState.gettingCuffed and
        not playerState.isCuffed and
        not playerState.isCuffing and
        targetState.isCuffed
end

RegisterNetEvent("ND_Police:syncAgressiveCuff", function(target, angle, cuffType, slot, heading)
    local src = source
    if not cuffCheck(src, target, cuffType) then return end

    local escaped = lib.callback.await("ND_Police:syncAgressiveCuff", target, angle, cuffType, heading)
    if escaped then return end

    Player(target).state.handsUp = false
    Ox_inventory:RemoveItem(src, cuffType, 1, nil, slot)
end)

RegisterNetEvent("ND_Police:syncNormalCuff", function(target, angle, cuffType, slot)
    local src = source
    if not cuffCheck(src, target, cuffType) or not Ox_inventory:RemoveItem(src, cuffType, 1, nil, slot) then return end
    TriggerClientEvent("ND_Police:syncNormalCuff", target, angle, cuffType)
end)

RegisterNetEvent("ND_Police:uncuffPed", function(target, cuffType)
    local src = source
    if not uncuffCheck(src, target, cuffType) then return end

    local playerCuffType = Player(target).state.cuffType or "cuffs"
    if playerCuffType ~= cuffType then return end

    TriggerClientEvent("ND_Police:uncuffPed", target)
    Wait(500)
    Ox_inventory:AddItem(src, cuffType, 1)
end)

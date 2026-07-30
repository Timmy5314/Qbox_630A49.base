-- taken from ND_Core under GPL-3.0 License: https://github.com/ND-Framework/ND_Core/blob/main/client/peds.lua
local data_death = require("data.death")
local alreadyEliminated = false

local function dbg(...)
    if not data_death.debug then return end
    print("[ND_Ambulance:death]", ...)
end

local function PlayerEliminated(deathCause, killerServerId, killerClientId)
    if alreadyEliminated then return end
    alreadyEliminated = true
    dbg("player death detected, cause:", deathCause)

    local info = {
        deathCause = deathCause,
        killerServerId = killerServerId,
        killerClientId = killerClientId,
        damagedBones = getBodyDamage() or {}
    }
    TriggerEvent("ND_Ambulance:playerEliminated", info)
    TriggerServerEvent("ND_Ambulance:playerEliminated", info)

    -- stay latched past the 2s revive delay in client/main.lua so the watchdog
    -- below doesn't fire again while the ped is still technically dead.
    SetTimeout(4000, function()
        alreadyEliminated = false
    end)
end

AddEventHandler("gameEventTriggered", function(name, args)
    if name ~= "CEventNetworkEntityDamage" then return end

    local victim = args[1]
    if not IsPedAPlayer(victim) or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId then return end

    local hit, bone = GetPedLastDamageBone(victim)
    if hit then
        local damageWeapon = getLastDamagingWeapon(victim)
        updateBodyDamage(bone, damageWeapon)
    end

    if not IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) > 100 then return end

    local killerEntity, deathCause = GetPedSourceOfDeath(cache.ped), GetPedCauseOfDeath(cache.ped)
    local killerClientId = NetworkGetPlayerIndexFromPed(killerEntity)
    if killerEntity ~= cache.ped and killerClientId and NetworkIsPlayerActive(killerClientId) then
        return PlayerEliminated(deathCause, GetPlayerServerId(killerClientId), killerClientId)
    end
    PlayerEliminated(deathCause)
end)

-- CEventNetworkEntityDamage doesn't fire for every way to die (falls, drowning,
-- some explosions). This catches any death the event above missed, and also
-- escalates "knocked" players who die again while already down.
CreateThread(function()
    while true do
        Wait(250)
        if not alreadyEliminated and IsPedFatallyInjured(cache.ped) then
            local deathState = Player(cache.serverId).state.isDead
            if not LocalPlayer.state.dead or deathState == "knocked" then
                dbg("death missed by game event, triggering manually")
                PlayerEliminated(GetPedCauseOfDeath(cache.ped))
            end
        end
    end
end)

if GetResourceState("spawnmanager"):find("start") then
    -- autospawn must stay off: otherwise spawnmanager respawns the player the
    -- moment they die and the whole death state gets skipped.
    exports.spawnmanager:setAutoSpawn(false)

    -- on qbx the core/multicharacter handles the initial spawn. Only take that
    -- over when the server explicitly asks for it, hijacking
    -- setAutoSpawnCallback otherwise breaks apartment/last-position spawns.
    if data_death.spawnmanagerFirstSpawn then
        local firstSpawn = true
        exports.spawnmanager:setAutoSpawnCallback(function()
            if not firstSpawn then return end
            firstSpawn = false
            exports.spawnmanager:spawnPlayer()
            exports.spawnmanager:setAutoSpawn(false)
        end)
        exports.spawnmanager:setAutoSpawn(true)
    end
end

-- NOTE: the ND_Ambulance:revivePlayer handler that used to live here moved to
-- client/main.lua (resetDeathState). Having both resurrect the ped caused a
-- double NetworkResurrectLocalPlayer on every revive.

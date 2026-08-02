local data_animations = require("data.animations")
local data_weapons = require("data.weapons")
local data_bone_settings = require("data.bone_settings")
local data_bones = require("data.bones")
local data_knockout = require("data.knockout")
local data_death = require("data.death")
local data_walks = require("data.walks")

local respawnKeybind = nil
local respawnKeybindLetter = ""
local respawning = false
local downAnim = nil
local deathState = nil
-- GetGameTimer() value of the moment the player first went down. Monotonic and
-- purely local: the countdown must not depend on a statebag round trip or on the
-- game/server clocks agreeing.
local deathStartedAt = nil
local bleedOutTimer = nil
local knockedOut = false
local signalSent = false
-- escalating "knocked" -> "eliminated" starts a fresh loop thread, so this has to
-- live outside it or the player gets the same notification twice per death.
local respawnNotified = false
local bleeding = 0
local bodyBonesDamage = lib.table.deepclone(data_bone_settings)
local oldMovement = nil

local function dbg(...)
    if not data_death.debug then return end
    print("[ND_Ambulance]", ...)
end

-- resolved lazily: right after lib.addKeybind the game doesn't know the key yet
-- and GetControlInstructionalButton hands back an empty glyph.
local function getRespawnKeybindLetter()
    if respawnKeybindLetter ~= "" then return respawnKeybindLetter end

    local key = respawnKeybind and respawnKeybind.currentKey
    if type(key) ~= "string" or key == "" then
        key = data_death.keybind
    end

    respawnKeybindLetter = key
    return key
end

function BlockActions(status, ignoreInv, ignoreTarget)
    LocalPlayer.state.blockHandsUp = status

    if not ignoreInv then
        LocalPlayer.state.invBusy = status
    end

    if not ignoreTarget then
        exports.ox_target:disableTargeting(status)
    end

    if GetResourceState("npwd") == "started" then
        exports.npwd:setPhoneDisabled(status)
    end
end

function Teleport(ped, coords, withVehicle)
    FreezeEntityPosition(ped, true)
    StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, coords.w, withVehicle, true, true)

    -- don't wait forever if collision never streams in, otherwise the ped stays frozen.
    local timeout = GetGameTimer()+15000
    while (IsPlayerTeleportActive() or not HasCollisionLoadedAroundEntity(ped)) and GetGameTimer() < timeout do
        Wait(10)
    end

    FreezeEntityPosition(ped, false)
end

function GetTotalDamageType(body, damageType)
    if not body then return 0 end

    local value = 0
    for _, info in pairs(body) do
        if info[damageType] then
            value += info[damageType]
        end
    end
    return value
end

local function revivePlayer()
    local oldPed = cache.ped
    local seat = cache.seat
    local veh = cache.vehicle
    local coords = GetEntityCoords(oldPed)
    local armor = GetPedArmour(oldPed)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(oldPed), true, true, false)

    local ped = PlayerPedId()
    if oldPed ~= ped then
        SetEntityLocallyInvisible(oldPed)
        DeleteEntity(oldPed)
        ClearAreaOfPeds(coords.x, coords.y, coords.z, 0.2, false)
    end

    SetEntityVisible(ped, true)
    SetPedArmour(ped, armor)

    if veh and veh ~= 0 then
        SetPedIntoVehicle(ped, veh, seat)
    end
end

local function getNearestRespawnPoint()
    local locations = data_death.hospitalRespawns
    local nearestDist = nil
    local nearestCoords = nil
    local pedCoords = GetEntityCoords(cache.ped)

    for i=1, #locations do
        local loc = locations[i]
        local dist = #(loc.xyz-pedCoords)
        if not nearestCoords or not nearestDist or dist < nearestDist then
            nearestCoords = loc
            nearestDist = dist
        end
    end

    return nearestCoords
end

local function resetWalk()
    local ped = cache.ped
    if GetPedMovementClipset(ped) ~= `move_m@injured` then return end

    SetPedMoveRateOverride(ped, 1.0)

    local movement = data_walks[oldMovement]
    return movement and SetPedMovementClipset(ped, movement, true) or ResetPedMovementClipset(ped, 0)
end

-- injured walking style set depending on body part injury.
local function hurtWalk()
    oldMovement = GetPedMovementClipset(cache.ped)

    for _, info in pairs(bodyBonesDamage) do
        if info.causeLimp and info.severity > 1.0 then
            lib.requestAnimSet("move_m@injured")
            SetPedMovementClipset(cache.ped, "move_m@injured", 1)
            SetPlayerSprint(cache.playerId, false)
            SetPedMoveRateOverride(cache.ped, 0.95)
            return true
        end
    end

    resetWalk()
end

-- get body damage based on body parts.
local function getInjuredBoneData(bones)
    local data = {}
    for bone, info in pairs(bones) do
        if info.severity <= 0 then goto skip end

        if not data[bone] then
            data[bone] = info
        else
            local limb = data[bone]
            limb.suffocating = info.suffocating
            limb.fracture = info.fracture
            limb.burn = info.burn
            limb.bleeding = info.bleeding
            limb.severity = info.severity
        end

        ::skip::
    end
    return data
end

-- update the statebag for the body damage.
local function updateInjuryStatus()
    local state = Player(cache.serverId).state
    state:set("injuries", getInjuredBoneData(bodyBonesDamage), true)
end

local function getRandomDeathAnim()
    return data_animations[math.random(1, #data_animations)]
end

local function getPlayerPostal()
    if GetResourceState("ModernHUD") == "started" then
        return exports["ModernHUD"]:getPostal()
    elseif GetResourceState("nearest-postal") == "started" then
        return exports["nearest-postal"]:getPostal()
    end
end

local function startSignalThread()
    CreateThread(function()
        while deathState and not signalSent do
            -- control 47 (G) can be disabled by other resources while down.
            if IsControlJustPressed(0, 47) or IsDisabledControlJustPressed(0, 47) then
                signalSent = true
                SendNUIMessage({ type = "signal_sent" })

                local coords = GetEntityCoords(cache.ped)
                local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
                local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
                local postal = getPlayerPostal()
                local location = postal and ("%s %s (%s)"):format(street, zoneName, postal) or ("%s %s"):format(street, zoneName)
                dbg("sending distress signal:", location)
                TriggerServerEvent("ND_Ambulance:sendSignal", location, coords)
                break
            end
            Wait(0)
        end
    end)
end

-- handle player death based on death state.
local function setDead(ped, dict, clip, newDeathState)
    if deathState == newDeathState then return end

    local firstDeath = deathState == nil
    deathState = newDeathState
    dbg("death state:", newDeathState, firstDeath and "(first death)" or "(escalation)")

    local state = Player(cache.serverId).state

    -- the respawn countdown starts on the FIRST death state and keeps running when
    -- "knocked" escalates to "eliminated", so a player never waits longer than
    -- data_death.timer in total before respawn becomes available.
    if firstDeath or not deathStartedAt then
        deathStartedAt = GetGameTimer()

        -- other players read this to judge how long a body has been down (defib).
        state:set("timeSinceDeath", GetCloudTimeAsInt(), true)

        -- the server keeps its own clock for the respawn: it must not trust a
        -- timestamp the client wrote into its own statebag.
        TriggerServerEvent("ND_Ambulance:playerDown")
    end

    -- The death screen used to show a bare countdown with no explanation, and the
    -- warning about losing your belongings only appeared once the timer ran out --
    -- five minutes too late to act on. Send the terms up front.
    local minutes = math.floor(data_death.timer/60)
    local seconds = data_death.timer%60
    local timerText = minutes > 0
        and (seconds > 0 and ("%d min %d sec"):format(minutes, seconds) or ("%d min"):format(minutes))
        or ("%d sec"):format(seconds)

    SendNUIMessage({
        type = "dead",
        state = newDeathState,
        cost = data_death.prices.respawn,
        timerText = timerText
    })

    -- One notification on the first death only. The screen keeps the terms
    -- visible after this; repeating it on every escalation is just noise.
    if firstDeath then
        Bridge.notify({
            title = "You are down",
            description = ("EMS can revive you and you keep your belongings. Respawning is possible in %s, costs $%s and you lose everything you carry.")
                :format(timerText, data_death.prices.respawn),
            type = "error",
            icon = "hospital",
            iconColor = "#eb4034",
            duration = 15000,
            position = "top-center"
        })
    end

    -- the red screen. "damage" is the vanilla low-health timecycle (red vignette);
    -- it replaces the GTA death effect, which is lost the moment this script
    -- resurrects the ped to play the down animation.
    SetTimecycleModifier("damage")
    SetTimecycleModifierStrength(newDeathState == "eliminated" and 1.0 or 0.6)

    if newDeathState == "eliminated" then
        SetEntityHealth(ped, 100)

        SetTimeout(2000, function()
            if LocalPlayer.state.onStretcher then
                local stretcher = GetNearestStretcher(GetEntityCoords(ped))
                if DoesEntityExist(stretcher) then
                    AttachPlayerToStretcher(stretcher)
                end
            end
        end)
    else
        -- coming back from "eliminated" (defib) leaves the player invincible and
        -- undamageable, which would make it impossible to ever bleed out again.
        SetPedDiesWhenInjured(ped, true)
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(cache.playerId, false)
        SetEntityCanBeDamaged(ped, true)

        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        bleedOutTimer = GetCloudTimeAsInt()
        SetTimeout(500, function()
            if bleeding < 1.0 then
                bleeding = 1.0
            end
        end)
        SetTimeout(10000, function()
            if deathState ~= "knocked" or signalSent then return end
            SendNUIMessage({ type = "signal_hint" })
            startSignalThread()
        end)
    end

    CreateThread(function()
        local damageTime = GetGameTimer()
        local timecycleTime = 0
        local lastShownTime = nil
        local respawnShown = false

        -- only `deathState` gates this loop. It used to also read the
        -- LocalPlayer.state.dead statebag, which is written a frame earlier and is
        -- not guaranteed to read back yet -- when it didn't, the loop exited
        -- immediately and there was no animation, no timer and no death screen.
        while deathState == newDeathState do
            local ped = cache.ped
            local onStretcher = LocalPlayer.state.onStretcher

            if onStretcher and not IsEntityPlayingAnim(ped, "anim@gangops@morgue@table@", "body_search", 3) then
                TaskPlayAnim(ped, "anim@gangops@morgue@table@", "body_search", 47.0, 47.0, -1, 1, 0, false, false, false)
            elseif not onStretcher and not IsEntityPlayingAnim(ped, dict, clip, 3) then
                TaskPlayAnim(ped, dict, clip, 47.0, 47.0, -1, 1, 0, false, false, false)
            end

            local time = GetGameTimer()

            -- other resources (and the fades below) clear timecycle modifiers, so
            -- re-assert the red tint instead of setting it once and hoping.
            if time-timecycleTime > 1000 then
                timecycleTime = time
                SetTimecycleModifier("damage")
                SetTimecycleModifierStrength(newDeathState == "eliminated" and 1.0 or 0.6)
            end

            -- respawn countdown, runs in every death state.
            local remaining = data_death.timer-math.floor((time-deathStartedAt)/1000)
            if remaining > 0 then
                if remaining ~= lastShownTime then
                    lastShownTime = remaining
                    SendNUIMessage({ type = "timer", time = remaining })
                end
            elseif not respawnShown then
                respawnShown = true
                dbg("respawn timer finished, respawn available")
                SendNUIMessage({
                    type = "respawn_ready",
                    keybind = getRespawnKeybindLetter(),
                    cost = data_death.prices.respawn
                })

                if not respawnNotified then
                    respawnNotified = true
                    Bridge.notify({
                        title = "You can respawn",
                        description = ("Press %s to respawn at the hospital for $%s. You will leave your belongings behind. Wait for EMS to keep them."):format(getRespawnKeybindLetter(), data_death.prices.respawn),
                        type = "inform",
                        icon = "hospital",
                        iconColor = "#eb4034",
                        duration = 12000,
                        position = "top-center"
                    })
                end
            end

            if newDeathState == "eliminated" then
                SetPedDiesWhenInjured(ped, false)
                SetEntityCanBeDamaged(ped, false)
                SetEntityInvincible(ped, true)
                SetPlayerInvincible(cache.playerId, true)
            elseif time-damageTime > data_death.damageInterval*1000 then
                damageTime = time

                -- the black fade is the "losing consciousness" blink. Only do it
                -- when the player is actually bleeding out, otherwise it strobes
                -- over the death screen every few seconds for no reason.
                if bleeding > 0 then
                    ApplyDamageToPed(ped, data_death.damage)

                    DoScreenFadeOut(500)
                    SetTimeout(200, function()
                        DoScreenFadeIn(500)
                    end)
                end
            end

            SetEveryoneIgnorePlayer(ped, true)
            SetPedCanBeTargetted(ped, false)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedCanRagdollFromPlayerImpact(ped, false)

            Wait(0)
        end
    end)
end

-- set stateags and determine animation that should be playing.
local function setDeathState(newState)
    if knockedOut or deathState == "eliminated" then return end

    knockedOut = false
    local ped = PlayerPedId()

    if LocalPlayer.state.dead and deathState == "knocked" then
        newState = "eliminated"
    end

    local state = Player(cache.serverId).state
    state:set("isDead", newState, true)
    state:set("injuries", getInjuredBoneData(bodyBonesDamage), true)
    LocalPlayer.state.dead = true

    BlockActions(true)

    downAnim = downAnim or getRandomDeathAnim()
    local anim = downAnim[cache.vehicle and "vehicle" or newState]
    local dict, clip = anim[1], anim[2]
    lib.requestAnimDict(dict)
    setDead(ped, dict, clip, newState)
end

local function updatePreviousPlayerDeath()
    SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)

    if not Bridge.isDead() then return end
    dbg("player was dead on load, restoring death state")
    revivePlayer()
    setDeathState("knocked")
end

local function setPlayerKnockedOut()
    local state = Player(cache.serverId).state
    state:set("knockedout", true, true)
    SendNUIMessage({ type = "knocked_out" })
    knockedOut = true
    local timeKnocked = GetCloudTimeAsInt()

    CreateThread(function()
        while knockedOut and GetCloudTimeAsInt()-timeKnocked < 30 do
            SetPedToRagdoll(cache.ped, 5000, 5000, 0, true, true, false)
            Wait(500)
        end

        state:set("knockedout", false, true)
        if not knockedOut then return end
        SendNUIMessage({ type = "ambulance_reset" })
        knockedOut = false
    end)
end

local function getPedHealthPercentage(ped)
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    if health > maxHealth then
        health = maxHealth
    elseif health < 0 then
        health = 0
    end

    local total = (health/maxHealth)*100
    local scalingFactor = (health/maxHealth)+((100-total)/60)
    if scalingFactor < 0 then
        scalingFactor = -scalingFactor
    end
    return (health / (maxHealth*scalingFactor))*100
end

-- triggered locally by client/modules/death.lua when the player dies.
AddEventHandler("ND_Ambulance:playerEliminated", function(info)
    dbg("playerEliminated received, cause:", info.deathCause)
    Wait(2000)
    revivePlayer()

    -- set player as knocked out if injured with a non lethal weapon.
    if not knockedOut and not deathState and lib.table.contains(data_knockout, info.deathCause) then
        return setPlayerKnockedOut()
    end

    -- set player as knocked down dead if injured any other way.
    setDeathState("knocked")
end)

AddEventHandler("onResourceStart", function(resourceName)
    if cache.resource ~= resourceName then return end
    Wait(1000)
    updatePreviousPlayerDeath()
end)

local function resetDeathState()
    dbg("resetting death state")
    deathState = nil
    deathStartedAt = nil
    bleeding = 0
    bleedOutTimer = nil
    downAnim = nil
    signalSent = false
    respawnNotified = false
    bodyBonesDamage = lib.table.deepclone(data_bone_settings)
    SendNUIMessage({ type = "ambulance_reset" })
    AnimpostfxStop("DeathFailOut")
    ClearTimecycleModifier()

    local state = Player(cache.serverId).state
    state:set("isDead", false, true)
    state:set("injuries", false, true)
    state:set("cprData", nil, true)
    state:set("timeSinceDeath", nil, true)
    LocalPlayer.state.dead = false
    LocalPlayer.state.onStretcher = false

    if knockedOut then
        state:set("knockedout", false, true)
        knockedOut = false
    end

    -- the death loop leaves these on, nothing else clears them.
    -- PlayerPedId() rather than cache.ped: resurrecting can swap the ped handle
    -- and the cache only catches up on the next tick.
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) then
        revivePlayer()
        ped = PlayerPedId()
    end

    -- still attached to a stretcher or a carrying player.
    if IsEntityAttached(ped) then
        DetachEntity(ped, true, false)
    end
    if state.ambulanceCarry then
        state:set("ambulanceCarry", nil, true)
    end

    SetPedDiesWhenInjured(ped, true)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(cache.playerId, false)
    SetEntityCanBeDamaged(ped, true)
    SetEntityVisible(ped, true)
    SetEveryoneIgnorePlayer(ped, false)
    SetPedCanBeTargetted(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, true)
    FreezeEntityPosition(ped, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedTasks(ped)

    -- the death anim loop needs a frame to notice deathState changed, otherwise it
    -- re-applies TaskPlayAnim right after this and the player keeps lying down.
    SetTimeout(100, function()
        local currentPed = PlayerPedId()
        ClearPedTasks(currentPed)
        ClearPedSecondaryTask(currentPed)
    end)

    BlockActions(false)
    resetWalk()
end

-- the server side (Bridge.revivePlayer) fires this on revive, hospital
-- treatment and admin /revive.
RegisterNetEvent("ND_Ambulance:revivePlayer", function()
    if source == "" then return end
    dbg("revive received from server")

    -- respawning at the hospital resets locally and is announced by the server
    -- (bill + lost belongings), so don't claim the player kept anything here.
    local wasDown = deathState ~= nil and not respawning
    resetDeathState()

    if wasDown then
        Bridge.notify({
            title = "You've been treated",
            description = "You were helped in time and kept your belongings.",
            type = "success",
            icon = "kit-medical",
            duration = 8000,
            position = "top-center"
        })
    end
end)

-- txAdmin's "heal player" / "heal all" fires this on the healed client. A downed
-- player is already at max health (setDead resurrects them into a down-animation
-- loop), so a plain heal changes nothing and the loop keeps forcing them to the
-- ground -- exactly the "admin/txadmin heal doet niks, ik blijf liggen"-bug.
-- Treat any heal received while down as a full revive so admins can get players up.
RegisterNetEvent("txcl:heal", function()
    if source == "" then return end
    if not deathState and not knockedOut then return end
    dbg("txAdmin heal received while down -> reviving")
    resetDeathState()
end)

-- qbx_adminmenu's revive-knop stuurt dit (server: TriggerClientEvent, of lokaal
-- TriggerEvent). qbx_medical is gestopt, dus zonder deze handler doet die knop
-- niks. ND vangt hem nu op zodat de admin-menu revive gewoon werkt.
RegisterNetEvent("qbx_medical:client:playerRevived", function()
    dbg("qbx_medical revive-event ontvangen -> ND resetDeathState")
    resetDeathState()
end)

-- triggered by shared/bridge.lua when qbx finishes loading the character.
AddEventHandler("ND_Ambulance:characterLoaded", function()
    Wait(4000)
    updatePreviousPlayerDeath()
end)

lib.onCache("ped", function()
    SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)
end)

CreateThread(function()
    local notifyInfo = {
        id = "playerBleeding",
        icon = "droplet",
        iconColor = "#eb4034",
        duration = 4000,
        position = "top-center"
    }

    while true do
        Wait(3000)
        if bleeding <= 0 then goto skip end

        local bleed = math.floor(bleeding/2)

        if bleed > 0 and (GetEntityHealth(cache.ped)-100) > bleed and not deathState then
            ApplyDamageToPed(cache.ped, bleed)
            notifyInfo.title = "You're bleeding!"
            Bridge.notify(notifyInfo)
        elseif bleed > 0 and not deathState then
            bleedOutTimer = GetCloudTimeAsInt()
            setDeathState("knocked")
            notifyInfo.title = "You need help!"
            Bridge.notify(notifyInfo)
        elseif bleed > 0 and deathState == "knocked" and bleedOutTimer and GetCloudTimeAsInt()-bleedOutTimer > 120 then
            setDeathState("eliminated")
            notifyInfo.title = "You bled out!"
            Bridge.notify(notifyInfo)
        end

        ::skip::
    end
end)

function getLastDamagingWeapon(ped)
    for i=0, 2 do
        for weapon, info in pairs(data_weapons) do
            if HasPedBeenDamagedByWeapon(ped, weapon, i) then
                ClearEntityLastDamageEntity(ped)
                return info
            end
        end
    end
end

function getBodyDamage()
    return bodyBonesDamage
end

function updateBodyDamage(bone, damageWeapon)
    local health = getPedHealthPercentage(cache.ped)
    if health > 80 then return end

    local boneName = data_bones[bone]
    if not boneName or not damageWeapon then return end

    local boneInfo = bodyBonesDamage[boneName]
    local updateDamageOn = {"fracture", "burn", "bleeding", "suffocating"}

    for i=1, #updateDamageOn do
        local item = updateDamageOn[i]
        if damageWeapon[item] then
            if not boneInfo[item] then
                boneInfo[item] = 0
            end
            boneInfo[item] += damageWeapon.severity
            boneInfo.severity += damageWeapon.severity
        end
    end

    if not boneInfo.injury then
        boneInfo.injury = {}
    end

    if not lib.table.contains(boneInfo.injury, damageWeapon.injury) then
        boneInfo.injury[#boneInfo.injury+1] = damageWeapon.injury
    end

    bleeding = GetTotalDamageType(bodyBonesDamage, "bleeding")
    hurtWalk()
    updateInjuryStatus()
end

exports("getLastDamagingWeapon", getLastDamagingWeapon)

exports("getBodyDamage", getBodyDamage)

exports("updateBodyDamage", updateBodyDamage)

respawnKeybind = lib.addKeybind({
    name = "respawn",
    description = "Respawn when dead",
    defaultKey = data_death.keybind,
    onPressed = function(self)
        -- works from both "knocked" and "eliminated", but only once the timer
        -- ran out.
        if respawning or not deathState or not deathStartedAt then return end

        local waited = math.floor((GetGameTimer()-deathStartedAt)/1000)
        if waited < data_death.timer then
            return dbg(("respawn rejected: waited %ss of %ss"):format(waited, data_death.timer))
        end

        respawning = true
        local coords = getNearestRespawnPoint()

        DoScreenFadeOut(500)
        Wait(500)

        -- wait for the server to actually bill the player and drop their
        -- inventory. This used to be a fire-and-forget event followed by a local
        -- reset, so a server-side rejection still gave a free respawn.
        --
        -- pcall is required: lib.callback.await raises (rather than returning nil)
        -- when the callback isn't registered server-side or the request times out.
        -- Letting that propagate would kill this thread with the screen still
        -- faded to black and `respawning` stuck true, so the player could never
        -- retry.
        local ok, approved = pcall(lib.callback.await, "ND_Ambulance:respawnPlayer", false)

        if not ok or not approved then
            dbg("respawn not granted:", ok and "server declined" or tostring(approved))
            DoScreenFadeIn(500)
            respawning = false
            return
        end

        dbg("respawning at hospital")
        resetDeathState()
        Teleport(PlayerPedId(), coords, false)

        DoScreenFadeIn(500)
        respawning = false
    end
})

RegisterNetEvent("ND_Ambulance:successDefib", function()
    if source == "" then return end
    deathState = nil
    setDeathState("knocked")
end)

-- De server heeft het noodsignaal goedgekeurd en stuurt het hier terug, omdat
-- ps-dispatch zijn CustomAlert alleen client-side heeft. Zie server/main.lua.
RegisterNetEvent("ND_Ambulance:sendDispatchAlert", function(location, coords)
    if type(coords) ~= "vector3" then return end

    -- `description` bestaat niet in CustomAlert en werd stilzwijgend weggegooid;
    -- straat en zone vult ps-dispatch zelf in. En `dispatchCode` is de interne
    -- naam terwijl `code` op het scherm komt - hier stond alleen dispatchCode,
    -- dus de melding toonde de standaard "10-80" in plaats van 10-13.
    local message = "Distress signal, EMS needed!"

    if location and location ~= "" then
        message = ("%s - %s"):format(message, location)
    end

    exports["ps-dispatch"]:CustomAlert({
        coords = coords,
        message = message,
        dispatchCode = "emsdistress",
        code = "10-13",
        icon = "fas fa-kit-medical",
        priority = 1,
        radius = 0,
        sprite = 153,
        color = 6,
        scale = 1.0,
        length = 3,
        jobs = { "ems" }
    })
end)

-- fallback for servers without ps-dispatch: EMS gets a notify plus a temporary blip.
RegisterNetEvent("ND_Ambulance:distressSignal", function(location, coords)
    if source == "" or type(coords) ~= "vector3" then return end

    Bridge.notify({
        title = "Distress signal",
        description = ("EMS needed: %s"):format(location or "unknown location"),
        type = "inform",
        icon = "kit-medical",
        iconColor = "#eb4034",
        duration = 10000,
        position = "top-center"
    })

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 153)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Distress signal")
    EndTextCommandSetBlipName(blip)

    PlaySoundFrontend(-1, "Lose_1st", "GTAO_FM_Events_Soundset", true)

    SetTimeout(180000, function()
        RemoveBlip(blip)
    end)
end)

AddStateBagChangeHandler("injuries", nil, function(bagName, key, value, reserved, replicated)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == 0 or replicated then return end

    local src = GetPlayerServerId(ply)
    if src ~= cache.serverId or not value then return end

    for bone, limb in pairs(bodyBonesDamage) do
        local updatedLimb = value[bone]
        if updatedLimb then
            limb.suffocating = updatedLimb.suffocating
            limb.fracture = updatedLimb.fracture
            limb.burn = updatedLimb.burn
            limb.bleeding = updatedLimb.bleeding
            limb.severity = updatedLimb.severity
        end
    end

    bleeding = GetTotalDamageType(bodyBonesDamage, "bleeding")
    hurtWalk()
end)

if Bridge.getDeathModule then
    Bridge.getDeathModule() -- for frameworks that don't have compatible death system.
end

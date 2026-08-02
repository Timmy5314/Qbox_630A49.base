local data_death = require("data.death")
local data_jobs = require("data.jobs")

local function isNearHospitalPed(coords)
    for i=1, #data_death.hospitalPeds do
        local location = data_death.hospitalPeds[i]
        if #(coords-location.xyz) < 5 then
            return true
        end
    end
end

local function getEntityFromNetId(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local time = os.time()
    while not DoesEntityExist(entity) and os.time()-time < 5 do Wait(100) end
    return entity
end

local function allowCheck(src, targetPlayerSrc)
    targetPlayerSrc = tonumber(targetPlayerSrc)
    if not targetPlayerSrc then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local targetPed = GetPlayerPed(targetPlayerSrc)
    local targetCoords = GetEntityCoords(targetPed)
    local state = Player(targetPlayerSrc).state
    if src == targetPlayerSrc or #(coords-targetCoords) > 10 or state.isDead ~= "eliminated" then return end

    return true
end

RegisterNetEvent("ND_Ambulance:sendSignal", function(location, coords)
    local src = source

    if not location or not coords or type(location) ~= "string" or type(coords) ~= "vector3" then
        return
    end

    if not Player(src).state.isDead then return end

    -- confirm to the sender, otherwise there is no way to tell it went through.
    Bridge.notify(src, {
        title = "Distress signal sent",
        description = "EMS has been notified of your location.",
        type = "inform",
        icon = "kit-medical",
        duration = 6000
    })

    -- Server-intern haakje voor andere resources. los_aidoctor hangt hieraan:
    -- die luisterde eerst rechtstreeks op dit net event, en of een
    -- AddEventHandler in een andere resource dan meevuurt hangt af van hoe
    -- FiveM binnenkomende net events routeert. Een gewone TriggerEvent bereikt
    -- aantoonbaar alle resources.
    --
    -- Bewust hier, vóór de ps-dispatch-tak: die doet een `return`.
    TriggerEvent("ND_Ambulance:signalSent", src, location, coords)

    if GetResourceState("ps-dispatch"):find("start") then
        -- `CustomAlert` bestaat alleen client-side (ps-dispatch/client/alerts.lua);
        -- server-side heeft ps-dispatch maar een export, GetDispatchCalls. Deze
        -- aanroep gooide dus "No such export CustomAlert" en de EMS-melding is
        -- nooit aangekomen. Loopt nu via de client van de speler zelf, want
        -- CustomAlert vult straat en zone aan met GetStreetAndZone en dat kan
        -- alleen daar.
        TriggerClientEvent("ND_Ambulance:sendDispatchAlert", src, location, coords)

        if data_death.debug then
            print(("[ND_Ambulance] distress signal from %s (%s) at %s -> ps-dispatch"):format(src, GetPlayerName(src), location))
        end
        return
    end

    -- no dispatch resource installed, alert EMS players directly.
    local players = GetPlayers()
    local notified = 0
    for i = 1, #players do
        local target = tonumber(players[i])
        if target and target ~= src and Bridge.hasJobs(target, data_jobs) then
            TriggerClientEvent("ND_Ambulance:distressSignal", target, location, coords)
            notified += 1
        end
    end

    if data_death.debug then
        print(("[ND_Ambulance] distress signal from %s (%s) at %s -> notified %d EMS player(s)"):format(src, GetPlayerName(src), location, notified))
    end
end)

-- server-owned respawn clock, keyed by player source. The client used to write its
-- death timestamp into its own statebag and the server compared that against
-- os.time(); that trusted client data and broke outright whenever the game clock
-- and the machine clock disagreed.
local deathTimes = {}

local function clearDeathTime(src)
    deathTimes[src] = nil
end

RegisterNetEvent("ND_Ambulance:playerDown", function()
    local src = source
    if deathTimes[src] then return end

    deathTimes[src] = os.time()
    if data_death.debug then
        print(("[ND_Ambulance] %s (%s) went down, respawn allowed in %ss"):format(src, GetPlayerName(src), data_death.timer))
    end
end)

AddEventHandler("playerDropped", function()
    clearDeathTime(source)
end)

--[[
    Een revive die BIJ DE CLIENT begint: de txAdmin heal-knop en de revive uit
    qbx_adminmenu. Die zetten alleen de clientstaat terug; de server wist dan
    nog steeds niet dat de speler weer overeind is.

    Dat is niet cosmetisch. qbx_core hangt de statebag `canUseWeapons` aan de
    metadata `isdead` (server/player.lua: SetMetadata -> canUseWeapons = not
    value). Bleef `isdead` op true staan, dan bleef `canUseWeapons` op false, en
    ox_inventory weigert dan stilletjes elk wapen:

        client.lua:528
        if EnableWeaponWheel or not client.player:get('canUseWeapons') then return end

    Geen foutmelding, geen notificatie - er gebeurt gewoon niets. Wie zich als
    admin liet revivenen kon daarna tot de volgende login geen wapen meer pakken.
]]
RegisterNetEvent("ND_Ambulance:clientSelfRevived", function()
    local src = source
    if not src or src == 0 then return end

    Bridge.clearDeadMetadata(src)
    clearDeathTime(src)

    if data_death.debug then
        print(("[ND_Ambulance] client-side revive van %s: dead-metadata gewist"):format(src))
    end
end)

-- fired by Bridge.revivePlayer: defib, hospital treatment, EMS and /revive.
AddEventHandler("ND_Ambulance:playerRevived", function(src)
    clearDeathTime(src)

    -- Tell the anti-cheat this health jump is legitimate. Without it a revive
    -- reads as healthRegen: 0 -> 200 with no source.
    if GetResourceState("los_anticheat") == "started" then
        exports.los_anticheat:ExpectHeal(src, 15)
    end
end)

lib.callback.register("ND_Ambulance:respawnPlayer", function(src)
    local downSince = deathTimes[src]
    -- 2s grace so a frame of latency between the client's countdown and this
    -- check can't reject a respawn the player legitimately waited out.
    if not downSince or os.time()-downSince < data_death.timer-2 then
        if data_death.debug then
            print(("[ND_Ambulance] respawn rejected for %s: downSince=%s"):format(src, downSince))
        end
        return false
    end

    local price = data_death.prices.respawn
    if price and price > 0 then
        if Bridge.hasMoney(src, price) then
            Bridge.deductMoney(src, price)
            Bridge.notify(src, {
                title = "Hospital bill",
                description = ("You paid $%s for your treatment."):format(price),
                type = "inform",
                icon = "file-invoice-dollar",
                duration = 8000
            })
        else
            Bridge.notify(src, {
                title = "Hospital bill",
                description = ("You couldn't afford the $%s hospital bill."):format(price),
                type = "error",
                icon = "file-invoice-dollar",
                duration = 8000
            })
        end
    end

    -- drop the inventory BEFORE the client teleports, so the items stay at the
    -- spot where the player died.
    if data_death.dropInventory then
        exports.ox_inventory:CreateDropFromPlayer(src)
        Bridge.notify(src, {
            title = "Belongings lost",
            description = "You left your belongings behind at the scene.",
            type = "inform",
            icon = "box-open",
            duration = 8000
        })
    end

    -- no TriggerClientEvent revive here: the client resets itself as soon as this
    -- returns true, and doing both resurrected the ped twice.
    Bridge.clearDeadMetadata(src)
    clearDeathTime(src)

    if data_death.debug then
        print(("[ND_Ambulance] %s (%s) respawned at hospital, billed $%s"):format(src, GetPlayerName(src), price or 0))
    end

    return true
end)

---Is this player covered by medical insurance?
---Returns false while the insurance resource does not exist yet, so everyone
---simply pays their own way until it does.
---@param src number
---@return boolean
local function isInsured(src)
    local config = data_death.insurance
    if not config or not config.enabled then return false end
    if GetResourceState(config.resource) ~= "started" then return false end

    local ok, result = pcall(function()
        return exports[config.resource]:hasMedicalInsurance(src)
    end)

    return ok and result == true
end

---Puts the bill with the insurer. Falls back to the player when the claim is
---refused, so treatment is never handed out for free by accident.
---@param src number
---@param price number
---@return boolean paid
local function settleTreatment(src, price)
    if price <= 0 then return true end

    if isInsured(src) then
        local config = data_death.insurance
        local ok, claimed = pcall(function()
            return exports[config.resource]:claimMedical(src, price)
        end)

        if ok and claimed then
            Bridge.notify(src, {
                title = "Covered by insurance",
                description = ("Your medical insurance paid the $%s bill."):format(price),
                type = "success",
                duration = 10000
            })
            return true
        end
    end

    if not Bridge.hasMoney(src, price) then
        Bridge.notify(src, {
            title = "Not enough money",
            type = "error"
        })
        return false
    end

    Bridge.deductMoney(src, price)
    return true
end

RegisterNetEvent("ND_Ambulance:treatSelf", function()
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local player = Bridge.getPlayer(src)
    if not player or not isNearHospitalPed(coords) then return end

    if not settleTreatment(src, data_death.prices.selfHeal) then return end

    TriggerClientEvent("ND_Ambulance:respawnHospital", src)
    Wait(1000)

    Bridge.revivePlayer(src)
    Bridge.notify(src, {
        title = "Succesfully healed!",
        type = "success"
    })
end)

RegisterNetEvent("ND_Ambulance:treatPatient", function(targetSrc, stretcherNetId)
    local src = source
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return end
    
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local player = Bridge.getPlayer(src)

    local targetPed = GetPlayerPed(targetSrc)
    local targetCoords = GetEntityCoords(targetPed)
    local targetPlayer = Bridge.getPlayer(targetSrc)

    if stretcherNetId then
        local entity = getEntityFromNetId(stretcherNetId)
        if not DoesEntityExist(entity) then return end
        local state = Entity(entity).state
        state:set("ambulanceStretcherPlayer", false, true)
    end

    if not player or not targetPlayer or not isNearHospitalPed(coords) or not isNearHospitalPed(targetCoords) then return end
    
    -- Was prices.selfHeal, waardoor prices.otherHeal nergens werd gebruikt en
    -- behandeld worden door iemand anders even duur was als het zelf regelen.
    -- Ook ging Bridge.deductMoney hier zonder saldocheck: een patient zonder
    -- geld werd gewoon gereanimeerd. settleTreatment doet beide, en laat de
    -- verzekering meebetalen.
    if not settleTreatment(targetSrc, data_death.prices.otherHeal) then
        return Bridge.notify(src, {
            title = "Patient cannot pay",
            description = "They have no insurance and not enough money for the bill.",
            type = "error"
        })
    end

    Bridge.notify(src, {
        title = "Succesfully treated patient!",
        type = "success"
    })

    TriggerClientEvent("ND_Ambulance:respawnHospital", targetSrc)
    Wait(700)

    Bridge.revivePlayer(targetSrc)
    Bridge.notify(targetSrc, {
        title = "Succesfully healed!",
        type = "success"
    })
end)

RegisterNetEvent("ND_Ambulance:startCpr", function(targetPlayerSrc)
    local src = source
    if not allowCheck(src, targetPlayerSrc) then return end
    
    local playerState = Player(src).state
    playerState:set("performingCpr", targetPlayerSrc, false)

    local state = Player(targetPlayerSrc).state
    local cprData = state.cprData or {}
    state:set("cprData", {
        ongoing = true,
        started = cprData.started or os.time(),
        stopped = false
    }, true)
    
    local changed = false
    local injuries = state.injuries
    for bone, limb in pairs(injuries) do
        if limb and limb.suffocating and limb.severity and limb.severity > 0 then
            limb.severity -= limb.suffocating
            limb.suffocating = nil
            changed = true
        end
    end

    if changed then
        state:set("injuries", injuries, true)
    end
end)

RegisterNetEvent("ND_Ambulance:stopCpr", function(targetPlayerSrc)
    local src = source
    if not allowCheck(src, targetPlayerSrc) then return end
    
    local playerState = Player(src).state
    playerState:set("performingCpr", nil, false)

    local state = Player(targetPlayerSrc).state
    local cprData = state.cprData or {}
    local time = os.time()
    state:set("cprData", {
        ongoing = false,
        started = cprData.started or time,
        stopped = time
    }, true)
end)

local function stopCprOnLogout(src)
    if not src then return end
    local playerState = Player(src).state
    if not playerState.performingCpr then return end

    local state = Player(playerState.performingCpr).state
    if state.cprData then        
        local cprData = state.cprData or {}
        local time = os.time()
        state:set("cprData", {
            ongoing = false,
            started = cprData.started or time,
            stopped = time
        }, true)
    end

    playerState:set("performingCpr", nil, false)
end

AddEventHandler("qbx_core:server:playerLoggedOut", function(src)
    stopCprOnLogout(src)
end)

AddEventHandler("playerDropped", function()
    stopCprOnLogout(source)
end)

RegisterNetEvent("ND_Ambulance:successDefib", function(targetPlayerSrc)
    local src = source
    local state = Player(targetPlayerSrc).state
    if not allowCheck(src, targetPlayerSrc) then return end
    TriggerClientEvent("ND_Ambulance:successDefib", targetPlayerSrc)
end)

RegisterNetEvent("ND_Ambulance:pickupDefib", function()
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local objects = lib.getNearbyObjects(coords, 2.0)
    for i=1, #objects do
        local entity = objects[i].object
        if DoesEntityExist(entity) and GetEntityModel(entity) == `lifepak15` then
            DeleteEntity(entity)
            return exports.ox_inventory:AddItem(src, "defib", 1)
        end
    end
end)

exports.ox_inventory:registerHook("swapItems", function(payload)
    if payload.toType ~= "player" or payload.fromInventory == payload.toInventory then return end
    return exports.ox_inventory:GetItemCount(payload.toInventory, "defib") == 0
end, {
    itemFilter = {
        defib = true
    }
})

if Bridge.setDeadMetadata then
    RegisterNetEvent("ND_Ambulance:playerEliminated", function(info)
        local src = source
        Bridge.setDeadMetadata(src, info)
    end)    
end

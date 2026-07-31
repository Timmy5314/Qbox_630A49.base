Ox_inventory = exports.ox_inventory
local glm = require 'glm'
local config = lib.load("data.config")
local shotspotterData = lib.load("data.shotspotter")

-- Elke handler hieronder wordt door een client afgevuurd. De client bepaalt dus
-- WAT hij wil, nooit OF het mag: dat hoort hier te staan. In de originele versie
-- ontbrak die laag vrijwel volledig.

local MAX_SPIKE_SIZE = 4
local MAX_SPIKE_DISTANCE = 25.0

---@param playerId any
---@return number? serverId
---@return number? ped
local function resolvePlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId or playerId <= 0 then return end

    local ped = GetPlayerPed(playerId)
    if ped == 0 then return end

    return playerId, ped
end

RegisterServerEvent('ND_Police:deploySpikestrip', function(data)
    local src = source

    if type(data) ~= 'table' then return end

    local size = tonumber(data.size)
    local segment = data.segment

    -- `count < data.size` liet een negatieve size door: RemoveItem draaide dan
    -- met een negatief aantal. Vandaar de expliciete integer-range.
    if not size or size ~= math.floor(size) or size < 1 or size > MAX_SPIKE_SIZE then return end

    if type(segment) ~= 'table' or type(segment[1]) ~= 'vector3' or type(segment[2]) ~= 'vector3' then return end
    if #(segment[1] - segment[2]) < 0.5 then return end -- glm.direction op twee gelijke punten geeft NaN

    if not Bridge.hasJobs(src, config.policeGroups) then return end

    local ped = GetPlayerPed(src)
    if ped == 0 or GetVehiclePedIsIn(ped, false) ~= 0 then return end

    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - segment[1]) > MAX_SPIKE_DISTANCE or #(pedCoords - segment[2]) > MAX_SPIKE_DISTANCE then return end

    local count = Ox_inventory:Search(src, 'count', 'spikestrip')
    if type(count) ~= 'number' or count < size then return end

    if not Ox_inventory:RemoveItem(src, 'spikestrip', size) then return end

    local dir = glm.direction(segment[1], segment[2])

    for i = size, 1, -1 do
        local coords = glm.segment.getPoint(segment[1], segment[2], (i * 2 - 1) / (size * 2))
        local object = CreateObject(`p_ld_stinger_s`, coords.x, coords.y, coords.z, true, true, true)

        while not DoesEntityExist(object) do
            Wait(0)
        end

        SetEntityRotation(object, math.deg(-math.sin(dir.z)), 0.0, math.deg(math.atan(dir.y, dir.x)) + 90, 2, false)
        Entity(object).state:set('inScope', true, true)
        Wait(800)
    end
end)

RegisterServerEvent('ND_Police:retrieveSpikestrip', function(netId)
    local src = source
    netId = tonumber(netId)
    if not netId then return end

    local ped = GetPlayerPed(src)
    if ped == 0 or GetVehiclePedIsIn(ped, false) ~= 0 then return end

    local spike = NetworkGetEntityFromNetworkId(netId)

    -- Zonder modelcontrole kon elke netId worden meegestuurd: dat verwijderde een
    -- willekeurige entity op de server en leverde ook nog een gratis spikestrip op.
    if not DoesEntityExist(spike) or GetEntityModel(spike) ~= `p_ld_stinger_s` then return end

    if #(GetEntityCoords(ped) - GetEntityCoords(spike)) > 5 then return end

    if not Ox_inventory:CanCarryItem(src, 'spikestrip', 1) then return end

    DeleteEntity(spike)

    Ox_inventory:AddItem(src, 'spikestrip', 1)
end)

RegisterServerEvent('ND_Police:setPlayerEscort', function(target, state, setIntoVeh, setIntoSeat, exitVeh)
    local src = source

    local targetPed
    target, targetPed = resolvePlayer(target)
    if not target or target == src then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local playerCoords = GetEntityCoords(ped)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return end

    local playerState = Player(src).state
    local targetState = Player(target).state

    -- Hier stond geen enkele controle. Iedereen kon elke speler binnen 10 meter
    -- aan zich vastmaken, naar zich toe teleporteren (exitVeh) en in een auto
    -- zetten - geen boeien nodig, geen job nodig.
    if state then
        if not targetState.isCuffed then return end
        if playerState.isCuffed or playerState.handsUp or playerState.gettingCuffed then return end
    elseif targetState.isEscorted and targetState.isEscorted ~= src then
        -- Losmaken mag alleen degene die hem vasthoudt.
        return
    end

    if exitVeh and GetVehiclePedIsIn(targetPed, false) ~= 0 then
        SetEntityCoords(targetPed, playerCoords.x, playerCoords.y, playerCoords.z)
    end

    targetState:set('isEscorted', state and src, true)

    if not setIntoVeh then return end

    local seat = tonumber(setIntoSeat)
    if not seat or seat < -1 or seat > 16 then return end

    Wait(500)

    local veh = NetworkGetEntityFromNetworkId(tonumber(setIntoVeh) or 0)
    if not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end
    if #(GetEntityCoords(veh) - GetEntityCoords(targetPed)) > 10.0 then return end

    SetPedIntoVehicle(targetPed, veh, seat)
end)

RegisterNetEvent('ND_Police:gsrTest', function(target)
    local src = source

    local targetPed
    target, targetPed = resolvePlayer(target)
    if not target then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    -- De ox_target-optie is al op politie gefilterd, maar dat is client-side en
    -- dus geen controle. Zonder dit kon iedereen iedereen testen.
    if not Bridge.hasJobs(src, config.policeGroups) then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 5.0 then return end

    if Player(target).state.shot then
        return Bridge.notify(src, {
            type = 'success',
            description = locale("gsr_positive")
        })
    end

    Bridge.notify(src, {
        type = 'error',
        description = locale("gsr_negative")
    })
end)

local shotspotterLast = {}

RegisterNetEvent("ND_Police:shotspotter", function(location, coords)
    local src = source

    -- De cooldown stond alleen in de client; een aangepaste client kon dispatch
    -- daarmee volspammen.
    local now = os.time()
    local last = shotspotterLast[src]
    if last and now - last < (shotspotterData.cooldown or 120) then return end
    shotspotterLast[src] = now

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    -- De client stuurt de coordinaten van het moment van schieten; die zijn
    -- nauwkeuriger dan de serverpositie een seconde later. Wel toetsen dat ze in
    -- de buurt liggen, anders kun je een melding op een verzonnen plek zetten.
    local pedCoords = GetEntityCoords(ped)
    if type(coords) ~= 'vector3' or #(coords - pedCoords) > 150.0 then
        coords = pedCoords
    end

    if type(location) ~= 'string' then
        location = ''
    elseif #location > 80 then
        location = location:sub(1, 80)
    end

    Bridge.shotSpotter(src, location, coords)
end)

local backupLast = {}

RegisterNetEvent("ND_Police:requestBackup", function(distress)
    local src = source

    if not Bridge.hasJobs(src, config.policeGroups) then return end

    if not GetResourceState("ps-dispatch"):find("start") then
        return Bridge.notify(src, {
            type = "error",
            description = locale("backup_unavailable")
        })
    end

    local now = os.time()
    local last = backupLast[src]
    if last and now - last < config.backupCooldown then
        return Bridge.notify(src, {
            type = "error",
            description = locale("backup_cooldown")
        })
    end
    backupLast[src] = now

    -- ps-dispatch bouwt de melding client-side op (naam, callsign, straat en
    -- coordinaten), dus daar moet hij afgevuurd worden. De autorisatie hoort
    -- hier: zonder deze stap kon iedereen de politie-alarmering afvuren.
    TriggerClientEvent("ND_Police:sendBackupAlert", src, distress and true or false)

    Bridge.notify(src, {
        type = "success",
        description = locale(distress and "backup_distress_sent" or "backup_sent")
    })
end)

AddEventHandler('playerDropped', function()
    local src = source
    shotspotterLast[src] = nil
    backupLast[src] = nil

    -- Client-side wordt het schild-prop aan een serverId gehangen. Zonder deze
    -- melding bleef dat prop na een disconnect voorgoed in de wereld hangen:
    -- de client luisterde op `onPlayerDropped`, en dat is een server-event.
    TriggerClientEvent('ND_Police:playerDropped', -1, src)
end)

RegisterNetEvent("ND_Police:impoundVehicle", function(netId, impoundReclaimPrice, reason)
    local src = source

    impoundReclaimPrice = tonumber(impoundReclaimPrice)

    if not impoundReclaimPrice or impoundReclaimPrice > config.maxImpoundPrice or impoundReclaimPrice < config.minImpoundPrice then
        return Bridge.notify(src, {
            type = "error",
            description = locale("invalid_impound_price")
        })
    end

    if not Bridge.hasJobs(src, config.policeGroups) then
        return Bridge.notify(src, {
            type = "error",
            description = locale("no_perms_impound")
        })
    end

    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)

    if not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return Bridge.notify(src, {
            type = "error",
            description = locale("veh_not_found_try_again")
        })
    end

    local vehCoords = GetEntityCoords(vehicle)
    local pedCoords = GetEntityCoords(GetPlayerPed(src))

    if #(vehCoords-pedCoords) > 5 then
        return Bridge.notify(src, {
            type = "error",
            description = locale("too_far_from_veh")
        })
    end

    if type(reason) ~= 'string' or reason == '' then
        reason = locale("impound_reason_default")
    elseif #reason > 120 then
        reason = reason:sub(1, 120)
    end

    -- `Bridge.impoundVehicle` bestond niet - die if was altijd onwaar. Het
    -- voertuig werd dus alleen verwijderd, terwijl de bevestiging belooft dat de
    -- eigenaar hem bij de impound kan ophalen. Die auto was gewoon weg.
    local stored = false

    if GetResourceState("renzu_garage"):find("start") then
        local impounder = "LSPD"
        local player = exports.qbx_core:GetPlayer(src)
        local charinfo = player and player.PlayerData and player.PlayerData.charinfo

        if charinfo then
            impounder = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
        end

        local ok, result = pcall(function()
            return exports.renzu_garage:ImpoundVehicle(GetVehicleNumberPlateText(vehicle), {
                fine = impoundReclaimPrice,
                reason = reason,
                impounder = impounder
            })
        end)

        if not ok then
            lib.print.error(("renzu_garage:ImpoundVehicle faalde: %s"):format(result))
        end

        stored = ok and result or false
    end

    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end

    Bridge.notify(src, {
        type = stored and "success" or "inform",
        description = locale(stored and "impound_stored" or "impound_not_owned")
    })
end)

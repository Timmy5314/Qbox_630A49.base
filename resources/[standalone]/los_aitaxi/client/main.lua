--[[
    De rit. Draait bij de speler die belt: die is altijd in de buurt van wat er
    gebeurt, dus er hoeft niets gesynct te worden dat niemand anders ziet.

    Alles zit in een enkele thread die stopt zodra de rit klaar is. Geen
    permanente loops - zonder rit kost deze resource niets.
]]

local config = require 'shared.config'

local active = false
local vehicle, driver

-- =========================================================================
--  De meter
--
--  Een NUI-overlay, geen dashboardmeter. De meter die je in het taxi-model ziet
--  zitten is onderdeel van het model; GTA V heeft geen native om die cijfers aan
--  te sturen (dat kon in IV wel). Een overlay is wat er overblijft, en die is
--  bovendien leesbaar vanuit elke camerahoek.
--
--  Puur weergave. De server rekent zelf af en begrenst; wat hier staat is
--  dezelfde som zodat het eindbedrag niet uit de lucht komt vallen.
-- =========================================================================

local meterOpen = false

local function showMeter()
    if meterOpen then return end
    meterOpen = true

    SendNUIMessage({
        action = 'show',
        company = config.companyName,
        base = config.fare.base,
        labels = {
            distance = locale('meter_distance'),
            start = locale('meter_start'),
            capped = locale('meter_capped'),
        },
    })
end

---@param metres number
local function updateMeter(metres)
    if not meterOpen then return end

    local km = metres / 1000
    local fare = config.fare.base + math.floor(km * config.fare.perKm)
    local capped = fare > config.fare.max

    if capped then fare = config.fare.max end

    SendNUIMessage({ action = 'update', fare = fare, distance = km, capped = capped })
end

local function hideMeter()
    if not meterOpen then return end
    meterOpen = false
    SendNUIMessage({ action = 'hide' })
end

local function cleanup()
    hideMeter()

    if driver and DoesEntityExist(driver) then DeleteEntity(driver) end
    if vehicle and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end

    driver, vehicle = nil, nil
    active = false
end

---@param model number
---@return boolean
local function loadModel(model)
    if not IsModelValid(model) then return false end
    lib.requestModel(model, 10000)
    return HasModelLoaded(model)
end

---Waar de taxi vandaan komt: het dichtstbijzijnde depot, of anders een
---wegknooppunt op afstand van de speler.
---@param depots table?
---@param coords vector3
---@return vector4?
local function pickSpawn(depots, coords)
    if depots and #depots > 0 then
        local best, bestDist

        for i = 1, #depots do
            local d = depots[i]
            local dist = #(coords - vec3(d.x, d.y, d.z))

            if not bestDist or dist < bestDist then
                best, bestDist = d, dist
            end
        end

        return best
    end

    -- Geen depot ingesteld. Zoek een wegknooppunt buiten beeld. Nodes worden
    -- van dichtbij naar ver genummerd, dus we lopen op tot we ver genoeg zitten.
    for n = 1, 60 do
        local found, node, heading = GetNthClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, n, 1, 3.0, 0)

        if found then
            local dist = #(coords - node)

            if dist >= config.spawnMinDistance and dist <= config.spawnMaxDistance then
                return vec4(node.x, node.y, node.z, heading)
            end
        end
    end
end

RegisterNetEvent('los_aitaxi:startRide', function(data)
    if active then return end
    active = true

    local playerCoords = GetEntityCoords(cache.ped)
    local spawn = pickSpawn(data and data.depots, playerCoords)

    if not spawn or not loadModel(config.models.vehicle) or not loadModel(config.models.driver) then
        active = false
        return TriggerServerEvent('los_aitaxi:rideFailed')
    end

    vehicle = CreateVehicle(config.models.vehicle, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    while not DoesEntityExist(vehicle) do Wait(0) end

    driver = CreatePedInsideVehicle(vehicle, 4, config.models.driver, -1, true, false)

    SetModelAsNoLongerNeeded(config.models.vehicle)
    SetModelAsNoLongerNeeded(config.models.driver)

    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityInvincible(driver, true)
    SetEntityInvincible(vehicle, true)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetDriverAbility(driver, 1.0)
    SetDriverAggressiveness(driver, 0.0)
    SetVehicleDoorsLocked(vehicle, 1)

    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 198)
    SetBlipColour(blip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(config.companyName)
    EndTextCommandSetBlipName(blip)

    lib.notify({ description = locale('taxi_dispatched'), type = 'inform', duration = 8000 })

    CreateThread(function()
        local started = GetGameTimer()
        local arrived = false

        -- 262588: normale route, houdt zich aan de weg en stopt voor verkeer.
        local function driveTo(target)
            TaskVehicleDriveToCoordLongrange(driver, vehicle, target.x, target.y, target.z, 20.0, 262588, config.arriveDistance)
        end

        -- ── Naar de speler ────────────────────────────────────────────────
        while active and not arrived do
            Wait(500)

            if not DoesEntityExist(vehicle) or not DoesEntityExist(driver) then break end

            local target = GetEntityCoords(cache.ped)
            driveTo(target)

            if #(GetEntityCoords(vehicle) - target) <= config.arriveDistance then
                arrived = true
                break
            end

            if GetGameTimer() - started > config.pickupTimeout * 1000 then
                TriggerServerEvent('los_aitaxi:rideFailed')
                RemoveBlip(blip)
                return cleanup()
            end
        end

        if not arrived or not active then
            RemoveBlip(blip)
            return cleanup()
        end

        TaskVehicleTempAction(driver, vehicle, 1, 2000) -- rem
        SetVehicleDoorsLocked(vehicle, 1)
        lib.notify({ description = locale('taxi_arrived'), type = 'success', duration = 10000 })

        -- ── Wachten tot de speler instapt ─────────────────────────────────
        local waitStart = GetGameTimer()

        while active and cache.vehicle ~= vehicle do
            Wait(500)

            if not DoesEntityExist(vehicle) then break end

            if GetGameTimer() - waitStart > config.waitTimeout * 1000 then
                lib.notify({ description = locale('taxi_left'), type = 'error', duration = 8000 })
                TriggerServerEvent('los_aitaxi:rideFailed')
                RemoveBlip(blip)
                return cleanup()
            end
        end

        RemoveBlip(blip)
        if not active or not DoesEntityExist(vehicle) then return cleanup() end

        lib.notify({ description = locale('set_waypoint'), type = 'inform', duration = 12000 })

        -- ── Wachten op een waypoint ───────────────────────────────────────
        local destination
        local waypointStart = GetGameTimer()

        while active and not destination do
            Wait(500)

            if cache.vehicle ~= vehicle then
                -- Uitgestapt voordat de rit begon; dan is er niets te betalen.
                TriggerServerEvent('los_aitaxi:rideFailed')
                return cleanup()
            end

            if IsWaypointActive() then
                local blipCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                local found, z = GetGroundZFor_3dCoord(blipCoords.x, blipCoords.y, 1000.0, false)
                destination = vec3(blipCoords.x, blipCoords.y, found and z or blipCoords.z)
            end

            if GetGameTimer() - waypointStart > config.waitTimeout * 1000 then
                lib.notify({ description = locale('no_destination'), type = 'error', duration = 8000 })
                TriggerServerEvent('los_aitaxi:rideFailed')
                return cleanup()
            end
        end

        if not destination then return cleanup() end

        local boardedAt = GetEntityCoords(cache.ped)
        lib.notify({ description = locale('on_route'), type = 'inform', duration = 8000 })
        showMeter()

        -- ── Naar de bestemming ────────────────────────────────────────────
        local rideStart = GetGameTimer()

        while active do
            Wait(500)

            if not DoesEntityExist(vehicle) or not DoesEntityExist(driver) then break end

            -- Onderweg uitgestapt: rit stopt, en er wordt niets afgeschreven.
            if cache.vehicle ~= vehicle then
                TriggerServerEvent('los_aitaxi:rideFailed')
                return cleanup()
            end

            -- Zelfde som als de server hanteert: hemelsbreed vanaf het instappunt.
            updateMeter(#(GetEntityCoords(cache.ped) - boardedAt))

            driveTo(destination)

            if #(GetEntityCoords(vehicle) - destination) <= config.dropoffDistance then
                TaskVehicleTempAction(driver, vehicle, 1, 3000)
                SetVehicleDoorsLocked(vehicle, 1)

                local travelled = #(GetEntityCoords(cache.ped) - boardedAt)
                local fare = lib.callback.await('los_aitaxi:completeRide', false, travelled)

                lib.notify({
                    description = locale('arrived', fare or 0),
                    type = 'success',
                    duration = 10000
                })

                TaskLeaveVehicle(cache.ped, vehicle, 0)
                Wait(3000)
                break
            end

            if GetGameTimer() - rideStart > config.rideTimeout * 1000 then
                TriggerServerEvent('los_aitaxi:rideFailed')
                break
            end
        end

        cleanup()
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    cleanup()
end)

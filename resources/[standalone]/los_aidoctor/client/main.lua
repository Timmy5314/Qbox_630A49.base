--[[
    De rit. Draait bij de speler die hulp nodig heeft, want die is altijd in de
    buurt van wat er gebeurt - dan hoeft er niets over het netwerk gesynct te
    worden dat niemand anders ziet.

    De hele rit is een enkele thread die stopt zodra hij klaar is. Geen
    permanente loops.
]]

local config = require 'shared.config'

local active = false
local entities = { vehicle = nil, doctor = nil }

local function cleanup()
    if entities.doctor and DoesEntityExist(entities.doctor) then
        DeleteEntity(entities.doctor)
    end

    if entities.vehicle and DoesEntityExist(entities.vehicle) then
        DeleteEntity(entities.vehicle)
    end

    entities.doctor, entities.vehicle = nil, nil
    active = false
end

---@param model number
---@return boolean
local function loadModel(model)
    if not IsModelValid(model) then return false end

    lib.requestModel(model, 10000)
    return HasModelLoaded(model)
end

RegisterNetEvent('los_aidoctor:cancelRide', function()
    if not active then return end
    cleanup()
end)

RegisterNetEvent('los_aidoctor:startRide', function(data)
    if active then return end
    active = true

    if not loadModel(config.models.vehicle) or not loadModel(config.models.doctor) then
        active = false
        return TriggerServerEvent('los_aidoctor:callFailed')
    end

    local station = data.station

    local vehicle = CreateVehicle(config.models.vehicle, station.x, station.y, station.z, station.w, true, false)
    local doctor = CreatePedInsideVehicle(vehicle, 4, config.models.doctor, -1, true, false)

    SetModelAsNoLongerNeeded(config.models.vehicle)
    SetModelAsNoLongerNeeded(config.models.doctor)

    entities.vehicle, entities.doctor = vehicle, doctor

    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleSiren(vehicle, true)
    SetBlockingOfNonTemporaryEvents(doctor, true)
    SetEntityInvincible(doctor, true)
    SetEntityInvincible(vehicle, true)
    SetDriverAbility(doctor, 1.0)
    SetDriverAggressiveness(doctor, 0.0)

    lib.notify({ description = locale('on_the_way'), type = 'inform', duration = 8000 })

    CreateThread(function()
        local started = GetGameTimer()
        local arrived = false

        --[[
            De rijtaak wordt EEN keer gegeven, niet elke tick.

            TaskVehicleDriveToCoordLongrange begint bij elke aanroep opnieuw met
            pathfinden. Hij stond hier in de lus en werd dus twee keer per
            seconde opnieuw opgedragen; de ambulance kwam daardoor nooit verder
            dan de eerste meters en na rideTimeout werd de rit stilletjes
            afgebroken. Dat is de "er komt helemaal geen ambulance"-klacht.

            Er stond bovendien een eerste opdracht naar 0,0,0 - dat is de
            wereld-oorsprong in de oceaan, niet de speler.

            Doelpunt is het dichtstbijzijnde wegknooppunt: naar een speler die
            binnen ligt bestaat geen autoroute. De dokter loopt het laatste
            stuk zelf.
        ]]

        ---@param coords vector3
        ---@return vector3
        local function roadNear(coords)
            local found, node = GetClosestVehicleNode(coords.x, coords.y, coords.z, 1, 3.0, 0)
            return found and node or coords
        end

        -- 262588 = normale route, negeert wegen niet, stopt voor verkeer.
        local function driveTo(target)
            TaskVehicleDriveToCoordLongrange(doctor, vehicle, target.x, target.y, target.z,
                25.0, 262588, config.arriveDistance)
        end

        local target = roadNear(GetEntityCoords(cache.ped))
        local taskedFor = GetEntityCoords(cache.ped)
        local lastPos = GetEntityCoords(vehicle)
        local lastMoved = GetGameTimer()
        local walking = false

        driveTo(target)

        while active do
            Wait(500)

            if not DoesEntityExist(vehicle) or not DoesEntityExist(doctor) then
                break
            end

            local targetPed = cache.ped
            local targetCoords = GetEntityCoords(targetPed)

            if not arrived then
                local vehPos = GetEntityCoords(vehicle)

                if #(vehPos - targetCoords) <= config.arriveDistance
                    or #(vehPos - target) <= config.nodeArriveDistance then
                    arrived = true
                    SetVehicleSiren(vehicle, false)
                    TaskLeaveVehicle(doctor, vehicle, 0)
                    Wait(2500)
                else
                    -- Speler verplaatst (brancard, gedragen): nieuw doel.
                    if #(targetCoords - taskedFor) > config.retaskDistance then
                        target = roadNear(targetCoords)
                        taskedFor = targetCoords
                        driveTo(target)
                        lastMoved = GetGameTimer()

                    -- Vastgelopen: opnieuw laten pathfinden.
                    elseif #(vehPos - lastPos) < 1.0 then
                        if GetGameTimer() - lastMoved > config.stuckSeconds * 1000 then
                            driveTo(target)
                            lastMoved = GetGameTimer()
                        end
                    else
                        lastMoved = GetGameTimer()
                    end

                    lastPos = vehPos
                end
            else
                if #(GetEntityCoords(doctor) - targetCoords) > config.treatDistance then
                    -- Ook deze taak maar een keer geven; elke tick opnieuw laat
                    -- de dokter ter plekke aarzelen in plaats van lopen.
                    if not walking then
                        walking = true
                        TaskGoToEntity(doctor, targetPed, -1, config.treatDistance - 0.5, 1.5, 0, 0)
                    end
                else
                    walking = false
                    ClearPedTasks(doctor)
                    TaskTurnPedToFaceEntity(doctor, targetPed, 3000)

                    lib.notify({ description = locale('treating'), type = 'inform', duration = 6000 })

                    TaskStartScenarioInPlace(doctor, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                    Wait(8000)

                    local revived = lib.callback.await('los_aidoctor:completeTreatment', false)

                    if revived then
                        lib.notify({ description = locale('treated'), type = 'success', duration = 8000 })
                    end

                    -- Dokter stapt weer in en rijdt weg; opruimen na een marge.
                    ClearPedTasks(doctor)
                    TaskEnterVehicle(doctor, vehicle, 10000, -1, 1.0, 1, 0)
                    Wait(6000)
                    TaskVehicleDriveToCoordLongrange(doctor, vehicle, station.x, station.y, station.z, 25.0, 262588, 20.0)
                    Wait(15000)
                    break
                end
            end

            if GetGameTimer() - started > data.timeout * 1000 then
                TriggerServerEvent('los_aidoctor:callFailed')
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

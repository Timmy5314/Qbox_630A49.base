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

        -- 262588 = normale route, negeert wegen niet, stopt voor verkeer.
        TaskVehicleDriveToCoordLongrange(doctor, vehicle, 0.0, 0.0, 0.0, 25.0, 262588, config.arriveDistance)

        while active do
            Wait(500)

            if not DoesEntityExist(vehicle) or not DoesEntityExist(doctor) then
                break
            end

            local targetPed = cache.ped
            local targetCoords = GetEntityCoords(targetPed)

            if not arrived then
                -- Doel steeds bijwerken: de speler kan verplaatst zijn (brancard,
                -- meegenomen door iemand anders).
                TaskVehicleDriveToCoordLongrange(doctor, vehicle, targetCoords.x, targetCoords.y, targetCoords.z,
                    25.0, 262588, config.arriveDistance)

                if #(GetEntityCoords(vehicle) - targetCoords) <= config.arriveDistance then
                    arrived = true
                    SetVehicleSiren(vehicle, false)
                    TaskLeaveVehicle(doctor, vehicle, 0)
                    Wait(2500)
                end
            else
                if #(GetEntityCoords(doctor) - targetCoords) > config.treatDistance then
                    TaskGoToEntity(doctor, targetPed, -1, config.treatDistance - 0.5, 1.5, 0, 0)
                else
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

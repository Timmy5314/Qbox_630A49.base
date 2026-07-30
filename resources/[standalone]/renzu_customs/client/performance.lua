--[[
    renzu_customs :: custom engine / turbo / tyre behaviour
    Everything here reads from entity state bags, which the server replicates,
    so passengers and bystanders get the same sound and feel as the driver.
]]

local ACCELERATE = 71 -- INPUT_VEH_ACCELERATE (works on keyboard and controller)

---@param vehicle integer
---@return boolean
local function isDriver(vehicle)
    return vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == cache.ped
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Engine swap - audio for everyone nearby, handling for the driver
-- ─────────────────────────────────────────────────────────────────────────────

AddStateBagChangeHandler('customEngine', nil, function(bagName)
    local entity = GetEntityFromStateBagName(bagName)
    if entity ~= 0 then
        Customs.engineAudio[entity] = nil -- force the audio loop to re-apply
    end
end)

AddStateBagChangeHandler('customTire', nil, function(bagName, _, value)
    local entity = GetEntityFromStateBagName(bagName)
    if entity ~= 0 and not value then
        Customs.resetTireHandling(entity)
    end
end)

CreateThread(function()
    if not Config.UseCustomEngineUpgrade then return end

    while true do
        local coords = GetEntityCoords(cache.ped)

        for entity in pairs(Customs.engineAudio) do
            if not DoesEntityExist(entity) then
                Customs.engineAudio[entity] = nil
            end
        end

        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if #(coords - GetEntityCoords(vehicle)) < 120.0 then
                local engine = Customs.getVehicleEngine(vehicle)
                if Customs.engineAudio[vehicle] ~= engine then
                    Customs.engineAudio[vehicle] = engine
                    ForceVehicleEngineAudio(vehicle, engine ~= 'Default'
                        and engine
                        or GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                end
            end
        end

        Wait(1500)
    end
end)

--- Cache the stock handling of a vehicle the moment the player gets in, before
--- any swap is applied, so `Default` can always be restored.
lib.onCache('vehicle', function(vehicle)
    if not vehicle then return end
    if Customs.getVehicleEngine(vehicle) ~= 'Default' then return end
    if Customs.getVehicleTireType(vehicle) ~= 'Default' then return end

    if not Customs.getHandlingFromModel('Default', vehicle) then
        Customs.addCustomHandling(vehicle)
    end
end)

CreateThread(function()
    if not Config.UseCustomEngineUpgrade and not Config.UseCustomTireUpgrade then return end

    while true do
        local vehicle = cache.vehicle

        if isDriver(vehicle) then
            if Config.UseCustomEngineUpgrade then
                local engine = Customs.getVehicleEngine(vehicle)
                if engine ~= 'Default' then
                    Customs.setVehicleHandlingSpec(vehicle, engine)
                end
            end

            if Config.UseCustomTireUpgrade then
                local tire = Customs.getVehicleTireType(vehicle)
                if tire ~= 'Default' then
                    Customs.applyTireHandling(vehicle, tire)
                end
            end
        end

        Wait(1000)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Turbo
-- ─────────────────────────────────────────────────────────────────────────────

local turbo = {
    boost = 0.0,
    gear = 0,
    soundId = nil,
    spooling = false,
    lastBlowOff = 0,
}

local function stopSpool()
    if turbo.soundId then
        StopSound(turbo.soundId)
        ReleaseSoundId(turbo.soundId)
        turbo.soundId = nil
    end
    turbo.spooling = false
end

---@param key string turbo name, matches html/audio/<key>.ogg
---@param volume number
local function blowOff(key, volume)
    if not Config.useturbosound then return end

    local now = GetGameTimer()
    if now - turbo.lastBlowOff < 900 then return end
    turbo.lastBlowOff = now

    local payload = { file = key, volume = math.min(math.max(volume, 0.05), 0.6) }

    SendNUIMessage({ action = 'playSound', data = payload })

    if Config.turbosoundSync then
        TriggerServerEvent('renzu_customs:server:turboSound', payload)
    end
end

CreateThread(function()
    if not Config.UseCustomTurboUpgrade then return end

    local list = Config.VehicleMod.custom_turbo and Config.VehicleMod.custom_turbo.list
    if not list then return end

    while true do
        local wait = 300
        local vehicle = cache.vehicle
        local key = (vehicle and isDriver(vehicle)) and Customs.getVehicleTurbo(vehicle) or 'Default'
        local spec = key ~= 'Default' and list[key] or nil

        if spec and spec.Power then
            wait = 10

            if not IsToggleModOn(vehicle, 18) then
                SetVehicleModKit(vehicle, 0)
                ToggleVehicleMod(vehicle, 18, true)
            end

            local rpm = GetVehicleCurrentRpm(vehicle)
            local gear = GetVehicleCurrentGear(vehicle)
            local accelerating = IsControlPressed(0, ACCELERATE)

            if accelerating then
                if turbo.boost < spec.Torque then
                    turbo.boost = turbo.boost + 0.01
                end

                SetVehicleTurboPressure(vehicle, turbo.boost + spec.Power * rpm)

                if GetVehicleTurboPressure(vehicle) >= spec.Power then
                    SetVehicleCheatPowerIncrease(vehicle, spec.Power * GetVehicleTurboPressure(vehicle))
                end

                if not turbo.spooling then
                    turbo.soundId = GetSoundId()
                    PlaySoundFromEntity(turbo.soundId, 'Flare', vehicle, 'DLC_HEISTS_BIOLAB_FINALE_SOUNDS', false, 0)
                    turbo.spooling = true
                end
            end

            -- vent when the driver lifts off, or shifts up while on boost
            local shifted = accelerating and rpm > 0.8 and gear ~= turbo.gear
            if (turbo.spooling and not accelerating) or shifted then
                stopSpool()
                if turbo.boost > 0.05 then
                    blowOff(key, 0.4 * (turbo.boost / math.max(spec.Torque, 0.01)))
                end
                turbo.boost = 0.0
                SetVehicleCheatPowerIncrease(vehicle, 1.0)
            end

            turbo.gear = gear
        elseif turbo.spooling then
            stopSpool()
            turbo.boost = 0.0
        end

        Wait(wait)
    end
end)

RegisterNetEvent('renzu_customs:client:playSound', function(payload)
    if type(payload) ~= 'table' or type(payload.file) ~= 'string' then return end
    SendNUIMessage({ action = 'playSound', data = payload })
end)

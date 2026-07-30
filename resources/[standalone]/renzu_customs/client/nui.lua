--[[ renzu_customs :: NUI callbacks ]]

local TUNER_DLC = GetGameBuildNumber() >= 2372

---@return integer? vehicle
local function activeVehicle()
    local vehicle = Customs.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetVehicleModKit(vehicle, 0)
    return vehicle
end

---Wraps a callback that needs the tuned vehicle.
---@param handler fun(vehicle: integer, data: table): any
local function withVehicle(handler)
    return function(data, cb)
        local vehicle = activeVehicle()
        if not vehicle then return cb(false) end

        local result = handler(vehicle, data or {})
        cb(result == nil and true or result)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Menu lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    cb(1)
    Customs.closeMenu(true)
end)

RegisterNUICallback('pay', function(_, cb)
    local vehicle = activeVehicle()
    if not Customs.inMenu or not vehicle then
        return cb({ success = false, message = 'No vehicle' })
    end

    local props = Customs.getVehicleProperties(vehicle)
    local result = lib.callback.await('renzu_customs:server:pay', false, props, GetVehicleClass(vehicle))

    if result and result.success then
        Customs.oldProps = props -- keep the new look when the menu closes
        cb({ success = true, cost = result.cost })

        Customs.notify(result.cost > 0
            and ('Payment received: $%s'):format(Customs.comma(result.cost))
            or 'Upgrades installed', 'success')

        if not result.owned and not Config.OwnedVehiclesOnly then
            Customs.notify('This vehicle is not registered, the upgrades are not saved', 'warning')
        end

        Customs.closeMenu(false)
    else
        cb({ success = false, message = result and result.message or 'Payment failed' })
        Customs.notify(result and result.message or 'Payment failed', 'error')
    end
end)

RegisterNUICallback('repair', function(_, cb)
    local vehicle = activeVehicle()
    if not vehicle then return cb({ success = false }) end

    local allowed = lib.callback.await('renzu_customs:server:repair', false, Customs.shopSession)
    if not allowed then
        cb({ success = false })
        return Customs.notify(('Not enough money, a repair costs $%s'):format(Customs.comma(Config.RepairCost)), 'error')
    end

    SetNuiFocus(false, false)

    local done = lib.progressCircle({
        duration = 8000,
        label = 'Repairing vehicle',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
    })

    SetNuiFocus(true, true)

    if not done then return cb({ success = false }) end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)

    if Customs.oldProps then
        Customs.oldProps.bodyHealth = 1000.0
        Customs.oldProps.engineHealth = 1000.0
        Customs.oldProps.tankHealth = 1000.0
        Customs.oldProps.dirtLevel = 0.0
    end

    Customs.notify('Vehicle repaired', 'success')
    cb({ success = true })
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Camera
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('focusMod', function(data, cb)
    cb(1)
    local vehicle = activeVehicle()
    if not vehicle then return end

    if data.action == 'openhood' then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    end

    if data.bone then Customs.setCamBone(data.bone) end

    if data.camera then
        Customs.setCamView(data.camera.val, data.camera.x + 0.0, data.camera.y + 0.0, data.camera.z + 0.0)
    end
end)

RegisterNUICallback('resetCamera', function(_, cb)
    cb(1)
    if Customs.camView ~= 'front' then
        Customs.setCamView('front', -2.5, 0.1, 1.3)
    end
end)

RegisterNUICallback('closeDoors', function(_, cb)
    cb(1)
    local vehicle = activeVehicle()
    if not vehicle then return end
    for door = 0, 5 do
        SetVehicleDoorShut(vehicle, door, false)
    end
end)

local freeLook = false

RegisterNUICallback('toggleCamera', function(_, cb)
    cb(1)
    if freeLook or not Customs.inMenu then return end
    freeLook = true

    RenderScriptCams(false, true, 400, true, true)
    SetNuiFocus(false, false)

    CreateThread(function()
        while Customs.inMenu and freeLook do
            lib.showTextUI('[E] Back to the menu', { position = 'bottom-center' })
            if IsControlJustReleased(0, 38) then break end
            Wait(0)
        end

        lib.hideTextUI()
        freeLook = false

        if Customs.inMenu then
            SetNuiFocus(true, true)
            if Customs.cam then
                SetCamActive(Customs.cam, true)
                RenderScriptCams(true, true, 400, true, true)
            end
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Standard mods
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('getModLevels', withVehicle(function(vehicle, data)
    local index = tonumber(data.index)
    if not index then return { levels = {}, current = -1 } end

    if data.wheelType then
        SetVehicleWheelType(vehicle, tonumber(data.wheelType) --[[@as integer]])
        Wait(0)
    end

    return {
        levels = Customs.buildModLevels(vehicle, index, data.name or 'Mod'),
        current = GetVehicleMod(vehicle, index),
    }
end))

RegisterNUICallback('setMod', withVehicle(function(vehicle, data)
    local index = tonumber(data.index)
    local level = tonumber(data.level)
    if not index or not level then return false end

    if data.wheelType then
        SetVehicleWheelType(vehicle, tonumber(data.wheelType) --[[@as integer]])
    end

    -- liveries: some vehicles use mod 48, older ones use the livery natives
    if index == 48 and GetNumVehicleMods(vehicle, 48) <= 0 and GetVehicleLiveryCount(vehicle) > 0 then
        SetVehicleLivery(vehicle, level)
    else
        SetVehicleMod(vehicle, index, level, data.customTires == true)
    end

    -- preview the horn the player just picked
    if index == 14 and level >= 0 then
        StartVehicleHorn(vehicle, 2500, `HELDDOWN`, false)
    end

    return true
end))

RegisterNUICallback('toggleTurbo', withVehicle(function(vehicle, data)
    ToggleVehicleMod(vehicle, 18, data.enabled == true)
    return true
end))

-- ─────────────────────────────────────────────────────────────────────────────
--  Paint
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('setPaint', withVehicle(function(vehicle, data)
    local index = tonumber(data.index)
    if not index then return false end

    local primary, secondary = GetVehicleColours(vehicle)
    local pearlescent, wheelColor = GetVehicleExtraColours(vehicle)

    if data.option == 'Pearlescent' then
        SetVehicleExtraColours(vehicle, index, wheelColor)
    elseif data.option == 'Chameleon' then
        ClearVehicleCustomPrimaryColour(vehicle)
        ClearVehicleCustomSecondaryColour(vehicle)
        SetVehicleColours(vehicle, index, index)
    elseif data.target == 'secondary' then
        ClearVehicleCustomSecondaryColour(vehicle)
        SetVehicleColours(vehicle, primary, index)
    else
        ClearVehicleCustomPrimaryColour(vehicle)
        SetVehicleColours(vehicle, index, secondary)
        SetVehicleExtraColours(vehicle, pearlescent, wheelColor)
    end

    return true
end))

RegisterNUICallback('setCustomColor', withVehicle(function(vehicle, data)
    local r, g, b = tonumber(data.r) or 0, tonumber(data.g) or 0, tonumber(data.b) or 0

    if data.target == 'secondary' then
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
    else
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
    end

    return true
end))

RegisterNUICallback('setWheelColor', withVehicle(function(vehicle, data)
    local pearlescent = GetVehicleExtraColours(vehicle)
    SetVehicleExtraColours(vehicle, pearlescent, tonumber(data.index) or 0)
    return true
end))

RegisterNUICallback('setSmokeColor', withVehicle(function(vehicle, data)
    ToggleVehicleMod(vehicle, 20, true)
    SetVehicleTyreSmokeColor(vehicle, tonumber(data.r) or 255, tonumber(data.g) or 255, tonumber(data.b) or 255)
    return true
end))

-- ─────────────────────────────────────────────────────────────────────────────
--  Lights, windows, plates, extras
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('setXenon', withVehicle(function(vehicle, data)
    local enabled = data.enabled == true
    ToggleVehicleMod(vehicle, 22, enabled)
    SetVehicleLights(vehicle, enabled and 2 or 0)
    if enabled then SetVehicleXenonLightsColour(vehicle, 0) end
    return true
end))

RegisterNUICallback('setXenonColor', withVehicle(function(vehicle, data)
    ToggleVehicleMod(vehicle, 22, true)
    SetVehicleXenonLightsColour(vehicle, tonumber(data.index) or 0)
    return true
end))

RegisterNUICallback('setNeon', withVehicle(function(vehicle, data)
    for light = 0, 3 do
        SetVehicleNeonLightEnabled(vehicle, light, data.enabled == true)
    end
    return true
end))

RegisterNUICallback('setNeonColor', withVehicle(function(vehicle, data)
    for light = 0, 3 do
        SetVehicleNeonLightEnabled(vehicle, light, true)
    end
    SetVehicleNeonLightsColour(vehicle, tonumber(data.r) or 255, tonumber(data.g) or 255, tonumber(data.b) or 255)
    return true
end))

RegisterNUICallback('setWindowTint', withVehicle(function(vehicle, data)
    SetVehicleWindowTint(vehicle, tonumber(data.index) or 0)
    return true
end))

RegisterNUICallback('setPlate', withVehicle(function(vehicle, data)
    SetVehicleNumberPlateTextIndex(vehicle, tonumber(data.index) or 0)
    return true
end))

RegisterNUICallback('setExtra', withVehicle(function(vehicle, data)
    local extra = tonumber(data.index)
    if not extra then return false end
    SetVehicleExtra(vehicle, extra, data.enabled and 0 or 1)
    return true
end))

-- ─────────────────────────────────────────────────────────────────────────────
--  Wheel accessories
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('toggleCustomTires', withVehicle(function(vehicle, data)
    local enabled = data.enabled == true
    SetVehicleMod(vehicle, 23, GetVehicleMod(vehicle, 23), enabled)
    SetVehicleMod(vehicle, 24, GetVehicleMod(vehicle, 24), enabled)
    return true
end))

RegisterNUICallback('toggleBulletProof', withVehicle(function(vehicle, data)
    SetVehicleTyresCanBurst(vehicle, data.enabled ~= true)
    return true
end))

RegisterNUICallback('toggleDrift', withVehicle(function(vehicle, data)
    if not TUNER_DLC then return false end
    local enabled = data.enabled == true
    SetDriftTyresEnabled(vehicle, enabled)
    SetReduceDriftVehicleSuspension(vehicle, enabled)
    return true
end))

-- ─────────────────────────────────────────────────────────────────────────────
--  Custom engine / turbo / tyres
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('setCustomPart', withVehicle(function(vehicle, data)
    if data.slot == 'custom_engine' then
        if not Customs.getHandlingFromModel('Default', vehicle) then
            Customs.addCustomHandling(vehicle)
        end
        Customs.setVehicleEngine(vehicle, data.model or 'Default')
        if data.model == 'Default' then
            Customs.setVehicleHandlingSpec(vehicle, 'Default')
        end
    elseif data.slot == 'custom_turbo' then
        Customs.setVehicleTurbo(vehicle, data.key or 'Default')
    elseif data.slot == 'custom_tires' then
        Customs.setVehicleTireType(vehicle, data.key or 'Default')
        if data.key == 'Default' then
            Customs.resetTireHandling(vehicle)
        end
    else
        return false
    end

    return true
end))

-- ─────────────────────────────────────────────────────────────────────────────
--  Spray can (custom colour picker outside the tuning menu)
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('sprayColor', function(data, cb)
    Config.Pilox.custom = { tonumber(data.r) or 0, tonumber(data.g) or 0, tonumber(data.b) or 0 }
    cb(1)
end)

RegisterNUICallback('sprayColorDone', function(_, cb)
    cb(1)
    Customs.customPaintDone = true
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeSprayPicker' })
end)

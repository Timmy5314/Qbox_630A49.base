--[[
    renzu_customs :: vehicle properties, custom parts and handling
    The custom engine / turbo / tyre upgrades are synced with entity state bags,
    so no server round trip or plate lookup is needed anymore.
]]

local TUNER_DLC = GetGameBuildNumber() >= 2372

-- ─────────────────────────────────────────────────────────────────────────────
--  Custom part state (state bags)
-- ─────────────────────────────────────────────────────────────────────────────

---@param vehicle integer
---@param key 'customEngine'|'customTurbo'|'customTire'
---@return string
local function getCustomPart(vehicle, key)
    if not DoesEntityExist(vehicle) then return 'Default' end
    local value = Entity(vehicle).state[key]
    return (value and value ~= '') and value or 'Default'
end

---@param vehicle integer
---@param key 'customEngine'|'customTurbo'|'customTire'
---@param value string?
local function setCustomPart(vehicle, key, value)
    if not DoesEntityExist(vehicle) then return end
    if value == 'Default' or value == nil or value == '' then value = nil end
    Entity(vehicle).state:set(key, value, true)
end

function Customs.getVehicleEngine(vehicle) return getCustomPart(vehicle, 'customEngine') end
function Customs.getVehicleTurbo(vehicle) return getCustomPart(vehicle, 'customTurbo') end
function Customs.getVehicleTireType(vehicle) return getCustomPart(vehicle, 'customTire') end

function Customs.setVehicleEngine(vehicle, engine) setCustomPart(vehicle, 'customEngine', engine) end
function Customs.setVehicleTurbo(vehicle, turbo) setCustomPart(vehicle, 'customTurbo', turbo) end
function Customs.setVehicleTireType(vehicle, tire) setCustomPart(vehicle, 'customTire', tire) end

-- ─────────────────────────────────────────────────────────────────────────────
--  Properties
-- ─────────────────────────────────────────────────────────────────────────────

--- native mod index -> property name, used by both the getter and the setter
local MODS = {
    { 0, 'modSpoilers' }, { 1, 'modFrontBumper' }, { 2, 'modRearBumper' }, { 3, 'modSideSkirt' },
    { 4, 'modExhaust' }, { 5, 'modFrame' }, { 6, 'modGrille' }, { 7, 'modHood' },
    { 8, 'modFender' }, { 9, 'modRightFender' }, { 10, 'modRoof' }, { 11, 'modEngine' },
    { 12, 'modBrakes' }, { 13, 'modTransmission' }, { 14, 'modHorns' }, { 15, 'modSuspension' },
    { 16, 'modArmor' }, { 25, 'modPlateHolder' }, { 26, 'modVanityPlate' }, { 27, 'modTrimA' },
    { 28, 'modOrnaments' }, { 29, 'modDashboard' }, { 30, 'modDial' }, { 31, 'modDoorSpeaker' },
    { 32, 'modSeats' }, { 33, 'modSteeringWheel' }, { 34, 'modShifterLeavers' }, { 35, 'modAPlate' },
    { 36, 'modSpeakers' }, { 37, 'modTrunk' }, { 38, 'modHydrolic' }, { 39, 'modEngineBlock' },
    { 40, 'modAirFilter' }, { 41, 'modStruts' }, { 42, 'modArchCover' }, { 43, 'modAerials' },
    { 44, 'modTrimB' }, { 45, 'modTank' }, { 46, 'modWindows' },
}

---@param vehicle integer
---@return table? props
function Customs.getVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
        end
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not Config.PlateSpace then
        plate = plate:gsub('^%s*(.-)%s*$', '%1')
    end

    -- liveries live on mod 48 for most cars and on the livery natives for the rest
    local livery = GetVehicleLivery(vehicle)
    if livery == -1 or GetVehicleMod(vehicle, 48) ~= -1 then
        livery = GetVehicleMod(vehicle, 48)
    end

    local props = {
        model = GetEntityModel(vehicle),
        plate = plate,
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth = Customs.round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = Customs.round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = Customs.round(GetVehiclePetrolTankHealth(vehicle), 1),
        fuelLevel = Customs.round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel = Customs.round(GetVehicleDirtLevel(vehicle), 1),

        color1 = colorPrimary,
        color2 = colorSecondary,
        rgb = { GetVehicleCustomPrimaryColour(vehicle) },
        rgb2 = { GetVehicleCustomSecondaryColour(vehicle) },
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,

        wheels = GetVehicleWheelType(vehicle),
        modCustomTires = GetVehicleModVariation(vehicle, 23),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColour(vehicle),

        neonEnabled = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3),
        },
        neonColor = { GetVehicleNeonLightsColour(vehicle) },
        tyreSmokeColor = { GetVehicleTyreSmokeColor(vehicle) },
        extras = extras,

        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),
        modFrontWheels = GetVehicleMod(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),
        modLivery = livery,

        custom_engine = Customs.getVehicleEngine(vehicle),
        custom_turbo = Customs.getVehicleTurbo(vehicle),
        custom_tire = Customs.getVehicleTireType(vehicle),
        drift_tire = TUNER_DLC and GetDriftTyresEnabled(vehicle) or false,
    }

    for i = 1, #MODS do
        props[MODS[i][2]] = GetVehicleMod(vehicle, MODS[i][1])
    end

    return props
end

---@param vehicle integer
---@param props table
function Customs.setVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or type(props) ~= 'table' then return end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

    SetVehicleModKit(vehicle, 0)

    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

    if props.color1 then SetVehicleColours(vehicle, props.color1, props.color2 or colorSecondary) end
    if props.color2 then SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2) end
    if props.pearlescentColor or props.wheelColor then
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor or wheelColor)
    end
    if props.rgb and props.rgb[1] then SetVehicleCustomPrimaryColour(vehicle, props.rgb[1], props.rgb[2], props.rgb[3]) end
    if props.rgb2 and props.rgb2[1] then SetVehicleCustomSecondaryColour(vehicle, props.rgb2[1], props.rgb2[2], props.rgb2[3]) end

    if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

    if props.neonEnabled then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] or false)
        end
    end
    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end

    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId) --[[@as integer]], enabled and 0 or 1)
        end
    end

    ToggleVehicleMod(vehicle, 18, props.modTurbo or false)
    ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled or false)
    ToggleVehicleMod(vehicle, 22, props.modXenon or false)
    if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end

    for i = 1, #MODS do
        local value = props[MODS[i][2]]
        if value then SetVehicleMod(vehicle, MODS[i][1], value, false) end
    end

    if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTires or false) end
    if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTires or false) end

    if props.modLivery then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end

    if Config.UseCustomTurboUpgrade and props.custom_turbo then Customs.setVehicleTurbo(vehicle, props.custom_turbo) end
    if Config.UseCustomEngineUpgrade and props.custom_engine then Customs.setVehicleEngine(vehicle, props.custom_engine) end
    if Config.UseCustomTireUpgrade and props.custom_tire then Customs.setVehicleTireType(vehicle, props.custom_tire) end

    if TUNER_DLC and props.drift_tire ~= nil then
        SetDriftTyresEnabled(vehicle, props.drift_tire == true)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Handling (used by the engine swap and tyre compounds)
-- ─────────────────────────────────────────────────────────────────────────────

local HANDLING_FIELDS = {
    fDriveInertia = 'DriveInertia',
    nInitialDriveGears = 'InitialDriveGears',
    fInitialDriveForce = 'InitialDriveForce',
    fClutchChangeRateScaleUpShift = 'ClutchChangeRateScaleUpShift',
    fClutchChangeRateScaleDownShift = 'ClutchChangeRateScaleDownShift',
    fInitialDriveMaxFlatVel = 'InitialDriveMaxFlatVel',
    fMass = 'Mass',
    fLowSpeedTractionLossMult = 'LowSpeedTractionLossMult',
    fTractionLossMult = 'TractionLossMult',
    fTractionCurveMin = 'TractionCurveMin',
    fTractionCurveMax = 'TractionCurveMax',
    fTractionCurveLateral = 'TractionCurveLateral',
}

--- model hash -> handling table, filled lazily from handling.min.json
local handlingCache = {}

local function loadHandlingFile()
    if Customs.handling then return end

    local file = LoadResourceFile(GetCurrentResourceName(), 'handling.min.json')
    local ok, decoded = pcall(json.decode, file or '[]')
    Customs.handling = (ok and type(decoded) == 'table') and decoded or {}

    for _, entry in ipairs(Customs.handling) do
        local models = entry.VehicleModels
        if type(models) == 'table' then
            for _, model in ipairs(models) do
                handlingCache[type(model) == 'number' and model or joaat(tostring(model):lower())] = entry
            end
        end
    end
end

---Reads the handling of a model out of handling.min.json.
---@param model string|number|'Default' model name/hash, or 'Default' for the vehicle itself
---@param vehicle integer
---@return table? handling
function Customs.getHandlingFromModel(model, vehicle)
    loadHandlingFile()

    local hash
    if model == 'Default' or model == nil then
        hash = GetEntityModel(vehicle)
    elseif tonumber(model) then
        hash = tonumber(model)
    else
        hash = joaat(tostring(model):lower())
    end

    local entry = handlingCache[hash]
    if not entry then return end

    local handling = {}
    for field, source in pairs(HANDLING_FIELDS) do
        handling[field] = tonumber(entry[source])
    end
    return handling
end

---Caches the live handling of a vehicle that is missing from handling.min.json.
---@param vehicle integer
function Customs.addCustomHandling(vehicle)
    loadHandlingFile()

    local hash = GetEntityModel(vehicle)
    if handlingCache[hash] then return end

    handlingCache[hash] = {
        VehicleModels = { hash },
        DriveInertia = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveInertia'),
        InitialDriveGears = GetVehicleHandlingInt(vehicle, 'CHandlingData', 'nInitialDriveGears'),
        InitialDriveForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce'),
        ClutchChangeRateScaleUpShift = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleUpShift'),
        ClutchChangeRateScaleDownShift = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleDownShift'),
        InitialDriveMaxFlatVel = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel'),
        Mass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass'),
        LowSpeedTractionLossMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fLowSpeedTractionLossMult'),
        TractionLossMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionLossMult'),
        TractionCurveMin = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin'),
        TractionCurveMax = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax'),
        TractionCurveLateral = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveLateral'),
    }
end

---Copies the drivetrain handling of `model` onto `vehicle` (engine swap).
---@param vehicle integer
---@param model string|number|'Default'
function Customs.setVehicleHandlingSpec(vehicle, model)
    local handling = Customs.getHandlingFromModel(model, vehicle)
    if not handling or not DoesEntityExist(vehicle) then return end

    local currentMass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass')
    local multiplier = currentMass > 0 and ((handling.fMass or currentMass) / currentMass) or 1.0

    local gears = handling.nInitialDriveGears
    if gears then
        if gears < 6 and GetVehicleMod(vehicle, 13) > 0 then gears = gears + 1 end
        if gears > GetVehicleHandlingInt(vehicle, 'CHandlingData', 'nInitialDriveGears') then
            SetVehicleHighGear(vehicle, gears)
        end
        SetVehicleHandlingInt(vehicle, 'CHandlingData', 'nInitialDriveGears', gears)
        SetVehicleHandlingField(vehicle, 'CHandlingData', 'nInitialDriveGears', gears)
    end

    for field, value in pairs(handling) do
        if field == 'fDriveInertia' then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value * math.max(multiplier, 0.8))
        elseif field == 'fInitialDriveForce' then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value * multiplier)
        elseif field == 'fInitialDriveMaxFlatVel' then
            SetVehicleHandlingField(vehicle, 'CHandlingData', field, value + 0.0)
        elseif field ~= 'fMass' and field ~= 'nInitialDriveGears' then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value + 0.0)
        end
    end

    -- required, otherwise the new max velocity / inertia is not picked up
    SetVehicleEnginePowerMultiplier(vehicle, 1.0)
end

---Applies a tyre compound on top of the vehicle's stock traction values.
---@param vehicle integer
---@param tire string key inside Config.VehicleMod.custom_tires.list
function Customs.applyTireHandling(vehicle, tire)
    local compound = Config.VehicleMod.custom_tires and Config.VehicleMod.custom_tires.list[tire]
    local stock = Customs.getHandlingFromModel('Default', vehicle)
    if not compound or not stock or not compound.fTractionCurveMax then return end

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fLowSpeedTractionLossMult', (stock.fLowSpeedTractionLossMult or 1.0) * compound.fLowSpeedTractionLossMult)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionLossMult', (stock.fTractionLossMult or 1.0) * compound.fTractionLossMult)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin', (stock.fTractionCurveMin or 1.0) * compound.fTractionCurveMin)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', (stock.fTractionCurveMax or 1.0) * compound.fTractionCurveMax)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveLateral', (stock.fTractionCurveLateral or 1.0) * compound.fTractionCurveLateral)
end

---Restores the stock traction values.
---@param vehicle integer
function Customs.resetTireHandling(vehicle)
    local stock = Customs.getHandlingFromModel('Default', vehicle)
    if not stock then return end

    for _, field in ipairs({ 'fLowSpeedTractionLossMult', 'fTractionLossMult', 'fTractionCurveMin', 'fTractionCurveMax', 'fTractionCurveLateral' }) do
        if stock[field] then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, stock[field] + 0.0)
        end
    end
end

CreateThread(loadHandlingFile)

-- ─────────────────────────────────────────────────────────────────────────────
--  Exports (kept compatible with the original resource)
-- ─────────────────────────────────────────────────────────────────────────────

exports('GetVehicleProperties', Customs.getVehicleProperties)
exports('SetVehicleProp', Customs.setVehicleProperties)
exports('SetVehicleProperties', Customs.setVehicleProperties)
exports('GetVehicleEngine', Customs.getVehicleEngine)
exports('SetVehicleEngine', Customs.setVehicleEngine)
exports('GetVehicleTurbo', Customs.getVehicleTurbo)
exports('SetVehicleTurbo', Customs.setVehicleTurbo)
exports('GetVehicleTireType', Customs.getVehicleTireType)
exports('SetVehicleTireType', Customs.setVehicleTireType)
exports('SetVehicleHandlingSpec', Customs.setVehicleHandlingSpec)
exports('GetHandlingfromModel', function(model, vehicle)
    return Customs.getHandlingFromModel(model, vehicle)
end)
exports('GetVehicleValue', function(modelHash)
    return lib.callback.await('renzu_customs:server:getVehicleValue', false, modelHash) or 0
end)

RegisterNetEvent('renzu_customs:client:restoreProps', function(netId, props)
    if not NetworkDoesNetworkIdExist(netId) then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    Customs.prepareVehicle(vehicle)
    Customs.setVehicleProperties(vehicle, props)
end)

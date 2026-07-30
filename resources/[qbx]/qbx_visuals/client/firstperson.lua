--[[
    qbx_visuals - first person

    Forceert het echte first-person camerastandpunt van het spel via
    SET_CAM_VIEW_MODE_FOR_CONTEXT, per cameracontext instelbaar.

    Waarom het echte standpunt en geen eigen camera: in de echte first-person
    modus haalt GTA het hoofd van je ped zelf weg. Scripts die met een eigen
    camera (CreateCam) een bredere FOV afdwingen doen dat niet - en dat is
    precies waarom je bij die scripts je eigen gezicht in beeld krijgt tijdens
    het rijden.

    Over de FOV: er bestaat GEEN native om het blikveld van de gameplay-camera
    te zetten. Er is alleen GET_GAMEPLAY_CAM_FOV, geen SET. De FOV is een
    client-instelling. Zie Config.FirstPerson.fov hieronder.
]]

local fp = Config.FirstPerson

-- Contexten uit camControlHelperMetadataViewModes.
local CONTEXT = {
    onFoot      = 0,
    inVehicle   = 1,
    onBike      = 2,
    inBoat      = 3,
    inAircraft  = 4,
    inSubmarine = 5,
    inHeli      = 6,
    inTurret    = 7,
}

local VIEW_FIRST_PERSON <const> = 4
local INPUT_NEXT_CAMERA  <const> = 0

local exempt     = false
local suppressed = false

-- ---------------------------------------------------------------------------
-- Field of view
-- ---------------------------------------------------------------------------

--- Zet de client-instelling voor het first-person blikveld.
--- Dit is een convar van de speler zelf, niet iets wat de server kan afdwingen.
--- We gebruiken de niet-blijvende vorm, dus het geldt alleen deze sessie.
function QV.setFieldOfView(value)
    local number = tonumber(value)
    if not number then return false end

    ExecuteCommand(('profile_fpsFieldOfView %s'):format(math.floor(number)))
    QV.debug('profile_fpsFieldOfView -> %d', math.floor(number))
    return true
end

--- Het blikveld dat de camera op dit moment daadwerkelijk gebruikt.
--- Hiermee kun je zelf vaststellen of het zetten van de convar iets doet:
--- meet, zet een andere waarde, meet opnieuw.
function QV.getFieldOfView()
    return GetGameplayCamFov()
end

-- ---------------------------------------------------------------------------
-- Handhaving
-- ---------------------------------------------------------------------------

local function shouldEnforce()
    if not fp.enabled or exempt or suppressed then return false end

    -- Niet ingrijpen waar het spel zijn eigen camera nodig heeft.
    if IsPauseMenuActive() then return false end
    if IsCutsceneActive() or IsPlayerSwitchInProgress() then return false end
    if NetworkIsInSpectatorMode() then return false end
    if IsPedDeadOrDying(PlayerPedId(), true) then return false end

    return true
end

--- Zet het standpunt alleen als het NIET al goed staat.
---
--- Blind elke seconde opnieuw zetten kan een zichtbaar schokje geven; dat is
--- de meest waarschijnlijke verklaring voor "de camera beweegt uit zichzelf".
--- Met deze controle raken we de camera alleen aan als er echt iets veranderd
--- is, bijvoorbeeld nadat een ander script hem heeft omgezet.
local function applyViewModes()
    for name, context in pairs(CONTEXT) do
        if fp.contexts[name] and GetCamViewModeForContext(context) ~= VIEW_FIRST_PERSON then
            SetCamViewModeForContext(context, VIEW_FIRST_PERSON)
            QV.debug('standpunt hersteld voor context %s', name)
        end
    end

    if fp.contexts.onFoot and GetFollowPedCamViewMode() ~= VIEW_FIRST_PERSON then
        SetFollowPedCamViewMode(VIEW_FIRST_PERSON)
    end

    if fp.contexts.inVehicle and GetFollowVehicleCamViewMode() ~= VIEW_FIRST_PERSON then
        SetFollowVehicleCamViewMode(VIEW_FIRST_PERSON)
    end
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(2000)

    -- Server bepaalt of deze speler vrijgesteld is. Nooit client-side
    -- beslissen wie admin is.
    local ok, result = pcall(lib.callback.await, 'qbx_visuals:firstPersonExempt', false)
    exempt = (ok and result) and true or false
    QV.state.fpExempt = exempt

    if exempt then
        QV.debug('first person: vrijgesteld (admin)')
        return
    end

    if fp.fov.autoApply then
        QV.setFieldOfView(fp.fov.value)
    end

    if fp.fov.notify then
        QV.notify(('Te smal beeld? Zet in de F8-console: profile_fpsFieldOfView %d')
            :format(fp.fov.value))
    end

    while true do
        local enforce = shouldEnforce()

        -- De per-frame thread in render.lua blokkeert hiermee de
        -- camera-wisseltoets, zodat je niet eerst even in derde persoon
        -- flitst voor wij hem terugzetten.
        QV.state.blockCameraToggle = enforce and fp.blockViewToggle

        -- customcam.lua kijkt hiernaar: een admin of iemand in derde persoon
        -- krijgt geen hoofdcamera.
        QV.state.fpActive = enforce

        if enforce then applyViewModes() end

        Wait(fp.enforceInterval)
    end
end)

-- ---------------------------------------------------------------------------
-- Exports
-- ---------------------------------------------------------------------------

exports('isFirstPersonExempt', function() return exempt end)

--- Tijdelijk uitzetten, bijvoorbeeld tijdens een eigen cutscene of camera.
exports('setFirstPersonSuppressed', function(value)
    suppressed = value and true or false
    if suppressed then QV.state.blockCameraToggle = false end
end)

exports('setFieldOfView', function(value) return QV.setFieldOfView(value) end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    -- Camerakeuze weer vrijgeven.
    EnableControlAction(0, INPUT_NEXT_CAMERA, true)
end)

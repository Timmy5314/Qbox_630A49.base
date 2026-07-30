--[[
    qbx_visuals - render & populatie

    Alle natives die per frame herhaald moeten worden, in EEN thread. Zowel de
    schaduw-instellingen als de dichtheids-multipliers zijn "this frame"
    natives: sla je een frame over, dan valt de waarde terug op standaard.

    Dat is meteen de reden dat density-scripts die met Wait(500) draaien
    onvoorspelbaar werken - ze zetten de waarde maar op 1 van de ~30 frames.
]]

local pop = Config.Population

-- ---------------------------------------------------------------------------
-- Per-frame
-- ---------------------------------------------------------------------------

CreateThread(function()
    while true do
        local paused     = IsPauseMenuActive()
        local doVisuals  = QV.state.enabled and not paused
        local doPop      = pop.enabled and not paused
        local doCam      = QV.state.blockCameraToggle and not paused
        local doCustom   = QV.state.customCamActive and not paused

        if not doVisuals and not doPop and not doCam and not doCustom then
            Wait(500)
        else
            if doCustom then
                -- Rotatie van de eigen first-person camera bijwerken.
                -- customcam.lua bepaalt wanneer die actief is.
                QV.customCamTick()
            end

            if doCam then
                -- INPUT_NEXT_CAMERA. Blokkeren in plaats van achteraf
                -- terugzetten, anders flitst de speler eerst naar derde
                -- persoon. firstperson.lua bepaalt wanneer dit aan staat.
                DisableControlAction(0, 0, true)
            end

            if doVisuals then
                local q = QV.quality()

                if q.shadows then
                    CascadeShadowsSetCascadeBoundsScale(q.shadowBoundsScale)
                    CascadeShadowsEnableEntityTracker(q.shadowEntityTracker)
                    CascadeShadowsSetEntityTrackerScale(q.shadowTrackerScale)
                    CascadeShadowsSetShadowSampleType(q.shadowSampleType)
                    -- Hoog in de lucht heeft de cascade een ander bereik nodig,
                    -- anders verdwijnen de schaduwen onder je.
                    CascadeShadowsSetAircraftMode(QV.state.aerial)
                end

                if q.lodScale then
                    OverrideLodscaleThisFrame(q.lodScale)
                end
            end

            if doPop then
                -- Rondlopende peds.
                SetPedDensityMultiplierThisFrame(pop.peds)
                SetAmbientPedRangeMultiplierThisFrame(pop.ambientPedRange)

                -- Scenario-peds: apart systeem, aparte native. Dit zijn de
                -- peds op vaste plekken.
                SetScenarioPedDensityMultiplierThisFrame(
                    pop.scenarioPeds.interior,
                    pop.scenarioPeds.exterior
                )

                -- Verkeer. Beide knoppen zijn nodig.
                SetVehicleDensityMultiplierThisFrame(pop.vehicles)
                SetRandomVehicleDensityMultiplierThisFrame(pop.randomVehicles)
                SetParkedVehicleDensityMultiplierThisFrame(pop.parkedVehicles)
            end

            Wait(0)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Blijvende instellingen
--
-- Niet per frame nodig. Opnieuw gezet bij een wijziging en elke 10 seconden
-- herbevestigd, omdat een respawn of sessiewissel ze soms terugdraait.
-- ---------------------------------------------------------------------------

local last = {}

local function applyWorldSettings(force)
    local q  = QV.quality()
    local on = QV.state.enabled

    -- Nep-verkeer in de verte.
    local distantCars = true
    if on then distantCars = q.distantCars end
    if force or last.distantCars ~= distantCars then
        SetDistantCarsEnabled(distantCars)
        last.distantCars = distantCars
    end

    -- Streaming-budget voor modellen.
    local reduce = false
    if on then reduce = q.reduceModelBudget end
    if force or last.reduce ~= reduce then
        SetReducePedModelBudget(reduce)
        SetReduceVehicleModelBudget(reduce)
        last.reduce = reduce
    end

    local pedBudget, vehBudget = 3, 3
    if on and Config.AllowPopulationBudget and q.lowPopulation then
        pedBudget = Config.PopulationBudget.ped
        vehBudget = Config.PopulationBudget.vehicle
    end
    if force or last.pedBudget ~= pedBudget then
        SetPedPopulationBudget(pedBudget)
        last.pedBudget = pedBudget
    end
    if force or last.vehBudget ~= vehBudget then
        SetVehiclePopulationBudget(vehBudget)
        last.vehBudget = vehBudget
    end

    -- Geparkeerde auto's komen grotendeels uit vehicle generators. Zonder dit
    -- blijft er ondanks een lage parkedVehicles-multiplier van alles staan.
    local generators = true
    if pop.enabled and pop.disableLowPriorityGenerators then generators = false end
    if force or last.generators ~= generators then
        SetAllLowPriorityVehicleGeneratorsActive(generators)
        last.generators = generators
    end

    if pop.enabled and pop.numberOfParkedVehicles >= 0 then
        if force or last.parkedCount ~= pop.numberOfParkedVehicles then
            SetNumberOfParkedVehicles(pop.numberOfParkedVehicles)
            last.parkedCount = pop.numberOfParkedVehicles
        end
    end

    -- Natte bandensporen en voetstappen.
    local wet = (on and Config.WetTracks and QV.state.wet) and true or false
    if force or last.wet ~= wet then
        SetForceVehicleTrails(wet)
        SetForcePedFootstepsTracks(wet)
        last.wet = wet
    end

    if on and Config.LightCutoff.enabled then
        if force or last.cutoff ~= Config.LightCutoff.value then
            SetLightsCutoffDistanceTweak(Config.LightCutoff.value)
            last.cutoff = Config.LightCutoff.value
        end
    end
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end

    applyWorldSettings(true)

    -- Populatie meteen vullen op de nieuwe dichtheid, anders duurt het
    -- minuten voor je ziet wat je instellingen doen.
    if pop.enabled and pop.instantFillOnSpawn then
        Wait(5000)
        InstantlyFillPedPopulation()
        QV.debug('populatie eenmalig gevuld')
    end

    while true do
        applyWorldSettings(true)
        Wait(10000)
    end
end)

QV.onChange(function() applyWorldSettings(false) end)

-- ---------------------------------------------------------------------------
-- Netjes opruimen
-- ---------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetDistantCarsEnabled(true)
    SetReducePedModelBudget(false)
    SetReduceVehicleModelBudget(false)
    SetPedPopulationBudget(3)
    SetVehiclePopulationBudget(3)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    SetAllLowPriorityVehicleGeneratorsActive(true)
    SetNumberOfParkedVehicles(-1)
end)

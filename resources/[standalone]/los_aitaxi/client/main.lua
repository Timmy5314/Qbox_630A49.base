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
--[[
    lib.requestModel GOOIT een error als het model niet op tijd laadt: hij loopt
    via lib.streamingRequest -> lib.waitFor, en die doet error() bij een timeout.

    Dat werd hier niet afgevangen. Een model dat niet laadde brak daarmee de hele
    startRide-handler af: geen taxi, en ook geen rideFailed, dus de speler kreeg
    zelfs geen afmelding. Stil kapot.

    Nu in een pcall, met een tweede poging. De log noemt bij falen precies welk
    model het betreft, zodat het de volgende keer geen zoekwerk is.
]]
local function loadModel(model)
    if not IsModelValid(model) then
        lib.print.error(('los_aitaxi: ongeldig model %s'):format(model))
        return false
    end

    for attempt = 1, 2 do
        local ok, err = pcall(lib.requestModel, model, 10000)

        if ok and HasModelLoaded(model) then return true end

        lib.print.warn(('los_aitaxi: model %s laadde niet (poging %d/2): %s')
            :format(model, attempt, ok and 'timeout' or tostring(err)))

        Wait(500)
    end

    return false
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

    --[[
        Geen depot ingesteld. Zoek een wegknooppunt buiten beeld.

        HIER GING HET MIS. Dit keek naar de 60 dichtstbijzijnde knooppunten en
        eiste dat er een tussen spawnMinDistance (150 m) en spawnMaxDistance
        (350 m) lag. In de stad liggen die 60 dichtstbijzijnde nodes allemaal
        ruim binnen 150 m - Los Santos zit vol wegen. Er kwam dus niets uit,
        `spawn` was nil, en startRide brak meteen af met rideFailed. Dat is de
        "de taxi kan je locatie niet bereiken" waar nooit een auto bij kwam.

        Nu drie dingen anders:
          - veel verder zoeken (400 nodes in plaats van 60)
          - de BESTE kandidaat onthouden in plaats van de eerste die past
          - en als er echt niets in de band ligt, alsnog de verste node pakken
            die we gevonden hebben. Liever een taxi die iets te dichtbij of te
            ver spawnt dan helemaal geen taxi.
    ]]
    local best, bestDist
    local farthest, farthestDist

    for n = 1, 400 do
        local found, node, heading = GetNthClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, n, 1, 3.0, 0)

        if found then
            local dist = #(coords - node)

            if dist >= config.spawnMinDistance and dist <= config.spawnMaxDistance then
                return vec4(node.x, node.y, node.z, heading)
            end

            -- Buiten de band, maar bruikbaar als er niets beters komt.
            if not farthestDist or dist > farthestDist then
                farthest, farthestDist = vec4(node.x, node.y, node.z, heading), dist
            end

            -- Te ver is minder erg dan te dichtbij: dan rijdt hij tenminste
            -- nog een stuk. Onthoud de dichtstbijzijnde die boven het minimum ligt.
            if dist > config.spawnMaxDistance and (not bestDist or dist < bestDist) then
                best, bestDist = vec4(node.x, node.y, node.z, heading), dist
            end
        end
    end

    if best then
        if config.debug then
            lib.print.info(('los_aitaxi: geen node binnen %d-%d m, uitgeweken naar %.0f m')
                :format(config.spawnMinDistance, config.spawnMaxDistance, bestDist))
        end
        return best
    end

    if farthest then
        if config.debug then
            lib.print.info(('los_aitaxi: alleen dichtbijgelegen nodes gevonden, spawn op %.0f m')
                :format(farthestDist))
        end
        return farthest
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

    --[[
        De chauffeur zag instappen als een carjacking: hij schrok, stapte uit en
        rende weg. SetBlockingOfNonTemporaryEvents alleen is daar niet genoeg
        voor - dat blokkeert omgevingsprikkels, maar niet de reactie op iemand
        die zijn portier opentrekt.

        Wat hier bij moet:
          251  gaat niet op de vlucht voor een gewapende speler
          281  reageert niet paniekerig op een dreiging
          17   blijft in het voertuig zitten in plaats van eruit te springen
          SetPedCanBeDraggedOut  je kunt hem er niet uit trekken
          SetPedFleeAttributes(0) hij vlucht sowieso nergens voor
          RelationshipGroup op PLAYER: hij ziet je als vriend, niet als bedreiging
    ]]
    SetPedCanBeDraggedOut(driver, false)
    SetPedFleeAttributes(driver, 0, false)
    SetPedCombatAttributes(driver, 17, true)
    SetPedConfigFlag(driver, 251, true)
    SetPedConfigFlag(driver, 281, true)
    SetPedDiesWhenInjured(driver, false)
    SetPedCanRagdoll(driver, false)
    SetPedRelationshipGroupHash(driver, `PLAYER`)

    -- Alle stoelen behalve die van de chauffeur vrijgeven, anders staat de
    -- passagierskant "bezet" en kun je alleen aan de bestuurderskant proberen -
    -- en juist dat leest de game als een poging tot autodiefstal.
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
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

        --[[
            ── Naar de speler ────────────────────────────────────────────────

            Hier zaten twee fouten die samen "de taxi kan je locatie niet
            bereiken" opleverden:

            1. De rijtaak werd elke 500 ms opnieuw gegeven.
               TaskVehicleDriveToCoordLongrange begint bij ELKE aanroep opnieuw
               met pathfinden. Vijf keer per seconde opnieuw opdragen betekent
               dat de auto nooit verder komt dan de eerste meters, en na
               pickupTimeout meldt de server keurig dat hij je niet kon
               bereiken. De taak wordt nu een keer gegeven en alleen opnieuw
               als de bestemming echt verschoven is of als hij vastzit.

            2. Er werd gereden naar de coordinaten van de SPELER.
               Sta je in een gebouw, op een steiger of tien meter van de weg,
               dan bestaat er geen route naartoe. De taxi rijdt nu naar het
               dichtstbijzijnde wegknooppunt, en dat telt ook als aangekomen.
        ]]

        --- Het dichtstbijzijnde punt waar een auto echt kan komen.
        ---@param coords vector3
        ---@return vector3
        local function roadNear(coords)
            local found, node = GetClosestVehicleNode(coords.x, coords.y, coords.z, 1, 3.0, 0)
            return found and node or coords
        end

        local pickup = roadNear(playerCoords)
        local taskedFor = pickup
        local lastPos = GetEntityCoords(vehicle)
        local lastMoved = GetGameTimer()

        driveTo(pickup)

        while active and not arrived do
            Wait(500)

            if not DoesEntityExist(vehicle) or not DoesEntityExist(driver) then break end

            local playerPos = GetEntityCoords(cache.ped)
            local vehPos = GetEntityCoords(vehicle)

            -- Aangekomen: bij de speler zelf, of zo dicht bij het ophaalpunt als
            -- de weg toelaat. Dat tweede is wat een speler binnen of naast de
            -- weg alsnog een taxi bezorgt in plaats van een afgebroken rit.
            if #(vehPos - playerPos) <= config.arriveDistance
                or #(vehPos - pickup) <= config.nodeArriveDistance then
                arrived = true
                break
            end

            -- Speler is doorgelopen: nieuw ophaalpunt, nieuwe opdracht.
            if #(playerPos - taskedFor) > config.retaskDistance then
                pickup = roadNear(playerPos)
                taskedFor = pickup
                driveTo(pickup)
                lastMoved = GetGameTimer()

            -- Vastgelopen (verkeer, hek, muur): opnieuw laten pathfinden.
            elseif #(vehPos - lastPos) < 1.0 then
                if GetGameTimer() - lastMoved > config.stuckSeconds * 1000 then
                    driveTo(pickup)
                    lastMoved = GetGameTimer()
                end
            else
                lastMoved = GetGameTimer()
            end

            lastPos = vehPos

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
        -- Zelfde verhaal als bij het ophalen: de rijtaak een keer geven, en
        -- alleen opnieuw als de auto vastloopt. Ook hier naar het wegknooppunt
        -- bij de waypoint, want een waypoint midden op een dak of in het water
        -- heeft geen route.
        local rideStart = GetGameTimer()

        destination = roadNear(destination)
        driveTo(destination)

        lastPos = GetEntityCoords(vehicle)
        lastMoved = GetGameTimer()

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

            local vehPos = GetEntityCoords(vehicle)

            if #(vehPos - lastPos) < 1.0 then
                if GetGameTimer() - lastMoved > config.stuckSeconds * 1000 then
                    driveTo(destination)
                    lastMoved = GetGameTimer()
                end
            else
                lastMoved = GetGameTimer()
            end

            lastPos = vehPos

            if #(vehPos - destination) <= config.dropoffDistance then
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

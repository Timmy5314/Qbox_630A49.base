-- ===========================================================================
-- PARKEREN: parkeermeter (/park) en realistisch parkeren op parkeerplaatsen
-- ===========================================================================

local function trim(s)
    return string.gsub(tostring(s), '^%s*(.-)%s*$', '%1')
end

local function RequestModelSafe(hash)
    if not hash or not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        RequestModel(hash)
        Wait(10)
    end
    return HasModelLoaded(hash)
end

-- Ruimt losse voertuigen op die op de parkeerplek staan. Begrensd: zonder limiet
-- bleef deze lus eeuwig draaien als een auto niet te verwijderen was (geen network
-- control), waardoor het complete parkeersysteem in die thread vastliep.
local function ClearParkSpot(x, y, z)
    local attempt = 0
    while IsAnyVehicleNearPoint(x, y, z, 1.1) and attempt < 20 do
        local nearveh = GetClosestVehicle(vector3(x, y, z), 2.0, 0, 70)
        -- nooit een auto slopen waar iemand in zit
        if nearveh == 0 or not DoesEntityExist(nearveh) or GetPedInVehicleSeat(nearveh, -1) ~= 0 then
            break
        end
        ReqAndDelete(nearveh)
        attempt = attempt + 1
        Wait(10)
    end
end

-- Blijft het scherm zwart hangen doordat de server niet antwoordt? Dan halen we
-- het er na 15 seconden alsnog af, anders zit de speler compleet vast.
local function FadeWatchdog()
    CreateThread(function()
        Wait(15000)
        if IsScreenFadedOut() then DoScreenFadeIn(500) end
    end)
end

-- Mag ik deze geparkeerde auto openen / ophalen?
local function MayTakeVehicle(plate, vehicleowner, entity)
    if PlayerData.identifier ~= nil and vehicleowner ~= nil and PlayerData.identifier == vehicleowner then
        return true
    end
    local share = GlobalState.Gshare and GlobalState.Gshare[plate]
    if share and PlayerData.identifier ~= nil and share[PlayerData.identifier] then
        return true
    end
    if Config.Ox_Inventory and entity and entity ~= 0 and DoesEntityExist(entity) and DoesPlayerHaveKey(entity, plate) then
        return true
    end
    return false
end

-- Auto is van jou: overnemen, ontgrendelen, sleutels regelen en de motor starten.
-- Zonder dit stap je in een dode, bevroren auto en gebeurt er niets.
local function TakeOverVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    SetVehicleOwned(vehicle)
    FreezeEntityPosition(vehicle, false)
    SetEntityCollision(vehicle, true, true)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleUndriveable(vehicle, false)
    SetPedConfigFlag(cache.ped, 429, false)
    if NetworkGetEntityIsNetworked(vehicle) then
        local ent = Entity(vehicle).state
        ent:set('havekeys', true, true)
        ent:set('unlock', true, true)
        ent:set('hotwired', false, true)
        TriggerServerEvent('renzu_garage:giveqbxkeys', VehToNet(vehicle))
    end
    SetVehicleEngineOn(vehicle, true, true, false)
end

-- ===========================================================================
-- PARKEERMETER  (/park , /parkingmeter)
-- ===========================================================================

function Park()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return Config.Notify('error', Message[77] or 'You are not in a vehicle')
    end
    if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then
        return Config.Notify('error', Message[77] or 'You must be the driver')
    end
    local closestparkingmeter = nil
    local loc = GetEntityCoords(vehicle)
    local coord = vector4(loc.x, loc.y, loc.z, GetEntityHeading(vehicle))
    if Config.ParkingAnywhere then
        closestparkingmeter = vehicle
    else
        for k, v in pairs(Config.MeterProp) do
            closestparkingmeter = GetClosestObjectOfType(loc, 7.0, GetHashKey(v), false)
            if closestparkingmeter ~= 0 then break end
        end
    end
    if closestparkingmeter == 0 or closestparkingmeter == nil then return end
    local vehicle_prop = GetVehicleProperties(vehicle)
    if not vehicle_prop then return end
    local ent = Entity(vehicle).state
    vehicle_prop.plate = trim(ent.plate or vehicle_prop.plate)
    TriggerServerCallback_("renzu_garage:parkingmeter", function(res)
        if not res then return end
        local parked = vehicle
        TaskLeaveVehicle(cache.ped, parked, 1)
        Wait(2000)
        -- Eerst opruimen, DAARNA pas eventueel vastzetten. Voorheen werd de auto
        -- bevroren en meteen daarna verwijderd; mislukte dat verwijderen, dan bleef
        -- er een bevroren spookauto staan waar je niet meer in kon.
        ReqAndDelete(parked)
        Wait(100)
        if DoesEntityExist(parked) then
            -- verwijderen lukte niet (geen network control): laat hem in elk geval
            -- NIET bevroren achter, anders blokkeert hij de parkeerplek
            FreezeEntityPosition(parked, false)
            SetEntityCollision(parked, true, true)
        end
        meter_cars[vehicle_prop.plate] = nil
    end, GetEntityCoords(closestparkingmeter), coord, vehicle_prop)
end

RegisterCommand('parkingmeter', function()
    Park()
end)

RegisterCommand('park', function()
    Park()
end)

local unparking = false

local function UnparkMeterVehicle(plate, vdata, parkcoord, preview)
    if unparking then return end
    unparking = true
    local hash = tonumber(vdata.model)
    TriggerServerEvent("renzu_garage:getparkmeter", plate, 0, hash)
    DoScreenFadeOut(500)
    FadeWatchdog()
    Wait(500)
    -- de server stuurt update_parked terug en die ruimt de preview op; nooit
    -- eindeloos wachten, anders blijft het scherm zwart als de query faalt
    local timeout = GetGameTimer() + 5000
    while meter_cars[plate] and DoesEntityExist(meter_cars[plate]) and GetGameTimer() < timeout do Wait(50) end
    if meter_cars[plate] then ReqAndDelete(meter_cars[plate]) meter_cars[plate] = nil end
    if preview and DoesEntityExist(preview) then ReqAndDelete(preview) end
    ClearParkSpot(parkcoord.x, parkcoord.y, parkcoord.z)
    local myveh = 0
    if RequestModelSafe(hash) then
        local netid = lib.callback.await('renzu_garage:CreateVehicle', false, {
            model = hash,
            coord = vec3(parkcoord.x, parkcoord.y, parkcoord.z),
            heading = parkcoord.w + 0.0,
            type = GetVehicleType(hash),
            prop = vdata
        })
        myveh = netid and NetworkGetEntityFromNetworkId(netid) or 0
    end
    if myveh ~= 0 and DoesEntityExist(myveh) then
        SetEntityHeading(myveh, parkcoord.w + 0.0)
        SetVehicleProp(myveh, vdata)
        SetVehicleOnGroundProperly(myveh)
        NetworkFadeInEntity(myveh, 1)
        TaskWarpPedIntoVehicle(cache.ped, myveh, -1)
        TakeOverVehicle(myveh)
        Config.Notify('info', Message[35])
    else
        Config.Notify('error', Message[77] or 'Vehicle could not be spawned')
    end
    DoScreenFadeIn(500)
    Wait(400)
    -- het sleutel-/anti-diefstalscript kan de motor net weer hebben afgezet
    TakeOverVehicle(myveh)
    unparking = false
end

CreateThread(function()
    Wait(2500)
    while not LocalPlayer.state.loaded do Wait(100) end
    while Config.ParkingMeter do
        if not deleting and not unparking then
            local mycoord = GetEntityCoords(cache.ped)
            local myveh = GetVehiclePedIsIn(cache.ped, false)
            for k, v in pairs(parkmeter) do
                local parkcoord = json.decode(v.park_coord)
                local vdata = json.decode(v.vehicle)
                local plate = trim(vdata.plate)
                local spot = vector3(parkcoord.x, parkcoord.y, parkcoord.z)
                local dist = #(mycoord - spot)
                local hash = tonumber(vdata.model)
                local car = meter_cars[plate]
                if car and not DoesEntityExist(car) then
                    meter_cars[plate] = nil
                    car = nil
                end
                if dist < 50 and IsModelInCdimage(hash) then
                    if not car and RequestModelSafe(hash) then
                        ClearParkSpot(parkcoord.x, parkcoord.y, parkcoord.z)
                        car = CreateVehicle(hash, parkcoord.x, parkcoord.y, parkcoord.z, parkcoord.w + 0.0, false, false)
                        local wait = GetGameTimer() + 3000
                        while not DoesEntityExist(car) and GetGameTimer() < wait do Wait(50) end
                        if DoesEntityExist(car) then
                            meter_cars[plate] = car
                            SetEntityHeading(car, parkcoord.w + 0.0)
                            SetVehicleProp(car, vdata)
                            SetEntityCollision(car, true, true)
                            SetVehicleOnGroundProperly(car)
                            NetworkFadeInEntity(car, 1)
                            SetVehicleDoorsLocked(car, 2)
                        else
                            car = nil
                        end
                    end
                    if car then
                        -- Alles wat met bevriezen/ontgrendelen te maken heeft gebeurt
                        -- alleen HIER. Voorheen deed een losse thread hetzelfde en
                        -- vochten die twee: de auto stond dan vrijwel altijd vast.
                        if dist < 5 then
                            FreezeEntityPosition(car, false)
                            SetEntityCollision(car, true, true)
                            local maytake = MayTakeVehicle(plate, v.identifier, car)
                            SetVehicleDoorsLocked(car, maytake and 1 or 2)
                            if maytake and myveh ~= 0 and myveh == car then
                                UnparkMeterVehicle(plate, vdata, parkcoord, car)
                            end
                        else
                            SetVehicleDoorsLocked(car, 2)
                            FreezeEntityPosition(car, true)
                        end
                    end
                elseif car then
                    NetworkFadeInEntity(car, 1)
                    ReqAndDelete(car)
                    meter_cars[plate] = nil
                end
            end
        end
        Wait(250)
    end
end)

RegisterNetEvent('renzu_garage:update_parked', function(t, plate, p)
    -- Dit event komt voor ELKE speler binnen zodra iemand waar dan ook een auto
    -- parkeert/uitparkeert (server broadcast naar -1). De vorige Wait(1500) hield
    -- daardoor de HELE parkeer-loop van ALLE spelers 1.5s+ stil bij elke actie van
    -- wie dan ook -> voelde aan als "blijft hangen" en moest je soms meerdere keren
    -- instappen. Kort genoeg houden zodat het alleen de eigen update afwacht.
    deleting = true
    Wait(150)
    if p then
        parkmeter = p
        if plate ~= nil then
            for k, v in pairs(meter_cars) do
                if trim(k) == trim(plate) then
                    meter_cars[k] = nil -- was: een verkeerde, opgepoetste key -> stale entry
                    ReqAndDelete(v)
                end
            end
        end
    end
    parkedvehicles = t
    Wait(100)
    if plate ~= nil then
        for k, v in pairs(spawned_cars) do
            if trim(k) == trim(plate) then
                spawned_cars[k] = nil
                ReqAndDelete(v)
            end
        end
    end
    deleting = false
end)

-- ===========================================================================
-- REALISTISCH PARKEREN (parkeerplaatsen)
-- ===========================================================================

parknotified = nil -- tijdstip (GetGameTimer) van de laatste parkeermelding
local realpark_running = false
local currentparkzone = nil

local function UnparkVehicle(plate, vdata, coord, preview)
    if unparking then return end
    unparking = true
    local hash = tonumber(vdata.model)
    TriggerServerEvent("renzu_garage:unpark", plate, 0, hash)
    DoScreenFadeOut(500)
    FadeWatchdog()
    Wait(500)
    -- niet eindeloos wachten op de server; anders hangt de speler in een zwart scherm
    local timeout = GetGameTimer() + 5000
    while spawned_cars[plate] and DoesEntityExist(spawned_cars[plate]) and GetGameTimer() < timeout do Wait(50) end
    if spawned_cars[plate] then ReqAndDelete(spawned_cars[plate]) spawned_cars[plate] = nil end
    if preview and DoesEntityExist(preview) then ReqAndDelete(preview) end
    ClearParkSpot(coord.x, coord.y, coord.z)
    local myveh = 0
    if RequestModelSafe(hash) then
        -- via de server spawnen: die maakt er een echt genetwerkt voertuig van en
        -- regelt meteen de sleutels. Client-side CreateVehicle gaf een auto zonder
        -- sleutels die je dus niet kon starten.
        local netid = lib.callback.await('renzu_garage:CreateVehicle', false, {
            model = hash,
            coord = vec3(coord.x, coord.y, coord.z),
            heading = (coord.heading or 0.0) + 0.0,
            type = GetVehicleType(hash),
            prop = vdata
        })
        myveh = netid and NetworkGetEntityFromNetworkId(netid) or 0
    end
    if myveh ~= 0 and DoesEntityExist(myveh) then
        SetEntityHeading(myveh, (coord.heading or 0.0) + 0.0)
        SetVehicleProp(myveh, vdata)
        SetVehicleOnGroundProperly(myveh)
        NetworkFadeInEntity(myveh, 1)
        TaskWarpPedIntoVehicle(cache.ped, myveh, -1)
        TakeOverVehicle(myveh)
        Config.Notify('info', Message[35])
    else
        Config.Notify('error', Message[77] or 'Vehicle could not be spawned')
    end
    DoScreenFadeIn(500)
    Wait(400)
    TakeOverVehicle(myveh)
    unparking = false
end

local function DoPark(zone)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local props = GetVehicleProperties(vehicle)
    if not props then return end
    local ent = Entity(vehicle).state
    props.plate = trim(ent.plate or props.plate)
    local coord = {
        heading = GetEntityHeading(vehicle),
        x = GetEntityCoords(vehicle).x,
        y = GetEntityCoords(vehicle).y,
        z = GetEntityCoords(vehicle).z
    }
    TaskLeaveVehicle(cache.ped, vehicle, 1)
    Wait(2000)
    spawned_cars[props.plate] = nil
    local success = lib.callback.await("renzu_garage:park", false, props.plate, 1, coord, props.model, props, zone)
    if success then
        ReqAndDelete(vehicle)
        Wait(100)
        if DoesEntityExist(vehicle) then
            -- verwijderen lukte niet: in elk geval niet bevroren achterlaten
            FreezeEntityPosition(vehicle, false)
            SetEntityCollision(vehicle, true, true)
        end
        Config.Notify('success', Message[34])
    else
        -- parkeren mislukte (geld/eigendom): auto gewoon bruikbaar laten
        FreezeEntityPosition(vehicle, false)
        SetEntityCollision(vehicle, true, true)
        SetVehicleDoorsLocked(vehicle, 1)
    end
end

local function HandleParkZone(index, zone)
    local center = vector3(zone.garage_x, zone.garage_y, zone.garage_z)
    currentparkzone = zone
    neargarage = true
    canpark = true
    while #(center - GetEntityCoords(cache.ped)) < zone.Dist do
        if not deleting and not unparking then
            local mycoord = GetEntityCoords(cache.ped)
            local myveh = GetVehiclePedIsIn(cache.ped, false)
            local list = parkedvehicles or {}
            for i = 1, #list do
                local park = list[i]
                local ok, coord = pcall(json.decode, park.park_coord)
                local ok2, vdata = pcall(json.decode, park[vehiclemod])
                if ok and ok2 and coord and vdata then
                    local plate = trim(park.plate)
                    local spot = vector3(coord.x, coord.y, coord.z)
                    local dist = #(mycoord - spot)
                    local hash = tonumber(vdata.model)
                    local car = spawned_cars[plate]
                    if car and not DoesEntityExist(car) then
                        spawned_cars[plate] = nil
                        car = nil
                    end
                    if dist < zone.Dist and IsModelInCdimage(hash) then
                        if not car and RequestModelSafe(hash) then
                            ClearParkSpot(coord.x, coord.y, coord.z)
                            car = CreateVehicle(hash, coord.x, coord.y, coord.z, (coord.heading or 0.0) + 0.0, false, false)
                            local wait = GetGameTimer() + 3000
                            while not DoesEntityExist(car) and GetGameTimer() < wait do Wait(50) end
                            if DoesEntityExist(car) then
                                spawned_cars[plate] = car
                                SetEntityHeading(car, (coord.heading or 0.0) + 0.0)
                                SetVehicleProp(car, vdata)
                                SetEntityCollision(car, true, true)
                                SetVehicleOnGroundProperly(car)
                                NetworkFadeInEntity(car, 1)
                                SetVehicleDoorsLocked(car, 2)
                            else
                                car = nil
                            end
                        end
                        if car then
                            if dist < 5 then
                                -- sta je ernaast: los, botsbaar en (als hij van jou is)
                                -- ontgrendeld. Anders kun je nooit instappen en dus
                                -- ook nooit ophalen.
                                FreezeEntityPosition(car, false)
                                SetEntityCollision(car, true, true)
                                local maytake = MayTakeVehicle(plate, park[owner], car)
                                SetVehicleDoorsLocked(car, maytake and 1 or 2)
                                if maytake and myveh ~= 0 and myveh == car then
                                    UnparkVehicle(plate, vdata, coord, car)
                                end
                            else
                                SetVehicleDoorsLocked(car, 2)
                                FreezeEntityPosition(car, true)
                            end
                        end
                    elseif car then
                        NetworkFadeInEntity(car, 1)
                        ReqAndDelete(car)
                        spawned_cars[plate] = nil
                    end
                end
            end
        end
        Wait(250)
    end
    currentparkzone = nil
    canpark = false
end

RealPark = function()
    -- De ox_lib zone roept dit bij elke onEnter aan. Zonder deze rem draaien er
    -- meerdere lussen tegelijk die elkaars auto's spawnen en verwijderen; dat gaf
    -- gestotter en auto's waar je pas na een paar pogingen in kon.
    if realpark_running then return end
    realpark_running = true
    while true do
        local mycoord = GetEntityCoords(cache.ped)
        local zone, index = nil, nil
        for k, v in pairs(parking) do
            if #(vector3(v.garage_x, v.garage_y, v.garage_z) - mycoord) < v.Dist then
                zone, index = v, k
                break
            end
        end
        if not zone then break end
        HandleParkZone(index, zone)
    end
    realpark_running = false
    currentparkzone = nil
    canpark = false
end

-- Aparte thread voor de [R]-toets. Voorheen zat dit in een blokkerende lus midden
-- in het spawnen van de geparkeerde auto's: zolang je stilstond werd er niets meer
-- ge-spawned, ontgrendeld of opgeruimd.
CreateThread(function()
    while true do
        local sleep = 500
        local zone = currentparkzone
        if zone and not ingarage and not unparking then
            local vehicle = GetVehiclePedIsIn(cache.ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == cache.ped and IsVehicleStopped(vehicle) then
                sleep = 0
                -- Tijd-gebaseerde rem: toont de melding hooguit eens per 10 sec.
                -- Bewust GEEN vlag die "aan" kan blijven hangen, want dan komt de
                -- melding nooit meer terug zodra de lus anders loopt dan verwacht.
                local now = GetGameTimer()
                if not parknotified or now - parknotified > 10000 then
                    parknotified = now
                    Config.Notify('info', '$ ' .. zone.fee .. ' Fee: ' .. Message[33] .. " [R]")
                end
                if IsControlJustPressed(0, Config.ParkButton) then
                    DoPark(zone)
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(500)
    while not LocalPlayer.state.loaded do Wait(100) end
    while Config.Realistic_Parking and not Config.Oxlib do
        RealPark()
        Wait(1000)
    end
end)

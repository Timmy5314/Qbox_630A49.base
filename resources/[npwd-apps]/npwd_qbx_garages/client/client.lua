--[[
    NPWD Garages — client.

    De locatie-knop deed niets omdat hij alleen de lokale game pool doorzocht:
    staat je auto in de garage of buiten je OneSync-radius, dan is er geen entity
    en gebeurde er stilletjes niets (findVehFromPlateAndLocate gaf nil terug).

    Nu: de server levert een concreet doel (garage / impound / parkeerplek). Alleen
    voor voertuigen die daadwerkelijk rondrijden valt hij terug op een wereldscan.
    In alle gevallen krijgt de speler een waypoint én een duidelijke melding.
]]

local function notify(content)
    exports.npwd:createNotification({
        notisId = 'npwd:qbx_garage:requestWaypoint',
        appId   = 'npwd_qbx_garages',
        content = content,
        keepOpen = false,
        duration = 5000,
        path = '/npwd_qbx_garages',
    })
end

--- Zoekt een voertuig op kenteken in de wereld (alleen voor rijdende voertuigen).
--- @return vector3?
local function findVehicleCoordsByPlate(plate)
    local pool = GetGamePool('CVehicle')
    for i = 1, #pool do
        local vehicle = pool[i]
        if DoesEntityExist(vehicle) and qbx.getVehiclePlate(vehicle) == plate then
            return GetEntityCoords(vehicle)
        end
    end
    return nil
end

local function setWaypoint(x, y)
    SetNewWaypoint(x + 0.0, y + 0.0)
end

RegisterNUICallback('npwd:qbx_garage:getVehicles', function(_, cb)
    local vehicles = lib.callback.await('npwd_qbx_garages:server:getPlayerVehicles', false)

    for _, v in pairs(vehicles) do
        local class = GetVehicleClassFromName(v.model)
        if class == 15 or class == 16 then
            v.type = 'aircraft'
        elseif class == 14 then
            v.type = 'boat'
        elseif class == 13 or class == 8 then
            v.type = 'bike'
        else
            v.type = 'car'
        end
    end

    cb({ status = 'ok', data = vehicles })
end)

RegisterNUICallback('npwd:qbx_garage:requestWaypoint', function(data, cb)
    local plate = data and data.plate

    if not plate then
        notify(locale('notification.cannot_locate'))
        return cb({})
    end

    local info = lib.callback.await('npwd_qbx_garages:server:getVehicleTarget', false, plate)

    if not info then
        notify(locale('notification.cannot_locate'))
        return cb({})
    end

    -- Vast doel bekend (garage, impound of geparkeerd op straat).
    if info.target then
        setWaypoint(info.target.x, info.target.y)

        local label = info.target.label or locale('states.garage_unknown')
        if info.state == 'impounded' then
            notify(locale('notification.marked_impound', label))
        elseif info.state == 'parked' then
            notify(locale('notification.marked_parked', label))
        else
            notify(locale('notification.marked_garage', label))
        end

        return cb({})
    end

    -- Geen vast doel: het voertuig staat "uit". Live zoeken in de wereld.
    local coords = findVehicleCoordsByPlate(plate)
    if coords then
        setWaypoint(coords.x, coords.y)
        notify(locale('notification.marked'))
    else
        notify(locale('notification.out_of_range'))
    end

    cb({})
end)

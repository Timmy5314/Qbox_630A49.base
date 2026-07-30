if GetConvar('qbx_vehiclekeys:enableBridge', 'true') ~= 'true' then return end

---@param source number
---@param plate string?
---@param trusted boolean? true wanneer een server-side resource dit aanroept via de export
local function giveKeys(source, plate, trusted)
    local vehicles
    if plate then
        -- Server-side aanroepers mogen elk kenteken opgeven; clients alleen voertuigen
        -- die daadwerkelijk naast ze staan.
        vehicles = trusted and GetVehiclesFromPlate(plate) or GetNearbyVehiclesFromPlate(source, plate)
    else
        vehicles = {GetVehiclePedIsIn(GetPlayerPed(source), false)}
    end
    local success = false
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            if GiveKeys(source, vehicles[i], true) then
                success = true
            end
            Wait(20)
        end
    end
    if success then
        exports.qbx_core:Notify(source, locale('notify.keys_taken'))
    end
    return success
end

CreateQbExport('GiveKeys', function(source, plate)
    return giveKeys(source, plate, true)
end)

---@param source number
---@param plate string?
---@param trusted boolean? true wanneer een server-side resource dit aanroept via de export
local function removeKeys(source, plate, trusted)
    local vehicles = trusted and GetVehiclesFromPlate(plate) or GetNearbyVehiclesFromPlate(source, plate)
    local success = false
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            if RemoveKeys(source, vehicle, true) then
                success = true
            end
            Wait(20)
        end
    end
    if success then
        exports.qbx_core:Notify(source, locale('notify.keys_removed'))
    end
    return success
end

CreateQbExport('RemoveKeys', function(source, plate)
    return removeKeys(source, plate, true)
end)

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    giveKeys(source, plate, false)
end)

RegisterNetEvent('qb-vehiclekeys:server:removeKeys', function(plate)
    removeKeys(source, plate, false)
end)

CreateQbExport('HasKeys', function(source, plate)
    local vehicles = GetVehiclesFromPlate(plate)
    local success = false
    for i = 1, #vehicles do
        success = success or HasKeys(source, vehicles[i])
    end
    return success
end)
--[[
    ps_lib vehicle keys bridge — qbx_vehiclekeys.

    De meegeleverde 'qb' bridge roept QBCore.Functions.GetPlate() aan. Op deze server
    draait geen qb-core resource (qbx_core levert alleen een interne bridge), dus is
    de QBCore global in ps_lib altijd nil en gooit die bridge een runtime error zodra
    een script een sleutel wil geven.

    Deze bridge praat rechtstreeks met qbx_vehiclekeys:
      - geven  : lib.callback 'qbx_vehiclekeys:server:giveKeys' (netId, server-gevalideerd)
      - innemen: qb-compat event dat qbx_vehiclekeys zelf registreert in bridge/qb/server.lua
]]

local function getPlate(vehicle)
    return (GetVehicleNumberPlateText(vehicle):gsub('^%s*(.-)%s*$', '%1'))
end

---@param vehicle number entity handle
---@return boolean
function ps.giveVehicleKey(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then
        ps.warn('giveVehicleKey: vehicle is not networked')
        return false
    end

    lib.callback.await('qbx_vehiclekeys:server:giveKeys', false, netId)
    return true
end

---@param vehicle number entity handle
---@return boolean
function ps.removeVehicleKey(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    TriggerServerEvent('qb-vehiclekeys:server:removeKeys', getPlate(vehicle))
    return true
end

---@param vehicle number entity handle
---@return boolean
function ps.hasVehicleKey(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    return exports.qbx_vehiclekeys:HasKeys(vehicle) and true or false
end

ps.success('Vehicle Keys Module Loaded: qbx_vehiclekeys')

---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job garage (client)

    The client never creates the vehicle. The server does that with
    CreateVehicleServerSetter and hands back a network id, which is what makes
    duplication impossible: there is only ever one entity per plate.
]]

JobGarage = {}

local opening = false
local busy = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@param netId number
---@return number? vehicle
local function waitForVehicle(netId)
    local attempts = 0
    while not NetworkDoesNetworkIdExist(netId) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not NetworkDoesNetworkIdExist(netId) then return nil end

    local vehicle = NetToVeh(netId)
    attempts = 0
    while (vehicle == 0 or not DoesEntityExist(vehicle)) and attempts < 100 do
        Wait(50)
        vehicle = NetToVeh(netId)
        attempts = attempts + 1
    end

    return DoesEntityExist(vehicle) and vehicle or nil
end

---@param vehicle number
---@return boolean
local function takeControl(vehicle)
    local attempts = 0
    while not NetworkHasControlOfEntity(vehicle) and attempts < 60 do
        NetworkRequestControlOfEntity(vehicle)
        Wait(20)
        attempts = attempts + 1
    end
    return NetworkHasControlOfEntity(vehicle)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Taking a vehicle out
-- ─────────────────────────────────────────────────────────────────────────────

---@param plate string
local function takeOut(plate)
    if busy then return end
    busy = true

    local result = lib.callback.await('renzu_jobs:takeVehicle', false, plate)
    if not result or type(result) ~= 'table' then
        busy = false
        return
    end

    Nui.close()

    local vehicle = waitForVehicle(result.netId)
    if not vehicle then
        Bridge.notify('error', 'Job Garage', 'The vehicle did not stream in. Try again.')
        busy = false
        return
    end

    takeControl(vehicle)

    if result.props and next(result.props) then
        -- Never let stored properties change which vehicle this is.
        result.props.model = nil
        pcall(lib.setVehicleProperties, vehicle, result.props)
    end

    SetVehicleNumberPlateText(vehicle, result.plate)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleDoorsLocked(vehicle, 1)

    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

    busy = false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Handing a vehicle back in
-- ─────────────────────────────────────────────────────────────────────────────

function JobGarage.store()
    if busy then return end

    local vehicle, plate = Utils.currentJobVehicle()
    if not vehicle then
        Bridge.notify('error', 'Job Garage', 'You are not in a company vehicle.')
        return
    end

    busy = true

    local props
    local ok, result = pcall(lib.getVehicleProperties, vehicle)
    if ok then props = result end
    if props then props.plate = plate end

    local netId = VehToNet(vehicle)
    local stored = lib.callback.await('renzu_jobs:storeVehicle', false, netId, props or {})

    if stored then
        -- The server deletes the entity; clean up locally if it lingers.
        Wait(250)
        if DoesEntityExist(vehicle) then Utils.deleteVehicle(vehicle) end
    end

    busy = false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- The garage point
-- ─────────────────────────────────────────────────────────────────────────────

--- Driving in stores the vehicle, walking up opens the list.
function JobGarage.interact()
    if cache.vehicle then
        JobGarage.store()
        return
    end
    JobGarage.open()
end

function JobGarage.open()
    if opening or busy or Nui.isOpen() then return end
    opening = true

    local data = lib.callback.await('renzu_jobs:getGarage', false)
    opening = false

    if not data then return end
    Nui.open('garage', data)
end

RegisterNetEvent('renzu_jobs:opengarage', function() JobGarage.interact() end)

local function refresh()
    local data = lib.callback.await('renzu_jobs:getGarage', false)
    if data then Nui.update('garage', data) end
end

RegisterNUICallback('garage:take', function(data, cb)
    cb(true)
    CreateThread(function() takeOut(data.plate) end)
end)

RegisterNUICallback('garage:recover', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:recoverVehicle', false, data.plate)
    if ok then refresh() end
    cb(ok)
end)

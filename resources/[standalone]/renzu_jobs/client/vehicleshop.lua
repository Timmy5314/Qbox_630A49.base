---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job vehicle shop (client)

    Buys for the company. The vehicle is not spawned here: it lands in the job
    garage, which is where employees sign it out.
]]

VehicleShop = {}

local opening = false

function VehicleShop.open()
    if opening or Nui.isOpen() then return end
    opening = true

    local data = lib.callback.await('renzu_jobs:getVehicleShop', false)
    opening = false

    if not data then return end

    -- Fill in the class label from the game, so the config does not have to.
    for _, vehicle in ipairs(data.vehicles) do
        vehicle.class = Utils.vehicleClass(vehicle.model)
    end

    Nui.open('vehicleshop', data)
end

RegisterNetEvent('renzu_jobs:openvehicleshop', function() VehicleShop.open() end)

RegisterNUICallback('vehicleshop:buy', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:buyVehicle', false, data.model)

    if ok then
        local fresh = lib.callback.await('renzu_jobs:getVehicleShop', false)
        if fresh then
            for _, vehicle in ipairs(fresh.vehicles) do
                vehicle.class = Utils.vehicleClass(vehicle.model)
            end
            Nui.update('vehicleshop', fresh)
        end
    end

    cb(ok)
end)

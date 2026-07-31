--[[
    Enige taak van de client: melden dat je achter het stuur zit. De server
    kijkt of daar een sleutel bij hoort.

    qbx_vehiclekeys start bij het instappen zelf al een lus die de motor uit
    houdt tot GetIsVehicleAccessible waar wordt. Zodra de server hier de
    sleutels toekent verandert de keysList-statebag en stopt die lus vanzelf.
    Er hoeft dus niets gesynchroniseerd te worden.
]]

local seatCheckPending = false

local function requestKeys()
    local vehicle = cache.vehicle
    if not vehicle or seatCheckPending then return end

    -- Al toegang? Dan is er niets te vragen.
    if exports.qbx_vehiclekeys:HasKeys(vehicle) then return end

    seatCheckPending = true
    TriggerServerEvent('los_vehiclekeys:requestKeys', VehToNet(vehicle))

    -- Kort blokkeren zodat in- en uitstappen niet een reeks events oplevert.
    SetTimeout(1500, function() seatCheckPending = false end)
end

lib.onCache('seat', function(seat)
    if seat ~= -1 then return end

    -- cache.vehicle loopt een frame achter op cache.seat.
    CreateThread(function()
        Wait(0)
        requestKeys()
    end)
end)

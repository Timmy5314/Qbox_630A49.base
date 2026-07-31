--[[
    Koppeling met los_vehiclekeys: de sleutel als ox_inventory-item.

    renzu_garage heeft een eigen sleutel-item (`keys`), maar dat staat uit -
    Config.Ox_Inventory is false, de toegang loopt via qbx_vehiclekeys. Deze twee
    helpers hangen daarnaast en werken het ITEM bij, zodat parkeren de sleutel
    inneemt en uithalen hem teruggeeft.

    Bewust hier en niet in los_vehiclekeys: dit zijn de twee plekken in
    renzu_garage waar een voertuig van eigenaar-in-de-wereld wisselt, en die
    kende renzu_garage al. Andersom zou los_vehiclekeys de interne callbacks van
    renzu_garage moeten kennen.

    Beide zijn no-ops als los_vehiclekeys niet draait.
]]

local function keysAvailable()
    return GetResourceState('los_vehiclekeys'):find('start') ~= nil
end

---Naam van het voertuig zoals renzu_garage hem kent, voor op het item.
---@param plate string
---@return string?
local function vehicleName(plate)
    local vehicles = GlobalState.GVehicles
    local entry = vehicles and vehicles[plate]

    if entry and entry.name and entry.name ~= 'NULL' then
        return entry.name
    end
end

---@param src number
---@param plate string
function LosGiveVehicleKey(src, plate)
    if not keysAvailable() or not src or type(plate) ~= 'string' then return end

    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    local ok, err = pcall(function()
        return exports.los_vehiclekeys:GiveKeyItem(src, plate, vehicleName(plate))
    end)

    if not ok then
        print(('[renzu_garage] los_vehiclekeys:GiveKeyItem faalde: %s'):format(err))
    end
end

---@param src number
---@param plate string
function LosTakeVehicleKey(src, plate)
    if not keysAvailable() or not src or type(plate) ~= 'string' then return end

    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    local ok, err = pcall(function()
        return exports.los_vehiclekeys:RemoveKeyItem(src, plate)
    end)

    if not ok then
        print(('[renzu_garage] los_vehiclekeys:RemoveKeyItem faalde: %s'):format(err))
    end
end

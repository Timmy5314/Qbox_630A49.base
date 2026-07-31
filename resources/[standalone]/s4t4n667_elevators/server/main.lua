--[[
    Het origineel had een lege server.lua: job- en itemsloten werden alleen
    client-side gecontroleerd. Voor de begane grond van een parkeergarage maakt
    dat weinig uit, voor de helikopterplatform van het politiebureau wel.

    De client vraagt hier toestemming voordat hij iemand verplaatst.
]]

lib.locale()

local config = lib.require 'config'

---Bouwt dezelfde verdiepingenlijst als de client, inclusief de ps-housing
---uitbreiding, zodat server en client naar hetzelfde kijken.
---@return table<string, table[]>
local function buildElevators()
    local elevators = {}

    for name, floors in pairs(config.elevators) do
        elevators[name] = floors
    end

    if config.psHousing.enabled then
        for name, floors in pairs(config.psHousing.floors) do
            elevators[name] = floors
        end
    end

    return elevators
end

local elevators = buildElevators()

---@param source number
---@param floor table
---@return boolean
local function meetsJobLock(source, floor)
    if not floor.joblock or not next(floor.joblock) then return true end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    local job = player.PlayerData.job
    if not job then return false end

    local required = floor.joblock[job.name]
    if not required then return false end

    -- Op deze server is on-duty een bewuste keuze; een agent die uitgeklokt is
    -- hoort niet bij het helikopterdek te kunnen.
    if not job.onduty then return false end

    return (job.grade and job.grade.level or 0) >= required
end

---@param source number
---@param floor table
---@return boolean
local function meetsItemLock(source, floor)
    if not floor.itemlock or not next(floor.itemlock) then return true end

    for i = 1, #floor.itemlock do
        local count = exports.ox_inventory:Search(source, 'count', floor.itemlock[i])
        if type(count) == 'number' and count > 0 then return true end
    end

    return false
end

lib.callback.register('s4t4n667_elevators:useFloor', function(source, elevatorName, floorIndex)
    if type(elevatorName) ~= 'string' or type(floorIndex) ~= 'number' then return false end

    local floors = elevators[elevatorName]
    if not floors then return false end

    local floor = floors[floorIndex]
    if not floor then return false end

    -- Sta je wel bij deze lift? Anders is dit een gratis teleport naar elke
    -- verdieping van elke lift op de map.
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local atSomeFloor = false

    for i = 1, #floors do
        local target = floors[i].coords
        if #(coords - vec3(target.x, target.y, target.z)) <= 5.0 then
            atSomeFloor = true
            break
        end
    end

    if not atSomeFloor then return false end

    if not meetsJobLock(source, floor) then
        return false, locale('no_access_job')
    end

    if not meetsItemLock(source, floor) then
        return false, locale('no_access_item')
    end

    return true
end)

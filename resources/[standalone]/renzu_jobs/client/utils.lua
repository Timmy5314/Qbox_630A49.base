---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - client helpers
]]

Utils = {}

local VEHICLE_CLASSES = {
    [0] = 'Compacts',   [1] = 'Sedans',     [2] = 'SUVs',        [3] = 'Coupes',
    [4] = 'Muscle',     [5] = 'Sports Classic', [6] = 'Sports',  [7] = 'Super',
    [8] = 'Motorcycles',[9] = 'Off-road',   [10] = 'Industrial', [11] = 'Utility',
    [12] = 'Vans',      [13] = 'Cycles',    [14] = 'Boats',      [15] = 'Helicopters',
    [16] = 'Planes',    [17] = 'Service',   [18] = 'Emergency',  [19] = 'Military',
    [20] = 'Commercial',[21] = 'Trains',
}

---@param model string|number
---@return string
function Utils.vehicleClass(model)
    local hash = type(model) == 'string' and joaat(model) or model
    return VEHICLE_CLASSES[GetVehicleClassFromName(hash)] or 'Unknown'
end

---@param model string|number
---@return string
function Utils.vehicleLabel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    local display = GetDisplayNameFromVehicleModel(hash)
    local label = GetLabelText(display)
    if label == 'NULL' or label == '' then return display end
    return label
end

--- Remove a vehicle we own control over, cleanly.
---@param entity number
function Utils.deleteVehicle(entity)
    if not entity or not DoesEntityExist(entity) then return end

    SetEntityAsMissionEntity(entity, true, true)

    local attempts = 0
    while not NetworkHasControlOfEntity(entity) and attempts < 50 and DoesEntityExist(entity) do
        NetworkRequestControlOfEntity(entity)
        Wait(20)
        attempts = attempts + 1
    end

    if DoesEntityExist(entity) then
        DeleteVehicle(entity)
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end

--- Find a streamed vehicle by its renzu_jobs plate state bag.
---@param plate string
---@return number? entity
function Utils.findVehicleByPlate(plate)
    plate = plate:gsub('%s+', ''):upper()

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) then
            local statePlate = Entity(vehicle).state.renzuPlate
            if statePlate and statePlate:gsub('%s+', ''):upper() == plate then
                return vehicle
            end

            local worldPlate = GetVehicleNumberPlateText(vehicle)
            if worldPlate and worldPlate:gsub('%s+', ''):upper() == plate then
                return vehicle
            end
        end
    end
    return nil
end

--- Is the vehicle the player sits in a company vehicle of their job?
---@return number? entity, string? plate
function Utils.currentJobVehicle()
    local vehicle = cache.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return nil, nil end

    local state = Entity(vehicle).state
    if not state.renzuPlate then return nil, nil end
    if Bridge.job and state.renzuJob and state.renzuJob ~= Bridge.job.name then return nil, nil end

    return vehicle, state.renzuPlate
end

---@param seconds number
---@return string
function Utils.formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)

    if hours > 0 then
        return ('%02d:%02d:%02d'):format(hours, minutes % 60, seconds % 60)
    end
    return ('%02d:%02d'):format(minutes, seconds % 60)
end

---@param value number
---@return string
function Utils.money(value)
    local formatted = tostring(math.floor(tonumber(value) or 0))
    local matches = 1
    while matches > 0 do
        formatted, matches = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
    end
    return formatted
end

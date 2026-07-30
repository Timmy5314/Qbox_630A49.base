if GetConvar('qbx_vehiclekeys:enableBridge', 'true') ~= 'true' then return end

function CreateQbExport(name, cb)
    AddEventHandler(('__cfx_export_qb-vehiclekeys_%s'):format(name), function(setCB)
        setCB(cb)
    end)
end

---Kentekens vergelijken: ox.cfg draait met inventory:trimplate, en de native geeft
---soms trailing spaces terug. Zonder normalisatie matcht 'ABC123 ' niet op 'ABC123'.
---@param plate string?
---@return string?
local function normalizePlate(plate)
    if type(plate) ~= 'string' then return end
    local trimmed = plate:gsub('%s+$', ''):gsub('^%s+', '')
    return trimmed ~= '' and trimmed:upper() or nil
end

function GetVehiclesFromPlate(plate)
    local target = normalizePlate(plate)
    if not target then return {} end

    Wait(500) -- delay needed to give client spawned vehicles time to be known to the server
    local vehicles = GetAllVehicles()
    local vehEntityFromPlate = {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        -- Was: `if plate == vehPlate or GetVehicleNumberPlateText(vehicle) then`.
        -- Die tweede tak is een string en dus altijd truthy, waardoor deze functie
        -- ELK voertuig op de server teruggaf ongeacht het kenteken. Dat maakte
        -- AcquireVehicleKeys en HasKeys volledig exploitbaar.
        local vehPlate = normalizePlate(qbx.getVehiclePlate(vehicle)) or normalizePlate(GetVehicleNumberPlateText(vehicle))
        if vehPlate and vehPlate == target then
            vehEntityFromPlate[#vehEntityFromPlate + 1] = vehicle
        end
    end

    return vehEntityFromPlate
end
--[[
    NPWD Garages — aangepast voor renzu_garage.

    Origineel praatte deze app met qbx_garages. Die resource draait niet op deze
    server (vervangen door renzu_garage), waardoor de assert op regel 2 de hele app
    liet crashen bij startup en de locatie-knop nooit iets deed.

    Wat er nu gebeurt:
      - voertuigen komen uit player_vehicles (qbx schema + renzu kolommen)
      - status leest zowel qbx `state` als renzu `impound` / `isparked`
      - de server bepaalt een concreet locatiedoel per voertuig, zodat de
        telefoon een waypoint kan zetten ook als de auto niet in de buurt is
]]

local GARAGE_RESOURCE = 'renzu_garage'

assert(GetResourceState(GARAGE_RESOURCE) == 'started',
    ('%s is not started — npwd_qbx_garages needs it for garage locations'):format(GARAGE_RESOURCE))

local VEHICLES = exports.qbx_core:GetVehiclesByName()

--- qbx `state` kolom
local STATE_OUT       = 0
local STATE_GARAGED   = 1
local STATE_IMPOUNDED = 2

local function trimPlate(plate)
    if not plate then return '' end
    return (plate:gsub('^%s*(.-)%s*$', '%1'))
end

--- Bepaalt waar een voertuig te vinden is en hoe de telefoon dat moet tonen.
--- @return string state  'garaged' | 'out' | 'impounded' | 'parked' | 'unknown'
--- @return table? target { x, y, z, label }  nil = client moet live zoeken op kenteken
local function resolveLocation(row, garages)
    local isImpounded = row.impound == 1 or row.state == STATE_IMPOUNDED
    local isParked    = row.isparked == 1

    if isImpounded then
        local g = row.garage and garages[row.garage]
        if not g or g.kind ~= 'impound' then
            g = exports[GARAGE_RESOURCE]:GetDefaultImpound()
        end
        if g then
            return 'impounded', { x = g.coords.x, y = g.coords.y, z = g.coords.z, label = g.label }
        end
        return 'impounded', nil
    end

    if row.state == STATE_GARAGED then
        local g = row.garage and garages[row.garage]
        if g then
            return 'garaged', { x = g.coords.x, y = g.coords.y, z = g.coords.z, label = g.label }
        end
        return 'garaged', nil
    end

    -- Buiten de garage. Eerst kijken of renzu het als "geparkeerd" heeft opgeslagen.
    if isParked then
        local coords = exports[GARAGE_RESOURCE]:GetParkedCoords(row.plate)
        if coords then
            return 'parked', { x = coords.x, y = coords.y, z = coords.z, label = locale('states.parked_street') }
        end
    end

    -- Anders: nil target -> de client scant de wereld op kenteken.
    return 'out', nil
end

lib.callback.register('npwd_qbx_garages:server:getPlayerVehicles', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local rows = MySQL.query.await(
        'SELECT id, plate, vehicle, garage, state, impound, isparked, `type`, `job` \z
         FROM player_vehicles WHERE citizenid = ?',
        { player.PlayerData.citizenid }
    )
    if not rows then return {} end

    local garages = exports[GARAGE_RESOURCE]:GetGarageIndex()
    local result = {}

    for i = 1, #rows do
        local row = rows[i]
        local model = row.vehicle
        local meta = VEHICLES[model]

        local state, target = resolveLocation(row, garages)
        local garageLabel = row.garage and garages[row.garage] and garages[row.garage].label

        result[#result + 1] = {
            id       = row.id,
            plate    = trimPlate(row.plate),
            model    = model,
            vehicle  = meta and meta.name or 'Unknown',
            brand    = meta and meta.brand or 'Vehicle',
            state    = state,
            garage   = garageLabel or (target and target.label) or locale('states.garage_unknown'),
            target   = target,
        }
    end

    return result
end)

--- De telefoon vraagt een waypoint. De server geeft het doel terug; de client
--- valt alleen terug op een wereldscan als er geen vast doel is (voertuig rijdt rond).
lib.callback.register('npwd_qbx_garages:server:getVehicleTarget', function(source, plate)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or type(plate) ~= 'string' then return nil end

    local row = MySQL.single.await(
        'SELECT plate, garage, state, impound, isparked FROM player_vehicles \z
         WHERE citizenid = ? AND TRIM(plate) = ? LIMIT 1',
        { player.PlayerData.citizenid, trimPlate(plate) }
    )
    if not row then return nil end

    local garages = exports[GARAGE_RESOURCE]:GetGarageIndex()
    local state, target = resolveLocation(row, garages)

    return { state = state, target = target }
end)

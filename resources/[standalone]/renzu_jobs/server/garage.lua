---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job garage

    Job vehicles belong to the COMPANY, not to a player. Employees sign one out,
    drive it, and hand it back in. The plate is registered in renzu_jobs_vehicles
    and never touches player_vehicles, so nobody ever "owns" a police car.

    Duplication is prevented server side:
      * checkoutVehicle() is an atomic UPDATE ... WHERE stored = 1, so two people
        pressing the button at the same moment cannot both get the car
      * the vehicle entity is created by the server, not the client
      * a plate already present in the world blocks a second spawn
]]

Garage = {}

--- Spawn-type mapping for CreateVehicleServerSetter.
local SPAWN_TYPES = {
    car        = 'automobile',
    automobile = 'automobile',
    bike       = 'bike',
    boat       = 'boat',
    sea        = 'boat',
    heli       = 'heli',
    air        = 'heli',
    plane      = 'plane',
    trailer    = 'trailer',
    submarine  = 'submarine',
}

local PLATE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

--- Generate a plate that is not in use anywhere.
---@param prefix string?
---@return string
function Garage.generatePlate(prefix)
    prefix = (prefix or ''):upper():sub(1, 3)

    for _ = 1, 25 do
        local plate = prefix
        for _ = 1, 8 - #prefix do
            local index = math.random(#PLATE_CHARS)
            plate = plate .. PLATE_CHARS:sub(index, index)
        end

        if not Db.plateExists(plate) then return plate end
    end

    -- Extremely unlikely, but never hand back a colliding plate.
    return ('%s%d'):format(prefix, math.random(100000, 999999))
end

--- Is a vehicle with this plate already streamed in somewhere?
---@param plate string
---@return number? entity
function Garage.findByPlate(plate)
    plate = plate:gsub('%s+', ''):upper()

    for _, vehicle in ipairs(GetAllVehicles()) do
        local state = Entity(vehicle).state
        if state and state.renzuPlate and state.renzuPlate:gsub('%s+', ''):upper() == plate then
            return vehicle
        end
    end
    return nil
end

--- Delete a vehicle that is out in the world, if we can find it.
---@param plate string
local function despawnByPlate(plate)
    local vehicle = Garage.findByPlate(plate)
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Keys
-- ─────────────────────────────────────────────────────────────────────────────

---@param src number
---@param plate string
---@param label string
local function giveKey(src, plate, label)
    if not Config.Garage.giveKeys then return end

    -- Preferred path: let the garage resource own the key format.
    local resource = Config.resolveResource(Config.GarageResource)
    if resource then
        local ok = pcall(function()
            return exports[resource]:GiveVehicleKey(plate, src)
        end)
        if ok then return end
    end

    -- Fallback: hand out the key item ourselves with matching metadata.
    if not Config.KeyItem then return end
    Bridge.addItem(src, Config.KeyItem, 1, {
        plate       = plate,
        label       = ('%s Key'):format(label or plate),
        description = ('Vehicle key for %s'):format(plate),
    })
end

---@param src number
---@param plate string
local function removeKey(src, plate)
    if not Config.Garage.removeKeysOnStore or not Config.KeyItem then return end

    plate = plate:gsub('%s+', ''):upper()

    local slots = exports.ox_inventory:Search(src, 'slots', Config.KeyItem)
    if not slots then return end

    for _, slot in pairs(slots) do
        local keyPlate = slot.metadata and slot.metadata.plate
        if keyPlate and keyPlate:gsub('%s+', ''):upper() == plate then
            exports.ox_inventory:RemoveItem(src, Config.KeyItem, slot.count or 1, slot.metadata, slot.slot)
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Garage list
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:getGarage', function(source)
    local allowed, job, feature = Access.feature(source, 'garage')
    if not job or not feature then return nil end

    if not allowed then
        Bridge.notify(source, 'error', 'Job Garage', 'Your rank does not have access to the garage.')
        return nil
    end
    if not Access.nearby(source, feature.coord, 12.0) then return nil end

    local citizenid = Bridge.getIdentifier(source)
    local rows = Db.getJobVehicles(job.name, 'main')

    local vehicles = {}
    for i = 1, #rows do
        local row = rows[i]
        vehicles[#vehicles + 1] = {
            plate    = row.plate,
            model    = row.model,
            label    = row.label or row.model,
            stored   = row.stored == 1,
            takenBy  = row.taken_by,
            mine     = row.taken_by ~= nil and row.taken_by == citizenid,
            image    = ('%s%s.png'):format(Config.VehicleImageUrl, (row.model or ''):lower()),
        }
    end

    table.sort(vehicles, function(a, b)
        if a.stored ~= b.stored then return a.stored end
        return a.label < b.label
    end)

    return {
        label       = feature.label,
        vehicles    = vehicles,
        recoveryFee = Config.Garage.recoveryFee,
        canRecover  = Config.Garage.recoveryFee >= 0,
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Take a vehicle out
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:takeVehicle', function(source, plate)
    local allowed, job, feature = Access.feature(source, 'garage')
    if not job or not feature or not allowed then return false end
    if not Access.nearby(source, feature.coord, 12.0) then
        Bridge.notify(source, 'error', 'Job Garage', 'Step up to the garage first.')
        return false
    end

    local row = Db.getJobVehicle(plate)
    if not row or row.job ~= job.name then
        lib.print.warn(('%s tried to take plate "%s" which is not a %s vehicle'):format(source, tostring(plate), job.name))
        return false
    end

    if row.stored ~= 1 then
        Bridge.notify(source, 'error', 'Job Garage', 'That vehicle is already out. Use "recover" to bring it back.')
        return false
    end

    -- Someone may already be driving it even though the row says stored.
    if Garage.findByPlate(plate) then
        Bridge.notify(source, 'error', 'Job Garage', 'That vehicle is already out on the streets.')
        return false
    end

    local citizenid = Bridge.getIdentifier(source)
    if not citizenid then return false end

    -- Atomic claim. If this returns false somebody beat us to it by milliseconds.
    if not Db.checkoutVehicle(plate, citizenid) then
        Bridge.notify(source, 'error', 'Job Garage', 'Somebody just signed that vehicle out.')
        return false
    end

    local spawn = feature.spawn
    local spawnType = SPAWN_TYPES[feature.vehicleType or 'car'] or 'automobile'
    local model = joaat(row.model)

    local vehicle = CreateVehicleServerSetter(model, spawnType, spawn.x, spawn.y, spawn.z, spawn.w or 0.0)

    local attempts = 0
    while not DoesEntityExist(vehicle) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not DoesEntityExist(vehicle) then
        Db.storeVehicle(plate, json.decode(row.props or '{}') or {})
        Bridge.notify(source, 'error', 'Job Garage', 'The vehicle could not be spawned. Nothing was signed out.')
        lib.print.error(('failed to spawn %s (%s) for job %s'):format(row.model, plate, job.name))
        return false
    end

    -- State bag lets us find this exact vehicle again without scanning plates
    -- from the client, and survives the client applying properties.
    local state = Entity(vehicle).state
    state:set('renzuPlate', plate, true)
    state:set('renzuJob', job.name, true)

    -- The plate itself is written by the client: SetVehicleNumberPlateText is a
    -- client native and does not exist in the server runtime.
    local props = json.decode(row.props or '{}') or {}
    props.plate = plate

    giveKey(source, plate, row.label or row.model)

    Bridge.notify(source, 'success', 'Job Garage',
        ('%s signed out. Plate %s.'):format(row.label or row.model, plate))

    Logs.send({
        feature = 'garage', webhook = feature.webhook,
        title = 'Vehicle signed out', severity = 'info', source = source,
        fields = {
            { name = 'Vehicle', value = row.label or row.model, inline = true },
            { name = 'Plate',   value = plate, inline = true },
            { name = 'Company', value = job.label, inline = true },
        },
    })

    return {
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        props = props,
        plate = plate,
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Hand a vehicle back in
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:storeVehicle', function(source, netId, props)
    local allowed, job, feature = Access.feature(source, 'garage')
    if not job or not feature or not allowed then return false end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then
        Bridge.notify(source, 'error', 'Job Garage', 'That vehicle no longer exists.')
        return false
    end

    -- Must be handed in at the garage, not from across the map.
    if #(GetEntityCoords(vehicle) - vec3(feature.coord.x, feature.coord.y, feature.coord.z)) > 25.0 then
        Bridge.notify(source, 'error', 'Job Garage', 'Bring the vehicle to the garage first.')
        return false
    end

    local plate = Entity(vehicle).state.renzuPlate
        or (type(props) == 'table' and props.plate)

    if not plate then
        Bridge.notify(source, 'error', 'Job Garage', 'This is not a company vehicle.')
        return false
    end
    plate = plate:gsub('%s+$', '')

    local row = Db.getJobVehicle(plate)
    if not row then
        Bridge.notify(source, 'error', 'Job Garage', 'This vehicle is not registered to any company.')
        return false
    end
    if row.job ~= job.name then
        Bridge.notify(source, 'error', 'Job Garage', ('That vehicle belongs to %s.'):format(row.job))
        return false
    end

    -- Either you took it out yourself, or your rank is high enough to hand in
    -- anything the company owns.
    local citizenid = Bridge.getIdentifier(source)
    local mine = row.taken_by == nil or row.taken_by == citizenid
    if not mine and job.grade < (Config.Garage.storeAnyoneGrade or 0) then
        Bridge.notify(source, 'error', 'Job Garage', 'Only the employee who signed this vehicle out can return it.')
        return false
    end

    if not Db.storeVehicle(plate, type(props) == 'table' and props or {}) then
        Bridge.notify(source, 'error', 'Job Garage', 'Storing the vehicle failed.')
        return false
    end

    DeleteEntity(vehicle)
    removeKey(source, plate)

    Bridge.notify(source, 'success', 'Job Garage', ('%s is back in the garage.'):format(row.label or row.model))

    Logs.send({
        feature = 'garage', webhook = feature.webhook,
        title = 'Vehicle returned', severity = 'success', source = source,
        fields = {
            { name = 'Vehicle', value = row.label or row.model, inline = true },
            { name = 'Plate',   value = plate, inline = true },
        },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Recover a vehicle that is out but nowhere to be found
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:recoverVehicle', function(source, plate)
    local allowed, job, feature = Access.feature(source, 'garage')
    if not job or not feature or not allowed then return false end
    if not Access.nearby(source, feature.coord, 12.0) then return false end

    local row = Db.getJobVehicle(plate)
    if not row or row.job ~= job.name then return false end
    if row.stored == 1 then
        Bridge.notify(source, 'inform', 'Job Garage', 'That vehicle is already in the garage.')
        return false
    end

    local fee = Config.Garage.recoveryFee or 0
    if fee > 0 then
        if Config.Garage.recoveryFromJobFunds then
            if not Db.removeBalance(job.name, 'money', fee) then
                Bridge.notify(source, 'error', 'Job Garage', ('The company treasury cannot cover the $%s recovery fee.'):format(fee))
                return false
            end
            Accounts.broadcast(job.name)
        else
            if Bridge.getMoney(source, Config.CashAccount) < fee then
                Bridge.notify(source, 'error', 'Job Garage', ('Recovery costs $%s and you do not have it on you.'):format(fee))
                return false
            end
            if not Bridge.removeMoney(source, Config.CashAccount, fee, 'renzu_jobs:recovery') then return false end
        end
    end

    despawnByPlate(plate)

    if not Db.storeVehicle(plate, json.decode(row.props or '{}') or {}) then
        -- Refund, nothing was recovered.
        if fee > 0 then
            if Config.Garage.recoveryFromJobFunds then
                Db.addBalance(job.name, 'money', fee)
                Accounts.broadcast(job.name)
            else
                Bridge.addMoney(source, Config.CashAccount, fee, 'renzu_jobs:recovery-refund')
            end
        end
        return false
    end

    Bridge.notify(source, 'success', 'Job Garage',
        fee > 0 and ('%s recovered for $%s.'):format(row.label or row.model, fee)
                 or ('%s recovered.'):format(row.label or row.model))

    Logs.money('garage', source, 'Vehicle recovered', fee, {
        { name = 'Plate', value = plate, inline = true },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Fleet management from the boss menu
-- ─────────────────────────────────────────────────────────────────────────────

--- Force every vehicle of the company back into the garage.
lib.callback.register('renzu_jobs:recallFleet', function(source)
    local allowed, job = Access.has(source, 'withdraw') -- treat as a management action
    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Job Garage', 'Your rank cannot recall the fleet.')
        return false
    end

    local rows = Db.getJobVehicles(job.name, 'main')
    for i = 1, #rows do
        if rows[i].stored == 0 then despawnByPlate(rows[i].plate) end
    end

    local affected = Db.returnAllVehicles(job.name)
    Bridge.notify(source, 'success', 'Job Garage', ('Recalled %d vehicle(s) to the garage.'):format(affected))

    Logs.send({
        feature = 'garage', title = 'Fleet recalled', severity = 'warning', source = source,
        fields = { { name = 'Vehicles', value = tostring(affected), inline = true } },
    })
    return true
end)

exports('generatePlate', Garage.generatePlate)

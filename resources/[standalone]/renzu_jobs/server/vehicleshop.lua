---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job vehicle shop

    Buys a vehicle FOR THE COMPANY using company money. The new vehicle is
    written into renzu_jobs_vehicles and shows up in the job garage. It is never
    added to player_vehicles, so no employee personally owns it.
]]

--- One purchase at a time per player.
local busy = {}

lib.callback.register('renzu_jobs:getVehicleShop', function(source)
    local allowed, job, feature = Access.feature(source, 'vehicleshop')
    if not job or not feature then return nil end

    if not allowed then
        Bridge.notify(source, 'error', 'Fleet Purchase', 'Your rank cannot buy company vehicles.')
        return nil
    end
    if not Access.nearby(source, feature.coord, 10.0) then return nil end

    local vehicles = {}
    for _, vehicle in ipairs(feature.vehicles or {}) do
        if (vehicle.grade or 0) <= job.grade then
            vehicles[#vehicles + 1] = {
                model = vehicle.model,
                label = vehicle.label or vehicle.model,
                price = tonumber(vehicle.price) or 0,
                image = ('%s%s.png'):format(Config.VehicleImageUrl, vehicle.model:lower()),
            }
        end
    end

    return {
        label    = feature.label,
        vehicles = vehicles,
        balance  = Db.getBalance(job.name, 'money'),
    }
end)

lib.callback.register('renzu_jobs:buyVehicle', function(source, model)
    if busy[source] then return false end

    local allowed, job, feature = Access.feature(source, 'vehicleshop')
    if not job or not feature or not allowed then return false end
    if not Access.nearby(source, feature.coord, 10.0) then
        Bridge.notify(source, 'error', 'Fleet Purchase', 'Step up to the dealer first.')
        return false
    end

    local entry
    for _, vehicle in ipairs(feature.vehicles or {}) do
        if vehicle.model == model then entry = vehicle break end
    end
    if not entry then
        lib.print.warn(('%s tried to buy "%s" which is not in the %s fleet list'):format(source, tostring(model), job.name))
        return false
    end
    if (entry.grade or 0) > job.grade then
        Bridge.notify(source, 'error', 'Fleet Purchase', 'Your rank cannot buy that vehicle.')
        return false
    end

    local price = tonumber(entry.price) or 0
    busy[source] = true

    local ok = (function()
        if price > 0 and not Db.removeBalance(job.name, 'money', price) then
            Bridge.notify(source, 'error', 'Fleet Purchase',
                ('The company treasury has $%s, this vehicle costs $%s.'):format(Db.getBalance(job.name, 'money'), price))
            return false
        end

        local plate = Garage.generatePlate(job.name:upper():sub(1, 2))

        local created = Db.createJobVehicle({
            plate  = plate,
            job    = job.name,
            garage = 'main',
            model  = entry.model,
            label  = entry.label or entry.model,
            props  = { model = joaat(entry.model), plate = plate },
        })

        if not created then
            if price > 0 then Db.addBalance(job.name, 'money', price) end
            Bridge.notify(source, 'error', 'Fleet Purchase', 'Registering the vehicle failed. The company was not charged.')
            return false
        end

        Accounts.broadcast(job.name)

        Bridge.notify(source, 'success', 'Fleet Purchase',
            ('%s bought for $%s. Plate %s, waiting in the job garage.'):format(entry.label or entry.model, price, plate))

        -- Tell everyone on shift, it is company money after all.
        local buyer = Bridge.getFullName(Bridge.getPlayer(source))
        for _, src in ipairs(Bridge.getPlayers()) do
            if src ~= source then
                local other = Bridge.getJob(src)
                if other and other.name == job.name then
                    Bridge.notify(src, 'inform', job.label,
                        ('%s bought a %s for the company.'):format(buyer, entry.label or entry.model))
                end
            end
        end

        Logs.send({
            feature = 'vehicleshop', webhook = feature.webhook,
            title = 'Fleet vehicle purchased', severity = 'success', source = source,
            fields = {
                { name = 'Vehicle', value = entry.label or entry.model, inline = true },
                { name = 'Plate',   value = plate, inline = true },
                { name = 'Price',   value = ('$%s'):format(price), inline = true },
                { name = 'Company', value = job.label, inline = true },
            },
        })
        return true
    end)()

    busy[source] = nil
    return ok
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)

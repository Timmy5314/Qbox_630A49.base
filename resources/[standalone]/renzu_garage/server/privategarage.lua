-- SERVER PRIVATE GARAGE

--- ps-housing integration.
--- House garages are driven by ps-housing through exports.renzu_garage:GarageHousing_Adv,
--- which uses the garage id format "garage_<property_id>". Those events carry no ownership
--- check of their own, so verify access against ps-housing here.
--- Any other garage id (normal private garages, jobs, ...) passes straight through.
---@param src number
---@param garageId string|nil
---@return boolean
function PsHousingCanAccess(src, garageId)
    if not garageId then return true end

    local propertyId = tostring(garageId):match('^garage_(%d+)$')
    if not propertyId then return true end

    if not GetResourceState('ps-housing'):find('start') then return true end

    local ok, allowed = pcall(function()
        return exports['ps-housing']:IsOwner(src, propertyId)
    end)

    if not ok then
        print(('[renzu_garage] ps-housing access check failed for %s: %s'):format(garageId, allowed))
        return false
    end

    return allowed == true
end

--- ps-housing integration.
--- A house garage copies its parking spots from the shell config the first time a car is
--- parked, and never looks at them again. So when ps-housing hands us a different shell
--- (the property changed size), the stored coordinates no longer match the interior the
--- player is teleported into and their cars end up somewhere else entirely.
--- This re-seats the cars onto the new shell's spots. Whatever no longer fits is moved to
--- a public garage. A car is removed from the JSON list in the same pass it is written to
--- player_vehicles, so it can never exist in both places.
---@param garageId string "garage_<property_id>"
---@param shellName string key of private_garage
---@param row table the private_garage row, modified in place
---@return table row
function PsHousingReseat(garageId, shellName, row)
    if not row or not garageId or not tostring(garageId):match('^garage_%d+$') then return row end

    local shell = private_garage[shellName]
    local park = shell and shell.park
    if not park or #park == 0 then return row end

    local list = json.decode(row.vehicles or '[]') or {}

    -- Same amount of spots AND the same first spot means the layout did not change.
    -- Compared with a tolerance on purpose: the stored coords went through json and back,
    -- exact equality against the vector4 in the config is not guaranteed. Getting this
    -- wrong would re-seat on every single garage entry and shuffle the cars around.
    local function sameSpot(a, b)
        if not a or not b then return false end
        return math.abs((a.x or 0) - (b.x or 0)) < 0.01
            and math.abs((a.y or 0) - (b.y or 0)) < 0.01
    end

    if #list == #park and sameSpot(list[1] and list[1].coord, park[1].coord) then
        return row
    end

    local parked = {}
    for i = 1, #list do
        local slot = list[i]
        if slot.taken and slot.vehicle then
            parked[#parked + 1] = slot.vehicle
        end
    end

    local seats = deepcopy(park)
    for i = 1, #seats do
        seats[i].taken = false
        seats[i].vehicle = nil

        if parked[i] then
            seats[i].taken = true
            seats[i].vehicle = parked[i]
        end
    end

    -- overflow: does not fit in the smaller garage, park it publicly instead
    for i = #seats + 1, #parked do
        local prop = parked[i]
        local plate = prop and prop.plate and string.gsub(tostring(prop.plate):upper(), '^%s*(.-)%s*$', '%1')

        if plate then
            MysqlGarage(Config.Mysql, 'execute',
                'UPDATE ' .. vehicletable .. ' SET `' .. stored .. '` = @state, ' .. garage__id .. ' = @garage WHERE TRIM(UPPER(plate)) = @plate', {
                    ['@state'] = 1,
                    ['@garage'] = Config.PsHousingOverflowGarage or 'A',
                    ['@plate'] = plate,
                })

            print(('[renzu_garage] %s no longer fits in %s, moved to public garage %s')
                :format(plate, garageId, Config.PsHousingOverflowGarage or 'A'))
        end
    end

    row.vehicles = json.encode(seats)

    MysqlGarage(Config.Mysql, 'execute', 'UPDATE private_garage SET `vehicles` = @vehicles WHERE garage = @garage', {
        ['@vehicles'] = row.vehicles,
        ['@garage'] = garageId,
    })

    return row
end

local garageshare = {}
function DoiOwnthis(xPlayer,id)
    local owned = false
    for k,v in pairs(current_routing) do
        if tonumber(v) == tonumber(xPlayer.source) and GetPlayerRoutingBucket(xPlayer.source) == tonumber(k) then
            owned = true
            success = true
        end
    end
    return owned
end

RegisterServerCallBack_('renzu_garage:getinventory', function (source, cb, id, share)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local share = share
    local id = id
    if not PsHousingCanAccess(source, id) then return cb({}) end
    if share and not DoiOwnthis(xPlayer,id) then
        identifier = share.owner
    end
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT inventory FROM private_garage WHERE identifier = @identifier and garage = @garage', {
        ['@identifier'] = identifier,
        ['@garage'] = id
    })
    local inventory = {}
    if json.decode(result[1].inventory) then
        inventory = json.decode(result[1].inventory) or {}
    end
    id = nil
    share = nil
    cb(inventory)
end)

RegisterServerCallBack_('renzu_garage:itemavailable', function (source, cb, id, item, share)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local share = share
    local id = id
    local item = item
    if share and not DoiOwnthis(xPlayer,id) then
        identifier = share.owner
    end
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT inventory FROM private_garage WHERE identifier = @identifier and garage = @garage', {
        ['@identifier'] = identifier,
        ['@garage'] = id
    })
    local inventory = false
    if json.decode(result[1].inventory) then
        inventory = json.decode(result[1].inventory) or {}
        if inventory[item] ~= nil and inventory[item] > 0 then
            inventory[item] = inventory[item] - 1
            MysqlGarage(Config.Mysql,'execute','UPDATE private_garage SET inventory = @inventory WHERE garage = @garage and identifier = @identifier', {
                ['@inventory'] = json.encode(inventory),
                ['@garage'] = id,
                ['@identifier'] = identifier,
            })
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
    share = nil
    id = nil
    item = nil
end)

RegisterServerEvent('renzu_garage:storemod')
AddEventHandler('renzu_garage:storemod', function(id,mod,lvl,newprop,share,save,savepartsonly)
    local newprop = newprop
	local savepartsonly = savepartsonly
    local src = source  
    local xPlayer = GetPlayerFromId(src)
    local id = id
    local identifier = xPlayer.identifier
	local save = save
	local share = share
    if share and not DoiOwnthis(xPlayer,id) then
        identifier = share.owner
    end
    local success = false
    local vehicles = nil
    if not savepartsonly then
        local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE identifier = @identifier and garage = @garage', {
            ['@identifier'] = identifier,
            ['@garage'] = id
        })
        vehicles = json.decode(result[1].vehicles)
        success = false
        for k,v in pairs(vehicles) do
            if v.vehicle == nil then v.taken = false end
            local prop = v.vehicle
            if v.taken and newprop.plate == prop.plate then
                vehicles[k].vehicle = newprop
                success = true
                break
            end
        end
    end
    if success and not savepartsonly or savepartsonly then
        if not savepartsonly then
            MysqlGarage(Config.Mysql,'execute','UPDATE '..vehicletable..' SET `'..stored..'` = @stored, '..garage__id..' = @garage_id, '..vehiclemod..' = @vehicle WHERE TRIM(UPPER(plate)) = @plate', {
                ['@vehicle'] = json.encode(newprop),
                ['@garage_id'] = 'private',
                ['@plate'] = string.gsub(newprop.plate:upper(), '^%s*(.-)%s*$', '%1'),
                ['@stored'] = 0
            })
        end
        local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT inventory FROM private_garage WHERE identifier = @identifier and garage = @garage', {
            ['@identifier'] = identifier,
            ['@garage'] = id
        })
        local inventory = json.decode(result[1].inventory) or {}
        if not save then
            local modname = mod.name..'-'..lvl
            if inventory[modname] == nil then
                inventory[modname] = 1
            else
                inventory[modname] = inventory[modname] + 1
            end
        end
        if savepartsonly then
            MysqlGarage(Config.Mysql,'execute','UPDATE private_garage SET inventory = @inventory WHERE garage = @garage and identifier = @identifier', {
                ['@inventory'] = json.encode(inventory),
                ['@garage'] = id,
                ['@identifier'] = identifier,
            })
        else
            MysqlGarage(Config.Mysql,'execute','UPDATE private_garage SET `vehicles` = @vehicles, inventory = @inventory WHERE garage = @garage and identifier = @identifier', {
                ['@vehicles'] = json.encode(vehicles),
                ['@inventory'] = json.encode(inventory),
                ['@garage'] = id,
                ['@identifier'] = identifier,
            })
        end
        newprop = {}
        share = false
        save = nil
        savepartsonly = nil
        Config.Notify( 'success', Message[63]..' ('..mod.name..')',xPlayer)
    else
        Config.Notify( 'error', Message[64],xPlayer)
    end
end)

RegisterServerEvent('renzu_garage:buygarage')
AddEventHandler('renzu_garage:buygarage', function(id,v)
    local src = source  
    local xPlayer = GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local cost = 10000
    -- Elke garage (huis-garage EN genummerde private garage) mag maar aan 1 speler
    -- toebehoren. Voorheen werd dit alleen gecontroleerd voor 'garage_' (huis) ids,
    -- waardoor twee spelers dezelfde genummerde private garage konden "kopen" en
    -- vervolgens in elkaars garage terecht konden komen / conflicteerden.
    local available = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE garage = @garage', {
        ['@garage'] = id
    })
    local canbuy = not (available and available[1])
    if canbuy then
        if type(v) ~= 'table' then
            local shellcost = 10000
            local houseid = string.gsub(id, 'garage_', '')
            for k,v in pairs(HousingGarages) do
                if tonumber(houseid) == tonumber(k) then
                    shellcost = HouseGarageCost[v.shell] or 10000
                end
            end
            cost = shellcost
        else
            cost = v.cost
        end
        if xPlayer.getMoney() >= cost then
            MysqlGarage(Config.Mysql,'execute','INSERT INTO private_garage (identifier, garage, vehicles) VALUES (@identifier, @garage, @vehicles)', {
                ['@identifier']   = xPlayer.identifier,
                ['@garage']   = id,
                ['@vehicles'] = '[]'
            })
            xPlayer.removeMoney(tonumber(cost))
            Config.Notify('success', ''..Message[65]..' '..id..'',xPlayer)
            local housingtemp = GlobalState.HousingGarages or {}
            housingtemp[id] = xPlayer.identifier
            GlobalState.HousingGarages = housingtemp
        else
            Config.Notify( 'error', Message[66],xPlayer)
        end
    else
        Config.Notify('error', Message[31], xPlayer) -- "You dont owned this garage" -- deze garage is al door iemand anders gekocht
    end
end)

RegisterServerEvent('renzu_garage:storeprivate')
AddEventHandler('renzu_garage:storeprivate', function(id,v,prop, shell)
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end
    if not PsHousingCanAccess(src, id) then return end
    local identifier = xPlayer.identifier
    if not private_garage[id] then
        local shelltype = shell or 'small'
        local houseid = string.gsub(id, 'garage_', '')
        for k,v in pairs(HousingGarages) do
            if tonumber(houseid) == tonumber(k) then
                shelltype = shell or v.shell
            end
        end
        housegarage[id] = {shell = shelltype, id = id, housing = housing}
        local owned = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE garage = @garage', {
            ['@garage'] = id
        })
        if owned[1] and owned[1].identifier then
            identifier = owned[1].identifier
        end
    end
    local id = housegarage[id] ~= nil and housegarage[id].id or id
    local prop = prop
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM '..vehicletable..' WHERE '..owner..' = @owner and TRIM(UPPER(plate)) = @plate LIMIT 1', {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = string.gsub(prop.plate:upper(), '^%s*(.-)%s*$', '%1')
    })
    if not Config.Allowednotowned and result[1] == nil then Config.Notify( 'error', Message[69], xPlayer) return end
    local garage = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE identifier = @identifier and garage = @garage', {
        ['@identifier'] = identifier,
        ['@garage'] = id
    })
    -- ps-housing: parking straight from the car never goes through gotohousegarage, so the
    -- row can still be missing (indexing garage[1] below would error) and the spots can
    -- still belong to the property's previous size.
    if not garage[1] then
        -- The select above filters on identifier too, so a row can exist under a different
        -- one. Check by garage id before inserting or we would create a second row for the
        -- same garage and end up writing to both.
        local existing = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE garage = @garage', {
            ['@garage'] = id
        })

        if existing[1] then
            garage = existing
        else
            MysqlGarage(Config.Mysql,'execute','INSERT INTO private_garage (identifier, garage, vehicles) VALUES (@identifier, @garage, @vehicles)', {
                ['@identifier'] = identifier,
                ['@garage'] = id,
                ['@vehicles'] = '[]'
            })
            garage = {[1] = {identifier = identifier, garage = id, vehicles = '[]'}}
        end
    end
    garage[1] = PsHousingReseat(id, housegarage[id] and housegarage[id].shell or shell, garage[1])
    local vehiclesgarage = {}
    vehiclesgarage = json.decode(garage[1].vehicles) or {}
    local success = false
    local newgarage = true
    for k,v in pairs(vehiclesgarage) do
        newgarage = false
        if v.vehicle == nil then v.taken = false end
        if not v.taken then
            v.taken = true
            v.vehicle = prop
            success = true
            break
        end
    end
    if newgarage then
        local shell = id
        if housegarage[id] ~= nil then
            shell = housegarage[id].shell
        end
        -- a typo in the shell name (ps-housing Config.RenzuGarageShell for example) would
        -- otherwise be a hard "index a nil value" error here
        if not private_garage[shell] or not private_garage[shell].park then
            print(('[renzu_garage] unknown garage shell "%s" for %s, falling back to small')
                :format(tostring(shell), tostring(id)))
            shell = 'small'
        end
        local pgarage = deepcopy(private_garage[shell].park)
        for k,v in pairs(pgarage) do
            vehiclesgarage[k] = v
            if v.vehicle == nil then vehiclesgarage[k].taken = false end
            if not vehiclesgarage[k].taken and k == #pgarage then
                vehiclesgarage[k].taken = true
                vehiclesgarage[k].vehicle = prop
                break
            end
        end
    end
    if success and not newgarage or newgarage then
        MysqlGarage(Config.Mysql,'execute','UPDATE '..vehicletable..' SET `'..stored..'` = @stored, '..garage__id..' = @garage_id, '..vehiclemod..' = @vehicle WHERE TRIM(UPPER(plate)) = @plate', {
            ['@vehicle'] = json.encode(prop),
            ['@garage_id'] = 'private',
            ['@plate'] = string.gsub(prop.plate:upper(), '^%s*(.-)%s*$', '%1'),
            ['@stored'] = 0
        })
        MysqlGarage(Config.Mysql,'execute','UPDATE private_garage SET `vehicles` = @vehicles WHERE garage = @garage and identifier = @identifier', {
            ['@vehicles'] = json.encode(vehiclesgarage),
            ['@garage'] = id,
            ['@identifier'] = identifier,
        })
        Config.Notify( 'success', Message[67], xPlayer)
        vehiclesgarage = {}
        pgarage = {}
        -- if Config.Ox_Inventory then
        --     DoesPlayerHaveKey(prop.plate,src,true)
        -- end
    else
        Config.Notify( 'error', Message[68], xPlayer)
    end
end)

RegisterServerEvent('renzu_garage:gotohousegarage')
AddEventHandler('renzu_garage:gotohousegarage', function(id,var)
    id,v,share,houseid,housing = table.unpack(var)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    if not xPlayer then return end
    if not PsHousingCanAccess(source, houseid) then return end
    local identifier = xPlayer.identifier
    if share and not DoiOwnthis(xPlayer,houseid) then
        identifier = v.owner or xPlayer.identifier
    end
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE garage = @garage', {
        ['@garage'] = houseid
    })
    if not result[1] then
        MysqlGarage(Config.Mysql,'execute','INSERT INTO private_garage (identifier, garage, vehicles) VALUES (@identifier, @garage, @vehicles)', {
            ['@identifier']   = xPlayer.identifier,
            ['@garage']   = houseid,
            ['@vehicles'] = '[]'
        })
        result = {[1] = {identifier = xPlayer.identifier, garage = houseid, vehicles = '[]'}}
    end
    -- ps-housing: property may have changed size, move the cars to the new spots
    result[1] = PsHousingReseat(houseid, id, result[1])
    local routing = 0
    local haveworld = false
    for k,v in pairs(current_routing) do
        if tonumber(v) == tonumber(source) then
            haveworld = true
            routing = tonumber(k)
        end
    end
    if not haveworld then
        default_routing[source] = GetPlayerRoutingBucket(source)
    end
    if not share and not haveworld then
        for route = default_routing[source]+100, 65000 do
            routing = route
            if current_routing[route] == nil then
                break
            end
        end
    elseif share and v and v.route then
        routing = v.route
    end
    garagehouseid = houseid:gsub('garage_','')
    SetPlayerRoutingBucket(source,tonumber(garagehouseid) or routing)
    SetRoutingBucketPopulationEnabled(tonumber(garagehouseid) or routing,false)
    if not share and not haveworld then
        current_routing[routing] = source
    end
    Wait(1000)
    lastgarage[source] = houseid
	local vehicle_ = {}
	for k,v in pairs(json.decode(result[1] and result[1].vehicles or '[]')) do
		vehicle_[k] = v
	end
    housegarage[houseid] = {shell = id, id = houseid, housing = housing}
    TriggerClientEvent('renzu_garage:ingarage',source, result[1],private_garage[id],houseid, vehicle_,housegarage[houseid])
    result = {}
    vehicle_ = {}
end)
safecoords = setmetatable({},{})
RegisterServerEvent('renzu_garage:gotogarage')
AddEventHandler('renzu_garage:gotogarage', function(id,v,share)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    safecoords[identifier] = GetEntityCoords(GetPlayerPed(source))
    if share and not DoiOwnthis(xPlayer,id) then
        identifier = v.owner or xPlayer.identifier
    end
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE `identifier` = @identifier and garage = @garage', {
        ['@identifier'] = identifier,
        ['@garage'] = id
    })
    local routing = 0
    local haveworld = false
    for k,v in pairs(current_routing) do
        if tonumber(v) == tonumber(source) then
            haveworld = true
            routing = tonumber(k)
        end
    end
    if not haveworld then
        default_routing[source] = GetPlayerRoutingBucket(source)
    end
    if not share and not haveworld then
        for route = default_routing[source]+100, 65000 do
            routing = route
            if current_routing[route] == nil then
                break
            end
        end
    elseif share and v and v.route and not DoiOwnthis(xPlayer,id) then
        routing = v.route or routing
    end
    SetPlayerRoutingBucket(source,routing)
    SetRoutingBucketPopulationEnabled(routing,false)
    if not share and not haveworld then
        current_routing[routing] = source
    end
    Wait(1000)
    lastgarage[source] = id
	local vehicle_ = {}
    local private_cars = result and result[1] and result[1].vehicles or '[]'
    local cars = json.decode(private_cars) or {}
	for k,v in pairs(cars) do
		vehicle_[k] = v
	end
    TriggerClientEvent('renzu_garage:ingarage',source, result[1],private_garage[id],id, vehicle_)

end)

RegisterServerEvent('renzu_garage:exitgarage')
AddEventHandler('renzu_garage:exitgarage', function(t,prop,id,choose,share)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    local id = id
    local identifier = xPlayer.identifier
    if not private_garage[id] then -- housing garages
        local owned = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE garage = @garage', {
            ['@garage'] = id
        })
        if owned[1] and owned[1].identifier then
            identifier = owned[1].identifier
        end
    end
    if not choose then
        --SetEntityCoords(GetPlayerPed(source),table.buycoords.x,table.buycoords.y,table.buycoords.z,true)
        TriggerClientEvent('renzu_garage:exitgarage',source, t, true)
        Wait(1000)
        SetPlayerRoutingBucket(source,default_routing[source])
        --current_routing[default_routing[source]] = nil
    else
        -- ps-housing: taking a vehicle out needs access, leaving on foot (the branch
        -- above) stays open so nobody can get stuck if the property is sold or deleted
        if not PsHousingCanAccess(source, id) then return end
        if share and not DoiOwnthis(xPlayer,id) then
            identifier = share.owner
        end
        local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE identifier = @identifier and garage = @garage', {
            ['@identifier'] = identifier,
            ['@garage'] = id
        })
        local vehicles = json.decode(result[1].vehicles)
        local success = false
        for k,v in pairs(vehicles) do
            if v.vehicle == nil then v.taken = false end
            if v.taken and v.vehicle ~= nil and string.gsub(v.vehicle.plate:upper(), '^%s*(.-)%s*$', '%1') == string.gsub(prop.plate:upper(), '^%s*(.-)%s*$', '%1') then
                vehicles[k].taken = false
                vehicles[k].vehicle = nil
                success = true
                break
            end
        end
        local result = MysqlGarage(Config.Mysql,'execute','UPDATE '..vehicletable..' SET `'..stored..'` = @stored, '..garage__id..' = @garage_id, '..vehiclemod..' = @vehicle WHERE TRIM(UPPER(plate)) = @plate', {
            ['@vehicle'] = json.encode(prop),
            ['@garage_id'] = 'A',
            ['@plate'] = string.gsub(prop.plate:upper(), '^%s*(.-)%s*$', '%1'),
            ['@stored'] = 0
        })
        local result = MysqlGarage(Config.Mysql,'execute','UPDATE private_garage SET `vehicles` = @vehicles WHERE garage = @garage and identifier = @identifier', {
            ['@vehicles'] = json.encode(vehicles),
            ['@garage'] = id,
            ['@identifier'] = identifier,
        })
        Config.Notify('success', Message[70], xPlayer)
        --SetEntityCoords(GetPlayerPed(source),table.buycoords.x,table.buycoords.y,table.buycoords.z,true)
        TriggerClientEvent('renzu_garage:exitgarage',source, t, true)
        Wait(500)
        --current_routing[default_routing[source]] = nil
        TriggerClientEvent('renzu_garage:choose',source,prop,t)
		Wait(2000)
		SetPlayerRoutingBucket(source,default_routing[source])
        TriggerClientEvent('renzu_garage:syncstate',-1,string.gsub(prop.plate:upper(), '^%s*(.-)%s*$', '%1'),source)
        -- if Config.Ox_Inventory then
        --     GiveVehicleKey(prop.plate,source)
        -- end
        t = {}
        vehicles = {}
        result = {}
    end
    lastgarage[source] = nil
    safecoords[source] = nil
end)

exports('GetPrivateGaragefromPlate', function(source,plate)
    local xPlayer = GetPlayerFromId(source)
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    })
    for k,v2 in pairs(result) do
        local vehicles = json.decode(v2?.vehicles or '[]') or {}
        for k,v in pairs(vehicles) do
            if v.vehicle == nil then v.taken = false end
            if v.taken and v.vehicle ~= nil and string.gsub(v.vehicle.plate, '^%s*(.-)%s*$', '%1') == string.gsub(plate:upper(), '^%s*(.-)%s*$', '%1') then
                return v2.garage
            end
        end
    end
    return false
end)

exports('RemoveVehicleFromPrivate', function(source,plate,id)
    local xPlayer = GetPlayerFromId(source)
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM private_garage WHERE identifier = @identifier and garage = @garage', {
        ['@identifier'] = xPlayer.identifier,
        ['@garage'] = id
    })
    local vehicles = json.decode(result[1].vehicles)
    for k,v in pairs(vehicles) do
        if v.vehicle == nil then v.taken = false end
        if v.taken and v.vehicle ~= nil and string.gsub(v.vehicle.plate, '^%s*(.-)%s*$', '%1') == string.gsub(plate:upper(), '^%s*(.-)%s*$', '%1') then
            v.taken = false
            v.vehicle = nil
            break
        end
    end
    local result = MysqlGarage(Config.Mysql,'execute','UPDATE '..vehicletable..' SET `'..stored..'` = @stored, '..garage__id..' = @garage_id WHERE TRIM(UPPER(plate)) = @plate', {
        ['@garage_id'] = 'A',
        ['@plate'] = string.gsub(plate:upper(), '^%s*(.-)%s*$', '%1'),
        ['@stored'] = 0
    })
    local result = MysqlGarage(Config.Mysql,'execute','UPDATE private_garage SET `vehicles` = @vehicles WHERE garage = @garage and identifier = @identifier', {
        ['@vehicles'] = json.encode(vehicles),
        ['@garage'] = id,
        ['@identifier'] = xPlayer.identifier,
    })
end)

RegisterServerCallBack_('renzu_garage:isgarageowned', function (source, cb, id, v)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    local id = id
    local result = MysqlGarage(Config.Mysql,'fetchAll','SELECT identifier FROM private_garage WHERE identifier = @identifier and garage = @garage', {
        ['@identifier'] = xPlayer.identifier,
        ['@garage'] = id
    })
    local garage_share = {}
    if result and result[1] ~= nil then
        if garageshare[tonumber(source)] ~= nil then
            garage_share = garageshare[tonumber(source)]
        end
        cb(true,garage_share)
    else
        if garageshare[tonumber(source)] ~= nil then
            garage_share = garageshare[tonumber(source)]
        end
        cb(false,garage_share)
    end
end)

RegisterCommand(Config.GiveAccessCommand, function(source, args, rawCommand)
    local source = source
    local xPlayer = GetPlayerFromId(source)
    if lastgarage[source] then
        for k,v in pairs(current_routing) do
            if v == source then
                garageshare[tonumber(args[1])] = {}
                garageshare[tonumber(args[1])].owner = xPlayer.identifier
                garageshare[tonumber(args[1])].route = k
                garageshare[tonumber(args[1])].garage = lastgarage[source]
            end
        end
    else
        Config.Notify('warning', Message[71], xPlayer)
    end
end)
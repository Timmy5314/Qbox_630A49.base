QBCore = nil
vehicletable = 'player_vehicles'
vehiclemod = 'mods'
owner = 'license'
stored = 'state'
garage_id = 'garage'
type_ = 'vehicle'
Initialized()
local vehicles = {}
local shops = {}
Citizen.CreateThread(function()
    for k,v in pairs(VehicleShop) do
        local list, foundshop = GetVehiclesFromShop(k or 'pdm')
        if not shops[k] then shops[k] = {} end
        --TriggerClientEvent('table',-1,Owned_Vehicle)
        if v.shop then
            shops[k].list = v.shop
            shops[k].type = v.type
        else
            shops[k].list = list
            shops[k].type = v.type
        end
    end
    GlobalState.VehicleShops = shops
end)

function GetVehiclesFromShop(shop)
    local vehicles = {}
    local found = false
    for k,v in pairs(Config.Vehicles) do
        if v.shop == shop then
            vehicles[k] = v
            found = true
        end
    end
    return vehicles, found
end

local NumberCharset = {}
for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

function Deleteveh(plate,src)
    local plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
    if plate and type(plate) == 'string' then
        CustomsSQL(Config.Mysql,'execute','DELETE FROM '..vehicletable..' WHERE TRIM(UPPER(plate)) = @plate',{['@plate'] = plate})
    else
        print('error not string - Delete Vehicle')
    end
end



RegisterServerEvent('renzu_vehicleshop:sellvehicle')
AddEventHandler('renzu_vehicleshop:sellvehicle', function()
    local source = source
    local xPlayer = GetPlayerFromId(source)
    local price = 1000
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(source))
    local plate = GetVehicleNumberPlateText(vehicle)
    r = CustomsSQL(Config.Mysql,'fetchAll','SELECT * FROM '..vehicletable..' WHERE UPPER(TRIM(plate)) = @plate and '..owner..' = @'..owner..'',{['@plate'] = string.gsub(plate:upper(), '^%s*(.-)%s*$', '%1'), ['@'..owner..''] = xPlayer.identifier})
    if r and #r > 0 then
        local model = json.decode(r[1][vehiclemod]).model
        if model == GetEntityModel(vehicle) then
            result = Config.Vehicles
                if result then
                    for k,v in pairs(result) do
                        if model == GetHashKey(v.model) then
                            price = v.price * (Config.RefundPercent * 0.01)
                        end
                    end
                    Deleteveh(plate,xPlayer.source)
                    xPlayer.addMoney(price)
                    xPlayer.showNotification('Vehicle has been Sold for ^g '..price..'',1,0,110)
                    TriggerClientEvent('sellvehiclecallback',xPlayer.source)
                end
        else
            print("EXPLOIT")
            xPlayer.showNotification('Are you really sure this is the vehicle?',1,0,110)
        end
    else
        xPlayer.showNotification('You dont owned this vehicle',1,0,110)
    end
end)

local Charset = {}
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end
local temp = {}
CreateThread(function()
    Wait(1000)
    local vehicles = CustomsSQL(Config.Mysql,'fetchAll','SELECT * FROM '..vehicletable..'',{})
    for k,v in pairs(vehicles) do
        if v.plate ~= nil then
            temp[v.plate] = v
        end
    end
end)

RegisterServerCallBack_('renzu_vehicleshop:GenPlate', function (source, cb, prefix)
    cb(GenPlate(prefix))
end)

RegisterServerCallBack_('renzu_vehicleshop:buyvehicle', function (source, cb, model, props, payment, job, type, garage, notregister)
    local source = source
	local xPlayer = GetPlayerFromId(source)
    if not xPlayer then return cb(false) end -- speler niet (meer) geladen: altijd antwoorden
    if not job and type == 'car' and not notregister then
        cb(Buy({[1] = Config.Vehicles[model]},xPlayer,model, props, payment, job, type , garage))
    elseif notregister then
        cb(Buy(true,xPlayer,model, props, payment or 'cash', job or 'civ', type or 'car' , garage or 'A' or false, notregister))
    else
        local found = nil
        for k,v in pairs(VehicleShop) do
            if v.shop and (v.job == job or type ~= 'car') then
                for _,sv in pairs(v.shop) do
                    if sv.model:lower() == model:lower() then
                        found = {[1] = {model = sv.model, price = sv.price, stock = 100}}
                        break
                    end
                end
            end
            if found then break end -- stop de buitenste loop, anders kan cb() dubbel worden aangeroepen
        end
        if found then
            cb(Buy(found,xPlayer,model, props, payment, job, type, garage))
        else
            -- ALTIJD antwoorden, anders blijft de client oneindig op de callback wachten
            print(('^1[renzu_vehicleshop] model %s niet gevonden in een shop voor job=%s type=%s^7'):format(tostring(model), tostring(job), tostring(type)))
            xPlayer.showNotification('Vehicle does not Exist')
            cb(false)
        end
    end
end)

local temp = {}

-- Zoekt de autoriteitsprijs voor een model server-side op. De showroom-displaycars
-- gebruiken `value`, de shop-lijsten `price`, Config.Vehicles is op model gekeyed.
-- Nodig omdat de notregister-koopflow anders de client-meegestuurde prijs vertrouwde.
function getServerPrice(model)
    if not model then return nil end
    local m = tostring(model):lower()
    for _, shop in pairs(VehicleShop) do
        if type(shop) == 'table' then
            if shop.displaycars then
                for _, dc in pairs(shop.displaycars) do
                    if dc.model and tostring(dc.model):lower() == m then
                        return dc.value or dc.price
                    end
                end
            end
            if shop.shop then
                for _, sv in pairs(shop.shop) do
                    if sv.model and tostring(sv.model):lower() == m then
                        return sv.price or sv.value
                    end
                end
            end
        end
    end
    local cfg = Config.Vehicles and Config.Vehicles[model]
    if cfg then return cfg.price or cfg.value end
    return nil
end

function Buy(result,xPlayer,model, props, payment, job, type, garage, notregister)
    fetchdone = false
    bool = false
    model = model
    if result then
        local price = nil
        local stock = nil
        if not notregister then
            model = result[1].model
            price = result[1].price
        else
            model = model
            -- NOOIT notregister.value vertrouwen: dat is een client-argument. Een
            -- cheater riep buyvehicle rechtstreeks aan met notregister={value=0} en
            -- een willekeurig model -> gratis auto van elk model. Prijs komt nu
            -- server-side uit de config (showroom displaycars / shop-lijsten).
            price = getServerPrice(model)
        end
        price = tonumber(price)
        if not price or price < 0 then
            xPlayer.showNotification('Vehicle does not Exist',1,0,110)
            fetchdone = true
            return false
        end
        local payment = payment
        local money = false
        if payment == 'cash' then
            money = xPlayer.getMoney() >= price
        else
            money = xPlayer.getAccount('bank').money >= price
        end
        stock = 999      
        if money then
            if payment == 'cash' then
                xPlayer.removeMoney(tonumber(price))
            elseif payment == 'bank' then
                xPlayer.removeAccountMoney('bank', tonumber(price))
            else
                xPlayer.removeMoney(tonumber(price))
            end
            stock = stock - 1
            local data = json.encode(props)
            -- de garage leest de `type` kolom en verwacht car/boat/air; 'carshop' is een shop-type, geen voertuigtype
            local vehtype = type
            if vehtype == 'carshop' or vehtype == nil then vehtype = 'car' end
            local query = 'INSERT INTO '..vehicletable..' ('..owner..', plate, '..vehiclemod..', `'..stored..'`, job, '..garage_id..', `'..type_..'`, `hash`, `citizenid`, `type`) VALUES (@'..owner..', @plate, @props, @'..stored..', @job, @'..garage_id..', @vehicle, @hash, @citizenid, @vehtype)'
            local var = {
                ['@'..owner..'']   = xPlayer.identifier,
                ['@plate']   = props.plate:upper(),
                ['@props'] = data,
                ['@'..stored..''] = 1,
                ['@job'] = job,
                ['@'..garage_id..''] = garage or 'pillboxgarage',
                ['@vehicle'] = model,
                ['@hash'] = tostring(GetHashKey(model)),
                ['@citizenid'] = xPlayer.citizenid,
                ['@vehtype'] = vehtype,
            }
            CustomsSQL(Config.Mysql,'execute',query,var)
            fetchdone = true
            bool = true
            Config.Carkeys(props.plate,xPlayer.source)
            temp[props.plate] = true
            --TriggerClientEvent('mycarkeys:setowned',xPlayer.source,props.plate) -- sample
        else
            print("NOT ENOUGH MONEY")
            xPlayer.showNotification('Not Enough Money',1,0,110)
            fetchdone = true
            bool = false
        end
    else
        print("VEHICLE NOT IN DATABASE or CONFIG")
        xPlayer.showNotification('Vehicle does not Exist',1,0,110)
        fetchdone = true
        bool = false
    end
    while not fetchdone do Wait(0) end
    return bool
end

local Charset = {}
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end
CreateThread(function()
    Wait(1000)
    local vehicles = CustomsSQL(Config.Mysql,'fetchAll','SELECT * FROM '..vehicletable..'',{})
    for k,v in pairs(vehicles) do
        if v.plate ~= nil then
            temp[v.plate] = v
        end
    end
end)

function GetRandomLetter(length)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function GenPlate(prefix)
    local plate = LetterRand()..' '..NumRand()
    if prefix then plate = prefix..' '..NumRand() end
    if temp[plate] == nil then
        return plate
    end
    Wait(1)
    return GenPlate(prefix)
end

function LetterRand()
    local emptyString = {}
    local randomLetter;
    while (#emptyString < 6) do
        randomLetter = GetRandomLetter(1)
        table.insert(emptyString,randomLetter)
        Wait(0)
    end
    local a = string.format("%s%s%s", table.unpack(emptyString)):upper()  -- "2 words"
    return a
end

function NumRand()
    local emptyString = {}
    local randomLetter;
    while (#emptyString < 6) do
        randomLetter = GetRandomNumber(1)
        table.insert(emptyString,randomLetter)
        Wait(0)
    end
    local a = string.format("%i%i%i", table.unpack(emptyString))  -- "2 words"
    return a
end

function GetRandomNumber(length)
	math.randomseed(os.time()+math.random(19999,999999))
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

exports('GenPlate', function(plate)
    return GenPlate(plate)
end)

exports('VehiclesList', function()
    return Config.Vehicles
end)

exports('Deleteveh', function(plate)
    return Deleteveh(plate)
end)
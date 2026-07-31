-- SERVER IMPOUND

RegisterServerEvent('renzu_garage:GetVehiclesTableImpound')
AddEventHandler('renzu_garage:GetVehiclesTableImpound', function()
    local src = source  
    local xPlayer = GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    --local Impounds = MySQL.Sync.fetchAll('SELECT * FROM '..vehicletable..' WHERE impound = 1', {})
    local q = 'SELECT * FROM '..vehicletable..' WHERE `'..stored..'` = 0 OR impound = 1'
    if not ImpoundedLostVehicle then
        q = 'SELECT * FROM '..vehicletable..' WHERE impound = 1'
    end
    local Impounds = MysqlGarage(Config.Mysql,'fetchAll',q, {})
    TriggerClientEvent("renzu_garage:receive_vehicles", src , LuaBoolShitLogic(Impounds),vehicles)
end)

-- Server-side ingang om een voertuig in beslag te nemen vanuit een andere resource.
--
-- renzu_garage kende alleen de client-callback `renzu_garage:changestate`. Een
-- ander script kon daardoor niets in beslag nemen. ND_Police verwijderde de auto
-- dus alleen uit de wereld, terwijl zijn eigen bevestigingstekst belooft dat de
-- eigenaar hem bij de impound kan ophalen. Die auto was gewoon weg.
--
---@param plate string kenteken
---@param data? table {garage?: string, fine?: number, reason?: string, impounder?: string, duration?: number}
---@return boolean ok
---@return string? reason 'invalid_plate' | 'unknown_garage' | 'not_owned'
local function ImpoundVehicle(plate, data)
    if type(plate) ~= 'string' then return false, 'invalid_plate' end

    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1'):upper()
    if plate == '' then return false, 'invalid_plate' end

    data = data or {}

    local garageId = data.garage or impoundcoord[1].garage
    local knownGarage = false
    for i = 1, #impoundcoord do
        if impoundcoord[i].garage == garageId then
            knownGarage = true
            break
        end
    end
    if not knownGarage then return false, 'unknown_garage' end

    local result = MysqlGarage(Config.Mysql, 'fetchAll',
        'SELECT `' .. owner .. '` FROM ' .. vehicletable .. ' WHERE TRIM(UPPER(plate)) = @plate LIMIT 1', {
            ['@plate'] = plate
        })

    -- Geen rij = geen player-owned voertuig. De beller mag hem dan gewoon
    -- verwijderen; er valt niets op te halen.
    if not result or not result[1] then return false, 'not_owned' end

    MysqlGarage(Config.Mysql, 'execute',
        'UPDATE ' .. vehicletable .. ' SET `' .. stored .. '` = 1, ' .. garage__id ..
        ' = @garage_id, impound = 1, isparked = 0 WHERE TRIM(UPPER(plate)) = @plate', {
            ['@garage_id'] = garageId,
            ['@plate'] = plate
        })

    local res = MysqlGarage(Config.Mysql, 'fetchAll', 'SELECT * FROM impound_garage WHERE garage = @garage', {
        ['@garage'] = garageId
    })

    local impound_data = res and res[1] and json.decode(res[1].data or '[]') or {}

    impound_data[plate] = {
        reason = data.reason or 'no reason',
        fine = tonumber(data.fine) or ImpoundPayment,
        duration = tonumber(data.duration) or DefaultDuration,
        impounder = data.impounder or 'LSPD',
        date = os.time()
    }

    MysqlGarage(Config.Mysql, 'execute', 'UPDATE impound_garage SET `data` = @data WHERE garage = @garage', {
        ['@data'] = json.encode(impound_data),
        ['@garage'] = garageId
    })

    impound_G[garageId] = impound_data

    -- Anders spawnt het voertuig na een restart gewoon weer op straat.
    if GlobalState.VehiclePersistData and GlobalState.VehiclePersistData[plate] then
        SetVehiclePersistent({props = {plate = plate}}, true, true)
    end

    -- Alleen relevant met Config.Ox_Inventory (het renzu `keys`-item). Deze
    -- server staat op false: sleutels lopen via qbx_vehiclekeys en die werkt op
    -- entity handles, dus het verwijderen van het voertuig is daar genoeg.
    -- Staat de eigenaar offline dan houdt hij zijn sleutel-item; ophalen bij de
    -- impound geeft geen tweede (GiveVehicleKey controleert eerst op bezit).
    if Config.Ox_Inventory and Config.RemoveKeys then
        local ownerPlayer = GetPlayerFromIdentifier(result[1][owner])
        if ownerPlayer and ownerPlayer.source then
            DoesPlayerHaveKey(plate, ownerPlayer.source, true)
        end
    end

    return true
end

exports('ImpoundVehicle', ImpoundVehicle)

RegisterServerCallBack_('renzu_garage:getowner',function(source, cb, identifier, plate, garage)
    local data = MysqlGarage(Config.Mysql,'fetchAll','SELECT * FROM '..users..' WHERE '..identifier_..' = @identifier', {
		['@identifier'] = identifier
	})
    if impound_G[garage][plate] == nil then
        -- create data from default
        impound_G[garage][plate] = {fine = ImpoundPayment, reason = 'no specified', impounder = 'Renzuzu', duration = -1, date = os.time()}
    end
    local res = impound_G[garage][plate] ~= nil and impound_G[garage][plate] or {}
    if data[1] then
        local playerinfo = json.decode(data[1].charinfo)
        local job = json.decode(data[1].job).label
        data[1] = {
            firstname = playerinfo.firstname,
            lastname = playerinfo.lastname,
            phone_number = playerinfo.phone,
            job = job
        }
    end
	cb(data,res)
end)
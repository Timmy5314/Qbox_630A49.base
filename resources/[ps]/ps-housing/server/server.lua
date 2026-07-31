if not Framework.isStarted('ox_doorlock') then
    return error('ox_doorlock must be started before ps-housing.')
end

local dbloaded = false

MySQL.ready(function()
    -- pcall omdat een ontbrekende tabel een exception geeft, geen nil. Zonder
    -- dit sterft de resource hier bij startup en werd de melding hieronder
    -- nooit bereikt - wat er van buitenaf uitzag als "ps-housing crasht de
    -- server" terwijl het gewoon een niet-geimporteerde SQL was.
    local ok, result = pcall(MySQL.query.await, 'SELECT * FROM properties')

    if not ok or not result then
        lib.print.error(
            'ps-housing kon de tabel `properties` niet lezen. Draai eerst ' ..
            '"README - INSTALL INSTRUCTIONS/QBOX/properties.sql". ' ..
            'Zie ook install/README.md in de server root.'
        )
        if not ok then lib.print.error(result) end
        dbloaded = true
        return
    end

    for i = 1, #result do
        local v = result[i]
        local id = tostring(v.property_id)
        local has_access = json.decode(v.has_access) or {}
        local owner = v.owner_citizenid

        PropertiesTable[id] = Property:new({
            property_id = id,
            owner = owner,
            street = v.street,
            region = v.region,
            description = v.description,
            has_access = has_access,
            -- these columns are nullable, and nil here crashes the client on `next()`
            extra_imgs = json.decode(v.extra_imgs) or {},
            furnitures = json.decode(v.furnitures) or {},
            for_sale = v.for_sale,
            price = v.price,
            shell = v.shell,
            apartment = v.apartment,
            door_data = json.decode(v.door_data) or {},
            garage_data = json.decode(v.garage_data) or {},
            zone_data = v.zone_data,
        })
    end

    dbloaded = true
end)

local function waitForDb()
    while not dbloaded do Wait(50) end
end

lib.callback.register('ps-housing:server:requestProperties', function()
    waitForDb()
    return PropertiesTable
end)

function RegisterProperty(propertyData, preventEnter, source)
    propertyData.owner = propertyData.owner or nil
    propertyData.has_access = propertyData.has_access or {}
    propertyData.extra_imgs = propertyData.extra_imgs or {}
    propertyData.furnitures = propertyData.furnitures or {}
    propertyData.door_data = propertyData.door_data or {}
    propertyData.garage_data = propertyData.garage_data or {}
    propertyData.zone_data = propertyData.zone_data or {}

    local cols = "(owner_citizenid, street, region, description, has_access, extra_imgs, furnitures, for_sale, price, shell, apartment, door_data, garage_data, zone_data)"
    local vals = "(@owner_citizenid, @street, @region, @description, @has_access, @extra_imgs, @furnitures, @for_sale, @price, @shell, @apartment, @door_data, @garage_data, @zone_data)"

    local id = MySQL.insert.await("INSERT INTO properties " .. cols .. " VALUES " .. vals, {
        ["@owner_citizenid"] = propertyData.owner or nil,
        ["@street"] = propertyData.street,
        ["@region"] = propertyData.region,
        ["@description"] = propertyData.description,
        ["@has_access"] = json.encode(propertyData.has_access),
        ["@extra_imgs"] = json.encode(propertyData.extra_imgs),
        ["@furnitures"] = json.encode(propertyData.furnitures),
        ["@for_sale"] = propertyData.for_sale ~= nil and propertyData.for_sale or 1,
        ["@price"] = propertyData.price or 0,
        ["@shell"] = propertyData.shell or '',
        ["@apartment"] = propertyData.apartment,
        ["@door_data"] = json.encode(propertyData.shell == 'mlo' and { count = #propertyData.door_data } or propertyData.door_data),
        ["@garage_data"] = json.encode(propertyData.garage_data),
        ["@zone_data"] = json.encode(propertyData.zone_data),
    })

    if source and propertyData.shell == 'mlo' then
        -- ox_doorlock exposes createDoor server side, so no client round trip and no
        -- `command.doorlock` ace permission needed on the realtor placing the door.
        for index = 1, #propertyData.door_data do
            local door = propertyData.door_data[index]
            local isDouble = door[1] ~= nil
            local name = ('ps_mloproperty%s_%s'):format(id, index)

            local payload = isDouble and { doors = door, name = name, maxDistance = 2.5 } or door
            payload.name = name

            local ok, err = pcall(function()
                exports.ox_doorlock:createDoor(payload)
            end)

            if not ok then
                lib.print.error(('Error creating doorlock %s: %s'):format(name, err))
            end
        end

        propertyData.door_data = { count = #propertyData.door_data }
        Wait(1000)
    end

    id = tostring(id)
    propertyData.property_id = id
    PropertiesTable[id] = Property:new(propertyData)

    TriggerClientEvent("ps-housing:client:addProperty", -1, propertyData)

    if propertyData.apartment and not preventEnter then
        local player = Framework.GetPlayerByCitizenId(propertyData.owner)
        if not player then
            lib.print.error(('Player not found for citizen ID %s'):format(propertyData.owner))
            return id
        end

        local src = player.PlayerData.source
        local property = Property.Get(id)
        if not property then
            lib.print.error(('Property not found for ID %s'):format(id))
            return id
        end

        property:PlayerEnter(src)

        Wait(1000)

        if not Framework.HasSkin(propertyData.owner) then
            Debug(('Player %s is creating a new character'):format(propertyData.owner))
            Framework.CreateFirstCharacter(src)
        end

        Framework.Notify(src, "Open radial menu for furniture menu and place down your stash and clothing locker.", "info")
    end

    return id
end

local function getMainDoor(propertyId, doorIndex, isShell)
    -- ps_mloproperty is prefix, property_id is the property's unique id,
    -- doorIndex is the door number because an mlo can have multiple doors
    if isShell then
        local property = Property.Get(propertyId)
        if not property then return end
        return {
            coords = property.propertyData.door_data
        }
    end

    return exports.ox_doorlock:getDoorFromName(('ps_mloproperty%s_%s'):format(propertyId, doorIndex))
end
exports('getMainDoor', getMainDoor)

lib.callback.register("ps-housing:cb:getMainMloDoor", function(_, propertyId, doorIndex)
    return getMainDoor(propertyId, doorIndex)
end)

exports('registerProperty', RegisterProperty) -- triggered by realtor job
AddEventHandler("ps-housing:server:registerProperty", RegisterProperty)

---@param citizenid string
---@return table? apartment row
local function getOwnedApartment(citizenid)
    if not citizenid then return end

    local result = MySQL.single.await(
        'SELECT * FROM properties WHERE owner_citizenid = ? AND apartment IS NOT NULL AND apartment <> ""',
        { citizenid }
    )

    return result
end
exports('getOwnedApartment', getOwnedApartment)

lib.callback.register("ps-housing:cb:GetOwnedApartment", function(source, cid)
    return getOwnedApartment(cid or Framework.GetCitizenId(source))
end)

---Used to stop players from deleting a storage unit that still holds items
lib.callback.register("ps-housing:cb:inventoryHasItems", function(_, stash)
    local items = exports.ox_inventory:GetInventoryItems(stash)
    return items ~= nil and next(items) ~= nil
end)

AddEventHandler("ps-housing:server:updateProperty", function(type, property_id, data)
    local property = Property.Get(property_id)
    if not property then return end

    property[type](property, data)
end)

AddEventHandler("onResourceStart", function(resourceName) -- Used for when the resource is restarted while in game
    if GetCurrentResourceName() ~= resourceName then return end

    waitForDb()
    TriggerClientEvent('ps-housing:client:initialiseProperties', -1, PropertiesTable)
end)

---@param src number
---@param aptLabel string key of Config.Apartments
---@return string? property_id
local function createStartingApartment(src, aptLabel)
    if not Config.StartingApartment then return end

    local apartment = Config.Apartments[aptLabel]
    if not apartment then return end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return end

    -- Guard against the event being spammed to farm apartments
    local owned = getOwnedApartment(citizenid)
    if owned then
        Debug(('%s already owns an apartment, skipping creation'):format(citizenid))
        return tostring(owned.property_id)
    end

    local playerData = Framework.GetPlayerData(src)
    local charName = ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)

    Debug(("Creating new apartment for %s in %s"):format(GetPlayerName(src), apartment.label))
    Framework.SendLog(("Creating new apartment for %s in %s"):format(GetPlayerName(src), apartment.label))

    return RegisterProperty({
        owner = citizenid,
        description = ("This is %s's apartment in %s"):format(charName, apartment.label),
        for_sale = 0,
        shell = apartment.shell,
        apartment = apartment.label,
    })
end

RegisterNetEvent("ps-housing:server:createNewApartment", function(aptLabel)
    createStartingApartment(source, aptLabel)
end)

-- Used by the apartment picker so the client knows when it can fade back in
lib.callback.register("ps-housing:cb:createApartment", function(source, aptLabel)
    return createStartingApartment(source, aptLabel)
end)

lib.callback.register("ps-housing:cb:needsStartingApartment", function(source)
    if not Config.StartingApartment then return false end

    local citizenid = Framework.GetCitizenId(source)
    if not citizenid then return false end

    return getOwnedApartment(citizenid) == nil
end)

-- Fires after the player has spawned. Handles two things:
--   1. no starting apartment -> open the character creator if they have no ped yet
--   2. logged out inside a property -> put them straight back into it
RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
    local src = source
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return end

    if not Config.StartingApartment and Config.ShowCustomizerWhenNoStartingApartment and not Framework.HasSkin(citizenid) then
        Debug(('Player %s is creating a new character'):format(citizenid))
        Framework.CreateFirstCharacter(src)
    end

    if not Config.ReturnToPropertyOnLogin then return end

    local propertyId = Framework.GetInsideProperty(src)
    if not propertyId then return end

    waitForDb()

    local property = Property.Get(propertyId)
    if not property or not property:CheckForAccess(citizenid) then
        Framework.SetInsideProperty(src, nil)
        return
    end

    property:PlayerEnter(src)
end)

AddEventHandler("ps-housing:server:addTenantToApartment", function(data)
    local apartment = data.apartment
    local targetSrc = tonumber(data.targetSrc)
    local realtorSrc = data.realtorSrc
    local targetCitizenid = Framework.GetCitizenId(targetSrc, realtorSrc)
    if not targetCitizenid then return end

    -- id of current apartment so we can change it
    local property_id = nil

    for _, v in pairs(PropertiesTable) do
        local propertyData = v.propertyData
        if propertyData.owner == targetCitizenid then
            if propertyData.apartment == apartment then
                Framework.Notify(targetSrc, "You are already in this apartment", "error")
                Framework.Notify(realtorSrc, "This person is already in this apartment", "error")
                return
            elseif propertyData.apartment and #propertyData.apartment > 1 then
                property_id = propertyData.property_id
                break
            end
        end
    end

    local targetPlayer = Framework.GetPlayerData(targetSrc)
    if not targetPlayer then return end

    local targetName = ('%s %s'):format(targetPlayer.charinfo.firstname, targetPlayer.charinfo.lastname)

    if property_id == nil then
        local newApartment = Config.Apartments[apartment]
        if not newApartment then return end

        Debug(("Creating new apartment for %s in %s"):format(GetPlayerName(targetSrc), newApartment.label))
        Framework.SendLog(("Creating new apartment for %s in %s"):format(GetPlayerName(targetSrc), newApartment.label))

        Framework.Notify(targetSrc, "Your apartment is now at " .. apartment, "success")
        Framework.Notify(realtorSrc, "You have added " .. targetName .. " to apartment " .. apartment, "success")

        RegisterProperty({
            owner = targetCitizenid,
            description = ("This is %s's apartment in %s"):format(targetName, newApartment.label),
            for_sale = 0,
            shell = newApartment.shell,
            apartment = newApartment.label,
        }, true)

        return
    end

    local property = Property.Get(property_id)
    if not property then return end

    property:UpdateApartment(data)

    Framework.Notify(targetSrc, "Your apartment is now at " .. apartment, "success")
    Framework.Notify(realtorSrc, "You have added " .. targetName .. " to apartment " .. apartment, "success")
end)

---Owner or key holder? Used by other resources (renzu_garage for example) as a
---permission check, so it stays silent instead of notifying the player.
exports('IsOwner', function(src, property_id)
    local property = Property.Get(property_id)
    if not property then return false end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return false end

    return property:CheckForAccess(citizenid) and true or false
end)

-- Kept as globals: other resources and community edits call into these.
function GetCitizenid(targetSrc, callerSrc)
    return Framework.GetCitizenId(targetSrc, callerSrc)
end

function GetCharName(src)
    return Framework.GetCharName(src)
end

function GetPlayerData(src)
    return Framework.GetPlayerData(src)
end

function GetPlayer(src)
    return Framework.GetPlayer(src)
end

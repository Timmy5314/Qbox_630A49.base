-- Property interiors sit at fixed, far-away coordinates, so entering one reads
-- as a teleport to the anti-cheat's movement check. Announce it instead.
-- Safe to call when los_anticheat is not running.
---@param src number
function ExpectTeleport(src)
    if GetResourceState("los_anticheat") ~= "started" then return end
    exports.los_anticheat:ExpectTeleport(src)
end

Property = {
    property_id = nil,
    propertyData = nil,
    playersInside = nil,   -- src
    playersInGarden = nil,   -- src
    playersDoorbell = nil, -- src

    raiding = false,
}
Property.__index = Property

function Property:new(propertyData)
    local self = setmetatable({}, Property)

    self.property_id = tostring(propertyData.property_id)
    self.propertyData = propertyData

    self.playersInside = {}
    self.playersInGarden = {}
    self.playersDoorbell = {}

    local shell = Config.Shells[propertyData.shell]

    if not shell then
        -- A renamed or removed shell should not take the whole property list down with it
        lib.print.warn(('Property %s uses unknown shell "%s"'):format(self.property_id, tostring(propertyData.shell)))
        return self
    end

    local stashName = ("property_%s"):format(propertyData.property_id)
    local label = ('Property: %s #%s'):format(propertyData.street or propertyData.apartment or 'Unknown', propertyData.property_id)

    for k = 1, #propertyData.furnitures do
        local v = propertyData.furnitures[k]
        if v.type == 'storage' then
            Framework.RegisterInventory(k == 1 and stashName or stashName .. v.id, label, shell.stash)
        end
    end

    return self
end

function Property:PlayerEnter(src)
    local _src = tostring(src)
    local isMlo = self.propertyData.shell == 'mlo'
    local isIpl = self.propertyData.apartment and Config.Apartments[self.propertyData.apartment].interior

    self.playersInside[_src] = true

    if not isMlo and Framework.isStarted('qb-weathersync') then
        TriggerClientEvent('qb-weathersync:client:DisableSync', src)
    end

    Debug(('%s entered property %s'):format(src, self.property_id))
    TriggerClientEvent('ps-housing:client:enterProperty', src, self.property_id, isMlo, self.propertyData)

    if next(self.playersDoorbell) then
        TriggerClientEvent("ps-housing:client:updateDoorbellPool", src, self.property_id, self.playersDoorbell)
        if self.playersDoorbell[_src] then
            self.playersDoorbell[_src] = nil
        end
    end

    local citizenid = Framework.GetCitizenId(src)

    if citizenid and self:CheckForAccess(citizenid) then
        Framework.SetInsideProperty(src, self.property_id)
    end

    if not isMlo or isIpl then
        local bucket = tonumber(self.property_id) -- because the property_id is a string
        Framework.SetPlayerBucket(src, bucket)
    end
end

function Property:PlayerLeave(src)
    local _src = tostring(src)
    self.playersInside[_src] = nil

    if Framework.isStarted('qb-weathersync') then
        TriggerClientEvent('qb-weathersync:client:EnableSync', src)
    end

    local citizenid = Framework.GetCitizenId(src)

    if citizenid and self:CheckForAccess(citizenid) then
        Framework.SetInsideProperty(src, nil)
    end

    Framework.SetPlayerBucket(src, 0)
end

function Property:CheckForAccess(citizenid)
    if self.propertyData.owner == citizenid then return true end
    return lib.table.contains(self.propertyData.has_access, citizenid)
end

function Property:AddToDoorbellPoolTemp(src)
    local _src = tostring(src)

    local name = GetCharName(src)

    self.playersDoorbell[_src] = {
        src = src,
        name = name
    }

    for src, _ in pairs(self.playersInside) do
        local targetSrc = tonumber(src)

        Framework.Notify(targetSrc, "Someone is at the door.", "info")
        TriggerClientEvent("ps-housing:client:updateDoorbellPool", targetSrc, self.property_id, self.playersDoorbell)
    end

    Framework.Notify(src, "You rang the doorbell. Just wait...", "info")

    SetTimeout(10000, function()
        if self.playersDoorbell[_src] then
            self.playersDoorbell[_src] = nil
            Framework.Notify(src, "No one answered the door.", "error")
        end

        for src, _ in pairs(self.playersInside) do
            local targetSrc = tonumber(src)

            TriggerClientEvent("ps-housing:client:updateDoorbellPool", targetSrc, self.property_id, self.playersDoorbell)
        end
    end)
end

function Property:RemoveFromDoorbellPool(src)
    local _src = tostring(src)

    if self.playersDoorbell[_src] then
        self.playersDoorbell[_src] = nil
    end

    for src, _ in pairs(self.playersInside) do
        local targetSrc = tonumber(src)

        TriggerClientEvent("ps-housing:client:updateDoorbellPool", targetSrc, self.property_id, self.playersDoorbell)
    end
end

function Property:StartRaid()
    self.raiding = true

    for src, _ in pairs(self.playersInside) do
        local targetSrc = tonumber(src)
        Framework.Notify(targetSrc, "This Property is being Raided.", "error")
    end

    SetTimeout(Config.RaidTimer * 60000, function()
        self.raiding = false
    end)
end

function Property:UpdateFurnitures(furnitures, isGarden)
    local newfurnitures = {}

    for i = 1, #furnitures do
        newfurnitures[i] = {
            id = furnitures[i].id,
            label = furnitures[i].label,
            object = furnitures[i].object,
            position = furnitures[i].position,
            rotation = furnitures[i].rotation,
            type = furnitures[i].type
        }
    end

    self.propertyData.furnitures = newfurnitures

    MySQL.update("UPDATE properties SET furnitures = @furnitures WHERE property_id = @property_id", {
        ["@furnitures"] = json.encode(newfurnitures),
        ["@property_id"] = self.property_id
    })

    if isGarden then
        for src, _ in pairs(self.playersInGarden) do
            TriggerClientEvent("ps-housing:client:updateFurniture", tonumber(src), self.property_id, furnitures, true)
        end
        return
    end

    for src, _ in pairs(self.playersInside) do
        TriggerClientEvent("ps-housing:client:updateFurniture", tonumber(src), self.property_id, furnitures)
    end
end

function Property:UpdateDescription(data)
    local description = data.description
    local realtorSrc = data.realtorSrc

    if self.propertyData.description == description then return end

    self.propertyData.description = description

    MySQL.update("UPDATE properties SET description = @description WHERE property_id = @property_id", {
        ["@description"] = description,
        ["@property_id"] = self.property_id
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateDescription", self.property_id, description)

    Framework.SendLog("**Changed Description** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed Description of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

function Property:UpdatePrice(data)
    local price = data.price
    local realtorSrc = data.realtorSrc

    if self.propertyData.price == price then return end

    self.propertyData.price = price

    MySQL.update("UPDATE properties SET price = @price WHERE property_id = @property_id", {
        ["@price"] = price,
        ["@property_id"] = self.property_id
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdatePrice", self.property_id, price)

    Framework.SendLog("**Changed Price** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed Price of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

function Property:UpdateForSale(data)
    local forsale = data.forsale
    local realtorSrc = data.realtorSrc

    self.propertyData.for_sale = forsale

    MySQL.update("UPDATE properties SET for_sale = @for_sale WHERE property_id = @property_id", {
        ["@for_sale"] = forsale and 1 or 0,
        ["@property_id"] = self.property_id
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateForSale", self.property_id, forsale)

    Framework.SendLog("**Changed For Sale** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed For Sale of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

function Property:UpdateShell(data)
    local shell = data.shell
    local realtorSrc = data.realtorSrc

    if self.propertyData.shell == shell then return end

    self.propertyData.shell = shell

    MySQL.update("UPDATE properties SET shell = @shell WHERE property_id = @property_id", {
        ["@shell"] = shell,
        ["@property_id"] = self.property_id
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateShell", self.property_id, shell)

    Framework.SendLog("**Changed Shell** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed Shell of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

---Runs fn(door, doorlock) for every doorlock belonging to this mlo property.
---@param fn fun(door: table, doorlock: table)
function Property:forEachMloDoor(fn)
    if self.propertyData.shell ~= 'mlo' then return end

    local doorlock = exports.ox_doorlock
    local count = self.propertyData.door_data and self.propertyData.door_data.count or 0

    for i = 1, count do
        local door = doorlock:getDoorFromName(('ps_mloproperty%s_%s'):format(self.property_id, i))
        if door then fn(door, doorlock) end
    end
end

function Property:addMloDoorsAccess(citizenid)
    self:forEachMloDoor(function(door, doorlock)
        local characters = door.characters or {}
        characters[#characters + 1] = citizenid
        doorlock:editDoor(door.id, { characters = characters })
    end)
end

function Property:removeMloDoorsAccess(citizenid)
    self:forEachMloDoor(function(door, doorlock)
        local characters = door.characters or {}

        for index = 1, #characters do
            if characters[index] == citizenid then
                table.remove(characters, index)
                break
            end
        end

        doorlock:editDoor(door.id, { characters = characters })
    end)
end

function Property:UpdateOwner(data)
    local targetSrc = data.targetSrc
    local realtorSrc = data.realtorSrc

    if not realtorSrc then Debug("No Realtor Src found") return end
    if not targetSrc then Debug("No Target Src found") return end

    local previousOwner = self.propertyData.owner

    local PlayerData = Framework.GetPlayerData(targetSrc)
    if not PlayerData then return end

    local bank = PlayerData.money.bank
    local citizenid = PlayerData.citizenid

    self:addMloDoorsAccess(citizenid)

    if self.propertyData.owner == citizenid then
        Framework.Notify(targetSrc, "You already own this property", "error")
        Framework.Notify(realtorSrc, "Client already owns this property", "error")
        return
    end

    --add callback 
    local targetAllow = lib.callback.await("ps-housing:cb:confirmPurchase", targetSrc, self.propertyData.price, self.propertyData.street, self.propertyData.property_id)

    if targetAllow ~= "confirm" then
        Framework.Notify(targetSrc, "You did not confirm the purchase", "info")
        Framework.Notify(realtorSrc, "Client did not confirm the purchase", "error")
        return
    end

    if bank < self.propertyData.price then
                Framework.Notify(targetSrc, "You do not have enough money in your bank account", "error")
            Framework.Notify(realtorSrc, "Client does not have enough money in their bank account", "error")
        return
    end

    local reason = "Property: " .. self.propertyData.street .. " " .. self.property_id

    Framework.RemoveMoney(targetSrc, 'bank', self.propertyData.price, "Bought " .. reason)

    local prevPlayer = previousOwner and Framework.GetPlayerByCitizenId(previousOwner)
    local realtor = Framework.GetPlayerData(realtorSrc)
    if not realtor then return end

    local realtorGradeLevel = realtor.job.grade.level
    local commission = math.floor(self.propertyData.price * (Config.Commissions[realtorGradeLevel] or 0))
    local totalAfterCommission = self.propertyData.price - commission

    if Config.QBManagement then
        -- Was exports['qb-banking']:AddMoney. Die resource bestaat niet op deze
        -- server; het bankscript is Renewed-Banking. Stond onschadelijk omdat
        -- Config.QBManagement op false staat, maar sprong zodra iemand dat
        -- aanzette.
        exports['Renewed-Banking']:addAccountMoney(realtor.job.name, totalAfterCommission)
    elseif prevPlayer then
        Framework.Notify(prevPlayer.PlayerData.source, "Sold " .. reason, "success")
        Framework.AddMoney(prevPlayer.PlayerData.source, 'bank', totalAfterCommission, "Sold " .. reason)
    elseif previousOwner then
        Framework.AddOfflineBankMoney(previousOwner, totalAfterCommission)
    end

    Framework.AddMoney(realtorSrc, 'bank', commission, "Commission from " .. reason)

    self.propertyData.owner = citizenid

    MySQL.update("UPDATE properties SET owner_citizenid = @owner_citizenid, for_sale = @for_sale WHERE property_id = @property_id", {
        ["@owner_citizenid"] = citizenid,
        ["@for_sale"] = 0,
        ["@property_id"] = self.property_id
    })

    self.propertyData.furnitures = {} -- to be fetched on enter

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateOwner", self.property_id, citizenid)
    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateForSale", self.property_id, 0)
    
    Framework.SendLog(("**House Bought** by: **%s %s** for $%s from **%s %s** !"):format(
        PlayerData.charinfo.firstname, PlayerData.charinfo.lastname,
        self.propertyData.price,
        realtor.charinfo.firstname, realtor.charinfo.lastname
    ))

    Framework.Notify(targetSrc, "You have bought the property for $"..self.propertyData.price, "success")
    Framework.Notify(realtorSrc, "Client has bought the property for $"..self.propertyData.price, "success")
end

function Property:UpdateImgs(data)
    local imgs = data.imgs
    local realtorSrc = data.realtorSrc

    self.propertyData.imgs = imgs

    MySQL.update("UPDATE properties SET extra_imgs = @extra_imgs WHERE property_id = @property_id", {
        ["@extra_imgs"] = json.encode(imgs),
        ["@property_id"] = self.property_id
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateImgs", self.property_id, imgs)

    Framework.SendLog("**Changed Images** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed Imgs of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end


function Property:UpdateDoor(data)
    local door = data.door

    if not door then return end
    local realtorSrc = data.realtorSrc

    local newDoor = {
        x = math.floor(door.x * 10000) / 10000,
        y = math.floor(door.y * 10000) / 10000,
        z = math.floor(door.z * 10000) / 10000,
        h = math.floor(door.h * 10000) / 10000,
        length = door.length or 1.5,
        width = door.width or 2.2,
        locked = door.locked or false,
    }

    self.propertyData.door_data = newDoor

    self.propertyData.street = data.street
    self.propertyData.region = data.region


    MySQL.update("UPDATE properties SET door_data = @door, street = @street, region = @region WHERE property_id = @property_id", {
        ["@door"] = json.encode(newDoor),
        ["@property_id"] = self.property_id,
        ["@street"] = data.street,
        ["@region"] = data.region
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateDoor", self.property_id, newDoor, data.street, data.region)

    Framework.SendLog("**Changed Door** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed Door of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

function Property:UpdateHas_access(data)
    local has_access = data or {}

    self.propertyData.has_access = has_access

    MySQL.update("UPDATE properties SET has_access = @has_access WHERE property_id = @property_id", {
        ["@has_access"] = json.encode(has_access), --Array of cids
        ["@property_id"] = self.property_id
    })

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateHas_access", self.property_id, has_access)

    Debug("Changed Has Access of property with id: " .. self.property_id)
end

function Property:UpdateGarage(data)
    local garage = data.garage
    local realtorSrc = data.realtorSrc

    local newData = {}

    if data ~= nil then 
        newData = {
            x = math.floor(garage.x * 10000) / 10000,
            y = math.floor(garage.y * 10000) / 10000,
            z = math.floor(garage.z * 10000) / 10000,
            h = math.floor(garage.h * 10000) / 10000,
            length = garage.length or 3.0,
            width = garage.width or 5.0,
        }
    end

    self.propertyData.garage_data = newData

    MySQL.update("UPDATE properties SET garage_data = @garageCoords WHERE property_id = @property_id", {
        ["@garageCoords"] = json.encode(newData),
        ["@property_id"] = self.property_id
    })
    
    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateGarage", self.property_id, newData)

    Framework.SendLog("**Changed Garage** of property with id: " .. self.property_id .. " by: " .. GetPlayerName(realtorSrc))

    Debug("Changed Garage of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

function Property:UpdateApartment(data)
    local apartment = data.apartment
    local realtorSrc = data.realtorSrc
    local targetSrc = data.targetSrc

    self.propertyData.apartment = apartment

    MySQL.update("UPDATE properties SET apartment = @apartment WHERE property_id = @property_id", {
        ["@apartment"] = apartment,
        ["@property_id"] = self.property_id
    })

    Framework.Notify(realtorSrc, "Changed Apartment of property with id: " .. self.property_id .." to ".. apartment, "success")

    Framework.Notify(targetSrc, "Changed Apartment to " .. apartment, "success")

    Framework.SendLog("**Changed Apartment** with id: " .. self.property_id .. " by: **" .. GetPlayerName(realtorSrc) .. "** for **" .. GetPlayerName(targetSrc) .."**")

    TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateApartment", self.property_id, apartment)

    Debug("Changed Apartment of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
end

---Removes the doorlocks that were created for an mlo property.
function Property:RemoveDoors()
    self:forEachMloDoor(function(door, doorlock)
        local ok, err = pcall(function()
            doorlock:removeDoor(door.id)
        end)

        if not ok then
            Debug(('Could not remove doorlock %s: %s'):format(door.name, err))
        end
    end)
end

function Property:DeleteProperty(data)
    local realtorSrc = data.realtorSrc
    local propertyid = self.property_id
    local realtorName = GetPlayerName(realtorSrc)

    self:RemoveDoors()

    MySQL.query("DELETE FROM properties WHERE property_id = ?", { propertyid })

    TriggerClientEvent("ps-housing:client:removeProperty", -1, propertyid)

    Framework.Notify(realtorSrc, "Property with id: " .. propertyid .." has been removed.", "info")

    Framework.SendLog("**Property Deleted** with id: " .. propertyid .. " by: " .. realtorName)

    PropertiesTable[propertyid] = nil
    self = nil

    Debug("Deleted property with id: " .. propertyid, "by: " .. realtorName)
end

function Property.Get(property_id)
    return PropertiesTable[tostring(property_id)]
end

RegisterNetEvent('ps-housing:server:enterGarden', function (property_id)
    local src = source
    local property = Property.Get(property_id)

    if not property then
        Debug("Properties returned", json.encode(PropertiesTable, {indent = true}))
        return
    end

    property.playersInGarden[tostring(src)] = true
    ExpectTeleport(src)
end)

RegisterNetEvent('ps-housing:server:enterProperty', function (property_id, spawn,isanmlo)
    local src = source
    Debug("Player is trying to enter property", property_id)

    local property = Property.Get(property_id)
    if not property then
        Debug("Properties returned", json.encode(PropertiesTable, {indent = true}))
        return
    end

    ExpectTeleport(src)

    local citizenid = GetCitizenid(src)

    if property:CheckForAccess(citizenid) and not isanmlo then
        Debug("Player has access to property")
        if spawn == 'spawn' then
            TriggerClientEvent("ps-housing:client:enterProperty", src, property_id, spawn)
        else
            property:PlayerEnter(src)
        end
        Debug("Player entered property")
        return
    else
        property:PlayerEnter(src)
    end

    if not isanmlo then
        local ringDoorbellConfirmation = lib.callback.await('ps-housing:cb:ringDoorbell', src)
        if ringDoorbellConfirmation == "confirm" then
            property:AddToDoorbellPoolTemp(src)
            Debug("Ringing doorbell")
            return
        end
    end
end)

RegisterNetEvent("ps-housing:server:showcaseProperty", function(property_id)
    local src = source

    local property = Property.Get(property_id)

    if not property then
        Debug("Properties returned", json.encode(PropertiesTable, {indent = true}))
        return
    end

    ExpectTeleport(src)


    local PlayerData = GetPlayerData(src)
    local job = PlayerData.job
    local jobName = job.name
    local onDuty = job.onduty

    if RealtorJobs[jobName] and onDuty then
        local showcase = lib.callback.await('ps-housing:cb:showcase', src)
        if showcase == "confirm" then
            property:PlayerEnter(src)
            return
        end
    end
end)

RegisterNetEvent('ps-housing:server:raidProperty', function(property_id)
    local src = source
    Debug("Player is trying to raid property", property_id)

    local property = Property.Get(property_id)

    if not property then 
        Debug("Properties returned", json.encode(PropertiesTable, {indent = true}))
        return 
    end

    local PlayerData = Framework.GetPlayerData(src)
    if not PlayerData then return end

    local job = PlayerData.job
    local jobName = job.name
    local gradeAllowed = tonumber(job.grade.level) >= Config.MinGradeToRaid
    local onDuty = job.onduty
    local raidItem = Config.RaidItem

    -- Check if the police officer has the "stormram" item
    local hasStormRam = Framework.HasItem(src, raidItem)

    local isAllowedToRaid = PoliceJobs[jobName] and onDuty and gradeAllowed
    if isAllowedToRaid then
        if hasStormRam then
            if not property.raiding then
                local confirmRaid = lib.callback.await('ps-housing:cb:confirmRaid', src, (property.propertyData.street or property.propertyData.apartment) .. " " .. property.property_id, property_id)
                if confirmRaid == "confirm" then
                    property:StartRaid(src)
                    property:PlayerEnter(src)
                    Framework.Notify(src, "Raid started", "success")

                    if Config.ConsumeRaidItem then
                        -- Remove the "stormram" item from the officer's inventory
                        Framework.RemoveItem(src, raidItem, 1)
                    end

                    -- unlock the mlo doors so the raid team can actually get in
                    property:forEachMloDoor(function(door, doorlock)
                        doorlock:setDoorState(door.id, 0)
                    end)
                end
            else
                Framework.Notify(src, "Raid in progress", "success")
                property:PlayerEnter(src)
            end
        else
            Framework.Notify(src, "You need a stormram to perform a raid", "error")
        end
    else
        if not PoliceJobs[jobName] then
            Framework.Notify(src, "Only police officers are permitted to perform raids", "error")
        elseif not onDuty then
            Framework.Notify(src, "You must be onduty before performing a raid", "error")
        elseif not gradeAllowed then
            Framework.Notify(src, "You must be a higher rank before performing a raid", "error")
        end
    end
end)



lib.callback.register('ps-housing:cb:getFurnitures', function(_, property_id)
    local property = Property.Get(property_id)
    if not property then return end
    return property.propertyData.furnitures or {}
end)


lib.callback.register('ps-housing:cb:getPlayersInProperty', function(source, property_id)

    local property = Property.Get(property_id)
    if not property then return end

    local players = {}

    for src, _ in pairs(property.playersInside) do
        local targetSrc = tonumber(src)
        if targetSrc ~= source then
            local name = GetCharName(targetSrc)

            players[#players + 1] = {
                src = targetSrc,
                name = name
            }
        end
    end

    return players or {}
end)

RegisterNetEvent('ps-housing:server:leaveProperty', function (property_id)
    local src = source
    local property = Property.Get(property_id)

    if not property then return end

    ExpectTeleport(src)
    property:PlayerLeave(src)
end)

-- When player presses doorbell, owner can let them in and this is what is triggered
RegisterNetEvent("ps-housing:server:doorbellAnswer", function (data) 
    local src = source
    local targetSrc = data.targetSrc

    local property = Property.Get(data.property_id)
    if not property then return end
    
    if not property.playersInside[tostring(src)] then return end
    property:RemoveFromDoorbellPool(targetSrc)
    
    property:PlayerEnter(targetSrc)
end)

-- Catalogue lookup, built once, so furniture prices are taken from the config instead
-- of being trusted from the client.
local furnitureCatalogue = {}
do
    for i = 1, #Config.Furnitures do
        local category = Config.Furnitures[i]
        for j = 1, #category.items do
            local item = category.items[j]
            furnitureCatalogue[item.object] = item
        end
    end
end

RegisterNetEvent("ps-housing:server:buyFurniture", function(property_id, items, _, isGarden)
    local src = source

    if type(items) ~= 'table' then return end

    local citizenid = Framework.GetCitizenId(src)
    local PlayerData = Framework.GetPlayerData(src)
    if not citizenid or not PlayerData then return end

    local property = Property.Get(property_id)
    if not property then return end

    if not property:CheckForAccess(citizenid) then return end

    -- Recalculate the price server side, the client only decides *what* is bought
    local price = 0
    for i = 1, #items do
        local catalogueItem = furnitureCatalogue[items[i].object]
        if not catalogueItem then
            Debug(('%s tried to buy unknown furniture %s'):format(src, tostring(items[i].object)))
            return
        end

        price += catalogueItem.price
        items[i].label = catalogueItem.label
        items[i].type = catalogueItem.type
    end

    if price > PlayerData.money.bank and price > PlayerData.money.cash then
        Framework.Notify(src, "You do not have enough money!", "error")
        return
    end

    Framework.RemoveMoney(src, price <= PlayerData.money.cash and 'cash' or 'bank', price, "Bought furniture")

    local propertyData = property.propertyData
    local numFurnitures = #propertyData.furnitures
    local firstStorage = true

    for _,v in ipairs(propertyData.furnitures) do
        if v.type == 'storage' then
            firstStorage = false
            break
        end
    end

    for i = 1, #items do
        local item = items[i]
        if item.type == 'storage' then
            local stashName = ("property_%s"):format(propertyData.property_id)
            local stashConfig = Config.Shells[propertyData.shell].stash
            if not propertyData.apartment then
                Framework.RegisterInventory(firstStorage and stashName or stashName .. item.id, 'Property: ' .. propertyData.street .. '#' .. propertyData.property_id, stashConfig)
            else 
               Framework.RegisterInventory(firstStorage and stashName or stashName .. item.id, 'Property: ' .. propertyData.apartment .. '#' .. propertyData.property_id, stashConfig)
            end
        end
        numFurnitures = numFurnitures + 1
        propertyData.furnitures[numFurnitures] = item
    end

    property:UpdateFurnitures(propertyData.furnitures, isGarden)

    Framework.Notify(src, "You bought furniture for $" .. price, "success")

    Framework.SendLog("**Player ".. GetPlayerName(src) .. "** bought furniture for **$" .. price .. "**")

    Debug("Player bought furniture for $" .. price, "by: " .. GetPlayerName(src))
end)

RegisterNetEvent("ps-housing:server:removeFurniture", function(property_id, itemid)
    local src = source
    
    local property = Property.Get(property_id)
    if not property then return end
    
    local citizenid = GetCitizenid(src)
    if not property:CheckForAccess(citizenid) then return end

    local currentFurnitures = property.propertyData.furnitures

    for k, v in ipairs(currentFurnitures) do
        if v.id == itemid then
            table.remove(currentFurnitures, k)
            break
        end
    end

    property:UpdateFurnitures(currentFurnitures)
end)

-- @@ VERY BAD 
-- I think its not bad anymore but if u got a better idea lmk
RegisterNetEvent("ps-housing:server:updateFurniture", function(property_id, item)
    local src = source

    local property = Property.Get(property_id)
    if not property then return end

    local citizenid = GetCitizenid(src)
    if not property:CheckForAccess(citizenid) then return end

    local currentFurnitures = property.propertyData.furnitures

    for k, v in ipairs(currentFurnitures) do
        if v.id == item.id then
            currentFurnitures[k] = item
            Debug("Updated furniture", json.encode(item))
            break
        end
    end

    property:UpdateFurnitures(currentFurnitures)
end)

RegisterNetEvent("ps-housing:server:addAccess", function(property_id, srcToAdd)
    local src = source

    local citizenid = GetCitizenid(src)
    local property = Property.Get(property_id)
    if not property then return end

    if not property.propertyData.owner == citizenid then
        -- hacker ban or something
        Framework.Notify(src, "You are not the owner of this property!", "error")
        return
    end

    local has_access = property.propertyData.has_access

    local targetCitizenid = GetCitizenid(srcToAdd)
    local targetPlayer = GetPlayerData(srcToAdd)

    if not property:CheckForAccess(targetCitizenid) then
        has_access[#has_access+1] = targetCitizenid
        property:addMloDoorsAccess(targetCitizenid)
        property:UpdateHas_access(has_access)

        Framework.Notify(src, "You added access to " .. targetPlayer.charinfo.firstname .. " " .. targetPlayer.charinfo.lastname, "success")
        Framework.Notify(srcToAdd, "You got access to this property!", "success")
    else
        Framework.Notify(src, "This person already has access to this property!", "error")
    end
end)


RegisterNetEvent("ps-housing:server:qbxRegisterHouse", function(property_id)
    if not Framework.isStarted('qbx_garages') then return end

    local src = source
    local property = Property.Get(property_id)
    if not property then return end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid or not property:CheckForAccess(citizenid) then return end

    local propertyData = property.propertyData
    local garageData = propertyData.garage_data
    if not garageData or not garageData.x then return end

    local coords = vec4(garageData.x, garageData.y, garageData.z, garageData.h)

    exports.qbx_garages:RegisterGarage('housegarage-' .. property_id, {
        label = propertyData.street .. property.property_id .. " Garage",
        vehicleType = 'car',
        -- Not `groups`: qbx_garages checks that with HasPrimaryGroup, which expects a
        -- job/gang name. A citizenid there denies everyone, owner included.
        -- canAccess is evaluated per request, so selling or deleting the property also
        -- revokes the garage without needing an unregister export.
        canAccess = function(requestSrc)
            local prop = Property.Get(property_id)
            if not prop then return false end

            local cid = Framework.GetCitizenId(requestSrc)
            return cid ~= nil and prop:CheckForAccess(cid)
        end,
        accessPoints = {
            {
                coords = coords,
                spawn = coords,
            }
        },
    })
end)

RegisterNetEvent("ps-housing:server:removeAccess", function(property_id, citizenidToRemove)
    local src = source

    local citizenid = GetCitizenid(src)
    local property = Property.Get(property_id)
    if not property then return end

    if not property.propertyData.owner == citizenid then
        -- hacker ban or something
        Framework.Notify(src, "You are not the owner of this property!", "error")
        return
    end

    local has_access = property.propertyData.has_access

    if property:CheckForAccess(citizenidToRemove) then
        for i = 1, #has_access do
            if has_access[i] == citizenidToRemove then
                table.remove(has_access, i)
                break
            end
        end 

        property:removeMloDoorsAccess(citizenidToRemove)
        property:UpdateHas_access(has_access)

        local playerToRemove = Framework.GetPlayerByCitizenIdOffline(citizenidToRemove)
        if not playerToRemove then return end

        local removePlayerData = playerToRemove.PlayerData
        local srcToRemove = removePlayerData.source

        Framework.Notify(src, "You removed access from " .. removePlayerData.charinfo.firstname .. " " .. removePlayerData.charinfo.lastname, "success")

        if srcToRemove then
            Framework.Notify(srcToRemove, "You lost access to " .. (property.propertyData.street or property.propertyData.apartment) .. " " .. property.property_id, "error")
        end
    else
        Framework.Notify(src, "This person does not have access to this property!", "error")
    end
end)

lib.callback.register("ps-housing:cb:getPlayersWithAccess", function (source, property_id)
    local src = source
    local citizenidSrc = GetCitizenid(src)
    local property = Property.Get(property_id)
    
    if not property then return end
    if property.propertyData.owner ~= citizenidSrc then return end

    local withAccess = {}
    local has_access = property.propertyData.has_access

    for i = 1, #has_access do
        local citizenid = has_access[i]
        local Player = Framework.GetPlayerByCitizenIdOffline(citizenid)
        if Player then
            withAccess[#withAccess + 1] = {
                citizenid = citizenid,
                name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            }
        end
    end

    return withAccess
end)

lib.callback.register('ps-housing:cb:getPropertyInfo', function (source, property_id)
    local src = source
    local property = Property.Get(property_id)

    if not property then return end

    
    local PlayerData = GetPlayerData(src)
    local job = PlayerData.job
    local jobName = job.name
    local onDuty = job.onduty

    if RealtorJobs[jobName] and not onDuty then return end

    local data = {}

    local ownerPlayer, ownerName

    local ownerCid = property.propertyData.owner
    if ownerCid then
        ownerPlayer = Framework.GetPlayerByCitizenIdOffline(ownerCid)
        ownerName = ownerPlayer
            and ("%s %s"):format(ownerPlayer.PlayerData.charinfo.firstname, ownerPlayer.PlayerData.charinfo.lastname)
            or "Unknown"
    else
        ownerName = "No Owner"
    end

    data.owner = ownerName
    data.street = property.propertyData.street
    data.region = property.propertyData.region
    data.description = property.propertyData.description
    data.for_sale = property.propertyData.for_sale
    data.price = property.propertyData.price
    data.shell = property.propertyData.shell
    data.property_id = property.property_id

    return data
end)

RegisterNetEvent('ps-housing:server:resetMetaData', function()
    Framework.SetInsideProperty(source, nil)
end)

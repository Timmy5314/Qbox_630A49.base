PlayerData = {}
PropertiesLoaded = false

local function createProperty(property)
	PropertiesTable[property.property_id] = Property:new(property)
end
RegisterNetEvent('ps-housing:client:addProperty', createProperty)

RegisterNetEvent('ps-housing:client:removeProperty', function(property_id)
	local property = Property.Get(property_id)

	if property then
		property:RemoveProperty()
	end

	PropertiesTable[property_id] = nil
end)

function InitialiseProperties(properties)
    if PropertiesLoaded then return end
    Debug("Initialising properties")

    PlayerData = Framework.GetPlayerData()

    for k, v in pairs(Config.Apartments) do
        ApartmentsTable[k] = Apartment:new(v)
    end

	if not properties then
    	properties = lib.callback.await('ps-housing:server:requestProperties')
	end

    for _, v in pairs(properties) do
        createProperty(v.propertyData)
    end

    PropertiesLoaded = true
    TriggerEvent("ps-housing:client:initialisedProperties")

    Debug("Initialised properties")
end
AddEventHandler("QBCore:Client:OnPlayerLoaded", InitialiseProperties)
RegisterNetEvent('ps-housing:client:initialiseProperties', InitialiseProperties)

---Blocks until the property list is available. Used by anything that can fire before
---the player is fully loaded (spawning back into a property after a relog for example).
---@param timeout? number milliseconds, defaults to 15s
---@return boolean loaded
function WaitForProperties(timeout)
    local deadline = GetGameTimer() + (timeout or 15000)

    while not PropertiesLoaded do
        if GetGameTimer() > deadline then return false end
        Wait(50)
    end

    return true
end

-- Keeps the cached PlayerData in sync. Without this, job/gang/duty changes would not be
-- picked up by the target canInteract checks until the player relogs.
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if type(data) ~= 'table' then return end
    PlayerData = data
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerData.gang = gang
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    if PlayerData.job then PlayerData.job.onduty = onDuty end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

if Framework.isStarted('qbx_properties') then
    lib.print.warn('qbx_properties is running. It owns a `properties` table with a different schema and will conflict with ps-housing, stop it.')
end

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() ~= resourceName then return end

    if Modeler.IsMenuActive then
        Modeler:CloseMenu()
    end

    for _, v in pairs(PropertiesTable) do
        v:RemoveProperty()
    end

    for _, v in pairs(ApartmentsTable) do
        v:RemoveApartment()
    end
end)

exports('GetProperties', function()
    return PropertiesTable
end)

exports('GetProperty', function(property_id)
    return Property.Get(property_id)
end)

exports('GetApartments', function()
    return ApartmentsTable
end)

exports('GetApartment', function(apartment)
    return Apartment.Get(apartment)
end)

exports('GetShells', function()
    return Config.Shells
end)

lib.callback.register('ps-housing:cb:confirmPurchase', function(amount, street, id)
    return lib.alertDialog({
        header = 'Purchase Confirmation',
        content = 'Are you sure you want to purchase '..street..' ' .. id .. ' for $' .. amount .. '?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Purchase",
            cancel = "Cancel"
        }
    })
end)

lib.callback.register('ps-housing:cb:confirmRaid', function(street, id)
    return lib.alertDialog({
        header = 'Raid',
        content = 'Do you want to raid '..street..' ' .. id .. '?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Raid",
            cancel = "Cancel"
        }
    })
end)

lib.callback.register('ps-housing:cb:ringDoorbell', function()
    return lib.alertDialog({
        header = 'Ring Doorbell',
        content = 'You dont have a key for this property, would you like to ring the doorbell?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Ring",
            cancel = "Cancel"
        }
    })
end)

lib.callback.register('ps-housing:cb:showcase', function()
    return lib.alertDialog({
        header = 'Showcase Property',
        content = 'Do you want to showcase this property?',
        centered = true,
        cancel = true,
        labels = {
            confirm = "Yes",
            cancel = "Cancel"
        }
    })
end)

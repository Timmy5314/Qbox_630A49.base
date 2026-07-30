if not GetResourceState('qbx_core'):find('start') then
    return error('ps-realtor requires qbx_core.')
end

local core = exports.qbx_core

---Which permission from Config.RealtorPerms each property action needs.
---This doubles as a whitelist and that matters: ps-housing dispatches this as
---`property[action](property, data)`, so accepting an arbitrary string would let a realtor
---call any method on the Property object, permission checks included.
local permissionByAction = {
    UpdateDescription = 'manageProperty',
    UpdatePrice = 'manageProperty',
    UpdateShell = 'manageProperty',
    UpdateImgs = 'manageProperty',
    UpdateDoor = 'manageProperty',
    UpdateGarage = 'manageProperty',
    UpdateForSale = 'changePropertyForSale',
    UpdateOwner = 'sellProperty',
    UpdateApartment = 'setApartments',
    DeleteProperty = 'deleteProperty',
}

---Job and grade check in one. The UI hides buttons the realtor may not use, but that is
---cosmetic: without this the server would accept any action from any realtor, grade 0
---included.
---@param src number
---@param permission? string key of Config.RealtorPerms
---@return table? playerData
local function getRealtor(src, permission)
    local player = core:GetPlayer(src)
    if not player then return end

    local job = player.PlayerData.job
    if not RealtorJobs[job.name] then return end

    if permission then
        local required = Config.RealtorPerms[permission]
        if required and (job.grade.level or 0) < required then
            core:Notify(src, ('You need a higher rank to do this (%s).'):format(permission), 'error')
            return
        end
    end

    return player.PlayerData
end

-- parameter is deliberately not called `type`: that would shadow the Lua builtin
RegisterNetEvent("bl-realtor:server:updateProperty", function(updateType, property_id, data)
    local src = source
    if not updateType or not property_id or type(data) ~= 'table' then return end

    local permission = permissionByAction[updateType]
    if not permission then
        lib.print.warn(('%s sent unknown property action "%s"'):format(src, tostring(updateType)))
        return
    end

    if not getRealtor(src, permission) then return end

    data.realtorSrc = src

    TriggerEvent("ps-housing:server:updateProperty", updateType, property_id, data)
end)

RegisterNetEvent("bl-realtor:server:registerProperty", function(data)
    local src = source
    if type(data) ~= 'table' then return end

    if not getRealtor(src, 'listNewProperty') then return end

    data.realtorSrc = src

    return exports['ps-housing']:registerProperty(data, nil, src)
end)

RegisterNetEvent("bl-realtor:server:addTenantToApartment", function(data)
    local src = source
    if type(data) ~= 'table' then return end

    if not getRealtor(src, 'setApartments') then return end

    data.realtorSrc = src

    TriggerEvent("ps-housing:server:addTenantToApartment", data)
end)

lib.callback.register("bl-realtor:server:getNames", function(source, data)
    if not getRealtor(source) then return {} end
    if type(data) ~= 'table' then return {} end

    local names = {}

    for i = 1, #data do
        local citizenid = data[i]
        local target = core:GetPlayerByCitizenId(citizenid) or core:GetOfflinePlayer(citizenid)

        names[#names + 1] = target
            and ('%s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname)
            or "Unknown"
    end

    return names
end)

if Config.UseItem then
    core:CreateUseableItem(Config.ItemName, function(source)
        TriggerClientEvent("bl-realtor:client:toggleUI", source)
    end)
end

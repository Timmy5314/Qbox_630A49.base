--[[
    ps-housing framework bridge (Qbox only)

    Core      : qbx_core
    Target    : ox_target
    Inventory : ox_inventory
    Radial    : ox_lib
    Notify    : ox_lib
    Doorlock  : ox_doorlock
    Clothing  : see Config.Clothing in shared/config.lua

    Note on the QBCore:* event names used throughout this resource: those are qbx_core's
    own events, Qbox kept the old names for compatibility. They are not qb-core.
]]

Framework = {}

PoliceJobs = {}
RealtorJobs = {}

for i = 1, #Config.PoliceJobNames do
    PoliceJobs[Config.PoliceJobNames[i]] = true
end

for i = 1, #Config.RealtorJobNames do
    RealtorJobs[Config.RealtorJobNames[i]] = true
end

---@param resource string
---@return boolean
local function isStarted(resource)
    return GetResourceState(resource):find('start') ~= nil
end
Framework.isStarted = isStarted

if not isStarted('qbx_core') then
    error('ps-housing requires qbx_core. For qb-core, use ps-housing 2.0.x.')
end

-- Clothing: the wardrobe (shop/outfits) and the character creator can live in two
-- different resources. renzu_clothes for example is only a shop/wardrobe, it always
-- runs on top of an appearance resource (illenium-appearance / fivem-appearance).
if Config.Clothing.wardrobe == 'auto' then
    Config.Clothing.wardrobe = (isStarted('renzu_clothes') and 'renzu_clothes')
        or (isStarted('illenium-appearance') and 'illenium-appearance')
        or (isStarted('fivem-appearance') and 'fivem-appearance')
        or (isStarted('qb-clothing') and 'qb-clothing')
        or 'none'
end

if Config.Clothing.appearance == 'auto' then
    Config.Clothing.appearance = (isStarted('illenium-appearance') and 'illenium-appearance')
        or (isStarted('fivem-appearance') and 'fivem-appearance')
        or (isStarted('qb-clothing') and 'qb-clothing')
        or 'none'
end

if Config.GarageResource == 'auto' then
    Config.GarageResource = (isStarted('renzu_garage') and 'renzu_garage')
        or (isStarted('qbx_garages') and 'qbx_garages')
        or 'none'
end

if isStarted('renzu_garage') and isStarted('qbx_garages') then
    lib.print.warn('renzu_garage and qbx_garages are both running. ps-housing uses ' .. Config.GarageResource ..
        ' for house garages; vehicles parked through the other one will not show up.')
end

--#region Server

if IsDuplicityVersion() then
    local core = exports.qbx_core

    ---@param src number|string
    ---@return table? player
    function Framework.GetPlayer(src)
        src = tonumber(src)
        if not src then return end
        return core:GetPlayer(src)
    end

    ---@param citizenid string
    ---@return table? player
    function Framework.GetPlayerByCitizenId(citizenid)
        if not citizenid then return end
        return core:GetPlayerByCitizenId(citizenid)
    end

    ---Online player first, falls back to the database record.
    ---@param citizenid string
    ---@return table? player
    function Framework.GetPlayerByCitizenIdOffline(citizenid)
        if not citizenid then return end
        return core:GetPlayerByCitizenId(citizenid) or core:GetOfflinePlayer(citizenid)
    end

    ---@param src number|string
    ---@return table? playerData
    function Framework.GetPlayerData(src)
        local player = Framework.GetPlayer(src)
        return player and player.PlayerData
    end

    ---@param src number|string
    ---@param callerSrc? number source to notify when the player can't be found
    ---@return string? citizenid
    function Framework.GetCitizenId(src, callerSrc)
        local playerData = Framework.GetPlayerData(src)
        if not playerData then
            if callerSrc then
                Framework.Notify(callerSrc, 'Player not found.', 'error')
            end
            return
        end
        return playerData.citizenid
    end

    ---@param src number|string
    ---@return string? name
    function Framework.GetCharName(src)
        local playerData = Framework.GetPlayerData(src)
        if not playerData then return end
        return ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)
    end

    ---@param src number
    ---@param bucket number
    function Framework.SetPlayerBucket(src, bucket)
        core:SetPlayerBucket(src, bucket)
    end

    ---Stores which property the player is currently inside so they can be put back
    ---there on relog.
    ---@param src number
    ---@param propertyId string?
    function Framework.SetInsideProperty(src, propertyId)
        local player = Framework.GetPlayer(src)
        if not player then return end

        local inside = player.PlayerData.metadata.inside or {}
        inside.property_id = propertyId

        core:SetMetadata(src, 'inside', inside)
    end

    ---@param src number
    ---@return string? propertyId
    function Framework.GetInsideProperty(src)
        local playerData = Framework.GetPlayerData(src)
        local inside = playerData and playerData.metadata and playerData.metadata.inside
        return inside and inside.property_id and tostring(inside.property_id) or nil
    end

    ---@param src number
    ---@param moneyType 'cash'|'bank'
    ---@param amount number
    ---@param reason? string
    ---@return boolean success
    function Framework.AddMoney(src, moneyType, amount, reason)
        return core:AddMoney(src, moneyType, amount, reason)
    end

    ---@param src number
    ---@param moneyType 'cash'|'bank'
    ---@param amount number
    ---@param reason? string
    ---@return boolean success
    function Framework.RemoveMoney(src, moneyType, amount, reason)
        return core:RemoveMoney(src, moneyType, amount, reason)
    end

    ---Pays an offline citizen straight into their bank balance.
    ---@param citizenid string
    ---@param amount number
    function Framework.AddOfflineBankMoney(citizenid, amount)
        MySQL.update('UPDATE `players` SET `money` = JSON_SET(`money`, "$.bank", JSON_EXTRACT(`money`, "$.bank") + ?) WHERE `citizenid` = ?', {
            amount, citizenid
        })
    end

    ---@param src number
    ---@param item string
    ---@return boolean
    function Framework.HasItem(src, item)
        return (exports.ox_inventory:Search(src, 'count', item) or 0) > 0
    end

    ---@param src number
    ---@param item string
    ---@param amount number
    function Framework.RemoveItem(src, item, amount)
        exports.ox_inventory:RemoveItem(src, item, amount)
    end

    ---@param stash string
    ---@param label string
    ---@param stashConfig {slots: number, maxweight: number}
    function Framework.RegisterInventory(stash, label, stashConfig)
        exports.ox_inventory:RegisterStash(stash, label, stashConfig.slots, stashConfig.maxweight, nil)
    end

    ---@param src number
    ---@param message string
    ---@param type? 'success'|'error'|'info'
    function Framework.Notify(src, message, type)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Property',
            description = message,
            type = type == 'inform' and 'info' or type
        })
    end

    ---@param message string
    function Framework.SendLog(message)
        if not Config.EnableLogs then return end

        if Config.LogsWebhook and Config.LogsWebhook ~= '' then
            PerformHttpRequest(Config.LogsWebhook, function() end, 'POST', json.encode({
                username = 'Housing System',
                embeds = { { title = 'Housing System', description = message, color = 3447003 } }
            }), { ['Content-Type'] = 'application/json' })
            return
        end

        lib.print.info(message)
    end

    ---Does this character already have a saved ped/skin?
    ---Errors (a missing playerskins table for example) count as "has a skin" so the
    ---character creator never spams players on join.
    ---@param citizenid string
    ---@return boolean
    function Framework.HasSkin(citizenid)
        if Config.Clothing.appearance == 'none' then return true end

        local ok, skin = pcall(function()
            return MySQL.scalar.await('SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1', { citizenid })
        end)

        if not ok then
            Debug(('Could not read playerskins for %s: %s'):format(citizenid, skin))
            return true
        end

        return skin ~= nil
    end

    ---Opens the character creator for a brand new character.
    ---@param src number
    function Framework.CreateFirstCharacter(src)
        local appearance = Config.Clothing.appearance

        if appearance == 'none' then return end

        if appearance == 'fivem-appearance' then
            TriggerClientEvent('fivem-appearance:client:openCharacterCreation', src)
            return
        end

        -- illenium-appearance's own event name, kept from its qb-clothes compatibility layer
        TriggerClientEvent('qb-clothes:client:CreateFirstCharacter', src)
    end

    return
end

--#endregion
--#region Client

---@return table playerData
function Framework.GetPlayerData()
    return exports.qbx_core:GetPlayerData() or {}
end

---@param message string
---@param type? 'success'|'error'|'info'
function Framework.Notify(message, type)
    lib.notify({
        title = 'Property',
        description = message,
        type = type == 'inform' and 'info' or type
    })
end

---Opens the personal wardrobe/outfit menu from the wardrobe furniture.
function Framework.OpenWardrobe()
    local wardrobe = Config.Clothing.wardrobe

    if wardrobe == 'renzu_clothes' then
        exports.renzu_clothes:OpenClotheInventory()
        return
    end

    if wardrobe == 'fivem-appearance' then
        TriggerEvent('fivem-appearance:client:openOutfitMenu')
        return
    end

    if wardrobe == 'none' then
        Framework.Notify('No clothing resource configured.', 'error')
        return
    end

    -- illenium-appearance's own event name, kept from its qb-clothing compatibility layer
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end

---@param stash string
function Framework.OpenInventory(stash)
    exports.ox_inventory:openInventory('stash', stash)
end

---@param stash string
---@return boolean
function Framework.inventoryHasItems(stash)
    return lib.callback.await('ps-housing:cb:inventoryHasItems', false, stash)
end

--#region Targets

local function hasApartment(apts)
    for propertyId in pairs(apts) do
        local property = PropertiesTable[propertyId]
        if property and property.owner then
            return true
        end
    end

    return false
end

local function canEnter(property_id)
    local property = Property.Get(property_id)
    return property and (property.has_access or property.owner) or false
end

local function canRing(property_id)
    local property = Property.Get(property_id)
    return property and not property.has_access and not property.owner or false
end

local function isRealtor(requireDuty)
    local job = PlayerData.job
    if not job then return false end
    if requireDuty and not job.onduty then return false end
    return RealtorJobs[job.name] or false
end

local function canRaid()
    local job = PlayerData.job
    if not job then return false end
    return (PoliceJobs[job.name] and job.onduty and tonumber(job.grade.level) >= Config.MinGradeToRaid) or false
end

---@return number handler
function Framework.AddEntrance(coords, size, heading, property_id, enter, raid, showcase, showData)
    return exports.ox_target:addBoxZone({
        coords = vector3(coords.x, coords.y, coords.z),
        size = vector3(size.y, size.x, size.z),
        rotation = heading,
        debug = Config.DebugMode,
        options = {
            {
                name = 'ps-housing:enter',
                label = 'Enter Property',
                icon = 'fas fa-door-open',
                onSelect = enter,
                canInteract = function() return canEnter(property_id) end,
            },
            {
                name = 'ps-housing:showcase',
                label = 'Showcase Property',
                icon = 'fas fa-eye',
                onSelect = showcase,
                canInteract = function() return isRealtor(false) end,
            },
            {
                name = 'ps-housing:info',
                label = 'Property Info',
                icon = 'fas fa-circle-info',
                onSelect = showData,
                canInteract = function() return isRealtor(true) end,
            },
            {
                name = 'ps-housing:doorbell',
                label = 'Ring Doorbell',
                icon = 'fas fa-bell',
                onSelect = enter,
                canInteract = function() return canRing(property_id) end,
            },
            {
                name = 'ps-housing:raid',
                label = 'Raid Property',
                icon = 'fas fa-building-shield',
                onSelect = raid,
                canInteract = canRaid,
            },
        },
    })
end

---@return number handler
function Framework.AddApartmentEntrance(coords, size, heading, apartment, enter, seeAll, seeAllToRaid)
    return exports.ox_target:addBoxZone({
        coords = vector3(coords.x, coords.y, coords.z),
        size = vector3(size.y, size.x, size.z),
        rotation = heading,
        debug = Config.DebugMode,
        options = {
            {
                name = 'ps-housing:enterApartment',
                label = 'Enter Apartment',
                onSelect = enter,
                icon = 'fas fa-door-open',
                canInteract = function()
                    local apartments = ApartmentsTable[apartment] and ApartmentsTable[apartment].apartments
                    return apartments and hasApartment(apartments) or false
                end,
            },
            {
                name = 'ps-housing:allApartments',
                label = 'See all apartments',
                onSelect = seeAll,
                icon = 'fas fa-circle-info',
            },
            {
                name = 'ps-housing:raidApartment',
                label = 'Raid Apartment',
                onSelect = seeAllToRaid,
                icon = 'fas fa-building-shield',
                canInteract = canRaid,
            },
        },
    })
end

---Interaction point for a house garage. Both storing and retrieving run through the
---same option, the garage resource decides which one based on whether you are driving.
---@param coords vector4 garage position and heading
---@param garageData table the property's garage_data (length/width)
---@param onSelect fun()
---@return number handler
function Framework.AddGarageEntrance(coords, garageData, onSelect)
    return exports.ox_target:addBoxZone({
        coords = coords.xyz,
        size = vector3((garageData.width or 5.0) + 2.0, (garageData.length or 3.0) + 2.0, 3.5),
        rotation = coords.w,
        debug = Config.DebugMode,
        options = {
            {
                name = 'ps-housing:garage',
                label = 'Garage',
                icon = 'fas fa-warehouse',
                onSelect = onSelect,
                -- works on foot and while driving, so no bones/vehicle filter here
            },
        },
    })
end

---@return number handler
function Framework.AddDoorZoneInside(coords, size, heading, leave, checkDoor)
    return exports.ox_target:addBoxZone({
        coords = vector3(coords.x, coords.y, coords.z),
        size = vector3(size.y, size.x, size.z),
        rotation = heading,
        debug = Config.DebugMode,
        options = {
            {
                name = 'leave',
                label = 'Leave Property',
                onSelect = leave,
                icon = 'fas fa-right-from-bracket',
            },
            {
                name = 'doorbell',
                label = 'Check Door',
                onSelect = checkDoor,
                icon = 'fas fa-bell',
            },
        },
    })
end

---@return number handler
function Framework.AddDoorZoneInsideTempShell(coords, size, heading, leave)
    return exports.ox_target:addBoxZone({
        coords = vector3(coords.x, coords.y, coords.z),
        size = vector3(size.y, size.x, size.z),
        rotation = heading,
        debug = Config.DebugMode,
        options = {
            {
                name = 'leave',
                label = 'Leave',
                onSelect = leave,
                icon = 'fas fa-right-from-bracket',
            },
        },
    })
end

---@param handler? number
function Framework.RemoveTargetZone(handler)
    if not handler then return end
    exports.ox_target:removeZone(handler)
end

function Framework.AddTargetEntity(entity, label, icon, action)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = label,
            label = label,
            icon = icon,
            onSelect = action,
        },
    })
end

function Framework.RemoveTargetEntity(entity)
    exports.ox_target:removeLocalEntity(entity)
end

function Framework.AddRadialOption(id, label, icon, fn)
    lib.addRadialItem({
        id = id,
        icon = icon,
        label = label,
        onSelect = fn,
    })
end

function Framework.RemoveRadialOption(id)
    lib.removeRadialItem(id)
end

--#endregion
--#endregion

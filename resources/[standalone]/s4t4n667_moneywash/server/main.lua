--[[
    Server is autoriteit. Het origineel liet de client het bedrag, de
    minimumcheck en het saldo bepalen en voerde dat hier klakkeloos uit.

    Wat er in het origineel mis was, en hier is afgevangen:
      1. `Amount` kwam ongevalideerd binnen. Een negatief getal passeerde
         `black_money >= Amount` en ging daarna als negatieve hoeveelheid naar
         RemoveItem/AddItem.
      2. minAmount stond in de config maar werd nergens server-side getoetst.
      3. De token-check was omgekeerd: `if itemRequired and token >= 1 then
         RemoveItem(token)`. Had je geen token, dan werd de token niet
         afgenomen maar liep het wassen gewoon door.
      4. Geen afstandscontrole; het event was vanaf elke plek op de map te
         triggeren.
      5. Geen slot. Twee gelijktijdige wasbeurten deelden dezelfde
         saldocontrole.
]]

lib.locale()

local config = lib.require 'config'

---@type table<number, boolean>
local busy = {}

-- =========================================================================
--  Toegang
-- =========================================================================

---Is deze speler eigenaar van een renzu_shops winkel?
---renzu_shops bewaart de eigenaar als license-identifier in GlobalState.Stores
---(zie server/framework/main.lua daar: owner = 'license').
---@param source number
---@return boolean
local function ownsAShop(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    local license = player.PlayerData.license
    if not license then return false end

    local stores = GlobalState.Stores
    if type(stores) ~= 'table' then return false end

    for _, store in pairs(stores) do
        if store.owner == license then return true end
    end

    return false
end

---@param source number
---@return boolean granted, string? reason
local function checkAccess(source)
    if config.access.requireShopOwner and not ownsAShop(source) then
        return false, 'access_no_shop'
    end

    if config.access.requireKey then
        local count = exports.ox_inventory:Search(source, 'count', config.access.keyItem)
        if type(count) ~= 'number' or count < 1 then
            return false, 'access_no_key'
        end
    end

    return true
end

lib.callback.register('s4t4n667_moneywash:canEnter', function(source)
    local granted, reason = checkAccess(source)

    if granted and config.access.removeKey then
        exports.ox_inventory:RemoveItem(source, config.access.keyItem, 1)
    end

    return granted, reason and locale(reason) or nil
end)

-- =========================================================================
--  Helpers
-- =========================================================================

---@param value any
---@param min number
---@param max number
---@return number?
local function sanitizeAmount(value, min, max)
    local amount = tonumber(value)
    if not amount then return end
    if amount ~= math.floor(amount) then return end
    if amount < min or amount > max then return end
    return amount
end

---@param source number
---@param coords vector3
---@return boolean
local function isNear(source, coords)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= config.interactDistance
end

---@param source number
---@param key string
---@param type_ string
local function notify(source, key, type_)
    TriggerClientEvent('ox_lib:notify', source, {
        description = locale(key),
        type = type_ or 'inform',
    })
end

-- =========================================================================
--  Wassen
-- =========================================================================

lib.callback.register('s4t4n667_moneywash:wash', function(source, amount)
    if busy[source] then return false end

    amount = sanitizeAmount(amount, config.washing.minAmount, config.washing.maxAmount)
    if not amount then
        notify(source, 'invalid_amount', 'error')
        return false
    end

    if not isNear(source, config.interior.wash) then
        notify(source, 'too_far', 'error')
        return false
    end

    local granted = checkAccess(source)
    if not granted then
        notify(source, 'access_no_shop', 'error')
        return false
    end

    local dirty = exports.ox_inventory:Search(source, 'count', config.washing.dirtyMoney)
    if type(dirty) ~= 'number' or dirty < amount then
        notify(source, 'not_enough_dirty', 'error')
        return false
    end

    if config.washing.requireToken then
        local tokens = exports.ox_inventory:Search(source, 'count', config.washing.tokenItem)
        if type(tokens) ~= 'number' or tokens < 1 then
            notify(source, 'no_token', 'error')
            return false
        end
    end

    busy[source] = true

    -- Eerst innemen, dan pas wachten. Andersom kan de speler in de tussentijd
    -- zijn geld wegzetten en alsnog wet_bills krijgen.
    if not exports.ox_inventory:RemoveItem(source, config.washing.dirtyMoney, amount) then
        busy[source] = nil
        return false
    end

    if config.washing.requireToken then
        exports.ox_inventory:RemoveItem(source, config.washing.tokenItem, 1)
    end

    Wait(config.washing.duration)

    local payout = math.floor(amount * (1.0 - config.washing.taxRate))
    exports.ox_inventory:AddItem(source, config.washing.wetMoney, payout)

    busy[source] = nil

    if config.debug then
        lib.print.info(('%s waste %d zwart geld, kreeg %d wet_bills'):format(GetPlayerName(source), amount, payout))
    end

    return true, payout
end)

-- =========================================================================
--  Drogen en tellen
-- =========================================================================

lib.callback.register('s4t4n667_moneywash:dry', function(source, amount)
    if busy[source] then return false end

    amount = sanitizeAmount(amount, 1, config.drying.maxAmount)
    if not amount then
        notify(source, 'invalid_amount', 'error')
        return false
    end

    if not isNear(source, config.interior.count) then
        notify(source, 'too_far', 'error')
        return false
    end

    local wet = exports.ox_inventory:Search(source, 'count', config.washing.wetMoney)
    if type(wet) ~= 'number' or wet < amount then
        notify(source, 'not_enough_wet', 'error')
        return false
    end

    busy[source] = true

    if not exports.ox_inventory:RemoveItem(source, config.washing.wetMoney, amount) then
        busy[source] = nil
        return false
    end

    Wait(config.drying.duration)

    exports.ox_inventory:AddItem(source, config.washing.cleanMoney, amount)
    busy[source] = nil

    return true, amount
end)

-- =========================================================================
--  Winkel
-- =========================================================================

lib.callback.register('s4t4n667_moneywash:buy', function(source, itemName)
    if type(itemName) ~= 'string' then return false end

    local entry
    for i = 1, #config.shop.items do
        if config.shop.items[i].item == itemName then
            entry = config.shop.items[i]
            break
        end
    end

    if not entry then return false end

    if not isNear(source, vec3(config.shop.coords.x, config.shop.coords.y, config.shop.coords.z)) then
        notify(source, 'too_far', 'error')
        return false
    end

    -- Ook de sleutel en de munten zijn alleen voor winkeleigenaren. Zonder deze
    -- check kan iedereen een sleutel kopen en is de eigendomseis bij de deur
    -- alsnog te omzeilen door hem aan een ander te geven.
    if config.access.requireShopOwner and not ownsAShop(source) then
        notify(source, 'access_no_shop', 'error')
        return false
    end

    local funds = exports.ox_inventory:Search(source, 'count', config.shop.currency)
    if type(funds) ~= 'number' or funds < entry.price then
        notify(source, 'not_enough_dirty', 'error')
        return false
    end

    if not exports.ox_inventory:CanCarryItem(source, itemName, 1) then
        notify(source, 'cannot_carry', 'error')
        return false
    end

    if not exports.ox_inventory:RemoveItem(source, config.shop.currency, entry.price) then
        return false
    end

    exports.ox_inventory:AddItem(source, itemName, 1)
    notify(source, 'purchased', 'success')

    return true
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)

---@diagnostic disable: undefined-global
--- Server bridge: framework (qbx_core / qb-core / ESX) and inventory (ox_inventory).

Bridge = {}
Inv = {}

-- ── Framework ─────────────────────────────────────────────────────────────

local function detectFramework()
    if GetResourceState('qbx_core'):find('start') then return 'qbx' end
    if GetResourceState('qb-core'):find('start') then return 'qb' end
    if GetResourceState('es_extended'):find('start') then return 'esx' end
    return 'standalone'
end

Bridge.framework = detectFramework()

local QBCore, ESX

if Bridge.framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Bridge.framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

lib.print.info(('renzu_clothes: framework = %s'):format(Bridge.framework))

--- Unique, permanent character id (citizenid / ESX identifier).
---@param src number
---@return string|nil
function Bridge.getIdentifier(src)
    if Bridge.framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    elseif Bridge.framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    elseif Bridge.framework == 'esx' then
        local player = ESX.GetPlayerFromId(src)
        return player and player.identifier
    end

    return GetPlayerIdentifierByType(src, 'license')
end

--- Balance of both accounts.
---@param src number
---@return { cash: number, bank: number }
function Bridge.getMoney(src)
    if Bridge.framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return { cash = 0, bank = 0 } end
        return { cash = player.PlayerData.money.cash or 0, bank = player.PlayerData.money.bank or 0 }
    elseif Bridge.framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return { cash = 0, bank = 0 } end
        return { cash = player.PlayerData.money.cash or 0, bank = player.PlayerData.money.bank or 0 }
    elseif Bridge.framework == 'esx' then
        local player = ESX.GetPlayerFromId(src)
        if not player then return { cash = 0, bank = 0 } end
        return {
            cash = player.getAccount('money') and player.getAccount('money').money or 0,
            bank = player.getAccount('bank') and player.getAccount('bank').money or 0,
        }
    end

    return { cash = 0, bank = 0 }
end

--- Takes money. Returns false when there is not enough.
---@param src number
---@param account 'cash'|'bank'
---@param amount number
---@param reason string
---@return boolean
function Bridge.removeMoney(src, account, amount, reason)
    if amount <= 0 then return true end

    local money = Bridge.getMoney(src)
    if (money[account] or 0) < amount then return false end

    if Bridge.framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.Functions.RemoveMoney(account, amount, reason) or false
    elseif Bridge.framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.Functions.RemoveMoney(account, amount, reason) or false
    elseif Bridge.framework == 'esx' then
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        player.removeAccountMoney(account == 'cash' and 'money' or 'bank', amount, reason)
        return true
    end

    return false
end

---@param src number
---@param account 'cash'|'bank'
---@param amount number
---@param reason string
---@return boolean
function Bridge.addMoney(src, account, amount, reason)
    if amount <= 0 then return true end

    if Bridge.framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.Functions.AddMoney(account, amount, reason) or false
    elseif Bridge.framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.Functions.AddMoney(account, amount, reason) or false
    elseif Bridge.framework == 'esx' then
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        player.addAccountMoney(account == 'cash' and 'money' or 'bank', amount, reason)
        return true
    end

    return false
end

---@param src number
---@param message string
---@param type? string
function Bridge.notify(src, message, type)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Clothing',
        description = message,
        type = type or 'inform',
        position = 'top-right',
    })
end

-- ── Inventory (ox_inventory) ──────────────────────────────────────────────

local hasOx = GetResourceState('ox_inventory'):find('start') ~= nil

if not hasOx then
    lib.print.error('renzu_clothes requires ox_inventory. Start ox_inventory before this resource.')
end

---@param src number
---@param item string
---@param count integer
---@param metadata table|nil
---@return boolean
function Inv.addItem(src, item, count, metadata)
    if not hasOx then return false end
    local ok = exports.ox_inventory:AddItem(src, item, count or 1, metadata)
    return ok and true or false
end

---@param src number
---@param item string
---@param count integer
---@param metadata table|nil
---@param slot integer|nil
---@return boolean
function Inv.removeItem(src, item, count, metadata, slot)
    if not hasOx then return false end
    return exports.ox_inventory:RemoveItem(src, item, count or 1, metadata, slot) and true or false
end

---@param src number
---@param slot integer
---@return table|nil
function Inv.getSlot(src, slot)
    if not hasOx or not slot then return nil end
    return exports.ox_inventory:GetSlot(src, slot)
end

--- Every inventory slot holding this item.
---@param src number
---@param item string
---@return table[]
function Inv.search(src, item)
    if not hasOx then return {} end
    local result = exports.ox_inventory:Search(src, 'slots', item)
    return result or {}
end

---@param src number
---@param item string
---@param count integer
---@param metadata table|nil
---@return boolean
function Inv.canCarry(src, item, count, metadata)
    if not hasOx then return false end
    local ok = exports.ox_inventory:CanCarryItem(src, item, count or 1, metadata)
    return ok ~= false
end

--- Drops items on the ground (e.g. on death).
---@param coords vector3|table
---@param items table[] list of { item, count, metadata }
function Inv.createDrop(coords, items)
    if not hasOx or #items == 0 then return end

    local payload = {}
    for i = 1, #items do
        payload[#payload + 1] = {
            items[i].item,
            items[i].count or 1,
            items[i].metadata,
        }
    end

    pcall(function()
        exports.ox_inventory:CustomDrop(
            'Clothing',
            payload,
            vec3(coords.x, coords.y, coords.z),
            #payload + 1,
            100000
        )
    end)
end

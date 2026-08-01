-- Qbox server wrapper (renzu_engine)
-- Vervangt de oude ESX/QB-wrapper. Levert alleen wat server.lua gebruikt:
--   GetPlayerFromId(src)         - xPlayer met .job/.getMoney/.removeMoney/removeInventoryItem
--   GetPlayerFromIdentifier(cid) - idem, opgezocht via citizenid
--   RegisterUsableItem(item, cb) - via qbx_core:CreateUseableItem
--   Inventory.AddItem / RemoveItem - via ox_inventory

local function wrap(player, src)
    if not player then return end
    local pd = player.PlayerData
    src = src or pd.source
    return {
        source = src,
        identifier = pd.citizenid,
        citizenid = pd.citizenid,
        job = pd.job,
        getMoney = function()
            return pd.money['cash'] or 0
        end,
        addMoney = function(value)
            return player.Functions.AddMoney('cash', tonumber(value), 'renzu_engine')
        end,
        removeMoney = function(value)
            return player.Functions.RemoveMoney('cash', tonumber(value), 'renzu_engine')
        end,
        getAccount = function(t)
            if t == 'money' then t = 'cash' end
            return { money = pd.money[t] or 0 }
        end,
        addAccountMoney = function(t, value)
            if t == 'money' then t = 'cash' end
            return player.Functions.AddMoney(t, tonumber(value), 'renzu_engine')
        end,
        removeAccountMoney = function(t, value)
            if t == 'money' then t = 'cash' end
            return player.Functions.RemoveMoney(t, tonumber(value), 'renzu_engine')
        end,
        getGroup = function()
            return IsPlayerAceAllowed(src, 'group.admin') and 'admin' or 'user'
        end,
        addInventoryItem = function(item, amount, info, slot)
            return exports.ox_inventory:AddItem(src, item, amount, info, slot)
        end,
        removeInventoryItem = function(item, amount, slot)
            return exports.ox_inventory:RemoveItem(src, item, amount, nil, slot)
        end,
        getInventoryItem = function(item)
            local data = exports.ox_inventory:GetItem(src, item, nil, false)
            local count = data and data.count or 0
            return { count = count, amount = count }
        end,
    }
end

function GetPlayerFromId(src)
    return wrap(exports.qbx_core:GetPlayer(src), src)
end

function GetPlayerFromIdentifier(identifier)
    return wrap(exports.qbx_core:GetPlayerByCitizenId(identifier))
end

RegisterUsableItem = function(item, cb)
    exports.qbx_core:CreateUseableItem(item, cb)
end

Inventory.AddItem = function(source, item, count, metadata, slot)
    return exports.ox_inventory:AddItem(source, item, count, metadata, slot)
end

Inventory.RemoveItem = function(source, item, count, metadata, slot)
    return exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
end

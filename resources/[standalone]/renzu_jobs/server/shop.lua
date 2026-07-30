---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job shops

    Two flavours:
      public = false -> employees only, paid from the job treasury
      public = true  -> anybody may buy, the money lands in the job treasury
]]

--- Anti-spam: one purchase in flight per player.
local busy = {}

lib.callback.register('renzu_jobs:getShop', function(source, jobName, index)
    index = tonumber(index)
    local shop = Access.publicFeature(jobName, { 'shops', index })
    if not shop then return nil end
    if not Access.nearby(source, shop.coord, 8.0) then return nil end

    if not shop.public then
        local job = Bridge.getJob(source)
        if not job or job.name ~= jobName then return nil end
        if (shop.grade or 0) > job.grade then
            Bridge.notify(source, 'error', shop.label, 'Your rank does not have access to this shop.')
            return nil
        end
    end

    -- Send labels resolved through ox_inventory so the UI shows real item names
    -- even when the config label is out of date.
    local items = {}
    for i = 1, #shop.items do
        local item = shop.items[i]
        items[#items + 1] = {
            name  = item.name,
            label = item.label or Bridge.getItemLabel(item.name),
            price = tonumber(item.price) or 0,
            image = Bridge.normaliseItem(item.name),
        }
    end

    return {
        job     = jobName,
        index   = index,
        label   = shop.label,
        public  = shop.public == true,
        items   = items,
        balance = shop.public and Bridge.getMoney(source, Config.CashAccount)
                              or Db.getBalance(jobName, 'money'),
    }
end)

lib.callback.register('renzu_jobs:buyItem', function(source, jobName, index, itemName, amount)
    index  = tonumber(index)
    amount = math.floor(tonumber(amount) or 0)

    if busy[source] then
        Bridge.notify(source, 'warning', 'Shop', 'Hold on, your previous purchase is still going through.')
        return false
    end

    if amount <= 0 or amount > 100 then
        Bridge.notify(source, 'error', 'Shop', 'Pick an amount between 1 and 100.')
        return false
    end

    local shop = Access.publicFeature(jobName, { 'shops', index })
    if not shop then return false end
    if not Access.nearby(source, shop.coord, 8.0) then
        Bridge.notify(source, 'error', 'Shop', 'You walked away from the counter.')
        return false
    end

    local job = Bridge.getJob(source)
    if not shop.public then
        if not job or job.name ~= jobName or (shop.grade or 0) > job.grade then
            Bridge.notify(source, 'error', shop.label, 'You are not allowed to shop here.')
            return false
        end
    end

    -- The item must be in the configured list. Anything else is a faked NUI call.
    local entry
    for i = 1, #shop.items do
        if shop.items[i].name == itemName then entry = shop.items[i] break end
    end
    if not entry then
        lib.print.warn(('%s tried to buy "%s" which is not in shop %s/%s'):format(source, tostring(itemName), jobName, index))
        return false
    end

    local isWeapon = Bridge.isWeapon(entry.name)
    if isWeapon and amount > 1 then
        Bridge.notify(source, 'error', shop.label, 'Weapons can only be bought one at a time.')
        return false
    end

    local total = (tonumber(entry.price) or 0) * amount
    local label = entry.label or Bridge.getItemLabel(entry.name)

    busy[source] = true

    local ok = (function()
        if not Bridge.canCarry(source, entry.name, amount) then
            Bridge.notify(source, 'error', shop.label, 'You do not have room for that.')
            return false
        end

        if total > 0 then
            if shop.public then
                if Bridge.getMoney(source, Config.CashAccount) < total then
                    Bridge.notify(source, 'error', shop.label, ('That costs $%s and you do not have it on you.'):format(total))
                    return false
                end
                if not Bridge.removeMoney(source, Config.CashAccount, total, 'renzu_jobs:shop') then return false end
                Db.addBalance(jobName, 'money', total)
                Accounts.broadcast(jobName)
            else
                if not Db.removeBalance(jobName, 'money', total) then
                    Bridge.notify(source, 'error', shop.label, ('The company treasury cannot cover $%s.'):format(total))
                    return false
                end
                Accounts.broadcast(jobName)
            end
        end

        if not Bridge.addItem(source, entry.name, amount) then
            -- Give the money back, the item never arrived.
            if total > 0 then
                if shop.public then
                    Db.removeBalance(jobName, 'money', total)
                    Bridge.addMoney(source, Config.CashAccount, total, 'renzu_jobs:shop-refund')
                else
                    Db.addBalance(jobName, 'money', total)
                end
                Accounts.broadcast(jobName)
            end
            Bridge.notify(source, 'error', shop.label, 'The item could not be delivered. You were refunded.')
            return false
        end

        Bridge.notify(source, 'success', shop.label,
            total > 0 and ('Bought %dx %s for $%s.'):format(amount, label, total)
                       or ('Took %dx %s.'):format(amount, label))

        Logs.send({
            feature  = 'shop',
            webhook  = shop.webhook,
            title    = 'Shop purchase',
            severity = 'info',
            source   = source,
            fields   = {
                { name = 'Shop',  value = ('%s (%s)'):format(shop.label, jobName), inline = true },
                { name = 'Item',  value = ('%dx %s'):format(amount, label), inline = true },
                { name = 'Total', value = ('$%s'):format(total), inline = true },
            },
        })
        return true
    end)()

    busy[source] = nil
    return ok
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)

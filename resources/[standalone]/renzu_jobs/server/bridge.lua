---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - server bridge

    Everything framework specific lives here. The rest of the resource only ever
    talks to Bridge.*, so swapping frameworks later means touching one file.

    Target framework: QBox (qbx_core) + ox_inventory.
    The wrappers try the modern qbx_core exports first and fall back to the
    player object Functions, so this works across qbx_core versions.
]]

Bridge = {}

local core = exports.qbx_core

-- ─────────────────────────────────────────────────────────────────────────────
-- Players
-- ─────────────────────────────────────────────────────────────────────────────

---@param src number
---@return table? player qbx player object
function Bridge.getPlayer(src)
    if not src or src == 0 then return nil end
    local ok, player = pcall(function() return core:GetPlayer(src) end)
    if ok and player then return player end
    return nil
end

---@param citizenid string
---@return table? player online qbx player object
function Bridge.getPlayerByCitizenId(citizenid)
    if not citizenid then return nil end
    local ok, player = pcall(function() return core:GetPlayerByCitizenId(citizenid) end)
    if ok and player then return player end
    return nil
end

---@param citizenid string
---@return table? player offline player object (no source)
function Bridge.getOfflinePlayer(citizenid)
    if not citizenid then return nil end
    local ok, player = pcall(function() return core:GetOfflinePlayer(citizenid) end)
    if ok and player then return player end
    return nil
end

---@return number[] sources
function Bridge.getPlayers()
    local ok, players = pcall(function() return core:GetQBPlayers() end)
    if ok and type(players) == 'table' then
        local list = {}
        for src in pairs(players) do list[#list + 1] = tonumber(src) end
        return list
    end

    ok, players = pcall(function() return core:GetPlayers() end)
    if ok and type(players) == 'table' then return players end

    return GetPlayers()
end

---@param src number
---@return string? citizenid
function Bridge.getIdentifier(src)
    local player = Bridge.getPlayer(src)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

---@param player table qbx player object
---@return string
function Bridge.getFullName(player)
    local info = player and player.PlayerData and player.PlayerData.charinfo
    if not info then return 'Unknown' end
    return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s*(.-)%s*$', '%1')
end

--- Normalised job info. Grade is always the numeric LEVEL.
---@param src number
---@return { name: string, label: string, grade: number, gradeLabel: string, onduty: boolean }?
function Bridge.getJob(src)
    local player = Bridge.getPlayer(src)
    if not player or not player.PlayerData or not player.PlayerData.job then return nil end

    local job = player.PlayerData.job
    return {
        name       = job.name,
        label      = job.label or job.name,
        grade      = type(job.grade) == 'table' and (job.grade.level or 0) or (tonumber(job.grade) or 0),
        gradeLabel = type(job.grade) == 'table' and (job.grade.name or '') or '',
        onduty     = job.onduty == true,
        isboss     = job.isboss == true,
    }
end

---@param src number
---@param jobName string
---@param grade number
---@return boolean
function Bridge.setJob(src, jobName, grade)
    local ok, result = pcall(function() return core:SetJob(src, jobName, grade) end)
    if ok and result ~= false then return true end

    local player = Bridge.getPlayer(src)
    if player and player.Functions and player.Functions.SetJob then
        return player.Functions.SetJob(jobName, grade) ~= false
    end
    return false
end

--- Change the job of a player that is not connected. Writes the `players.job`
--- JSON column directly because qbx_core has no offline setter.
---@param citizenid string
---@param jobName string
---@param grade number
---@return boolean
function Bridge.setJobOffline(citizenid, jobName, grade)
    local jobs = Bridge.getJobs()
    local jobData = jobs and jobs[jobName]
    if not jobData then return false end

    local gradeData = jobData.grades and (jobData.grades[grade] or jobData.grades[tostring(grade)])
    if not gradeData then return false end

    local payload = json.encode({
        name    = jobName,
        label   = jobData.label or jobName,
        payment = gradeData.payment or 0,
        onduty  = jobData.defaultDuty ~= false,
        isboss  = gradeData.isboss == true,
        type    = jobData.type,
        grade   = {
            name    = gradeData.name or tostring(grade),
            level   = grade,
            payment = gradeData.payment or 0,
        },
    })

    local affected = MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { payload, citizenid })
    return (affected or 0) > 0
end

---@param src number
---@param onDuty boolean
function Bridge.setDuty(src, onDuty)
    local ok = pcall(function() return core:SetJobDuty(src, onDuty) end)
    if ok then return true end

    local player = Bridge.getPlayer(src)
    if player and player.Functions and player.Functions.SetJobDuty then
        player.Functions.SetJobDuty(onDuty)
        return true
    end
    return false
end

---@return table jobs shared job list from qbx_core
function Bridge.getJobs()
    local ok, jobs = pcall(function() return core:GetJobs() end)
    if ok and type(jobs) == 'table' then return jobs end
    return {}
end

---@param src number
---@return boolean
function Bridge.isAdmin(src)
    -- qbx_core owns the permission groups, ask it first.
    local ok, has = pcall(function() return core:HasPermission(src, Config.AdminGroups) end)
    if ok and has == true then return true end

    -- Fall back to plain aces so this still works without qbx permissions set up.
    for _, group in ipairs(Config.AdminGroups) do
        if IsPlayerAceAllowed(src, ('group.%s'):format(group)) then return true end
    end

    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Money
-- ─────────────────────────────────────────────────────────────────────────────

---@param src number
---@param account string 'cash' | 'bank'
---@return number
function Bridge.getMoney(src, account)
    local player = Bridge.getPlayer(src)
    if not player then return 0 end

    if player.Functions and player.Functions.GetMoney then
        return tonumber(player.Functions.GetMoney(account)) or 0
    end
    return tonumber(player.PlayerData and player.PlayerData.money and player.PlayerData.money[account]) or 0
end

---@param src number
---@param account string
---@param amount number
---@param reason string
---@return boolean
function Bridge.addMoney(src, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.getPlayer(src)
    if not player or not player.Functions then return false end
    return player.Functions.AddMoney(account, amount, reason or 'renzu_jobs') ~= false
end

---@param src number
---@param account string
---@param amount number
---@param reason string
---@return boolean
function Bridge.removeMoney(src, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.getPlayer(src)
    if not player or not player.Functions then return false end
    return player.Functions.RemoveMoney(account, amount, reason or 'renzu_jobs') ~= false
end

--- Deposit money into an offline player's bank balance.
---@param citizenid string
---@param amount number
---@return boolean
function Bridge.addMoneyOffline(citizenid, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local row = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', { citizenid })
    if not row then return false end

    local money = json.decode(row.money) or {}
    money[Config.BankAccount] = (tonumber(money[Config.BankAccount]) or 0) + amount

    local affected = MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', {
        json.encode(money), citizenid,
    })
    return (affected or 0) > 0
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Inventory (ox_inventory)
-- ─────────────────────────────────────────────────────────────────────────────

local inventory = exports.ox_inventory

---@param name string
---@return boolean
function Bridge.isWeapon(name)
    return type(name) == 'string' and name:upper():find('^WEAPON_') ~= nil
end

--- ox_inventory item names are always lowercase.
---@param name string
---@return string
function Bridge.normaliseItem(name)
    return type(name) == 'string' and name:lower() or ''
end

---@param name string
---@return table? item definition from ox_inventory
function Bridge.getItemData(name)
    local items = inventory:Items()
    return items and items[Bridge.normaliseItem(name)] or nil
end

---@param name string
---@return string label
function Bridge.getItemLabel(name)
    local item = Bridge.getItemData(name)
    return item and item.label or name
end

---@param src number
---@param item string
---@return number count
function Bridge.getItemCount(src, item)
    local count = inventory:Search(src, 'count', Bridge.normaliseItem(item))
    return tonumber(count) or 0
end

---@param src number
---@param item string
---@param count number
---@return boolean
function Bridge.canCarry(src, item, count)
    local ok, result = pcall(function()
        return inventory:CanCarryItem(src, Bridge.normaliseItem(item), count)
    end)
    return ok and result == true
end

---@param src number
---@param item string
---@param count number
---@param metadata table?
---@return boolean
function Bridge.addItem(src, item, count, metadata)
    local ok, result = pcall(function()
        return inventory:AddItem(src, Bridge.normaliseItem(item), count, metadata)
    end)
    return ok and result ~= false
end

---@param src number
---@param item string
---@param count number
---@param metadata table?
---@return boolean
function Bridge.removeItem(src, item, count, metadata)
    local ok, result = pcall(function()
        return inventory:RemoveItem(src, Bridge.normaliseItem(item), count, metadata)
    end)
    return ok and result ~= false
end

---@param src number
---@return table[] weapons currently in the player inventory
function Bridge.getWeapons(src)
    local slots = inventory:GetInventoryItems(src)
    local weapons = {}
    if not slots then return weapons end

    for _, slot in pairs(slots) do
        if slot and slot.name and Bridge.isWeapon(slot.name) then
            weapons[#weapons + 1] = slot
        end
    end
    return weapons
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Notifications
-- ─────────────────────────────────────────────────────────────────────────────

--- Central notify. Every server side message goes through here so the styling
--- stays consistent and a single change updates the whole resource.
---@param src number  target player, or -1 for everybody
---@param type string 'success' | 'error' | 'warning' | 'inform'
---@param title string
---@param description string
---@param duration number?
function Bridge.notify(src, type, title, description, duration)
    TriggerClientEvent('renzu_jobs:notify', src, {
        type        = type,
        title       = title,
        description = description,
        duration    = duration or Config.Notify.duration,
    })
end

--- Server wide announcement with a longer duration.
function Bridge.announce(type, title, description)
    TriggerClientEvent('renzu_jobs:notify', -1, {
        type        = type,
        title       = title,
        description = description,
        duration    = Config.Notify.announceDuration,
    })
end

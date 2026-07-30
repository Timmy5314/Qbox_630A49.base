---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job treasury + permission helpers

    Access.* is the single place that decides whether a player may do something.
    Every callback in this resource validates through it, so a client that fakes
    a NUI message still gets nowhere.
]]

Access = {}

--- Permission flags for a grade, merged downwards: a grade inherits nothing, so
--- config lists them explicitly, but a missing grade falls back to the highest
--- configured grade that is still <= the player grade.
---@param job string
---@param grade number
---@return table flags
function Access.flags(job, grade)
    local jobConfig = Config.Jobs[job]
    if not jobConfig or not jobConfig.grades then return {} end

    local exact = jobConfig.grades[grade]
    if exact then return exact end

    local best, bestLevel = {}, -1
    for level, flags in pairs(jobConfig.grades) do
        if level <= grade and level > bestLevel then
            best, bestLevel = flags, level
        end
    end
    return best
end

--- Does this player hold a boss-menu permission?
---@param src number
---@param flag string
---@return boolean allowed, table? job
function Access.has(src, flag)
    local job = Bridge.getJob(src)
    if not job then return false, nil end

    local jobConfig = Config.Jobs[job.name]
    if not jobConfig then return false, job end

    return Access.flags(job.name, job.grade)[flag] == true, job
end

--- Grade check against a feature block (bossmenu / armory / garage / ...).
---@param src number
---@param featurePath string|string[] e.g. 'armory' or {'stashes','Boss'}
---@return boolean allowed, table? job, table? feature
function Access.feature(src, featurePath)
    local job = Bridge.getJob(src)
    if not job then return false, nil, nil end

    local jobConfig = Config.Jobs[job.name]
    if not jobConfig then return false, job, nil end

    local node = jobConfig
    if type(featurePath) == 'table' then
        for _, key in ipairs(featurePath) do
            node = node and node[key]
        end
    else
        node = jobConfig[featurePath]
    end

    if not node then return false, job, nil end
    if (node.grade or 0) > job.grade then return false, job, node end

    return true, job, node
end

--- Feature lookup for a specific job (used by public shops and public stashes,
--- where the player does not need to work there).
---@param jobName string
---@param featurePath string|string[]
---@return table? feature
function Access.publicFeature(jobName, featurePath)
    local jobConfig = Config.Jobs[jobName]
    if not jobConfig then return nil end

    local node = jobConfig
    if type(featurePath) == 'table' then
        for _, key in ipairs(featurePath) do
            node = node and node[key]
        end
    else
        node = jobConfig[featurePath]
    end
    return node
end

--- Distance check so a player cannot fire a callback from across the map.
---@param src number
---@param coord vector3|vector4
---@param maxDistance number?
---@return boolean
function Access.nearby(src, coord, maxDistance)
    if not coord then return true end

    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local target = vec3(coord.x, coord.y, coord.z)
    return #(GetEntityCoords(ped) - target) <= (maxDistance or 10.0)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Treasury exports (kept compatible with renzu_jobs 1.x)
-- ─────────────────────────────────────────────────────────────────────────────

---@param job string
---@return table accounts
exports('JobMoney', function(job)
    return Db.getAccounts(job)
end)

---@param amount number
---@param job string
---@param _src number? unused, kept for signature compatibility
---@param moneyType string?
---@return boolean
exports('addMoney', function(amount, job, _src, moneyType)
    local ok = Db.addBalance(job, moneyType or 'money', amount)
    if ok then Accounts.broadcast(job) end
    return ok
end)

---@param amount number
---@param job string
---@param _src number?
---@param moneyType string?
---@return boolean
exports('removeMoney', function(amount, job, _src, moneyType)
    local ok = Db.removeBalance(job, moneyType or 'money', amount)
    if ok then Accounts.broadcast(job) end
    return ok
end)

---@param job string
---@param account string
---@param amount number
---@return boolean
exports('canAfford', function(job, account, amount)
    return Db.getBalance(job, account or 'money') >= (tonumber(amount) or 0)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Live balance updates
-- ─────────────────────────────────────────────────────────────────────────────

Accounts = {}

--- Push the current treasury to every employee that has the boss menu open.
---@param job string
function Accounts.broadcast(job)
    if not job then return end

    local accounts = Db.getAccounts(job)
    for _, src in ipairs(Bridge.getPlayers()) do
        local playerJob = Bridge.getJob(src)
        if playerJob and playerJob.name == job then
            TriggerClientEvent('renzu_jobs:updateAccounts', src, accounts)
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Withdraw / deposit
-- ─────────────────────────────────────────────────────────────────────────────

--- Move money between the player and the job treasury.
--- direction: 'withdraw' takes from the job, 'deposit' gives to the job.
lib.callback.register('renzu_jobs:transfer', function(source, direction, account, amount)
    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        Bridge.notify(source, 'error', 'Job Treasury', 'Enter an amount above zero.')
        return false
    end

    local flag = direction == 'withdraw' and 'withdraw' or 'deposit'
    local allowed, job = Access.has(source, flag)

    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Job Treasury', ('Your rank is not allowed to %s company funds.'):format(flag))
        return false
    end

    local isBlackMoney = account == 'black_money'

    if direction == 'withdraw' then
        if Db.getBalance(job.name, account) < amount then
            Bridge.notify(source, 'error', 'Job Treasury',
                ('The company only has $%s in %s.'):format(Db.getBalance(job.name, account), account == 'money' and 'cash' or 'black money'))
            return false
        end

        -- Take from the treasury first, hand out second, refund on failure.
        if not Db.removeBalance(job.name, account, amount) then return false end

        local delivered
        if isBlackMoney then
            if not Config.BlackMoneyItem then
                Db.addBalance(job.name, account, amount)
                return false
            end
            delivered = Bridge.canCarry(source, Config.BlackMoneyItem, amount)
                and Bridge.addItem(source, Config.BlackMoneyItem, amount)
        else
            delivered = Bridge.addMoney(source, Config.CashAccount, amount, 'renzu_jobs:withdraw')
        end

        if not delivered then
            Db.addBalance(job.name, account, amount)
            Bridge.notify(source, 'error', 'Job Treasury', 'You cannot carry that much. Nothing was withdrawn.')
            return false
        end

        Accounts.broadcast(job.name)
        Bridge.notify(source, 'success', 'Job Treasury',
            ('Withdrew $%s from the %s account.'):format(amount, isBlackMoney and 'black money' or 'cash'))

        Logs.money('bossmenu', source, 'Treasury withdrawal', amount, {
            { name = 'Account', value = account, inline = true },
            { name = 'Company', value = job.label, inline = true },
        })
        return true
    end

    -- deposit
    local taken
    if isBlackMoney then
        if not Config.BlackMoneyItem then return false end
        if Bridge.getItemCount(source, Config.BlackMoneyItem) < amount then
            Bridge.notify(source, 'error', 'Job Treasury', 'You do not have that much black money on you.')
            return false
        end
        taken = Bridge.removeItem(source, Config.BlackMoneyItem, amount)
    else
        if Bridge.getMoney(source, Config.CashAccount) < amount then
            Bridge.notify(source, 'error', 'Job Treasury', 'You do not have that much cash on you.')
            return false
        end
        taken = Bridge.removeMoney(source, Config.CashAccount, amount, 'renzu_jobs:deposit')
    end

    if not taken then
        Bridge.notify(source, 'error', 'Job Treasury', 'The deposit failed, nothing was taken.')
        return false
    end

    Db.addBalance(job.name, account, amount)
    Accounts.broadcast(job.name)

    Bridge.notify(source, 'success', 'Job Treasury',
        ('Deposited $%s into the %s account.'):format(amount, isBlackMoney and 'black money' or 'cash'))

    Logs.money('bossmenu', source, 'Treasury deposit', amount, {
        { name = 'Account', value = account, inline = true },
        { name = 'Company', value = job.label, inline = true },
    })
    return true
end)

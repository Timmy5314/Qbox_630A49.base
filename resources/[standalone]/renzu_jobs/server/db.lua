---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - database layer

    Creates the schema on boot and keeps the job treasury in memory so the boss
    menu does not hit MySQL on every single interaction. Writes are still
    immediate, reads come from cache.
]]

Db = {}

--- job name -> { money = n, black_money = n }
local accountCache = {}
local ready = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Schema
-- ─────────────────────────────────────────────────────────────────────────────

local schema = {
    [[CREATE TABLE IF NOT EXISTS `renzu_jobs` (
        `name`     VARCHAR(64) NOT NULL,
        `accounts` LONGTEXT NULL,
        PRIMARY KEY (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci]],

    [[CREATE TABLE IF NOT EXISTS `renzu_jobs_vehicles` (
        `plate`      VARCHAR(12)  NOT NULL,
        `job`        VARCHAR(64)  NOT NULL,
        `garage`     VARCHAR(64)  NOT NULL DEFAULT 'main',
        `model`      VARCHAR(64)  NOT NULL,
        `label`      VARCHAR(64)  NULL,
        `props`      LONGTEXT     NULL,
        `stored`     TINYINT(1)   NOT NULL DEFAULT 1,
        `taken_by`   VARCHAR(64)  NULL,
        `taken_at`   INT(11)      NULL,
        `created_at` INT(11)      NULL,
        PRIMARY KEY (`plate`),
        KEY `idx_job_garage` (`job`, `garage`),
        KEY `idx_stored` (`stored`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci]],

    [[CREATE TABLE IF NOT EXISTS `renzu_jobs_turfs` (
        `turf`        VARCHAR(64) NOT NULL,
        `owner`       VARCHAR(64) NULL,
        `owner_label` VARCHAR(64) NULL,
        `claimed_at`  INT(11)     NULL,
        `vault_at`    INT(11)     NULL,
        PRIMARY KEY (`turf`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci]],

    [[CREATE TABLE IF NOT EXISTS `renzu_jobs_salaries` (
        `job`    VARCHAR(64) NOT NULL,
        `grade`  INT(11)     NOT NULL,
        `salary` INT(11)     NOT NULL DEFAULT 0,
        PRIMARY KEY (`job`, `grade`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci]],
}

---@return boolean
function Db.isReady()
    return ready
end

--- Blocks the calling coroutine until the schema is up and the cache is warm.
function Db.await()
    local attempts = 0
    while not ready and attempts < 300 do
        Wait(100)
        attempts = attempts + 1
    end
    return ready
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Job treasury
-- ─────────────────────────────────────────────────────────────────────────────

---@param job string
---@return table accounts
local function defaultAccounts()
    local accounts = {}
    for _, account in ipairs(Config.JobAccounts) do
        accounts[account.name] = 0
    end
    return accounts
end

---@param job string
---@return table accounts { money = n, black_money = n }
function Db.getAccounts(job)
    if not job then return defaultAccounts() end

    local cached = accountCache[job]
    if cached then return cached end

    local row = MySQL.single.await('SELECT accounts FROM renzu_jobs WHERE name = ?', { job })
    local accounts = row and json.decode(row.accounts or '{}') or defaultAccounts()

    -- Backfill any account added to the config after the row was created.
    for _, account in ipairs(Config.JobAccounts) do
        accounts[account.name] = tonumber(accounts[account.name]) or 0
    end

    accountCache[job] = accounts
    return accounts
end

---@param job string
---@param account string
---@return number
function Db.getBalance(job, account)
    return tonumber(Db.getAccounts(job)[account]) or 0
end

---@param job string
---@param accounts table
local function persistAccounts(job, accounts)
    accountCache[job] = accounts
    MySQL.prepare('INSERT INTO renzu_jobs (name, accounts) VALUES (?, ?) ON DUPLICATE KEY UPDATE accounts = VALUES(accounts)', {
        job, json.encode(accounts),
    })
end

--- Add money to a job treasury.
---@param job string
---@param account string
---@param amount number
---@return boolean ok, number balance
function Db.addBalance(job, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not job or amount <= 0 then return false, Db.getBalance(job, account) end

    local accounts = Db.getAccounts(job)
    accounts[account] = (tonumber(accounts[account]) or 0) + amount
    persistAccounts(job, accounts)

    return true, accounts[account]
end

--- Remove money from a job treasury. Fails (and changes nothing) when the
--- treasury cannot cover the amount, so callers never have to pre-check.
---@param job string
---@param account string
---@param amount number
---@return boolean ok, number balance
function Db.removeBalance(job, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not job or amount <= 0 then return false, Db.getBalance(job, account) end

    local accounts = Db.getAccounts(job)
    local balance = tonumber(accounts[account]) or 0
    if balance < amount then return false, balance end

    accounts[account] = balance - amount
    persistAccounts(job, accounts)

    return true, accounts[account]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Employees
-- ─────────────────────────────────────────────────────────────────────────────

--- Every character that currently holds this job. One indexed query instead of
--- pulling the whole players table like the old version did.
---@param job string
---@return table[] employees
function Db.getEmployees(job)
    local rows = MySQL.query.await([[
        SELECT citizenid, charinfo, job
        FROM players
        WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ?
    ]], { job }) or {}

    local employees = {}
    for i = 1, #rows do
        local row = rows[i]
        local charinfo = json.decode(row.charinfo or '{}') or {}
        local jobData  = json.decode(row.job or '{}') or {}
        local grade    = jobData.grade or {}

        employees[#employees + 1] = {
            citizenid  = row.citizenid,
            firstname  = charinfo.firstname or 'Unknown',
            lastname   = charinfo.lastname or '',
            grade      = tonumber(grade.level) or 0,
            gradeLabel = grade.name or tostring(grade.level or 0),
        }
    end

    return employees
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Job vehicles
-- ─────────────────────────────────────────────────────────────────────────────

---@param job string
---@param garage string
---@return table[] vehicles
function Db.getJobVehicles(job, garage)
    return MySQL.query.await(
        'SELECT plate, job, garage, model, label, props, stored, taken_by FROM renzu_jobs_vehicles WHERE job = ? AND garage = ?',
        { job, garage }
    ) or {}
end

---@param plate string
---@return table? vehicle
function Db.getJobVehicle(plate)
    return MySQL.single.await('SELECT * FROM renzu_jobs_vehicles WHERE plate = ?', { plate })
end

---@param data table
---@return boolean
function Db.createJobVehicle(data)
    local affected = MySQL.insert.await([[
        INSERT INTO renzu_jobs_vehicles (plate, job, garage, model, label, props, stored, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    ]], {
        data.plate, data.job, data.garage, data.model, data.label,
        json.encode(data.props or {}), os.time(),
    })
    return affected ~= nil
end

--- Flip a vehicle to "out of the garage". Returns false when somebody else beat
--- us to it, which is what stops the vehicle from being duplicated.
---@param plate string
---@param citizenid string
---@return boolean
function Db.checkoutVehicle(plate, citizenid)
    local affected = MySQL.update.await(
        'UPDATE renzu_jobs_vehicles SET stored = 0, taken_by = ?, taken_at = ? WHERE plate = ? AND stored = 1',
        { citizenid, os.time(), plate }
    )
    return (affected or 0) > 0
end

---@param plate string
---@param props table
---@return boolean
function Db.storeVehicle(plate, props)
    local affected = MySQL.update.await(
        'UPDATE renzu_jobs_vehicles SET stored = 1, taken_by = NULL, taken_at = NULL, props = ? WHERE plate = ?',
        { json.encode(props or {}), plate }
    )
    return (affected or 0) > 0
end

--- Force every vehicle of a job back into its garage.
---@param job string?
---@return number affected
function Db.returnAllVehicles(job)
    if job then
        return MySQL.update.await(
            'UPDATE renzu_jobs_vehicles SET stored = 1, taken_by = NULL, taken_at = NULL WHERE job = ? AND stored = 0',
            { job }
        ) or 0
    end
    return MySQL.update.await(
        'UPDATE renzu_jobs_vehicles SET stored = 1, taken_by = NULL, taken_at = NULL WHERE stored = 0'
    ) or 0
end

--- Return vehicles that have been out longer than `minutes` and are not being
--- driven by anyone. Keeps a fleet from leaking after crashes and disconnects.
---@param minutes number
---@return number affected
function Db.returnStaleVehicles(minutes)
    if not minutes or minutes <= 0 then return 0 end
    return MySQL.update.await(
        'UPDATE renzu_jobs_vehicles SET stored = 1, taken_by = NULL, taken_at = NULL WHERE stored = 0 AND taken_at IS NOT NULL AND taken_at < ?',
        { os.time() - (minutes * 60) }
    ) or 0
end

---@param plate string
---@return boolean
function Db.plateExists(plate)
    local row = MySQL.scalar.await('SELECT 1 FROM renzu_jobs_vehicles WHERE plate = ?', { plate })
    if row then return true end

    -- Also avoid colliding with player owned vehicles when that table exists.
    local ok, owned = pcall(function()
        return MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate })
    end)
    return ok and owned ~= nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Turfs
-- ─────────────────────────────────────────────────────────────────────────────

---@return table<string, table> turfs
function Db.getTurfs()
    local rows = MySQL.query.await('SELECT * FROM renzu_jobs_turfs') or {}
    local turfs = {}
    for i = 1, #rows do
        local row = rows[i]
        if row.owner then
            turfs[row.turf] = {
                owner      = row.owner,
                ownerLabel = row.owner_label,
                claimedAt  = row.claimed_at,
                vaultAt    = row.vault_at,
            }
        end
    end
    return turfs
end

---@param turf string
---@param owner string?
---@param ownerLabel string?
function Db.setTurfOwner(turf, owner, ownerLabel)
    if not owner then
        MySQL.prepare('DELETE FROM renzu_jobs_turfs WHERE turf = ?', { turf })
        return
    end

    MySQL.prepare([[
        INSERT INTO renzu_jobs_turfs (turf, owner, owner_label, claimed_at, vault_at)
        VALUES (?, ?, ?, ?, NULL)
        ON DUPLICATE KEY UPDATE owner = VALUES(owner), owner_label = VALUES(owner_label),
                                claimed_at = VALUES(claimed_at), vault_at = NULL
    ]], { turf, owner, ownerLabel, os.time() })
end

---@param turf string
function Db.markVaultClaimed(turf)
    MySQL.prepare('UPDATE renzu_jobs_turfs SET vault_at = ? WHERE turf = ?', { os.time(), turf })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Boot
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    for i = 1, #schema do
        MySQL.query.await(schema[i])
    end

    -- Make sure every configured job has a treasury row and warm the cache.
    for job in pairs(Config.Jobs) do
        MySQL.prepare.await('INSERT IGNORE INTO renzu_jobs (name, accounts) VALUES (?, ?)', {
            job, json.encode(defaultAccounts()),
        })
    end

    local rows = MySQL.query.await('SELECT name, accounts FROM renzu_jobs') or {}
    for i = 1, #rows do
        local accounts = json.decode(rows[i].accounts or '{}') or {}
        for _, account in ipairs(Config.JobAccounts) do
            accounts[account.name] = tonumber(accounts[account.name]) or 0
        end
        accountCache[rows[i].name] = accounts
    end

    -- Anything left "out" after a server restart is put back in the garage.
    local recovered = Db.returnAllVehicles(nil)
    if recovered > 0 then
        lib.print.info(('returned %d job vehicle(s) to their garage after restart'):format(recovered))
    end

    ready = true
    lib.print.info('database ready')
end)

--- Periodic cleanup of vehicles nobody brought back.
CreateThread(function()
    local minutes = Config.Garage.autoReturnMinutes
    if not minutes or minutes <= 0 then return end

    while true do
        Wait(300000) -- every 5 minutes
        if ready then
            local affected = Db.returnStaleVehicles(minutes)
            if affected > 0 then
                lib.print.info(('auto-returned %d idle job vehicle(s)'):format(affected))
            end
        end
    end
end)

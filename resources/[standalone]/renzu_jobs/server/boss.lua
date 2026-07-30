---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - boss menu

    Employee management, promotions, hiring, firing, bonuses and salaries.
    Salaries live in renzu_jobs_salaries and default to the `payment` value from
    qbx_core/shared/jobs.lua, so nothing breaks if you never touch them.
]]

Boss = {}

--- job -> { [grade] = salary }
local salaryCache = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Salaries
-- ─────────────────────────────────────────────────────────────────────────────

--- Grades of a job, taken from qbx_core, with our salary overrides applied.
---@param jobName string
---@return table[] grades sorted by level
function Boss.getGrades(jobName)
    local jobs = Bridge.getJobs()
    local jobData = jobs[jobName]
    local overrides = salaryCache[jobName] or {}

    local grades = {}
    if jobData and jobData.grades then
        for level, grade in pairs(jobData.grades) do
            level = tonumber(level) or 0
            grades[#grades + 1] = {
                level  = level,
                label  = grade.name or ('Grade %d'):format(level),
                salary = tonumber(overrides[level]) or tonumber(grade.payment) or 0,
            }
        end
    else
        -- qbx_core does not know this job; fall back to whatever renzu_jobs knows.
        local jobConfig = Config.Jobs[jobName]
        if jobConfig and jobConfig.grades then
            for level in pairs(jobConfig.grades) do
                grades[#grades + 1] = {
                    level  = level,
                    label  = ('Grade %d'):format(level),
                    salary = tonumber(overrides[level]) or 0,
                }
            end
        end
    end

    table.sort(grades, function(a, b) return a.level < b.level end)
    return grades
end

---@param jobName string
---@param grade number
---@return number
function Boss.getSalary(jobName, grade)
    for _, entry in ipairs(Boss.getGrades(jobName)) do
        if entry.level == grade then return entry.salary end
    end
    return 0
end

local function loadSalaries()
    local rows = MySQL.query.await('SELECT job, grade, salary FROM renzu_jobs_salaries') or {}
    salaryCache = {}
    for i = 1, #rows do
        local row = rows[i]
        salaryCache[row.job] = salaryCache[row.job] or {}
        salaryCache[row.job][tonumber(row.grade)] = tonumber(row.salary)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Menu data
-- ─────────────────────────────────────────────────────────────────────────────

---@param index number
---@return table avatar colours
local function avatarFor(citizenid)
    -- Deterministic colour per character so the list does not reshuffle on every
    -- refresh the way the old random pick did.
    local sum = 0
    for i = 1, #citizenid do sum = sum + citizenid:byte(i) end
    return Config.RandomAvatars[(sum % #Config.RandomAvatars) + 1]
end

lib.callback.register('renzu_jobs:getBossData', function(source)
    local allowed, job, feature = Access.feature(source, 'bossmenu')
    if not job then return nil end

    if not allowed then
        Bridge.notify(source, 'error', 'Boss Menu', 'Your rank does not have access to the boss office.')
        return nil
    end
    if not Access.nearby(source, feature.coord, 12.0) then return nil end

    local flags = Access.flags(job.name, job.grade)

    -- Online lookup once, instead of a query per employee.
    local onlineByCid = {}
    for _, src in ipairs(Bridge.getPlayers()) do
        local cid = Bridge.getIdentifier(src)
        if cid then onlineByCid[cid] = src end
    end

    local employees = {}
    for _, row in ipairs(Db.getEmployees(job.name)) do
        local colours = avatarFor(row.citizenid)
        employees[#employees + 1] = {
            citizenid  = row.citizenid,
            name       = ('%s %s'):format(row.firstname, row.lastname),
            grade      = row.grade,
            gradeLabel = row.gradeLabel,
            online     = onlineByCid[row.citizenid] ~= nil,
            image      = ('https://ui-avatars.com/api/?name=%s+%s&background=%s&color=%s')
                            :format(row.firstname, row.lastname, colours.background, colours.color),
        }
    end

    table.sort(employees, function(a, b)
        if a.grade ~= b.grade then return a.grade > b.grade end
        return a.name < b.name
    end)

    -- Candidates for hiring: players standing close by who do not work here.
    local nearby = {}
    local myCoords = GetEntityCoords(GetPlayerPed(source))
    for _, src in ipairs(Bridge.getPlayers()) do
        if src ~= source then
            local otherJob = Bridge.getJob(src)
            if otherJob and otherJob.name ~= job.name then
                local ped = GetPlayerPed(src)
                if ped ~= 0 and #(myCoords - GetEntityCoords(ped)) < 15.0 then
                    local player = Bridge.getPlayer(src)
                    nearby[#nearby + 1] = {
                        citizenid = player.PlayerData.citizenid,
                        name      = Bridge.getFullName(player),
                        serverId  = src,
                    }
                end
            end
        end
    end

    return {
        job = {
            name  = job.name,
            label = job.label,
            grade = job.grade,
        },
        accounts    = Db.getAccounts(job.name),
        permissions = flags,
        employees   = employees,
        grades      = Boss.getGrades(job.name),
        nearby      = nearby,
        maxSalary   = Config.Jobs[job.name].maxSalary or 0,
        accountList = Config.JobAccounts,
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Promote / demote
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:setGrade', function(source, citizenid, grade)
    grade = tonumber(grade)
    if not citizenid or not grade then return false end

    local allowed, job = Access.has(source, 'gradechange')
    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Boss Menu', 'Your rank cannot change grades.')
        return false
    end

    -- Never let somebody promote another player to or above their own rank.
    if grade >= job.grade then
        Bridge.notify(source, 'error', 'Boss Menu', 'You cannot promote somebody to your own rank or higher.')
        return false
    end

    local gradeExists = false
    local gradeLabel = tostring(grade)
    for _, entry in ipairs(Boss.getGrades(job.name)) do
        if entry.level == grade then
            gradeExists, gradeLabel = true, entry.label
            break
        end
    end
    if not gradeExists then
        Bridge.notify(source, 'error', 'Boss Menu', 'That grade does not exist for this job.')
        return false
    end

    local target = Bridge.getPlayerByCitizenId(citizenid)
    local actorName = Bridge.getFullName(Bridge.getPlayer(source))

    if target then
        local currentGrade = type(target.PlayerData.job.grade) == 'table'
            and target.PlayerData.job.grade.level or 0

        if target.PlayerData.job.name ~= job.name then
            Bridge.notify(source, 'error', 'Boss Menu', 'That person no longer works here.')
            return false
        end
        if currentGrade >= job.grade then
            Bridge.notify(source, 'error', 'Boss Menu', 'You cannot change the rank of somebody at or above your own.')
            return false
        end

        if not Bridge.setJob(target.PlayerData.source, job.name, grade) then
            Bridge.notify(source, 'error', 'Boss Menu', 'Changing the grade failed.')
            return false
        end

        local promoted = grade > currentGrade
        Bridge.notify(source, 'success', 'Boss Menu',
            ('%s %s to %s.'):format(promoted and 'Promoted' or 'Demoted', Bridge.getFullName(target), gradeLabel))
        Bridge.notify(target.PlayerData.source, promoted and 'success' or 'warning', job.label,
            ('You have been %s to %s by %s.'):format(promoted and 'promoted' or 'demoted', gradeLabel, actorName))
    else
        if not Bridge.setJobOffline(citizenid, job.name, grade) then
            Bridge.notify(source, 'error', 'Boss Menu', 'Could not update that offline employee.')
            return false
        end
        Bridge.notify(source, 'success', 'Boss Menu', ('Set the offline employee to %s.'):format(gradeLabel))
    end

    Logs.send({
        feature  = 'bossmenu',
        webhook  = Config.Jobs[job.name].bossmenu and Config.Jobs[job.name].bossmenu.webhook,
        title    = 'Grade changed',
        severity = 'info',
        source   = source,
        fields   = {
            { name = 'Target',    value = ('`%s`'):format(citizenid), inline = true },
            { name = 'New grade', value = ('%s (%d)'):format(gradeLabel, grade), inline = true },
        },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Hire
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:hire', function(source, targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return false end

    local allowed, job = Access.has(source, 'hire')
    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Boss Menu', 'Your rank cannot hire people.')
        return false
    end

    local target = Bridge.getPlayer(targetSrc)
    if not target then
        Bridge.notify(source, 'error', 'Boss Menu', 'That player is no longer online.')
        return false
    end

    -- Distance check: hiring is a face to face action.
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetSrc))) > 15.0 then
        Bridge.notify(source, 'error', 'Boss Menu', 'That person is too far away.')
        return false
    end

    if target.PlayerData.job.name == job.name then
        Bridge.notify(source, 'error', 'Boss Menu', 'They already work here.')
        return false
    end

    if not Bridge.setJob(targetSrc, job.name, 0) then
        Bridge.notify(source, 'error', 'Boss Menu', 'Hiring failed. Is the job configured in qbx_core?')
        return false
    end

    local actorName = Bridge.getFullName(Bridge.getPlayer(source))
    Bridge.notify(source, 'success', 'Boss Menu', ('Hired %s.'):format(Bridge.getFullName(target)))
    Bridge.notify(targetSrc, 'success', job.label, ('%s hired you. Welcome aboard.'):format(actorName))

    Logs.send({
        feature  = 'bossmenu',
        webhook  = Config.Jobs[job.name].bossmenu and Config.Jobs[job.name].bossmenu.webhook,
        title    = 'Employee hired',
        severity = 'success',
        source   = source,
        fields   = {
            { name = 'Hired', value = ('%s\n`%s`'):format(Bridge.getFullName(target), target.PlayerData.citizenid), inline = true },
        },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Fire
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:fire', function(source, citizenid)
    if not citizenid then return false end

    local allowed, job = Access.has(source, 'fire')
    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Boss Menu', 'Your rank cannot fire people.')
        return false
    end

    if citizenid == Bridge.getIdentifier(source) then
        Bridge.notify(source, 'error', 'Boss Menu', 'You cannot fire yourself.')
        return false
    end

    local target = Bridge.getPlayerByCitizenId(citizenid)
    local actorName = Bridge.getFullName(Bridge.getPlayer(source))

    if target then
        local targetGrade = type(target.PlayerData.job.grade) == 'table'
            and target.PlayerData.job.grade.level or 0

        if targetGrade >= job.grade then
            Bridge.notify(source, 'error', 'Boss Menu', 'You cannot fire somebody at or above your own rank.')
            return false
        end

        if not Bridge.setJob(target.PlayerData.source, Config.DefaultJob, 0) then
            Bridge.notify(source, 'error', 'Boss Menu', 'Firing failed.')
            return false
        end

        Bridge.notify(source, 'success', 'Boss Menu', ('Fired %s.'):format(Bridge.getFullName(target)))
        Bridge.notify(target.PlayerData.source, 'error', job.label, ('%s fired you from %s.'):format(actorName, job.label))
    else
        if not Bridge.setJobOffline(citizenid, Config.DefaultJob, 0) then
            Bridge.notify(source, 'error', 'Boss Menu', 'Could not update that offline employee.')
            return false
        end
        Bridge.notify(source, 'success', 'Boss Menu', 'The offline employee has been let go.')
    end

    Logs.send({
        feature  = 'bossmenu',
        webhook  = Config.Jobs[job.name].bossmenu and Config.Jobs[job.name].bossmenu.webhook,
        title    = 'Employee fired',
        severity = 'warning',
        source   = source,
        fields   = { { name = 'Target', value = ('`%s`'):format(citizenid), inline = true } },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Bonus
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:bonus', function(source, citizenid, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not citizenid or amount <= 0 then
        Bridge.notify(source, 'error', 'Boss Menu', 'Enter an amount above zero.')
        return false
    end

    local allowed, job = Access.has(source, 'givebonus')
    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Boss Menu', 'Your rank cannot hand out bonuses.')
        return false
    end

    if Db.getBalance(job.name, 'money') < amount then
        Bridge.notify(source, 'error', 'Boss Menu', 'The company treasury does not have that much.')
        return false
    end
    if not Db.removeBalance(job.name, 'money', amount) then return false end

    local target = Bridge.getPlayerByCitizenId(citizenid)
    local delivered, targetName

    if target then
        targetName = Bridge.getFullName(target)
        delivered = Bridge.addMoney(target.PlayerData.source, Config.BankAccount, amount, 'renzu_jobs:bonus')
        if delivered then
            Bridge.notify(target.PlayerData.source, 'success', job.label,
                ('You received a $%s bonus from %s.'):format(amount, Bridge.getFullName(Bridge.getPlayer(source))))
        end
    else
        targetName = 'the offline employee'
        delivered = Bridge.addMoneyOffline(citizenid, amount)
    end

    if not delivered then
        Db.addBalance(job.name, 'money', amount) -- refund, nothing left the company
        Bridge.notify(source, 'error', 'Boss Menu', 'The payout failed, the money stayed in the treasury.')
        return false
    end

    Accounts.broadcast(job.name)
    Bridge.notify(source, 'success', 'Boss Menu', ('Paid a $%s bonus to %s.'):format(amount, targetName))

    Logs.money('bossmenu', source, 'Bonus paid', amount, {
        { name = 'Target', value = ('`%s`'):format(citizenid), inline = true },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Salary
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:setSalary', function(source, grade, amount)
    grade = tonumber(grade)
    amount = math.floor(tonumber(amount) or 0)
    if not grade or amount < 0 then return false end

    local allowed, job = Access.has(source, 'salarychange')
    if not job then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Boss Menu', 'Your rank cannot change salaries.')
        return false
    end

    local maxSalary = Config.Jobs[job.name].maxSalary or 0
    if amount > maxSalary then
        Bridge.notify(source, 'error', 'Boss Menu', ('The maximum salary for this company is $%s.'):format(maxSalary))
        return false
    end

    MySQL.prepare.await([[
        INSERT INTO renzu_jobs_salaries (job, grade, salary) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE salary = VALUES(salary)
    ]], { job.name, grade, amount })

    salaryCache[job.name] = salaryCache[job.name] or {}
    salaryCache[job.name][grade] = amount

    Bridge.notify(source, 'success', 'Boss Menu', ('Salary for grade %d set to $%s.'):format(grade, amount))

    Logs.money('bossmenu', source, 'Salary changed', amount, {
        { name = 'Grade', value = tostring(grade), inline = true },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Paycheck (optional - off by default so it cannot double up with qbx_core)
-- ─────────────────────────────────────────────────────────────────────────────

local function runPaycheck()
    for _, src in ipairs(Bridge.getPlayers()) do
        local job = Bridge.getJob(src)
        if job and Config.Jobs[job.name] then
            if not Config.Paycheck.requireDuty or job.onduty then
                local salary = Boss.getSalary(job.name, job.grade)

                if salary > 0 then
                    if Config.Paycheck.fromJobFunds then
                        if Db.removeBalance(job.name, 'money', salary) then
                            Bridge.addMoney(src, Config.Paycheck.account, salary, 'renzu_jobs:paycheck')
                            Bridge.notify(src, 'success', 'Paycheck', ('You received $%s from %s.'):format(salary, job.label))
                            Accounts.broadcast(job.name)
                        else
                            Bridge.notify(src, 'warning', 'Paycheck', ('%s cannot cover your salary right now.'):format(job.label))
                        end
                    else
                        Bridge.addMoney(src, Config.Paycheck.account, salary, 'renzu_jobs:paycheck')
                        Bridge.notify(src, 'success', 'Paycheck', ('You received $%s from %s.'):format(salary, job.label))
                    end
                end
            end
        end
    end
end

CreateThread(function()
    Db.await()
    loadSalaries()

    if not Config.Paycheck or not Config.Paycheck.enabled then return end

    local interval = math.max(1, Config.Paycheck.intervalMinutes or 10) * 60000
    while true do
        Wait(interval)
        local ok, err = pcall(runPaycheck)
        if not ok then lib.print.error(('paycheck failed: %s'):format(err)) end
    end
end)

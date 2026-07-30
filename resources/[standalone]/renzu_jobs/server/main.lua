---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - server entry point

    Everything in config/ is a shared_script, so the client already has the job
    layout without a round trip. The only server-only config is the webhook
    block in server/logs.lua.
]]

-- ─────────────────────────────────────────────────────────────────────────────
-- Job creator
-- ─────────────────────────────────────────────────────────────────────────────

--- QBox reads jobs from qbx_core/shared/jobs.lua. We can register one at runtime
--- so it works immediately, but it only survives a restart once you paste the
--- printed snippet into that file. The snippet is written to the console so
--- there is no guesswork.
lib.callback.register('renzu_jobs:createJob', function(source, data)
    if not Bridge.isAdmin(source) then
        Bridge.notify(source, 'error', 'Job Creator', 'You do not have permission for this.')
        return false
    end

    if type(data) ~= 'table' or not data.name or not data.label then return false end

    local name = data.name:lower():gsub('[^%w_]', '')
    if name == '' then
        Bridge.notify(source, 'error', 'Job Creator', 'That job name is not usable.')
        return false
    end

    local jobs = Bridge.getJobs()
    if jobs[name] then
        Bridge.notify(source, 'error', 'Job Creator', ('The job "%s" already exists.'):format(name))
        return false
    end

    local definition = {
        label = data.label,
        type  = data.gang and 'gang' or nil,
        defaultDuty = true,
        offDutyPay  = false,
        grades = {
            [0] = { name = 'Recruit', payment = tonumber(data.salary) or 50 },
        },
    }

    local ok = pcall(function()
        return exports.qbx_core:CreateJobs({ [name] = definition })
    end)

    if not ok then
        Bridge.notify(source, 'error', 'Job Creator', 'qbx_core refused the job. Check the server console.')
        return false
    end

    lib.print.info(([[

Job "%s" registered at runtime. Add this to qbx_core/shared/jobs.lua to keep it
after a restart:

    ['%s'] = {
        label = '%s',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Recruit', payment = %d },
        },
    },
]]):format(name, name, data.label, tonumber(data.salary) or 50))

    Bridge.notify(source, 'success', 'Job Creator',
        ('Created "%s". Check the server console for the snippet to make it permanent.'):format(data.label))
    return true
end)

lib.callback.register('renzu_jobs:addGrade', function(source, data)
    if not Bridge.isAdmin(source) then
        Bridge.notify(source, 'error', 'Job Creator', 'You do not have permission for this.')
        return false
    end

    if type(data) ~= 'table' or not data.job then return false end

    local jobs = Bridge.getJobs()
    local job = jobs[data.job]
    if not job then
        Bridge.notify(source, 'error', 'Job Creator', 'That job does not exist.')
        return false
    end

    local level = tonumber(data.grade) or 0
    if job.grades[level] then
        Bridge.notify(source, 'error', 'Job Creator', ('Grade %d already exists.'):format(level))
        return false
    end

    job.grades[level] = {
        name    = data.label,
        payment = tonumber(data.salary) or 0,
        isboss  = data.isboss == true,
    }

    local ok = pcall(function()
        return exports.qbx_core:CreateJobs({ [data.job] = job })
    end)
    if not ok then
        Bridge.notify(source, 'error', 'Job Creator', 'qbx_core refused the update.')
        return false
    end

    lib.print.info(([[

Grade %d ("%s") added to "%s". Add this inside its `grades` table in
qbx_core/shared/jobs.lua to keep it after a restart:

    [%d] = { name = '%s', payment = %d%s },
]]):format(level, data.label, data.job, level, data.label, tonumber(data.salary) or 0,
           data.isboss and ', isboss = true' or ''))

    Bridge.notify(source, 'success', 'Job Creator',
        ('Added grade %d to %s. Snippet printed to the server console.'):format(level, job.label or data.job))
    return true
end)

lib.callback.register('renzu_jobs:getJobList', function(source)
    if not Bridge.isAdmin(source) then return nil end

    local list = {}
    for name, job in pairs(Bridge.getJobs()) do
        local grades = 0
        for _ in pairs(job.grades or {}) do grades = grades + 1 end
        list[#list + 1] = { name = name, label = job.label or name, grades = grades }
    end

    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Wardrobe hand-off
-- ─────────────────────────────────────────────────────────────────────────────

--- The wardrobe itself lives in the clothing resource. We only check that the
--- player is allowed to use this particular wardrobe point.
lib.callback.register('renzu_jobs:canUseWardrobe', function(source)
    local allowed, job, feature = Access.feature(source, 'wardrobe')
    if not job or not feature then return false end

    if not allowed then
        Bridge.notify(source, 'error', 'Wardrobe', 'Your rank does not have access to this wardrobe.')
        return false
    end
    return Access.nearby(source, feature.coord, 8.0)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Boot banner
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    Db.await()

    local jobCount, missing = 0, {}
    local known = Bridge.getJobs()

    for name in pairs(Config.Jobs) do
        jobCount = jobCount + 1
        if not known[name] then missing[#missing + 1] = name end
    end

    lib.print.info(('loaded %d job(s)'):format(jobCount))

    if #missing > 0 then
        lib.print.warn(([[
the following jobs are configured in renzu_jobs but do not exist in
qbx_core/shared/jobs.lua, so hiring and promoting will fail for them:
  %s]]):format(table.concat(missing, ', ')))
    end

    if Config.ClothingResource and GetResourceState(Config.ClothingResource) ~= 'started' then
        lib.print.warn(('clothing resource "%s" is not running - wardrobe points will not work'):format(Config.ClothingResource))
    end
    if Config.GarageResource and Config.Garage.giveKeys and GetResourceState(Config.GarageResource) ~= 'started' then
        lib.print.warn(('garage resource "%s" is not running - falling back to the built in key item'):format(Config.GarageResource))
    end
end)

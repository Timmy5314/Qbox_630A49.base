---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - duty clock

    QBox tracks duty natively on the job object, so there is no need for the
    "offpolice" shadow job that renzu_jobs 1.x used. Clocking in/out flips
    job.onduty, which every other QBox resource already understands.
]]

lib.callback.register('renzu_jobs:toggleDuty', function(source)
    local allowed, job, feature = Access.feature(source, 'duty')
    if not job or not feature then return nil end

    if not allowed then
        Bridge.notify(source, 'error', 'Duty', 'Your rank cannot clock in here.')
        return nil
    end
    if not Access.nearby(source, feature.coord, 8.0) then return nil end

    local goingOnDuty = not job.onduty
    if not Bridge.setDuty(source, goingOnDuty) then
        Bridge.notify(source, 'error', 'Duty', 'The duty clock did not respond.')
        return nil
    end

    Bridge.notify(source, goingOnDuty and 'success' or 'inform', job.label,
        goingOnDuty and 'You are now on duty.' or 'You are now off duty.')

    -- Let colleagues know somebody started or ended their shift.
    local name = Bridge.getFullName(Bridge.getPlayer(source))
    for _, src in ipairs(Bridge.getPlayers()) do
        if src ~= source then
            local other = Bridge.getJob(src)
            if other and other.name == job.name and other.onduty then
                Bridge.notify(src, 'inform', job.label,
                    ('%s clocked %s.'):format(name, goingOnDuty and 'in' or 'out'))
            end
        end
    end

    return { onduty = goingOnDuty }
end)

--- Small helper other resources can use.
---@param src number
---@return boolean
exports('isOnDuty', function(src)
    local job = Bridge.getJob(src)
    return job and job.onduty == true
end)

---@param jobName string
---@return number
exports('getOnDutyCount', function(jobName)
    local count = 0
    for _, src in ipairs(Bridge.getPlayers()) do
        local job = Bridge.getJob(src)
        if job and job.name == jobName and job.onduty then
            count = count + 1
        end
    end
    return count
end)

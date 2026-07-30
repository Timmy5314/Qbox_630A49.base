---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - client bridge

    Holds the player job state and the notification helper. Everything else on
    the client reads Bridge.job instead of touching qbx_core directly.
]]

Bridge = {}

--- Current job, refreshed on load and on every job update.
---@type { name: string, label: string, grade: number, onduty: boolean }?
Bridge.job = nil

Bridge.loaded = false

--- Fired whenever the job (or duty state) changes, so features can rebuild.
local listeners = {}

---@param fn fun(job: table?)
function Bridge.onJobChange(fn)
    listeners[#listeners + 1] = fn
end

local function emit()
    for i = 1, #listeners do
        local ok, err = pcall(listeners[i], Bridge.job)
        if not ok then lib.print.error(('job listener failed: %s'):format(err)) end
    end
end

---@param jobData table? raw qbx job object
local function setJob(jobData)
    if not jobData then
        Bridge.job = nil
        emit()
        return
    end

    Bridge.job = {
        name   = jobData.name,
        label  = jobData.label or jobData.name,
        grade  = type(jobData.grade) == 'table' and (jobData.grade.level or 0) or (tonumber(jobData.grade) or 0),
        gradeLabel = type(jobData.grade) == 'table' and (jobData.grade.name or '') or '',
        onduty = jobData.onduty == true,
        isboss = jobData.isboss == true,
    }
    emit()
end

function Bridge.refresh()
    local data = exports.qbx_core:GetPlayerData()
    if data and data.job then
        Bridge.loaded = true
        setJob(data.job)
    end
end

---@return string? citizenid
function Bridge.getCitizenId()
    local data = exports.qbx_core:GetPlayerData()
    return data and data.citizenid or nil
end

--- Grade check against a feature block from the config.
---@param feature table?
---@return boolean
function Bridge.canUse(feature)
    if not feature then return false end
    if not Bridge.job then return false end
    return Bridge.job.grade >= (feature.grade or 0)
end

--- Permission flags for the current grade (mirrors Access.flags on the server).
---@param flag string
---@return boolean
function Bridge.hasFlag(flag)
    if not Bridge.job then return false end

    local jobConfig = Config.Jobs[Bridge.job.name]
    if not jobConfig or not jobConfig.grades then return false end

    local exact = jobConfig.grades[Bridge.job.grade]
    if exact then return exact[flag] == true end

    local best, bestLevel = {}, -1
    for level, flags in pairs(jobConfig.grades) do
        if level <= Bridge.job.grade and level > bestLevel then
            best, bestLevel = flags, level
        end
    end
    return best[flag] == true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Framework events
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Bridge.loaded = true
    Wait(500)
    Bridge.refresh()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Bridge.loaded = false
    setJob(nil)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobData)
    setJob(jobData)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    if Bridge.job then
        Bridge.job.onduty = onDuty == true
        emit()
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Notifications
-- ─────────────────────────────────────────────────────────────────────────────

--- Every notification in the resource goes through here. Changing the look of
--- notifications is a one line change.
---@param type string 'success' | 'error' | 'warning' | 'inform'
---@param title string
---@param description string
---@param duration number?
function Bridge.notify(type, title, description, duration)
    lib.notify({
        title       = title,
        description = description,
        type        = type == 'info' and 'inform' or type,
        position    = Config.Notify.position,
        duration    = duration or Config.Notify.duration,
    })
end

RegisterNetEvent('renzu_jobs:notify', function(data)
    if type(data) ~= 'table' then return end
    Bridge.notify(data.type or 'inform', data.title or 'Job', data.description or '', data.duration)
end)

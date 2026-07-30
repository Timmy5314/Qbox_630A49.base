---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - client entry point

    Waits for the player to be loaded, then builds the interaction points.
    Everything rebuilds automatically on a job change, so a promotion instantly
    unlocks the points it should.
]]

local booted = false

local function rebuild()
    Targets.buildJobPoints()
    TurfClient.buildPoints()
    FoodJob.build()
end

CreateThread(function()
    -- Wait until qbx_core has handed us a character.
    while not LocalPlayer.state.isLoggedIn do Wait(250) end
    Wait(500)

    Bridge.refresh()

    -- Public points do not depend on the job, so they are built once.
    Targets.buildPublicPoints()
    rebuild()

    booted = true
    lib.print.info('ready')
end)

--- Rebuild the job points whenever the job or duty state changes.
Bridge.onJobChange(function()
    if not booted then return end
    Targets.buildJobPoints()
end)

exports('rebuildPoints', rebuild)

-- ─────────────────────────────────────────────────────────────────────────────
-- Job creator
-- ─────────────────────────────────────────────────────────────────────────────

local function createJobDialog()
    local input = lib.inputDialog('Create a job', {
        { type = 'input',    label = 'Label',      placeholder = 'Los Santos Customs', required = true },
        { type = 'input',    label = 'Job name',   placeholder = 'lscustoms', required = true },
        { type = 'number',   label = 'Starting salary', default = 50, min = 0 },
        { type = 'checkbox', label = 'This is a gang' },
    })
    if not input then return end

    lib.callback.await('renzu_jobs:createJob', false, {
        label  = input[1],
        name   = input[2],
        salary = input[3],
        gang   = input[4],
    })
end

---@param jobName string
---@param jobLabel string
---@param gradeCount number
local function addGradeDialog(jobName, jobLabel, gradeCount)
    local input = lib.inputDialog(('New grade for %s'):format(jobLabel), {
        { type = 'input',    label = 'Grade name', placeholder = 'Manager', required = true },
        { type = 'number',   label = 'Grade level', default = gradeCount, min = 0 },
        { type = 'number',   label = 'Salary', default = 100, min = 0 },
        { type = 'checkbox', label = 'Boss grade' },
    })
    if not input then return end

    lib.callback.await('renzu_jobs:addGrade', false, {
        job    = jobName,
        label  = input[1],
        grade  = input[2],
        salary = input[3],
        isboss = input[4],
    })
end

RegisterCommand('jobcreator', function()
    local jobs = lib.callback.await('renzu_jobs:getJobList', false)
    if not jobs then
        Bridge.notify('error', 'Job Creator', 'You do not have permission to use this.')
        return
    end

    local options = {
        {
            title = 'Create a new job',
            description = 'Registers it in qbx_core right away',
            icon = 'plus',
            onSelect = createJobDialog,
        },
    }

    for _, job in ipairs(jobs) do
        options[#options + 1] = {
            title = job.label,
            description = ('%d grade%s - add another'):format(job.grades, job.grades == 1 and '' or 's'),
            icon = 'layer-group',
            onSelect = function() addGradeDialog(job.name, job.label, job.grades) end,
        }
    end

    lib.registerContext({ id = 'renzu_jobcreator', title = 'Job Creator', options = options })
    lib.showContext('renzu_jobcreator')
end, false)

TriggerEvent('chat:addSuggestion', '/jobcreator', 'Create jobs and grades (admin only)')

---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - food preparation (client)

    Cooking stations are ox_target points instead of the old 1s marker loop, and
    the minigame is the ox_lib skill check instead of renzu_lockgame.
]]

FoodJob = {}

local busy = false

---@param station table
local function runStation(action)
    if busy then return end
    busy = true

    local passed = lib.skillCheck(Config.FoodSkillCheck or { 'easy', 'easy' })
    if not passed then
        Bridge.notify('error', 'Kitchen', 'You botched it.')
        busy = false
        return
    end

    local completed = lib.progressCircle({
        duration = Config.FoodDuration or 4000,
        label    = 'Preparing',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'amb@prop_human_bbq@male@base', clip = 'base' },
    })
    ClearPedTasks(cache.ped)

    if completed then action() end
    busy = false
end

--- Recipe picker for the prep station.
---@param stationKey string
local function openRecipes(stationKey)
    local recipes = lib.callback.await('renzu_jobs:getRecipes', false)
    if not recipes or #recipes == 0 then
        Bridge.notify('inform', 'Kitchen', 'No recipes are set up for this job.')
        return
    end

    local options = {}
    for _, recipe in ipairs(recipes) do
        local lines, ready = {}, true

        for _, ingredient in ipairs(recipe.ingredients) do
            local has = ingredient.owned >= ingredient.amount
            if not has then ready = false end
            lines[#lines + 1] = ('%s %s %d/%d'):format(
                has and '✓' or '✗', ingredient.label, ingredient.owned, ingredient.amount)
        end

        options[#options + 1] = {
            title       = recipe.label,
            description = table.concat(lines, '  ·  '),
            icon        = ready and 'utensils' or 'ban',
            disabled    = not ready,
            onSelect    = function()
                runStation(function()
                    lib.callback.await('renzu_jobs:cookMeal', false, recipe.name, stationKey)
                end)
            end,
        }
    end

    lib.registerContext({
        id      = 'renzu_food_recipes',
        title   = 'Recipes',
        options = options,
    })
    lib.showContext('renzu_food_recipes')
end

--- Build the stations for the job the player currently holds.
function FoodJob.build()
    Targets.clear('food')

    local job = Bridge.job
    if not job then return end

    local foodConfig = Config.FoodJobs and Config.FoodJobs[job.name]
    if not foodConfig then return end

    for key, task in pairs(foodConfig.Tasks or {}) do
        Targets.register('food', {
            id     = ('renzu_food_task_%s'):format(key),
            coord  = task.coord,
            label  = task.label,
            icon   = 'fire-burner',
            ped    = false,
            onSelect = function()
                runStation(function()
                    lib.callback.await('renzu_jobs:foodTask', false, key)
                end)
            end,
        })
    end

    for key, station in pairs(foodConfig.Proccess or {}) do
        Targets.register('food', {
            id     = ('renzu_food_prep_%s'):format(key),
            coord  = station.coord,
            label  = station.label,
            icon   = 'utensils',
            ped    = false,
            onSelect = function() openRecipes(key) end,
        })
    end
end

Bridge.onJobChange(function()
    FoodJob.build()
end)

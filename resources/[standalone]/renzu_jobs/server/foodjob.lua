---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - food preparation (server)

    Fixes two bugs from the 1.x plugin:
      * the meal processor removed 1 of each ingredient instead of the required
        count, so a recipe asking for 4x cheese only ever cost you 1
      * nothing checked that the player was actually standing at the station
]]

--- Anti-spam per player.
local busy = {}

---@param src number
---@param jobName string
---@return table? job config
local function foodConfigFor(src, jobName)
    local job = Bridge.getJob(src)
    if not job or job.name ~= jobName then return nil end
    return Config.FoodJobs[job.name]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Single item conversion (cook a patty, heat a bun, ...)
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:foodTask', function(source, taskKey)
    if busy[source] then return false end

    local job = Bridge.getJob(source)
    if not job then return false end

    local foodConfig = Config.FoodJobs[job.name]
    local task = foodConfig and foodConfig.Tasks and foodConfig.Tasks[taskKey]
    if not task then
        lib.print.warn(('%s tried food task "%s" which does not exist for %s'):format(source, tostring(taskKey), job.name))
        return false
    end

    if not Access.nearby(source, task.coord, 5.0) then
        Bridge.notify(source, 'error', 'Kitchen', 'Stand at the station first.')
        return false
    end

    local input = task.require.item
    local needed = task.require.count or 1
    local output = foodConfig.Convert and foodConfig.Convert[input]

    if not output then
        lib.print.warn(('no Convert entry for "%s" in %s'):format(input, job.name))
        return false
    end

    if Bridge.getItemCount(source, input) < needed then
        Bridge.notify(source, 'error', 'Kitchen',
            ('You need %dx %s.'):format(needed, Bridge.getItemLabel(input)))
        return false
    end
    if not Bridge.canCarry(source, output, 1) then
        Bridge.notify(source, 'error', 'Kitchen', 'Your hands are full.')
        return false
    end

    busy[source] = true

    local ok = Bridge.removeItem(source, input, needed) and Bridge.addItem(source, output, 1)
    if not ok then
        -- Put the input back if the output never arrived.
        Bridge.addItem(source, input, needed)
        Bridge.notify(source, 'error', 'Kitchen', 'Something went wrong, nothing was used.')
    else
        Bridge.notify(source, 'success', 'Kitchen', ('Made 1x %s.'):format(Bridge.getItemLabel(output)))
    end

    busy[source] = nil
    return ok
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Recipes (combine ingredients into a meal)
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:getRecipes', function(source)
    local job = Bridge.getJob(source)
    if not job then return nil end

    local foodConfig = Config.FoodJobs[job.name]
    if not foodConfig or not foodConfig.Recipes then return nil end

    local recipes = {}
    for name, recipe in pairs(foodConfig.Recipes) do
        local ingredients = {}
        for item, data in pairs(recipe.ingredients) do
            ingredients[#ingredients + 1] = {
                name   = item,
                label  = data.label or Bridge.getItemLabel(item),
                amount = data.count,
                owned  = Bridge.getItemCount(source, item),
            }
        end
        table.sort(ingredients, function(a, b) return a.label < b.label end)

        recipes[#recipes + 1] = {
            name        = name,
            label       = recipe.label,
            ingredients = ingredients,
        }
    end

    table.sort(recipes, function(a, b) return a.label < b.label end)
    return recipes
end)

lib.callback.register('renzu_jobs:cookMeal', function(source, mealName, stationKey)
    if busy[source] then return false end

    local job = Bridge.getJob(source)
    if not job then return false end

    local foodConfig = Config.FoodJobs[job.name]
    local recipe = foodConfig and foodConfig.Recipes and foodConfig.Recipes[mealName]
    if not recipe then
        lib.print.warn(('%s tried to cook "%s" which is not a %s recipe'):format(source, tostring(mealName), job.name))
        return false
    end

    local station = foodConfig.Proccess and foodConfig.Proccess[stationKey]
    if station and not Access.nearby(source, station.coord, 5.0) then
        Bridge.notify(source, 'error', 'Kitchen', 'Stand at the prep station first.')
        return false
    end

    -- Check everything before touching the inventory.
    for item, data in pairs(recipe.ingredients) do
        if Bridge.getItemCount(source, item) < data.count then
            Bridge.notify(source, 'error', 'Kitchen',
                ('You are short on %s (need %d).'):format(data.label or Bridge.getItemLabel(item), data.count))
            return false
        end
    end
    if not Bridge.canCarry(source, mealName, 1) then
        Bridge.notify(source, 'error', 'Kitchen', 'You cannot carry the finished meal.')
        return false
    end

    busy[source] = true

    -- Take the full required count of each ingredient, refunding on failure.
    local taken = {}
    for item, data in pairs(recipe.ingredients) do
        if Bridge.removeItem(source, item, data.count) then
            taken[#taken + 1] = { name = item, amount = data.count }
        else
            for _, refund in ipairs(taken) do
                Bridge.addItem(source, refund.name, refund.amount)
            end
            busy[source] = nil
            Bridge.notify(source, 'error', 'Kitchen', 'Something went wrong, your ingredients were returned.')
            return false
        end
    end

    if not Bridge.addItem(source, mealName, 1) then
        for _, refund in ipairs(taken) do
            Bridge.addItem(source, refund.name, refund.amount)
        end
        busy[source] = nil
        Bridge.notify(source, 'error', 'Kitchen', 'The meal could not be plated, ingredients returned.')
        return false
    end

    busy[source] = nil
    Bridge.notify(source, 'success', 'Kitchen', ('Served 1x %s.'):format(recipe.label))
    return true
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)

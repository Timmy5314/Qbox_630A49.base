---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - crafting

    Flow:
      1. startCraft  -> validate, take the ingredients, remember when we started
      2. client runs the ox_lib progress bar for the returned duration
      3. finishCraft -> server checks the clock itself before handing anything out

    Because step 3 verifies the elapsed time server side, a client that lies about
    finishing early gets nothing. Cancelling refunds the ingredients when
    Config.Crafting.refundOnCancel is on.
]]

--- source -> { item, amount, job, recipe, startedAt, duration, coord }
local active = {}

lib.callback.register('renzu_jobs:getCrafting', function(source)
    local allowed, job, feature = Access.feature(source, 'crafting')
    if not job or not feature then return nil end

    if not allowed then
        Bridge.notify(source, 'error', 'Workbench', 'Your rank does not have access to this workbench.')
        return nil
    end
    if not Access.nearby(source, feature.coord, 8.0) then return nil end

    local recipes = {}
    for name, recipe in pairs(feature.recipes or {}) do
        local requirements = {}
        for _, req in ipairs(recipe.requirements) do
            requirements[#requirements + 1] = {
                name  = req.name,
                label = Bridge.getItemLabel(req.name),
                image = Bridge.normaliseItem(req.name),
                amount = req.amount,
                owned  = Bridge.getItemCount(source, req.name),
            }
        end

        recipes[#recipes + 1] = {
            name         = name,
            label        = recipe.label or Bridge.getItemLabel(name),
            image        = Bridge.normaliseItem(name),
            seconds      = recipe.seconds or 10,
            amount       = recipe.amount or 1,
            requirements = requirements,
        }
    end

    table.sort(recipes, function(a, b) return a.label < b.label end)

    return { label = feature.label, recipes = recipes }
end)

lib.callback.register('renzu_jobs:startCraft', function(source, itemName, batches)
    batches = math.floor(tonumber(batches) or 0)

    if active[source] then
        Bridge.notify(source, 'warning', 'Workbench', 'You are already making something.')
        return nil
    end
    if batches <= 0 or batches > 20 then
        Bridge.notify(source, 'error', 'Workbench', 'Pick an amount between 1 and 20.')
        return nil
    end

    local allowed, job, feature = Access.feature(source, 'crafting')
    if not job or not feature or not allowed then return nil end
    if not Access.nearby(source, feature.coord, Config.Crafting.maxDistance + 3.0) then
        Bridge.notify(source, 'error', 'Workbench', 'Stand at the workbench first.')
        return nil
    end

    local recipe = feature.recipes and feature.recipes[itemName]
    if not recipe then
        lib.print.warn(('%s tried to craft "%s" which is not on the %s bench'):format(source, tostring(itemName), job.name))
        return nil
    end

    local isWeapon = Bridge.isWeapon(itemName)
    if isWeapon and batches > 1 then
        Bridge.notify(source, 'error', 'Workbench', 'Weapons are made one at a time.')
        return nil
    end

    local produced = (recipe.amount or 1) * batches

    -- Check everything before taking anything.
    for _, req in ipairs(recipe.requirements) do
        local needed = req.amount * batches
        if Bridge.getItemCount(source, req.name) < needed then
            Bridge.notify(source, 'error', 'Workbench',
                ('You need %dx %s.'):format(needed, Bridge.getItemLabel(req.name)))
            return nil
        end
    end

    if not Bridge.canCarry(source, itemName, produced) then
        Bridge.notify(source, 'error', 'Workbench', 'You do not have room for the result.')
        return nil
    end

    -- Take the ingredients. If one fails halfway, put back what we already took.
    local taken = {}
    for _, req in ipairs(recipe.requirements) do
        local needed = req.amount * batches
        if Bridge.removeItem(source, req.name, needed) then
            taken[#taken + 1] = { name = req.name, amount = needed }
        else
            for _, refund in ipairs(taken) do
                Bridge.addItem(source, refund.name, refund.amount)
            end
            Bridge.notify(source, 'error', 'Workbench', 'Something went wrong taking the materials.')
            return nil
        end
    end

    local duration = (recipe.seconds or 10) * batches

    active[source] = {
        item      = itemName,
        produced  = produced,
        job       = job.name,
        taken     = taken,
        startedAt = os.time(),
        duration  = duration,
        coord     = feature.coord,
        webhook   = feature.webhook,
        label     = recipe.label or Bridge.getItemLabel(itemName),
    }

    return { duration = duration * 1000, label = active[source].label }
end)

lib.callback.register('renzu_jobs:finishCraft', function(source, completed)
    local job = active[source]
    if not job then return false end
    active[source] = nil

    local function refund()
        if not Config.Crafting.refundOnCancel then return end
        for _, entry in ipairs(job.taken) do
            Bridge.addItem(source, entry.name, entry.amount)
        end
    end

    if not completed then
        refund()
        Bridge.notify(source, 'warning', 'Workbench',
            Config.Crafting.refundOnCancel and 'Crafting cancelled, your materials were returned.'
                                            or 'Crafting cancelled.')
        return false
    end

    -- The server keeps its own clock. A client claiming instant completion fails here.
    local elapsed = os.time() - job.startedAt
    if elapsed < (job.duration - 2) then
        refund()
        lib.print.warn(('%s reported finishing a craft after %ds but it needs %ds'):format(source, elapsed, job.duration))
        Bridge.notify(source, 'error', 'Workbench', 'The craft did not complete properly.')
        return false
    end

    if not Access.nearby(source, job.coord, Config.Crafting.maxDistance + 5.0) then
        refund()
        Bridge.notify(source, 'error', 'Workbench', 'You left the workbench, the batch is ruined.')
        return false
    end

    if not Bridge.addItem(source, job.item, job.produced) then
        refund()
        Bridge.notify(source, 'error', 'Workbench', 'You could not carry the result, materials returned.')
        return false
    end

    Bridge.notify(source, 'success', 'Workbench', ('Crafted %dx %s.'):format(job.produced, job.label))

    Logs.send({
        feature  = 'crafting',
        webhook  = job.webhook,
        title    = 'Item crafted',
        severity = 'info',
        source   = source,
        fields   = {
            { name = 'Item', value = ('%dx %s'):format(job.produced, job.label), inline = true },
            { name = 'Job',  value = job.job, inline = true },
        },
    })
    return true
end)

AddEventHandler('playerDropped', function()
    -- Nothing to refund into once the player is gone, just drop the record.
    active[source] = nil
end)

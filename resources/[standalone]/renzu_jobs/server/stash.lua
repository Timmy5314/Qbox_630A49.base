---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job stashes (ox_inventory)

    Stashes are registered the first time somebody opens them, not on boot, so a
    server with 30 jobs does not register hundreds of unused stashes.
]]

Stash = {}

local registered = {}

---@param value string
---@return string safe id fragment
local function slug(value)
    return (tostring(value):gsub('[^%w]', '_')):lower()
end

--- Build the stash id for a job stash.
---@param job string
---@param key string
---@param citizenid string? only for personal stashes
---@return string
function Stash.id(job, key, citizenid)
    if citizenid then
        return ('renzujob_%s_%s_%s'):format(slug(job), slug(key), slug(citizenid))
    end
    return ('renzujob_%s_%s'):format(slug(job), slug(key))
end

--- Register a stash with ox_inventory once.
---@param id string
---@param label string
---@param slots number
---@param weight number
---@param owner string|boolean? citizenid for personal stashes, false for shared
---@param groups table? job restriction handed to ox_inventory
function Stash.register(id, label, slots, weight, owner, groups)
    if registered[id] then return id end

    exports.ox_inventory:RegisterStash(id, label, slots or 50, weight or 250000, owner or false, groups or nil)
    registered[id] = true
    return id
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Job stashes
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:openStash', function(source, key)
    local allowed, job, feature = Access.feature(source, { 'stashes', key })

    if not job or not feature then return false end
    if not allowed then
        Bridge.notify(source, 'error', 'Storage', 'Your rank does not have access to this storage.')
        return false
    end
    if not Access.nearby(source, feature.coord, 8.0) then return false end

    local citizenid = feature.personal and Bridge.getIdentifier(source) or nil
    if feature.personal and not citizenid then return false end

    local id = Stash.id(job.name, key, citizenid)
    local label = feature.personal
        and ('%s - %s'):format(feature.label, Bridge.getFullName(Bridge.getPlayer(source)))
        or ('%s - %s'):format(Config.Jobs[job.name].label or job.label, feature.label)

    -- Personal stashes are owned by the character. Shared stashes are locked to
    -- the job + minimum grade through ox_inventory groups, which means the
    -- inventory itself refuses access even if this callback were bypassed.
    Stash.register(
        id,
        label,
        feature.slots,
        feature.weight,
        feature.personal and citizenid or false,
        not feature.personal and { [job.name] = feature.grade or 0 } or nil
    )

    Logs.send({
        feature  = 'stash',
        webhook  = feature.webhook,
        title    = 'Storage opened',
        severity = 'info',
        source   = source,
        fields   = { { name = 'Storage', value = feature.label, inline = true } },
    })

    return { id = id, label = label, slots = feature.slots, weight = feature.weight }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Public stashes (trays, counters - anybody may open them)
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:openPublicStash', function(source, jobName, key)
    local feature = Access.publicFeature(jobName, { 'publicStashes', key })
    if not feature then return false end
    if not Access.nearby(source, feature.coord, 8.0) then return false end

    local id = ('renzujobpub_%s_%s'):format(slug(jobName), slug(key))
    local label = ('%s - %s'):format(Config.Jobs[jobName].label or jobName, feature.label)

    Stash.register(id, label, feature.slots, feature.weight, false, nil)

    return { id = id, label = label, slots = feature.slots, weight = feature.weight }
end)

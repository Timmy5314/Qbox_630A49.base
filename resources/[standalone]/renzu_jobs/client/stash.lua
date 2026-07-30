---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job storage (client)

    Storage is plain ox_inventory. The server registers the stash and returns its
    id, we just open it. No custom inventory UI, no duplicated item logic.
]]

JobStash = {}

local opening = false

---@param key string stash key from config/jobs.lua
function JobStash.open(key)
    if opening then return end
    opening = true

    local stash = lib.callback.await('renzu_jobs:openStash', false, key)
    opening = false

    if not stash then return end

    exports.ox_inventory:openInventory('stash', { id = stash.id })
end

---@param jobName string
---@param key string
function JobStash.openPublic(jobName, key)
    if opening then return end
    opening = true

    local stash = lib.callback.await('renzu_jobs:openPublicStash', false, jobName, key)
    opening = false

    if not stash then return end

    exports.ox_inventory:openInventory('stash', { id = stash.id })
end

RegisterNetEvent('renzu_jobs:openinventory', function(key)
    JobStash.open(key)
end)

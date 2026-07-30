---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - wardrobe (client)

    renzu_jobs no longer contains a clothing menu. The wardrobe point checks
    access and then hands over to whichever clothing resource in
    Config.ClothingResource is actually running.
]]

Wardrobe = {}

local busy = false

--- Try the known entry points of the clothing resource, newest first.
---@param resource string
---@return boolean opened
local function callClothing(resource)
    local target = exports[resource]
    if not target then return false end

    local candidates = { 'openWardrobe', 'OpenClotheInventory', 'openOutfits', 'openWornMenu' }

    for _, name in ipairs(candidates) do
        local ok = pcall(function() return target[name](target) end)
        if ok then return true end
    end

    return false
end

function Wardrobe.open()
    if busy then return end

    if not Config.ClothingResource then
        Bridge.notify('error', 'Wardrobe', 'No clothing resource is configured.')
        return
    end

    local resource = Config.resolveResource(Config.ClothingResource)
    if not resource then
        Bridge.notify('error', 'Wardrobe', 'The clothing resource is not running.')
        lib.print.error('no clothing resource started, tried: ' ..
            table.concat(type(Config.ClothingResource) == 'table' and Config.ClothingResource or { Config.ClothingResource }, ', '))
        return
    end

    busy = true
    local allowed = lib.callback.await('renzu_jobs:canUseWardrobe', false)
    busy = false

    if not allowed then return end

    if not callClothing(resource) then
        Bridge.notify('error', 'Wardrobe',
            ('"%s" does not expose a wardrobe export this script knows about.'):format(resource))
        lib.print.error(('%s has no openWardrobe / OpenClotheInventory export'):format(resource))
    end
end

RegisterNetEvent('renzu_jobs:openwardrobe', function() Wardrobe.open() end)

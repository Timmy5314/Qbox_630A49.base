---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - wardrobe (client)

    renzu_jobs no longer contains a clothing menu. The wardrobe point checks
    access and then hands over to the clothing resource configured in
    Config.ClothingResource (renzuzu_clothes by default).
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

    local resource = Config.ClothingResource
    if not resource then
        Bridge.notify('error', 'Wardrobe', 'No clothing resource is configured.')
        return
    end

    if GetResourceState(resource) ~= 'started' then
        Bridge.notify('error', 'Wardrobe', ('The clothing resource "%s" is not running.'):format(resource))
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

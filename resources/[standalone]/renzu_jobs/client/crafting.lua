---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - crafting (client)

    The NUI closes before the progress bar starts so the player can see (and
    cancel) the craft, and so the bar is not hidden behind the menu.
]]

Crafting = {}

local opening = false
local busy = false

function Crafting.open()
    if opening or busy or Nui.isOpen() then return end
    opening = true

    local data = lib.callback.await('renzu_jobs:getCrafting', false)
    opening = false

    if not data then return end
    Nui.open('crafting', data)
end

RegisterNetEvent('renzu_jobs:opencrafting', function() Crafting.open() end)

---@param item string
---@param amount number
local function craft(item, amount)
    if busy then return false end

    local job = lib.callback.await('renzu_jobs:startCraft', false, item, amount)
    if not job then return false end

    busy = true
    Nui.close()

    local anim = Config.Crafting.anim
    local completed = lib.progressBar({
        duration = job.duration,
        label    = ('Crafting %s'):format(job.label),
        useWhileDead = false,
        canCancel = true,
        disable  = { car = true, move = true, combat = true },
        anim     = anim and { dict = anim.dict, clip = anim.clip } or nil,
    })

    ClearPedTasks(cache.ped)

    local ok = lib.callback.await('renzu_jobs:finishCraft', false, completed == true)
    busy = false

    return ok
end

RegisterNUICallback('crafting:craft', function(data, cb)
    cb(true) -- answer straight away, the progress bar takes over from here
    CreateThread(function()
        craft(data.item, data.amount)
    end)
end)

---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job shop (client)
]]

Shop = {}

local current = nil
local opening = false

---@param jobName string
---@param index number
function Shop.open(jobName, index)
    if opening or Nui.isOpen() then return end
    opening = true

    local data = lib.callback.await('renzu_jobs:getShop', false, jobName, index)
    opening = false

    if not data then return end

    current = { job = jobName, index = index }
    Nui.open('shop', data)
end

Nui.onClose('shop', function() current = nil end)

RegisterNetEvent('renzu_jobs:openshop', function(jobName, index)
    Shop.open(jobName, index)
end)

RegisterNUICallback('shop:buy', function(data, cb)
    if not current then return cb(false) end

    local ok = lib.callback.await('renzu_jobs:buyItem', false,
        current.job, current.index, data.item, data.amount)

    if ok then
        -- Refresh the balance shown in the header.
        local fresh = lib.callback.await('renzu_jobs:getShop', false, current.job, current.index)
        if fresh then Nui.update('shop', fresh) end
    end

    cb(ok)
end)

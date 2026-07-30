---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - boss menu (client)
]]

Boss = {}

local opening = false

function Boss.open()
    if opening or Nui.isOpen() then return end
    opening = true

    local data = lib.callback.await('renzu_jobs:getBossData', false)
    opening = false

    if not data then return end
    Nui.open('boss', data)
end

--- Reload the data without closing the view, so the list does not flash.
local function refresh()
    local data = lib.callback.await('renzu_jobs:getBossData', false)
    if data then Nui.update('boss', data) end
end

RegisterNetEvent('renzu_jobs:openbossmenu', function() Boss.open() end)

--- Live treasury updates pushed by the server.
RegisterNetEvent('renzu_jobs:updateAccounts', function(accounts)
    Nui.update('boss', { accounts = accounts, partial = true })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- NUI callbacks
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('boss:refresh', function(_, cb)
    refresh()
    cb(true)
end)

RegisterNUICallback('boss:transfer', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:transfer', false, data.direction, data.account, data.amount)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('boss:setGrade', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:setGrade', false, data.citizenid, data.grade)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('boss:fire', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:fire', false, data.citizenid)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('boss:hire', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:hire', false, data.serverId)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('boss:bonus', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:bonus', false, data.citizenid, data.amount)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('boss:setSalary', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:setSalary', false, data.grade, data.amount)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('boss:recallFleet', function(_, cb)
    local ok = lib.callback.await('renzu_jobs:recallFleet', false)
    cb(ok)
end)

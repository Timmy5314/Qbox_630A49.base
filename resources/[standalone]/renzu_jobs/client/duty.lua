---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - duty clock (client)

    A confirmation dialog rather than a NUI page: it is a single yes/no action
    and ox_lib already does that well.
]]

Duty = {}

local busy = false

function Duty.toggle()
    if busy then return end
    busy = true

    local onDuty = Bridge.job and Bridge.job.onduty
    local confirmed = lib.alertDialog({
        header  = 'Duty Clock',
        content = onDuty
            and 'You are currently **on duty**.\n\nClock out?'
            or  'You are currently **off duty**.\n\nClock in?',
        centered = true,
        cancel   = true,
        labels   = { confirm = onDuty and 'Clock out' or 'Clock in', cancel = 'Cancel' },
    })

    if confirmed ~= 'confirm' then
        busy = false
        return
    end

    lib.callback.await('renzu_jobs:toggleDuty', false)
    busy = false
end

RegisterNetEvent('renzu_jobs:duty', function() Duty.toggle() end)

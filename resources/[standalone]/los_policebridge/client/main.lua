--- De server stuurt dit naar de client van de dader; die maakt de ps-dispatch
--- melding aan met zijn eigen positie. CustomAlert bestaat alleen client-side.
RegisterNetEvent('los_policebridge:alert', function(message)
    local ok = pcall(function()
        exports['ps-dispatch']:CustomAlert({
            coords = GetEntityCoords(cache.ped),
            message = message,
            dispatchCode = 'robbery',
            code = '10-90',
            icon = 'fas fa-sack-dollar',
            priority = 2,
            radius = 0,
            sprite = 484,
            color = 1,
            scale = 1.0,
            length = 3,
            jobs = { 'leo' },
        })
    end)

    if not ok then
        lib.print.warn('[los_policebridge] ps-dispatch CustomAlert faalde')
    end
end)

--- Handmatige EMS-oproep (hospital:server:emergencyAlert) -> ps-dispatch EMS.
RegisterNetEvent('los_policebridge:emsalert', function()
    local ok = pcall(function()
        exports['ps-dispatch']:CustomAlert({
            coords = GetEntityCoords(cache.ped),
            message = 'Medical emergency',
            dispatchCode = 'ems',
            code = '10-52',
            icon = 'fas fa-truck-medical',
            priority = 2,
            radius = 0,
            sprite = 61,
            color = 1,
            scale = 1.0,
            length = 3,
            jobs = { 'ems' },
        })
    end)

    if not ok then
        lib.print.warn('[los_policebridge] ps-dispatch EMS-alert faalde')
    end
end)

--- qbx_truckrobbery stuurt `police:client:policeAlert` per agent (coords + msg).
--- Dat legacy-event werd nergens afgevangen. We tonen het direct op de agent zijn
--- scherm: melding + knipperende blip. GEEN CustomAlert, want dat zou opnieuw naar
--- alle agenten broadcasten en de melding verveelvoudigen (truckrobbery loopt zelf
--- al over elke agent).
RegisterNetEvent('police:client:policeAlert', function(coords, msg)
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return end

    local text = type(msg) == 'string' and msg or 'Robbery in progress'
    lib.notify({ title = '10-90', description = text, type = 'inform', duration = 8000 })

    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.2)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandSetBlipName(blip)

    SetTimeout(60000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

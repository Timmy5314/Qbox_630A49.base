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

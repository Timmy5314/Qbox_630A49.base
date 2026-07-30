---Review-menu voor admins (ox_lib context menu).

local function openFlagDetail(entry)
    local options = {}

    for i = 1, #entry.flags do
        local flag = entry.flags[i]
        options[#options + 1] = {
            title = ('%s  (+%d)'):format(flag.check, flag.points),
            description = flag.detail or locale('no_detail'),
            metadata = { { label = locale('time'), value = os.date('%H:%M:%S', flag.time) } },
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('fp_header'),
                    content = locale('fp_content', flag.check),
                    centered = true,
                    cancel = true,
                })

                if confirm == 'confirm' then
                    TriggerServerEvent('los_anticheat:markFalsePositive', flag.check)
                end
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = locale('no_flags'), disabled = true }
    end

    lib.registerContext({
        id = 'los_ac_detail',
        title = ('%s  -  %d'):format(entry.name, entry.score),
        menu = 'los_ac_overview',
        options = options,
    })

    lib.showContext('los_ac_detail')
end

RegisterNetEvent('los_anticheat:openMenu', function()
    local overview = lib.callback.await('los_anticheat:getOverview', false)

    if not overview then
        return lib.notify({ type = 'error', description = locale('no_access') })
    end

    local options = {}

    for i = 1, #overview do
        local entry = overview[i]
        options[#options + 1] = {
            title = entry.name,
            description = locale('score_flags', entry.score, #entry.flags),
            icon = entry.score >= 60 and 'triangle-exclamation' or 'circle-info',
            onSelect = function() openFlagDetail(entry) end,
        }
    end

    if #options == 0 then
        options[1] = { title = locale('all_clear'), disabled = true }
    end

    lib.registerContext({
        id = 'los_ac_overview',
        title = locale('menu_title'),
        options = options,
    })

    lib.showContext('los_ac_overview')
end)

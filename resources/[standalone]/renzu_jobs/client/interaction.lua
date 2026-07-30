---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job interaction menu

    A shortcut menu that fires events from your other job scripts. It builds an
    ox_lib context menu from Config.Jobs[job].interaction, filtered by grade.
]]

Interaction = {}

--- Build the menu fresh each time so a promotion is reflected immediately.
function Interaction.open()
    local job = Bridge.job
    if not job then return end

    local jobConfig = Config.Jobs[job.name]
    local categories = jobConfig and jobConfig.interaction
    if not categories then
        Bridge.notify('inform', 'Interactions', 'Your job has no interactions configured.')
        return
    end

    local root = {}
    local built = 0

    for title, entries in pairs(categories) do
        local options = {}

        for _, entry in ipairs(entries) do
            if (entry.grade or 0) <= job.grade then
                local definition = Config.Interactions[entry.type]
                    and Config.Interactions[entry.type][entry.index]

                if definition then
                    options[#options + 1] = {
                        title       = definition.label,
                        description = definition.description,
                        icon        = definition.icon,
                        onSelect    = function()
                            TriggerEvent(definition.event)
                        end,
                    }
                end
            end
        end

        if #options > 0 then
            built = built + 1
            local menuId = ('renzu_interaction_%s'):format(title:gsub('%s+', '_'):lower())

            lib.registerContext({
                id      = menuId,
                title   = title,
                menu    = 'renzu_interaction_root',
                options = options,
            })

            root[#root + 1] = {
                title       = title,
                description = ('%d action%s'):format(#options, #options == 1 and '' or 's'),
                icon        = title:lower():find('vehicle') and 'car' or 'people-group',
                arrow       = true,
                menu        = menuId,
            }
        end
    end

    if built == 0 then
        Bridge.notify('inform', 'Interactions', 'Nothing is available at your rank.')
        return
    end

    table.sort(root, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id      = 'renzu_interaction_root',
        title   = ('%s - Interactions'):format(job.label),
        options = root,
    })

    lib.showContext('renzu_interaction_root')
end

CreateThread(function()
    if not Config.EnableInteractions then return end

    RegisterCommand(Config.InteractionCommand, function()
        Interaction.open()
    end, false)

    if Config.InteractionKey then
        RegisterKeyMapping(Config.InteractionCommand, 'Job interaction menu', 'keyboard', Config.InteractionKey)
    end

    TriggerEvent('chat:addSuggestion', ('/%s'):format(Config.InteractionCommand), 'Open the job interaction menu')
end)

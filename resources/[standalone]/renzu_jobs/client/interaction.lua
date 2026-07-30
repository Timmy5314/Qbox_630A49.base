---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - job interaction menu

    A shortcut menu that fires events from your other job scripts. It builds an
    ox_lib context menu from Config.Jobs[job].interaction, filtered by grade.
]]

Interaction = {}

--[[
    Een entry kan op twee manieren werk doen:

      event  = 'police:cuff'          -> TriggerEvent
      export = 'ND_Police:cuff'       -> exports.ND_Police:cuff()

    Exports krijgen de voorkeur. Bij een event kunnen we niet controleren of er
    iets luistert, bij een export wel: draait de resource niet, dan verbergen we
    de knop. Dat is belangrijk, want tot juli 2026 vuurden alle achttien
    entries hier events af waar NIETS in de hele server naar luisterde. Het hele
    menu was dood zonder dat je het zag.

    Entries zonder implementatie krijgen `unimplemented = true` en worden
    overgeslagen. Een knop die niets doet is slechter dan geen knop.
]]

---@param definition table
---@return boolean
function isAvailable(definition)
    if definition.unimplemented then return false end

    if definition.export then
        local resource = definition.export:match('^([^:]+)')
        if not resource or GetResourceState(resource) ~= 'started' then
            return false
        end
    end

    return definition.event ~= nil or definition.export ~= nil
end

---@param definition table
function runInteraction(definition)
    if definition.export then
        local resource, method = definition.export:match('^([^:]+):(.+)$')
        if resource and method then
            local ok, err = pcall(function()
                return exports[resource][method](nil)
            end)
            if not ok then
                Bridge.notify('error', 'Interactions', ('%s gaf een fout: %s'):format(definition.label, err))
            end
        end
        return
    end

    TriggerEvent(definition.event)
end

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

                if definition and isAvailable(definition) then
                    options[#options + 1] = {
                        title       = definition.label,
                        description = definition.description,
                        icon        = definition.icon,
                        onSelect    = function()
                            runInteraction(definition)
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

--[[
    Client: de interacties en de waarschuwingen.

    Geen eigen lus voor het verval - dat doet de server. Hier draait alleen een
    trage herinneringslus, en die kijkt naar waarden die toch al in het geheugen
    staan.
]]

local config = require 'shared.config'

local statuses = {
    hygiene = config.defaults.hygiene,
    bladder = config.defaults.bladder,
    bowel = config.defaults.bowel,
}

RegisterNetEvent('los_hygiene:update', function(data)
    if type(data) ~= 'table' then return end

    statuses.hygiene = tonumber(data.hygiene) or statuses.hygiene
    statuses.bladder = tonumber(data.bladder) or statuses.bladder
    statuses.bowel = tonumber(data.bowel) or statuses.bowel

    -- Doorgeven aan de HUD. qbx_hud tekent de ringen; deze resource bepaalt
    -- alleen de waarden.
    if GetResourceState('qbx_hud'):find('start') then
        TriggerEvent('hud:client:UpdateHygiene', statuses)
    end
end)

exports('GetStatuses', function()
    return statuses
end)

-- =========================================================================
--  Handelingen
-- =========================================================================

---@param action string
---@param label string
---@param anim table?
local function perform(action, label, anim)
    local settings = config.actions[action]
    if not settings then return end

    if lib.progressBar({
        duration = settings.duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = anim,
    }) then
        lib.callback.await('los_hygiene:finishAction', false, action)
    end
end

--[[
    ── /pee en /poo — in het wild ───────────────────────────────────────────

    Werkt altijd, behalve als er niets te legen valt. De server controleert dat
    opnieuw; deze check is er om meteen te kunnen zeggen waarom het niet mag in
    plaats van stil te falen.
]]

---@param status 'bladder'|'bowel'
---@param action string
---@param label string
---@param anim table
local function relieveOutside(status, action, label, anim)
    if config.wild.blockInVehicle and cache.vehicle then
        return lib.notify({ description = locale('not_in_vehicle'), type = 'error' })
    end

    if IsEntityDead(cache.ped) then return end

    if statuses[status] < config.wild.minimum then
        return lib.notify({ description = locale('nothing_to_do'), type = 'error' })
    end

    perform(action, label, anim)
end

RegisterCommand('pee', function()
    relieveOutside('bladder', 'peeWild', locale('doing_pee'), {
        dict = 'misscarsteal2peeing',
        clip = 'peeing_loop',
    })
end, false)

RegisterCommand('poo', function()
    -- Gehurkt. Er is geen nette "poepen buiten"-animatie in de basisgame; dit
    -- is de laagste hurkhouding die er wel is. Bevalt hij niet, dan is dit de
    -- enige plek waar hij staat.
    relieveOutside('bowel', 'pooWild', locale('doing_poo'), {
        dict = 'amb@world_human_bum_wash@male@low@idle_a',
        clip = 'idle_a',
    })
end, false)

local function addTargets(models, options)
    if not models or #models == 0 then return end
    exports.ox_target:addModel(models, options)
end

CreateThread(function()
    addTargets(config.models.toilet, {
        {
            name = 'los_hygiene:pee',
            icon = 'fa-solid fa-toilet',
            label = locale('use_toilet_pee'),
            distance = 2.5,
            onSelect = function()
                perform('pee', locale('doing_pee'), {
                    dict = 'misscarsteal2peeing',
                    clip = 'peeing_loop',
                })
            end,
        },
        {
            name = 'los_hygiene:poo',
            icon = 'fa-solid fa-toilet',
            label = locale('use_toilet_poo'),
            distance = 2.5,
            onSelect = function()
                perform('poo', locale('doing_poo'), {
                    dict = 'timetable@ron@ig_5_p3',
                    clip = 'ig_5_p3_base',
                })
            end,
        },
    })

    addTargets(config.models.shower, {
        {
            name = 'los_hygiene:shower',
            icon = 'fa-solid fa-shower',
            label = locale('use_shower'),
            distance = 2.5,
            onSelect = function()
                perform('shower', locale('doing_shower'), {
                    dict = 'mp_safehouseshower@male@',
                    clip = 'male_shower_idle_b',
                })
            end,
        },
    })

    addTargets(config.models.sink, {
        {
            name = 'los_hygiene:washhands',
            icon = 'fa-solid fa-hands-bubbles',
            label = locale('wash_hands'),
            distance = 2.5,
            onSelect = function()
                perform('washHands', locale('doing_wash'), {
                    dict = 'mp_arresting',
                    clip = 'a_uncuff',
                })
            end,
        },
    })
end)

-- =========================================================================
--  Herinneringen
-- =========================================================================

CreateThread(function()
    local interval = config.effects.reminderMinutes * 60000

    while true do
        Wait(interval)

        if statuses.hygiene < config.effects.dirtyBelow then
            lib.notify({ description = locale('you_smell'), type = 'inform', duration = 8000 })
        end

        if statuses.bladder > config.effects.urgeAbove then
            lib.notify({ description = locale('need_to_pee'), type = 'inform', duration = 8000 })
        end

        if statuses.bowel > config.effects.urgeAbove then
            lib.notify({ description = locale('need_to_poo'), type = 'inform', duration = 8000 })
        end
    end
end)

--[[
    Modelcontrole.

    De modelnamen in de config zijn niet op deze server geverifieerd. Werkt een
    toilet of douche niet, kijk er dan naar en typ dit commando: het meldt het
    model, zodat je het in shared/config.lua kunt zetten. Zelfde aanpak als
    /gangped in los_gangpeds.
]]
RegisterCommand('hygienemodel', function()
    local hit, entity = lib.raycast.cam(511, 4, 6.0)

    if not hit or not DoesEntityExist(entity) then
        return lib.notify({ description = locale('no_object'), type = 'error' })
    end

    local model = GetEntityModel(entity)

    lib.notify({
        description = locale('object_model', model),
        type = 'inform',
        duration = 15000,
    })

    lib.print.info(('hygienemodel: %s'):format(model))
end, false)

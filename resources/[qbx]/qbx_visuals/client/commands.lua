--[[
    qbx_visuals - commands

    /gfx opent een ox_lib menu. Er is ook een keybind die de speler zelf kan
    instellen (standaard leeg, zodat we niets van je bestaande binds afpakken).
]]

local CONTEXT_LABEL = {
    day        = 'Dag',
    overcast   = 'Bewolkt',
    dawn       = 'Zonsopgang',
    dusk       = 'Zonsondergang',
    night      = 'Nacht',
    rain_day   = 'Regen (dag)',
    rain_night = 'Regen (nacht)',
    fog        = 'Mist',
    snow       = 'Sneeuw',
    aerial     = 'In de lucht',
    interior   = 'Binnen',
}

local function openMenu() end -- forward declaration

-- ---------------------------------------------------------------------------
-- Submenu: look
-- ---------------------------------------------------------------------------

local function openPresetMenu()
    local options = {}

    for id, preset in pairs(Config.Presets) do
        options[#options + 1] = {
            title       = preset.label,
            description = ('Sterkte %d%%'):format(math.floor(preset.strength * 100)),
            icon        = QV.state.preset == id and 'circle-check' or 'circle',
            onSelect    = function()
                QV.setPreset(id)
                QV.notify('Look: ' .. preset.label)
                openMenu()
            end
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id      = 'qv_preset',
        title   = 'Look',
        menu    = 'qv_main',
        options = options
    })
    lib.showContext('qv_preset')
end

-- ---------------------------------------------------------------------------
-- Submenu: kwaliteit
-- ---------------------------------------------------------------------------

local function openProfileMenu()
    local options = {
        {
            title       = 'Automatisch',
            description = 'Past zich aan je framerate aan',
            icon        = QV.state.profile == 'auto' and 'circle-check' or 'circle',
            onSelect    = function()
                QV.setProfile('auto')
                QV.notify('Kwaliteit: automatisch')
                openMenu()
            end
        }
    }

    for _, id in ipairs({ 'ultra', 'balanced', 'performance' }) do
        local profile = Config.Profiles[id]
        if profile then
            options[#options + 1] = {
                title       = profile.label,
                description = id == 'performance' and 'Minder detail, meer frames'
                    or id == 'ultra' and 'Maximale kwaliteit'
                    or 'Middenweg',
                icon     = QV.state.profile == id and 'circle-check' or 'circle',
                onSelect = function()
                    QV.setProfile(id)
                    QV.notify('Kwaliteit: ' .. profile.label)
                    openMenu()
                end
            }
        end
    end

    lib.registerContext({
        id      = 'qv_profile',
        title   = 'Kwaliteit',
        menu    = 'qv_main',
        options = options
    })
    lib.showContext('qv_profile')
end

-- ---------------------------------------------------------------------------
-- Hoofdmenu
-- ---------------------------------------------------------------------------

function openMenu()
    local s = QV.state
    local _, profileName = QV.quality()
    local profileLabel   = Config.Profiles[profileName].label

    if s.profile == 'auto' then
        profileLabel = ('Automatisch (%s)'):format(profileLabel)
    end

    local options = {
        {
            title       = s.enabled and 'Uitschakelen' or 'Inschakelen',
            description = s.enabled and 'Zet de grafische verbetering uit'
                or 'Zet de grafische verbetering aan',
            icon        = s.enabled and 'toggle-on' or 'toggle-off',
            onSelect    = function()
                QV.setEnabled(not s.enabled)
                QV.notify(s.enabled and 'Ingeschakeld' or 'Uitgeschakeld')
            end
        },
        {
            title       = 'Look',
            description = QV.presetData().label,
            icon        = 'palette',
            arrow       = true,
            onSelect    = openPresetMenu
        },
        {
            title       = 'Kwaliteit',
            description = profileLabel,
            icon        = 'gauge-high',
            arrow       = true,
            onSelect    = openProfileMenu
        },
        {
            title       = 'Blikveld',
            description = ('First person: %s | /%s fov <getal>'):format(
                (not Config.FirstPerson.enabled and 'uit')
                    or (s.fpExempt and 'vrijgesteld')
                    or 'verplicht',
                Config.Command
            ),
            icon     = 'eye',
            readOnly = true
        },
        {
            title       = 'Status',
            description = ('Scene: %s%s'):format(
                CONTEXT_LABEL[s.context] or 'geen',
                s.profile == 'auto' and s.fps > 0 and (' | %d fps'):format(s.fps) or ''
            ),
            icon     = 'circle-info',
            readOnly = true
        }
    }

    lib.registerContext({
        id      = 'qv_main',
        title   = 'Visuals',
        options = options
    })
    lib.showContext('qv_main')
end

-- ---------------------------------------------------------------------------
-- Commando en keybind
-- ---------------------------------------------------------------------------

RegisterCommand(Config.Command, function(_, args)
    local arg = (args[1] or ''):lower()

    if arg == '' then
        openMenu()
    elseif arg == 'on' then
        QV.setEnabled(true)
        QV.notify('Ingeschakeld')
    elseif arg == 'off' then
        QV.setEnabled(false)
        QV.notify('Uitgeschakeld')
    elseif Config.Presets[arg] then
        QV.setPreset(arg)
        QV.notify('Look: ' .. Config.Presets[arg].label)
    elseif arg == 'auto' or Config.Profiles[arg] then
        QV.setProfile(arg)
        QV.notify('Kwaliteit aangepast')
    elseif arg == 'fov' then
        local value = tonumber(args[2])
        if not value then
            -- Zonder getal: meet het huidige blikveld. Zo kun je zelf
            -- vaststellen of het zetten van de convar echt iets doet.
            QV.notify(('Huidig blikveld: %.1f graden. Zet met /%s fov <getal>.')
                :format(QV.getFieldOfView(), Config.Command))
        else
            -- Meten, zetten, opnieuw meten. Een command-handler mag zelf niet
            -- yielden, dus dat gaat in een eigen thread.
            CreateThread(function()
                local before = QV.getFieldOfView()
                if not QV.setFieldOfView(value) then return end
                Wait(500)
                local after = QV.getFieldOfView()

                QV.notify(('Gevraagd %d. Camera: %.1f -> %.1f%s'):format(
                    math.floor(value), before, after,
                    math.abs(after - before) < 0.1
                        and ' (onveranderd, de convar doet niets op deze build)'
                        or ''))
            end)
        end
    elseif arg == 'cam' then
        -- Eigen first-person camera aan/uit, om af te stellen.
        -- Geen argument = omschakelen.
        local sub, target = args[2] and args[2]:lower() or nil, nil
        if sub == 'on' then target = true elseif sub == 'off' then target = false end

        local state = QV.toggleCustomCam(target)
        QV.notify(('Eigen camera %s'):format(state and 'AAN' or 'UIT'))
    elseif arg == 'camfov' then
        if QV.setCustomCamFov(args[2]) then
            QV.notify(('Camera-FOV: %s'):format(args[2]))
        else
            QV.notify(('Gebruik: /%s camfov <getal>'):format(Config.Command), 'error')
        end
    elseif arg == 'nearclip' then
        if QV.setCustomCamNearClip(args[2]) then
            QV.notify(('Near clip: %s'):format(args[2]))
        else
            QV.notify(('Gebruik: /%s nearclip <getal>, bijvoorbeeld 0.15'):format(Config.Command), 'error')
        end
    else
        QV.notify('Onbekende optie: ' .. arg, 'error')
    end
end, false)

RegisterKeyMapping(Config.Command, 'Visuals-menu openen', 'keyboard', Config.Keybind)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command,
    'Grafische instellingen openen of direct aanpassen', {
        { name = 'optie', help = 'leeg = menu | on | off | preset | profiel | fov <n> | cam [on/off] | camfov <n> | nearclip <n>' }
    })

--[[
    qbx_visuals - core
    Gedeelde state, voorkeuren en helpers. Wordt als eerste geladen.
]]

QV = {
    state = {
        enabled     = Config.Enabled,
        preset      = Config.DefaultPreset,
        profile     = Config.DefaultProfile,
        autoProfile = Config.Auto.start,
        context     = nil,   -- huidige grading-context
        aerial      = false, -- speler is hoog in de lucht
        wet         = false, -- regen of sneeuw
        fps         = 0,

        -- First person. Hier gezet door firstperson.lua, gelezen door de
        -- per-frame thread in render.lua.
        blockCameraToggle = false,
        fpExempt          = false,
        fpActive          = false, -- first person wordt nu daadwerkelijk afgedwongen
        customCamActive   = false,
    }
}

local KVP_ENABLED = 'qbx_visuals:enabled'
local KVP_PRESET  = 'qbx_visuals:preset'
local KVP_PROFILE = 'qbx_visuals:profile'

local listeners = {}

-- ---------------------------------------------------------------------------
-- Events (intern, tussen de modules van deze resource)
-- ---------------------------------------------------------------------------

--- Registreert een callback die draait zodra de instellingen wijzigen.
function QV.onChange(fn)
    listeners[#listeners + 1] = fn
end

function QV.emit()
    for i = 1, #listeners do
        local ok, err = pcall(listeners[i])
        if not ok then print(('[qbx_visuals] listener fout: %s'):format(err)) end
    end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function QV.debug(msg, ...)
    if not Config.Debug then return end
    print(('[qbx_visuals] ' .. msg):format(...))
end

function QV.notify(msg, kind)
    lib.notify({
        title       = 'Visuals',
        description = msg,
        type        = kind or 'inform',
        position    = 'top-right'
    })
end

--- Het profiel dat op dit moment daadwerkelijk geldt.
--- @return table profile, string name
function QV.quality()
    local name = QV.state.profile
    if name == 'auto' then name = QV.state.autoProfile end
    local profile = Config.Profiles[name]
    if not profile then
        name = 'balanced'
        profile = Config.Profiles.balanced
    end
    return profile, name
end

function QV.presetData()
    return Config.Presets[QV.state.preset] or Config.Presets[Config.DefaultPreset]
end

-- ---------------------------------------------------------------------------
-- Voorkeuren
-- ---------------------------------------------------------------------------

function QV.savePrefs()
    if not Config.SavePreference then return end
    SetResourceKvp(KVP_ENABLED, QV.state.enabled and 'true' or 'false')
    SetResourceKvp(KVP_PRESET, QV.state.preset)
    SetResourceKvp(KVP_PROFILE, QV.state.profile)
end

local function loadPrefs()
    if not Config.SavePreference then return end

    local e = GetResourceKvpString(KVP_ENABLED)
    if e then QV.state.enabled = e == 'true' end

    local p = GetResourceKvpString(KVP_PRESET)
    if p and Config.Presets[p] then QV.state.preset = p end

    local q = GetResourceKvpString(KVP_PROFILE)
    if q and (q == 'auto' or Config.Profiles[q]) then QV.state.profile = q end
end

loadPrefs()

-- ---------------------------------------------------------------------------
-- Publieke setters
-- ---------------------------------------------------------------------------

function QV.setEnabled(value)
    QV.state.enabled = value and true or false
    QV.savePrefs()
    QV.emit()
end

function QV.setPreset(name)
    if not Config.Presets[name] then return false end
    QV.state.preset = name
    QV.savePrefs()
    QV.emit()
    return true
end

function QV.setProfile(name)
    if name ~= 'auto' and not Config.Profiles[name] then return false end
    QV.state.profile = name
    QV.savePrefs()
    QV.emit()
    return true
end

-- ---------------------------------------------------------------------------
-- Exports voor andere resources
-- ---------------------------------------------------------------------------

exports('isEnabled', function() return QV.state.enabled end)
exports('setEnabled', function(v) QV.setEnabled(v) end)
exports('getPreset',  function() return QV.state.preset end)
exports('setPreset',  function(v) return QV.setPreset(v) end)
exports('getProfile', function() local _, n = QV.quality() return n end)
exports('setProfile', function(v) return QV.setProfile(v) end)
exports('getContext', function() return QV.state.context end)

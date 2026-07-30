--[[
    qbx_visuals - grading

    Bepaalt de context (weer / tijd / binnen / lucht) en zet de bijpassende
    timecycle-modifier. De overgang laten we door GTA zelf doen met
    SET_TRANSITION_TIMECYCLE_MODIFIER, dus er is geen blend-thread nodig.

    Deze module draait op Config.UpdateInterval, niet per frame.
]]

local G = Config.Grading

-- ---------------------------------------------------------------------------
-- Weer -> klasse
-- ---------------------------------------------------------------------------

local WEATHER_CLASS = {
    [`CLEAR`]      = 'clear',
    [`EXTRASUNNY`] = 'clear',
    [`NEUTRAL`]    = 'clear',
    [`HALLOWEEN`]  = 'clear',

    [`CLOUDS`]     = 'overcast',
    [`OVERCAST`]   = 'overcast',

    [`RAIN`]       = 'rain',
    [`THUNDER`]    = 'rain',
    [`CLEARING`]   = 'rain',

    [`FOGGY`]      = 'fog',
    [`SMOG`]       = 'fog',

    [`SNOW`]       = 'snow',
    [`SNOWLIGHT`]  = 'snow',
    [`BLIZZARD`]   = 'snow',
    [`XMAS`]       = 'snow',
}

local function weatherClass()
    local prev = GetPrevWeatherTypeHashName()
    local next_ = GetNextWeatherTypeHashName()
    -- Zit er een overgang aan te komen, dan alvast op het nieuwe weer
    -- gradeeren; onze eigen overgang duurt toch nog een seconde.
    local hash = (next_ ~= 0 and next_ ~= prev) and next_ or prev
    return WEATHER_CLASS[hash] or 'clear'
end

local function timeClass()
    local h = GetClockHours()
    local t = Config.Time
    if h >= t.night or h < t.dawn then return 'night' end
    if h < t.day then return 'dawn' end
    if h >= t.dusk then return 'dusk' end
    return 'day'
end

-- ---------------------------------------------------------------------------
-- Context
-- ---------------------------------------------------------------------------

--- @return string|nil context, of nil wanneer er geen grading hoort te staan
local function getContext()
    local ped = PlayerPedId()
    local s   = QV.state

    -- Niet ingrijpen waar het spel of een ander script zijn eigen look nodig
    -- heeft.
    if IsCutsceneActive() or NetworkIsInSpectatorMode() or IsPlayerSwitchInProgress() then
        s.aerial, s.wet = false, false
        return nil
    end
    if IsPedSwimmingUnderWater(ped) or IsPedDeadOrDying(ped, true) then
        s.aerial, s.wet = false, false
        return nil
    end

    local wc = weatherClass()
    s.wet = (wc == 'rain' or wc == 'snow')

    if GetInteriorFromEntity(ped) ~= 0 then
        s.aerial = false
        return 'interior'
    end

    s.aerial = GetEntityHeightAboveGround(ped) > G.aerialHeight
    if s.aerial then return 'aerial' end

    local tc = timeClass()

    if wc == 'rain' then
        return tc == 'night' and 'rain_night' or 'rain_day'
    elseif wc == 'fog' then
        return 'fog'
    elseif wc == 'snow' then
        return 'snow'
    elseif wc == 'overcast' then
        return tc == 'night' and 'night' or 'overcast'
    end

    return tc -- day / dawn / dusk / night
end

-- ---------------------------------------------------------------------------
-- Toepassen
-- ---------------------------------------------------------------------------

local applied    = false
local ownedIndex = -1
local yieldUntil = 0

local function release()
    if applied then
        SetTransitionOutOfTimecycleModifier(1.0)
    end
    applied         = false
    ownedIndex      = -1
    QV.state.context = nil
end

local function apply(ctx)
    local preset = QV.presetData()
    local mods   = Config.ModSets[preset.mods] or Config.ModSets.full
    local mod    = mods[ctx]
    if not mod then return end

    local strength = preset.strength * (Config.ContextStrength[ctx] or 1.0)
    if strength > 1.0 then strength = 1.0 elseif strength < 0.0 then strength = 0.0 end

    SetTransitionTimecycleModifier(mod, G.transitionSpeed)
    SetTimecycleModifierStrength(strength)

    QV.state.context = ctx
    applied    = true
    ownedIndex = -1 -- pas na de overgang vastleggen

    QV.debug('context %s -> %s (strength %.2f)', ctx, mod, strength)
end

local function tick()
    local s = QV.state

    if not s.enabled then
        if applied then release() end
        return
    end

    -- Heeft een ander script onze slot overgenomen? Dan gaan we er niet mee
    -- vechten: even loslaten en later opnieuw proberen.
    if applied then
        local idx = GetTimecycleModifierIndex()
        if ownedIndex == -1 then
            ownedIndex = idx
        elseif idx ~= ownedIndex then
            QV.debug('timecycle-slot overgenomen door ander script, we laten los')
            applied     = false
            ownedIndex  = -1
            s.context   = nil
            yieldUntil  = GetGameTimer() + G.yieldTime
            return
        end
    end

    local ctx = getContext()

    if not ctx then
        if applied then release() end
        return
    end

    if applied and ctx == s.context then return end

    if not applied then
        if GetGameTimer() < yieldUntil then return end
        -- Alleen de slot pakken als niemand anders hem gebruikt.
        if GetTimecycleModifierIndex() ~= -1 then return end
    end

    apply(ctx)
end

-- ---------------------------------------------------------------------------
-- Tweede timecycle-slot (constante, zeer subtiele filmlaag)
--
-- Deze slot heeft geen sterkte-native, dus het is aan of uit. 'pr_film' is
-- daarom expres bijna onzichtbaar afgesteld.
-- ---------------------------------------------------------------------------

local extraOn = false

local function updateExtraLayer()
    local want = QV.state.enabled and G.extraLayer and true or false
    if want == extraOn then return end

    if want then
        SetExtraTimecycleModifier(G.extraLayerMod)
    else
        ClearExtraTimecycleModifier()
    end
    extraOn = want
end

-- ---------------------------------------------------------------------------
-- Loop
-- ---------------------------------------------------------------------------

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(2000)

    while true do
        updateExtraLayer()
        tick()
        Wait(Config.UpdateInterval)
    end
end)

-- Direct reageren op een toggle of presetwissel in plaats van tot de
-- volgende tick wachten.
QV.onChange(function()
    QV.state.context = nil
    updateExtraLayer()
    tick()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
end)

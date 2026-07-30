--[[
    qbx_visuals - visualsettings

    Overschrijft waardes uit het spel-bestand visualsettings.dat.

    Dit gaat NIET via data_file: er bestaat geen VISUAL_SETTINGS_FILE type.
    In plaats daarvan lezen we ons eigen bestand op de client in en zetten we
    elke regel via SET_VISUAL_SETTING_FLOAT.

    Die native staat niet in de gedocumenteerde natives-lijst, maar bestaat
    wel: joaat("SET_VISUAL_SETTING_FLOAT") == 0xD1D31681, en dat is precies de
    hash waaronder docs.fivem.net hem kent. We roepen hem daarom direct met
    die hash aan in plaats van hem elke keer opnieuw te hashen.

    Alleen de sleutels die in het bestand staan worden overschreven. Alles wat
    je weglaat houdt zijn standaardwaarde, dus een onvolledig bestand is
    veilig.
]]

local SET_VISUAL_SETTING_FLOAT <const> = 0xD1D31681

local cfg = Config.VisualSettings

--- Leest 'sleutel   waarde' regels. Alles achter # of // is commentaar.
--- @return table<string, number>
local function parse(contents)
    local settings = {}

    for line in contents:gmatch('[^\r\n]+') do
        -- Commentaar en lege regels overslaan.
        local trimmed = line:match('^%s*(.-)%s*$')
        if trimmed ~= ''
            and trimmed:sub(1, 1) ~= '#'
            and trimmed:sub(1, 2) ~= '//'
        then
            local key, value = trimmed:match('^(%S+)%s+(%-?[%d%.]+)')
            if key and value then
                local number = tonumber(value)
                if number then settings[key] = number end
            end
        end
    end

    return settings
end

local function apply()
    if not cfg.enabled then return end

    local contents = LoadResourceFile(GetCurrentResourceName(), cfg.file)
    if not contents or contents == '' then
        print(('[qbx_visuals] %s niet gevonden of leeg - visualsettings overgeslagen')
            :format(cfg.file))
        return
    end

    local settings = parse(contents)
    local applied, skipped = 0, 0

    for key, value in pairs(settings) do
        if cfg.ignore[key] then
            skipped = skipped + 1
        else
            -- pcall zodat een enkele onbekende sleutel de rest niet meesleept.
            local ok = pcall(Citizen.InvokeNative, SET_VISUAL_SETTING_FLOAT, key, value + 0.0)
            if ok then applied = applied + 1 else skipped = skipped + 1 end
        end
    end

    QV.debug('visualsettings: %d toegepast, %d overgeslagen', applied, skipped)
    return applied, skipped
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(1000)
    apply()
end)

-- Opnieuw toepassen na een respawn of sessiewissel is niet nodig: deze
-- waardes zijn globaal en blijven staan tot de client herstart.

exports('reloadVisualSettings', function()
    return apply()
end)

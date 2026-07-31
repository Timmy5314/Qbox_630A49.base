local config = require 'shared.config'

---@param msg string
local function dbg(msg)
    if config.debug then lib.print.info(msg) end
end

-- =========================================================================
--  Rate-limited wachtrij
--
--  Discord gooit je eruit als je te snel post. Alles gaat daarom door één
--  wachtrij die zichzelf afknijpt; een piek aan meldingen wordt uitgesmeerd in
--  plaats van half weggegooid.
-- =========================================================================

local queue = {}
local dropped = 0

---@param text string?
---@return string?
local function sanitise(text)
    if type(text) ~= 'string' then return end

    -- Geen identifiers in een log. Zie de privacy-sectie in de config.
    if config.privacy.stripIdentifiers then
        text = text:gsub('license:%w+', '[license]')
            :gsub('steam:%w+', '[steam]')
            :gsub('discord:%d+', '[discord]')
            :gsub('fivem:%d+', '[fivem]')
    end

    if #text > config.privacy.maxTextLength then
        text = text:sub(1, config.privacy.maxTextLength) .. '...'
    end

    return text
end

---Zet een bericht in de wachtrij.
---@param channel string sleutel uit Config.channels
---@param title string
---@param description string?
---@param fields table? lijst van {name, value}
local function log(channel, title, description, fields)
    local settings = config.channels[channel]
    if not settings then return end

    local url = GetConvar(settings.convar, '')
    if url == '' then return end

    if #queue >= config.rateLimit.queueMax then
        dropped = dropped + 1
        return
    end

    local embed = {
        title = sanitise(title),
        description = sanitise(description),
        color = settings.color,
        footer = { text = settings.label },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }

    if type(fields) == 'table' then
        embed.fields = {}
        for i = 1, #fields do
            embed.fields[i] = {
                name = sanitise(fields[i].name) or '?',
                value = sanitise(fields[i].value) or '-',
                inline = fields[i].inline and true or false,
            }
        end
    end

    queue[#queue + 1] = { url = url, embed = embed }
end

exports('Log', log)

CreateThread(function()
    local interval = math.floor(60000 / config.rateLimit.perMinute)

    while true do
        Wait(interval)

        local item = table.remove(queue, 1)
        if item then
            PerformHttpRequest(item.url, function(status)
                if status ~= 204 and status ~= 200 then
                    dbg(('webhook gaf status %s'):format(status))
                end
            end, 'POST', json.encode({
                username = 'Los Balos RP',
                embeds = { item.embed },
            }), { ['Content-Type'] = 'application/json' })
        end

        if dropped > 0 and #queue == 0 then
            dbg(('%d berichten weggegooid omdat de wachtrij vol zat'):format(dropped))
            dropped = 0
        end
    end
end)

-- =========================================================================
--  Wat er gelogd wordt
-- =========================================================================

--- Meldkamer. ps-dispatch bewaart elke melding server-side.
AddEventHandler('ps-dispatch:server:notify', function(data)
    if type(data) ~= 'table' then return end

    log('dispatch', ('%s %s'):format(data.code or '10-80', data.message or ''), data.street, {
        { name = 'Straat', value = data.street or '-', inline = true },
        { name = 'Code', value = data.code or '-', inline = true },
    })
end)

--- Anti-cheat. los_anticheat vuurt dit af bij elke flag.
AddEventHandler('los_anticheat:flag', function(src, check, detail)
    local name = src and GetPlayerName(src) or 'onbekend'

    log('anticheat', ('Flag: %s'):format(check or '?'), detail, {
        { name = 'Speler', value = ('%s (%s)'):format(name, src or '-'), inline = true },
    })
end)

--- Wipe.
AddEventHandler('los_wipe:announced', function(message)
    log('wipe', 'Maandelijkse wipe', message)
end)

-- =========================================================================
--  Rol-sync
--
--  De FiveM-kant bepaalt WELKE rol erbij hoort; de bot kent hem toe. Dat kan
--  niet anders: rollen zetten vraagt een bot-token, en dat hoort niet op een
--  gameserver.
-- =========================================================================

---Bouwt de gewenste rolstand op. De bot haalt dit op via zijn eigen endpoint.
---@return table
local function buildRoleState()
    local out = {}
    local players = exports.qbx_core:GetQBPlayers()

    for _, player in pairs(players) do
        local data = player.PlayerData
        local discord

        for _, id in pairs(GetPlayerIdentifiers(data.source) or {}) do
            local match = id:match('^discord:(%d+)$')
            if match then discord = match break end
        end

        if discord then
            local roles = {}

            local jobRole = data.job and config.roles.jobs[data.job.name]
            if jobRole and jobRole ~= '' then roles[#roles + 1] = jobRole end

            local gangRole = data.gang and config.roles.gangs[data.gang.name]
            if gangRole and gangRole ~= '' then roles[#roles + 1] = gangRole end

            out[discord] = roles
        end
    end

    return out
end

exports('GetRoleState', buildRoleState)

--- De bot vraagt dit op; hij draait naast de server en heeft geen andere manier
--- om te weten wie welke job heeft.
lib.callback.register('los_discord:roleState', function()
    return buildRoleState()
end)

CreateThread(function()
    Wait(15000)

    while true do
        local state = buildRoleState()
        local count = 0
        for _ in pairs(state) do count = count + 1 end

        dbg(('rolstand opgebouwd voor %d spelers'):format(count))
        TriggerEvent('los_discord:roleStateReady', state)

        Wait(config.syncMinutes * 60000)
    end
end)

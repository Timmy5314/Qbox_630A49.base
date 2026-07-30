---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - discord logging

    SERVER ONLY. Webhook urls are deliberately kept out of config/ because
    everything in config/ is a shared_script and therefore downloaded by every
    client that connects.
]]

-- ─────────────────────────────────────────────────────────────────────────────
-- Configuration
-- ─────────────────────────────────────────────────────────────────────────────

Config.Logging = {
    enabled = false,

    botName = 'renzu_jobs',
    avatar  = '',

    --- Used whenever a feature has no webhook of its own.
    default = '',

    --- Per feature webhooks. Leave empty to fall back to `default`.
    webhooks = {
        bossmenu    = '',
        stash       = '',
        shop        = '',
        crafting    = '',
        armory      = '',
        garage      = '',
        vehicleshop = '',
        turf        = '',
    },

    --- Embed colours per severity.
    colors = {
        info    = 3447003,
        success = 3066993,
        warning = 16776960,
        error   = 15158332,
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

Logs = {}

---@param value number
---@return string
local function money(value)
    local formatted = tostring(math.floor(tonumber(value) or 0))
    local matches = 1
    while matches > 0 do
        formatted, matches = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
    end
    return formatted
end

---@param feature string key in Config.Logging.webhooks
---@param override string? per-feature webhook from config/jobs.lua
---@return string? url
local function resolveWebhook(feature, override)
    if type(override) == 'string' and override ~= '' then return override end

    local url = Config.Logging.webhooks[feature]
    if type(url) == 'string' and url ~= '' then return url end

    url = Config.Logging.default
    if type(url) == 'string' and url ~= '' then return url end

    return nil
end

--- The "who did this" block shared by every embed.
---@param src number
---@return table[] fields
local function actorFields(src)
    local player = Bridge.getPlayer(src)
    if not player then
        return { { name = 'Player', value = ('Unknown (%s)'):format(src), inline = false } }
    end

    local job = Bridge.getJob(src)
    return {
        {
            name   = 'Player',
            value  = ('%s\n`%s`'):format(Bridge.getFullName(player), player.PlayerData.citizenid),
            inline = true,
        },
        {
            name   = 'Job',
            value  = job and ('%s (grade %d)'):format(job.label, job.grade) or 'None',
            inline = true,
        },
        {
            name   = 'Server ID',
            value  = tostring(src),
            inline = true,
        },
    }
end

--- Send a structured embed.
---@param opts { feature: string, webhook: string?, title: string, description: string?, severity: string?, source: number?, fields: table[]? }
function Logs.send(opts)
    if not Config.Logging.enabled then return end

    local url = resolveWebhook(opts.feature, opts.webhook)
    if not url then return end

    local fields = {}
    if opts.source then
        for _, field in ipairs(actorFields(opts.source)) do
            fields[#fields + 1] = field
        end
    end
    if opts.fields then
        for _, field in ipairs(opts.fields) do
            fields[#fields + 1] = field
        end
    end

    local payload = {
        username = Config.Logging.botName,
        embeds = { {
            title       = opts.title,
            description = opts.description,
            color       = Config.Logging.colors[opts.severity or 'info'] or Config.Logging.colors.info,
            fields      = fields,
            footer      = { text = ('renzu_jobs • %s'):format(os.date('%Y-%m-%d %H:%M:%S')) },
        } },
    }
    if Config.Logging.avatar ~= '' then payload.avatar_url = Config.Logging.avatar end

    PerformHttpRequest(url, function(status)
        if status ~= 200 and status ~= 204 then
            lib.print.warn(('discord webhook for "%s" returned status %s'):format(opts.feature, status))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

--- Convenience helper for money movements.
---@param feature string
---@param src number
---@param action string
---@param amount number
---@param extra table[]?
function Logs.money(feature, src, action, amount, extra)
    local fields = {
        { name = 'Amount', value = ('$%s'):format(money(amount)), inline = true },
    }
    if extra then
        for _, field in ipairs(extra) do fields[#fields + 1] = field end
    end

    Logs.send({
        feature  = feature,
        title    = action,
        severity = 'info',
        source   = src,
        fields   = fields,
    })
end

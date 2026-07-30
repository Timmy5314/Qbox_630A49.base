---Score-engine: verzamelt flags, laat ze vervallen, en voert acties uit.
---
---Geen enkele detectie leidt direct tot een ban. Alles wordt gescoord, want elke
---losse check heeft false positives (sync-hikken, pakketverlies, interior-laden).
---Pas een opeenstapeling binnen korte tijd is bewijs.

local sessions = {}      ---@type table<number, {score: number, flags: table[], citizenid: string?}>
local bannedCache = {}   ---@type table<string, {reason: string, expires: number?}>

-- =========================================================================
--  Helpers
-- =========================================================================

---@param source number
---@return string? license
local function getLicense(source)
    return GetPlayerIdentifierByType(source, 'license') or GetPlayerIdentifierByType(source, 'fivem')
end

---@param source number
---@return string?
local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.citizenid
end

---@param source number
local function getSession(source)
    local session = sessions[source]
    if not session then
        session = { score = 0, flags = {}, citizenid = getCitizenId(source), lastAction = 0 }
        sessions[source] = session
    end
    return session
end

---@param message string
local function log(message)
    if Config.verbose then
        print(('[los_anticheat] %s'):format(message))
    end
end

---Stuurt een flag naar Discord. Faalt stil: een kapotte webhook mag nooit de
---anti-cheat blokkeren.
---@param title string
---@param description string
local function sendWebhook(title, description)
    local url = GetConvar(Config.webhookConvar, '')
    if url == '' then return end

    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'Los Balos Anti-Cheat',
        embeds = { {
            title = title,
            description = description,
            color = 15158332,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
        } },
    }), { ['Content-Type'] = 'application/json' })
end

-- =========================================================================
--  Bans
-- =========================================================================

---@param license string
---@param reason string
---@param minutes number 0 = permanent
---@param evidence table
local function persistBan(license, reason, minutes, evidence)
    local expires = minutes > 0 and (os.time() + minutes * 60) or nil

    bannedCache[license] = { reason = reason, expires = expires }

    MySQL.insert('INSERT INTO los_anticheat_bans (license, reason, evidence, expires) VALUES (?, ?, ?, ?)', {
        license, reason, json.encode(evidence), expires,
    })
end

---@param source number
---@return {reason: string, expires: number?}?
function AC_GetBan(source)
    local license = getLicense(source)
    if not license then return end

    local ban = bannedCache[license]
    if not ban then return end

    if ban.expires and ban.expires < os.time() then
        bannedCache[license] = nil
        return
    end

    return ban
end

---Laadt actieve bans in het geheugen. Bij een lege of ontbrekende tabel gaat de
---resource gewoon door: liever draaien zonder bancache dan helemaal niet starten.
local function loadBans()
    local ok, rows = pcall(MySQL.query.await,
        'SELECT license, reason, expires FROM los_anticheat_bans WHERE expires IS NULL OR expires > ?', { os.time() })

    if not ok or not rows then
        log('WAARSCHUWING: los_anticheat_bans niet leesbaar. Draai install/anticheat.sql. Bans zijn nu niet actief.')
        return
    end

    for i = 1, #rows do
        bannedCache[rows[i].license] = { reason = rows[i].reason, expires = rows[i].expires }
    end

    log(('%d actieve bans geladen.'):format(#rows))
end

-- =========================================================================
--  Acties
-- =========================================================================

---@param source number
---@param session table
---@param threshold table
local function applyAction(source, session, threshold)
    local name = GetPlayerName(source) or ('id %d'):format(source)
    local summary = {}
    for i = 1, #session.flags do
        local flag = session.flags[i]
        summary[#summary + 1] = ('%s (%d) %s'):format(flag.check, flag.points, flag.detail or '')
    end
    local evidence = table.concat(summary, '\n')

    if Config.dryRun then
        log(('DRY RUN - zou %s uitvoeren op %s (score %d)\n%s'):format(threshold.action, name, session.score, evidence))
        sendWebhook(('[DRY RUN] %s: %s'):format(threshold.action, name), evidence)
        return
    end

    if threshold.action == 'warn' then
        sendWebhook(('Waarschuwing: %s (score %d)'):format(name, session.score), evidence)
        return
    end

    if threshold.action == 'kick' then
        sendWebhook(('Kick: %s (score %d)'):format(name, session.score), evidence)
        DropPlayer(source, locale('kick_reason'))
        return
    end

    if threshold.action == 'ban' then
        local license = getLicense(source)
        if license then
            persistBan(license, locale('ban_reason'), threshold.banMinutes or 0, session.flags)
        end
        sendWebhook(('BAN: %s (score %d)'):format(name, session.score), evidence)
        DropPlayer(source, locale('ban_reason'))
    end
end

-- =========================================================================
--  Publieke API
-- =========================================================================

---Registreert een detectie.
---@param source number
---@param check string Sleutel uit Config.weights
---@param detail string? Mensleesbare toelichting, komt in het bewijs
---@param meta table? Extra data voor het review-menu
function AC_Flag(source, check, detail, meta)
    if not source or source <= 0 then return end

    local points = Config.weights[check]
    if not points or points == 0 then return end

    local session = getSession(source)
    session.score = session.score + points
    session.flags[#session.flags + 1] = {
        check = check,
        points = points,
        detail = detail,
        meta = meta,
        time = os.time(),
    }

    log(('FLAG %s | %s +%d (totaal %d) | %s'):format(
        GetPlayerName(source) or source, check, points, session.score, detail or ''))

    MySQL.insert('INSERT INTO los_anticheat_flags (license, citizenid, name, check_name, points, detail, meta) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        getLicense(source), session.citizenid, GetPlayerName(source), check, points, detail, meta and json.encode(meta) or nil,
    })

    for i = 1, #Config.score.thresholds do
        local threshold = Config.score.thresholds[i]
        if session.score >= threshold.points then
            -- Alleen handelen als we een ZWAARDERE drempel raken dan de vorige keer.
            -- Zonder deze check vuurt elke volgende flag boven de warn-drempel
            -- opnieuw een webhook af en loop je Discord vol.
            if threshold.points > session.lastAction then
                session.lastAction = threshold.points
                applyAction(source, session, threshold)
            end
            return
        end
    end
end

exports('Flag', AC_Flag)

---@param source number
---@return number
function AC_GetScore(source)
    local session = sessions[source]
    return session and session.score or 0
end

exports('GetScore', AC_GetScore)

---@param source number
---@return table[]
function AC_GetFlags(source)
    local session = sessions[source]
    return session and session.flags or {}
end

exports('GetFlags', AC_GetFlags)

---Markeert een check als false positive: verlaagt het gewicht permanent in de DB
---zodat de volgende sessie er minder zwaar aan tilt.
---@param check string
function AC_MarkFalsePositive(check)
    local current = Config.weights[check]
    if not current then return end

    Config.weights[check] = math.max(0, math.floor(current / 2))
    log(('False positive gemeld voor %s: gewicht %d -> %d'):format(check, current, Config.weights[check]))
end

exports('MarkFalsePositive', AC_MarkFalsePositive)

-- =========================================================================
--  Levenscyclus
-- =========================================================================

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)

---Ban-check bij verbinden. Deferrals zodat de speler een reden ziet.
AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    local ban = AC_GetBan(src)
    if not ban then
        deferrals.done()
        return
    end

    local until_ = ban.expires and os.date('%Y-%m-%d %H:%M', ban.expires) or 'permanent'
    deferrals.done(locale('ban_connect', ban.reason, until_))
end)

---Score-decay. Draait elke minuut en is daarmee verwaarloosbaar duur.
CreateThread(function()
    while true do
        Wait(60000)
        for _, session in pairs(sessions) do
            if session.score > 0 then
                session.score = math.max(0, session.score - Config.score.decayPerMinute)

                -- Zakt de score onder de laatst geraakte drempel, dan mag die
                -- drempel later opnieuw vuren.
                if session.score < session.lastAction then
                    session.lastAction = session.score
                end
            end
        end
    end
end)

CreateThread(function()
    Wait(2000) -- oxmysql tijd geven om te verbinden
    loadBans()

    if Config.dryRun then
        log('DRY RUN staat AAN. Er wordt niemand gekickt of gebanned, alleen gelogd.')
        log('Zet Config.dryRun op false in shared/config.lua zodra de logs schoon zijn.')
    end
end)

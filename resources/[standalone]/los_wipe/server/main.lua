local config = require 'shared.config'

local running = false

---@param msg string
local function log(msg)
    print(('[los_wipe] %s'):format(msg))
end

---@return string
local function today()
    return os.date('%Y-%m-%d')
end

--[[
    Mag de wipe echt draaien?

    Geeft false terug met een reden zodra één van de drie sloten dicht zit. De
    droogloop mag altijd; die raakt niets aan.
]]
---@return boolean live
---@return string reason
local function canRunLive()
    if config.dryRun then return false, 'dryRun staat aan' end
    if not config.armed then return false, 'armed staat op false' end

    if config.dumpConfirmed ~= today() then
        return false, ('dumpConfirmed is "%s", vandaag is %s'):format(config.dumpConfirmed, today())
    end

    return true, 'alle drie de sloten open'
end

-- =========================================================================
--  Wat gaat er weg
-- =========================================================================

---Telt wat de wipe zou raken. Draait ook in droogloop, want dit is precies wat
---je wilt zien voordat je hem scherp zet.
---@return table
local function survey()
    local counts = {}

    local function scalar(query)
        local ok, result = pcall(function() return MySQL.scalar.await(query) end)
        return ok and tonumber(result) or 0
    end

    counts.players = scalar('SELECT COUNT(*) FROM players')

    if config.wipe.vehicles then
        counts.vehicles = scalar('SELECT COUNT(*) FROM player_vehicles')
    end

    if config.wipe.inventories then
        -- ox_inventory bewaart stashes in zijn eigen tabel; kofferbakken en
        -- dashboardkastjes staan als kolom op player_vehicles.
        counts.stashes = scalar('SELECT COUNT(*) FROM ox_inventory')
    end

    if config.wipe.properties then
        counts.properties = scalar('SELECT COUNT(*) FROM properties')
    end

    return counts
end

---Momentopname van wat er geraakt wordt. Geen vervanging van een mysqldump,
---wel een vangnet als er iets misgaat.
---@return boolean
local function snapshot()
    local data = {
        takenAt = os.date('%Y-%m-%d %H:%M:%S'),
        counts = survey(),
        config = config.wipe,
    }

    local ok = pcall(function()
        local rows = MySQL.query.await('SELECT citizenid, money FROM players') or {}
        data.money = rows

        if config.wipe.vehicles then
            data.vehicles = MySQL.query.await('SELECT plate, citizenid FROM player_vehicles') or {}
        end
    end)

    if not ok then
        log('momentopname mislukt - wipe gaat NIET door')
        return false
    end

    local name = ('snapshot_%s.json'):format(os.date('%Y%m%d_%H%M%S'))
    local written = SaveResourceFile(GetCurrentResourceName(), 'snapshots/' .. name, json.encode(data), -1)

    if not written then
        log('momentopname kon niet worden weggeschreven - wipe gaat NIET door')
        return false
    end

    log(('momentopname weggeschreven: snapshots/%s'):format(name))
    return true
end

-- =========================================================================
--  De wipe
-- =========================================================================

local function performWipe(live)
    local counts = survey()

    log(('--- WIPE %s ---'):format(live and 'ECHT' or 'DROOGLOOP'))
    for key, value in pairs(counts) do
        log(('  %s: %d'):format(key, value))
    end

    if not live then
        log('droogloop: er is niets gewijzigd')
        return counts
    end

    if config.wipe.money then
        local money = json.encode(config.startingMoney)
        MySQL.update.await('UPDATE players SET money = ?', { money })
        log('geld teruggezet')
    end

    if config.wipe.vehicles then
        MySQL.update.await('DELETE FROM player_vehicles')
        log('voertuigen verwijderd')
    end

    if config.wipe.inventories then
        MySQL.update.await('UPDATE players SET inventory = ?', { '[]' })
        MySQL.update.await('DELETE FROM ox_inventory')
        log('inventories geleegd')
    end

    if config.wipe.properties then
        MySQL.update.await('DELETE FROM properties')
        log('eigendommen verwijderd')
    end

    -- Characters, identiteiten en accounts blijven staan. Bewust geen optie.
    log('characters en identiteiten zijn NIET aangeraakt')

    return counts
end

---@param message string
local function announce(message)
    log(message)

    local players = GetPlayers()
    for i = 1, #players do
        exports.qbx_core:Notify(tonumber(players[i]), message, 'error', 15000)
    end

    -- Discord: bij voorkeur via de centrale logger (los_discord), zodat alle
    -- meldingen door één rate-limited wachtrij lopen. Draait los_discord niet,
    -- dan valt hij terug op de eigen webhook-convar.
    if GetResourceState('los_discord') == 'started' then
        local ok = pcall(function()
            exports.los_discord:Log('wipe', 'Maandelijkse wipe', message)
        end)
        if ok then return end
    end

    local webhook = GetConvar(config.webhookConvar, '')
    if webhook == '' then return end

    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = 'Los Balos RP',
        embeds = { {
            title = 'Maandelijkse wipe',
            description = message,
            color = 15158332,
        } },
    }), { ['Content-Type'] = 'application/json' })
end

---@param live boolean
local function runWipe(live)
    if running then return end
    running = true

    if live then
        for i = 1, #config.warnMinutes do
            local minutes = config.warnMinutes[i]
            announce(('De maandelijkse wipe begint over %d minuten.'):format(minutes))

            local next = config.warnMinutes[i + 1] or 0
            Wait((minutes - next) * 60000)
        end

        if not snapshot() then
            running = false
            return
        end
    end

    performWipe(live)

    if live then
        announce('De wipe is uitgevoerd. Je character en identiteit zijn behouden.')
    end

    running = false
end

-- =========================================================================
--  Planning
-- =========================================================================

CreateThread(function()
    Wait(10000)

    local live, reason = canRunLive()
    log(('gestart. %s.'):format(reason))
    if not live then
        log('een wipe zou nu als droogloop draaien. Zie shared/config.lua.')
    end

    local lastRun = ''

    while true do
        Wait(60000)

        local now = os.date('*t')
        local stamp = os.date('%Y-%m-%d')

        if now.day == config.dayOfMonth and now.hour == config.hour and lastRun ~= stamp then
            lastRun = stamp
            runWipe((canRunLive()))
        end
    end
end)

lib.addCommand('wipedryrun', {
    help = 'Toon wat een wipe nu zou doen, zonder iets te wijzigen',
    restricted = 'group.admin',
}, function(source)
    local counts = performWipe(false)
    local parts = {}

    for key, value in pairs(counts) do
        parts[#parts + 1] = ('%s: %d'):format(key, value)
    end

    exports.qbx_core:Notify(source, 'Droogloop', 'inform', 15000, table.concat(parts, ' | '))
end)

lib.addCommand('wipenow', {
    help = 'Voert de wipe direct uit. Alleen als alle drie de sloten open staan.',
    restricted = 'group.god',
}, function(source)
    local live, reason = canRunLive()

    if not live then
        return exports.qbx_core:Notify(source, ('Wipe geweigerd: %s'):format(reason), 'error', 15000)
    end

    exports.qbx_core:Notify(source, 'Wipe gestart.', 'inform', 10000)
    runWipe(true)
end)

---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - turf wars (server)

    A war is a scored contest, not a "first person to hold E wins" race:

      * every second, each gang member standing on the capture point earns
        pointsPerSecond for their gang (capped at maxStack members)
      * if members of two or more different gangs are within contestRadius the
        point is CONTESTED and nobody scores
      * when the timer expires the highest scoring gang owns the territory

    The scoring loop only runs while a war is actually live. Outside of a war
    this file costs one os.date() check per minute.
]]

Turf = {}

--- turf -> { owner, ownerLabel, claimedAt, vaultAt }
local owners = {}

--- Live war state, mirrored to clients through GlobalState.
local war = nil

--- Guards so announcements cannot spam.
local lastLeadAnnounce = 0
local lastIntervalAnnounce = 0

-- ─────────────────────────────────────────────────────────────────────────────
-- State sync
-- ─────────────────────────────────────────────────────────────────────────────

local function pushOwners()
    GlobalState:set('TurfOwners', owners, true)
end

local function pushWar()
    if not war then
        GlobalState:set('TurfWar', false, true)
        return
    end

    GlobalState:set('TurfWar', {
        turf      = war.turf,
        label     = Config.Turfs[war.turf].label,
        endsAt    = war.endsAt,
        scores    = war.scores,
        leader    = war.leader,
        contested = war.contested,
    }, true)
end

---@param turfId string
---@return table? owner
function Turf.getOwner(turfId)
    return owners[turfId]
end

---@param src number
---@return string? gang job name
local function gangOf(src)
    local job = Bridge.getJob(src)
    if not job then return nil end
    if Config.TurfWar.blacklistedJobs[job.name] then return nil end
    return job.name, job.label
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Starting and ending a war
-- ─────────────────────────────────────────────────────────────────────────────

---@param turfId string
---@return boolean started
function Turf.start(turfId)
    if not Config.TurfWar.enabled then return false end
    if war then
        lib.print.warn(('cannot start "%s", a war on "%s" is already running'):format(turfId, war.turf))
        return false
    end

    local turf = Config.Turfs[turfId]
    if not turf then
        lib.print.warn(('unknown turf "%s"'):format(tostring(turfId)))
        return false
    end

    war = {
        turf      = turfId,
        endsAt    = os.time() + Config.TurfWar.duration,
        scores    = {},
        labels    = {},
        leader    = nil,
        contested = false,
    }

    lastLeadAnnounce = 0
    lastIntervalAnnounce = os.time()

    -- Ownership is cleared for the duration: it is up for grabs again.
    local previous = owners[turfId]
    owners[turfId] = nil
    pushOwners()
    pushWar()

    Bridge.announce('warning', 'Turf War',
        previous
            and ('%s is under attack. %s has %d minutes to defend it.'):format(
                    turf.label, previous.ownerLabel or previous.owner, math.floor(Config.TurfWar.duration / 60))
            or ('%s is up for grabs. The war runs for %d minutes.'):format(
                    turf.label, math.floor(Config.TurfWar.duration / 60)))

    Logs.send({
        feature = 'turf', title = 'Turf war started', severity = 'warning',
        fields = {
            { name = 'Territory',       value = turf.label, inline = true },
            { name = 'Previous owner',  value = previous and (previous.ownerLabel or previous.owner) or 'None', inline = true },
            { name = 'Duration',        value = ('%d min'):format(Config.TurfWar.duration / 60), inline = true },
        },
    })
    return true
end

---@param reason string?
function Turf.stop(reason)
    if not war then return end

    local turfId = war.turf
    local turf   = Config.Turfs[turfId]

    -- Highest score wins. A tie or an empty board means nobody takes it.
    local winner, winnerScore, tied = nil, 0, false
    for job, score in pairs(war.scores) do
        if score > winnerScore then
            winner, winnerScore, tied = job, score, false
        elseif score == winnerScore and score > 0 then
            tied = true
        end
    end

    if winner and not tied and winnerScore > 0 then
        owners[turfId] = {
            owner      = winner,
            ownerLabel = war.labels[winner] or winner,
            claimedAt  = os.time(),
            vaultAt    = nil,
        }
        Db.setTurfOwner(turfId, winner, owners[turfId].ownerLabel)

        Bridge.announce('success', 'Turf War',
            ('%s now controls %s with %d points.'):format(owners[turfId].ownerLabel, turf.label, winnerScore))
    else
        Db.setTurfOwner(turfId, nil, nil)
        Bridge.announce('inform', 'Turf War',
            tied and ('%s ended in a draw. Nobody takes the territory.'):format(turf.label)
                  or ('%s ended with nobody holding the point.'):format(turf.label))
    end

    Logs.send({
        feature = 'turf', title = 'Turf war ended', severity = 'info',
        fields = {
            { name = 'Territory', value = turf.label, inline = true },
            { name = 'Winner',    value = owners[turfId] and owners[turfId].ownerLabel or 'None', inline = true },
            { name = 'Score',     value = tostring(winnerScore), inline = true },
            { name = 'Reason',    value = reason or 'timer expired', inline = false },
        },
    })

    war = nil
    pushOwners()
    pushWar()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Scoring loop (only alive during a war)
-- ─────────────────────────────────────────────────────────────────────────────

local function tick()
    local turf = Config.Turfs[war.turf]
    local capture = turf.capture
    local captureRadius = Config.TurfWar.captureRadius
    local contestRadius = Config.TurfWar.contestRadius

    local onPoint, nearPoint = {}, {}

    for _, src in ipairs(Bridge.getPlayers()) do
        local ped = GetPlayerPed(src)
        if ped ~= 0 and GetEntityHealth(ped) > 0 then
            local gang, label = gangOf(src)
            if gang then
                local distance = #(GetEntityCoords(ped) - capture)

                if distance <= captureRadius then
                    onPoint[gang] = (onPoint[gang] or 0) + 1
                    war.labels[gang] = label or gang
                end
                if distance <= contestRadius then
                    nearPoint[gang] = true
                end
            end
        end
    end

    -- More than one gang in the contest radius blocks all scoring.
    local gangsNear = 0
    for _ in pairs(nearPoint) do gangsNear = gangsNear + 1 end
    war.contested = gangsNear > 1

    if not war.contested then
        for gang, count in pairs(onPoint) do
            local gained = math.min(count, Config.TurfWar.maxStack) * Config.TurfWar.pointsPerSecond
            war.scores[gang] = (war.scores[gang] or 0) + gained
        end
    end

    -- Work out who is ahead.
    local leader, leaderScore = nil, 0
    for gang, score in pairs(war.scores) do
        if score > leaderScore then leader, leaderScore = gang, score end
    end

    local now = os.time()
    if Config.TurfWar.announceLeadChange and leader and leader ~= war.leader then
        if now - lastLeadAnnounce >= Config.TurfWar.leadChangeCooldown then
            lastLeadAnnounce = now
            Bridge.announce('inform', 'Turf War',
                ('%s has taken the lead on %s.'):format(war.labels[leader] or leader, turf.label))
        end
    end
    war.leader = leader

    -- Periodic reminder of the time left.
    local interval = Config.TurfWar.announceInterval
    if interval > 0 and now - lastIntervalAnnounce >= interval then
        lastIntervalAnnounce = now
        local remaining = math.max(0, war.endsAt - now)
        if remaining > 30 then
            Bridge.announce('inform', 'Turf War',
                ('%s: %d minutes left. Leader: %s.'):format(
                    turf.label, math.ceil(remaining / 60), leader and (war.labels[leader] or leader) or 'nobody'))
        end
    end

    pushWar()
end

CreateThread(function()
    while true do
        if war then
            local ok, err = pcall(tick)
            if not ok then lib.print.error(('turf tick failed: %s'):format(err)) end

            if os.time() >= war.endsAt then
                Turf.stop('timer expired')
            end
            Wait(1000)
        else
            Wait(1000)
        end
    end
end)

--- Schedule watcher. Cheap: one date check a minute.
CreateThread(function()
    Db.await()
    if not Config.TurfWar.enabled then return end

    local lastFired = {}

    while true do
        local now = os.date('*t')
        local stamp = ('%d-%d'):format(now.yday, now.hour)

        if not war then
            for turfId, turf in pairs(Config.Turfs) do
                for _, hour in ipairs(turf.schedule or {}) do
                    if now.hour == hour and lastFired[turfId] ~= stamp then
                        lastFired[turfId] = stamp
                        Turf.start(turfId)
                        break
                    end
                end
                if war then break end
            end
        end

        Wait(60000)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Turf points (vault / stash / garage / wardrobe)
-- ─────────────────────────────────────────────────────────────────────────────

---@param src number
---@param turfId string
---@return boolean owns, string? gang
local function ownsTurf(src, turfId)
    local job = Bridge.getJob(src)
    if not job then return false, nil end

    local owner = owners[turfId]
    if not owner or owner.owner ~= job.name then return false, job.name end

    return true, job.name
end

lib.callback.register('renzu_jobs:turfVault', function(source, turfId)
    local turf = Config.Turfs[turfId]
    if not turf then return false end

    local owns = ownsTurf(source, turfId)
    if not owns then
        Bridge.notify(source, 'error', 'Turf', 'Your gang does not control this territory.')
        return false
    end
    if war and war.turf == turfId then
        Bridge.notify(source, 'error', 'Turf', 'The vault stays sealed while the war is running.')
        return false
    end
    if not Access.nearby(source, turf.points.vault.coord, 5.0) then return false end

    local owner = owners[turfId]
    local cooldown = Config.TurfWar.vaultCooldown or 0
    if owner.vaultAt and (os.time() - owner.vaultAt) < cooldown then
        local minutes = math.ceil((cooldown - (os.time() - owner.vaultAt)) / 60)
        Bridge.notify(source, 'warning', 'Turf', ('The vault has already been emptied. Try again in %d minutes.'):format(minutes))
        return false
    end

    local delivered = {}
    for _, reward in ipairs(turf.reward()) do
        if Bridge.canCarry(source, reward.item, reward.amount) and Bridge.addItem(source, reward.item, reward.amount) then
            delivered[#delivered + 1] = ('%dx %s'):format(reward.amount, Bridge.getItemLabel(reward.item))
        end
    end

    if #delivered == 0 then
        Bridge.notify(source, 'error', 'Turf', 'You cannot carry anything from the vault right now.')
        return false
    end

    owner.vaultAt = os.time()
    Db.markVaultClaimed(turfId)
    pushOwners()

    Bridge.notify(source, 'success', 'Turf Vault', table.concat(delivered, ', '))
    Bridge.announce('inform', 'Turf War',
        ('%s emptied the vault at %s.'):format(owner.ownerLabel or owner.owner, turf.label))

    Logs.send({
        feature = 'turf', title = 'Turf vault claimed', severity = 'success', source = source,
        fields = {
            { name = 'Territory', value = turf.label, inline = true },
            { name = 'Loot',      value = table.concat(delivered, '\n'), inline = false },
        },
    })
    return true
end)

lib.callback.register('renzu_jobs:turfStash', function(source, turfId)
    local turf = Config.Turfs[turfId]
    if not turf or not turf.points.stash then return false end

    if not ownsTurf(source, turfId) then
        Bridge.notify(source, 'error', 'Turf', 'Your gang does not control this territory.')
        return false
    end
    if not Access.nearby(source, turf.points.stash.coord, 5.0) then return false end

    local job = Bridge.getJob(source)
    local id = ('renzuturf_%s'):format(turfId)

    Stash.register(id, ('%s Stash'):format(turf.label),
        turf.points.stash.slots or 100, turf.points.stash.weight or 2000000,
        false, { [job.name] = 0 })

    return { id = id, label = ('%s Stash'):format(turf.label) }
end)

lib.callback.register('renzu_jobs:turfAccess', function(source, turfId)
    return ownsTurf(source, turfId)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Admin commands
-- ─────────────────────────────────────────────────────────────────────────────

lib.addCommand('startturf', {
    help = 'Start a turf war on a territory',
    restricted = 'group.admin',
    params = {
        { name = 'turf', type = 'string', help = 'Territory id from config/turfs.lua' },
    },
}, function(source, args)
    if not Config.Turfs[args.turf] then
        Bridge.notify(source, 'error', 'Turf War', ('Unknown territory "%s".'):format(args.turf))
        return
    end
    if not Turf.start(args.turf) then
        Bridge.notify(source, 'error', 'Turf War', 'A war is already running.')
    end
end)

lib.addCommand('endturf', {
    help = 'Force the running turf war to finish',
    restricted = 'group.admin',
}, function(source)
    if not war then
        Bridge.notify(source, 'error', 'Turf War', 'No war is running.')
        return
    end
    Turf.stop('ended by an admin')
end)

lib.addCommand('setturf', {
    help = 'Give a territory to a gang',
    restricted = 'group.admin',
    params = {
        { name = 'turf', type = 'string', help = 'Territory id' },
        { name = 'gang', type = 'string', help = 'Job/gang name, or "none" to clear' },
    },
}, function(source, args)
    if not Config.Turfs[args.turf] then
        Bridge.notify(source, 'error', 'Turf War', ('Unknown territory "%s".'):format(args.turf))
        return
    end

    if args.gang == 'none' then
        owners[args.turf] = nil
        Db.setTurfOwner(args.turf, nil, nil)
    else
        local jobs = Bridge.getJobs()
        local label = jobs[args.gang] and jobs[args.gang].label or args.gang
        owners[args.turf] = { owner = args.gang, ownerLabel = label, claimedAt = os.time() }
        Db.setTurfOwner(args.turf, args.gang, label)
    end

    pushOwners()
    Bridge.notify(source, 'success', 'Turf War',
        ('%s is now owned by %s.'):format(Config.Turfs[args.turf].label, args.gang))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Boot
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    Db.await()
    owners = Db.getTurfs()
    pushOwners()
    pushWar()
end)

exports('getTurfOwner', function(turfId) return owners[turfId] end)
exports('startTurfWar', function(turfId) return Turf.start(turfId) end)

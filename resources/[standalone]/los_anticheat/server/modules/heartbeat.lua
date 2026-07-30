---Server-side bemonstering van positie, health en armor, plus ontvangst van de
---client-heartbeat.
---
---BELANGRIJK OVER BETROUWBAARHEID
---De positie- en healthwaarden hieronder komen uit de OneSync-state. Die is een
---stuk betrouwbaarder dan iets wat een client ons in een event toestuurt, maar hij
---is niet onvervalsbaar: een cheat kan zijn eigen sync manipuleren. Daarom scoren
---deze checks alleen, ze blokkeren niets. De harde blokkades zitten in damage.lua
---en entities.lua.

---@class ACSample
---@field coords vector3?
---@field health number?
---@field armor number?
---@field lastMove number
---@field grace number
---@field hits number
---@field noDamageSamples number
---@field missedBeats number

---@type table<number, ACSample>
local samples = {}

---@type table<number, number> ped handle -> player source
local pedToSource = {}

---@type table<number, number> source -> timestamp tot wanneer healen verwacht wordt
local expectedHeals = {}

---@type table<number, number> source -> timestamp tot wanneer verplaatsen verwacht wordt
---Bewust een aparte tabel en niet een veld op de sample: een speler kan
---aangemeld worden voordat hij ooit bemonsterd is, en dan mag de grace niet
---verloren gaan.
local graceUntil = {}

-- =========================================================================
--  Exports voor andere resources
-- =========================================================================

---Meldt aan dat een speler zo meteen legitiem geheeld wordt (revive, bandage,
---ziekenhuis). Zonder deze melding scoort de health-check dat als healthRegen.
---
---   exports.los_anticheat:ExpectHeal(source, 10)
---@param source number
---@param seconds number?
function AC_ExpectHeal(source, seconds)
    expectedHeals[source] = os.time() + (seconds or 10)
end

exports('ExpectHeal', AC_ExpectHeal)

---Geeft een speler tijdelijk vrijstelling van de movement-checks. Aanroepen
---vanuit elk script dat een speler verplaatst (garage, housing, jail, admin-tp).
---
---   exports.los_anticheat:ExpectTeleport(source)
---@param source number
---@param seconds number?
function AC_ExpectTeleport(source, seconds)
    graceUntil[source] = os.time() + (seconds or Config.movement.graceSeconds)

    -- Vorige positie weggooien, anders wordt de sprong alsnog gemeten zodra de
    -- grace verloopt maar de speler nog niet opnieuw bemonsterd is.
    local sample = samples[source]
    if sample then sample.coords = nil end
end

exports('ExpectTeleport', AC_ExpectTeleport)

---Registreert dat een speler geraakt is. Wordt aangeroepen vanuit damage.lua.
---@param source number
function AC_RecordHit(source)
    local sample = samples[source]
    if not sample then return end
    sample.hits = sample.hits + 1
end

-- =========================================================================
--  Movement
-- =========================================================================

---@param coords vector3
---@return boolean
local function inIgnoredZone(coords)
    local zones = Config.movement.ignoreZones
    for i = 1, #zones do
        local zone = zones[i]
        if #(coords - vec3(zone.x, zone.y, zone.z)) <= zone.w then
            return true
        end
    end
    return false
end

---@param source number
---@param sample ACSample
---@param ped number
local function checkMovement(source, sample, ped)
    local coords = GetEntityCoords(ped)
    local now = os.time()

    if (graceUntil[source] or 0) > now or inIgnoredZone(coords) then
        sample.coords = coords
        return
    end

    local previous = sample.coords
    sample.coords = coords

    if not previous then return end

    local distance = #(coords - previous)
    if distance <= 0.1 then return end

    local seconds = math.max(1, now - sample.lastMove)
    sample.lastMove = now

    if distance > Config.movement.maxDistancePerTick then
        AC_Flag(source, 'teleport',
            ('%.0f m verplaatst in %d s'):format(distance, seconds),
            { distance = distance, seconds = seconds })
        return
    end

    -- Snelheid te voet. In een voertuig zegt dit niets zinnigs.
    if GetVehiclePedIsIn(ped, false) ~= 0 then return end

    local speed = distance / seconds
    if speed > Config.movement.maxFootSpeed then
        AC_Flag(source, 'speedHack',
            ('%.1f m/s te voet'):format(speed),
            { speed = speed })
    end
end

-- =========================================================================
--  Health en armor
-- =========================================================================

---@param source number
---@param sample ACSample
---@param ped number
local function checkVitals(source, sample, ped)
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local armor = GetPedArmour(ped)

    -- Dood of aan het respawnen: niets te meten.
    if health <= 0 then
        sample.health = nil
        sample.armor = nil
        sample.hits = 0
        sample.noDamageSamples = 0
        return
    end

    -- Waarden buiten het mogelijke bereik zijn ondubbelzinnig.
    if maxHealth > 0 and health > maxHealth then
        AC_Flag(source, 'godmode',
            ('health %d boven maximum %d'):format(health, maxHealth),
            { health = health, maxHealth = maxHealth })
    end

    if armor > 100 then
        AC_Flag(source, 'armorRegen',
            ('armor %d boven 100'):format(armor),
            { armor = armor })
    end

    local healExpected = (expectedHeals[source] or 0) >= os.time()

    if sample.health and not healExpected then
        local gain = health - sample.health
        if gain > Config.health.maxRegenPerTick then
            AC_Flag(source, 'healthRegen',
                ('health +%d in %d ms zonder bron'):format(gain, Config.health.interval),
                { gain = gain })
        end
    end

    if sample.armor and not healExpected then
        local gain = armor - sample.armor
        if gain > Config.health.maxArmorGainPerTick then
            AC_Flag(source, 'armorRegen',
                ('armor +%d zonder vest'):format(gain),
                { gain = gain })
        end
    end

    -- Godmode: wel geraakt, geen health verloren, meerdere metingen achter elkaar.
    if sample.hits > 0 then
        if sample.health and health >= sample.health then
            sample.noDamageSamples = sample.noDamageSamples + 1
            if sample.noDamageSamples >= Config.health.godmodeSamples then
                AC_Flag(source, 'godmode',
                    ('%d treffers zonder healthverlies'):format(sample.hits),
                    { hits = sample.hits, health = health })
                sample.noDamageSamples = 0
            end
        else
            sample.noDamageSamples = 0
        end
        sample.hits = 0
    end

    sample.health = health
    sample.armor = armor
end

-- =========================================================================
--  Client-heartbeat
-- =========================================================================
-- Dit zijn de zwakke signalen. Een executor bepaalt zelf wat hij hier instuurt,
-- dus ze wegen bewust bijna niets. Ze staan er omdat ze gratis meeliften en soms
-- iemand vangen die een kant-en-klaar menu draait zonder te weten wat het doet.

RegisterNetEvent('los_anticheat:heartbeat', function(payload)
    local src = source
    local sample = samples[src]
    if not sample or type(payload) ~= 'table' then return end

    sample.missedBeats = 0

    if type(payload.resources) == 'number' and payload.resources ~= GetNumResources() then
        AC_Flag(src, 'resourceCount',
            ('client meldt %d resources, server heeft er %d'):format(payload.resources, GetNumResources()),
            { client = payload.resources, server = GetNumResources() })
    end

    if payload.kvpTamper then
        AC_Flag(src, 'kvpTamper', 'client meldt gewijzigde kvp-store')
    end

    if payload.threadMismatch then
        AC_Flag(src, 'threadMismatch', 'client meldt afwijkende thread-timing')
    end
end)

-- =========================================================================
--  Lussen
-- =========================================================================

AddEventHandler('playerDropped', function()
    local src = source
    local ped = GetPlayerPed(src)

    samples[src] = nil
    expectedHeals[src] = nil
    graceUntil[src] = nil

    -- Ped-handles worden hergebruikt; een oude entry zou treffers aan de
    -- verkeerde speler toeschrijven.
    if ped and ped ~= 0 then pedToSource[ped] = nil end
end)

CreateThread(function()
    while true do
        Wait(Config.movement.interval)

        local players = GetPlayers()
        for i = 1, #players do
            local src = tonumber(players[i])
            local ped = GetPlayerPed(src)

            if ped and ped ~= 0 then
                pedToSource[ped] = src

                local sample = samples[src]
                if not sample then
                    -- Nieuwe speler: grace op het spawnen, tenzij een script al
                    -- een langere grace heeft aangemeld.
                    graceUntil[src] = math.max(graceUntil[src] or 0, os.time() + Config.movement.graceSeconds)

                    sample = {
                        lastMove = os.time(),
                        hits = 0,
                        noDamageSamples = 0,
                        missedBeats = 0,
                    }
                    samples[src] = sample
                end

                checkMovement(src, sample, ped)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.health.interval)

        local players = GetPlayers()
        for i = 1, #players do
            local src = tonumber(players[i])
            local ped = GetPlayerPed(src)
            local sample = samples[src]

            if ped and ped ~= 0 and sample then
                checkVitals(src, sample, ped)
            end
        end
    end
end)

---Gemiste heartbeats tellen.
CreateThread(function()
    while true do
        Wait(Config.heartbeat.interval)

        for src, sample in pairs(samples) do
            sample.missedBeats = sample.missedBeats + 1
            if sample.missedBeats == Config.heartbeat.missedBeforeFlag then
                AC_Flag(src, 'heartbeatMissing',
                    ('%d heartbeats gemist'):format(sample.missedBeats))
            end
        end
    end
end)

---Ped-naar-speler map, gebruikt door damage.lua om treffers toe te wijzen.
---@param ped number
---@return number?
function AC_SourceFromPed(ped)
    return pedToSource[ped]
end

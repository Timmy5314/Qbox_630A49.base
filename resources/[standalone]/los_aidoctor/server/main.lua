--[[
    Server beslist alles: of er een ambulance komt, wanneer de reanimatie geldt
    en wie de rekening krijgt. De client rijdt alleen.
]]

local config = require 'shared.config'

---@type number? source van de speler die nu geholpen wordt
local activeCall

---@type table<number, boolean> spelers met een lopende oproep
local pending = {}

---@param msg string
local function dbg(msg)
    if config.debug then print(('[los_aidoctor] %s'):format(msg)) end
end

---@return number
local function emsOnDuty()
    local total = 0

    for i = 1, #config.emsJobs do
        local ok, count = pcall(function()
            return exports.qbx_core:GetDutyCountJob(config.emsJobs[i])
        end)

        if ok and type(count) == 'number' then total = total + count end
    end

    return total
end

---@param src number
---@return vector4
local function nearestStation(src)
    local ped = GetPlayerPed(src)
    local coords = ped and ped ~= 0 and GetEntityCoords(ped)

    if not coords then return config.stations[1] end

    local best, bestDist = config.stations[1], nil

    for i = 1, #config.stations do
        local station = config.stations[i]
        local dist = #(coords - vec3(station.x, station.y, station.z))

        if not bestDist or dist < bestDist then
            best, bestDist = station, dist
        end
    end

    return best
end

-- =========================================================================
--  Rekening
-- =========================================================================

---@param src number
---@return boolean
local function hasInsurance(src)
    local ins = config.billing.insurance
    if not ins.enabled then return false end
    if GetResourceState(ins.resource) ~= 'started' then return false end

    local ok, result = pcall(function()
        return exports[ins.resource]:hasMedicalInsurance(src)
    end)

    return ok and result == true
end

---@param src number
local function bill(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local insured = hasInsurance(src)
    local amount = insured and config.billing.insured or config.billing.uninsured

    if insured then
        local ins = config.billing.insurance
        local ok, claimed = pcall(function()
            return exports[ins.resource]:claimMedical(src, amount)
        end)

        if ok and claimed then
            exports.qbx_core:Notify(src, locale('billed_insured', amount), 'inform', 10000)
            return
        end

        -- Verzekeraar weigert of de claim mislukt: de speler betaalt alsnog,
        -- maar het lage tarief. Hij had tenslotte wel een polis.
        dbg(('claim geweigerd voor %s, speler betaalt zelf'):format(src))
    end

    player.Functions.RemoveMoney(config.billing.account, amount, 'AI doctor callout')

    exports.qbx_core:Notify(src,
        insured and locale('billed_insured', amount) or locale('billed_uninsured', amount),
        insured and 'inform' or 'error', 12000)
end

-- =========================================================================
--  Oproep
-- =========================================================================

---@param src number
local function finish(src)
    pending[src] = nil
    if activeCall == src then activeCall = nil end
end

---Wordt door de client gemeld zodra de dokter bij de speler staat.
lib.callback.register('los_aidoctor:completeTreatment', function(_, targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not pending[targetSrc] then return false end

    -- Nog steeds dood? Zo niet, dan is hij intussen door iemand anders geholpen.
    if not Player(targetSrc).state.isDead then
        finish(targetSrc)
        return false
    end

    local ped = GetPlayerPed(targetSrc)
    if not ped or ped == 0 then
        finish(targetSrc)
        return false
    end

    local ok = pcall(function()
        return exports.ND_Ambulance:revivePlayer(targetSrc)
    end)

    if not ok then
        dbg('ND_Ambulance:revivePlayer faalde')
        finish(targetSrc)
        return false
    end

    bill(targetSrc)
    finish(targetSrc)

    return true
end)

RegisterNetEvent('los_aidoctor:callFailed', function(targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not pending[targetSrc] then return end

    exports.qbx_core:Notify(targetSrc, locale('no_response'), 'error', 10000)
    finish(targetSrc)
end)

--[[
    Haakje in ND_Ambulance.

    sendSignal is een RegisterNetEvent daar; een AddEventHandler hier op dezelfde
    naam vuurt mee zonder dat ND_Ambulance aangepast hoeft te worden. Het gaat
    dus mee met de bestaande "druk op G"-flow en het ps-dispatch bericht dat daar
    al uitgaat.
]]
AddEventHandler('ND_Ambulance:sendSignal', function(location, coords)
    local src = source

    if type(coords) ~= 'vector3' then return end
    if not Player(src).state.isDead then return end
    if pending[src] then return end

    if config.oneAtATime and activeCall then
        dbg('er rijdt al een ambulance, oproep genegeerd')
        return
    end

    local onDuty = emsOnDuty()
    if onDuty > 0 then
        dbg(('%d EMS on duty, AI blijft thuis'):format(onDuty))
        return
    end

    pending[src] = true
    activeCall = src

    exports.qbx_core:Notify(src, locale('dispatched'), 'inform', 10000)

    SetTimeout(config.responseDelay * 1000, function()
        if not pending[src] then return end

        -- In de tussentijd geholpen of gerespawned.
        if not Player(src).state.isDead then return finish(src) end

        -- Ook nu nog niemand on duty? Anders alsnog afblazen.
        if emsOnDuty() > 0 then
            dbg('EMS kwam alsnog on duty, oproep afgeblazen')
            return finish(src)
        end

        local station = nearestStation(src)

        TriggerClientEvent('los_aidoctor:startRide', src, {
            target = src,
            station = station,
            timeout = config.rideTimeout,
        })
    end)
end)

AddEventHandler('playerDropped', function()
    finish(source)
end)

---Als de speler onderweg alsnog door iemand anders wordt gereanimeerd.
AddEventHandler('ND_Ambulance:playerRevived', function(src)
    if pending[src] then
        TriggerClientEvent('los_aidoctor:cancelRide', src)
        finish(src)
    end
end)

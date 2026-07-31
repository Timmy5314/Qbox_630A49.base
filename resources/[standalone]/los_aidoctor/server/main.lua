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

--[[
    Eigen-risicomodel.

    De rit kost altijd `uninsured`; dat is de werkelijke prijs. Ben je
    verzekerd, dan betaalt de verzekeraar het verschil en houd jij alleen
    `insured` over als eigen bijdrage. Staat die op 0, dan is de rit gratis.

    Weigert de verzekeraar of bestaat de resource nog niet, dan valt het terug
    op de speler - maar wel tegen zijn eigen bijdrage, niet het volle tarief.
    Hij had immers een polis.
]]
---@param src number
local function bill(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local cost = config.billing.uninsured
    local insured = hasInsurance(src)
    local owed = insured and config.billing.insured or cost

    if insured then
        local covered = cost - config.billing.insured

        if covered > 0 then
            local ins = config.billing.insurance
            local ok, claimed = pcall(function()
                return exports[ins.resource]:claimMedical(src, covered)
            end)

            if not ok or not claimed then
                dbg(('claim geweigerd voor %s'):format(src))
            end
        end
    end

    if owed <= 0 then
        return exports.qbx_core:Notify(src, locale('billed_covered'), 'success', 10000)
    end

    player.Functions.RemoveMoney(config.billing.account, owed, 'AI doctor callout')

    exports.qbx_core:Notify(src,
        insured and locale('billed_insured', owed) or locale('billed_uninsured', owed),
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
---
---De rit draait op de client van de patiënt zelf, dus de bron ís het doelwit.
---Het meegestuurde id werd hier eerst gebruikt; daarmee kon iedereen de
---behandeling van een ander afronden en die de rekening bezorgen.
lib.callback.register('los_aidoctor:completeTreatment', function(source)
    local targetSrc = source
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

RegisterNetEvent('los_aidoctor:callFailed', function()
    -- Zelfde reden als hierboven: bron, niet het meegestuurde id.
    local targetSrc = source
    if not pending[targetSrc] then return end

    exports.qbx_core:Notify(targetSrc, locale('no_response'), 'error', 10000)
    finish(targetSrc)
end)

--[[
    Haakje in ND_Ambulance.

    Dit hing eerst aan `ND_Ambulance:sendSignal` - een net event dat in
    ND_Ambulance is geregistreerd. Of een AddEventHandler in een ANDERE resource
    dan meevuurt hangt af van hoe FiveM binnenkomende net events routeert, en
    daar wilde ik niet op gokken voor de enige trigger van deze resource.

    ND_Ambulance vuurt nu na zijn eigen controles een gewone server-interne
    `ND_Ambulance:signalSent` af. Dat is een TriggerEvent en die bereikt
    aantoonbaar alle resources. Het gaat nog steeds mee met de bestaande
    "druk op G"-flow.
]]
AddEventHandler('ND_Ambulance:signalSent', function(src, location, coords)
    src = tonumber(src)
    if not src then return end

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

--[[
    Server beslist of er een taxi komt en wie de rekening krijgt.
    De client rijdt alleen.
]]

local config = require 'shared.config'

---@type table<number, boolean> spelers met een lopende rit
local active = {}

---@param msg string
local function dbg(msg)
    if config.debug then lib.print.info(msg) end
end

---@return number
local function driversOnDuty()
    local ok, count = pcall(function()
        return exports.qbx_core:GetDutyCountJob(config.taxiJob)
    end)

    return (ok and type(count) == 'number') and count or 0
end

---@param src number
---@param message string
local function sms(src, message)
    if not GetResourceState('npwd'):find('start') then return end

    -- getPlayerData wil een LOCATOR-object, geen source-getal, en geeft een
    -- platte tabel terug met phoneNumber. Zie npwd/dist/game/server/server.js.
    -- Dit is dezelfde val waar los_insurance in trapte.
    local ok, data = pcall(function()
        return exports.npwd:getPlayerData({ source = src })
    end)

    if not ok or type(data) ~= 'table' then return end

    if data.phoneNumber == nil and type(data.next) == 'function' then
        local awaited
        local awaitOk = pcall(function() awaited = Citizen.Await(data) end)
        data = awaitOk and awaited or nil
    end

    local number = type(data) == 'table' and data.phoneNumber
    if not number then return end

    pcall(function()
        exports.npwd:emitMessage({
            senderNumber = config.phoneNumber,
            targetNumber = number,
            message = message,
        })
    end)
end

---@param src number
local function finish(src)
    active[src] = nil
end

-- =========================================================================
--  De rit
-- =========================================================================

---@param src number
local function dispatch(src)
    if active[src] then
        return sms(src, locale('already_on_the_way'))
    end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    if driversOnDuty() > 0 then
        dbg(('%d taxichauffeur(s) on duty, geen AI'):format(driversOnDuty()))
        return sms(src, locale('drivers_available'))
    end

    active[src] = true
    sms(src, locale('on_the_way'))

    SetTimeout(config.responseDelay * 1000, function()
        if not active[src] then return end

        if GetPlayerPed(src) == 0 then return finish(src) end

        -- Alsnog iemand on duty? Dan gaat de rit niet door.
        if driversOnDuty() > 0 then
            sms(src, locale('drivers_available'))
            return finish(src)
        end

        TriggerClientEvent('los_aitaxi:startRide', src, {
            depots = config.depots,
        })
    end)
end

-- =========================================================================
--  NPWD
-- =========================================================================

CreateThread(function()
    while GetResourceState('npwd') ~= 'started' do Wait(1000) end
    Wait(2000)

    --[[
        NPWD exporteert `onCall(nummer, cb)` vanuit zijn JS-bundle
        (server/calls/middleware/index.ts). De callback krijgt een tabel met:

            receiverNumber   het gebelde nummer
            incomingCaller   { number = ... } van de beller
            next()           laat het gesprek doorgaan
            exit()           hangt op
            reply(msg)       stuurt een SMS terug namens dit nummer
            forward(nr, anoniem)

        We hangen altijd op: er zit geen speler achter dit nummer, dus doorgaan
        zou alleen een gesprek opleveren dat niemand opneemt. De bevestiging
        komt per SMS, en dat is meteen het bewijs dat je oproep is aangekomen.
    ]]
    local ok, err = pcall(function()
        exports.npwd:onCall(config.phoneNumber, function(data)
            local caller = data and data.incomingCaller
            local number = caller and caller.number

            if data and data.exit then data.exit() end
            if not number then return end

            -- Van nummer naar source, want alleen daarmee kunnen we een ped en
            -- een portemonnee vinden.
            local lookupOk, player = pcall(function()
                return exports.npwd:getPlayerData({ phoneNumber = number })
            end)

            if not lookupOk or type(player) ~= 'table' then return end

            if player.source == nil and type(player.next) == 'function' then
                local awaited
                local awaitOk = pcall(function() awaited = Citizen.Await(player) end)
                player = awaitOk and awaited or nil
            end

            local src = type(player) == 'table' and tonumber(player.source)
            if not src then return end

            dispatch(src)
        end)
    end)

    if not ok then
        lib.print.error(('npwd:onCall faalde, de taxicentrale is niet bereikbaar: %s'):format(err))
    end
end)

-- =========================================================================
--  Afrekenen
-- =========================================================================

---De client meldt dat de rit klaar is en hoe ver er gereden is. De afstand
---wordt hier begrensd, dus een aangepaste client kan zichzelf hooguit een
---goedkopere rit geven - nooit een duurdere of een negatieve.
lib.callback.register('los_aitaxi:completeRide', function(src, distanceMeters)
    if not active[src] then return false end

    distanceMeters = tonumber(distanceMeters) or 0
    if distanceMeters < 0 then distanceMeters = 0 end

    local fare = config.fare.base + math.floor((distanceMeters / 1000) * config.fare.perKm)
    if fare > config.fare.max then fare = config.fare.max end

    local player = exports.qbx_core:GetPlayer(src)

    if player then
        if player.Functions.RemoveMoney(config.fare.account, fare, 'Taxi fare') then
            sms(src, locale('receipt', fare))
        else
            sms(src, locale('unpaid'))
        end
    end

    finish(src)
    return fare
end)

RegisterNetEvent('los_aitaxi:rideFailed', function()
    local src = source
    if not active[src] then return end

    sms(src, locale('no_response'))
    finish(src)
end)

AddEventHandler('playerDropped', function()
    finish(source)
end)

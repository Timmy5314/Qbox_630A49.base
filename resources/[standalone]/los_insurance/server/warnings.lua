--[[
    Waarschuwingen van de overheid aan onverzekerde burgers.

    Via NPWD. De exports zijn niet gedocumenteerd bij deze build; ze zijn uit de
    gecompileerde bundle gehaald:
        emitMessage({ senderNumber, targetNumber, message })
        getPlayerData(locator) -> speler, met getPhoneNumber()

    Bewust terughoudend: hooguit een bericht per `cooldownHours` per speler, en
    alleen als hij al even online is. Een verzekering die je aanpraat met spam
    werkt averechts.
]]

lib.locale()

local config = require 'shared.config'
if not config.warnings.enabled then return end

---@type table<string, number> citizenid -> timestamp van het laatste bericht
local lastWarned = {}

---@type table<number, number> source -> timestamp waarop hij online kwam
local onlineSince = {}

---@param src number
---@return string?
local function phoneNumberOf(src)
    local ok, player = pcall(function()
        return exports.npwd:getPlayerData(src)
    end)

    if not ok or not player then return end

    -- getPlayerData geeft een object met getPhoneNumber(); afhankelijk van de
    -- bundle kan het ook een tabel met phoneNumber zijn.
    if type(player) == 'table' then
        if type(player.getPhoneNumber) == 'function' then
            return player:getPhoneNumber()
        end
        return player.phoneNumber
    end
end

---@param src number
---@param key string
local function sendWarning(src, key)
    local number = phoneNumberOf(src)
    if not number then return false end

    local ok = pcall(function()
        exports.npwd:emitMessage({
            senderNumber = config.warnings.senderNumber,
            targetNumber = number,
            message = locale(key),
        })
    end)

    return ok
end

AddEventHandler('playerDropped', function()
    onlineSince[source] = nil
end)

-- Hier stond `RegisterNetEvent('QBCore:Server:OnPlayerLoaded')`. Dat werkte:
-- qbx_core vuurt dat event af vanaf de CLIENT (client/character.lua regel 280
-- en 407), dus `source` was de speler.
--
-- Toch omgezet naar `QBCore:Server:PlayerLoaded`, dat qbx_core server-side
-- afvuurt in server/player.lua regel 1064. Reden: een client-getriggerd event
-- kan een speler zelf blijven afvuren en daarmee zijn eigen online-teller
-- resetten, zodat de waarschuwing nooit komt. Dit event komt van de server en
-- is dus niet te sturen. Het geeft het spelerobject mee, geen source.
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if not src then return end

    onlineSince[src] = os.time()
end)

CreateThread(function()
    -- npwd tijd geven om te laden; zonder dat bestaat de export nog niet.
    while GetResourceState('npwd') ~= 'started' do Wait(1000) end
    Wait(5000)

    while true do
        Wait(config.warnings.intervalMinutes * 60000)

        local now = os.time()
        local players = GetPlayers()

        for i = 1, #players do
            local src = tonumber(players[i])
            local player = exports.qbx_core:GetPlayer(src)

            if player then
                local citizenid = player.PlayerData.citizenid
                local since = onlineSince[src]

                local longEnough = since and (now - since) >= config.warnings.minMinutesOnline * 60
                local notRecently = (now - (lastWarned[citizenid] or 0)) >= config.warnings.cooldownHours * 3600

                if longEnough and notRecently then
                    local medical = MySQL.single.await([[
                        SELECT 1 FROM los_insurance_policies
                        WHERE citizenid = ? AND type = 'medical' AND expires > ? LIMIT 1
                    ]], { citizenid, now })

                    -- Heeft hij voertuigen zonder polis?
                    local uninsuredVehicles = MySQL.scalar.await([[
                        SELECT COUNT(*) FROM player_vehicles v
                        WHERE v.citizenid = ?
                          AND NOT EXISTS (
                              SELECT 1 FROM los_insurance_policies p
                              WHERE p.type = 'vehicle'
                                AND p.plate = TRIM(UPPER(v.plate))
                                AND p.expires > ?
                          )
                    ]], { citizenid, now }) or 0

                    local key
                    if not medical and uninsuredVehicles > 0 then
                        key = 'warn_both'
                    elseif not medical then
                        key = 'warn_medical'
                    elseif uninsuredVehicles > 0 then
                        key = 'warn_vehicle'
                    end

                    if key and sendWarning(src, key) then
                        lastWarned[citizenid] = now
                    end
                end
            end
        end
    end
end)

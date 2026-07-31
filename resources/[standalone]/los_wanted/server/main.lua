local config = require 'shared.config'

local currentTier
local lastAlert = {}

---@param count number officers on duty
---@return string tier
local function resolveTier(count)
    if count == 0 then return 'full' end
    if count <= config.fewOfficersUpTo then return 'passive' end
    return 'off'
end

--- De stand staat in GlobalState en niet in een event. Elke client leest hem
--- bij het inladen zelf uit, dus iemand die net joint zit meteen goed - met een
--- broadcast-event had die de laatste wissel gemist.
local function refresh(force)
    local count = exports.qbx_core:GetDutyCountType(config.policeJobType) or 0
    local tier = resolveTier(count)

    GlobalState.losWantedOfficers = count

    if tier == currentTier and not force then return end

    currentTier = tier
    GlobalState.losWantedTier = tier

    if config.debug then
        lib.print.info(('stand -> %s (%d agent(en) on duty)'):format(tier, count))
    end
end

CreateThread(function()
    -- qbx_core moet zijn spelers geladen hebben voordat de eerste telling klopt.
    Wait(5000)
    refresh(true)

    while true do
        Wait(config.checkInterval * 1000)
        refresh()
    end
end)

exports('GetTier', function()
    return currentTier or 'off'
end)

exports('GetOfficerCount', function()
    return GlobalState.losWantedOfficers or 0
end)

--- De client meldt dat hij gezocht is geraakt. Hij bepaalt WAT, de server
--- bepaalt OF: cooldown, geldige waarde, en de coordinaten komen niet uit het
--- event maar van de speler zelf.
RegisterNetEvent('los_wanted:report', function(level)
    local src = source

    if not config.dispatch.enabled then return end
    if not GetResourceState('ps-dispatch'):find('start') then return end

    level = tonumber(level)
    if not level or level < config.dispatch.minLevel or level > 5 then return end

    local now = os.time()
    local last = lastAlert[src]
    if last and now - last < config.dispatch.cooldown then return end
    lastAlert[src] = now

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    -- ps-dispatch bouwt de melding client-side op; CustomAlert bestaat daar ook
    -- alleen. Server-side aanroepen gooit "No such export CustomAlert" - dat is
    -- precies wat ND_Police en ND_Ambulance deden.
    TriggerClientEvent('los_wanted:sendAlert', src, level)
end)

AddEventHandler('playerDropped', function()
    lastAlert[source] = nil
    refresh()
end)

--- Direct hertellen scheelt tot `checkInterval` seconden vertraging na een
--- dienstwissel. Het event heet `QBCore:Server:SetDuty` - qbx_core vuurt dat af
--- in server/player.lua, SetJobDuty(). Er bestaat geen qbx_core:server:onSetDuty.
AddEventHandler('QBCore:Server:SetDuty', function()
    refresh()
end)

lib.addCommand('wantedtier', {
    help = 'Toon de huidige AI-politiestand',
    restricted = 'group.admin',
}, function(source)
    local count = GlobalState.losWantedOfficers or 0

    exports.qbx_core:Notify(source, ('AI-politie: %s (%d agent(en) on duty)')
        :format(currentTier or 'onbekend', count), 'inform')
end)

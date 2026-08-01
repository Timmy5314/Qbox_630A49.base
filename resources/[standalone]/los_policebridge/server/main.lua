--[[
    los_policebridge - compatibiliteitsbrug voor de qbx-overvallen.

    PROBLEEM (gevonden aug 2026)
      qbx_bankrobbery, qbx_houserobbery, qbx_jewelery, qbx_storerobbery en
      qbx_vehiclekeys vuren nog het legacy qb-policejob event
      `police:server:policeAlert` af. Op deze server (ND_Police + ps-dispatch)
      ving NIEMAND dat af -> de politie kreeg GEEN enkele melding van een overval.

      Daarnaast luistert qbx_bankrobbery naar `police:SetCopCount` om te weten of
      er genoeg agenten zijn. Niemand vuurde dat af -> zijn teller bleef op 0
      (nu onschadelijk omdat minFleecaPolice=0, maar latent kapot zodra je een
      minimum instelt).

    OPLOSSING
      - police:server:policeAlert -> ps-dispatch CustomAlert, via de client van de
        dader. CustomAlert bestaat ALLEEN client-side (zie CLAUDE.md-valkuil en
        ND_Police/los_wanted die hetzelfde patroon gebruiken).
      - police:SetCopCount periodiek broadcasten met de leo-dienstteller.
]]

local lastAlert = {}

--- Platte melding aan alle agenten op dienst (geen kaartblip). Fallback voor het
--- geval er geen geldige bron-speler is: de huisoverval vuurt het event uitgesteld
--- af via SetTimeout, waardoor `source` verloren is.
---@param text string
local function notifyLeo(text)
    local players = exports.qbx_core:GetQBPlayers()
    for _, player in pairs(players) do
        local job = player.PlayerData.job
        if job and job.type == 'leo' and job.onduty then
            exports.qbx_core:Notify(player.PlayerData.source, text, 'inform', 8000)
        end
    end
end

RegisterNetEvent('police:server:policeAlert', function(message, _, explicitSource)
    -- jewelery geeft de bron expliciet mee als 3e argument; de rest laat het aan
    -- `source` over (geldig bij TriggerServerEvent vanaf de client).
    local src = tonumber(explicitSource) or source

    -- Client-geleverde tekst: begrenzen zodat een gemanipuleerde client de
    -- meldkamer niet kan volgooien met een enorme string.
    local text = type(message) == 'string' and message:sub(1, 120) or 'Robbery in progress'

    if not src or src == 0 or GetPlayerName(src) == nil then
        -- Geen geldige bron -> geen coords -> platte melding zonder blip.
        notifyLeo(text)
        return
    end

    -- Rate-limit per bron: een overval mag de meldkamer niet volspammen.
    local now = os.time()
    if lastAlert[src] and now - lastAlert[src] < 5 then return end
    lastAlert[src] = now

    TriggerClientEvent('los_policebridge:alert', src, text)
end)

AddEventHandler('playerDropped', function()
    lastAlert[source] = nil
end)

--- Voedt qbx_bankrobbery's CurrentCops (police:SetCopCount). GetDutyCountType
--- telt agenten op dienst van jobtype 'leo' (police/bcso/sasp).
CreateThread(function()
    while true do
        local count = exports.qbx_core:GetDutyCountType('leo') or 0
        TriggerClientEvent('police:SetCopCount', -1, count)
        Wait(15000)
    end
end)

---Client-heartbeat.
---
---Bewust minimaal. Alles wat hier gemeten wordt is per definitie te vervalsen:
---een executor draait in dezelfde Lua-omgeving als dit bestand en kan de
---uitkomst van elke meting veranderen of het event helemaal onderdrukken.
---
---Daarom weegt dit in Config.weights bijna niets. Het bestaat om twee redenen:
---  1. Het vangt de amateur die een kant-en-klaar menu draait zonder te weten
---     wat het aanraakt.
---  2. Het uitblijven van heartbeats is zelf een signaal.
---
---Er staat opzettelijk GEEN hash-controle van clientbestanden in. Wie het bestand
---kan wijzigen, kan ook de hash liegen. Dat geeft schijnzekerheid, geen veiligheid.

local resourceCount = GetNumResources()

---Detecteert of de scheduler structureel afwijkt van de gevraagde wachttijd.
---Lage FPS en streaming geven dit ook, dus het is een zwak signaal.
---@return boolean
local function checkThreadTiming()
    local expected = 1000
    local start = GetGameTimer()
    Wait(expected)
    local drift = GetGameTimer() - start - expected

    -- Ruim: pas boven twee seconden afwijking is er iets structureel mis.
    return drift > 2000 or drift < -100
end

CreateThread(function()
    -- Even wachten tot de speler echt geladen is; anders meten we het laadscherm.
    Wait(30000)

    while true do
        local threadMismatch = checkThreadTiming()

        TriggerServerEvent('los_anticheat:heartbeat', {
            resources = resourceCount,
            threadMismatch = threadMismatch,
            kvpTamper = GetResourceKvpString('los_anticheat:marker') ~= nil,
        })

        Wait(Config.heartbeat.interval)
    end
end)

---Marker die alleen bestaat om aan te tonen dat de kvp-store van deze resource
---niet van buitenaf beschreven wordt. Wordt nooit door ons gezet.
DeleteResourceKvp('los_anticheat:marker')

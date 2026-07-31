if not Config.Drugs['cornerselling'] then return end
if not Config.Junkies or not Config.Junkies.enabled then return end

--[[
    Junkie-gedrag en het looten van een neergehaalde junkie.

    OPTIMALISATIE
    Er wordt niets gespawnd en er draait geen permanente zware loop. Eens per
    `scanInterval` wordt een klein aantal wereld-peds in de buurt bekeken; wie
    in aanmerking komt krijgt eenmalig een scenario en een vlag, daarna wordt hij
    met rust gelaten. Zonder spelers in de buurt slaapt de thread.

    JUNKIES VALLEN NIEMAND AAN
    Er wordt bewust geen agressie of relationship group gezet. Ze zien er
    onrustig uit en meer niet. Een NPC die willekeurig aanvalt verpest de RP en
    dat was expliciet niet de bedoeling.
]]

local cfg = Config.Junkies

---Peds die we al hebben behandeld. Entity handles worden hergebruikt, dus deze
---tabel wordt periodiek opgeschoond.
---@type table<number, boolean>
local marked = {}

---@type table<number, boolean>
local lootedLocally = {}

---@param ped number
---@return boolean
local function canBeJunkie(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if ped == cache.ped or IsPedAPlayer(ped) then return false end
    if not IsPedHuman(ped) then return false end
    if GetEntityHealth(ped) <= 0 then return false end
    if IsPedInAnyVehicle(ped, false) then return false end

    -- Alleen ambient bevolking. 1 t/m 5 zijn de random populatietypes; al het
    -- andere is door een script neergezet en daar blijven we vanaf.
    local popType = GetEntityPopulationType(ped)
    if popType < 1 or popType > 5 then return false end

    -- Politie, medics en leger met rust laten.
    local pedType = GetPedType(ped)
    if pedType == 6 or pedType == 20 or pedType == 21 or pedType == 27 or pedType == 29 then
        return false
    end

    return true
end

---@param ped number
local function makeJunkie(ped)
    marked[ped] = true

    if math.random(100) > cfg.chance then return end

    -- Alleen een scenario. Geen agressie, geen combat attributes.
    local scenario = cfg.scenarios[math.random(#cfg.scenarios)]
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, scenario, 0, true)

    -- Zichtbaar onrustig, maar niet gevaarlijk.
    SetPedMovementClipset(ped, cfg.clipset, 1.0)
    SetPedConfigFlag(ped, 166, true) -- CPED_CONFIG_FLAG_DisableTakeOffScubaGear, onschadelijk
end

CreateThread(function()
    while true do
        local slept = cfg.scanInterval

        local coords = GetEntityCoords(cache.ped)
        local pool = GetGamePool('CPed')
        local checked = 0

        for i = 1, #pool do
            local ped = pool[i]

            if not marked[ped] and #(coords - GetEntityCoords(ped)) < cfg.scanRadius then
                if canBeJunkie(ped) then
                    makeJunkie(ped)
                    checked = checked + 1

                    -- Nooit alles in een tick: dat geeft een hik bij het
                    -- inladen van een drukke straat.
                    if checked >= cfg.maxPerScan then break end
                else
                    marked[ped] = true
                end
            end
        end

        Wait(slept)
    end
end)

---Looten van een junkie die is neergehaald.
CreateThread(function()
    while true do
        Wait(cfg.lootScanInterval)

        local coords = GetEntityCoords(cache.ped)
        local pool = GetGamePool('CPed')

        for i = 1, #pool do
            local ped = pool[i]

            if not lootedLocally[ped]
                and GetEntityHealth(ped) <= 0
                and marked[ped]
                and #(coords - GetEntityCoords(ped)) < cfg.lootDistance
            then
                lootedLocally[ped] = true

                -- De server beslist of er iets valt en wat. Hier alleen vragen.
                local netId = NetworkGetNetworkIdFromEntity(ped)
                if netId and netId ~= 0 then
                    TriggerServerEvent('md-drugs:server:lootJunkie', netId)
                end
            end
        end
    end
end)

---Entity handles worden hergebruikt. Zonder opruimen groeit deze tabel en
---worden nieuwe peds ten onrechte als 'al behandeld' gezien.
CreateThread(function()
    while true do
        Wait(120000)

        for ped in pairs(marked) do
            if not DoesEntityExist(ped) then
                marked[ped] = nil
                lootedLocally[ped] = nil
            end
        end
    end
end)

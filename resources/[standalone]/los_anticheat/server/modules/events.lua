---Event-monitoring en rate limiting.
---
---WAT DIT WEL EN NIET KAN — lees dit voordat je verwachtingen aanpast.
---
---Een losse resource kan in FiveM GEEN net events van andere resources
---blokkeren. CancelEvent() zet bij een net event alleen een vlag; handlers die
---daarna geregistreerd zijn draaien gewoon door, tenzij ze zelf
---WasEventCanceled() controleren. Vrijwel geen enkele resource doet dat.
---
---Wat wel kan, en wat deze module doet:
---  1. Een extra handler hangen aan elk bekend server-side net event. Die vuurt
---     mee zodra een client het event triggert, dus we zien alles.
---  2. Per speler per event tellen hoe vaak het binnen een tijdvenster gebeurt,
---     en spam scoren.
---  3. Rapporteren welke events bestaan, zodat je weet waar je guards moet zetten.
---
---Echt dichttimmeren gebeurt in de resource die het event registreert, met een
---server-side check op de argumenten. Zie qbx_vehiclekeys voor het patroon:
---daar bleek AcquireVehicleKeys elk voertuig op de map terug te geven.
---
---"Onbekende events blokkeren" is overigens al standaardgedrag van FiveM: een
---client kan alleen events triggeren die met RegisterNetEvent zijn aangemeld.
---Er bestaat geen categorie "niet-geregistreerde events" om te blokkeren.

---@type table<number, table<string, {count: number, window: number}>>
local counters = {}

---@param source number
---@param event string
local function track(source, event)
    if not source or source <= 0 then return end
    if Config.events.ignore[event] then return end

    local perPlayer = counters[source]
    if not perPlayer then
        perPlayer = {}
        counters[source] = perPlayer
    end

    local now = GetGameTimer()
    local entry = perPlayer[event]

    if not entry or now - entry.window > Config.events.windowMs then
        perPlayer[event] = { count = 1, window = now }
        return
    end

    entry.count = entry.count + 1

    local limit = Config.events.limits[event] or Config.events.defaultLimit
    if entry.count == limit + 1 then
        AC_Flag(source, 'eventSpam',
            ('%s %d keer in %d ms'):format(event, entry.count, Config.events.windowMs),
            { event = event, count = entry.count })
    end
end

---Hangt observers aan alle bekende server-side net events.
local function attachObservers()
    if type(KnownServerEvents) ~= 'table' then
        print('[los_anticheat] data/events.generated.lua ontbreekt of is leeg. Event-monitoring staat uit.')
        return
    end

    local attached = 0
    for eventName in pairs(KnownServerEvents) do
        if not Config.events.ignore[eventName] then
            AddEventHandler(eventName, function()
                track(source, eventName)
            end)
            attached = attached + 1
        end
    end

    print(('[los_anticheat] %d server-side net events onder monitoring.'):format(attached))
end

AddEventHandler('playerDropped', function()
    counters[source] = nil
end)

---Rapport van de aanvalsoppervlakte, gegroepeerd per resource.
---Draai dit als je wilt weten waar guards ontbreken.
RegisterCommand('ac_events', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, Config.adminAce) then return end

    local perResource = {}
    for eventName, resource in pairs(KnownServerEvents or {}) do
        perResource[resource] = perResource[resource] or {}
        table.insert(perResource[resource], eventName)
    end

    local names = {}
    for resource in pairs(perResource) do names[#names + 1] = resource end
    table.sort(names)

    print('--- los_anticheat: server-side net events per resource ---')
    for i = 1, #names do
        print(('%-28s %d'):format(names[i], #perResource[names[i]]))
    end
end, false)

CreateThread(attachObservers)

---Entity-autoriteit: welke voertuigen mogen bestaan.
---
---entityCreating wordt server-side afgehandeld en is cancelbaar, dus dit is naast
---weaponDamageEvent de tweede plek waar we een client echt kunnen stoppen.
---
---De handler draait voor ELKE entity die aangemaakt wordt. Hij moet daarom
---goedkoop blijven: geen MySQL, geen exports, geen loops over spelers.

---Modellen die nooit mogen bestaan, als hashset voor O(1) lookup.
---@type table<number, boolean>
local blacklisted = {}
for i = 1, #Config.entities.blacklistedModels do
    blacklisted[joaat(Config.entities.blacklistedModels[i])] = true
end

---Registraties van server-side scripts: "ik ga zo een voertuig spawnen".
---@type table<number, number> model hash -> expiry timestamp
local expectedSpawns = {}

---Meldt aan dat een script binnenkort een voertuig spawnt, zodat de
---entityCreating-handler het niet blokkeert.
---
---Gebruik vanuit een server-side script:
---   exports.los_anticheat:RegisterSpawn(`adder`)
---@param model number|string
function AC_RegisterSpawn(model)
    local hash = type(model) == 'string' and joaat(model) or model
    expectedSpawns[hash] = os.time() + Config.entities.registrationTtl
end

exports('RegisterSpawn', AC_RegisterSpawn)

AddEventHandler('entityCreating', function(entity)
    if GetEntityType(entity) ~= 2 then return end -- alleen voertuigen

    local model = GetEntityModel(entity)

    if blacklisted[model] then
        CancelEvent()

        local owner = NetworkGetEntityOwner(entity)
        if owner and owner > 0 then
            AC_Flag(owner, 'illegalEntitySpawn',
                ('geblokkeerd model %s'):format(model),
                { model = model })
        end
        return
    end

    if not Config.entities.blockUnregisteredVehicles then return end

    local expiry = expectedSpawns[model]
    if expiry and expiry >= os.time() then
        expectedSpawns[model] = nil
        return
    end

    CancelEvent()

    local owner = NetworkGetEntityOwner(entity)
    if owner and owner > 0 then
        AC_Flag(owner, 'illegalEntitySpawn',
            ('niet-geregistreerde spawn van model %s'):format(model),
            { model = model })
    end
end)

---Opruimen van verlopen registraties. Eens per minuut is ruim voldoende.
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for hash, expiry in pairs(expectedSpawns) do
            if expiry < now then
                expectedSpawns[hash] = nil
            end
        end
    end
end)

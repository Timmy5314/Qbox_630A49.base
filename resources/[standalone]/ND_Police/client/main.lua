Config = lib.load("data.config")

-- Deze lus is de enige bron van `ND_Police:playerJustShot`, en dus van GSR,
-- sporenonderzoek en de shotspotter.
--
-- De oude versie zette bij een tweede event `activeLoop = false` en stopte
-- meteen. Wissel je van wapen zonder eerst op te bergen - het normale geval -
-- dan vuurde het event opnieuw terwijl de lus al liep, waarna hij zichzelf
-- afsloot en er GEEN nieuwe startte. Elk tweede wapen dat je pakte werd dus niet
-- gedetecteerd: geen kruitsporen, geen hulzen, geen melding.
local currentWeapon
local loopRunning = false

AddEventHandler("ox_inventory:currentWeapon", function(weaponData)
    currentWeapon = weaponData?.ammo and weaponData or nil

    if not currentWeapon or loopRunning then return end

    loopRunning = true

    CreateThread(function()
        while currentWeapon do
            Wait(0)

            if IsPedShooting(cache.ped) then
                TriggerEvent("ND_Police:playerJustShot", currentWeapon)
            end
        end

        loopRunning = false
    end)
end)

AddEventHandler("ND_Police:playerUnloaded", function()
    LocalPlayer.state:set('isCuffed', false, true)
    LocalPlayer.state:set('isEscorted', false, true)
end)

exports.ox_target:addGlobalVehicle({
    {
        icon = "fa-solid fa-car-side",
        label = locale("impound_vehicle"),
        groups = Config.policeGroups,
	    distance = 1.5,
        onSelect = function(data)
            local input = lib.inputDialog(locale("impound_vehicle"), {
                {
                    type = "number",
                    label = locale("impound_reclaim_price"),
                    description = locale("impound_reclaim_price_description"),
                    icon = "money-check",
                    min = Config.minImpoundPrice,
                    max = Config.maxImpoundPrice,
                    default = Config.defaultImpoundPrice
                },
                {
                    -- Komt in de impound-administratie van renzu_garage terecht,
                    -- zodat de eigenaar bij het ophalen ziet waarom.
                    type = "input",
                    label = locale("impound_reason"),
                    description = locale("impound_reason_description"),
                    icon = "file-lines",
                    max = 120
                }
            })

            local impoundReclaimPrice = input and input[1]
            if not impoundReclaimPrice then return end

            local alert = lib.alertDialog({
                header = locale("impound_vehicle"),
                content = locale("impound_vehicle_alert", impoundReclaimPrice),
                centered = true,
                cancel = true
            })

            if alert ~= "confirm" then return end
            TriggerServerEvent("ND_Police:impoundVehicle", VehToNet(data.entity), impoundReclaimPrice, input[2])
        end
    }
})

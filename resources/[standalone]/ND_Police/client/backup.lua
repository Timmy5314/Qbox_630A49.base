-- Assistentie-oproep richting ps-dispatch.
--
-- ps-dispatch heeft OfficerBackup (10-32) en OfficerInDistress (10-99) al klaar
-- staan, maar niets op deze server riep ze aan: OfficerDown vuurt automatisch af
-- als je neergaat, en dat was alles. Een agent kon dus geen assistentie vragen
-- zolang hij nog stond.
--
-- De server autoriseert (job + cooldown) en stuurt het pas daarna terug, omdat
-- ps-dispatch de melding client-side opbouwt uit naam, callsign en straat.

if not Config.backup then return end

local function requestBackup(distress)
    if not Bridge.hasGroup(Config.policeGroups) then return end
    TriggerServerEvent("ND_Police:requestBackup", distress)
end

RegisterNetEvent("ND_Police:sendBackupAlert", function(distress)
    if distress then
        return exports["ps-dispatch"]:OfficerInDistress()
    end

    exports["ps-dispatch"]:OfficerBackup()
end)

lib.addKeybind({
    name = "policebackup",
    description = locale("backup_keybind"),
    defaultKey = Config.backupKey,
    onPressed = function()
        requestBackup(false)
    end
})

-- 10-99 heeft bewust geen toets: dit is de zwaarste melding en moet een bewuste
-- handeling zijn, geen misgeslagen knop.
RegisterCommand("distress", function()
    requestBackup(true)
end, false)

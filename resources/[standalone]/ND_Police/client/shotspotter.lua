local data_shotspotter = lib.load("data.shotspotter")
local lastTrigger = 0

local function hasIgnoredJob()
    local player = Bridge.getPlayer()
    for i=1, #data_shotspotter.ignoredJobs do
        local job = data_shotspotter.ignoredJobs[i]
        if Bridge.doesPlayerHaveJob(player, job) then
            return true
        end
    end
end

local function getPlayerPostal()
    if GetResourceState("ModernHUD") == "started" then
        return exports["ModernHUD"]:getPostal()
    elseif GetResourceState("nearest-postal") == "started" then
        return exports["nearest-postal"]:getPostal()
    end
end

local function isPlayerNearShotspotter(coords)
    for i=1, #data_shotspotter.locations do
        local loc = data_shotspotter.locations[i]
        if #(coords.xy-loc.xy) < data_shotspotter.radius then
            return true
        end
    end
end

local function isWeaponIgnored(weapon)
    for i=1, #data_shotspotter.ignoredWeapons do
        local ignoredWeapon = data_shotspotter.ignoredWeapons[i]
        if ignoredWeapon == weapon then
            return true
        end
    end
end

local function usingSuppressor(ped, weapon)
    for i=1, #data_shotspotter.suppresors do
        local suppresor = data_shotspotter.suppresors[i]
        if HasPedGotWeaponComponent(ped, weapon, suppresor) then
            return true
        end
    end
end

local function triggerShotSpotter()
    if hasIgnoredJob() then return end

    local ped = cache.ped
    local time = GetCloudTimeAsInt()

    if time-lastTrigger < data_shotspotter.cooldown then return end

    local coords = GetEntityCoords(ped)
    local weapon = cache.weapon
    if not isPlayerNearShotspotter(coords) or isWeaponIgnored(weapon) or usingSuppressor(ped, weapon) then return end

    -- Pas hier zetten. Stond het hierboven, dan verbruikte een schot dat toch
    -- niets zou melden (demper, uitgezonderd wapen, buiten bereik) de cooldown,
    -- en bleef een echt schot in de twee minuten daarna stil.
    lastTrigger = time


    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    local postal = getPlayerPostal()
    local location = postal and ("%s %s (%s)"):format(street, zoneName, postal) or ("%s %s"):format(street, zoneName)
    
    Wait(data_shotspotter.delay * 1000)

    -- De server toetst deze coordinaten tegen de eigen positie van de speler.
    TriggerServerEvent("ND_Police:shotspotter", location, coords)
end

AddEventHandler("ND_Police:playerJustShot", function(weaponData)
    triggerShotSpotter()
end)

-- De server heeft de melding goedgekeurd (cooldown, coordinaten getoetst) en
-- stuurt hem hier terug, omdat ps-dispatch zijn CustomAlert alleen client-side
-- heeft. Zie shared/bridge.lua.
RegisterNetEvent("ND_Police:sendShotSpotterAlert", function(location, coords)
    -- Twee dingen die het origineel fout had:
    --
    -- `description` bestaat niet in CustomAlert; dat veld werd stilzwijgend
    -- weggegooid. De straat en zone vult ps-dispatch zelf in uit de coordinaten.
    -- Alleen de postcode is extra, en die vraagt om nearest-postal of ModernHUD -
    -- geen van beide draait hier, dus `location` is nu hetzelfde als wat
    -- ps-dispatch al toont. Hij gaat mee in de titel zodra dat verandert.
    --
    -- En `dispatchCode` is de INTERNE naam, `code` is wat de agent op zijn scherm
    -- ziet. Hier stond alleen dispatchCode = "10-71", dus het scherm toonde de
    -- standaard "10-80".
    local message = locale("shot_spotter")

    if location and location ~= "" then
        message = ("%s - %s"):format(message, location)
    end

    exports["ps-dispatch"]:CustomAlert({
        coords = coords,
        message = message,
        dispatchCode = "shotspotter",
        code = "10-71",
        icon = "fas fa-volume-high",
        priority = 1,
        radius = 0,
        sprite = 110,
        color = 1,
        scale = 1.0,
        length = 3,
        jobs = { "leo" }
    })
end)

if data_shotspotter.debug then
    for i=1, #data_shotspotter.locations do
        local loc = data_shotspotter.locations[i]
        local blip = AddBlipForRadius(loc.x, loc.y, loc.z, data_shotspotter.radius)
        SetBlipAlpha(blip, 100)
    end
end

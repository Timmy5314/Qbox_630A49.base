---Schade- en explosievalidatie.
---
---Dit is de enige plek in de hele anti-cheat waar de server een actie van een
---client echt kan TEGENHOUDEN. weaponDamageEvent en explosionEvent worden
---server-side gerouteerd en CancelEvent() werkt hier wel degelijk. Alle andere
---modules kunnen alleen waarnemen en scoren.

---Wapens waarvoor geen inventory-bezitscheck geldt. Melee en ongewapend zitten
---niet als item in ox_inventory, en voertuigwapens komen uit het voertuig.
local skipOwnershipCheck = {
    [joaat('WEAPON_UNARMED')] = true,
    [joaat('WEAPON_ANIMAL')] = true,
    [joaat('WEAPON_COUGAR')] = true,
    [joaat('OBJECT')] = true,
    [joaat('WEAPON_RAMMED_BY_CAR')] = true,
    [joaat('WEAPON_RUN_OVER_BY_CAR')] = true,
    [joaat('WEAPON_FALL')] = true,
    [joaat('WEAPON_DROWNING')] = true,
    [joaat('WEAPON_EXPLOSION')] = true,
    [joaat('WEAPON_FIRE')] = true,
    [joaat('WEAPON_HIT_BY_WATER_CANNON')] = true,
    [joaat('WEAPON_ELECTRIC_FENCE')] = true,
}

---Controleert of de speler het wapen daadwerkelijk in zijn ox_inventory heeft.
---@param source number
---@param weaponName string
---@return boolean
local function hasWeaponItem(source, weaponName)
    local ok, items = pcall(function()
        return exports.ox_inventory:Search(source, 'count', weaponName:lower())
    end)

    if not ok then return true end -- inventory niet bereikbaar: geen conclusie trekken
    return (items or 0) > 0
end

AddEventHandler('weaponDamageEvent', function(sender, data)
    local weaponHash = data.weaponType
    local weapon = WeaponData.get(weaponHash)

    -- 1. Wapens die op deze server niet bestaan. Geen sync-fout mogelijk.
    if WeaponData.blacklistByHash[weaponHash] then
        CancelEvent()
        AC_Flag(sender, 'blacklistedWeapon',
            ('wapen %s'):format(weapon and weapon.name or weaponHash),
            { weapon = weaponHash, damage = data.weaponDamage })
        return
    end

    -- 2. Damage modifier. Legitieme scripts zetten deze vlag niet; menu's wel.
    if data.overrideDefaultDamage then
        CancelEvent()
        AC_Flag(sender, 'damageOverride',
            ('%s met overrideDefaultDamage, schade %s'):format(weapon and weapon.name or weaponHash, data.weaponDamage),
            { weapon = weaponHash, damage = data.weaponDamage })
        return
    end

    -- 3. Schade boven wat het wapen kan leveren.
    --    Onbekende wapens worden bewust NIET op schade gecontroleerd: liever een
    --    gemiste detectie dan een ban omdat iemand een custom wapen toevoegde
    --    zonder shared/weapondamage.lua bij te werken.
    local maxDamage = WeaponData.maxDamage(weaponHash)
    if maxDamage and data.weaponDamage and data.weaponDamage > maxDamage then
        CancelEvent()
        AC_Flag(sender, 'damageTooHigh',
            ('%s deed %s, maximum is %.0f'):format(weapon and weapon.name or weaponHash, data.weaponDamage, maxDamage),
            { weapon = weaponHash, damage = data.weaponDamage, max = maxDamage })
        return
    end

    if not weapon or skipOwnershipCheck[weaponHash] then return end

    -- 4a. Voertuig-/turretwapens: aparte redenering. Deze horen niet in een
    --     inventory thuis. De vraag is of de speler uberhaupt in een voertuig zit.
    if weapon.kind == 'vehicle' then
        local ped = GetPlayerPed(sender)
        if ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) == 0 then
            CancelEvent()
            AC_Flag(sender, 'weaponNotOwned',
                ('voertuigwapen %s afgevuurd zonder in een voertuig te zitten'):format(weapon.name),
                { weapon = weaponHash })
        end
        return
    end

    -- 4b. Handwapens: moet als item in ox_inventory zitten.
    --     Alleen scoren, niet cancelen. ox_inventory draait al met
    --     inventory:weaponmismatch true en ontwapent zelf. Hier ook cancelen
    --     geeft dubbele afhandeling en false positives tijdens wapenwissels.
    if not hasWeaponItem(sender, weapon.name) then
        AC_Flag(sender, 'weaponNotOwned',
            ('schoot met %s zonder het item te bezitten'):format(weapon.name),
            { weapon = weaponHash })
    end

    -- Treffers registreren voor de godmode-check in heartbeat.lua. Alleen
    -- geldige schade telt mee; geannuleerde events hebben hierboven al returned.
    local targets = data.hitGlobalIds
    if type(targets) ~= 'table' then return end

    for i = 1, #targets do
        local entity = NetworkGetEntityFromNetworkId(targets[i])
        if entity and entity ~= 0 then
            local victim = AC_SourceFromPed(entity)
            if victim then
                AC_RecordHit(victim)
            end
        end
    end
end)

AddEventHandler('explosionEvent', function(sender, data)
    if not Config.blockedExplosions[data.explosionType] then return end

    CancelEvent()
    AC_Flag(sender, 'explosionBlocked',
        ('explosietype %d geblokkeerd'):format(data.explosionType),
        { explosionType = data.explosionType, position = { data.posX, data.posY, data.posZ } })
end)

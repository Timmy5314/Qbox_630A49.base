---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - weapon armory

    Weapons and attachments are plain ox_inventory items. The armory hands them
    out and takes them back; attaching them happens through the normal
    ox_inventory flow (use the attachment while holding the weapon), so we are
    not fighting the inventory with a parallel component system like 1.x did.
]]

Armory = {}

--- Cached attachment list built from ox_inventory item data.
local attachmentCache

---@return table[] attachments { name, label, image }
local function getAttachments()
    if attachmentCache then return attachmentCache end

    attachmentCache = {}
    local items = exports.ox_inventory:Items() or {}

    for name, item in pairs(items) do
        -- ox_inventory marks weapon attachments with a client.component list.
        if item.client and item.client.component then
            attachmentCache[#attachmentCache + 1] = {
                name       = name,
                label      = item.label or name,
                image      = name,
                components = item.client.component,
            }
        end
    end

    table.sort(attachmentCache, function(a, b) return a.label < b.label end)
    return attachmentCache
end

---@param jobName string
---@param grade number
---@return table[] weapons the grade may take
function Armory.getAllowed(jobName, grade)
    local list = Config.Armory[jobName]
    if not list then return {} end

    local weapons = {}
    for weapon, data in pairs(list) do
        if (data.mingrade or 0) <= grade then
            weapons[#weapons + 1] = {
                name     = weapon,
                label    = Bridge.getItemLabel(weapon),
                image    = Bridge.normaliseItem(weapon),
                price    = tonumber(data.price) or 0,
                mingrade = data.mingrade or 0,
            }
        end
    end

    table.sort(weapons, function(a, b) return a.label < b.label end)
    return weapons
end

lib.callback.register('renzu_jobs:getArmory', function(source)
    local allowed, job, feature = Access.feature(source, 'armory')
    if not job or not feature then return nil end

    if not allowed then
        Bridge.notify(source, 'error', 'Armory', 'Your rank does not have access to the armory.')
        return nil
    end
    if not Access.nearby(source, feature.coord, 8.0) then return nil end

    if not Config.Armory[job.name] then
        Bridge.notify(source, 'warning', 'Armory', ('No weapons are configured for %s in config/weapons.lua.'):format(job.name))
        return nil
    end

    -- Mark what the player already carries so the UI can show take vs return.
    local owned = {}
    for _, slot in ipairs(Bridge.getWeapons(source)) do
        owned[slot.name:upper()] = true
    end

    local weapons = Armory.getAllowed(job.name, job.grade)
    for _, weapon in ipairs(weapons) do
        weapon.owned = owned[weapon.name:upper()] == true
    end

    return {
        label       = feature.label,
        weapons     = weapons,
        attachments = getAttachments(),
        balance     = Db.getBalance(job.name, 'money'),
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Take / return a weapon
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:toggleWeapon', function(source, weaponName)
    local allowed, job, feature = Access.feature(source, 'armory')
    if not job or not feature or not allowed then return false end
    if not Access.nearby(source, feature.coord, 8.0) then
        Bridge.notify(source, 'error', 'Armory', 'Step up to the armory first.')
        return false
    end

    local entry = Config.Armory[job.name] and Config.Armory[job.name][weaponName]
    if not entry then
        lib.print.warn(('%s tried to take "%s" which is not in the %s armory'):format(source, tostring(weaponName), job.name))
        return false
    end
    if (entry.mingrade or 0) > job.grade then
        Bridge.notify(source, 'error', 'Armory', 'Your rank is not cleared for that weapon.')
        return false
    end

    local label = Bridge.getItemLabel(weaponName)

    -- Already carrying it? Then this is a hand-in.
    if Bridge.getItemCount(source, weaponName) > 0 then
        if not Bridge.removeItem(source, weaponName, 1) then
            Bridge.notify(source, 'error', 'Armory', 'Could not take that weapon back.')
            return false
        end
        Bridge.notify(source, 'inform', 'Armory', ('Returned the %s.'):format(label))

        Logs.send({
            feature = 'armory', webhook = feature.webhook,
            title = 'Weapon returned', severity = 'info', source = source,
            fields = { { name = 'Weapon', value = label, inline = true } },
        })
        return true
    end

    local price = tonumber(entry.price) or 0
    if price > 0 then
        if not Db.removeBalance(job.name, 'money', price) then
            Bridge.notify(source, 'error', 'Armory', ('The company treasury cannot cover $%s.'):format(price))
            return false
        end
        Accounts.broadcast(job.name)
    end

    if not Bridge.canCarry(source, weaponName, 1) then
        if price > 0 then Db.addBalance(job.name, 'money', price) Accounts.broadcast(job.name) end
        Bridge.notify(source, 'error', 'Armory', 'You do not have room for that weapon.')
        return false
    end

    -- Give the weapon plus a magazine of the matching ammo, if it uses any.
    local weaponData = Bridge.getItemData(weaponName)
    local ammoName = weaponData and weaponData.ammoname

    if not Bridge.addItem(source, weaponName, 1) then
        if price > 0 then Db.addBalance(job.name, 'money', price) Accounts.broadcast(job.name) end
        Bridge.notify(source, 'error', 'Armory', 'The weapon could not be handed out.')
        return false
    end

    if ammoName and Bridge.canCarry(source, ammoName, 60) then
        Bridge.addItem(source, ammoName, 60)
    end

    Bridge.notify(source, 'success', 'Armory',
        price > 0 and ('Signed out the %s for $%s.'):format(label, price)
                   or ('Signed out the %s.'):format(label))

    Logs.send({
        feature = 'armory', webhook = feature.webhook,
        title = 'Weapon taken', severity = 'info', source = source,
        fields = {
            { name = 'Weapon', value = label, inline = true },
            { name = 'Cost',   value = ('$%s'):format(price), inline = true },
        },
    })
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Attachments
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('renzu_jobs:takeAttachment', function(source, itemName)
    local allowed, job, feature = Access.feature(source, 'armory')
    if not job or not feature or not allowed then return false end
    if not Access.nearby(source, feature.coord, 8.0) then return false end

    -- Only real attachment items are allowed through.
    local valid = false
    for _, attachment in ipairs(getAttachments()) do
        if attachment.name == itemName then valid = true break end
    end
    if not valid then
        lib.print.warn(('%s tried to take "%s" as an attachment'):format(source, tostring(itemName)))
        return false
    end

    if not Bridge.canCarry(source, itemName, 1) then
        Bridge.notify(source, 'error', 'Armory', 'You do not have room for that attachment.')
        return false
    end
    if not Bridge.addItem(source, itemName, 1) then return false end

    local label = Bridge.getItemLabel(itemName)
    Bridge.notify(source, 'success', 'Armory',
        ('Took a %s. Equip the weapon and use the attachment to fit it.'):format(label))

    Logs.send({
        feature = 'armory', webhook = feature.webhook,
        title = 'Attachment taken', severity = 'info', source = source,
        fields = { { name = 'Attachment', value = label, inline = true } },
    })
    return true
end)

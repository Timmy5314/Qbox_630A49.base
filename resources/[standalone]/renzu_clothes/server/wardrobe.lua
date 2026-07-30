---@diagnostic disable: undefined-global
--- Server side of the item system. The server is the single source of truth:
--- it decides what you are wearing, pulls items out of your inventory and
--- puts them back.

Wardrobe = {}

---@type table<number, { identifier: string, worn: table, outfits: table }>
local state = {}
local deathCooldown = {}

-- ── State ─────────────────────────────────────────────────────────────────

---@param src number
---@return table|nil
function Wardrobe.getState(src)
    local cached = state[src]
    if cached then return cached end

    local identifier = Bridge.getIdentifier(src)
    if not identifier then return nil end

    local row = Db.load(identifier)
    state[src] = {
        identifier = identifier,
        worn = row.worn,
        outfits = row.outfits,
    }

    return state[src]
end

---@param src number
local function sync(src)
    local data = state[src]
    TriggerClientEvent('renzu_clothes:sync', src, data and data.worn or {})
end

---@param src number
local function persist(src)
    local data = state[src]
    if not data then return end
    Db.saveWorn(data.identifier, data.worn)
end

-- ── Metadata sanitising ───────────────────────────────────────────────────

--- Makes sure metadata always matches the config. Stops an item with crafted
--- metadata from setting an arbitrary component.
---@param slot string
---@param metadata table|nil
---@return table
local function normalize(slot, metadata)
    local slotData = Config.Slots[slot]
    metadata = type(metadata) == 'table' and metadata or {}

    local drawable = math.floor(tonumber(metadata.drawable) or 0)
    local texture = math.floor(tonumber(metadata.texture) or 0)

    if drawable < (slotData.isProp and -1 or 0) then drawable = slotData.isProp and -1 or 0 end
    if texture < 0 then texture = 0 end
    if drawable > 1000 then drawable = 0 end
    if texture > 100 then texture = 0 end

    local clean = {
        slot = slot,
        component = slotData.component,
        isProp = slotData.isProp or false,
        drawable = drawable,
        texture = texture,
        label = type(metadata.label) == 'string' and metadata.label
            or ('%s #%d-%d'):format(slotData.label, drawable, texture),
        description = ('Category: %s'):format(slotData.label),
        image = slotData.item,
        model = type(metadata.model) == 'string' and metadata.model or nil,
    }

    if slotData.linkedArms and type(metadata.arms) == 'table' then
        clean.arms = {
            drawable = math.floor(tonumber(metadata.arms.drawable) or 0),
            texture = math.floor(tonumber(metadata.arms.texture) or 0),
        }
    end

    return clean
end

Wardrobe.normalize = normalize

-- ── Returning an item to the inventory ────────────────────────────────────

--- Tries to put a garment back in the inventory. If that fails it drops on
--- the ground instead of vanishing.
---@param src number
---@param metadata table
---@return boolean inInventory
local function returnToInventory(src, metadata)
    local slotData = Config.Slots[metadata.slot]
    if not slotData then return false end

    if Inv.addItem(src, slotData.item, 1, metadata) then
        return true
    end

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        Inv.createDrop(coords, { { item = slotData.item, count = 1, metadata = metadata } })
        Bridge.notify(src, 'Your bag was full, the garment dropped on the ground.', 'warning')
    end

    return false
end

-- ── Putting clothes on ────────────────────────────────────────────────────

lib.callback.register('renzu_clothes:wear', function(src, payload)
    local data = Wardrobe.getState(src)
    if not data then return { success = false, message = 'Player not found.' } end

    local itemName = type(payload) == 'table' and payload.item
    if type(itemName) ~= 'string' then
        return { success = false, message = 'Invalid item.' }
    end

    local slot = Config.SlotByItem(itemName)
    if not slot then return { success = false, message = 'That is not a garment.' } end

    -- Find the item: prefer the hinted slot, otherwise search the inventory.
    local invSlot, metadata

    local hinted = Inv.getSlot(src, tonumber(payload.slot))
    if hinted and hinted.name == itemName then
        invSlot, metadata = hinted.slot, hinted.metadata
    else
        local found = Inv.search(src, itemName)
        if found and found[1] then
            invSlot, metadata = found[1].slot, found[1].metadata
        end
    end

    if not invSlot then
        return { success = false, message = 'You do not have that garment.' }
    end

    local clean = normalize(slot, metadata)

    -- Take the new piece out of the inventory.
    if not Inv.removeItem(src, itemName, 1, nil, invSlot) then
        return { success = false, message = 'Could not take the item from your bag.' }
    end

    -- Something already in this slot goes back into the bag.
    local previous = data.worn[slot]
    if previous then
        returnToInventory(src, previous)
    end

    data.worn[slot] = clean
    persist(src)
    sync(src)

    return { success = true, worn = data.worn }
end)

-- ── Taking clothes off ────────────────────────────────────────────────────

--- Throttles converting spawn clothing into items, so a bad actor cannot
--- farm garments by spamming the callback.
local convertCooldown = {}

lib.callback.register('renzu_clothes:takeOff', function(src, slot, visual)
    local data = Wardrobe.getState(src)
    if not data then return { success = false, message = 'Player not found.' } end

    if type(slot) ~= 'string' or not Config.Slots[slot] then
        return { success = false, message = 'Unknown clothing slot.' }
    end

    local metadata = data.worn[slot]
    local managed = metadata ~= nil

    if not metadata then
        -- Spawn / appearance clothing: not an item yet. The client reports
        -- what the ped visually wears; normalize() clamps it to sane values.
        -- Taking it off converts the garment into a regular inventory item.
        if type(visual) ~= 'table' then
            return { success = false, message = 'You are not wearing anything there.' }
        end

        local now = GetGameTimer()
        if convertCooldown[src] and now - convertCooldown[src] < 1000 then
            return { success = false, message = 'Slow down.' }
        end
        convertCooldown[src] = now

        metadata = normalize(slot, {
            drawable = visual.drawable,
            texture = visual.texture,
            arms = visual.arms,
            model = visual.model,
        })
    end

    local slotData = Config.Slots[slot]

    if not Inv.canCarry(src, slotData.item, 1, metadata) then
        return { success = false, message = 'Your bag is full.' }
    end

    if not Inv.addItem(src, slotData.item, 1, metadata) then
        return { success = false, message = 'Could not put the garment in your bag.' }
    end

    if managed then
        data.worn[slot] = nil
        persist(src)
    end
    sync(src)

    return { success = true, worn = data.worn }
end)

lib.callback.register('renzu_clothes:getWorn', function(src)
    local data = Wardrobe.getState(src)
    return data and data.worn or {}
end)

--- Reads an item's metadata without touching it. The client uses this to
--- check whether the garment matches its ped model.
lib.callback.register('renzu_clothes:peekItem', function(src, itemName, invSlot)
    if type(itemName) ~= 'string' or not Config.SlotByItem(itemName) then return nil end

    local hinted = Inv.getSlot(src, tonumber(invSlot))
    if hinted and hinted.name == itemName then return hinted.metadata end

    local found = Inv.search(src, itemName)
    return found and found[1] and found[1].metadata or nil
end)

-- ── Death ─────────────────────────────────────────────────────────────────

RegisterNetEvent('renzu_clothes:died', function()
    local src = source
    if not Config.Death.enabled then return end
    if Config.Death.onDeath == 'keep' then return end

    local now = os.time()
    if deathCooldown[src] and now - deathCooldown[src] < 3 then return end
    deathCooldown[src] = now

    local data = Wardrobe.getState(src)
    if not data then return end

    local removed = {}

    for slot, metadata in pairs(data.worn) do
        if not Config.Death.keepSlots[slot] then
            removed[#removed + 1] = metadata
            data.worn[slot] = nil
        end
    end

    if #removed == 0 then return end

    if Config.Death.onDeath == 'return' then
        for i = 1, #removed do
            returnToInventory(src, removed[i])
        end
        Bridge.notify(src, 'Your clothing is back in your bag. Put it on again.', 'inform')
    elseif Config.Death.onDeath == 'drop' then
        local ped = GetPlayerPed(src)
        local coords = ped ~= 0 and GetEntityCoords(ped) or nil

        if coords then
            local items = {}
            for i = 1, #removed do
                items[#items + 1] = {
                    item = Config.Slots[removed[i].slot].item,
                    count = 1,
                    metadata = removed[i],
                }
            end
            Inv.createDrop(coords, items)
            Bridge.notify(src, 'Your clothing dropped where you went down.', 'warning')
        end
    else -- 'delete'
        Bridge.notify(src, 'Your clothing was lost.', 'error')
    end

    persist(src)
    sync(src)
end)

-- ── Player load / unload ──────────────────────────────────────────────────

local function onPlayerLoaded(src)
    if not src then return end
    state[src] = nil

    SetTimeout(2000, function()
        local data = Wardrobe.getState(src)
        if data then sync(src) end
    end)
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
    onPlayerLoaded(player and (player.PlayerData and player.PlayerData.source) or source)
end)

RegisterNetEvent('qbx_core:server:playerLoaded', function(player)
    onPlayerLoaded(player and (player.PlayerData and player.PlayerData.source) or source)
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    onPlayerLoaded(playerId or source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    persist(src)
    state[src] = nil
    deathCooldown[src] = nil
    convertCooldown[src] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src in pairs(state) do
        persist(src)
    end
end)

-- Reload every online player after a restart.
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetTimeout(3000, function()
        local players = GetPlayers()

        for i = 1, #players do
            local src = tonumber(players[i])
            local data = Wardrobe.getState(src)
            if data then sync(src) end
        end
    end)
end)

-- ── Exports for other resources ───────────────────────────────────────────

--- Gives a player a garment as an inventory item.
---@param src number
---@param slot string
---@param drawable integer
---@param texture integer
---@param label string|nil
---@return boolean
exports('giveClothing', function(src, slot, drawable, texture, label)
    local slotData = Config.Slots[slot]
    if not slotData then return false end

    local metadata = normalize(slot, { drawable = drawable, texture = texture, label = label })
    return Inv.addItem(src, slotData.item, 1, metadata)
end)

exports('getWorn', function(src)
    local data = Wardrobe.getState(src)
    return data and data.worn or {}
end)

--- Takes everything off and puts it back in the inventory.
exports('stripPlayer', function(src)
    local data = Wardrobe.getState(src)
    if not data then return false end

    for slot, metadata in pairs(data.worn) do
        returnToInventory(src, metadata)
        data.worn[slot] = nil
    end

    persist(src)
    sync(src)
    return true
end)

Wardrobe.sync = sync
Wardrobe.persist = persist
Wardrobe.returnToInventory = returnToInventory

---@diagnostic disable: undefined-global
--- Outfits: save, wear, delete and share through a code.
---
--- An outfit is a list of garments. Wearing one only works with items you
--- actually own, so a shared code can never conjure clothing out of thin air.

local codes = {}

local CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' -- no I/O/0/1, easier to read

---@param length integer
---@return string
local function randomCode(length)
    local out = {}

    for _ = 1, length do
        local index = math.random(1, #CHARSET)
        out[#out + 1] = CHARSET:sub(index, index)
    end

    return table.concat(out)
end

---@param src number
---@param outfits table
local function persistOutfits(src, outfits)
    local data = Wardrobe.getState(src)
    if not data then return end

    data.outfits = outfits
    Db.saveOutfits(data.identifier, outfits)
end

-- ── Fetching ──────────────────────────────────────────────────────────────

lib.callback.register('renzu_clothes:getOutfits', function(src)
    local data = Wardrobe.getState(src)
    return data and data.outfits or {}
end)

-- ── Saving ────────────────────────────────────────────────────────────────

lib.callback.register('renzu_clothes:saveOutfit', function(src, name)
    local data = Wardrobe.getState(src)
    if not data then return { success = false, message = 'Player not found.' } end

    if type(name) ~= 'string' then return { success = false, message = 'Invalid name.' } end

    name = name:gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 32)
    if name == '' then return { success = false, message = 'Give it a name.' } end

    local count = 0
    for _ in pairs(data.outfits) do count = count + 1 end

    if not data.outfits[name] and count >= Config.MaxOutfits then
        return { success = false, message = ('Your wardrobe is full (max %d outfits).'):format(Config.MaxOutfits) }
    end

    local snapshot = {}
    local pieces = 0

    for slot, metadata in pairs(data.worn) do
        snapshot[slot] = {
            slot = slot,
            drawable = metadata.drawable,
            texture = metadata.texture,
            label = metadata.label,
            arms = metadata.arms,
        }
        pieces = pieces + 1
    end

    if pieces == 0 then
        return { success = false, message = 'You are not wearing anything to save.' }
    end

    data.outfits[name] = snapshot
    persistOutfits(src, data.outfits)

    return { success = true }
end)

-- ── Deleting ──────────────────────────────────────────────────────────────

lib.callback.register('renzu_clothes:deleteOutfit', function(src, name)
    local data = Wardrobe.getState(src)
    if not data or type(name) ~= 'string' or not data.outfits[name] then return false end

    data.outfits[name] = nil
    persistOutfits(src, data.outfits)

    return true
end)

-- ── Wearing ───────────────────────────────────────────────────────────────

--- Looks for an owned garment matching this outfit entry.
---@param src number
---@param slot string
---@param target table
---@return integer|nil invSlot, table|nil metadata
local function findOwned(src, slot, target)
    local slotData = Config.Slots[slot]
    if not slotData then return nil end

    local found = Inv.search(src, slotData.item)

    for i = 1, #found do
        local meta = found[i].metadata

        if type(meta) == 'table'
            and tonumber(meta.drawable) == tonumber(target.drawable)
            and tonumber(meta.texture) == tonumber(target.texture)
        then
            return found[i].slot, meta
        end
    end

    return nil
end

lib.callback.register('renzu_clothes:wearOutfit', function(src, name)
    local data = Wardrobe.getState(src)
    if not data then return { success = false, message = 'Player not found.' } end

    local outfit = type(name) == 'string' and data.outfits[name]
    if not outfit then return { success = false, message = 'That outfit does not exist.' } end

    local missing = {}

    -- 1. Take off anything the outfit does not include.
    for slot, metadata in pairs(data.worn) do
        if not outfit[slot] then
            Wardrobe.returnToInventory(src, metadata)
            data.worn[slot] = nil
        end
    end

    -- 2. Build the outfit.
    for slot, target in pairs(outfit) do
        if Config.Slots[slot] then
            local current = data.worn[slot]

            local alreadyRight = current
                and tonumber(current.drawable) == tonumber(target.drawable)
                and tonumber(current.texture) == tonumber(target.texture)

            if not alreadyRight then
                local invSlot, metadata = findOwned(src, slot, target)

                if invSlot then
                    local clean = Wardrobe.normalize(slot, metadata)

                    if Inv.removeItem(src, Config.Slots[slot].item, 1, nil, invSlot) then
                        if current then
                            Wardrobe.returnToInventory(src, current)
                        end
                        data.worn[slot] = clean
                    else
                        missing[#missing + 1] = slot
                    end
                else
                    if current then
                        Wardrobe.returnToInventory(src, current)
                        data.worn[slot] = nil
                    end
                    missing[#missing + 1] = slot
                end
            end
        end
    end

    Wardrobe.persist(src)
    Wardrobe.sync(src)

    return { success = true, worn = data.worn, missing = missing }
end)

-- ── Sharing through a code ────────────────────────────────────────────────

lib.callback.register('renzu_clothes:generateCode', function(src, name)
    local data = Wardrobe.getState(src)
    if not data then return nil end

    local outfit = type(name) == 'string' and data.outfits[name]
    if not outfit then return nil end

    local code
    repeat code = randomCode(6) until not codes[code]

    codes[code] = {
        outfit = outfit,
        expires = os.time() + (Config.OutfitCodeMinutes * 60),
    }

    return code
end)

lib.callback.register('renzu_clothes:redeemCode', function(src, payload)
    local data = Wardrobe.getState(src)
    if not data then return { success = false, message = 'Player not found.' } end

    local code = type(payload) == 'table' and type(payload.code) == 'string' and payload.code:upper() or nil
    local name = type(payload) == 'table' and type(payload.name) == 'string' and payload.name or nil

    if not code or not name then return { success = false, message = 'Fill in both fields.' } end

    local entry = codes[code]
    if not entry or entry.expires < os.time() then
        codes[code] = nil
        return { success = false, message = 'That code does not exist or has expired.' }
    end

    name = name:gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 32)
    if name == '' then return { success = false, message = 'Give it a name.' } end

    local count = 0
    for _ in pairs(data.outfits) do count = count + 1 end

    if not data.outfits[name] and count >= Config.MaxOutfits then
        return { success = false, message = ('Your wardrobe is full (max %d outfits).'):format(Config.MaxOutfits) }
    end

    data.outfits[name] = entry.outfit
    persistOutfits(src, data.outfits)

    return { success = true }
end)

-- Clean up expired codes.
CreateThread(function()
    while true do
        Wait(300000) -- every 5 minutes
        local now = os.time()

        for code, entry in pairs(codes) do
            if entry.expires < now then codes[code] = nil end
        end
    end
end)

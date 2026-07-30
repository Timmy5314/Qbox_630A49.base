---@diagnostic disable: undefined-global
--- Core of the item system: what the player is wearing, and how it ends up
--- on the ped.
---
--- Key idea: equipped clothing is NOT in the inventory. Use an item and it
--- leaves your bag and goes onto your body. Take it off and the item comes
--- back, so it can be dropped, traded or lost like any other item.

Wardrobe = {}

---@type table<string, table> slot -> metadata of the equipped item
local worn = {}
local wornCount = 0
local previewing = false
local applying = false
local busy = false
local isDead = false

-- ── Animations ────────────────────────────────────────────────────────────

local ANIMS = {
    jacket   = { dict = 'clothingshirt',    clip = 'try_shirt_positive_d' },
    shirt    = { dict = 'clothingshirt',    clip = 'try_shirt_positive_d' },
    vest     = { dict = 'clothingshirt',    clip = 'try_shirt_positive_d' },
    decals   = { dict = 'clothingshirt',    clip = 'try_shirt_positive_d' },
    chain    = { dict = 'clothingtie',      clip = 'try_tie_positive_a' },
    pants    = { dict = 'clothingtrousers', clip = 'try_trousers_positive_a' },
    shoes    = { dict = 'clothingshoes',    clip = 'try_shoes_positive_a' },
    hat      = { dict = 'clothinghat',      clip = 'try_hat_positive_a' },
    mask     = { dict = 'clothinghat',      clip = 'try_hat_positive_a' },
    glasses  = { dict = 'clothingspecs',    clip = 'try_glasses_positive_a' },
    ears     = { dict = 'clothingspecs',    clip = 'try_glasses_positive_a' },
    watch    = { dict = 'clothingtie',      clip = 'try_tie_positive_a' },
    bracelet = { dict = 'clothingtie',      clip = 'try_tie_positive_a' },
    bag      = { dict = 'clothingtie',      clip = 'try_tie_positive_a' },
}

---@param slot string
local function playClothingAnim(slot)
    local time = Config.Inventory.animationTime
    if not time or time <= 0 then return end

    local anim = ANIMS[slot]
    if not anim then return end
    if IsPedInAnyVehicle(cache.ped, false) then return end

    local ok = pcall(lib.requestAnimDict, anim.dict, 1000)
    if not ok or not HasAnimDictLoaded(anim.dict) then return end

    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 8.0, 1.0, -1, 49, 0, false, false, false)
    Wait(time)
    StopAnimTask(cache.ped, anim.dict, anim.clip, 1.0)
    RemoveAnimDict(anim.dict)
end

-- ── Applying to the ped ───────────────────────────────────────────────────

--- Puts one slot on the ped: the equipped item, or the default value when
--- the slot is empty.
---@param slot string
local function applySlot(slot)
    local data = Config.Slots[slot]
    if not data then return end

    local meta = worn[slot]
    applying = true

    if meta then
        Bridge.applyPiece(cache.ped, data.component, meta.drawable, meta.texture, data.isProp)

        if data.linkedArms and meta.arms then
            SetPedComponentVariation(cache.ped, Config.ArmsComponent, meta.arms.drawable, meta.arms.texture or 0, 0)
        end
    else
        local drawable, texture = Bridge.getDefaultPiece(cache.ped, data.component, data.isProp)
        Bridge.applyPiece(cache.ped, data.component, drawable, texture, data.isProp)

        if data.linkedArms then
            local aDraw, aTex = Bridge.getDefaultPiece(cache.ped, Config.ArmsComponent, false)
            SetPedComponentVariation(cache.ped, Config.ArmsComponent, aDraw, aTex, 0)
        end
    end

    applying = false
end

local function recount()
    wornCount = 0
    for _ in pairs(worn) do wornCount = wornCount + 1 end
end

--- Slots that were applied as "worn" on the last pass. Needed so taking a
--- piece off resets exactly that slot - and nothing else.
local lastApplied = {}

--- Applies the equipped clothing to the ped.
---
--- Deliberately touches ONLY two kinds of slots:
---   1. slots with an equipped item (put it on)
---   2. slots that had one last time but no longer do (back to default)
--- Empty slots are left alone, so spawn clothing or job outfits from another
--- script are never overwritten by this resource.
function Wardrobe.apply()
    if previewing then return end

    for slot in pairs(lastApplied) do
        if not worn[slot] then
            applySlot(slot) -- just taken off: back to the default value
        end
    end

    for slot in pairs(worn) do
        applySlot(slot)
    end

    lastApplied = {}
    for slot in pairs(worn) do lastApplied[slot] = true end
end

--- What the player is wearing (a copy, not the internal table).
---@return table<string, table>
function Wardrobe.getWorn()
    local copy = {}
    for slot, meta in pairs(worn) do
        copy[slot] = meta
    end
    return copy
end

---@param slot string
---@return table|nil
function Wardrobe.getSlot(slot)
    return worn[slot]
end

---@return boolean
function Wardrobe.isPreviewing()
    return previewing
end

--- What the ped visually wears in a slot this resource does NOT manage:
--- spawn clothing from an appearance script, job outfits, and so on.
--- Returns nil for managed slots, while previewing (so fitting-room clothes
--- can never be converted into free items) and when the slot shows the
--- default "nothing equipped" value.
---@param slot string
---@return { drawable: integer, texture: integer, arms?: table }|nil
function Wardrobe.getVisualSlot(slot)
    if previewing or worn[slot] then return nil end

    local data = Config.Slots[slot]
    if not data then return nil end

    local drawable = data.isProp and GetPedPropIndex(cache.ped, data.component)
        or GetPedDrawableVariation(cache.ped, data.component)
    local texture = data.isProp and GetPedPropTextureIndex(cache.ped, data.component)
        or GetPedTextureVariation(cache.ped, data.component)

    if data.isProp and (not drawable or drawable < 0) then return nil end

    local defDraw, defTex = Bridge.getDefaultPiece(cache.ped, data.component, data.isProp)
    if drawable == defDraw and texture == defTex then return nil end

    local visual = { drawable = drawable, texture = texture }

    if data.linkedArms then
        visual.arms = {
            drawable = GetPedDrawableVariation(cache.ped, Config.ArmsComponent),
            texture = GetPedTextureVariation(cache.ped, Config.ArmsComponent),
        }
    end

    return visual
end

--- Toggles preview mode. While previewing, the integrity watcher leaves the
--- ped alone so the shop UI can try things on freely.
---@param state boolean
function Wardrobe.setPreview(state)
    previewing = state and true or false
    if not previewing then
        Wardrobe.apply()
    end
end

-- ── Server sync ───────────────────────────────────────────────────────────

local function setWorn(data)
    worn = data or {}
    recount()

    if not previewing then
        Wardrobe.apply()
    end

    TriggerEvent('renzu_clothes:wornChanged', Wardrobe.getWorn())
end

RegisterNetEvent('renzu_clothes:sync', setWorn)

--- Fetches the equipped clothing from the server again and applies it.
function Wardrobe.refresh()
    setWorn(lib.callback.await('renzu_clothes:getWorn', false))
end

-- ── Putting clothes on ────────────────────────────────────────────────────

---@param itemName string
---@param invSlot integer|nil
---@return boolean
function Wardrobe.wear(itemName, invSlot)
    if busy then return false end

    local slot = Config.SlotByItem(itemName)
    if not slot then return false end

    if not Config.Inventory.allowInVehicle and IsPedInAnyVehicle(cache.ped, false) then
        Bridge.notify('You cannot change clothes inside a vehicle.', 'error')
        return false
    end

    if previewing then
        -- Still inside the store zone. With the shop UI actually open we
        -- refuse; with it closed we just end the fitting-room preview and
        -- dress normally.
        if Shop and Shop.isOpen and Shop.isOpen() then
            Bridge.notify('Close the clothing store first.', 'error')
            return false
        end

        if Shop and Shop.stopPreview then
            Shop.stopPreview()
        end
    end

    busy = true

    -- Clothing is model specific. A male garment on a female ped just gives
    -- broken textures, so block it up front.
    local peek = lib.callback.await('renzu_clothes:peekItem', false, itemName, invSlot)
    if peek and peek.model and peek.model ~= Bridge.getModelName(cache.ped) then
        busy = false
        Bridge.notify('This garment was not made for your body type.', 'error')
        return false
    end

    playClothingAnim(slot)

    local result = lib.callback.await('renzu_clothes:wear', false, {
        item = itemName,
        slot = invSlot,
    })

    busy = false

    if not result or not result.success then
        Bridge.notify(result and result.message or 'This garment does not fit.', 'error')
        return false
    end

    setWorn(result.worn)
    Bridge.notify(('%s equipped.'):format(Config.Slots[slot].label), 'success')
    return true
end

-- ── Taking clothes off ────────────────────────────────────────────────────

---@param slot string
---@return boolean
function Wardrobe.takeOff(slot)
    if busy then return false end

    if not Config.Inventory.allowInVehicle and IsPedInAnyVehicle(cache.ped, false) then
        Bridge.notify('You cannot change clothes inside a vehicle.', 'error')
        return false
    end

    if previewing then
        if Shop and Shop.isOpen and Shop.isOpen() then
            Bridge.notify('Close the clothing store first.', 'error')
            return false
        end

        if Shop and Shop.stopPreview then
            Shop.stopPreview()
        end
    end

    -- Read the visual AFTER the preview has been dropped, otherwise clothes
    -- from the fitting room could be converted into free items.
    local visual = not worn[slot] and Wardrobe.getVisualSlot(slot) or nil

    if not worn[slot] and not visual then
        Bridge.notify('You are not wearing anything there.', 'error')
        return false
    end

    busy = true
    playClothingAnim(slot)

    local result = lib.callback.await('renzu_clothes:takeOff', false, slot, visual and {
        drawable = visual.drawable,
        texture = visual.texture,
        arms = visual.arms,
        model = Bridge.getModelName(cache.ped),
    } or nil)
    busy = false

    if not result or not result.success then
        Bridge.notify(result and result.message or 'Could not take that off.', 'error')
        return false
    end

    setWorn(result.worn)

    if visual then
        -- Unmanaged slot: the sync does not touch it, so reset it to the
        -- default value ourselves.
        applySlot(slot)
    end

    Bridge.notify(('%s taken off, it is back in your bag.'):format(Config.Slots[slot].label), 'success')
    return true
end

--- Takes off everything the player is wearing: item based clothing AND
--- visible spawn clothing (which gets converted into items on the way out).
function Wardrobe.takeOffAll()
    local slots = {}
    local sorted = Config.SortedSlots()

    for i = 1, #sorted do
        local slot = sorted[i]
        if worn[slot] or Wardrobe.getVisualSlot(slot) then
            slots[#slots + 1] = slot
        end
    end

    if #slots == 0 then
        Bridge.notify('You are not wearing any clothing from this system.', 'inform')
        return
    end

    for i = 1, #slots do
        Wardrobe.takeOff(slots[i])
    end
end

-- ── ox_inventory: using an item ───────────────────────────────────────────

--- Digs the item table out of whatever ox_inventory hands over. The signature
--- has changed over the years, so this is deliberately tolerant.
local function resolveItemArgs(...)
    local args = { ... }

    for i = 1, #args do
        local value = args[i]
        if type(value) == 'table' and value.name then
            return value.name, value.slot
        end
    end

    for i = 1, #args do
        if type(args[i]) == 'string' then
            return args[i], type(args[i + 1]) == 'number' and args[i + 1] or nil
        end
    end

    return nil, nil
end

local lastUse = { name = nil, time = 0 }

---@return boolean
local function handleUse(...)
    local itemName, invSlot = resolveItemArgs(...)
    if not itemName then return false end
    if not Config.SlotByItem(itemName) then return false end

    -- Deduplicate: the export path and the event path can both fire.
    local now = GetGameTimer()
    if lastUse.name == itemName and now - lastUse.time < 500 then return false end
    lastUse.name, lastUse.time = itemName, now

    CreateThread(function()
        Wardrobe.wear(itemName, invSlot)
    end)

    return true
end

--- Called by ox_inventory via `client = { export = 'renzu_clothes.useClothing' }`.
exports('useClothing', function(...)
    return handleUse(...)
end)

if Config.Inventory.useItemFallback then
    -- Safety net for when the export is missing from data/items.lua.
    RegisterNetEvent('ox_inventory:usedItem', function(...)
        handleUse(...)
    end)
end

-- ── Death ─────────────────────────────────────────────────────────────────

--- Resets only the slots with an equipped item back to their default value.
--- Empty slots and everything else (hair, face, and anything a spawn or
--- appearance script owns) are left untouched.
local function resetManagedSlots()
    applying = true

    for slot, data in pairs(Config.Slots) do
        if worn[slot] and not Config.Death.keepSlots[slot] then
            local drawable, texture = Bridge.getDefaultPiece(cache.ped, data.component, data.isProp)
            Bridge.applyPiece(cache.ped, data.component, drawable, texture, data.isProp)

            if data.linkedArms then
                local aDraw, aTex = Bridge.getDefaultPiece(cache.ped, Config.ArmsComponent, false)
                SetPedComponentVariation(cache.ped, Config.ArmsComponent, aDraw, aTex, 0)
            end
        end
    end

    applying = false
end

local function onDeath()
    if not Config.Death.enabled then return end
    if Config.Death.onDeath == 'keep' then return end
    if wornCount == 0 then return end

    previewing = false

    if Config.Death.instantVisualReset then
        resetManagedSlots()
    end

    TriggerServerEvent('renzu_clothes:died')
end

CreateThread(function()
    if not Config.Death.enabled then return end

    while true do
        Wait(1000)

        local dead = IsPedDeadOrDying(cache.ped, true) or LocalPlayer.state.isDead == true

        if dead and not isDead then
            isDead = true
            onDeath()
        elseif not dead and isDead then
            isDead = false
            -- After respawn: put back whatever the player still owns.
            Wait(1500)
            Wardrobe.apply()
        end
    end
end)

-- ── Integrity watcher ─────────────────────────────────────────────────────
--
-- Appearance resources, job outfits and spawn scripts overwrite components
-- without asking. This loop notices that and puts equipped clothing back, so
-- your item based clothing does not silently disappear.

CreateThread(function()
    if not Config.Integrity.enabled then return end

    local enforceEmpty = Config.Integrity.enforceEmptySlots

    while true do
        Wait(Config.Integrity.interval)

        -- Nothing equipped and not enforcing empty slots means there is
        -- nothing to guard, so skip the work entirely.
        local shouldCheck = (wornCount > 0 or enforceEmpty)
            and not previewing
            and not applying
            and not busy
            and not isDead
            and Bridge.isPlayerLoaded()

        if shouldCheck then
            local ped = cache.ped

            for slot, data in pairs(Config.Slots) do
                local meta = worn[slot]

                if meta or enforceEmpty then
                    local expectDraw, expectTex

                    if meta then
                        expectDraw, expectTex = meta.drawable, meta.texture
                    else
                        expectDraw, expectTex = Bridge.getDefaultPiece(ped, data.component, data.isProp)
                    end

                    local drawable = data.isProp and GetPedPropIndex(ped, data.component)
                        or GetPedDrawableVariation(ped, data.component)
                    local texture = data.isProp and GetPedPropTextureIndex(ped, data.component)
                        or GetPedTextureVariation(ped, data.component)

                    if drawable ~= expectDraw or texture ~= expectTex then
                        applySlot(slot)
                    end
                end
            end
        end
    end
end)

-- ── Startup / model change ────────────────────────────────────────────────

lib.onCache('ped', function()
    Wait(500)
    if not previewing then
        Wardrobe.apply()
    end
end)

local booted = false

local function bootstrap()
    if booted then return end
    booted = true

    CreateThread(function()
        -- Give the appearance resource time to apply its skin first.
        Wait(2500)
        Wardrobe.refresh()
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', bootstrap)
RegisterNetEvent('qbx_core:client:playerLoaded', bootstrap)
RegisterNetEvent('esx:playerLoaded', bootstrap)

local function unbootstrap()
    booted = false
    worn = {}
    wornCount = 0
    lastApplied = {}
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', unbootstrap)
RegisterNetEvent('qbx_core:client:playerLoggedOut', unbootstrap)
RegisterNetEvent('esx:onPlayerLogout', unbootstrap)

-- Safety net: not every framework fires the same load event. Once the player
-- is loaded we fetch the clothing regardless.
CreateThread(function()
    while true do
        Wait(2000)
        if not booted and Bridge.isPlayerLoaded() then
            bootstrap()
        end
    end
end)

-- ── Exports for other resources ───────────────────────────────────────────

exports('getWorn', Wardrobe.getWorn)
exports('takeOff', Wardrobe.takeOff)
exports('takeOffAll', Wardrobe.takeOffAll)
exports('refresh', Wardrobe.refresh)
exports('setPreview', Wardrobe.setPreview)
exports('applyWorn', Wardrobe.apply)

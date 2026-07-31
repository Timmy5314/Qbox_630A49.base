---@diagnostic disable: undefined-global
--- The shop UI: camera, live preview on the ped and all NUI callbacks.
---
--- Shopping works like the original script: you pick things at the racks, the
--- cart follows you through the store, and you settle up at the register.
--- The cart and the preview survive closing the UI - they are only cleared
--- when you leave the store or after you have paid.

Shop = {}

local isOpen = false
local currentShop = nil
local allowedSlots = nil
local savedAppearance = nil

--- Cart and preview live here, not in the UI, so walking from the shirt rack
--- to the pants rack keeps everything.
local cart = {}
local previewed = {}

local cam = nil
local camAnchor = nil
local camBase = 0.0     -- orbit angle of the camera, fixed while the UI is open
local pedHeading = 0.0  -- current ped heading; dragging rotates this, not the cam
local baseHeading = 0.0 -- heading the ped had when the store opened
local camZone = 'full'
local camZoom = 0.0

local PAGE_SIZE = 60

--- Ped bones. Anchoring the camera on bones is the only reliable way to aim
--- at a body part: GetEntityCoords returns the middle of the ped, not the
--- feet, and the offset differs per model.
local BONE_HEAD  = 31086 -- SKEL_Head
local BONE_SPINE = 24818 -- SKEL_Spine3
local BONE_THIGH = 58271 -- SKEL_L_Thigh
local BONE_FOOT  = 65245 -- SKEL_L_Foot

local CAM_ZONES = {
    full  = { bone = nil,        dist = 2.30, fov = 42.0, offset = 0.05 },
    head  = { bone = BONE_HEAD,  dist = 0.80, fov = 30.0, offset = 0.02 },
    torso = { bone = BONE_SPINE, dist = 1.25, fov = 34.0, offset = 0.00 },
    legs  = { bone = BONE_THIGH, dist = 1.35, fov = 36.0, offset = -0.15 },
    feet  = { bone = BONE_FOOT,  dist = 0.85, fov = 32.0, offset = 0.10 },
}

-- ── Camera ────────────────────────────────────────────────────────────────

--- The point the camera looks at for the current zone.
---@return number x, number y, number z
local function focusPoint()
    local zone = CAM_ZONES[camZone] or CAM_ZONES.full

    if zone.bone then
        local bone = GetPedBoneCoords(cache.ped, zone.bone, 0.0, 0.0, 0.0)
        -- x/y from the frozen anchor so rotating the ped does not make the
        -- camera swing around; only the height comes from the bone.
        return camAnchor.x, camAnchor.y, bone.z + zone.offset
    end

    return camAnchor.x, camAnchor.y, camAnchor.z + zone.offset
end

local function updateCamera()
    if not cam or not camAnchor then return end

    local zone = CAM_ZONES[camZone] or CAM_ZONES.full
    local dist = math.max(0.45, zone.dist + camZoom)
    local rad = math.rad(camBase)

    local fx, fy, fz = focusPoint()

    -- The camera sits at a fixed spot in front of where the player stood when
    -- the store opened. Dragging rotates the PED, not the camera - that way
    -- you can actually look at the back of a jacket.
    SetCamCoord(cam, fx - math.sin(rad) * dist, fy + math.cos(rad) * dist, fz)
    PointCamAtCoord(cam, fx, fy, fz)
    SetCamFov(cam, zone.fov)
end

local function startCamera()
    camAnchor = GetEntityCoords(cache.ped)
    baseHeading = GetEntityHeading(cache.ped)
    pedHeading = baseHeading
    camBase = baseHeading
    camZone = 'full'
    camZoom = 0.0

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        camAnchor.x, camAnchor.y, camAnchor.z, 0.0, 0.0, 0.0, 42.0, false, 0)

    updateCamera()
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function stopCamera()
    RenderScriptCams(false, false, 0, true, true)

    if cam then
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
        -- Face the way you walked in again, not however far you spun around.
        SetEntityHeading(cache.ped, baseHeading)
    end

    camAnchor = nil
end

-- ── Preview ───────────────────────────────────────────────────────────────

---@param slot string
---@param drawable integer
---@param texture integer
---@param armsDrawable integer|nil
local function preview(slot, drawable, texture, armsDrawable)
    local data = Config.Slots[slot]
    if not data then return end

    Bridge.applyPiece(cache.ped, data.component, drawable, texture, data.isProp)

    -- A jacket owns the arms, otherwise the sleeves clip through the skin.
    if data.linkedArms and armsDrawable then
        SetPedComponentVariation(cache.ped, Config.ArmsComponent, armsDrawable, 0, 0)
    end

    previewed[slot] = { drawable = drawable, texture = texture, arms = armsDrawable }
end

--- Rolls one slot back to what the player actually owns and wears.
---@param slot string
local function revertSlot(slot)
    local data = Config.Slots[slot]
    if not data then return end

    previewed[slot] = nil

    local wornMeta = Wardrobe.getSlot(slot)

    if wornMeta then
        Bridge.applyPiece(cache.ped, data.component, wornMeta.drawable, wornMeta.texture, data.isProp)

        if data.linkedArms and wornMeta.arms then
            SetPedComponentVariation(cache.ped, Config.ArmsComponent, wornMeta.arms.drawable, wornMeta.arms.texture or 0, 0)
        end
    else
        local drawable, texture = Bridge.getDefaultPiece(cache.ped, data.component, data.isProp)
        Bridge.applyPiece(cache.ped, data.component, drawable, texture, data.isProp)

        if data.linkedArms then
            local aDraw, aTex = Bridge.getDefaultPiece(cache.ped, Config.ArmsComponent, false)
            SetPedComponentVariation(cache.ped, Config.ArmsComponent, aDraw, aTex, 0)
        end
    end
end

-- ── Data for the UI ───────────────────────────────────────────────────────

---@param slot string
---@return integer
local function countDrawables(slot)
    local data = Config.Slots[slot]

    if data.isProp then
        return GetNumberOfPedPropDrawableVariations(cache.ped, data.component)
    end

    return GetNumberOfPedDrawableVariations(cache.ped, data.component)
end

---@param slot string
---@param drawable integer
---@return integer
local function countTextures(slot, drawable)
    local data = Config.Slots[slot]

    if data.isProp then
        return GetNumberOfPedPropTextureVariations(cache.ped, data.component, drawable)
    end

    return GetNumberOfPedTextureVariations(cache.ped, data.component, drawable)
end

---@return table[]
local function buildCategories()
    local list = {}
    local sorted = Config.SortedSlots()

    for i = 1, #sorted do
        local slot = sorted[i]

        if not allowedSlots or allowedSlots[slot] then
            local data = Config.Slots[slot]
            local wornMeta = Wardrobe.getSlot(slot)
            local total = math.min(countDrawables(slot), Config.ShopSettings.maxDrawables)

            -- Categories with nothing to show would only be a dead end.
            if total > 0 then
                list[#list + 1] = {
                    key = slot,
                    label = data.label,
                    icon = data.icon,
                    camera = data.camera or 'full',
                    count = total,
                    arms = data.linkedArms and {
                        count = GetNumberOfPedDrawableVariations(cache.ped, Config.ArmsComponent),
                        current = GetPedDrawableVariation(cache.ped, Config.ArmsComponent),
                    } or nil,
                    worn = wornMeta and {
                        drawable = wornMeta.drawable,
                        texture = wornMeta.texture,
                    } or nil,
                }
            end
        end
    end

    return list
end

--- One page of garments. Paging keeps the payload small and the UI usable -
--- sending 400 items at once made the list unclickable.
---@param slot string
---@param page integer
---@return table
local function buildPage(slot, page)
    local data = Config.Slots[slot]
    if not data then return { total = 0, page = 1, pageSize = PAGE_SIZE, items = {} } end

    local total = math.min(countDrawables(slot), Config.ShopSettings.maxDrawables)
    local pages = math.max(1, math.ceil(total / PAGE_SIZE))

    page = math.floor(tonumber(page) or 1)
    if page < 1 then page = 1 end
    if page > pages then page = pages end

    local first = (page - 1) * PAGE_SIZE
    local last = math.min(first + PAGE_SIZE, total) - 1

    local items = {}

    for drawable = first, last do
        local textures = countTextures(slot, drawable)
        if textures < 1 then textures = 1 end

        local variants = {}
        for texture = 0, textures - 1 do
            variants[#variants + 1] = {
                texture = texture,
                price = Config.GetPrice(slot, drawable, texture),
            }
        end

        items[#items + 1] = {
            drawable = drawable,
            label = ('%s #%d'):format(data.label, drawable),
            variants = variants,
        }
    end

    return { total = total, pages = pages, page = page, pageSize = PAGE_SIZE, items = items }
end

-- ── Cart ──────────────────────────────────────────────────────────────────

---@return table[]
local function cartPayload()
    local list = {}

    for i = 1, #cart do
        local entry = cart[i]
        list[#list + 1] = {
            index = i,
            slot = entry.slot,
            slotLabel = Config.Slots[entry.slot].label,
            drawable = entry.drawable,
            texture = entry.texture,
            label = entry.label,
            price = Config.GetPrice(entry.slot, entry.drawable, entry.texture),
        }
    end

    return list
end

local function clearCart()
    cart = {}
end

-- ── Open / close ──────────────────────────────────────────────────────────

---@param shop table
---@param categories string[]|nil
---@param opts table|nil { view = 'cart' }
function Shop.open(shop, categories, opts)
    if isOpen then return end
    if not Bridge.isPlayerLoaded() then return end

    if shop.job then
        local job = Bridge.getJob()
        if job ~= shop.job then
            Bridge.notify(('This store is for %s only.'):format(shop.job), 'error')
            return
        end
    end

    -- Tijdelijk gesloten: de juwelier gebruikt dit tijdens de qbx_jewelery
    -- overval. De server weigert de aankoop sowieso; dit voorkomt alleen dat
    -- iemand midden in een overval rustig staat te winkelen.
    if shop.closedWhen and GlobalState[shop.closedWhen] then
        Bridge.notify('The store is closed right now.', 'error')
        return
    end

    allowedSlots = nil
    if categories then
        allowedSlots = {}
        for i = 1, #categories do allowedSlots[categories[i]] = true end
    end

    isOpen = true
    currentShop = shop

    -- Only snapshot the first time we enter the store, so trying things on at
    -- one rack is still undoable after visiting three others.
    if not savedAppearance then
        savedAppearance = Bridge.readPed(cache.ped)
    end

    Wardrobe.setPreview(true)

    SetEntityInvincible(cache.ped, true)
    FreezeEntityPosition(cache.ped, true)
    DisplayRadar(false)
    startCamera()

    local money = lib.callback.await('renzu_clothes:getMoney', false) or { cash = 0, bank = 0 }

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            shop = shop.name or 'Clothing Store',
            categories = buildCategories(),
            cart = cartPayload(),
            money = money,
            allowPaymentChoice = Config.AllowPaymentChoice,
            defaultAccount = Config.PaymentAccount,
            view = opts and opts.view or nil,
            atRegister = opts and opts.view == 'cart' or false,
        },
    })
end

--- Closes the UI but keeps the cart and everything you tried on, because you
--- are probably walking to the next rack.
function Shop.close()
    if not isOpen then return end
    isOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    stopCamera()
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)
    DisplayRadar(true)

    currentShop = nil
    allowedSlots = nil
end

--- Called when the player walks out of the store. This is where the cart and
--- the fitting-room preview are actually thrown away.
function Shop.leave()
    if isOpen then Shop.close() end

    clearCart()
    previewed = {}

    if savedAppearance then
        Bridge.applySnapshot(cache.ped, savedAppearance)
        savedAppearance = nil
    end

    Wardrobe.setPreview(false)
end

---@return boolean
function Shop.isOpen()
    return isOpen
end

--- Ends the fitting-room preview without touching the cart. Used when the
--- player uses a clothing item while still inside the store zone: the
--- preview would otherwise block dressing until they walk out.
---@return boolean
function Shop.stopPreview()
    if isOpen then return false end

    previewed = {}

    if savedAppearance then
        Bridge.applySnapshot(cache.ped, savedAppearance)
        savedAppearance = nil
    end

    -- Leaving preview re-applies the equipped clothing on top of the snapshot.
    Wardrobe.setPreview(false)
    return true
end

---@return integer
function Shop.cartCount()
    return #cart
end

-- ── NUI callbacks ─────────────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    Shop.close()
    cb(true)
end)

RegisterNUICallback('getItems', function(data, cb)
    cb(buildPage(data.slot, data.page or 1))
end)

RegisterNUICallback('preview', function(data, cb)
    preview(data.slot, data.drawable, data.texture or 0, data.arms)
    cb(true)
end)

RegisterNUICallback('previewState', function(data, cb)
    local slotData = Config.Slots[data.slot]
    if not slotData then cb({}) return end

    cb({
        drawable = slotData.isProp and GetPedPropIndex(cache.ped, slotData.component)
            or GetPedDrawableVariation(cache.ped, slotData.component),
        texture = slotData.isProp and GetPedPropTextureIndex(cache.ped, slotData.component)
            or GetPedTextureVariation(cache.ped, slotData.component),
        arms = slotData.linkedArms and GetPedDrawableVariation(cache.ped, Config.ArmsComponent) or nil,
    })
end)

RegisterNUICallback('revert', function(data, cb)
    revertSlot(data.slot)
    cb(true)
end)

RegisterNUICallback('addToCart', function(data, cb)
    local slot = data.slot

    if not slot or not Config.Slots[slot] then
        cb({ ok = false, message = 'Unknown category.' })
        return
    end

    for i = 1, #cart do
        if cart[i].slot == slot and cart[i].drawable == data.drawable and cart[i].texture == data.texture then
            cb({ ok = false, message = 'That piece is already in your cart.', cart = cartPayload() })
            return
        end
    end

    cart[#cart + 1] = {
        slot = slot,
        drawable = math.floor(tonumber(data.drawable) or 0),
        texture = math.floor(tonumber(data.texture) or 0),
        label = data.label,
        arms = previewed[slot] and previewed[slot].arms
            and { drawable = previewed[slot].arms, texture = 0 } or nil,
    }

    cb({ ok = true, cart = cartPayload() })
end)

RegisterNUICallback('removeFromCart', function(data, cb)
    local index = math.floor(tonumber(data.index) or 0)

    if cart[index] then
        table.remove(cart, index)
    end

    cb({ ok = true, cart = cartPayload() })
end)

RegisterNUICallback('camera', function(data, cb)
    camZone = CAM_ZONES[data.zone] and data.zone or 'full'
    camZoom = 0.0
    updateCamera()
    cb(true)
end)

RegisterNUICallback('rotate', function(data, cb)
    pedHeading = (pedHeading + (tonumber(data.delta) or 0.0)) % 360.0

    -- A frozen entity ignores SetEntityHeading, so lift the freeze for the
    -- single frame the heading is applied in.
    FreezeEntityPosition(cache.ped, false)
    SetEntityHeading(cache.ped, pedHeading)
    FreezeEntityPosition(cache.ped, true)

    cb(true)
end)

RegisterNUICallback('zoom', function(data, cb)
    -- Upper bound kept small on purpose: zooming out further than ~1m past
    -- the default puts the camera inside the shop walls.
    camZoom = math.max(-0.5, math.min(0.9, camZoom + (tonumber(data.delta) or 0.0)))
    updateCamera()
    cb(true)
end)

RegisterNUICallback('checkout', function(data, cb)
    if #cart == 0 then
        cb({ success = false, message = 'Your cart is empty.' })
        return
    end

    local model = Bridge.getModelName(cache.ped)
    local payload = {}

    for i = 1, #cart do
        payload[i] = {
            slot = cart[i].slot,
            drawable = cart[i].drawable,
            texture = cart[i].texture,
            label = cart[i].label,
            arms = cart[i].arms,
            model = model,
        }
    end

    local result = lib.callback.await('renzu_clothes:buy', false, {
        cart = payload,
        account = data.account or Config.PaymentAccount,
        shop = currentShop and currentShop.name or nil,
    })

    if result and result.success then
        clearCart()

        -- The purchase lands in the inventory, not on the body. Take the
        -- fitting-room preview off again so the ped shows what the player is
        -- actually wearing; the items are used from the inventory to equip.
        for slot in pairs(previewed) do
            revertSlot(slot)
        end
        previewed = {}

        local money = lib.callback.await('renzu_clothes:getMoney', false) or { cash = 0, bank = 0 }
        SendNUIMessage({ action = 'money', data = money })
        result.cart = cartPayload()
    end

    cb(result or { success = false, message = 'Purchase failed.' })
end)

RegisterNUICallback('wardrobe', function(_, cb)
    cb(true)
    Shop.close()
    Wait(400)
    Outfits.openMenu()
end)

-- Safety net: if the UI ever gets stuck, this gives your mouse back.
RegisterCommand('clothingfix', function()
    if isOpen then
        Shop.close()
    else
        SetNuiFocus(false, false)
        FreezeEntityPosition(cache.ped, false)
        DisplayRadar(true)
    end
end, false)

TriggerEvent('chat:addSuggestion', '/clothingfix', 'Force close the clothing store if the UI gets stuck')

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)
    stopCamera()
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)
    DisplayRadar(true)
end)

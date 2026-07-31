---@diagnostic disable: undefined-global
--- Checkout. Prices are recalculated here; the client only gets to display
--- them. That way nobody can tamper with the amounts.

local MAX_CART = 24

--- Hoe ver je van de kassa mag staan bij het afrekenen. Ruim genoeg voor de
--- ped en de toonbank ertussen, te krap om vanaf een rek af te rekenen.
local REGISTER_DISTANCE = 4.0

---@param shopName string?
---@return table?
local function findShop(shopName)
    if type(shopName) ~= 'string' then return end

    for i = 1, #Config.Shop do
        if Config.Shop[i].name == shopName then return Config.Shop[i] end
    end
end

--- Een winkel kan tijdelijk dicht zijn. De juwelier gebruikt dit tijdens de
--- qbx_jewelery overval (GlobalState.jewelryRobbery).
---@param shop table
---@return boolean
local function isClosed(shop)
    return shop.closedWhen ~= nil and GlobalState[shop.closedWhen] == true
end

--- Kleren uitzoeken mag overal in de winkel, betalen alleen bij de kassa.
--- Dit staat server-side omdat de NUI-knop uitschakelen niets tegenhoudt: de
--- client kan de callback gewoon rechtstreeks aanroepen.
---@param src number
---@param shop table
---@return boolean
local function atRegister(src, shop)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local register = shop.cashier or shop.coord
    if not register then return false end

    return #(GetEntityCoords(ped) - register) <= REGISTER_DISTANCE
end

lib.callback.register('renzu_clothes:getMoney', function(src)
    return Bridge.getMoney(src)
end)

lib.callback.register('renzu_clothes:buy', function(src, payload)
    local data = Wardrobe.getState(src)
    if not data then return { success = false, message = 'Player not found.' } end

    local cart = type(payload) == 'table' and payload.cart or nil
    if type(cart) ~= 'table' or #cart == 0 then
        return { success = false, message = 'Your cart is empty.' }
    end

    if #cart > MAX_CART then
        return { success = false, message = 'Too many items in your cart.' }
    end

    local shop = findShop(payload.shop)
    if not shop then
        return { success = false, message = 'Unknown store.' }
    end

    if isClosed(shop) then
        return { success = false, message = 'The store is closed right now.' }
    end

    if not atRegister(src, shop) then
        return { success = false, message = 'Take your cart to the register to pay.' }
    end

    local account = payload.account == 'cash' and 'cash' or 'bank'
    if not Config.AllowPaymentChoice then
        account = Config.PaymentAccount
    end

    -- 1. Validate and price everything.
    local total = 0
    local entries = {}

    for i = 1, #cart do
        local entry = cart[i]
        local slot = type(entry) == 'table' and entry.slot

        if type(slot) ~= 'string' or not Config.Slots[slot] then
            return { success = false, message = 'Unknown garment in your cart.' }
        end

        local metadata = Wardrobe.normalize(slot, {
            drawable = entry.drawable,
            texture = entry.texture,
            label = entry.label,
            arms = entry.arms,
            model = entry.model,
        })

        total = total + Config.GetPrice(slot, metadata.drawable, metadata.texture)
        entries[#entries + 1] = metadata
    end

    -- 2. Check inventory space.
    for i = 1, #entries do
        local slotData = Config.Slots[entries[i].slot]
        if not Inv.canCarry(src, slotData.item, 1, entries[i]) then
            return { success = false, message = 'Your bag is full, make some room first.' }
        end
    end

    -- 3. Pay.
    local money = Bridge.getMoney(src)
    if (money[account] or 0) < total then
        return {
            success = false,
            message = ('Not enough %s. You need $%d.'):format(account, total),
        }
    end

    if not Bridge.removeMoney(src, account, total, 'renzu_clothes-purchase') then
        return { success = false, message = 'Payment failed.' }
    end

    -- 4. Hand over the goods. Everything goes into the inventory as an item;
    --    the player puts it on by using the item (or via the radial menu).
    for i = 1, #entries do
        local metadata = entries[i]
        local slotData = Config.Slots[metadata.slot]

        if not Inv.addItem(src, slotData.item, 1, metadata) then
            -- canCarry said yes earlier, but the bag filled up meanwhile:
            -- drop it on the ground instead of losing a paid item.
            Wardrobe.returnToInventory(src, metadata)
        end
    end

    if Config.Debug then
        lib.print.info(('%s bought %d garments for $%d at %s')
            :format(GetPlayerName(src), #entries, total, payload.shop or 'unknown'))
    end

    return {
        success = true,
        total = total,
        message = ('Paid $%d — the clothing is in your inventory.'):format(total),
    }
end)

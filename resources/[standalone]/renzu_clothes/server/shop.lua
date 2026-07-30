---@diagnostic disable: undefined-global
--- Checkout. Prices are recalculated here; the client only gets to display
--- them. That way nobody can tamper with the amounts.

local MAX_CART = 24

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

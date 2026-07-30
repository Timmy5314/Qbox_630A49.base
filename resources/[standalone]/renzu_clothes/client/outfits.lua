---@diagnostic disable: undefined-global
--- Wardrobe: manage equipped pieces, save/load outfits and share them.

Outfits = {}

local function slotLabel(slot)
    return Config.Slots[slot] and Config.Slots[slot].label or slot
end

-- ── Equipped clothing ─────────────────────────────────────────────────────

function Outfits.openWorn()
    local worn = Wardrobe.getWorn()
    local options = {}
    local sorted = Config.SortedSlots()

    for i = 1, #sorted do
        local slot = sorted[i]
        local meta = worn[slot]

        if meta then
            options[#options + 1] = {
                title = meta.label or slotLabel(slot),
                description = ('%s - taking it off puts the item back in your bag'):format(slotLabel(slot)),
                icon = 'shirt',
                iconColor = '#8ab4ff',
                arrow = true,
                onSelect = function()
                    Wardrobe.takeOff(slot)
                end,
            }
        end
    end

    if #options == 0 then
        options[#options + 1] = {
            title = 'You are not wearing anything from this system',
            description = 'Use a clothing item in your inventory to put it on.',
            icon = 'circle-info',
            readOnly = true,
        }
    else
        options[#options + 1] = {
            title = 'Take everything off',
            description = 'Put every equipped garment back in your bag',
            icon = 'user-slash',
            iconColor = '#ff8a8a',
            onSelect = function()
                Wardrobe.takeOffAll()
            end,
        }
    end

    lib.registerContext({
        id = 'renzu_clothes_worn',
        title = 'Currently wearing',
        menu = 'renzu_clothes_main',
        options = options,
    })

    lib.showContext('renzu_clothes_worn')
end

-- ── Outfits ───────────────────────────────────────────────────────────────

---@param outfits table<string, table>
---@param name string
local function outfitOptions(outfits, name)
    local outfit = outfits[name]
    local pieces = {}

    for slot, meta in pairs(outfit or {}) do
        pieces[#pieces + 1] = ('%s: %s'):format(slotLabel(slot), meta.label or '?')
    end

    table.sort(pieces)

    lib.registerContext({
        id = 'renzu_clothes_outfit',
        title = name,
        menu = 'renzu_clothes_outfits',
        options = {
            {
                title = 'Wear',
                description = #pieces > 0 and table.concat(pieces, '  \n') or 'Empty outfit',
                icon = 'user-check',
                iconColor = '#7ee787',
                onSelect = function()
                    local result = lib.callback.await('renzu_clothes:wearOutfit', false, name)

                    if not result or not result.success then
                        Bridge.notify(result and result.message or 'Could not wear that outfit.', 'error')
                        return
                    end

                    TriggerEvent('renzu_clothes:sync', result.worn)

                    if result.missing and #result.missing > 0 then
                        local labels = {}
                        for i = 1, #result.missing do
                            labels[#labels + 1] = slotLabel(result.missing[i])
                        end
                        Bridge.notify(('Outfit on. Still missing: %s'):format(table.concat(labels, ', ')), 'warning')
                    else
                        Bridge.notify(('Outfit "%s" equipped.'):format(name), 'success')
                    end
                end,
            },
            {
                title = 'Create share code',
                description = 'Generate a code someone else can save',
                icon = 'qrcode',
                onSelect = function()
                    local code = lib.callback.await('renzu_clothes:generateCode', false, name)

                    if not code then
                        Bridge.notify('Could not create a code.', 'error')
                        return
                    end

                    lib.setClipboard(code)
                    lib.alertDialog({
                        header = 'Outfit code',
                        content = ('Your code is:  \n# %s  \nIt has been copied to your clipboard and is valid for %d minutes.')
                            :format(code, Config.OutfitCodeMinutes),
                        centered = true,
                    })
                end,
            },
            {
                title = 'Delete',
                description = 'Remove this outfit from your wardrobe',
                icon = 'trash',
                iconColor = '#ff8a8a',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Delete outfit',
                        content = ('Are you sure you want to delete "%s"?'):format(name),
                        centered = true,
                        cancel = true,
                    })

                    if confirm ~= 'confirm' then return end

                    local ok = lib.callback.await('renzu_clothes:deleteOutfit', false, name)
                    Bridge.notify(ok and 'Outfit deleted.' or 'Could not delete it.', ok and 'success' or 'error')
                    Outfits.openOutfits()
                end,
            },
        },
    })

    lib.showContext('renzu_clothes_outfit')
end

function Outfits.openOutfits()
    local outfits = lib.callback.await('renzu_clothes:getOutfits', false) or {}
    local options = {}
    local names = {}

    for name in pairs(outfits) do names[#names + 1] = name end
    table.sort(names)

    for i = 1, #names do
        local name = names[i]
        local count = 0
        for _ in pairs(outfits[name]) do count = count + 1 end

        options[#options + 1] = {
            title = name,
            description = ('%d garment%s'):format(count, count == 1 and '' or 's'),
            icon = 'shirt',
            arrow = true,
            onSelect = function() outfitOptions(outfits, name) end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = 'No outfits yet',
            description = 'Save what you are wearing to get started.',
            icon = 'circle-info',
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'renzu_clothes_outfits',
        title = 'My outfits',
        menu = 'renzu_clothes_main',
        options = options,
    })

    lib.showContext('renzu_clothes_outfits')
end

-- ── Main menu ─────────────────────────────────────────────────────────────

function Outfits.openMenu()
    local worn = Wardrobe.getWorn()
    local count = 0
    for _ in pairs(worn) do count = count + 1 end

    lib.registerContext({
        id = 'renzu_clothes_main',
        title = 'Wardrobe',
        options = {
            {
                title = 'Currently wearing',
                description = ('%d garment%s equipped'):format(count, count == 1 and '' or 's'),
                icon = 'user',
                arrow = true,
                onSelect = Outfits.openWorn,
            },
            {
                title = 'My outfits',
                description = 'Wear or manage saved combinations',
                icon = 'list',
                arrow = true,
                onSelect = Outfits.openOutfits,
            },
            {
                title = 'Save current outfit',
                description = 'Store what you are wearing under a name',
                icon = 'floppy-disk',
                onSelect = function()
                    if count == 0 then
                        Bridge.notify('You are not wearing anything to save.', 'error')
                        return
                    end

                    local input = lib.inputDialog('Save outfit', {
                        {
                            type = 'input',
                            label = 'Name',
                            description = 'What do you want to call this outfit?',
                            required = true,
                            min = 1,
                            max = 32,
                        },
                    })

                    if not input or not input[1] then return end

                    local result = lib.callback.await('renzu_clothes:saveOutfit', false, input[1])

                    Bridge.notify(
                        result and result.success and ('Outfit "%s" saved.'):format(input[1])
                            or (result and result.message or 'Could not save it.'),
                        result and result.success and 'success' or 'error'
                    )
                end,
            },
            {
                title = 'Redeem outfit code',
                description = 'Add a shared outfit to your wardrobe',
                icon = 'code',
                onSelect = function()
                    local input = lib.inputDialog('Outfit code', {
                        { type = 'input', label = 'Code', required = true, min = 4, max = 16 },
                        { type = 'input', label = 'Name in your wardrobe', required = true, min = 1, max = 32 },
                    })

                    if not input then return end

                    local result = lib.callback.await('renzu_clothes:redeemCode', false, {
                        code = input[1],
                        name = input[2],
                    })

                    Bridge.notify(
                        result and result.success and 'Outfit added to your wardrobe.'
                            or (result and result.message or 'That code does not exist anymore.'),
                        result and result.success and 'success' or 'error'
                    )
                end,
            },
        },
    })

    lib.showContext('renzu_clothes_main')
end

-- ── Commands ──────────────────────────────────────────────────────────────

RegisterCommand('clothing', function()
    if Shop.isOpen() then return end
    Outfits.openMenu()
end, false)

RegisterCommand('undress', function()
    if Shop.isOpen() then return end
    Wardrobe.takeOffAll()
end, false)

TriggerEvent('chat:addSuggestion', '/clothing', 'Open your wardrobe and outfits')
TriggerEvent('chat:addSuggestion', '/undress', 'Take off all equipped clothing')

exports('openWardrobe', Outfits.openMenu)
exports('openWornMenu', Outfits.openWorn)

---@diagnostic disable: undefined-global
--- Radial menu integration (ox_lib radial, the one qbx_core uses).
--- The submenu is rebuilt whenever you put something on or take it off, so it
--- always lists exactly the pieces you are wearing right now.

if not Config.Radial or not Config.Radial.enabled then return end

local RADIAL_ID = 'renzu_clothes'
local SUBMENU_ID = 'renzu_clothes_radial'

local RADIAL_ICONS = {
    mask = 'mask-face',
    jacket = 'shirt',
    shirt = 'shirt',
    vest = 'shield-halved',
    decals = 'stamp',
    pants = 'person',
    shoes = 'shoe-prints',
    bag = 'bag-shopping',
    chain = 'link',
    hat = 'hat-cowboy',
    glasses = 'glasses',
    ears = 'gem',
    watch = 'clock',
    bracelet = 'ring',
}

local registered = false

local function buildRadial()
    local worn = Wardrobe.getWorn()
    local items = {}
    local sorted = Config.SortedSlots()

    for i = 1, #sorted do
        local slot = sorted[i]

        -- Item based clothing AND visible spawn clothing (the latter gets
        -- converted into an inventory item when taken off).
        if worn[slot] or Wardrobe.getVisualSlot(slot) then
            items[#items + 1] = {
                label = Config.Slots[slot].label,
                icon = RADIAL_ICONS[slot] or 'shirt',
                onSelect = function()
                    Wardrobe.takeOff(slot)
                end,
            }
        end
    end

    items[#items + 1] = {
        label = 'Wardrobe',
        icon = 'box-archive',
        onSelect = function()
            Outfits.openMenu()
        end,
    }

    if #items > 1 then
        items[#items + 1] = {
            label = 'Take all off',
            icon = 'user-slash',
            onSelect = function()
                Wardrobe.takeOffAll()
            end,
        }
    end

    lib.registerRadial({
        id = SUBMENU_ID,
        items = items,
    })

    if not registered then
        registered = true
        lib.addRadialItem({
            id = RADIAL_ID,
            label = 'Clothing',
            icon = 'shirt',
            menu = SUBMENU_ID,
        })
    end
end

AddEventHandler('renzu_clothes:wornChanged', buildRadial)

-- Spawn clothing is applied by the appearance script whenever it pleases, so
-- there is no event to hook into. Poll the visible slots and rebuild the
-- submenu only when the picture actually changed.
CreateThread(function()
    Wait(1500)
    buildRadial()

    local lastSignature = nil

    while true do
        Wait(3000)

        local sorted = Config.SortedSlots()
        local worn = Wardrobe.getWorn()
        local sig = {}

        for i = 1, #sorted do
            local slot = sorted[i]
            if worn[slot] or Wardrobe.getVisualSlot(slot) then
                sig[#sig + 1] = slot
            end
        end

        sig = table.concat(sig, ',')

        if sig ~= lastSignature then
            lastSignature = sig
            buildRadial()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if registered then
        pcall(lib.removeRadialItem, RADIAL_ID)
    end
end)

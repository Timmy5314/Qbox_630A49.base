---@diagnostic disable: undefined-global
Config = {}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  GENERAL                                                             ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Debug = false

--- Account used to pay for clothing. 'cash' | 'bank'
Config.PaymentAccount = 'bank'

--- Let the player choose between cash and bank at checkout.
Config.AllowPaymentChoice = true

--- Maximum saved outfits per character.
Config.MaxOutfits = 30

--- How long (in minutes) a shared outfit code stays valid.
Config.OutfitCodeMinutes = 60

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  CLOTHING SLOTS                                                      ║
-- ╠══════════════════════════════════════════════════════════════════════╣
-- ║  Every slot maps to one ox_inventory item. Which shirt exactly it is ║
-- ║  lives in the item metadata, so you need 14 item definitions instead ║
-- ║  of thousands.                                                       ║
-- ║                                                                      ║
-- ║  component  = GTA component / prop id                                ║
-- ║  isProp     = true for props (hat, glasses, ears, watch, bracelet)   ║
-- ║  item       = ox_inventory item name                                 ║
-- ║  price      = base price (see Config.Pricing for the spread)         ║
-- ║  camera     = which camera angle the shop UI uses for this slot      ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Slots = {
    mask = {
        order = 1, label = 'Mask', icon = 'mask',
        component = 1, isProp = false,
        item = 'clothing_mask', price = 250, camera = 'head',
    },
    jacket = {
        order = 2, label = 'Jacket / Top', icon = 'shirt',
        component = 11, isProp = false,
        item = 'clothing_jacket', price = 650, camera = 'torso',
        -- Component 11 is tied to the arms (component 3). The arms are stored
        -- in the item metadata so the sleeves always match the jacket.
        linkedArms = true,
    },
    shirt = {
        order = 3, label = 'Shirt / Undershirt', icon = 'shirt',
        component = 8, isProp = false,
        item = 'clothing_shirt', price = 220, camera = 'torso',
    },
    vest = {
        order = 4, label = 'Vest / Body Armor', icon = 'shield',
        component = 9, isProp = false,
        item = 'clothing_vest', price = 900, camera = 'torso',
    },
    decals = {
        order = 5, label = 'Decals', icon = 'sparkles',
        component = 10, isProp = false,
        item = 'clothing_decals', price = 150, camera = 'torso',
    },
    pants = {
        order = 6, label = 'Pants', icon = 'pants',
        component = 4, isProp = false,
        item = 'clothing_pants', price = 480, camera = 'legs',
    },
    shoes = {
        order = 7, label = 'Shoes', icon = 'shoe',
        component = 6, isProp = false,
        item = 'clothing_shoes', price = 380, camera = 'feet',
    },
    bag = {
        order = 8, label = 'Bag / Backpack', icon = 'bag',
        component = 5, isProp = false,
        item = 'clothing_bag', price = 300, camera = 'torso',
    },
    chain = {
        order = 9, label = 'Chain', icon = 'chain',
        component = 7, isProp = false,
        item = 'clothing_chain', price = 550, camera = 'torso',
    },
    hat = {
        order = 10, label = 'Hat / Helmet', icon = 'hat',
        component = 0, isProp = true,
        item = 'clothing_hat', price = 320, camera = 'head',
    },
    glasses = {
        order = 11, label = 'Glasses', icon = 'glasses',
        component = 1, isProp = true,
        item = 'clothing_glasses', price = 200, camera = 'head',
    },
    ears = {
        order = 12, label = 'Earrings', icon = 'gem',
        component = 2, isProp = true,
        item = 'clothing_ears', price = 260, camera = 'head',
    },
    watch = {
        order = 13, label = 'Watch', icon = 'watch',
        component = 6, isProp = true,
        item = 'clothing_watch', price = 800, camera = 'torso',
    },
    bracelet = {
        order = 14, label = 'Bracelet', icon = 'bracelet',
        component = 7, isProp = true,
        item = 'clothing_bracelet', price = 420, camera = 'torso',
    },
}

--- Component id of the arms. Controlled by the `jacket` slot.
Config.ArmsComponent = 3

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  PRICING                                                             ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Pricing = {
    --- Deterministic spread around the base price (0.35 = +/- 35%).
    --- Deterministic means the same pair of pants always costs the same, and
    --- the server can recalculate the price independently (no exploits).
    variance = 0.35,
    minimum = 25,
}

--- Calculates the price of a single garment. Shared so client and server
--- always agree on the number.
---@param slot string
---@param drawable integer
---@param texture integer
---@return integer
function Config.GetPrice(slot, drawable, texture)
    local data = Config.Slots[slot]
    if not data then return Config.Pricing.minimum end

    -- Simple stable hash. Deliberately not math.random: that is not
    -- reproducible between client and server.
    local seed = (data.component + 1) * 7919 + (drawable + 1) * 104729 + (texture + 1) * 1299709
    local hash = (seed * 2654435761) % 4294967296
    local ratio = (hash % 1000) / 1000.0 -- 0.000 .. 0.999

    local factor = 1.0 + ((ratio * 2.0) - 1.0) * Config.Pricing.variance
    local price = math.floor(data.price * factor + 0.5)

    return price < Config.Pricing.minimum and Config.Pricing.minimum or price
end

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  DEFAULT CLOTHING                                                    ║
-- ╠══════════════════════════════════════════════════════════════════════╣
-- ║  Used when a slot is empty: no jacket equipped means these values.   ║
-- ║  Also what the player falls back to on death.                        ║
-- ║  Props with drawable -1 mean "nothing equipped".                     ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.DefaultOutfit = {
    ['mp_m_freemode_01'] = {
        components = {
            [1]  = { drawable = 0,  texture = 0 }, -- mask
            [3]  = { drawable = 15, texture = 0 }, -- arms
            [4]  = { drawable = 21, texture = 0 }, -- pants
            [5]  = { drawable = 0,  texture = 0 }, -- bag
            [6]  = { drawable = 34, texture = 0 }, -- shoes
            [7]  = { drawable = 0,  texture = 0 }, -- chain
            [8]  = { drawable = 15, texture = 0 }, -- undershirt
            [9]  = { drawable = 0,  texture = 0 }, -- vest
            [10] = { drawable = 0,  texture = 0 }, -- decals
            [11] = { drawable = 15, texture = 0 }, -- jacket / torso
        },
        props = {
            [0] = { drawable = -1, texture = 0 },
            [1] = { drawable = -1, texture = 0 },
            [2] = { drawable = -1, texture = 0 },
            [6] = { drawable = -1, texture = 0 },
            [7] = { drawable = -1, texture = 0 },
        },
    },
    ['mp_f_freemode_01'] = {
        components = {
            [1]  = { drawable = 0,  texture = 0 },
            [3]  = { drawable = 15, texture = 0 },
            [4]  = { drawable = 15, texture = 0 },
            [5]  = { drawable = 0,  texture = 0 },
            [6]  = { drawable = 35, texture = 0 },
            [7]  = { drawable = 0,  texture = 0 },
            [8]  = { drawable = 14, texture = 0 },
            [9]  = { drawable = 0,  texture = 0 },
            [10] = { drawable = 0,  texture = 0 },
            [11] = { drawable = 15, texture = 0 },
        },
        props = {
            [0] = { drawable = -1, texture = 0 },
            [1] = { drawable = -1, texture = 0 },
            [2] = { drawable = -1, texture = 0 },
            [6] = { drawable = -1, texture = 0 },
            [7] = { drawable = -1, texture = 0 },
        },
    },
}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  DEATH                                                               ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Death = {
    --- Take equipped clothing off when the player dies.
    enabled = true,

    --- What happens to the equipped garments on death:
    ---   'return' -> back into the inventory (player can put them on again)
    ---   'drop'   -> dropped on the ground where the player went down (lootable)
    ---   'delete' -> gone for good
    ---   'keep'   -> stays equipped, nothing happens
    onDeath = 'return',

    --- Slots that never come off on death (e.g. your backpack).
    keepSlots = { bag = true },

    --- Reset the affected slots to Config.DefaultOutfit right away on the
    --- client, instead of waiting for the server round trip.
    ---
    --- Only the slots this resource manages are touched. Hair, face and
    --- anything another script controls are left alone, so a separate
    --- spawn/appearance script keeps working next to this one.
    instantVisualReset = true,
}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  INTEGRITY                                                           ║
-- ╠══════════════════════════════════════════════════════════════════════╣
-- ║  Other resources (appearance scripts, job outfits, ...) happily      ║
-- ║  overwrite your components. This watcher puts equipped clothing back.║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Integrity = {
    enabled = true,
    interval = 2000,
    --- Also force empty slots back to their default value? Leave this off if
    --- another script hands out job outfits or spawn clothing - with it off,
    --- this resource only guards the slots you actually have equipped.
    enforceEmptySlots = true,
}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  SHOPS                                                               ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Shop = Config.Shop or {}

Config.ShopSettings = {
    --- Radius in which a shop's interaction points get created.
    zoneRadius = 40.0,
    --- Distance at which [E] works.
    interactDistance = 2.2,
    --- ox_target: size of the interaction box around racks/register/wardrobe
    --- and the distance from which you can use it.
    targetSize = vec3(2.4, 2.4, 3.0),
    targetDistance = 3.0,
    --- Marker drawn under every rack / point.
    marker = { type = 2, scale = 0.35, r = 235, g = 235, b = 245, a = 180 },
    --- Shop clerk ped near the register. The clerk has an ox_target option
    --- (open register / shop) and turns to face you within `faceDistance`.
    ped = { model = 's_f_y_shop_mid', spawn = true, faceDistance = 3.0 },
    --- Show map blips.
    blips = true,
    blipScale = 0.75,
    --- Max drawables the UI loads per category (keeps the menu snappy).
    maxDrawables = 400,
}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  RADIAL MENU                                                         ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Radial = {
    --- Adds a "Clothing" entry to the ox_lib radial menu (the one qbx uses).
    --- It lists exactly what you are wearing so you can take pieces off.
    enabled = true,
}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  ITEMS / INVENTORY                                                   ║
-- ╚══════════════════════════════════════════════════════════════════════╝

Config.Inventory = {
    --- Safety net: also react to `ox_inventory:usedItem` in case you forgot
    --- the `client.export` in ox_inventory/data/items.lua.
    useItemFallback = true,
    --- Allow changing clothes inside a vehicle?
    allowInVehicle = false,
    --- Length of the dressing animation in ms (0 = no animation).
    animationTime = 1200,
}

--- Looks up a slot by item name.
---@param itemName string
---@return string|nil
function Config.SlotByItem(itemName)
    for slot, data in pairs(Config.Slots) do
        if data.item == itemName then return slot end
    end
    return nil
end

local sortedSlots

--- Slots sorted by `order`, handy for menus and the UI. Cached, since this
--- gets called on every radial rebuild.
---@return string[]
function Config.SortedSlots()
    if sortedSlots then return sortedSlots end

    local list = {}
    for slot in pairs(Config.Slots) do list[#list + 1] = slot end
    table.sort(list, function(a, b)
        return (Config.Slots[a].order or 99) < (Config.Slots[b].order or 99)
    end)

    sortedSlots = list
    return list
end

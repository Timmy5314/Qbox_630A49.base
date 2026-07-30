--[[
    renzu_clothes — items for ox_inventory

    Paste the lines below into `ox_inventory/data/items.lua`, anywhere inside
    the big `return { ... }` table.

    Two lines are essential, do not remove them:

      client = { export = 'renzu_clothes.useClothing' }
          makes "Use" put the garment on.

      consume = 0
          stops ox_inventory from eating the item itself. renzu_clothes takes
          the item out of the inventory once it is equipped, and puts it back
          when you take it off. Without this line you lose the garment.

    Images (optional) go in `ox_inventory/web/images/` with exactly these
    filenames: clothing_mask.png, clothing_jacket.png, and so on. A missing
    image only means no picture, the item still works.
]]

['clothing_mask'] = {
    label = 'Mask',
    weight = 120,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_jacket'] = {
    label = 'Jacket',
    weight = 900,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_shirt'] = {
    label = 'Shirt',
    weight = 250,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_vest'] = {
    label = 'Vest',
    weight = 1800,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_decals'] = {
    label = 'Decals',
    weight = 50,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_pants'] = {
    label = 'Pants',
    weight = 600,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_shoes'] = {
    label = 'Shoes',
    weight = 800,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_bag'] = {
    label = 'Bag',
    weight = 500,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_chain'] = {
    label = 'Chain',
    weight = 150,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_hat'] = {
    label = 'Hat',
    weight = 200,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_glasses'] = {
    label = 'Glasses',
    weight = 80,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_ears'] = {
    label = 'Earrings',
    weight = 40,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_watch'] = {
    label = 'Watch',
    weight = 120,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

['clothing_bracelet'] = {
    label = 'Bracelet',
    weight = 90,
    stack = false,
    consume = 0,
    close = true,
    description = 'Use it or pick it from the radial menu to put it on.',
    client = { export = 'renzu_clothes.useClothing' },
},

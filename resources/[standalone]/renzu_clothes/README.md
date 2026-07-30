# renzu_clothes v2

Clothing store, wardrobe and outfit system for **QBox (qbx_core)** — with
clothing as real inventory items.

The old ESX version has been fully rewritten. What is new:

- **Clothing is an item.** Buy a shirt and it lands in your `ox_inventory`.
- **Wearing takes the item out of your bag**, taking it off puts it back. So
  clothing can be given away, dropped, traded and lost.
- **Take pieces off from the radial menu** (the ox_lib radial qbx uses), via
  `/clothing`, or from the wardrobe in a store.
- **On death** you fall back to the default outfit and your garments go back
  into your bag (or on the ground — configurable).
- **New UI**: own HTML/CSS/JS, no jQuery, no CDNs, no webfonts.
- **Storage** in a single table through `oxmysql`, holding both the equipped
  clothing and the outfits.
- No `renzu_shield`, no `mysql-async`, no escrow.

---

## 1. Requirements

| Resource | Required? | Used for |
|---|---|---|
| `ox_lib` | ✅ yes | menus, points, zones, callbacks |
| `oxmysql` | ✅ yes | storage |
| `ox_inventory` | ✅ yes | the clothing items |
| `qbx_core` | recommended | money and identity (qb-core and ESX work too) |
| `ox_target` | optional | used automatically when running, otherwise `[E]` |

An appearance resource (`illenium-appearance`, `fivem-appearance`, …) is
**not** needed. This resource drives the clothing components through natives;
your appearance resource stays responsible for face, hair and model.

---

## 2. Installation

### Step 1 — Add the resource

Drop the folder in your `resources` and add it to `server.cfg`, **after**
ox_lib, oxmysql, ox_inventory and qbx_core:

```
ensure renzu_clothes
```

### Step 2 — Add the items to ox_inventory

Open `ox_inventory/data/items.lua` and paste in the contents of
[`install/ox_inventory_items.lua`](install/ox_inventory_items.lua).

Two lines per item matter:

```lua
consume = 0,                                        -- ox_inventory must NOT eat the item
client  = { export = 'renzu_clothes.useClothing' }, -- "Use" puts it on
```

`consume = 0` is not a detail: leave it out and ox_inventory removes the item
before this resource can equip it, and the garment is gone.

Images (optional) go in `ox_inventory/web/images/` as `clothing_shirt.png`,
`clothing_pants.png`, and so on.

### Step 3 — Database

The table is created automatically on start. To do it by hand, run
[`install/renzu_clothes.sql`](install/renzu_clothes.sql).

That is it. Restart and you have clothing stores at 14 locations.

---

## 3. How it works

### Buying

Same flow as the original script: collect things at the racks, then settle up
at the register.

Walk up to a rack and press `[E]` (or use ox_target). The UI opens:

- **Left** the categories, with a green dot on whatever you already wear.
- **Middle** your character. Drag to rotate, scroll to zoom.
- **Right** a grid of garments, 60 per page. Type a number in the search box
  to jump straight to it. Picking one shows its colors and the buy button in
  a bar pinned to the bottom.
- **Bottom** camera buttons: full, head, torso, legs, feet.

Closing the UI does **not** empty your cart. Walk to the next rack, pick more,
and the cart follows you. What you tried on stays on your character while you
walk around the store. Both are only cleared when you leave the store or after
you have paid.

Interacting with the **register** opens the cart directly so you can pay for
everything at once. You can also check out from the cart button in any rack
menu if you prefer.

Prices are recalculated on the server, so the client cannot tamper with them.

### Putting clothes on and taking them off

| Action | What happens |
|---|---|
| **Use** the item in ox_inventory | Item leaves your bag and goes on your body |
| **Radial menu → Clothing → \<piece\>** | Piece comes off and returns to your bag |
| `/clothing` | Wardrobe menu: what you wear, outfits, saving, codes |
| `/undress` | Everything off at once |

Because equipped clothing is not in your inventory, you cannot accidentally
give away the shirt you are wearing — take it off first, then hand it over.

### Outfits

From the wardrobe (the point in a store, or `/clothing`):

- **Save current outfit** under a name
- **Wear an outfit** — pulls the matching items out of your bag. If a piece is
  missing you are told which one.
- **Create a share code** — 6 characters, valid for 60 minutes by default.
  Whoever redeems it gets the outfit in their wardrobe, but still has to own
  the actual garments to wear it.

### Death

Go down and you are instantly back in the default outfit. What happens to the
pieces is set in `config/shared.lua`:

```lua
Config.Death = {
    enabled   = true,
    onDeath   = 'return',       -- 'return' | 'drop' | 'delete' | 'keep'
    keepSlots = { bag = true },  -- these slots never come off
    instantVisualReset = true,
}
```

- `return` — back in your bag, you have to get dressed again *(default)*
- `drop` — dropped where you went down, lootable by others
- `delete` — gone for good
- `keep` — stays equipped, nothing happens

**Playing nicely with a spawn/appearance script:** the death reset only
touches the slots this resource manages. Hair, face and anything another
script owns are left alone. `Config.Integrity.enforceEmptySlots` is `false` by
default for the same reason — empty slots are not policed, so a separate
script handing out spawn clothing or job outfits keeps working.

---

## 4. Configuration

Everything lives in **`config/shared.lua`**:

| Setting | Meaning |
|---|---|
| `Config.Slots` | the 14 slots: component id, item, base price, icon |
| `Config.Pricing` | price spread (deterministic, so the server can verify it) |
| `Config.DefaultOutfit` | how you look with an empty slot, per gender |
| `Config.Death` | see above |
| `Config.Integrity` | restores equipped clothing when another script overwrites it |
| `Config.ShopSettings` | markers, clerk ped, blips, zone radius |
| `Config.Inventory` | animation length, changing in a vehicle, use fallback |
| `Config.Radial` | radial menu on/off |

**`config/shops.lua`** holds the 14 stores with their racks, register and
wardrobe — every coordinate from the original version was kept.

Adding a store:

```lua
{
    name  = 'My Clothing Store',
    coord = vector3(0.0, 0.0, 70.0),
    blip  = { sprite = 73, color = 1 },
    cashier  = vector3(2.0, 0.0, 70.0),
    ped      = vector3(3.0, 0.0, 70.0),
    wardrobe = vector3(5.0, 0.0, 70.0),
    racks = {
        { coord = vector3(1.0, 1.0, 70.0), label = 'Shirts', categories = { 'shirt' } },
    },
},
```

Leave out `racks` and you get one point with every category. Use
`categories = { 'vest' }` at store level to make an armor shop.

---

## 5. Exports

**Client**

```lua
exports.renzu_clothes:getWorn()            -- table: slot -> metadata
exports.renzu_clothes:takeOff('shirt')     -- take one piece off
exports.renzu_clothes:takeOffAll()
exports.renzu_clothes:refresh()            -- pull from the server again
exports.renzu_clothes:openWardrobe()       -- open the wardrobe menu
exports.renzu_clothes:setPreview(true)     -- pause the watcher (own changing room)
```

**Server**

```lua
exports.renzu_clothes:getWorn(src)
exports.renzu_clothes:giveClothing(src, 'jacket', 12, 3, 'Police Jacket')
exports.renzu_clothes:stripPlayer(src)     -- everything off, back in the bag
```

`giveClothing` is handy for job issue: hand an officer their uniform as an
item so they can put it on and take it off themselves.

**Event**

```lua
AddEventHandler('renzu_clothes:wornChanged', function(worn) end) -- client
```

---

## 6. Troubleshooting

**"Use" does nothing in ox_inventory**
The `client = { export = 'renzu_clothes.useClothing' }` line is missing from
`ox_inventory/data/items.lua`. There is a fallback
(`Config.Inventory.useItemFallback`), but the export is the proper way.

**The item disappears when I use it**
`consume = 0` is missing from the item definition. See step 2.

**My clothing vanishes a few seconds after equipping**
Another script is overwriting the components. The `Config.Integrity` watcher
puts it back; turn it on if you disabled it. If you run a second clothing
script on the same slots, disable that one.

**My old clothing is gone**
Correct — v2 works with items instead of a stored skin JSON. Existing players
start in the default outfit. To compensate them, use
`exports.renzu_clothes:giveClothing`.

**The UI is stuck**
`/clothingfix` gives your mouse and camera back.

---

## 7. Old version

The complete v1 code sits in [`legacy/`](legacy/) and is **not** loaded (it is
not in `fxmanifest.lua`). Handy for reference; feel free to delete the folder.

---

Originally by **Renzuzu**. v2 rewrite for qbx_core, ox_lib and ox_inventory.

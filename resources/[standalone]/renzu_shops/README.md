# renzu_shops
Fivem Advanced Shops with stocks and player owned shops, built for **QBox (qbx_core)**, **ox_inventory** and **ox_target**.

![image](https://forum.cfx.re/uploads/default/original/4X/c/8/9/c89e89ca9b9ffdc2fb4867a7346f1c4810c84092.gif)

# Features
- Support All types of Shops
- Categorized Shop
- Player Owned Shops
- Shop Management - Stock management, employee management, finance management, item data mangement, item orders manage.
- Shop Owner can Order Bulk items from Suppliers with preconfigured discounts.
- Shop Owner can Deposit or Withdraw items from Store Inventory.
- Support Multiple Currency. money , black_money or your custom item.
- Support Preconfigured Item Metadas type. ( eg. sell burger, Cheese Burger, Double Bart Burger with one item 'burger')
- Support Item Customisation using Metadatas. ( Semi Advanced Usage ) ( example: Donut can have toppings. Burger can have cheese, lettuce addons) each addons can have effects. as for weapon customisation its defaults is Attachements.
- Movable Shops - preconfigured. 'Chihuahua Hot Dogs', 'Beefy Bills Burger Bar', 'Attack A Taco' (van)
- Ondemand Shop Selling - Sell Items to Random Locals Orders. (soon player based ondemand as this is currently WIP)
- Shipping Jobs - Store Owner Bulk Orders will be redirected to Shipping Job. its mean this script does not do Self Delivery like the other stock shops script. while owner can still do shipping job on their own. as shipping job is open for all and no job requirement at the moment.)
- Cashier System - All New Sales income money will be redirected to Cashier. Store Owner or Any OnDuty Clerk can Withdraw the money from Cashier.
- Store Robbery - a Simple store robbery with Skill Check. Every Cashier can be Robbed with a default 30minutes cooldown.
- Item Custom Effects on use. ( from item customisation or Preconfigured Metadatas ex.status)
- Admin Store Management - Manage Store Stocks and everything, Add New Store Via Menu from preconfigured Shop Ownable types.
- Player Stalls/Booths - place a stall anywhere (outside blacklisted areas) with a stash, storage and cash register, all working through ox_target.
- Every shop entry point (default shops, owned shops, movable shops) spawns an NPC + ox_target interaction, no marker/textUI fallback.

# Commands
- /stores - Open Admin store manage
- /addstock - @param ShopName : string: ex: General @param ShopIndex : number: ex: 1 @param Amount : number: ex: 100 @extraparam ItemName : string: ex: burger
- /delmov - remove your own stuck movable-shop entities (cart/vehicle)

# Preconfigured Shops
- General 24 / 7 Stores
- Ammunation
- Black markets
- Vehicle Shops ( Boat, Helis, Vehicles )

# Shared Options - can be found init.lua
- shared.allowplayercreateitem - @value Boolean - Allow you to Add new Custom Item to to Any Stores (exluding vehicleshop) Default false (only admin)
- shared.defaultStock - @value table - Declare how much the Initial Stock upon Store Purchase.

# NPC / ox_target
Every buyable/manageable shop point spawns an NPC ped with an ox_target option attached to it (`client/target.lua`), the same way `renzu_garage`/`renzu_vehicleshop` do it. Secondary interaction points (cashier, stash, crafting stations, work/task spots) are plain ox_target zones without a ped, since those represent physical props (a cash register, a storage box, a coffee machine) rather than a shopkeeper.

To customise which ped model/scenario spawns at a shop, pass an `npc` table to `ShopTargets.AddShopTarget` (see `client/target.lua`'s `NPC_MODELS` table for the current per-shop-type defaults) - or pass `npc = false` for a plain box zone with no ped.

# Dependency
- qbx_core (QBox)
- ox_inventory (latest)
- ox_lib (latest)
- ox_target
- oxmysql

# Note
- This resource overrides ox_inventory's own shop UI (decoy shops are registered off-map) so the built-in web UI (`web/index.html`) is always what's shown.
- To fully test the resource you need to install all the items it uses into `ox_inventory/data/items.lua` - the full list (in ox_inventory item format) is in `data/item_install.lua`. On boot, the server console prints which of these items are still missing from your ox_inventory install.
- Shop Images Used from `ox_inventory/web/images/{item}.png`
- TO use Item Effects from Customisation @ data/item-customisation.lua
- You need to Insert the export , `export = 'renzu_shops.ItemUse'`, once you use this export. this will override your config from data/items.lua on ox.

- Example

```
['burger'] = {
		label = 'Burger',
		weight = 0,
		client = {
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger',
			export = 'renzu_shops.ItemUse'
		},
	},
```

# DEMO IMAGES
- General Store

![image](https://user-images.githubusercontent.com/82306584/200500266-2028d8f3-bc95-4131-888f-0d07935f90be.png)
![image](https://user-images.githubusercontent.com/82306584/200500357-fde259cd-e5ab-4111-9d93-74de8e95e2b4.png)
- Ammunation
![image](https://user-images.githubusercontent.com/82306584/200500508-37c12934-b17a-4fd9-a63d-2cc1a665e670.png)
- Vehicle Shop
![image](https://user-images.githubusercontent.com/82306584/200500777-eeaed626-675b-43ca-94cd-9857d929b06e.png)

- Ondemand Selling
- Store

![image](https://user-images.githubusercontent.com/82306584/200501623-bdcdd9f4-ce8d-455e-b5a0-06c8c0a56af2.png)

- Movable Shop

![image](https://user-images.githubusercontent.com/82306584/200501834-de161c46-08ca-4065-9bfa-4094828dd05f.png)

- Store Manage

![image](https://user-images.githubusercontent.com/82306584/200500860-ab032c2a-5829-47f8-a4ce-eb9685117767.png)
![image](https://user-images.githubusercontent.com/82306584/200500891-19074f78-e7ed-42f5-8a3e-0f641a2564ab.png)
![image](https://user-images.githubusercontent.com/82306584/200500940-37377f39-41e5-436e-880b-ea5992db000d.png)
![image](https://user-images.githubusercontent.com/82306584/200500995-621bee56-dc22-4c49-a36c-c7acee96d1ad.png)
![image](https://user-images.githubusercontent.com/82306584/200501383-3cedc4e9-8c29-4b35-97c2-db818e35b9e6.png)

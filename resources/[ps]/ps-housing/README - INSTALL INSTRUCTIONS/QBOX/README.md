# ps-housing on Qbox

Verified against **qbx_core 1.23.0**, current `qbx_spawn`, current `ox_doorlock`.

> **This build is Qbox-only.** The qb-core / qb-target / qb-inventory / qb-radialmenu /
> qb-doorlock code paths have been removed, so there is nothing to configure: it is
> qbx_core + ox_lib + ox_target + ox_inventory + ox_doorlock, full stop. If you need
> qb-core support, use ps-housing 2.0.x.

> **This replaces the old instructions.** The previous version of this file told you to
> paste new `createCharacter` / `spawnLastLocation` functions into `qbx_core`, to gut
> `qbx_properties`, and to add a `RemoveDoorlock` event to `ox_doorlock`. **Do not do
> that any more** — all of it is either broken against current Qbox or handled by
> ps-housing itself now. See [What changed](#what-changed-and-why) at the bottom.

---

## 1. Dependencies

| Resource | Required | Notes |
|---|---|---|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | yes | 1.20.0+ |
| [ox_lib](https://github.com/overextended/ox_lib) | yes | |
| [oxmysql](https://github.com/overextended/oxmysql) | yes | |
| [ox_target](https://github.com/overextended/ox_target) | yes | |
| [ox_inventory](https://github.com/overextended/ox_inventory) | yes | |
| [ox_doorlock](https://github.com/overextended/ox_doorlock) | yes | **no patch needed any more** |
| [fivem-freecam](https://github.com/Deltanic/fivem-freecam) | yes | furniture placement |
| [ps-realtor](https://github.com/Project-Sloth/ps-realtor) | yes | creating/selling properties |

Optional, detected automatically when present: `qbx_garages` (house garages),
`qb-weathersync` (weather freeze indoors), `qb-banking` (`Config.QBManagement`).

## 2. Resources you must NOT run alongside ps-housing

- **`qbx_properties`** — it owns a `properties` table with a completely different schema
  (`id`, `owner`, `property_name`, `coords`) plus `properties_decorations`. Running both
  means one of the two will fail on every query. Stop it and remove it from your cfg.
- **`qbx_apartments`** — archived/unmaintained upstream, and it fires the same apartment
  selection event ps-housing now handles.
- **`qb-apartments` / `qb-houses`** — legacy, replaced by ps-housing.

## 3. Database

`properties_decorations` (from qbx_properties) has a foreign key onto `properties`, so it
has to go first:

```sql
DROP TABLE IF EXISTS `properties_decorations`;
DROP TABLE IF EXISTS `properties`;
```

Then import `README - INSTALL INSTRUCTIONS/QBOX/properties.sql`.

## 4. The only qbx_core edit

`qbx_core/config/server.lua`, in `characterDataTables`, change:

```lua
{'properties', 'owner'},
```

to:

```lua
{'properties', 'owner_citizenid'},
```

Without this, deleting a character throws `Unknown column 'owner' in 'where clause'`,
because ps-housing's table uses `owner_citizenid`.

That is it. **No other core file has to be touched.**

## 5. Starting apartments

`qbx_core/config/client.lua` → `characters.startingApartment` may be `true` or `false`,
ps-housing handles both:

- `true` — qbx_core fires `apartments:client:setupSpawnUI`, ps-housing shows its own
  apartment picker (`client/apartmentselect.lua`), creates the apartment, and announces
  the player to the core.
- `false` — the core spawns the player normally; if `Config.StartingApartment` is still
  `true` in ps-housing, the picker opens right after spawn instead.

Turn the picker off with `Config.UseOwnApartmentSelect = false` if another resource
already does apartment selection.

Coming back into the property you logged out in is handled by ps-housing
(`Config.ReturnToPropertyOnLogin`), no core edit needed.

## 6. Clothing

ps-housing has two separate clothing hooks, both `"auto"` by default:

```lua
Config.Clothing = {
    wardrobe = "auto",   -- opened by the wardrobe furniture inside a property
    appearance = "auto", -- opens the character creator for a brand new character
}
```

**If you use `renzu_clothes`:** renzu is a shop/wardrobe only — it has no character
creator and no appearance storage of its own, it drives whatever appearance resource you
configured in `renzu_clothes/config.lua` (`fivem-appearance`, `illenium-appearance` or
skinchanger). So on `"auto"` you get:

- wardrobe → `exports.renzu_clothes:OpenClotheInventory()`
- appearance → your `illenium-appearance` / `fivem-appearance`

You do **not** need illenium's menus for this to work, only its (or fivem-appearance's)
appearance backend, which renzu needs anyway.

## 7. Optional: houses in the qbx_spawn spawn selector

Only if you run `qbx_spawn` and want your ps-housing properties listed as spawn points.
Everything else works without touching qbx_spawn.

`qbx_spawn/server/main.lua`, replace `qbx_spawn:server:getProperties` with:

```lua
lib.callback.register('qbx_spawn:server:getProperties', function(source)
    if not GetResourceState('ps-housing'):find('start') then return {} end

    local player = exports.qbx_core:GetPlayer(source)
    local houseData = {}
    local houses = MySQL.query.await(
        'SELECT property_id, street, door_data FROM properties WHERE owner_citizenid = ? AND (apartment IS NULL OR apartment = "")',
        { player.PlayerData.citizenid }
    )

    for i = 1, #houses do
        local house = houses[i]
        local door = house.door_data and json.decode(house.door_data)

        if door and door.x then
            houseData[#houseData + 1] = {
                label = house.street,
                coords = vec4(door.x, door.y, door.z, door.h or 0.0),
                propertyId = tostring(house.property_id),
            }
        end
    end

    return houseData
end)
```

`qbx_spawn/client/main.lua`, inside `inputHandler`, replace the confirm branch
(`IsControlJustReleased(0, 191)`) body with:

```lua
            DoScreenFadeOut(1000)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            local spawnData = spawns[currentButtonId]

            -- index 1 is "Last Location"; picking anything else means the player does not
            -- want to be put back inside the property they logged out in
            if currentButtonId ~= 1 then
                TriggerServerEvent('ps-housing:server:resetMetaData')
            end

            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
            FreezeEntityPosition(cache.ped, false)
            DisplayRadar(true)

            if spawnData.propertyId then
                TriggerServerEvent('ps-housing:server:enterProperty', spawnData.propertyId)
            else
                SetEntityCoords(cache.ped, spawnData.coords.x, spawnData.coords.y, spawnData.coords.z, false, false, false, false)
                SetEntityHeading(cache.ped, spawnData.coords.w or 0.0)
            end

            DoScreenFadeIn(1000)

            break
```

`qbx_spawn:server:getLastLocation` needs no change — it returns
`metadata.currentPropertyId`, which ps-housing does not use, so it stays `nil`.

If you do not patch qbx_spawn, set `Config.ReturnToPropertyOnLogin = false` when you let
players pick a spawn point, otherwise a player who picks Legion Square is still pulled
back into the house they logged out in.

## 8. ox_doorlock

**No patch.** ps-housing now uses `exports.ox_doorlock:createDoor` / `removeDoor` /
`getDoorFromName` on the server, which have existed in ox_doorlock for a long time.
This also means realtors no longer need the `command.doorlock` ace permission to place
MLO doors.

---

## What changed and why

| Old instruction | Status |
|---|---|
| Replace `createCharacter` in `qbx_core/client/character.lua` | **Harmful.** Current qbx_core sends `cid = cid` to `qbx_core:server:createCharacter` and uses the return value; the old snippet sends `citizenid = cid` and drops it, breaking character creation. |
| Replace `spawnLastLocation` in `qbx_core/client/character.lua` | **Not needed.** ps-housing puts you back in your property from `Config.ReturnToPropertyOnLogin`. The snippet also read `metadata.inside.property_id` while its qbx_spawn snippet read `metadata.inside.propertyId` — they never matched. |
| `characterDataTables` `owner` → `owner_citizenid` | **Still required.** |
| Gut `qbx_properties/fxmanifest.lua`, patch its `apartmentselect.lua` and `config/shared.lua` | **Replaced.** qbx_properties is actively maintained again and conflicts on the `properties` table. ps-housing ships its own apartment picker; just do not run qbx_properties. |
| Add `GetNameFromDoor` + `ox_doorlock:RemoveDoorlock` to ox_doorlock | **Not needed**, ox_doorlock has server exports for this. |
| Patch `qbx_spawn` | **Optional**, only for listing houses as spawn points, and the snippet has been rewritten against the current file. |

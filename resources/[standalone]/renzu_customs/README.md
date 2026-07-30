# renzu_customs 2.0 — Qbox edition

Advanced mechanic tuning shop for FiveM, rewritten for **Qbox (qbx_core)**.
No ESX, no popui, no renzu_contextmenu, no renzu_notify, no renzu_progressbar, no mysql-async.

Everything now runs on **ox_lib**, **ox_target** and **oxmysql**.

---

## Dependencies

| Resource | Required | Used for |
|---|---|---|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | yes | player data, jobs, money |
| [ox_lib](https://github.com/overextended/ox_lib) | yes | menus, notifications, progress bars, callbacks, points |
| [ox_target](https://github.com/overextended/ox_target) | yes | every interaction |
| [oxmysql](https://github.com/overextended/oxmysql) | yes | database |
| [qbx_management](https://github.com/Qbox-project/qbx_management) | optional | society payouts (`Config.UseSociety`) |

OneSync must be enabled — the custom engine/turbo/tyre upgrades sync through entity state bags.

## Installation

1. Import `sql/renzu_customs.sql` into your database.
2. Drop the folder into your resources and add it to `server.cfg` **after** its dependencies:

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure qbx_core
ensure renzu_customs
```

3. Open `config.lua`, set the shop coordinates and jobs, and you are done.

Set `Config.Debug = true` to draw the ox_target zones while you align coordinates.

---

## What changed compared to the original

**Framework**
- ESX support and the `framework/` wrapper files are gone; the resource talks to `qbx_core` directly.
- `mysql-async` / `ghmattimysql` support removed — everything is oxmysql with prepared statements.
- Vehicle mods are written to `player_vehicles.mods`.

**Interaction**
- Every marker, `DrawMarker` loop and popui text prompt was replaced with **ox_target** zones.
- `renzu_contextmenu` menus became **ox_lib context menus**.
- `renzu_notify` became `lib.notify`, `renzu_progressbar` became `lib.progressBar` / `lib.progressCircle`.
- Shop presence uses `lib.points` instead of a 1-second distance loop.

**Custom engine / turbo / tyres**
- No more plate-keyed server tables, KVP storage or network-id broadcasts.
- The upgrades live on entity state bags (`customEngine`, `customTurbo`, `customTire`), so they replicate
  automatically and passengers hear the same engine as the driver.

**NUI**
- Rewritten from scratch: vanilla JavaScript, no jQuery, no Bootstrap, no Font Awesome CDN.
  The old UI pulled four external scripts, which simply do not load for players behind a strict network.
- Breadcrumb navigation, live search, a real invoice, keyboard shortcuts, and a responsive dark theme.
- Every click updates the UI immediately instead of waiting for the game to answer, and a timeout
  guarantees the menu can never freeze on a callback that does not come back.

**Security / correctness**
- **The price is now calculated on the server.** It diffs the vehicle as it was when the menu opened
  against the vehicle as it is at checkout. The client's number is only an estimate shown in the invoice.
- `playerDropped` was registered as a *net* event, letting any client fake another player's disconnect —
  fixed.
- The `syncdel` event let any client delete any entity by network id — removed entirely.
- `/freecustoms` used a shared, non-player-specific `menu` flag that any player could ride along with;
  it is now per-player and restricted to `group.admin` through `lib.addCommand`.
- Shop callbacks verify the player is actually standing at the shop they claim to be at.

**Bugs fixed**
- Aerials pointed at mod index 42 (arch cover) instead of 43.
- `GetVehicleProperties` returned `table.pack` results, so every colour array carried a stray `n` field.
- `GetModData` contained `local wheel = GetVehicleWheelType(vehicle),` — a stray comma that only worked by accident.
- The `pay` callback read a `vehicle` variable that was never in scope, so the vehicle class was always `nil`.
- `config.lua` called `GetGameBuildNumber()` while being loaded as a shared script, erroring on the server.
- Duplicate `action = 'openhood'` key and a duplicate headlight entry (index 22 vs `headlight`).

---

## Controls

| Key | Action |
|---|---|
| `Esc` | close the menu (changes are reverted unless you paid) |
| `Backspace` | one step back |
| `E` | free look, press `E` again to return |

## Features

- Multiple shops, each owned by a job with its own grade requirements
- Full mod coverage: performance, cosmetics, interior, wheels, liveries, extras, paint (incl. chameleon), neon, xenon, window tint, plates
- Custom engine swaps (copies sound + drivetrain handling), turbo kits with blow-off sound, tyre compounds
- Repair station built into the menu
- Stock room: browse every part that fits the cars parked in the shop
- Parts storage: pull a part off a car, carry it, store it or fit it to another car
- Spray can painting with a custom RGB picker
- Free upgrades per vehicle class, per-job discounts, society payouts

## Exports

Client:

```lua
exports.renzu_customs:GetVehicleProperties(vehicle)          -- table
exports.renzu_customs:SetVehicleProperties(vehicle, props)   -- alias: SetVehicleProp
exports.renzu_customs:GetVehicleEngine(vehicle)              -- 'adder' | 'Default'
exports.renzu_customs:SetVehicleEngine(vehicle, engine)
exports.renzu_customs:GetVehicleTurbo(vehicle)               -- 'Street' | 'Default'
exports.renzu_customs:SetVehicleTurbo(vehicle, turbo)
exports.renzu_customs:GetVehicleTireType(vehicle)            -- 'Racing' | 'Default'
exports.renzu_customs:SetVehicleTireType(vehicle, tire)
exports.renzu_customs:SetVehicleHandlingSpec(vehicle, model) -- copy another model's handling
exports.renzu_customs:GetHandlingfromModel(model, vehicle)
exports.renzu_customs:GetVehicleValue(modelHash)
```

Server:

```lua
exports.renzu_customs:GetVehicleValue(modelHash)
```

Use `GetVehicleProperties` / `SetVehicleProperties` in your garage resource so the custom engine, turbo and
tyres survive a respawn.

## Commands

| Command | Access | Description |
|---|---|---|
| `/freecustoms` | `group.admin` | opens the tuning menu anywhere, everything free |

---

## Credits

Original resource by [renzuzu](https://github.com/renzuzu/renzu_customs).
Tuner Auto Shop MLO used in the sample config: <https://forum.cfx.re/t/free-mlo-tuner-auto-shop/4247145>

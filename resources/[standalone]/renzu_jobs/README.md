# renzu_jobs 2.0

Job utility suite for **QBox (qbx_core)**. Boss menu, storage, shops, crafting,
weapon armory, a company vehicle fleet, duty clock, food preparation jobs and
turf wars.

This is a full rewrite of the original ESX version. Nothing of `es_extended`,
`mysql-async`, `skinchanger` or the old jQuery UI is left.

---

## Dependencies

| Resource | Why |
| --- | --- |
| `qbx_core` | framework, jobs, money, duty |
| `ox_lib` | callbacks, menus, progress bars, zones, points, notifications |
| `ox_inventory` | items, weapons, stashes |
| `ox_target` | interaction points |
| `oxmysql` | database |

Optional integrations, configured in `config/config.lua`:

| Resource | Used for | Setting |
| --- | --- | --- |
| `renzuzu_clothes` | every wardrobe point | `Config.ClothingResource` |
| `renzuzu_garage` | vehicle keys for company vehicles | `Config.GarageResource` |

Both are looked up by resource name and degrade gracefully: if the clothing
resource is not running the wardrobe says so instead of erroring, and if the
garage resource is missing renzu_jobs hands out its own key item.

---

## Install

1. Drop the folder in your resources and name it **`renzu_jobs`**.
2. `ensure renzu_jobs` after `qbx_core`, `ox_lib`, `ox_inventory` and `ox_target`.
3. Tables are created automatically on first start. `install/renzu_jobs.sql` is
   there if you prefer to apply the schema yourself, and contains the migration
   notes for anyone coming from 1.x.
4. Make sure every job in `config/jobs.lua` also exists in
   `qbx_core/shared/jobs.lua`. The console prints a warning listing any that do
   not — hiring and promoting cannot work for those.

---

## Configuration

| File | Contents |
| --- | --- |
| `config/config.lua` | integrations, money, peds/targeting, paycheck, images |
| `config/jobs.lua` | every job: points, stashes, shops, crafting, fleet, grades |
| `config/weapons.lua` | which grade may take which weapon from the armory |
| `config/turfs.lua` | turf war rules and territories |
| `config/foodjobs.lua` | cooking stations and recipes |
| `server/logs.lua` | Discord webhooks (**server only, on purpose**) |

> Webhook urls are **not** in `config/`. Everything in `config/` is a
> `shared_script` and is downloaded by every connecting client, so a webhook
> there is a webhook anyone can spam. They live in `server/logs.lua` instead.

### Interaction points

Every point supports a `ped` field:

```lua
ped = false                                              -- no NPC, plain zone
ped = { model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_CLIPBOARD' }
```

NPCs are only created while you are within `Config.PedRenderDistance` and are
removed again when you walk away, change job or the resource stops. Set
`Config.UseTarget = false` to fall back to an ox_lib `[E]` prompt.

---

## How the job garage works

Company vehicles belong to the **job**, never to a player.

* They live in `renzu_jobs_vehicles`, not in `player_vehicles`.
* Buying at the fleet dealer spends **company money** and registers the vehicle
  to the job with a generated plate.
* An employee signs a vehicle out at the garage and receives a key item.
  Storing it takes the key back.
* Duplication is blocked server side in three places: the checkout is an atomic
  `UPDATE ... WHERE stored = 1`, the entity is created by the server rather than
  the client, and a plate already present in the world refuses a second spawn.
* Vehicles nobody brought back are returned automatically after
  `Config.Garage.autoReturnMinutes`, and after every server restart.
* Bosses can force the whole fleet back from the boss menu (Fleet tab).

---

## Turf wars

A war is scored, not a race to press a button:

1. At a scheduled hour a war opens on one territory.
2. Gang members standing on the capture point earn points every second, capped
   at `maxStack` members so a zerg does not decide it instantly.
3. If two or more gangs are within `contestRadius`, the point is **contested**
   and nobody scores.
4. When the timer runs out, the highest scoring gang owns the territory until
   the next war there.
5. The owner gets the vault (once per `vaultCooldown`), the turf stash, the turf
   wardrobe and the turf garage.

Admin commands: `/startturf <id>`, `/endturf`, `/setturf <id> <gang|none>`.

Ownership survives restarts through `renzu_jobs_turfs`.

---

## Exports

```lua
-- server
exports.renzu_jobs:JobMoney('police')                       --> { money = n, black_money = n }
exports.renzu_jobs:addMoney(10000, 'police', nil, 'money')  --> boolean
exports.renzu_jobs:removeMoney(10000, 'police', nil, 'money')
exports.renzu_jobs:canAfford('police', 'money', 5000)       --> boolean
exports.renzu_jobs:isOnDuty(source)                         --> boolean
exports.renzu_jobs:getOnDutyCount('police')                 --> number
exports.renzu_jobs:getTurfOwner('ballas')                   --> table?
exports.renzu_jobs:startTurfWar('ballas')                   --> boolean
exports.renzu_jobs:generatePlate('PD')                      --> string

-- client
exports.renzu_jobs:rebuildPoints()   -- re-register every interaction point
```

---

## Commands

| Command | Who | What |
| --- | --- | --- |
| `/jobcreator` | admin | create jobs and grades |
| `/interaction` | anyone | job interaction menu (off by default) |
| `/startturf <id>` | admin | start a turf war |
| `/endturf` | admin | end the running war |
| `/setturf <id> <gang>` | admin | assign a territory |

`/jobcreator` registers the job in qbx_core immediately **and** prints a ready
to paste snippet for `qbx_core/shared/jobs.lua`, because qbx_core reads jobs
from that file and would otherwise lose it on restart.

---

## Notes on the paycheck

`Config.Paycheck` is **off by default**. Turning it on makes renzu_jobs pay
employees out of the job treasury, which is what gives the salary manager in the
boss menu something to control. Only enable it if you disabled the qbx_core
paycheck, otherwise everyone gets paid twice.

---

## What changed from 1.x

* ESX → qbx_core. Duty uses the native `job.onduty` instead of a shadow
  "offpolice" job.
* The built-in JSON inventory is gone; storage is ox_inventory stashes with
  job + grade restrictions enforced by the inventory itself.
* The wardrobe (skinchanger, camera, `saveclothes` table) is gone and handed to
  the clothing resource.
* Money wash removed.
* Turf wars rewritten. The old version rendered an ox_lib **debug** sphere,
  which is the big translucent ball people saw in the middle of the map.
* NUI rebuilt: no jQuery, no CDN fonts or icon packs (they never loaded offline
  in CEF), no `window.location.reload()` as a close button.
* Boss menu no longer selects the entire `players` table on every open; it runs
  one indexed query for the job.
* The food job plugin was keyed on `fastfood` while the job is called
  `burgershot`, so its stations never appeared. Fixed, and the meal processor
  now consumes the required amount of each ingredient instead of always 1.

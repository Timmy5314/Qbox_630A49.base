# los_anticheat

Server-side autoriteitslaag voor Los Balos RP.

## Wat dit wel doet

**Harde blokkades.** Drie server-side events zijn in FiveM echt cancelbaar. Daar
zit de werkelijke verdediging:

| Event | Module | Blokkeert |
|---|---|---|
| `weaponDamageEvent` | `server/modules/damage.lua` | damage modifiers (`overrideDefaultDamage`), schade boven de basiswaarde van het wapen, wapens die op deze server niet bestaan, voertuigwapens afgevuurd buiten een voertuig |
| `explosionEvent` | `server/modules/damage.lua` | explosietypes die geen enkel script gebruikt |
| `entityCreating` | `server/modules/entities.lua` | voertuigmodellen op de blacklist, en optioneel elk voertuig zonder server-registratie |

**Scoring.** Movement, health, armor en godmode worden server-side bemonsterd en
leveren punten op. Punten vervallen. Bij een drempel volgt log → admin-warn →
kick → ban, met het bewijs in de database.

**Monitoring.** 281 server-side net events staan onder rate-limiting. De lijst
wordt gegenereerd uit de codebase, niet met de hand bijgehouden.

## Wat dit niet doet, en waarom niet

Dit is geen bescherming tegen betaalde of kernel-level menu's. Die draaien onder
elke Lua-detectie die hier mogelijk is. Wat hier staat zorgt ervoor dat zo'n menu
wel kan injecteren maar niets kan bereiken dat blijft staan.

Specifiek bewust weggelaten of laag gewogen:

- **Hash-checks op clientbestanden.** De client berekent de hash. Wie het bestand
  kan wijzigen, kan de hash liegen. Schijnzekerheid.
- **`Citizen.Wait`-timing en infinite loop detectie.** Client-gerapporteerd, dus
  vervalsbaar, en geeft false positives bij lage FPS en streaming. Zit als
  signaal met gewicht 2 in de heartbeat, niet meer dan dat.
- **`GetNumResources()` mismatch.** Een injector voegt geen resource toe; hij
  draait in een bestaande. Gewicht 2.
- **Client-side `RegisterCommand` verwijderen / `SetResourceKvp` uitzetten.** Dat
  kan alleen in onze eigen resources, niet in geïnjecteerde code. Maakt de server
  niet veiliger.
- **Net events van andere resources blokkeren.** Kan niet. `CancelEvent()` zet bij
  een net event alleen een vlag; handlers die daarna geregistreerd zijn draaien
  door tenzij ze zelf `WasEventCanceled()` controleren, wat vrijwel niemand doet.
  Echt dichttimmeren gebeurt in de resource zelf. Zie het patroon in
  `qbx_vehiclekeys` na de fix van juli 2026.

"Niet-geregistreerde events blokkeren" is geen taak: FiveM staat een client al
alleen toe events te triggeren die met `RegisterNetEvent` zijn aangemeld.

## Installatie

1. `install/anticheat.sql` draaien.
2. `ensure los_anticheat` staat al in `server.cfg`, direct na `ox_target`.
3. Optioneel een webhook: `set los_anticheat:webhook "https://discord.com/api/webhooks/..."`
   in `secrets.cfg`, niet in `server.cfg`.

## Belangrijk: dry run staat aan

`Config.dryRun = true` in `shared/config.lua`. Er wordt niemand gekickt of
gebanned; alles wordt alleen gelogd. Laat dit een paar dagen zo staan met echte
spelers erop, kijk in `los_anticheat_flags` welke checks vuren op eerlijk gedrag,
stel de gewichten bij, en zet hem daarna pas uit.

Een anti-cheat die op dag één op scherp staat, kickt vooral je eigen spelers.

## Exports voor andere resources

Scripts die spelers legitiem verplaatsen of helen moeten dat melden, anders
scoort de heuristiek het als cheat.

```lua
-- Voor een revive, bandage, ziekenhuisbehandeling
exports.los_anticheat:ExpectHeal(source, 10)

-- Voor garage, housing, jail, admin-teleport
exports.los_anticheat:ExpectTeleport(source)

-- Voor een server-side voertuigspawn
exports.los_anticheat:RegisterSpawn(`adder`)

-- Handmatig een detectie melden vanuit een ander script
exports.los_anticheat:Flag(source, 'eventSpam', 'toelichting')
```

**Nog te doen:** deze aanroepen zitten nog nergens ingebouwd. renzu_garage,
ps-housing, ND_Ambulance en xt-prison moeten ze krijgen voordat `dryRun` uit kan.
Zonder dat scoren legitieme garage-uithalingen als teleport.

## Wapenschade

`shared/weapondamage.lua` bevat de vanilla basisschade. Er staat op deze server
geen enkele `weapons.meta` met damage-overrides, dus dat is de juiste baseline.
Voeg je custom wapens toe, zet hun basisschade er dan bij — anders wordt legitieme
schade als te hoog gescoord.

Handwapens en voertuig-/turretwapens staan in gescheiden tabellen en worden
verschillend beoordeeld: een handwapen moet als item in de inventory zitten, een
turret hoort bij het voertuig waar de speler in zit.

## Commando's

| Commando | Wie | Doet |
|---|---|---|
| `/acflags` | admin | Review-menu met actieve flags, false positives markeren |
| `ac_events` | console | Rapport van net events per resource |

## De lijst met events opnieuw genereren

Na het toevoegen of verwijderen van resources:

```
powershell -ExecutionPolicy Bypass -File "resources\[standalone]\los_anticheat\tools\generate_events.ps1"
```

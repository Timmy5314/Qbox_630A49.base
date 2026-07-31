# los_wanted

AI-politie die meeschaalt met het aantal echte agenten on duty.

## Waarom

`qbx_disableservices` zette `SetMaxWantedLevel(0)` en alle politie-dispatchservices
uit. Er was op deze server dus nooit AI-politie, ook niet als er nul agenten
online waren. Op een leeg uur kostte criminaliteit daardoor niets.

## De drie standen

| Agenten on duty (`leo`) | Stand | Wat er gebeurt |
|---|---|---|
| 0 | `full` | AI-politie doet alles, tot wanted level 5 |
| 1 t/m `fewOfficersUpTo` (2) | `passive` | AI-politie komt wel opdagen, maar schiet niet |
| meer dan 2 | `off` | Geen AI-politie; sterren worden gewist |

Het aantal komt uit `exports.qbx_core:GetDutyCountType('leo')`. Dat is het job
**type**, niet de jobnaam — police, bcso en sasp vallen daar allemaal onder.

De stand staat in `GlobalState.losWantedTier`, zodat een speler die net joint
meteen goed zit. Met een broadcast-event zou die de laatste wissel missen.

## Eerlijk over "schiet niet"

Daar bestaat geen instelling voor. In de stand `passive` worden de peds die GTA
zelf spawnt client-side ontwapend (`RemoveAllPedWeapons`, accuracy 0,
combat-attributen uit) zodra ze binnen 120 meter komen. Dat werkt, maar het is
een heuristiek: tussen het spawnen van een agent en de eerstvolgende scan
(1,5 s) kan er een schot vallen.

Wil je die kans nul hebben, zet dan in `shared/config.lua`:

```lua
Config.maxWantedLevel.passive = 0
```

Dan komt er in die stand simpelweg geen AI-politie, en is het verschil tussen
`passive` en `off` weg.

De scan draait alleen als je zelf sterren hebt én de stand `passive` is. Normaal
gesproken loopt hij dus nooit.

## Verhouding tot qbx_disableservices

`los_wanted` beheert de tien politie-dispatchservices en `SetMaxWantedLevel`.
Brandweer, ambulance, gangs, leger en bikers blijven van `qbx_disableservices`.
Die resource slaat de politiedelen over zodra `los_wanted` draait — zonder die
uitzondering zetten twee scripts dezelfde natives en wint degene die toevallig
als laatste draait.

## Dispatch

Vanaf drie sterren gaat er een 10-99 naar ps-dispatch, met 90 seconden cooldown
per speler. De server autoriseert; de melding wordt door de client van de
verdachte afgevuurd, omdat `CustomAlert` alleen client-side bestaat.

## Commando

`/wantedtier` (admin) toont de huidige stand en het aantal agenten on duty.

## Exports

```lua
exports.los_wanted:GetTier()          -- 'full' | 'passive' | 'off'
exports.los_wanted:GetOfficerCount()  -- aantal leo's on duty
```

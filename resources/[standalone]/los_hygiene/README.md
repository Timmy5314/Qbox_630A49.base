# los_hygiene

Douchen, plassen en poepen. Volledig nieuw voor Qbox — `_external/renzu_hygiene`
is alleen als concept gebruikt: dat is ESX (`esx_status`, `mysql-async`,
`fx_version 'adamant'`) en had hoe dan ook helemaal herschreven moeten worden.

## De drie statussen

| Status | Richting | Vol → grens | Actie |
|---|---|---|---|
| hygiene | loopt af | ~8,3 uur | douchen zet hem op 100, handen wassen +15 |
| bladder | loopt **op** | ~4,6 uur | plassen zet hem op 0 |
| bowel | loopt **op** | ~12 uur | poepen zet hem op 0, én de blaas |

Blaas en darmen lopen omhoog in plaats van omlaag — "blaas 80%" leest als vol, en
dat scheelt overal een omkering. In de HUD kleurt daarom **hoog** rood, terwijl
hygiëne juist bij **laag** rood wordt.

Alles zit in de metadata van de speler via qbx_core's `SetMetaData`, net als
honger en dorst. Geen eigen tabel, geen extra SQL, en het overleeft een herstart
omdat qbx_core de speler toch al wegschrijft.

## Alle vijf de decay-rates

De opdracht vraagt om centraal instelbare rates. Honger en dorst horen bij
qbx_core en die resource wordt niet herschreven, dus die twee staan daar.
`shared/config.lua` houdt het overzicht bij:

| status | per tick | tick | vol → leeg | waar |
|---|---|---|---|---|
| honger | −1.4 | 5 min | ~6 uur | `qbx_core/config/server.lua` |
| dorst | −1.3 | 5 min | ~6,4 uur | `qbx_core/config/server.lua` |
| hygiene | −1.0 | 5 min | ~8,3 uur | `shared/config.lua` |
| blaas | +1.8 | 5 min | ~4,6 uur | `shared/config.lua` |
| darmen | +0.7 | 5 min | ~12 uur | `shared/config.lua` |

**Honger en dorst stonden op −4.2 en −3.8**, oftewel ruim twee uur van vol naar
leeg. Je zat elke sessie meermaals te eten in plaats van te spelen. Ze zijn ruim
drie keer zo traag gezet; je moet nog steeds eten, maar het onderbreekt geen
scene meer.

## Interacties: modellen, geen coördinaten

`ox_target` hangt aan **modellen**, niet aan vaste punten. Dat werkt overal waar
zo'n object staat — ook in appartementen van ps-housing en in interieurs die
later bijkomen — en het scheelt een lijst coördinaten die iemand had moeten
opmeten.

> **De modelnamen zijn niet op deze server geverifieerd.** Werkt een toilet of
> douche niet, kijk er dan naar en typ `/hygienemodel`. Dat meldt de modelhash
> van het object waar je naar kijkt, zodat je hem in `shared/config.lua` kunt
> zetten. Zelfde aanpak als `/gangped` in los_gangpeds.

## HUD

Drie extra ringen in qbx_hud, naast honger en dorst. los_hygiene stuurt de
waarden via `hud:client:UpdateHygiene`; qbx_hud tekent ze. Een gewone
`TriggerEvent`, dus draait los_hygiene niet, dan gebeurt er in de HUD simpelweg
niets.

## Exports

```lua
-- server
exports.los_hygiene:GetStatuses(src)              -- {hygiene, bladder, bowel}
exports.los_hygiene:AddStatus(src, status, delta) -- boolean

-- client
exports.los_hygiene:GetStatuses()                 -- {hygiene, bladder, bowel}
```

Handig voor bijvoorbeeld eten en drinken die de blaas laten vollopen, of een
cel in xt-prison die de hygiëne sneller laat zakken.

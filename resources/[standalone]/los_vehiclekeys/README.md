# los_vehiclekeys

Voertuigsleutels als echt ox_inventory-item, bovenop qbx_vehiclekeys.

## Waarom ernaast en niet erin

qbx_vehiclekeys werkt met een `keysList` in de statebag van de speler, op
`sessionId` van het voertuig. Dat is de gate waar alles op leunt:
`GetIsVehicleAccessible` → `HasKeys` → `keysList`. Die logica herschrijven raakt
ook carjacking, lockpicken, hotwiren en de politie-alert.

Deze resource laat dat staan en zet er een laag boven: het **item** bepaalt wie
een sleutel hoort te hebben, en zodra iemand met dat item achter het stuur
kruipt geeft hij de sleutels door aan qbx_vehiclekeys.

## Hoe het loopt

| Moment | Wat er gebeurt | Waar |
|---|---|---|
| Kopen | Sleutel in je zak | `renzu_vehicleshop` `Config.Carkeys` |
| Instappen | Server ziet het item, geeft toegang | `los_vehiclekeys:requestKeys` |
| Parkeren | Sleutel ingeleverd | `renzu_garage/server/los_keys.lua` |
| Uithalen | Sleutel terug | idem |

Het item is `vehiclekey`, `stack = false`, met metadata `plate`, `model`,
`label` en optioneel `expires`. Geen eigen afbeelding — `key.png` stond er al.

## Job- en gangvoertuigen

`GiveKeyItem(src, plate, model, true)` geeft een tijdelijke sleutel met een
`expires` in de metadata. Die vervalt na `Config.temporaryLifetime` (4 uur) en
telt daarna niet meer mee, ook al zit het item nog in de inventory — zo ziet de
speler dat hij een dode sleutel bij zich heeft in plaats van dat hij stilletjes
verdwijnt.

Dit is de haak die md-drugs en de job-voertuigen kunnen gebruiken. **Nog niet
aangesloten** — zie BACKLOG.

## Wat dit NIET verandert

Een auto die niemand toebehoort. Hotwiren, lockpicken en carjacken blijven
precies zoals ze waren; daar komt geen item aan te pas. Het item gaat alleen
over voertuigen die van iemand zijn.

## Exports

```lua
exports.los_vehiclekeys:GiveKeyItem(src, plate, model?, temporary?) -- boolean
exports.los_vehiclekeys:RemoveKeyItem(src, plate)                   -- boolean
exports.los_vehiclekeys:HasKeyItem(src, plate)                      -- boolean
```

Alle drie zijn no-ops bij een onbekend kenteken. `GiveKeyItem` geeft geen tweede
sleutel voor hetzelfde kenteken.

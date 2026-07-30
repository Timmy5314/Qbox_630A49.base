# ND_Police — QBox (qbx_core) installatie

Dit script is omgebouwd naar **QBox-only**. De oude multi-framework `bridge/` map is verwijderd;
alle core-specifieke code staat nu in `shared/bridge.lua`.

## 1. Resource plaatsen

Zet de map in je resources en zorg dat hij `ND_Police` heet (exact — de exports gebruiken die naam):

```
resources/[standalone]/ND_Police
```

In je `server.cfg` (na `ensure qbx_core`, `ensure ox_lib`, `ensure ox_target`, `ensure ox_inventory`):

```
ensure ND_Police
```

Staat de map in een categorie die je al met `ensure [standalone]` start? Dan hoeft die regel niet.

## 2. Items toevoegen aan ox_inventory

Plak de inhoud van `items/items.lua` (zonder de `return {` en de laatste `}`) bovenin je
`ox_inventory/data/items.lua`, net binnen de bestaande `return {`.

Items die erbij komen: `cuffs`, `zipties`, `handcuffkey`, `tools`, `spikestrip`, `shield`,
`casing`, `projectile`.

Let op: `qbx_core` heeft standaard al een item `handcuffs` — dat botst niet met `cuffs`,
maar geef spelers wel de juiste (`cuffs`).

## 3. Item-afbeeldingen

Kopieer alle `.png` bestanden uit `items/` naar `ox_inventory/web/images/`.

## 4. Jobs

`data/config.lua` en `data/shotspotter.lua` staan ingesteld op de standaard qbx jobnamen:
`police`, `bcso`, `sasp` (en `ambulance` voor de shotspotter). Pas aan als jouw server
andere jobnamen gebruikt.

`data/locker_rooms.lua` staat op `police`. Wil je de SWAT/K9 outfits beperken, maak dan
die jobs aan in `qbx_core/shared/jobs.lua` en zet de `groups` daar weer op terug.

## 5. Optionele resources

| Resource | Waarvoor | Zonder deze resource |
|---|---|---|
| `ND_GunAnims` | politieschild | `shield.lua` stopt met een waarschuwing; **verwijder dan het `shield` item** |
| `ps-dispatch` | shotspotter meldingen | shotspotter detecteert wel, maar stuurt geen melding |
| `nearest-postal` of `ModernHUD` | postcode in shotspotter melding | melding toont alleen straat + zone |
| `npwd` | telefoon blokkeren bij handen omhoog | wordt overgeslagen |

## 6. Let op: overlap met `qbx_police`

`qbx_police` heeft zijn eigen boeien, escort en evidence systeem. Draai je beide, dan krijg
je dubbele ox_target opties en conflicterende animaties. Zet in `qbx_police/config` de
overlappende onderdelen uit, of stop `qbx_police` helemaal.

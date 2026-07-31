# Database-installatie — runbook

De server draait niet op deze machine. Er staat hier geen MySQL en niets luistert
op poort 3306, dus de database is niet vanaf hier te controleren of te vullen.
Deze stappen moet je zelf draaien op de machine waar de server staat.

**Maak eerst een dump. Zonder dump niets draaien.**

```bash
mysqldump -u qboxuser -p qbox > backup_voor_overhaul.sql
```

## Stap 1 — kijken wat er ontbreekt

Wijzigt niets.

```bash
mysql -u qboxuser -p qbox < install/01_check_tables.sql
```

De uitvoer noemt precies welke tabellen en kolommen missen. Draai in stap 2
alleen wat daadwerkelijk in die lijst staat.

## Stap 2 — ontbrekende onderdelen aanmaken

In deze volgorde. Alles met `IF NOT EXISTS` is veilig om nogmaals te draaien.

| # | Bestand | Alleen als stap 1 meldt |
|---|---|---|
| 1 | `resources/[ps]/ps_lib/modules/ORM/server/orm.sql` | `ps_cache_metadata` ontbreekt |
| 2 | `resources/[ps]/ps-housing/README - INSTALL INSTRUCTIONS/QBOX/properties.sql` | `properties` ontbreekt |
| 3 | `resources/[ps]/ps-mdt/sql/qbx.sql` | een `mdt_*` tabel ontbreekt |
| 4 | `install/02_renzu_garage_columns.sql` | een kolom in `player_vehicles` ontbreekt |
| 5 | `resources/[standalone]/renzu_garage/QBCORE_garage.sql` | een garage-tabel ontbreekt — **sla de vijf ALTER-regels bovenaan over**, die zijn vervangen door stap 4 |
| 6 | `resources/[standalone]/los_anticheat/install/anticheat.sql` | altijd (nieuwe resource) |
| 7 | `resources/[standalone]/los_insurance/install/insurance.sql` | altijd (nieuwe resource) |
| 8 | `resources/[standalone]/murderface-pets/sql/install.sql` | niet verplicht — zie hieronder |

Let op bij stap 3: `ps-mdt/sql/qbx.sql` is 126 KB en bevat naast tabellen ook
seed-data. Draai hem één keer.

Let op bij stap 8: murderface-pets maakt zijn eigen tabellen aan bij het opstarten
(`CREATE TABLE IF NOT EXISTS` in `server/server.lua` en `server/petshop.lua`). Je
hoeft het bestand dus niet te draaien. Het staat hier zodat je weet wat de
resource aanmaakt: `murderface_pets`, `murderface_stray_trust`,
`murderface_doghouses`, `murderface_breeding` en `murderface_petshop_displays`.

Let op bij stap 5: gebruik de QBOX-variant van ps-housing, niet de QBCore-variant
die ernaast staat.

## Stap 3 — controleren

Draai `01_check_tables.sql` opnieuw. De uitvoer moet nu leeg zijn onder beide
kopjes.

## Stap 4 — server starten en log lezen

Start pas daarna de server. Stuur de volledige startup-log door; die is nodig om
te zien of `[ps]` en `los_anticheat` schoon opkomen.

---

## Wat er nog niet geverifieerd is

`ps-housing` en `ps-mdt` zijn sinds de vorige sessie nooit runtime gedraaid. Of
ze hierna foutloos starten is niet vast te stellen zonder die log. Zie
`BACKLOG.md` #12 en #13.

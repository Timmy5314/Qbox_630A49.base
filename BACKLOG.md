# Werklijst — Los Balos RP overhaul

Status per item. Fasen verwijzen naar [SERVER-OVERHAUL.md](SERVER-OVERHAUL.md).
Severity: **BLOCKER** (server stuk) · **HIGH** · **MED** · **LOW**

---

## AFGEROND

| # | Sev | Item | Fix |
|---|---|---|---|
| 1 | BLOCKER | `ensure [ps]` ontbrak volledig in server.cfg — ps-dispatch, ps-mdt, ps-housing, ps-realtor en ps_lib draaiden nooit | server.cfg: expliciete ensure-volgorde toegevoegd |
| 2 | BLOCKER | `npwd_qbx_garages` crashte bij startup op `assert(GetResourceState('qbx_garages') == 'started')` | Volledig omgebouwd naar renzu_garage |
| 3 | HIGH | NPWD garage locatie-knop deed niets: scande alleen de lokale game pool, dus auto's in de garage werden nooit gevonden | Server bepaalt nu het doel (garage/impound/geparkeerd); client valt alleen terug op wereldscan voor rijdende auto's |
| 4 | HIGH | `ps-mdt` stond op housing-preset `qbx_properties` (bestaat niet) → SQL-error op elk burgerprofiel | Preset → `ps_housing` |
| 5 | HIGH | `ps_lib` VehicleKeys-bridge riep `QBCore.Functions.GetPlate()` aan; QBCore is nil op deze server | Nieuwe `qbx` bridge geschreven op qbx_vehiclekeys |
| 6 | MED | `ps_lib` Banking stond op `qb`, server draait Renewed-Banking | Config → `Renewed` |
| 7 | MED | Laadvolgorde: `[npwd-apps]` startte vóór `npwd`/`qbx_npwd` | Volgorde omgedraaid |
| 8 | MED | Dubbele `ensure ND_Police` / `ND_Ambulance` (zaten al in `[standalone]`) | Losse ensures verwijderd |
| 9 | MED | Security-convars allemaal uit; `sv_scriptHookAllowed` ontbrak | scriptHook 0, filterRequestControl 1, phoneExplosions false, networkedSounds false, requestParanoia 1, onesync on |
| 10 | MED | `sv_licenseKey` stond in de te committen config | Verplaatst naar gitignored `secrets.cfg` |
| 11 | LOW | Geen versiebeheer op de server | git init + baseline commit (7937 bestanden) |

---

## OPEN — eerst doen

| # | Sev | Fase | Item |
|---|---|---|---|
| 12 | **BLOCKER** | 1 | **SQL niet geverifieerd.** Er is geen MySQL-client op deze machine, dus ik kon niet controleren of de tabellen van ps-housing en ps-mdt bestaan. Nu `[ps]` start, faalt housing/MDT hard als ze ontbreken. Zie *Te draaien SQL* hieronder. |
| 13 | **BLOCKER** | 1 | **Server nog niet opgestart na de wijzigingen.** Alles is statisch geverifieerd (luac + JSON), niet runtime. Startup-log moet schoon zijn vóór verder wordt gebouwd. |
| 14 | **HIGH** | 2 | **Security hole in `qbx_vehiclekeys`**: `RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate) ...)` in `bridge/qb/server.lua` accepteert een willekeurig kenteken van de client zonder eigendomscheck. Elke speler kan sleutels van elk voertuig opvragen. Zelfde patroon bij `qb-vehiclekeys:server:removeKeys`. |
| 15 | HIGH | 1 | `sv_enableNetworkedSounds false` kan legitieme geluidsscripts breken (o.a. `mana_audio`). Testen; zo niet werkend → terug naar `true`. |
| 16 | HIGH | 3 | **Dirty money bestaat niet.** `ox.cfg` heeft `inventory:accounts ["money"]` — geen `black_money`. Model kiezen (advies: item `markedbills` met metadata) en alle illegale inkomsten erop aansluiten. |
| 17 | MED | 1 | `community_bridge` dead weight: uitzoeken wat `md-drugs` er écht van gebruikt, rest niet laden. |
| 18 | MED | 1 | `ensure [standalone]` start alles alfabetisch; `renzu_garage` verwacht dat `ox_inventory` eerder is (dependency staat in de manifest, dus dit klopt — maar controleren in de startup-log). |

---

## OPEN — nog niet aangeraakt (volledige opdracht)

Alle overige fasen uit SERVER-OVERHAUL.md staan nog volledig open:

- **Fase 2** Anti-cheat (event firewall, geld-/inventory-/vehicle-autoriteit, scoring, auto-ban)
- **Fase 3** renzu_shops, renzu_clothes, juwelier, economie, moneywash, elevators, cw-crafting
- **Fase 4** md-drugs, gangs, junkies, robnpcs, chopshop, cayocrates, scenario peds
- **Fase 5** ND_Ambulance UI, AI-dokter, ND_Police, lawmenu, verzekeringen, K9/pets, wanted
- **Fase 6** qbx_vehiclekeys item-based, carjacking, proefrit 60s, mns-aitaxi
- **Fase 7** HUD, hygiene, ps-dispatch/mdt/housing integratie, billing, qbx_visuals, monthly wipe
- **Fase 8** Discord-integratie

De 15 bronrepos staan geklooond in `_external/` en zijn klaar voor conversie.

---

## Te draaien SQL (na akkoord + backup)

Volgorde:

1. `resources/[ps]/ps-housing/README - INSTALL INSTRUCTIONS/QBOX/properties.sql`
2. `resources/[ps]/ps-mdt/sql/qbx.sql`
3. `resources/[ps]/ps_lib/modules/ORM/server/orm.sql`
4. `resources/[standalone]/renzu_garage/QBCORE_garage.sql`
   — bevat `ALTER TABLE player_vehicles ADD ...`. Draai die **alleen als de kolommen
   nog niet bestaan**, anders faalt de query. Controleer eerst:
   `SHOW COLUMNS FROM player_vehicles;` — verwacht `impound`, `type`, `job`,
   `park_coord`, `isparked`.

Maak eerst een dump:

```bash
mysqldump -u qboxuser -p qbox > backup_voor_overhaul.sql
```

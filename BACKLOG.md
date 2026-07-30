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
| 14 | **HIGH** | Sleutel-exploit `qbx_vehiclekeys`. Oorzaak lag dieper dan gedacht: `GetVehiclesFromPlate()` in `bridge/qb/shared.lua` had `plate == vehPlate or GetVehicleNumberPlateText(vehicle)` — die tweede tak is een string en dus altijd waar, waardoor de functie élk voertuig op de server teruggaf | Kentekenvergelijking gefixt + genormaliseerd; afstandscheck op alle client-aanroepbare ingangen; ook `tookKeys` en `hotwiredVehicle` (upstream "TODO: secure this event") en `setVehLockState` |
| 16 | HIGH | Dirty money bestond niet | `black_money` als tweede ox_inventory account + money type in qbx_core. Item bestond al |

---

## OPEN — eerst doen

| # | Sev | Fase | Item |
|---|---|---|---|
| 12 | **BLOCKER** | 1 | **SQL niet geverifieerd, en niet verifieerbaar vanaf deze machine.** Er draait hier geen MySQL en niets luistert op 3306 — de database staat op de host waar de server draait, niet hier. Runbook staat klaar in `install/README.md` met een controlequery die zelf meldt wat ontbreekt. Tim moet dit zelf draaien. |
| 13 | **BLOCKER** | 1 | **Server niet opgestart, en niet op te starten vanaf deze machine.** Er staat geen FXServer-artifact op C:/D:/E: dat bij deze map hoort; `.replxx_history` en `txaEvent`-regels laten zien dat de server via txAdmin op een andere machine draait (txData-config wijst naar `/home/container/`). Deze map is een werkkopie. Alles is statisch geverifieerd (luac + JSON), niets runtime. **Startup-log van Tim nodig.** |
| 15 | HIGH | 1 | `sv_enableNetworkedSounds false` kan legitieme geluidsscripts breken (o.a. `mana_audio`). Testen; zo niet werkend → terug naar `true`. |
| 19 | **HIGH** | 1 | **`los_anticheat` staat in dry run.** Voordat `Config.dryRun` uit kan moeten renzu_garage, ps-housing, ND_Ambulance en xt-prison `ExpectTeleport`/`ExpectHeal` aanroepen. Zonder dat scoort elke legitieme garage-uithaling als teleport en elke revive als healthRegen. |
| 20 | MED | 1 | `Config.entities.blockUnregisteredVehicles` staat uit. Aanzetten kan pas als renzu_garage, renzu_vehicleshop en md-drugs hun spawns via `RegisterSpawn` aanmelden. Nu spawnen die client-side. |
| 21 | MED | 3 | Alle illegale inkomsten moeten nog op `black_money` worden aangesloten: md-drugs, chopshop, robnpcs, cayo crates, qbx-overvallen. Het account bestaat nu wel, maar niemand vult het. |
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

Volledig runbook staat nu in **`install/README.md`**, met:

- `install/01_check_tables.sql` — wijzigt niets, meldt precies welke tabellen en
  kolommen ontbreken. Draai deze eerst en draai daarna alleen wat in de lijst staat.
- `install/02_renzu_garage_columns.sql` — idempotente vervanging van de vijf
  `ALTER TABLE player_vehicles ADD ...` regels uit `QBCORE_garage.sql`. Het
  origineel faalt hard als een kolom al bestaat.

Maak eerst een dump:

```bash
mysqldump -u qboxuser -p qbox > backup_voor_overhaul.sql
```

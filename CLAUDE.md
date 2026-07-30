# Los Balos RP — projectcontext

Qbox FiveM RP-server, EN/NL. Dit bestand is de vaste context voor elke sessie.
De volledige opdracht en fasering staat in [SERVER-OVERHAUL.md](SERVER-OVERHAUL.md).
De actuele werklijst staat in [BACKLOG.md](BACKLOG.md).

## Stack

| Laag | Resource |
|---|---|
| Framework | `qbx_core` (Qbox) |
| Lib / UI | `ox_lib`, `ps_lib` |
| Inventory | `ox_inventory` (framework convar `qbx`) |
| Targeting | `ox_target` |
| Database | `oxmysql` → MySQL `qbox` @ 127.0.0.1 |
| Telefoon | `npwd` + `qbx_npwd` + apps in `[npwd-apps]` |
| Bank | `Renewed-Banking` |
| Politie | `ND_Police` |
| Ambulance | `ND_Ambulance` |
| Housing | `ps-housing` (+ `ps-realtor`) |
| MDT | `ps-mdt` |
| Dispatch | `ps-dispatch` |
| Garage | `renzu_garage` |
| Autodealer | `renzu_vehicleshop` |
| Kleding | `renzu_clothes` |
| Winkels | `renzu_shops` |
| Jobs | `renzu_jobs` |
| Drugs | `md-drugs` |
| Sleutels | `qbx_vehiclekeys` |

## KRITIEK — resources die NIET bestaan

Deze zijn bewust vervangen en staan alleen nog in `cache/files/` (oude download-cache).
**Verwijs er nooit naar in code.** Elke referentie is een dode link.

`qbx_police` · `qbx_ambulancejob` · `qbx_garages` · `qbx_vehicleshop` · `qbx_drugs` ·
`qbx_mechanicjob` · `qbx_properties` · `qbx_density` · `qb-core` (alleen interne bridge)

Vervangen door: ND_Police, ND_Ambulance, renzu_garage, renzu_vehicleshop, md-drugs, ps-housing.

> `QBCore` is **altijd nil** in scripts die het via `GetResourceState('qb-core')` ophalen —
> er draait geen losse qb-core resource. Gebruik `exports.qbx_core`.

## Mapstructuur

```
resources/
  [qbx]/          Qbox resources
  [ox]/           ox_lib, ox_inventory, ox_target, ox_doorlock, ox_fuel, oxmysql
  [ps]/           ps_lib, ps-dispatch, ps-housing, ps-realtor, ps-mdt, fivem-freecam
  [npwd]/         npwd, qbx_npwd
  [npwd-apps]/    npwd_qbx_garages, npwd_qbx_mail
  [standalone]/   ND_*, renzu_*, md-drugs, community_bridge, ...
  [assets]/       maps en props
  [voice]/        pma-voice, mm_radio
_external/        referentie-clones van GitHub (NIET geladen door FiveM, gitignored)
```

## Config-bestanden

- `server.cfg` — resources en laadvolgorde. **Volgorde is bewust, niet husselen.**
- `secrets.cfg` — licentiesleutel en tokens. **Gitignored, nooit committen.**
- `ox.cfg` — ox_lib / ox_target / ox_inventory convars
- `misc.cfg` — Cfx convars
- `permissions.cfg` — ace permissions

## Conventies in deze codebase

- **Lua 5.4** (`lua54 'yes'`), fxmanifest `cerulean`.
- Server is autoriteit voor geld, items, health en positie. Client stuurt intentie.
- Callbacks via `lib.callback` (ox_lib), niet via losse events met terugroep.
- Notificaties via `exports.qbx_core:Notify(src, msg)` server-side, `lib.notify` client-side.
- Vertalingen via ox_lib locales (`locales/en.json`, `locales/nl.json`), `ox_lib 'locale'`
  in de manifest. Server draait op `en`.
- Targets via `exports.ox_target`, nooit qb-target.
- Database via `MySQL.query.await` / `MySQL.single.await` (oxmysql).
- Voertuigsleutels via `exports.qbx_vehiclekeys` (entity handles, geen plates).

### Let op bij syntax
FiveM's Lua (CfxLua) kent uitbreidingen die standaard `luac` niet parseert:

- `?.` safe navigation — bv. `exports.qbx_vehicles:GetPlayerVehicle(id)?.citizenid`
- `+=` `-=` `*=` `/=` compound assignment — bv. `notified += 1`

Een `luac -p` fout op een regel met een van deze twee is **geen echte fout**.
Controleer altijd of de gemelde regel er een van jou is voordat je hem "fixt".

Bekende voorbeelden die altijd falen op luac: `ND_Ambulance/server/main.lua:78`,
`ps-housing/server/sv_property.lua:790`, `qbx_vehiclekeys/server/keys.lua`.

Syntaxcheck: `"/c/Users/timwi/AppData/Local/Programs/Lua/bin/luac" -p <bestand>`

## Git

Repo geïnitialiseerd op de server root. `cache/`, `db/`, `_external/` en `secrets.cfg`
zijn genegeerd.

**Geparkeerde nested repos:** `renzu_garage`, `renzu_shops` en `renzu_vehicleshop` hadden
een eigen `.git`. Die zijn hernoemd naar `.git.parked` zodat de root-repo ze kan tracken.
Terugzetten kan door de map weer `.git` te noemen.

## Werkwijze

1. Lees het bestand echt voordat je het aanpast. Deze server wijkt fors af van standaard Qbox.
2. Eén fase per sessie. Zie SERVER-OVERHAUL.md.
3. Commit per logische stap.
4. Nooit een core-resource herschrijven zonder overleg — bouw een bridge ernaast.
5. Claude kan geen FiveM-client draaien. Lever bij elke wijziging een testplan voor Tim.
6. Rapporteer eerlijk wat niet getest of niet opgelost is. Zet het in BACKLOG.md.

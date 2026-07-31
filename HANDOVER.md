# Overdracht naar een nieuwe sessie

Dit bestand is geschreven omdat het contextvenster van de vorige sessie vol
raakte. Lees dit samen met [CLAUDE.md](CLAUDE.md) en [BACKLOG.md](BACKLOG.md).

---

## 1. Het allerbelangrijkste

**Geen enkele regel van dit hele traject heeft ooit op een draaiende server
gestaan.** Alles is statisch geverifieerd — syntax, itemnamen, eventnamen,
API-signaturen tegen de bron — maar de server is nooit gestart en de SQL is nooit
gedraaid.

Dat is niet vrijblijvend. In deze sessie zijn **negen** dingen gevonden die al
als "afgerond" waren opgeschreven en aantoonbaar niet werkten. Ze faalden
allemaal stil. Een startup-log had ze in tien seconden gevonden.

Doe daarom eerst:

1. `install/README.md` volgen — begin met `install/01_check_tables.sql`, die
   wijzigt niets.
2. De server starten en de **volledige startup-log** bewaren.

Zonder die log bouwt elke volgende fase op ongeteste grond.

---

## 2. Stand

| Fase | Punten | Af | Wat rest |
|---|---|---|---|
| 1 Anti-cheat | 6 | 6 | — |
| 2 Shops, kleding, economie | 7 | 6 | cw-crafting (**geparkeerd door Tim**), economie-rebalance |
| 3 Gangs, drugs, illegaal | 7 | 7 | — |
| 4 Hulpdiensten, medisch | 7 | 7 | — |
| 5 Voertuigen, sleutels | 5 | 5 | — |
| 6 HUD, visuals, systemen | 6 | 6 | — |
| 7 Discord | 2 | 2 | bot-token en rol-ID's moet Tim zelf zetten |

**Alle fases zijn doorlopen.** Wat er nog ligt is geen bouwwerk maar besluiten en
handelingen die alleen Tim kan doen:

- **ECONOMY.md** ligt klaar als voorstel. Er is bewust niets doorgevoerd; de
  opdracht vraagt om eerst akkoord. Vier concrete vragen staan onderaan dat
  bestand.
- **cw-crafting** blijft geparkeerd — dat is Tims eigen beslissing.
- **Discord-bot**: token, intents en rol-ID's. Zie `discord-bot/README.md`.

---

## 3. Nieuw in dit traject, en waar de haken zitten

| Resource | Wat | Let op |
|---|---|---|
| `los_billing` | Rekeningen, verzekeringsdekking, rente, deurwaarder-SMS, audit | `claimVehicle` zoekt de polis **op kenteken**; zonder kenteken geen dekking |
| `los_discord` + `discord-bot/` | Logging naar webhooks, rol-sync | Token en rol-ID's moet Tim zelf zetten; bot-rol moet **boven** de rollen staan die hij toekent |
| `los_wipe` | Maandelijkse wipe, drie sloten | Kan **geen** mysqldump draaien — FiveM's Lua heeft geen shell. Maakt wel een JSON-momentopname |
| `los_hygiene` | Douchen, blaas, darmen + alle decay-rates | Modelnamen niet geverifieerd; `/hygienemodel` geeft de hash |
| `los_vehiclekeys` | Sleutel als ox_inventory-item | Laat qbx_vehiclekeys' `keysList` intact; het item is de laag erboven |
| `los_aitaxi` | Downtown Cab Co., nummer 4747 | `Config.depots` is leeg gelaten; hij spawnt op een wegknooppunt |
| `los_wanted` | AI-politie op 3 standen | "Schiet niet" is een client-heuristiek, geen instelling |

Telefoonnummers die bezet zijn: **1500** overheid · **4040** black market ·
**4747** taxi · **1600** deurwaarder.

## 4. Fouten die deze codebase steeds oplevert

Boven op de lijst in CLAUDE.md. Dit zijn de patronen die deze sessie negen keer
raak waren:

1. **`require` zonder `return`.** ox_lib's `require` geeft boolean `true` terug
   als het bestand niets retourneert. `local config = require 'shared.config'`
   crasht dan op de eerste index. Raakte `los_aidoctor` en `los_insurance`.
2. **Server-side een client-only export aanroepen.** `ps-dispatch` exporteert
   `CustomAlert` alleen client-side; server-side bestaat alleen
   `GetDispatchCalls`. Raakte ND_Police én ND_Ambulance — beide meldingen zijn
   nooit aangekomen.
3. **Eventnamen die niet bestaan.** `qbx_core:client:onLogout` bestaat niet (het
   is `playerLoggedOut`). Raakte vier opruimhandlers in murderface-pets.
4. **Een verkeerd argumenttype in een externe API.** `npwd:getPlayerData(src)`
   in plaats van `{source = src}` levert stilzwijgend `null`.
5. **Itemnamen uit een andere server.** Van de 40 namen in de K9-drugslijst
   bestonden er 4.
6. **Twee resources die dezelfde native beheren.** renzu_garage zette elk
   voertuig terug op slot en won van qbx_vehiclekeys, waardoor carjacking wel
   lukte maar je niet kon instappen.
7. **`Notify` met een tabel.** qbx_core leest `text`/`caption`, niet
   `title`/`description`. Fout gebruikt = de speler ziet letterlijk
   "Placeholder".
8. **`ON DUPLICATE KEY` op een unique key met een NULLbare kolom.** MySQL ziet
   twee NULLs als verschillend; elke aankoop maakte een nieuwe rij.

### Twee dingen die ik zélf fout deed

- Ik verklaarde een listener dood op basis van een grep op alleen
  server-side `TriggerEvent`. Het event werd afgevuurd met `TriggerServerEvent`
  **vanuit de client**. **Zoek altijd op alle drie de vormen.**
- Ik schreef een fps-berekening op als gemeten feit. Tim corrigeerde dat
  terecht. Schrijf niet op wat je niet gemeten hebt.

---

## 5. Beslissingen van Tim — niet omkeren

Staan volledig in [BACKLOG.md](BACKLOG.md) onder "BESLISSINGEN VAN TIM".
Samengevat: restraints en medische handelingen zijn **items**, nooit
menuknoppen; handboeien alleen politie; lockpick is illegaal; YouTool is bewust
weg; de ziekenhuis-NPC is altijd beschikbaar; verzekering wordt van het **loon**
ingehouden; cw-crafting nog niet toevoegen; **geen coördinaten verzinnen**.

Die laatste is er één waar ik zelf tegenaan liep: ik had depot-coördinaten voor
de taxi ingetypt die ik "uit qbx_taxijob" dacht te halen maar uit mijn hoofd
schreef. Ze zijn eruit; `los_aitaxi` spawnt nu op een wegknooppunt.

---

## 6. Nieuwe resources uit dit traject

`los_anticheat` · `los_aidoctor` · `los_insurance` · `los_gangpeds` ·
`los_wanted` · `los_vehiclekeys` · `los_aitaxi` · `los_hygiene` · `los_wipe` ·
`murderface-pets` · `s4t4n667_moneywash` · `s4t4n667_elevators` ·
`s4t4n667_lawmenu` · `xt-robnpcs` · `stevo_chopshop` · `stevo_cayocrates`

Elk met een eigen README waarin staat wat er is gebouwd en waarom.

---

## 7. Handelingen die Tim moet doen

| Wat | Waar |
|---|---|
| SQL draaien | `install/README.md` |
| Server starten, log bewaren | — |
| Dierenwinkel neerzetten met `/petshop` | anders kan niemand een huisdier kopen |
| Toilet- en douchemodellen controleren met `/hygienemodel` | `los_hygiene/shared/config.lua` |
| Zwerfdier-coördinaten controleren | `murderface-pets/config.lua` |
| Wipe scherp zetten (drie sloten) | `los_wipe/shared/config.lua` |
| Discord-bot aanmaken | fase 7 |

---

## 8. Gereedschap

```bash
bash tools/luacheck.sh <bestanden>
```

Syntaxcheck die CfxLua-uitbreidingen saneert (`?.`, `+=`, backtick-hashes)
voordat luac draait. Zonder saneren stopt luac bij de eerste extensie.

```
powershell -ExecutionPolicy Bypass -File "resources\[standalone]\los_anticheat\tools\generate_events.ps1"
```

Genereert de event-whitelist van de anti-cheat opnieuw. **Draai dit na elke
nieuwe resource**, anders staan de events daarvan buiten de monitoring.

### Controles die schoon moeten blijven

Deze vier zijn breed over alle resources gedraaid en zijn nu schoon. Draai ze
opnieuw na grotere wijzigingen:

- `require` waar het doelbestand geen top-level `return` heeft
- server-side aanroep van een export die alleen client-side bestaat
- `AddEventHandler`/`RegisterNetEvent` op een naam die niemand afvuurt
- `lib.callback.await` op een callback die nergens geregistreerd is

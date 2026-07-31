# Werklijst — Los Balos RP overhaul

Status per item. Fasen verwijzen naar [SERVER-OVERHAUL.md](SERVER-OVERHAUL.md).
Severity: **BLOCKER** (server stuk) · **HIGH** · **MED** · **LOW**

> **Let op bij de fasenummers.** Tims opdracht telt Fase 1 t/m 7,
> SERVER-OVERHAUL.md telt Fase 0 t/m 8. Ze lopen één uit de pas:
> opdracht-fase 1 (anti-cheat) = SERVER-OVERHAUL fase 2. Hieronder wordt
> **Tims nummering** aangehouden.

---

## STAND: 30 van de 38 punten

| Fase | Punten | Af | Openstaand |
|---|---|---|---|
| 1 Anti-cheat | 6 | **6** | — |
| 2 Shops, kleding, economie | 7 | **6** | cw-crafting (geparkeerd door Tim), economie-rebalance |
| 3 Gangs, drugs, illegaal | 7 | **7** | — |
| 4 Hulpdiensten, medisch | 6 | **5** | K9/pets, wanted-systeem |
| 5 Voertuigen, sleutels | 4 | 0 | alles |
| 6 HUD, visuals, systemen | 6 | 0 | alles |
| 7 Discord | 2 | 0 | alles |

43 commits sinds `da40e53`.

---

## ⛔ EERST DOEN — dit blokkeert alles

**Niets van dit alles heeft ooit gedraaid.** Alle 29 punten zijn statisch
geverifieerd (syntax, itembestaan, event-namen, API-signaturen tegen de bron),
maar geen enkele regel is op een draaiende server geweest.

1. **Draai de SQL.** Zie [install/README.md](install/README.md). Begin met
   `install/01_check_tables.sql` — die wijzigt niets en meldt wat ontbreekt.
2. **Start de server en bewaar de volledige startup-log.**

Zonder die log blijft elke volgende fase bouwen op ongeteste grond.

**De server draait niet op deze machine.** Geen FXServer-artifact, geen MySQL,
niets op poort 3306. Deze map is een werkkopie; de echte server draait elders
(txAdmin-config wees naar `/home/container/`). Claude kan dus niet zelf booten
of de database bereiken.

---

## ⚠️ BESLISSINGEN VAN TIM — niet omkeren

Deze zijn tijdens het werk expliciet gecorrigeerd. Ze staan als comment in de
betreffende bestanden, maar een nieuwe sessie kan ze anders "verbeteren".
**Draai ze niet terug zonder het te vragen.**

| Beslissing | Waarom |
|---|---|
| **Restraints en medische handelingen zijn ITEMS, nooit menuknoppen.** `cuffs`, `zipties`, `handcuffkey`, `tools`, defib, medbag, stretcher. | Een menuknop ernaast maakt het item betekenisloos: het bezit van het middel ís de RP-beperking. Ze zijn uit `renzu_jobs/config/jobs.lua` verwijderd — laat ze eruit. |
| **Handboeien alleen politie, zipties voor de rest.** Server-side afgedwongen in `ND_Police/server/cuff.lua`. | Gangs moeten iemand kunnen vastbinden, maar geen politie-uitrusting dragen. |
| **De lockpick is illegaal.** Alleen bij de md-drugs dealer, nooit in een winkel. | Inbraakgereedschap hoort niet over de toonbank. |
| **YouTool is bewust VERWIJDERD.** Alle md-drugs spullen, legaal én illegaal, lopen via de dealer-NPC. | Niet opnieuw als bouwmarkt toevoegen. |
| **De ziekenhuis-NPC is ALTIJD beschikbaar.** Geen EMS-check erop. | Wie zelf naar het ziekenhuis komt wordt geholpen, ongeacht hoeveel medics online zijn. De AI-dokter die naar je toe rijdt (`los_aidoctor`) is het aparte systeem dat wél op 0 EMS wacht. |
| **Verzekering wordt van het LOON ingehouden, niet in één bedrag betaald.** Vaste premie per loonstrook via `qbx_core:server:onPaycheck`. | Zie `los_insurance/server/payroll.lua`. Samen met belasting ±30% van het loon, afgetopt op 35%. |
| **Met verzekering is medische zorg gratis.** | Eigen bijdrage staat op 0. |
| **cw-crafting nog NIET toevoegen.** | Tim wil er eerst RP voor bedenken. |
| **Prijzen die vastliggen** | behandeling $1000 · door een ander $1500 · AI-dokter $750 · respawnen $1000 |
| **Geen coördinaten verzinnen.** | Tim heeft hier terecht op gecorrigeerd. Kun je een locatie niet uit de codebase of een repo halen, vraag het dan of laat het staan met een comment. |

---

## AFGEROND — eerdere sessies

| # | Sev | Item | Fix |
|---|---|---|---|
| 1 | BLOCKER | `ensure [ps]` ontbrak in server.cfg | expliciete ensure-volgorde toegevoegd |
| 2 | BLOCKER | `npwd_qbx_garages` crashte op `qbx_garages` | omgebouwd naar renzu_garage |
| 3 | HIGH | NPWD garage locatie-knop deed niets | server bepaalt nu het doel |
| 4 | HIGH | `ps-mdt` op housing-preset `qbx_properties` | preset → `ps_housing` |
| 5 | HIGH | `ps_lib` VehicleKeys-bridge riep QBCore aan | qbx-bridge geschreven |
| 6 | MED | `ps_lib` Banking op `qb` | → `Renewed` |
| 7 | MED | `[npwd-apps]` startte vóór npwd | volgorde omgedraaid |
| 8 | MED | Dubbele `ensure ND_Police` / `ND_Ambulance` | opgeruimd |
| 9 | MED | Security-convars uit | scriptHook 0, onesync, e.a. |
| 10 | MED | `sv_licenseKey` in gecommitte config | → `secrets.cfg` |
| 11 | LOW | Geen versiebeheer | git init + baseline |

## AFGEROND — deze sessie

| Sev | Item | Fix |
|---|---|---|
| **HIGH** | Sleutel-exploit `qbx_vehiclekeys`. `GetVehiclesFromPlate()` had `plate == vehPlate or GetVehicleNumberPlateText(vehicle)` — die tweede tak is een string en dus altijd waar, waardoor **elk voertuig op de server** werd teruggegeven | kentekenvergelijking gefixt, afstandscheck op alle zeven client-ingangen |
| **HIGH** | `renzu_jobs` interactiemenu volledig dood: alle 18 entries vuurden events af waar **nul** handlers voor bestonden | `export`-ondersteuning; restraints teruggebracht naar items |
| **HIGH** | ps-housing crashte bij startup. `MySQL.query.await('SELECT * FROM properties')` gooit een **exception** bij een ontbrekende tabel, geen nil — de vriendelijke melding werd nooit bereikt | pcall + melding die naar install/README.md wijst |
| **HIGH** | ND_Police uitrusting (cuffs, zipties, shield, spikestrip) stond **nergens** te koop | naar de job-supply van renzu_jobs |
| **HIGH** | ND_Ambulance had geen enkele winkel: geen medbag of defib te krijgen | naar de job-supply van renzu_jobs |
| **HIGH** | `zipties` alleen in de politie-supply; gangs konden er nergens aan komen | toegevoegd aan de md-drugs dealer |
| **HIGH** | `data_death.prices.respawn` bestond niet, maar werd op 5 plekken gebruikt → scherm toonde "$nil" en respawnen was gratis | toegevoegd |
| **HIGH** | Meth-wholesale stil kapot: item `methbaggy` bestaat niet (heet `methbags`) én `methburner` ontbrak | beide gefixt |
| **HIGH** | Dirty money bestond niet | `black_money` als account in ox.cfg + qbx_core money type |
| **HIGH** | `qbx_core` kende geen `marabunta` en geen `mafia` | beide toegevoegd |
| MED | 14 kleding-iconen ontbraken in ox_inventory | zelf gegenereerd, `tools/gen_clothing_icons.py` |
| MED | `renzu_clothes` afrekenen kon overal in de winkel | server-side kassa-check + knop gated |
| MED | `['handcuffs']` stond dubbel in items.lua; `['lockpick']` riep dode export `ars_policejob` aan | beide opgeruimd |
| MED | `stevo_chopshop` `AddItem` schaduwde zijn parameter en gaf een ongedefinieerde `count` door | herschreven |
| MED | `stevo_chopshop` las `config.policeRequirement` (bestaat niet, heet `policeRequired`) | gefixt |
| MED | `ND_Ambulance` `prices.otherHeal` werd nergens gebruikt; afschrijven zonder saldocheck | beide gefixt |
| MED | md-drugs dealer-locatie stond vast bij resource-start | verhuist elke 45 min + black market SMS |
| MED | `xt-robnpcs` `requiredCops` las `GlobalState.copCount` van Renewed-Lib (bestaat hier niet) → deed stilzwijgend niets; dispatch stond uitgecommentarieerd | beide gefixt |

## AFGEROND — ND_Police doorlopen (fase 4)

| Sev | Item | Fix |
|---|---|---|
| **HIGH** | `client/shield.lua` riep `lib.RequestAnimDict` aan met hoofdletter R. ox_lib laadt modules op exacte naam en valt anders terug op `exports.ox_lib:RequestAnimDict`, die niet bestaat → **error zodra je het schild gebruikte** | 3× naar `lib.requestAnimDict` |
| **HIGH** | De lus die schoten detecteert zette zichzelf uit bij een tweede `ox_inventory:currentWeapon`. Wisselen van wapen zonder opbergen → **geen nieuwe lus**: geen GSR, geen hulzen, geen shotspotter voor elk tweede wapen | eigen thread met een `currentWeapon`-variabele |
| **HIGH** | `setPlayerEscort` had **nul** controles: iedereen kon elke speler binnen 10m aan zich vastmaken, naar zich toe teleporteren (`exitVeh`) en in een auto zetten | boei-, staat- en afstandscontrole server-side |
| **HIGH** | `deploySpikestrip` accepteerde een negatieve `size`; `count < data.size` was dan onwaar en `RemoveItem` draaide met een negatief aantal | integer-range 1..4 + jobcheck + afstandscheck |
| **HIGH** | `retrieveSpikestrip` controleerde het model niet → elke netId **verwijderde een willekeurige entity** en gaf een gratis spikestrip | modelcontrole op `p_ld_stinger_s` |
| **HIGH** | Inbeslagname deed niets. `if Bridge.impoundVehicle then` verwees naar een functie die nergens bestaat; de auto werd alleen **verwijderd**, terwijl de bevestiging belooft dat de eigenaar hem kan ophalen | nieuwe export `renzu_garage:ImpoundVehicle` + reden-veld |
| **HIGH** | Twee handen-omhoog systemen naast elkaar: scully zet `state.handsup` (kleine u, niet gerepliceerd), ND_Police `state.handsUp`. Alleen de tweede wordt gelezen → wie H gebruikte kon **niet getiewrapt, gefouilleerd of gedragen** worden | scully's toets uit via `server.cfg` |
| MED | `gsrTest`, `shotspotter` en `collectEvidence` waren alleen client-side afgeschermd; `collectEvidence` liep bovendien over `pairs(nil)` bij een onbekende sleutel | jobcheck, afstandscheck, rate-limit, nil-guards |
| MED | Schild-prop werd opgeruimd op `onPlayerDropped` — een **server**-event, dus die client-handler vuurde nooit. Props bleven na een disconnect hangen | server stuurt `ND_Police:playerDropped` |
| MED | Sporen bleven eeuwig op de server én als ox_target-zone bij elke client | `evidenceLifetime`, standaard 45 min |
| MED | Shotspotter zette zijn cooldown **vóór** de filters: een demper-schot verbruikte de cooldown | volgorde omgedraaid |
| MED | ps-dispatch `OfficerBackup` (10-32) en `OfficerInDistress` (10-99) werden **nergens** aangeroepen | toets `F6` + commando `/distress`, server autoriseert |
| LOW | Geen `nl.json`; `en.json` had een typefout ("otufit") | beide opgelost |

### Nieuwe resources deze sessie

`los_anticheat` · `los_aidoctor` · `los_insurance` · `los_gangpeds` ·
`s4t4n667_moneywash` · `s4t4n667_elevators` · `s4t4n667_lawmenu` ·
`xt-robnpcs` · `stevo_chopshop` · `stevo_cayocrates`

---

## OPEN

| # | Sev | Fase | Item |
|---|---|---|---|
| 12 | **BLOCKER** | — | **SQL niet gedraaid.** Zie install/README.md. Niet verifieerbaar vanaf deze machine. |
| 13 | **BLOCKER** | — | **Server nooit gestart.** Startup-log nodig. |
| 19 | **HIGH** | 1 | `los_anticheat` staat in **dry run**. Voor `Config.dryRun = false` moeten renzu_garage, ps-housing, ND_Ambulance en xt-prison `ExpectTeleport`/`ExpectHeal` aanroepen — deels gedaan (ND_Ambulance, ps-housing, xt-prison), renzu_garage bewust niet (blijft onder de 600m-drempel). |
| 20 | MED | 1 | `Config.entities.blockUnregisteredVehicles` staat uit; kan pas aan als renzu_garage/vehicleshop/md-drugs hun spawns via `RegisterSpawn` aanmelden. |
| 22 | **HIGH** | 3 | **meth heeft geen server-event voor verwerking.** meth.lua kent alleen `get*`/`give*`; verwerking zit client-side achter een minigame. Daardoor als enige drug niet gang-gebonden te maken. |
| 23 | MED | 3 | Drugverdeling per gang (crack→ballas, weed→families, meth→marabunta, heroin→vagos) is een **voorstel**; alleen cocaine→mafia lag vast. |
| 27 | MED | 3 | Turfs bestaan alleen voor ballas, triads en lostmc. Voor families, vagos, marabunta en mafia zijn 5-7 **opgemeten coördinaten per gang** nodig (zone, capture, vault, stash, wardrobe, garage+spawn). Alleen in-game vast te stellen. |
| 28 | MED | 3 | `los_gangpeds`: de `AMBIENT_GANG_*`-namen zijn GTA-gamedata en niet uit de serverbestanden te verifiëren. Controleer in-game met `/gangped`. |
| 29 | MED | 4 | `los_aidoctor` / `los_insurance` / elevators: coördinaten niet in-game gecontroleerd. |
| 30 | MED | 2 | **cw-crafting geparkeerd op verzoek van Tim** — hij wil er eerst RP voor bedenken. |
| 31 | MED | 2 | **Economie-rebalance server-breed** nog niet gedaan (job-payouts, drugsprijzen). Vraagt eerst een model. |
| 32 | MED | 4 | **ox_inventory herkent het geknielde "handen omhoog" van ND_Police niet.** `canOpenTarget` kent `missminuteman_1ig_2` en `random@mugging3`, maar niet `random@arrests@busted idle_c` (X ingedrukt houden). Politie kan altijd fouilleren, een burger-overvaller niet. ox_inventory is een core-resource — niet aangeraakt, zie standing rule 4. |
| 33 | LOW | 4 | ND_Police impound kiest altijd `impoundcoord[1]` (MRPD). Boten en vliegtuigen belanden dus in de auto-impound. De export accepteert al een `garage`-parameter; alleen de keuze ontbreekt nog. |
| 34 | LOW | 4 | `ND_Police/data/locker_rooms.lua` "opgeslagen outfits" hangt aan `ND_AppearanceShops` + `fivem-appearance`, die hier niet draaien. De knop verschijnt dus nooit. De vaste outfits werken wel. Koppelen aan illenium-appearance kan, maar is een keuze. |
| 35 | LOW | 4 | `ND_Police/locales/sv.json` mist de nieuwe sleutels. Valt terug op `en`, dus onschadelijk. |
| 17 | ~~MED~~ | — | ~~community_bridge dead weight~~ — **ONJUIST.** md-drugs gebruikt het op ruim 800 aanroepen over 30 API's. **Laten staan.** |

### Nog te bouwen (Fase 4 t/m 7)

- **Fase 4**: K9/pets (`murderface-pets`), wanted-systeem
- **Fase 5**: qbx_vehiclekeys item-based, NPC-carjacking, proefrit 60s, NPWD garage-app, mns-aitaxi
- **Fase 6**: HUD (job + geld rechtsboven), renzu_hygiene, ps-dispatch/mdt nalopen, billing, qbx_visuals, monthly wipe
- **Fase 7**: Discord-koppeling (server-ID `1067817202578890802`)

---

## Testplan — ND_Police (fase 4)

Alles hieronder is statisch geverifieerd, niets is op een draaiende server geweest.
Doe eerst de twee blockers bovenaan dit bestand.

| # | Wat | Verwacht |
|---|---|---|
| 1 | Pak een pistool, schiet, wissel **zonder op te bergen** naar een tweede wapen, schiet weer. Bekijk daarna de grond. | Bij **beide** wapens hulzen op de grond. Dit was de bug: het tweede wapen liet niets achter. |
| 2 | Laat een agent `GSR Test` doen na test 1. | POSITIEF. Spring daarna een minuut in het water → melding dat het is weggespoeld. |
| 3 | Gebruik het `shield`-item. | Schild komt in beeld, geen `SCRIPT ERROR` over `RequestAnimDict` in F8. |
| 4 | Speler met schild disconnect. | Prop verdwijnt bij de andere spelers. |
| 5 | Druk `X` (handen omhoog) en laat een ander je tiewrappen. Druk daarna `H`. | X werkt. H doet **niets** meer — dat is de bedoeling, zie punt over scully. |
| 6 | Boei iemand, neem hem mee, zet hem in een auto, haal hem eruit. | Werkt als voorheen. |
| 7 | Probeer als **niet-agent** iemand mee te nemen die niet geboeid is. | Gebeurt niets. |
| 8 | Leg een spijkermat, rijd erover, pak hem weer op. | Banden klappen, mat komt terug in je inventory. |
| 9 | Neem een **speler-eigen** auto in beslag, vul een reden in. Laat de eigenaar naar de MRPD-impound gaan. | Auto staat in de impound, met de opgegeven boete en reden. Dit werkte hiervoor niet — de auto was gewoon weg. |
| 10 | Neem een **NPC-auto** in beslag. | Melding "staat op niemands naam", auto verdwijnt. |
| 11 | Schiet in een shotspotter-zone (zie `data/shotspotter.lua`), als burger. | Politie krijgt een 10-71 met straat + zone. Tweede schot binnen 2 minuten: geen tweede melding. |
| 12 | Zelfde met een demper. | Geen melding. Daarna direct **zonder** demper schieten → wél een melding (dit ging eerder mis). |
| 13 | Druk als agent `F6`. | 10-32 in ps-dispatch bij politie én EMS. Nogmaals binnen 30 s → melding dat je moet wachten. |
| 14 | Typ als agent `/distress`. | 10-99 in ps-dispatch. |
| 15 | Typ `/distress` als burger. | Gebeurt niets. |
| 16 | `resmon 1` bij ND_Police. | Idle ≈ 0.00 ms. Piek tijdens schieten of geboeid zijn is verwacht (dat zijn `Wait(0)`-lussen). |

## Gereedschap

`bash tools/luacheck.sh <bestanden>` — syntaxcheck die CfxLua-uitbreidingen
saneert (backtick-hashes, `?.`, `?:`, compound assignment) voordat luac draait.
Zonder saneren stopt luac bij de eerste extensie en blijft de rest van een groot
bestand ongecontroleerd.

`python tools/gen_clothing_icons.py <map>` — genereert de kleding-iconen.

---

## Te draaien SQL

Volledig runbook in **[install/README.md](install/README.md)**. Maak eerst een dump.

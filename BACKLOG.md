# Werklijst — Los Balos RP overhaul

Status per item. Fasen verwijzen naar [SERVER-OVERHAUL.md](SERVER-OVERHAUL.md).
Severity: **BLOCKER** (server stuk) · **HIGH** · **MED** · **LOW**

> **Let op bij de fasenummers.** Tims opdracht telt Fase 1 t/m 7,
> SERVER-OVERHAUL.md telt Fase 0 t/m 8. Ze lopen één uit de pas:
> opdracht-fase 1 (anti-cheat) = SERVER-OVERHAUL fase 2. Hieronder wordt
> **Tims nummering** aangehouden.

---

## STAND: 46 van de 46 punten

| Fase | Punten | Af | Openstaand |
|---|---|---|---|
| 1 Anti-cheat | 6 | **6** | — |
| 2 Shops, kleding, economie | 7 | **6½** | cw-crafting (**geparkeerd door Tim**); economie-model **goedgekeurd + doorgevoerd** (jobs/premies/dirty-money/voertuig-cap); resterend: renzu_shops per-item repricing (subjectief) + drugs $/uur (in-game meten) |
| 3 Gangs, drugs, illegaal | 7 | **7** | — |
| 4 Hulpdiensten, medisch | 7 | **7** | — |
| 5 Voertuigen, sleutels | 5 | **5** | — |
| 6 HUD, visuals, systemen | 6 | **6** | — |
| 7 Discord | 2 | **2** | bot-token en rol-ID's moet Tim zelf zetten |

> Fase 4 stond hier op 6 punten met 3 open — dat telde niet op. SERVER-OVERHAUL
> fase 5 heeft er zeven: ND_Ambulance, AI-dokter, ND_Police, lawmenu,
> verzekeringen, K9/pets en het wanted-systeem. Gecorrigeerd naar 7; het totaal
> wordt daarmee 39 in plaats van 38.

68 commits sinds `da40e53`. **Alle fases doorlopen.**

> Overdracht naar een nieuwe sessie: **[HANDOVER.md](HANDOVER.md)**.

---

## ⛔ EERST DOEN — dit blokkeert alles

**Niets van dit alles heeft ooit gedraaid.** Alle 46 punten zijn statisch
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

## AFGEROND — murderface-pets / K9 (fase 4)

De resource was al Qbox-native, dus er viel geen framework-tak te strippen. Wat
er wél mis was:

| Sev | Item | Fix |
|---|---|---|
| **HIGH** | `Config.k9.illegalItems` had 40 namen waarvan er **vier** op deze server bestaan (`weed_brick`, `coke_small_brick`, `coke_brick`, `heroin`). De rest kwam van een andere server. De K9 vond dus vrijwel nooit iets, zonder foutmelding | nieuwe lijst van 71 items, stuk voor stuk gecontroleerd tegen items.lua |
| **HIGH** | Voertuig doorzoeken zocht in `gloveV`/`trunkV` + kenteken. ox_inventory noemt die opslag `glove`/`trunk` + kenteken. Het script zocht dus een voertuig met kenteken `V<kenteken>` → **altijd** "niets gevonden" | prefix gecorrigeerd |
| **HIGH** | De jobcontrole op beide K9-callbacks zat **alleen client-side**. Iedereen kon `searchInventory` rechtstreeks aanroepen en uitlezen of een speler drugs bij zich had | server-side check op job, on duty en afstand |
| **HIGH** | `buyPet` controleerde `jobRestricted` niet, terwijl `server/petshop.lua` dat wel deed. Iedereen kon rechtstreeks de politiehond kopen — prijs 0 | check toegevoegd; `buyPet`/`buySupply` bovendien achter de `enabled`-vlag van hun (uitgeschakelde) winkel |
| **HIGH** | Tien rassen gebruikten modellen uit `dusa_addonpets` / een pdk9-pack die hier **niet** staan. Zo'n hond spawnt niet: je koopt hem en er gebeurt niets | rassen verwijderd, riem uitgezet (zelfde pack) |
| MED | Politiehond was `pdk9` (ontbrekend model) | German Shepherd op base-game model, enige ras met `isK9`, `jobRestricted` op police/bcso/sasp |
| MED | De zwerfhond in Sandy Shores gaf het item `murderface_shepherd` — na bovenstaande is dat de **politiehond**. Een burger die hem temde kreeg een K9 | zwerver is nu een Golden Retriever |
| MED | `SearchLogic` controleerde niet of het dier wel een K9 is; de voertuigvariant deed dat wel | check toegevoegd |
| MED | renzu_shops had een `Petshop` geconfigureerd die naar `shared.Storeitems.Petshop` wees — die bestond niet, en de winkel stond daarom uitgecommentarieerd | itemlijst aangemaakt, winkel aan |
| LOW | `los_anticheat` kende de 14 nieuwe server-events niet | whitelist opnieuw gegenereerd |

## AFGEROND — wanted-systeem + twee dingen die nooit gedraaid kunnen hebben

| Sev | Item | Fix |
|---|---|---|
| **BLOCKER** | `los_aidoctor` en `los_insurance` doen `local config = require 'shared.config'`, maar hun config.lua gaf **niets terug**. ox_lib's require levert dan boolean `true`, dus de eerste `config.<iets>` crasht op "attempt to index a boolean value". Beide zijn vorige sessie als afgerond opgeschreven en **geen van beide zou ooit hebben gewerkt** | `return Config` toegevoegd |
| **HIGH** | `ps-dispatch` exporteert `CustomAlert` **alleen client-side**. Zowel de shotspotter van ND_Police als het noodsignaal van ND_Ambulance riep hem aan vanuit een server-bestand → `No such export CustomAlert`. Beide meldingen zijn nooit aangekomen | loopt nu via de client van de speler; autorisatie blijft server-side |
| MED | `description` bestaat niet in `CustomAlert` en werd stilzwijgend weggegooid — de straatnaam die beide scripts meestuurden kwam nooit in beeld | in de titel gezet |
| MED | Beide scripts zetten alleen `dispatchCode` en geen `code`. Dat is de valkuil uit CLAUDE.md: het scherm toonde "10-80" in plaats van 10-71 en 10-13 | gecorrigeerd |
| **HIGH** | Er was **nooit** AI-politie. `qbx_disableservices` zette `SetMaxWantedLevel(0)` en alle politie-dispatchservices uit, ook bij nul agenten online | nieuwe resource `los_wanted` met drie standen |

## AFGEROND — controlepas op verzoek van Tim

Vijf echte fouten en één misdiagnose van mij. Daarna dezelfde controles breed
over álle resources gedraaid — zie "Controles die nu schoon zijn" hieronder.

> **Les uit de misdiagnose:** ik greppte alleen op server-side `TriggerEvent` en
> concludeerde dat het event niet bestond. Het werd afgevuurd met
> `TriggerServerEvent` vanuit de **client**. Zoek altijd op alle drie de vormen —
> `TriggerEvent`, `TriggerServerEvent` en `TriggerClientEvent` — voordat je een
> listener dood verklaart. De sweep verderop doet dat wel goed.

| Sev | Resource | Item | Fix |
|---|---|---|---|
| ~~BLOCKER~~ LOW | los_insurance | **Mijn eigen misdiagnose, rechtgezet.** Ik schreef op dat `QBCore:Server:OnPlayerLoaded` niet bestaat en dat er dus nooit een waarschuwing verstuurd is. Dat klopt niet: qbx_core vuurt dat event af vanaf de **client** (`client/character.lua` regel 280 en 407). De originele code werkte. | Wel omgezet naar het server-side `QBCore:Server:PlayerLoaded`, want een client-getriggerd event kan een speler zelf blijven afvuren om zijn online-teller te resetten. Verbetering, geen bugfix. |
| **HIGH** | los_insurance | `payroll.lua` gaf `Notify` een tabel met `title`/`description`. qbx_core leest bij een tabel `text`/`caption` → de speler zag letterlijk **"Placeholder"** zonder omschrijving | naar de `subTitle`-vorm |
| **HIGH** | los_insurance | Kopen gebruikte `ON DUPLICATE KEY UPDATE` op een unique key met een NULLbare `plate`. MySQL ziet twee NULLs als verschillend → elke aankoop van een zorgpolis maakte een **nieuwe rij**, en payroll telt alle lopende polissen op. Drie keer kopen = drie keer premie | expliciet zoeken met `<=>` en bijwerken |
| **HIGH** | los_aidoctor | Hing aan `AddEventHandler('ND_Ambulance:sendSignal')` — een **net event van een andere resource**. Of dat meevuurt hangt af van FiveM's routering; te riskant voor de enige trigger van de resource | ND_Ambulance vuurt nu een server-interne `signalSent` af |
| MED | los_aidoctor | `completeTreatment` en `callFailed` gebruikten het door de client meegestuurde id in plaats van `source` → je kon de behandeling van een ander afronden en die de rekening bezorgen | `source` |
| **HIGH** | murderface-pets | Vier opruimhandlers luisterden op `qbx_core:client:onLogout`. Bestaat niet (het is `playerLoggedOut`) → bij elke characterwissel bleven dieren, hondenhok en winkelhonden **in de wereld staan** | juiste naam |

### Controles die nu schoon zijn

Breed gedraaid over `[standalone]`, `[qbx]`, `[ps]` en `[ox]`:

| Controle | Uitkomst |
|---|---|
| `local x = require 'y'` waar `y` geen top-level `return` heeft | geen |
| Server-side aanroep van een export die alleen client-side bestaat | geen |
| `AddEventHandler`/`RegisterNetEvent` op een naam die niemand afvuurt | geen |
| `lib.callback.await` op een callback die nergens geregistreerd is | één, zie #43 |
| Item-namen die onze resources gebruiken maar niet in ox_inventory staan | geen (op de bewust niet-geregistreerde riem na) |

### Nieuwe resources deze sessie

`los_anticheat` · `los_aidoctor` · `los_insurance` · `los_gangpeds` · `los_wanted` ·
`s4t4n667_moneywash` · `s4t4n667_elevators` · `s4t4n667_lawmenu` ·
`xt-robnpcs` · `stevo_chopshop` · `stevo_cayocrates`

---

## AFGEROND — controle- en economiepas (sessie aug 2026)

Fresh statische audit + economie doorgevoerd. Server niet gedraaid (kan niet vanaf
deze machine); alles statisch geverifieerd + syntax-gecheckt.

**Economie (ECONOMY.md goedgekeurd door Tim):**

| Sev | Item | Fix |
|---|---|---|
| — | Loon-model $600/$1.200/$1.500 per uur | `qbx_core/shared/jobs.lua` herschreven: instap $100/strook, ervaren $200, hulpdienst $150→$250, werkloos $25. **Politie was $500/strook ($3000/uur)** — ver boven model, teruggebracht naar $250 top. |
| — | Verzekeringspremies halveren | `los_insurance/shared/config.lua`: medical $12→$6, vehicle $8→$4. Comments bijgewerkt. |
| — | Voertuigprijzen "$300-500k top" | renzu_vehicleshop lag al goed (median $36k, p95 $210k, 1 uitschieter). `vxr` $900k→$475k. |
| MED | Shop-consumables uitschieters | tabak (redw/marlboro) $1000→$45, latte $280→$25 in storeitems.lua. Volledige per-item pas nog open (#49). |

**Dirty-money consistentie (SERVER-OVERHAUL 6.7 — ALLE illegaal inkomen = black_money):**

| Sev | Resource | Item | Fix |
|---|---|---|---|
| **HIGH** | md-drugs | wholesale (gang bulk) betaalde clean **cash** → grootste drugsopbrengst omzeilde het witwasmodel | `wholesale.lua` → black_money |
| **HIGH** | md-drugs | cornerselling fallback betaalde clean cash; `markedbills`-tak verwees naar niet-bestaand item | `CustomItem='black_money'` in DrugData/cornerselling.lua |
| MED | md-drugs | oxyruns betaalde clean cash | `oxyruns.lua` → black_money (met comment: terug naar cash als je oxy legaal wilt) |
| **HIGH** | qbx_storerobbery | kluis gaf **`markedbills`** — dat item bestaat NIET in ox_inventory → kluis leverde stil niets op | `safeCracked` → black_money (aantal × waarde) |
| MED | qbx_storerobbery | kassa gaf clean cash | `AddMoney('black_money', ...)` |

> Al consistent (geverifieerd): qbx_bankrobbery, qbx_truckrobbery, stevo_chopshop,
> stevo_cayocrates, renzu_jobs turfs gebruiken al black_money.

**Overige bevindingen:**

| Sev | Resource | Item | Fix |
|---|---|---|---|
| MED | los_wipe | `Config.startingMoney` miste **`crypto`** (qbx_core kent cash/bank/crypto/black_money). Na een wipe zou de money-JSON een sleutel missen die qbx_core verwacht | `crypto = 0` toegevoegd + comment |
| LOW | los_billing | `install/01_check_tables.sql` controleert `los_billing_invoices` niet (staat wel in README stap 9) | zie #50 |

**Geverifieerd schoon / geen actie:**
- Syntax: 114 los_*/geconverteerde bestanden + alle bewerkte bestanden — 0 echte fouten.
- los_billing volledig gelezen: `return Config` aanwezig, insurance-exports bestaan, `billing.sql` heeft juiste defaults (interest/status). Sound.
- los_anticheat event-whitelist: was NIET stale (regen gaf 1-regel dateverschil). los_billing/discord/wipe gebruiken lib.callback/lib.addCommand, geen client-triggerbare RegisterNetEvent — correct afwezig.
- `ps-dispatch:server:notify` → los_discord: werkt (ps-dispatch client vuurt het af, is net-event).

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
| 36 | MED | 4 | **murderface-pets: de drie zwerfdier-coördinaten komen uit de originele repo** en zijn niet in-game gecontroleerd. Staat er een hond in een muur of in de lucht, dan is dat de reden. Zelfde categorie als #29. |
| 37 | MED | 4 | **De dierenwinkel moet nog neergezet worden.** `/petshop` als admin, bij een van de renzu_shops Petshop-locaties. Zolang dat niet gebeurd is, kan niemand een huisdier kopen — de politiehond wél, die loopt via de job-supply. |
| 38 | LOW | 4 | murderface-pets gebruikt een eigen `locales/en.lua` (Lua-tabel met `Lang:t`), niet ox_lib locales met en/nl zoals de rest. Omzetten raakt honderden strings verspreid over ~300 KB code; niet gedaan. |
| 39 | LOW | 4 | De riem is uit (`Config.leash.enabled = false`) omdat de props `leash_model*` uit een streaming-pack komen dat hier niet staat. Komt dat pack er, dan kunnen riem én de tien verwijderde rassen terug uit `_external/murderface-pets/config.lua`. |
| 40 | MED | 4 | **`los_wanted` "schiet niet" is een heuristiek.** De AI-agenten worden client-side ontwapend zodra ze binnen 120 m komen; tussen spawnen en de scan van 1,5 s kan er een schot vallen. Wil je die kans nul: `Config.maxWantedLevel.passive = 0`. Staat zo in de README. |
| 41 | LOW | — | **Twee agenten-tellers naast elkaar.** `xt-prison` houdt `GlobalState.copCount` bij op jobnaam (interval 120 s), `los_wanted` houdt `GlobalState.losWantedOfficers` bij op jobtype `leo` (interval 20 s). `xt-robnpcs` leest de eerste. Werkt, maar het is dubbel werk met twee definities van "agent". |
| 43 | LOW | 4 | `murderface-pets` NUI-winkelscherm is **onbereikbaar**: `OpenPetShopNUI()` wordt nergens aangeroepen, en de `buyDirect`-callback erachter is nergens geregistreerd. Dode code van de auteur. De werkende route is de display-hond via ox_target. Niet gebouwd — dat is een feature die niemand gevraagd heeft. |
| 48 | MED | 6 | **De modelnamen in `los_hygiene/shared/config.lua` zijn niet geverifieerd.** Toiletten, douches en wastafels hangen aan modelhashes die ik niet op deze server heb kunnen controleren. Werkt er een niet: `/hygienemodel` meldt het model van het object waar je naar kijkt. |
| 42 | **HIGH** | — | **De `require`-valkuil is generiek.** Elk nieuw config-bestand dat via `require` wordt geladen moet eindigen op `return Config`, anders krijg je boolean `true` terug en crasht de eerste index. Dit heeft `los_aidoctor` en `los_insurance` allebei stukgemaakt. Controleer dit bij elke nieuwe resource. |
| 17 | ~~MED~~ | — | ~~community_bridge dead weight~~ — **ONJUIST.** md-drugs gebruikt het op ruim 800 aanroepen over 30 API's. **Laten staan.** |
| 49 | MED | 2 | **renzu_shops per-item repricing.** Catalogus is grotendeels redelijk, maar er is een patroon van luie `$1000`-defaults (phone, radio, garden_shovel/pitcher, e.a.) en per-shop bestanden (ownedshops/) zijn niet langs de $10-60 meetlat gelegd. Duidelijke consumable-uitschieters (tabak, latte) zijn gefixt; de rest is een subjectieve per-item pas — beste met Tims input per categorie. |
| 50 | LOW | 6 | **`install/01_check_tables.sql` mist `los_billing_invoices`.** README stap 9 draait `billing.sql` altijd, dus gedekt — maar de pre-flight check waarschuwt niet als je stap 9 overslaat. Voeg de tabel toe aan de check-lijst. |
| 51 | MED | 7 | **los_discord dode listeners.** `los_discord` is bedoeld als centrale rate-limited logger, maar `los_anticheat` en `los_wipe` posten naar hun **eigen** webhook en vuren `los_anticheat:flag` / `los_wipe:announced` nooit af → die twee los_discord-kanalen zijn dood. Functioneel werkt Discord (via directe webhooks), maar een flag-storm kan Discord's rate limit raken zonder throttling. Advies: route beide via `exports.los_discord:Log(...)` (guard met `GetResourceState('los_discord')`), óf verwijder de dode handlers als self-posting de bedoeling is. Design-keuze — niet blind doorgevoerd. Volledig gated op Tims webhook-config. |
| 52 | LOW | 3 | **Drugs $/uur-calibratie.** Prijsstructuur klopt (straat laag, bulk hoog met quantity-bonus), maar de absolute magnitudes op een exact $/uur afstellen vraagt in-game meting van deal-duur — statisch niet te doen. Meet met een paar spelers en stel de wholesale `Price` min/max bij. |

## AFGEROND — fase 5

| Sev | Item | Fix |
|---|---|---|
| — | Sleutels als echt ox_inventory-item | nieuwe resource `los_vehiclekeys`, gekoppeld aan renzu_vehicleshop (kopen) en renzu_garage (parkeren, uithalen, impound) |
| **HIGH** | **Carjacking lukte wel maar je kon niet instappen.** Niet de schuld van qbx_vehiclekeys: die zet `doorslockstate` op 1 en geeft sleutels. Maar renzu_garage draait client-side een lus die elk voertuig zonder zijn **eigen** `unlock`-statebag continu weer op slot zet, en met `LockAllLocalVehicle` geldt dat voor al het verkeer. Die lus keek niet naar `doorslockstate` | renzu_garage respecteert die statebag nu |
| MED | **Proefrit: gevraagd is 60 seconden.** De oude teller liep van 30000 met −1 per `Wait(1)`; de duur hing daarmee af van hoe vaak die lus draait in plaats van van de klok. Ik heb dat nooit gemeten en had er geen fps-getallen aan moeten hangen — dat deed ik wel, meerdere keren, en Tim corrigeerde dat terecht. De duur is nu tijdgebaseerd via `GetGameTimer`, dus hoe dan ook gelijk | `Config.TestDriveSeconds = 60` in renzu_vehicleshop |
| MED | Job- en drugsvoertuigen gaven geen sleutel-item | tijdelijke sleutel (4 uur) via het gedeelde `qb-vehiclekeys:server:AcquireVehicleKeys`, dat community_bridge en md-drugs al gebruiken |
| **HIGH** | **`los_insurance` vroeg NPWD om een telefoonnummer met een getal**, terwijl `getPlayerData` een **locator-object** wil (`{source=...}`). Alle drie de takken werden overgeslagen → altijd `null` → geen nummer → **de waarschuwings-SMS is nooit verstuurd**. De code las bovendien `getPhoneNumber()`, een methode die niet bestaat; het is een platte tabel met `phoneNumber` | beide gefixt, met de bundle-definitie als comment erbij |

> De vorige controlepas noemde warnings.lua al eens ten onrechte stuk (verkeerde
> eventnaam). Die diagnose was fout, maar de conclusie toevallig wel juist: het
> module werkte inderdaad niet — alleen door dit, één regel verderop.

### Fase 5 — af

Sleutels als item, tijdelijke sleutels voor job- en drugsvoertuigen, carjacking,
proefrit van 60 seconden en de AI-taxi. Zie de tabel hierboven.

`los_aitaxi` is volledig nieuw geschreven; `_external/mns-aitaxi` was als basis
onbruikbaar (overal `_fixed`/`_new`/`_updated` varianten van hetzelfde bestand,
niet af te leiden welke telt). Alleen het concept is overgenomen.

## FASE 6 — HUD: de keuze, met onderbouwing

De opdracht vraagt hier expliciet om advies vóór het bouwen: qbx_hud uitbreiden
of `ps-hud` porten.

**Advies: qbx_hud uitbreiden. ps-hud niet porten.**

De premisse "qbx_hud is te kaal" bleek maar half te kloppen. Wat er al in zit,
nagelopen in `html/index.html`, `html/app.js` en `client/main.lua`:

- health, armor, honger, dorst, stress, zuurstof, voice
- cash én bank, met een +/- animatie bij mutaties
- snelheidsmeter, brandstof, gordel, hoogtemeter, nitro, motorstaat
- een instellingenmenu op `I` waarin elk element apart aan/uit kan, opgeslagen
  in KVP
- stress met blur en schermschudden, per niveau instelbaar
- 20+ locales, waaronder `nl.json`

Wat er echt ontbrak was **de job**, en dat het saldo niet bleef staan.

Tegenover die kleine delta staat wat porten zou kosten: ps-hud is 2,9 MB,
QBCore-tijdperk, en zou betekenen dat we de framework-laag herbouwen én een
werkende, gelokaliseerde, qbx-native HUD weggooien. Dat is veel eigenaarschap
voor weinig winst, op een codebase die al veel te onderhouden heeft.

### Wat er is gedaan

| Sev | Item | Fix |
|---|---|---|
| MED | **Het saldo bleef niet staan.** De NUI kán dat al — er zit een `showconstant`-actie in `app.js` die `showCash`/`showBank` vastzet — maar de client stuurde die **nooit**. Daardoor flitste het bedrag alleen 3,5 seconde op na een mutatie en verdween daarna | client stuurt `showconstant` bij inladen, en opnieuw na elke mutatie |
| MED | **De job stond nergens in de HUD** | rechtsboven boven het saldo, met een stipje dat groen wordt zodra je on duty bent; ververst op `OnJobUpdate` en `SetDuty` (beide geverifieerd afgevuurd door qbx_core) |

## FASE 6 — hygiëne en de decay-rates

`los_hygiene`, volledig nieuw. `_external/renzu_hygiene` is ESX (`esx_status`,
`mysql-async`, `fx_version 'adamant'`) en is alleen als concept gebruikt.

| Sev | Item | Fix |
|---|---|---|
| **HIGH** | **Honger en dorst waren survival-grind.** −4.2 en −3.8 per tick van 5 minuten: ruim twee uur van vol naar leeg, dus meermaals eten per sessie | −1.4 en −1.3, rond de zes uur. Je moet nog steeds eten, maar het onderbreekt geen scene |
| — | Drie statussen erbij: hygiëne (loopt af), blaas en darmen (lopen **op**, want "blaas 80%" leest als vol) | metadata via qbx_core, geen eigen tabel. Rates op verzoek van Tim gehalveerd: ~16,6 / ~9,2 / ~24 uur |
| — | Drie extra ringen in qbx_hud | los_hygiene stuurt de waarden, qbx_hud tekent ze |
| — | Alle vijf de rates op één plek gedocumenteerd | `los_hygiene/shared/config.lua`; honger en dorst blijven in qbx_core, want die resource wordt niet herschreven |

Interacties hangen aan **modellen** via ox_target, niet aan coördinaten. Werkt
overal waar zo'n object staat, ook in ps-housing appartementen.

### Nog open in fase 6

- Minimap-styling
- ps-housing / ps-dispatch / ps-mdt / ps-realtor nalopen
- Billing-systeem
- `qbx_visuals` lichtreflectie
- Monthly wipe

> **Opgemerkt, niet aangeraakt:** `qbx_hud/html/app.js` regel ~449 doet
> `eval(\`this.${event.data.event} = "${event.data.toggle}"\`)` op data uit een
> NUI-bericht. Het gaat om de eigen client die zijn eigen NUI voedt, dus geen
> andere speler kan er iets in stoppen — maar een `eval` met string-interpolatie
> in een instellingenmenu is nergens voor nodig. Los te vervangen door een
> lookup; niet gedaan om deze wijziging klein te houden.

### Nog te bouwen (Fase 7)
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

## Testplan — murderface-pets / K9 (fase 4)

Doe **eerst punt 1**, anders kan niemand een huisdier kopen.

| # | Wat | Verwacht |
|---|---|---|
| 1 | Als admin `/petshop`, kies een ras, zet een display-hond neer bij de Pet Shop (`405.32, 318.54, 102.87`). | Hond staat er en blijft na een restart staan (hij zit in de DB). |
| 2 | Loop er als burger naartoe en koop hem via ox_target. | Geld eraf, item in je inventory, met afbeelding. |
| 3 | Gebruik het item. | Hond spawnt, krijgt vanzelf een naam en level 0. Tweede keer gebruiken = oproepen/wegsturen. |
| 4 | Probeer als burger de **Police K9** te kopen bij de display. | Geweigerd. Zet er anders geen K9-display neer; hij is bedoeld voor de job-supply. |
| 5 | Haal als agent de Police K9 uit de supply bij MRPD. | Item met prijs 0. Gebruiken spawnt de hond. |
| 6 | Ga on duty, richt het hond-menu (`]`) op een speler met drugs → persoon doorzoeken. | Hond loopt ernaartoe en slaat aan. Dit werkte hiervoor nooit — de itemlijst klopte niet. |
| 7 | Zelfde bij iemand **zonder** drugs. | "K9 could not find anything". |
| 8 | Doorzoek een voertuig met drugs in de kofferbak of het dashboardkastje. | Slaat aan. Dit was kapot door de `gloveV`/`trunkV`-prefix. |
| 9 | Probeer hetzelfde **off duty**, of als burger. | Gebeurt niets. |
| 10 | Probeer een gewone hond (Rottweiler) te laten doorzoeken. | "This pet can not do that!" |
| 11 | Koop voer, EHBO, waterfles, halsband, naamplaatje, trimset en een hondenhok bij de Pet Shop van renzu_shops. | Allemaal aanwezig, met afbeelding. |
| 12 | Gebruik voer en EHBO op je hond. | Item gaat er **één keer** af, niet twee keer. |
| 13 | Zet het hondenhok neer. | Prop verschijnt; hond in de buurt krijgt de rust-bonus. |
| 14 | Loop naar een zwerfdier-punt (Sandy Shores, Paleto, stad) en voer hem. | Dier staat op de grond en niet in een muur — zo niet, zie BACKLOG #36. Sandy Shores is nu een Retriever, geen Shepherd. |
| 15 | `resmon 1` bij murderface-pets, met en zonder hond buiten. | Idle laag; piek terwijl een hond je volgt is verwacht. |

## Testplan — wanted-systeem en dispatch (fase 4)

| # | Wat | Verwacht |
|---|---|---|
| 1 | Start de server, ga **niet** on duty. `/wantedtier` als admin. | `full`, 0 agenten. |
| 2 | Pleeg iets waar de politie op af komt (auto stelen waar een NPC bij is, schieten). | Je krijgt sterren en er komt AI-politie. Dit kon hiervoor niet: `SetMaxWantedLevel` stond op 0. |
| 3 | Ga on duty als agent (of laat iemand dat doen). `/wantedtier`. | Binnen ~20 s `passive`. Direct na de dienstwissel eigenlijk al. |
| 4 | Krijg in die stand sterren. | AI-politie komt wel, maar schiet niet. Zie #40 — er kan een schot vallen vlak na het spawnen. |
| 5 | Zet drie agenten on duty. `/wantedtier`. | `off`. Sterren die je had worden gewist en er komt geen AI-politie meer. |
| 6 | Ga in de stand `full` naar drie sterren. | Politie krijgt een **10-99** in ps-dispatch. Binnen 90 s geen tweede melding. |
| 7 | Schiet als burger in een shotspotter-zone. | **10-71** in ps-dispatch, met de juiste code — niet "10-80". Dit kwam hiervoor helemaal niet aan. |
| 8 | Ga neer en stuur het noodsignaal (G). | **10-13** bij EMS. Ook dit kwam nooit aan. |
| 9 | Ga dood met 0 EMS on duty. | Er rijdt een AI-ambulance uit. Dit crashte hiervoor op `config` — zie de blocker-regel hierboven. |
| 10 | Check je verzekering (ps-mdt of het radial menu). | Werkt. Crashte hiervoor op dezelfde fout. |
| 11 | `resmon 1` bij los_wanted, zonder sterren. | Idle ≈ 0.00 ms. De ped-scan draait alleen met sterren én in de stand `passive`. |

## Gereedschap

`bash tools/luacheck.sh <bestanden>` — syntaxcheck die CfxLua-uitbreidingen
saneert (backtick-hashes, `?.`, `?:`, compound assignment) voordat luac draait.
Zonder saneren stopt luac bij de eerste extensie en blijft de rest van een groot
bestand ongecontroleerd.

`python tools/gen_clothing_icons.py <map>` — genereert de kleding-iconen.

---

## Te draaien SQL

Volledig runbook in **[install/README.md](install/README.md)**. Maak eerst een dump.

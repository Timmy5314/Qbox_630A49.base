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

## 🔴 RUNTIME-BEVINDINGEN — eerste echte boot (Tim, aug 2026)

**De server draait nu echt.** SQL-tabellen staan erin (bevestigd door Tim), dus de
lege inventory / kapotte housing komt NIET door ontbrekende tabellen maar door een
startup-error of config. **Console-log (F8 / txAdmin) nog nodig** om de crash-cascade
te vinden. Prioriteit: eerst schoon booten, dan functionele breuk, dan ontwerp.

| # | Sev | Wat | Categorie |
|---|---|---|---|
| R1 | **BLOCKER** | **Inventory laadt niet / is leeg / werkt niet.** SQL staat er wel in → startup-error of ox_inventory-config. Console-log nodig. | breuk |
| R2 | **BLOCKER** | **Down/revive kapot.** Speler blijft op de grond liggen, glitcht/"oud", admin- én txadmin-heal werken niet. ND_Ambulance death-flow. | breuk |
| R3 | **HIGH** | **renzu_shops werkt bijna niet; ox_target staat verkeerd / te ver.** Zones misplaatst of resource start niet goed. | breuk |
| R4 | **HIGH** | **ps-housing werkt niet.** Ziet álle appartementen, kan met de lift naar appartementen die hij niet bezit. | breuk |
| R5 | **HIGH** | **AI-dokter (los_aidoctor) komt niet opdagen** als je down bent. Hangt deels aan R2 (death-flow). | breuk |
| R6 | **HIGH** | **AI-taxi (los_aitaxi) werkt niet + staat niet in npwd-contacten.** | breuk |
| R7 | MED | **Black market moet via de NPWD DarkChat/IRC-app** (Tim: "dit is de black market app van npwd"), NIET via SMS 4040. Nu: md-drugs TravellingMerchant gebruikt `npwd:onMessage`/`emitMessage` op een nummer. NPWD heeft een **DarkChat**-app (anonieme IRC-chat) — daar moet de black market naartoe. Te doen: onderzoek NPWD DarkChat server-API en herbedraad md-drugs erheen. Taxi blijft een **contact** (AI taxi, nr 4747) — dat is los van de black market. | ontwerp |
| R8 | MED | **Shop-peds spawnen te laat en op onbekende plek** (clothes, vehicleshop). **renzu_shops-ped draait niet mee** met de speler. Wens: pre-spawn in de winkel + meedraaien zoals clothes. | breuk |
| R9 | **HIGH** | **renzu_clothes: kopen kan nog op verschillende ox_target-plekken** (per kledingrek). Moet: **alles alleen bij de kassa** afrekenen. Kassa-menu "doet raar". | ontwerp/breuk |
| R10 | MED | **Housing-herbouw (wens).** Geen ps-realtor meer. Huizen op de map zien → kopen → na aankoop ziet **alleen de eigenaar** het huis op de map. | ontwerp |

> Dit is precies het patroon waar dit traject voor waarschuwde: statisch "af" ≠
> runtime werkend. De aanpak moet nu zijn: **tegen de draaiende server fixen**,
> niet blind. Console-errors zijn de sleutel voor R1-R6.

### ✅ Gefixt deze sessie (code, nog te testen door Tim)

- **R2 (down/revive glitch + admin-heal doet niks) — ROOT CAUSE gevonden:**
  `qbx_medical` draaide als **tweede death-systeem** naast ND_Ambulance. Beide
  detecteerden death en forceerden down-animatie/ragdoll/health → "raar op de grond"
  en onbetrouwbare revives. **`stop qbx_medical`** in server.cfg. De 3 afhankelijkheden
  omgeleid naar ND: `ps_lib` bridge `ps.isDead()` leest nu `LocalPlayer.state.dead`;
  ND vangt `qbx_medical:client:playerRevived` op (qbx admin-menu revive werkt weer);
  qbx_radialmenu death-bag is passief (breekt niet). **Extra:** ND luistert nu naar
  `txcl:heal` → een txAdmin-heal haalt je overeind (deed dat niet, want een downed
  speler is al max-health, dus "heal" veranderde niks).
- **R9 (kledingwinkel: overal kopen) — GEFIXT:** `renzu_clothes/client/shop.lua`
  maakt geen koop-target meer per kledingrek. Eén punt bij de kassa opent de hele
  winkel (bladeren + afrekenen), en het rare "cart-only" kassamenu is weg. Elke winkel
  verkoopt nog steeds precies wat hij had (juwelier = alleen sieraden, masker = maskers).
- **R11 (kleding-afbeeldingen):** zie boven — GitHub HTTPS.
- **bob74_ipl parse-fout:** gefixt (interieurs laden weer).
- **R4 (lift naar appartement dat je niet bezit) — GEFIXT (deels):** de **vreemde**
  liften zaten in `s4t4n667_elevators`. Vier appartementstorens (Del Perro Heights,
  4 Integrity Way, Richard Majestic, Tinsel Towers, uit qbx_properties) gaven IEDEREEN
  via ox_target een gratis lift naar appartementverdiepingen, los van eigendom.
  Verwijderd; alleen de publieke liften (Mission Row, Mount Zonah) blijven. ps-housing
  regelt toegang tot z'n eigen panden zelf. **Nog te doen:** "ik kan geen huizen kopen"
  — properties.sql staat er wél in (Tim bevestigt), dus de koop-/map-flow van ps-housing
  zelf moet nagelopen worden (staan huizen te koop op de map, werkt de koop-actie).
  Evt. meer locaties uit qbx_properties / ps-housing GitHub toevoegen (wens Tim).

> **Let op — qbx_radialmenu:** met qbx_medical uit verandert de `qbx_medical:deathState`
> statebag niet meer, dus het radiaal-menu wordt niet automatisch geblokkeerd terwijl
> je down bent. ND's BlockActions zet ox_target/inventory al uit; het radiaalmenu open
> kunnen tijdens down is klein. Eventueel later: ND de death-bag laten spiegelen.

### Onderzocht deze sessie (code blijkt correct)

- **AI-dokter (R5) & AI-taxi (R6):** volledige code-audit gedaan. Beide zijn correct
  bedraad: los_aidoctor hangt aan `ND_Ambulance:signalSent` (ND vuurt dat écht af),
  `GetDutyCountJob` bestaat; los_aitaxi's contact-insert gebruikt het juiste event
  (`QBCore:Server:PlayerLoaded`, dat qbx_core afvuurt), de juiste tabelkolommen
  (`npwd_phone_contacts`: identifier/number/display/avatar) en de juiste identifier
  (citizenid, exact wat qbx_npwd bij NPWD registreert). **Conclusie:** het "werkt niet"
  kwam hoogstwaarschijnlijk door de qbx_medical death-botsing (nu weg). Test-flow:
  - **Dokter:** ga down, geen medic on duty, druk **G** (noodsignaal) → na ~25s komt de AI.
  - **Taxi:** nummer is **4747** (NIET 4040 — dat is de black market), je **belt** het.
    Contact kan één relog nodig hebben (NPWD cachet contacten bij het laden).
- **Housing (R4) — diagnose:** ps-housing "apartments" zijn bewust **gedeelde** lobby's
  (iedereen kan de lift/lobby in; de individuele unit is wél op slot). Dat verklaart
  "ik zie alle appartementen en kan met de lift omhoog". Losse **huizen** in ps-housing
  worden door de **realtor** aangemaakt/verkocht; als de `properties`-tabel leeg is
  (properties.sql niet geïmporteerd, of nog geen enkele property door een realtor
  aangemaakt) staat er niks te koop → "ik kan geen huizen kopen". **Te verifiëren:**
  is `ps-housing/README - INSTALL INSTRUCTIONS/QBOX/properties.sql` geïmporteerd en
  staan er rijen in `properties`/`apartments`? Realtor blijft (wens Tim); fix richt
  zich op: huizen koopbaar + op de map + toegang alleen voor eigenaar.

### Console-log triage (F8-boot, aug 2026)

De log leek "vol errors" maar bestond voor ~95% uit ÉÉN regel, duizenden keren
herhaald (de carmap Mixed-Content, zie R11). De écht losse fouten:

| Bron | Melding | Status |
|---|---|---|
| **carmap / renzu_clothes NUI** | `Mixed Content … http://151.80.87.69:30120/carmap/... upgraded to HTTPS` (×~3000) | **R11 — kern-blocker, zie onder.** De afbeeldingen wórden opgevraagd met de juiste NameHash-namen (de wiring wérkt), maar de browser blokkeert HTTP vanaf een HTTPS-NUI. |
| **bob74_ipl** | `Error parsing script @bob74_ipl/client.lua:42: unexpected symbol near '.'` | ✅ **GEFIXT.** Regel 42 was corrupt (`   [.Enable(false)` i.p.v. `UFO.Hippie.Enable(false)`). Parse-fout brak de hele client.lua → **geen enkele IPL/interieur laadde** (Michaels huis, alle appartementen, casino). Kan housing-/interieur-gedrag beïnvloeden. |
| **chat** | `TypeError: Cannot read properties of undefined (reading 'replace') (@chat/dist/chat.js:1)` | ⚠️ Te onderzoeken. Cfx-`chat` resource; niet fataal maar verklaart mogelijk "chat doet raar". |
| **npwd** | `Failed to load external app "npwd_qbx_mail" / "npwd_qbx_garages". Make sure it is started before NPWD.` | ⚠️ Boot-waarschuwing. Vaak niet-fataal (apps laden alsnog bij openen telefoon). **In-game verifiëren** vóór we de laadvolgorde omgooien — huidige volgorde volgt de officiële qbx-docs. Los van R7 (SMS 4040) en de taxi-contacten, dat zijn npwd-CORE dingen. |
| **qbx_core** | `[ERROR] cannot set job. Job mechenic does not exist` + `command 'setjob' failed` | ✅ **Geen bug.** "mechenic" komt nergens in de code voor → dit was een typefout die jij (of iemand) in de console typte (`mechanic`). |
| **stevo_chopshop** | `Replacing existing target option 'stevo_chopshop:1..11'` | ⚠️ Chopshop registreert z'n ox_targets dubbel. Niet fataal; opschonen kan later. |
| **community_bridge** | `[ox_target] No entity with id '0' exists in community_bridge` | ⚠️ Warning, niet fataal. |
| **ps-realtor** | `-1 (@ps-realtor/html/index.js:4)` (spam) | Hangt aan R10 (ps-realtor moet eruit). |

> **Belangrijk inzicht:** ox_inventory, ND_Ambulance en ps-housing gooien in deze
> log **géén** startup-error. `[SUCCESS] Inventory Module Loaded` staat er gewoon.
> Dat betekent: R1 (lege inventory), R2 (niet kunnen revivven) en R4 (housing)
> zijn **runtime-logica/config-bugs**, geen crash-cascade. Die moeten in-game
> gereproduceerd worden — een schone bootlog "bewijst" niet dat ze werken, maar
> sluit wel uit dat een kapotte resource ze omvertrekt. bob74_ipl (nu gefixt)
> was de enige die echt niet laadde.

| # | Sev | Wat | Categorie |
|---|---|---|---|
| R11 | ✅ **OPGELOST** | **carmap-afbeeldingen werden geblokkeerd door Mixed Content** (NUI = https, game-poort = http). Oplossing (keuze Tim): afbeeldingen laden van **`https://raw.githubusercontent.com/Timmy5314/carmap/main/carmap`** (eigen GitHub-repo, HTTPS). `carmap:baseurl` in server.cfg omgezet; lokale `ensure carmap` uitgezet. Geverifieerd: submappen `clothes/`, `items/`, `vehicle/` bestaan en geven 200. renzu_clothes-wiring was al correct (leest de convar, plakt `/clothes/<NameHash>.png`). **Nog te doen (taak #7/#8):** items → `/items/`, voertuigen → `/vehicle/` (voertuig-bestanden zijn `0xHASH.jpg`, vehicleshop verwacht modelnaam → mapping nodig). |

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
| **HIGH** | qbx-overvallen + EMS | **Politie én EMS kregen GEEN enkele melding.** bank/huis/juwelier/winkel-overval + voertuigdiefstal vuren legacy `police:server:policeAlert`; truckrobbery `police:client:policeAlert`; de EMS-knop in qbx_radialmenu `hospital:server:emergencyAlert` — alle door **niemand** afgevangen op deze ND_Police/ps-dispatch-server. Ook `police:SetCopCount` werd nergens afgevuurd → qbx_bankrobbery's agententeller bleef 0 (latent: blokkeert Fleeca zodra je een minimum >0 instelt) | nieuwe brug **`los_policebridge`**: alle drie de alert-events → ps-dispatch (CustomAlert via de client van de dader; truckrobbery als directe blip; EMS naar jobtype ems) en broadcast de leo-dienstteller |
| **HIGH** | los_discord | dode listeners `los_anticheat:flag` / `los_wipe:announced` (self-posting) | gecentraliseerd via `exports.los_discord:Log`, zie #51 |
| MED | los_wipe | `Config.startingMoney` miste **`crypto`** (qbx_core kent cash/bank/crypto/black_money). Na een wipe zou de money-JSON een sleutel missen die qbx_core verwacht | `crypto = 0` toegevoegd + comment |
| MED | renzu_shops | food/beverage-shops 25-100x te hoog + `panties` prijsloos (syntax) | zie #49 |
| LOW | los_billing | `install/01_check_tables.sql` controleert `los_billing_invoices` niet | zie #50, opgelost |

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
| 49 | ~~MED~~ LOW | 2 | **renzu_shops consumable-repricing — grotendeels GEDAAN.** Alle food/beverage-shops stonden 25-100x te hoog (PondCafe koffie $3500, Balls8 maaltijden $1500, LiquorStore water $350 / grilled $1251) — teruggebracht naar de $10-60 band. Ook: tabak $1000→$45, latte $280→$25, garden tools $1000→$150/$120, en de `panties`-entry miste `price =` (syntax-bug, was prijsloos) — gefixt. **Rest bewust gelaten:** Ammunation (armour $20k e.a. — "hard to get weapons", opzet), MechanicSupply (business-parts), phone/radio $1000 (verdedigbare RP-gadgets). Store-buy prijzen ($450k per liquorstore e.a.) zijn business-investeringen, geen item-prijzen. Wil je die anders: Tims call per categorie. |
| 50 | LOW | 6 | **`install/01_check_tables.sql` mist `los_billing_invoices`.** README stap 9 draait `billing.sql` altijd, dus gedekt — maar de pre-flight check waarschuwt niet als je stap 9 overslaat. Voeg de tabel toe aan de check-lijst. |
| ~~51~~ | ~~MED~~ | 7 | ~~los_discord dode listeners.~~ **OPGELOST.** los_anticheat en los_wipe routen nu via `exports.los_discord:Log(...)` (guard met `GetResourceState('los_discord')`, eigen webhook als terugval). De dode handlers `los_anticheat:flag` / `los_wipe:announced` zijn uit los_discord verwijderd. Alle Discord-meldingen lopen nu door één rate-limited wachtrij. **LET OP:** configureer de kanaal-webhooks in `los_discord/shared/config.lua`, niet meer in de per-resource convars (die zijn nu alleen terugval als los_discord uit staat). |
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

## AFGEROND — renzu-scripts omzetten naar Qbox (sessie aug 2026)

Tim wil 8 oude renzu-scripts (motels, customs, stancer, turbo, engine, nitro,
itemback, bag) — allemaal oud ESX/QB — werkend maken op Qbox/ox.
**Alle 8 zijn omgebouwd en luacheck-schoon. Nog niet in-game getest** — testplan
per script bij Tim. Allemaal laden via `ensure [standalone]`.

| Script | Wat gedaan |
|---|---|
| **renzu_motels** | Was al bridge-gebaseerd. ESX/QB/quasar/qb-target/qb-inventory bridges eruit; nieuwe `bridge/framework/*/qbx.lua` via `exports.qbx_core`. wardrobe=renzu_clothes (`:openWardrobe`, want `OpenClotheInventory` bestond niet), target=true. `keys`-item toegevoegd. |
| **renzu_customs** | Stond al als Qbox-rewrite v2.0.0. Society-payout gefixt: was `qbx_management`/`GetAccountMoney` (bestaat niet) → **Renewed-Banking** `qb-management`/`GetAccount`. |
| **renzu_stancer** | Wrapper Qbox-only: `CreateUseableItem` + ox_inventory RemoveItem. Framework='QBX' (stancerkit-item vereist). `stancerkit`-item toegevoegd. Notify→lib.notify. |
| **renzu_turbo** | Dode `cl_wrapper.lua` (ESX, niet geladen) weg. sv_wrapper Qbox-only. `@mysql-async` weg (KVP). 4 turbo-items + iconen. |
| **renzu_nitro** | Hardcoded ESX eruit; qbx_core wrapper + `CreateUseableItem`. Dode ESX items-tabel-registratie (SqlFunc) weg. 3 nitro-shots + 3 flessen + iconen. Bijvul-no-op-bug gefixt. |
| **renzu_itemback** | `@renzu_shield` weg. Kern was al ox_inventory-native. `esx:*`-events → `QBCore:Client:*`; `esx:add/removeInventoryItem` (vuren nooit op Qbox) → `ox_inventory:itemCount`. Dode html/components.json-refs weg. |
| **renzu_bag** | `@renzu_shield` + ongebruikte ui_page/html weg (client is 100% ox_lib). ESX getSharedObject weg. Ontbrekende `renzu_bag:Notify`-handler toegevoegd. `bag`-item (`client.export`) + 4 iconen. |
| **renzu_engine** | framework/init+main naar qbx_core (wrappers, `CreateUseableItem`, ox_inventory). Use-callback-signatuur gefixt (`(source,item,data)`→`(source,data)`; qbx geeft `cb(source,data)`, oude 3e arg was nil = crash). `@oxmysql` weg (KVP). `enginegago`-item. |

Svelte overwogen en **bewust niet gedaan**: de UI's zijn al ox_lib-native menus;
de enige NUI's zijn kleine geluid/effect-overlays. Svelte = een npm/Vite-build
toevoegen voor niets. "Modern Qbox" is hier juist ox_lib, wat er al staat.

**Aandachtspunten voor de test:**
- Overlap voertuig-tuning: customs, engine, turbo, nitro, stancer werken allemaal
  op voertuigen. In-game checken dat ze elkaar niet in de weg zitten.
- Alle tuning-items (stancerkit, turbo's, nitro's, enginegago) zijn nog **nergens
  te koop** — voeg ze toe aan een shop/job-supply of geef ze als admin om te testen.
- renzu_bag heeft een eigen shop (Config.Shopcoord); renzu_nitro een bijvulstation.
- `renzu_shield` is dood — bij itemback en bag was dat één manifest-regel (weg).

## Gereedschap

`bash tools/luacheck.sh <bestanden>` — syntaxcheck die CfxLua-uitbreidingen
saneert (backtick-hashes, `?.`, `?:`, compound assignment) voordat luac draait.
Zonder saneren stopt luac bij de eerste extensie en blijft de rest van een groot
bestand ongecontroleerd.

`python tools/gen_clothing_icons.py <map>` — genereert de kleding-iconen.

---

## Te draaien SQL

Volledig runbook in **[install/README.md](install/README.md)**. Maak eerst een dump.

---

# Sessie 2 augustus 2026 — reparatieronde na Tims testronde

Tim meldde dat vrijwel niets werkte. Hieronder wat er daadwerkelijk aan de hand
was. Rode draad: **niet één grote fout, maar losse fouten die elk stil faalden.**

## Opgelost

| Klacht | Oorzaak |
|---|---|
| ox_fuel deed niets | `config.lua` had een C-stijl `/* */` commentaar. Lua parst dat niet, resource startte nooit. |
| bob74_ipl deed niets | `[.Enable(false)` — restant van een kapotte edit. Zelfde verhaal. |
| Kleding kon niet afgerekend worden | De kassa-refactor haalde het punt weg dat `atRegister` zette. `html/app.js:458` zet de afrekenknop uit zonder die vlag. |
| Kleding bleef aan na passen | Pasgoed werd pas teruggezet bij het verlaten van de winkelZONE. Met één kassapunt loop je daar niet meer uit. |
| Taxi: "kan locatie niet bereiken" | `TaskVehicleDriveToCoordLongrange` stond in een lus en werd elke 500 ms opnieuw gegeven. Die native herstart dan het pathfinden — de auto kwam nooit ergens. |
| AI-ambulance kwam niet | Zelfde fout, plus een eerste rijopdracht naar `0,0,0`. |
| Auto's stelen met lockpick | qbx_vehiclekeys wacht op `lockpicks:UseLockpick` uit de QBCore-resource `lockpicks`. Die draait hier niet en het item had geen koppeling. De twee minigames (deur + motor) bestonden al. |
| Instappen bij andere auto's | renzu_garage zette server-side élk voertuig op slot (`LockAllLocalVehicle`) zonder de `doorslockstate` statebag te vullen waar qbx_vehiclekeys op stuurt. Ontgrendelen stond uit, vergrendelen niet. |
| `/pee` en `/poo` ontbraken | Bestonden nooit; los_hygiene had alleen ox_target op toiletprops. |
| Geen huizen op de kaart | `cl_property.lua` maakte alleen een blip voor panden die je al bezit. Te koop = geen blip. |

## Wat de query-historie leerde

Tim leverde zijn HeidiSQL-config aan. De query-historie daarin gaf drie antwoorden:

1. **`impound` is nooit aangemaakt op `player_vehicles`.** renzu_garage verwijst
   er 131 keer naar in zijn serverqueries. Elke garage-query faalde dus op
   "Unknown column". Dat was de kapotte garage. Opgelost met een idempotente
   controle bij het opstarten (`renzu_garage/server/00_migrate.lua`), want de
   kolommenlijst is meermaals met de hand toegevoegd en weer weggegooid — de
   laatste DDL in de historie is een DROP van `type`, `job`, `stored`,
   `metadata`, `mileage` en `pound`, zonder dat er iets na komt.
2. **De insurance-tabellen bestaan wel** (aangemaakt 1 aug 15:46). De error komt
   dus ergens anders vandaan. Nog niet gevonden.
3. **`properties` bestaat, maar er is nooit een INSERT geweest.** Geen huizen te
   koop is dus geen bug: er staan simpelweg geen panden in. Ze worden aangemaakt
   door een makelaar via ps-realtor. De blip-fix maakt ze zichtbaar zodra er
   panden ín staan.

## Nog open

1. **los_insurance geeft een error.** Tabellen bestaan, config is compleet, de
   code leest goed. Vergt de serverlog met de echte foutregel.
2. **Wapen kan niet geequipt worden.** Geen oorzaak in de code. `canUseItem` in
   ox_inventory eist onder meer `not PlayerData.dead`, `not invBusy` en
   `PlayerData.loaded`. Vergt de clientconsole (F8) op het moment dat het misgaat.
3. **Chopshop-keten.** Het diefstal-deel is af (lockpick werkt, sleutels zoeken
   uit, ps-dispatch-melding bij geslaagde diefstal). Wat nog ontbreekt: auto
   inleveren bij de chopshop, eigenaar een verzekeringsuitkering + melding geven,
   en het voertuig terugzetten in zijn garage. Raakt stevo_chopshop,
   los_insurance en renzu_garage.
4. **renzu_jobs-menu heeft dode knoppen.** `config/jobs.lua` bevat items met
   `unimplemented = true` (`police:identity_card`, `police:search`). ND_Police
   heeft die functies zelf. Cosmetisch, niet brekend.

## Nog te bouwen

- **Chopshop-keten.** Gevraagd: gestolen auto naar de shop, eigenaar krijgt
  verzekeringsuitkering + melding + auto terug in de garage, ps-dispatch-melding
  bij diefstal, nette meldingen in de chopshop. Raakt stevo_chopshop,
  los_insurance, renzu_garage en ps-dispatch. Nog niets aan gedaan.
- **339 items hebben nergens een afbeelding.** Lijst in
  [install/ONTBREKENDE-ITEM-AFBEELDINGEN.md](install/ONTBREKENDE-ITEM-AFBEELDINGEN.md).
  Dat is content, geen code.

## Gecontroleerd en in orde

- **renzu_jobs x ND_Police x ND_Ambulance.** Delen dezelfde dienststatus:
  `Bridge.setDuty` schrijft via `SetJobDuty` naar qbx_core, en beide ND-resources
  lezen `PlayerData.job.onduty`. ND_Police matcht op jobnaam
  (`police`/`bcso`/`sasp`), ND_Ambulance op naam OF type (`ambulance`/`ems`).
  Alle vier bestaan in `qbx_core/shared/jobs.lua`. Geen actie nodig.
- **ps-dispatch bij voertuigdiefstal.** `los_policebridge` vertaalt
  `police:server:policeAlert` correct naar een ps-dispatch CustomAlert met
  `jobs = {'leo'}` op jobtype. Werkte al goed.

## Bijvangst

- `data/items.lua` had 39 dubbel gedefinieerde items. Lua neemt stil de laatste.
  Meestal wint de rijkere definitie, dus meestal ongevaarlijk — maar `lockpick`
  stond er twee keer en dat is nu samengevoegd. De rest is niet aangeraakt.

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

## SESSIE 8 augustus 2026, vervolg — qbx_*-golf + tweede externals-pas

Zelfde sessie, derde en vierde controle-golf: de laatste nog niet
gecontroleerde resources (qbx_* vehicle/economy, qbx_* UI/admin, qbx_*
jobscripts) plus een herkansing van de s4t4n667/xt/stevo-pas die eerder op
een sessielimiet liep. **Hiermee is vrijwel de hele `resources/`-boom deze
sessie doorgelicht.**

### Gefixt — twee onbeperkte geldmachines, drie client-vertrouwt-zichzelf-exploits

| Sev | Resource | Wat | Fix |
|---|---|---|---|
| **KRITIEK (security)** | stevo_chopshop | `giveRewards(source, data.name)` gebruikte de reward-tier-naam RECHTSTREEKS van de client, zonder te checken of die overeenkwam met de echte `choppingStage` van het voertuig. Iedereen kon `stevo_chopshop:chopPart` rechtstreeks aanroepen met de duurste tier (chassis, 1500-2800 black_money) en die 9-11 keer per auto claimen — 3-5x de bedoelde opbrengst | `name` wordt nu altijd afgeleid van `Entity(vehicle).state.choppingStage`, nooit meer van client-data |
| **KRITIEK (security)** | stevo_cayocrates | `createCrateDrop` stond als `RegisterNetEvent` — bedoeld als server-intern event, maar daardoor ook gewoon aanroepbaar vanaf de client via `TriggerServerEvent`. Zo kon een speler zelf een crate op zijn eigen positie "spawnen" en de USB-kosten, de 60s-timer en de cooldown volledig omzeilen: gegarandeerd 8500-11500 black_money + wapen per ~6,4s, onbeperkt herhaalbaar | → `AddEventHandler` (reageert nog op de server-interne aanroep, niet meer op de client) |
| **KRITIEK (security)** | qbx_streetraces | `RaceWon` betaalde de pot uit aan wie dan ook die het event aanriep — geen check op race-bestaan/gestart/deelname, en de race werd niet afgesloten na uitbetaling (dus herhaalbaar op dezelfde RaceId) | alleen een ingeschreven deelnemer van een gestarte race, en maar één uitkering per race. **Blijft beperkt:** dit script houdt geen server-side race-voortgang (laps/checkpoints) bij, dus een deelnemer kan in theorie nog steeds vroegtijdig "winnen" zonder echt te finishen — een volledige fix vergt de minigame herbouwen |
| **KRITIEK (security)** | qbx_weed | `harvestPlant` kreeg het item-type ÉN de hoeveelheid zaden rechtstreeks van de client — elk ox_inventory-item met elke hoeveelheid was te claimen als "oogst" van om het even welke plant | `sort`/`gender` komen nu uit de `weed_plants`-rij zelf, niet van de client |
| **KRITIEK (security)** | qbx_vehiclesales | `sellVehicle` verwijderde ELK voertuig met de opgegeven plate/model uit `player_vehicles`, ongeacht eigenaarschap, en zette het te koop onder de naam van de aanroeper — vergelijk `sellVehicleBack` ernaast, die wél op citizenid filtert | citizenid toegevoegd aan de DELETE; listing wordt alleen aangemaakt als er echt een rij van déze speler verwijderd is |
| HIGH | qbx_towjob | Uitbetaling was gebaseerd op een 'drops'-getal dat de client zelf meestuurde bij het afrekenen (bovengrens 20, verder niets) — repeatable ~$3400 zonder te towen | server telt nu zelf mee via een nieuw `dropDelivered`-event per aflevering (met 15s-ratelimit), afrekenen negeert het client-argument volledig |
| HIGH | xt-robnpcs | Straatberoving betaalde schone `money` i.p.v. `black_money` — stond niet op de "al consistent"-lijst, nooit gefixt | → black_money |
| MED | xt-prison | `config.policeJobs` (lowercase, bestaat niet — de config heeft `PoliceJobs`) hield `GlobalState.copCount` altijd op 0. Dormant zolang `MinimumPolice = 0`, maar zou de prison-break-cop-eis permanent onhaalbaar hebben gemaakt zodra die omhoog gaat | juiste veldnaam; `PoliceJobs`-lijst had ook `lspd` (bestaat niet) i.p.v. bcso/sasp — gecorrigeerd |
| MED | qbx_radialmenu | Noodknop voor een neergeschoten solo-agent riep een event aan waar nergens een handler voor bestond — deed niets | → `ND_Police:requestBackup(true)`, dezelfde 10-99 als `/distress` |
| LOW | items.lua | `10kgoldchain` gebruikt door qbx_jewelery/qbx_houserobbery loot-tabellen, nergens geregistreerd — die loot-rollen leverden stil niets op | item toegevoegd |

### Bevestigd al goed (geen actie)

s4t4n667_moneywash/elevators/lawmenu (volledig server-authoritative, geen dode refs); xt-prison's framework-bridge-bestanden (correct zelf-gegate per framework); qbx_vehiclekeys' eerder-gefixte plate-exploit (nog intact op alle 7 ingangen); qbx_taxijob (juiste jobnaam/dutystatus); dispatch-eventvorm van alle 4 qbx-robbery-resources + qbx_jewelery klopt end-to-end met los_policebridge; qbx_customs prijzen server-side berekend; qbx_hud showconstant-fix nog intact; qbx_management (geen society-money-rol, dus ook geen kandidaat voor renzu_customs — dat was al correct naar Renewed-Banking gefixt); qbx_radialmenu's dood-statebag-handler crasht niet nu qbx_medical uit staat.

### Nog open — vergt Tims oordeel, geen eenduidige codefix

| # | Sev | Wat |
|---|---|---|
| 61 | HIGH | **Dubbele voertuighandel-stack.** `qbx_customs`/`qbx_vehiclesales` (vanilla) draaien gewoon mee náást `renzu_customs`/`renzu_vehicleshop` (de aangewezen stack) — geen van beide wordt gestopt in server.cfg. Andere locaties, dus geen letterlijke botsing, maar wel dubbel onderhoud, twee losse (nooit samen gebalanceerde) prijsmodellen, en de nu-gefixte kritieke bug zat specifiek in de vanilla kant. **Advies:** `qbx_customs`/`qbx_vehiclesales` stoppen in server.cfg, zelfde precedent als `qbx_medical`. Niet zelf doorgevoerd — dit verwijdert een speler-zichtbare feature (occasion-listings) en is Tims beslissing. |
| 62 | HIGH | **qbx_weed en md-drugs botsen op itemnamen.** `weed_skunk`/`weed_amnesia`/`weed_ak47` (+ hun `_seed`-varianten) staan dubbel gedefinieerd in items.lua — qbx_weed (vrij, geen gang-eis) én md-drugs (Families-exclusief, verwerkt product). Een speler kan die drie soorten gewoon via qbx_weed kweken en rechtstreeks in md-drugs' cornerselling verkopen, buiten de gang-gate om. **Vergt een naamswijziging in óf qbx_weed óf md-drugs** — niet zelf doorgevoerd, dat raakt bestaande spelerinventories/database-rijen. |
| 63 | MED | **qbx_garbagejob-uitbetaling ver boven het economiemodel.** Een korte route kan $2.500-$10.000+ opleveren tegen het gedocumenteerde model (~$600-750/uur voor instap/hulpdiensten). Zelfde categorie als de eerdere renzu_shops-prijspas: vergt Tims goedkeuring, niet zelf doorgevoerd. |
| 64 | LOW | **qbx_spawn verwijst naar het dode `qbx_properties`** (`GetResourceState('qbx_properties')`, event `qbx_properties:server:enterProperty`). Nu onschadelijk (niets vult ooit `metadata.currentPropertyId`, dus de check geeft altijd een lege lijst — "spawn bij mijn huis" toont nooit iets, geen crash). Zou "spawn bij mijn huis" moeten koppelen aan ps-housing in plaats van het dode qbx_properties, maar dat vergt eerst uitzoeken welke ps-housing-API daarvoor bedoeld is — niet blind gegokt. |
| 65 | LOW | **qbx_vineyard-baan wordt nergens afgedwongen.** De job `vineyard` bestaat in `qbx_core/shared/jobs.lua` (Picker, $300/strook) maar de minigame zelf checkt geen enkele job — druiven/wijn plukken is voor iedereen gratis toegankelijk, ook niet-werknemers. |
| 66 | LOW | **qbx_storerobbery's safe-cracking genereert geen dispatch-melding.** Alleen de kassa-lockpick-route (laagste waarde) triggert `alertPolice()`; de kluisroute (hoogste waarde: black_money + rolex/goldbar) niet. |
| 67 | LOW | **qbx_visuals — concrete kandidaat voor de "overdreven lichtreflectie".** `Config.ContextStrength` demt elke context (0.70-0.95) behalve `night`/`rain_night`, die op `1.00` staan. Niet blind aangepast (audit kon dit niet in-game verifiëren) — **testplan:** zet die twee tijdelijk op ~0.85 en vergelijk. |
| 68 | LOW | **Diverse dode events/aanroepen zonder gevolgen voor de economie**, gevonden maar niet gefixt (geen failure behalve "doet niets"): `qbx_bankrobbery` → `qb-banking:server:SetBankClosed` (geen listener); `qbx_lapraces` → `qb-phone:client:RaceNotify` (qb-phone bestaat hier niet, NPWD is de telefoon); `qbx_newsjob` → `camera:Activate` (nergens afgevuurd, live pad is `qbx_newsjob:client:toggleCam`); `safecracker` gebruikt nog het onvertaalde `exports['qb-core']:GetCoreObject()`/`QBCore.Functions.Notify` (werkt via de qb-core-bridge, maar niet volgens conventie); `vehiclehandler` doet een GitHub-versiecheck bij elke boot (niet-fataal, wel een externe afhankelijkheid die elders al gestript is). |

---

## SESSIE 8 augustus 2026 — volledige server-audit (op verzoek van Tim: "alle scripten")

Tim was niet tevreden met alleen renzu/AI-ambulance/taxi ("ik denk dat er veel
meer is dan alleen dat, het klopt allemaal niet") en vroeg om de hele server
te controleren. Deze sessie: 8 parallelle deelaudits over vrijwel de rest van
`resources/` (ps-housing, ps-realtor, ps-dispatch, ps-mdt, npwd + beide
npwd-apps, md-drugs, community_bridge, los_billing, los_insurance, los_wipe,
los_discord, los_hygiene, los_wanted, los_anticheat, los_vehiclekeys,
los_gangpeds, los_policebridge, ND_Police, ND_GunAnims, murderface-pets, en
een aparte pas over s4t4n667_*/xt-*/stevo_*/safecracker/mhacking/
ultra-voltlab/vehiclehandler). **Nog niet gedaan:** de vanilla qbx_*
job-/robbery-/UI-resources (busjob, garbagejob, qbx_hud, qbx_storerobbery
e.d.) — dat is de volgende golf.

**Server nog steeds niet vanaf deze machine te draaien.** Alles hieronder is
weer statisch geverifieerd (code gelezen, cross-checks tussen bestanden), niet
in-game getest.

### Gefixt

| Sev | Resource | Wat | Fix |
|---|---|---|---|
| **KRITIEK (security)** | ps-housing | `server:enterProperty` riep in de else-tak altijd `PlayerEnter` aan, **vóór** de doorbell-bevestiging ooit werd afgewacht. Iedereen die "Enter"/"Ring Doorbell" op andermans huis of appartement klikte werd meteen naar binnen geteleporteerd, ongeacht toegang. Trof alles behalve echte mlo-gebouwen — dus ook de IPL-shell startappartementen. De eerdere diagnose ("gedeelde lobby, unit zelf op slot") klopte niet: er was helemaal geen toegangscontrole | else-tak belt nu alleen nog de doorbell-flow; `PlayerEnter` loopt via `doorbellAnswer` (eigenaar laat je binnen) of directe toegang |
| **HIGH (security)** | ps-housing | `addAccess`/`removeAccess`: `not owner == citizenid` — `not` bindt sterker dan `==` in Lua, dus altijd `false`. De eigenaarscheck vuurde nooit; iedereen kon zichzelf/anderen toegang tot willekeurig welk pand geven of afnemen | `owner ~= citizenid` |
| **BLOCKER** | npwd_qbx_garages + npwd_qbx_mail | Beide apps bevatten alleen TS/TSX-broncode, `web/dist` bestond niet op schijf. npwd fetcht `web/dist/remoteEntry.js` via module federation **elke keer dat een speler zijn telefoon opent**, niet eenmalig bij boot — dus 404 voor iedereen, altijd, geen Garage- en geen Mail-app. De oude aanname dat de boot-warning "niet-fataal" was klopte niet | gebouwd met `npm install --legacy-peer-deps && npm run build` (pnpm niet beschikbaar), `web/dist` gecommit (`.gitignore`'s kale `dist`-regel matchte op elke diepte, expliciet uitgezonderd) |
| HIGH | md-drugs | Dealer-ped verhuisde nooit mee met de server-side rotatie (elke `rotateMinutes`) — bevroor voorgoed op zijn eerste plek. Na de eerste rotatie stond de zichtbare ped dus op de oude plek terwijl `purchaseGoods` al tegen de nieuwe locatie de afstandscheck deed | server broadcast `md-drugs:client:merchantMoved`; client despawnt/respawnt de ped |
| HIGH | md-drugs | `deliveries.lua` riep 2x `Bridge.Notify.Error` aan — bestaat niet in community_bridge (alleen SendNotify/SendNotification). Speler zonder geld of zonder het delivery-item kreeg dus geen melding, handler crashte er stil op af | → `Bridge.Notify.SendNotify(src, msg, 'error')` |
| HIGH | los_aitaxi | Registreerde zijn voertuig-spawn nooit bij `los_anticheat:RegisterSpawn` — stond niet op de lijst (BACKLOG #20) van resources die dat moeten doen voordat `blockUnregisteredVehicles` aan mag. Nu nog dormant (flag staat uit) maar zou de taxi stil hebben stukgemaakt zodra iemand die flag omzet | server registreert het taximodel vlak voor de client 'm laat spawnen |
| MED | los_anticheat | Event-whitelist was gegenereerd vóór de 6 renzu-tuningscript-rewrites van de vorige sessie — hun events stonden niet onder spam-monitoring (whitelist is geen block/allow-list, dus geen false-kick risico, wel een blinde vlek) | `tools/generate_events.ps1` opnieuw gedraaid, 321 events uit 486 bestanden |
| HIGH | ps-mdt | Voertuigverzekering-check wees naar resource `m-Insurance` (bestaat hier niet) met een callback-export. De echte resource is `los_insurance`, met een directe (non-callback) export `hasVehicleInsurance(plate)`. Stond bovendien op `enabled = false` — dit was de "kentekencheck via ps-mdt" uit SERVER-OVERHAUL fase 5.5, die als afgerond stond maar nooit gebouwd bleek | doorverwezen naar los_insurance + aangezet. Registratie-check blijft uit: geen equivalent resource in dit project |
| LOW | ps-mdt | Traffic-stop alert (Wolfknight-integratie, nu inert want die resource draait hier niet) zette `dispatchCode` maar niet `code` → viel terug op "10-80" i.p.v. "10-11". Klassieke dispatchCode/code-valkuil | `code = '10-11'` toegevoegd, dode `description`/`firstStreet`-velden weg |
| MED | los_wipe | JSON-"vangnet"-snapshot legde bij inventories/properties alleen een **rijentelling** vast, nooit de inhoud — terwijl `config.wipe.inventories` zowel `players.inventory` als de volledige `ox_inventory`-tabel wipet. Bij een betwist verloren item was er dus niets om op terug te vallen | snapshot bevat nu ook `players.inventory`, de volledige `ox_inventory`-tabel en de `properties`-tabel |
| LOW/MED | los_wipe | De echte wipe-DELETE/UPDATE-statements waren als enige in deze codebase niet pcall-wrapped — één ontbrekende tabel (properties heeft hier al een DDL-geschiedenis) liet `performWipe` midden in de reeks sterven | elke stap los pcall-wrapped, logt expliciet MISLUKT + foutmelding i.p.v. de rest mee te slepen |
| LOW | ps-housing | `Config.RaidItem = 'police_stormram'` stond nergens geregistreerd of te koop — de raid-actie was sowieso nooit bruikbaar | item toegevoegd + in de politie-supply (renzu_jobs) |
| LOW | items.lua | `cokebaggy` stond dubbel gedefinieerd (zelfde patroon als de eerder opgeruimde stancerkit-dupe) | dode kopie weg |

### Bevestigd al goed (geen actie)

- los_billing (claimVehicle-plate-check bestaat al), los_insurance (alle drie eerder-gevonden bugs nog steeds gefixt), los_discord (geen dode listeners), los_hygiene (rates + model-disclaimer kloppen) — stuk voor stuk geverifieerd tegen de actuele code, niet alleen tegen de docs.
- ND_Police/ND_GunAnims/murderface-pets: alle fase-4-fixes nog intact na hercontrole; ps-dispatch/ps-policebridge-wiring klopt end-to-end voor alle 6 origin-events gecheckt.
- los_wanted/los_vehiclekeys/los_gangpeds/los_policebridge: alle vijf schoon.
- npwd_qbx_garages ↔ renzu_garage-koppeling, qbx_npwd-registratie, geen enkele npwd `getPlayerData`-aanroep met de oude raw-id-bug.
- md-drugs gang-gating (cocaine→mafia, crack→ballas, weed→families, heroin→**vagos**, niet aztecas) blijkt al volledig geïmplementeerd — BACKLOG #23 was stale, dit stond niet meer als "voorstel".
- ps-dispatch `isJobValid` matcht op zowel jobtype als jobnaam — de CLAUDE.md-valkuil "type vs naam" grijpt hier niet, alle geverifieerde callers zijn toch al correct.

### Nog open

| # | Sev | Wat |
|---|---|---|
| 57 | MED | **ND_GunAnims leest `inventory:weaponanims` mogelijk verkeerd** (`GetConvarInt` op een `"true"`-string-convar i.p.v. `GetConvarBool`). Bewust NIET blind gefixt: welke van de twee code-paden (event-gedreven via ox_inventory, of eigen polling) daadwerkelijk correct is kan alleen in-game bepaald worden, en de verkeerde kant op "fixen" had een werkende situatie zomaar kunnen breken. **Testplan:** trek een wapen, kijk of je een dubbele animatie ziet. |
| 58 | MED | **bcso/sasp zijn geregistreerde leo-jobs zonder bevoorradingsketen.** `renzu_jobs` heeft alleen een `police`-supply/kluis/kleedkamer; ND_Police's locker_rooms staat hardcoded op `groups = {"police"}`. Een agent op bcso/sasp passeert alle jobchecks maar kan nergens cuffs/zipties/shield/uniform krijgen. Waarschijnlijk bewust (alleen LSPD bemand) — navragen bij Tim. |
| 59 | LOW | **xt-robnpcs leest zijn eigen live cop-count** (`qbx_core:GetDutyCountJob`) i.p.v. `xt-prison`'s `GlobalState.copCount`, terwijl beide dezelfde soort telling bijhouden. Dormant (`requiredCops = 0`), maar zodra dat omhoog gaat kan de client-UI (die wél `xt-prison`'s telling leest) een ander getal tonen dan wat de server afdwingt. |
| 60 | — | **Vanilla qbx_*-resources nog niet gecontroleerd deze sessie** (busjob, garbagejob, recyclejob, scrapyard, towjob, truckerjob, newsjob, carwash, weed, vineyard, fireworks, lapraces, streetraces, diving, divegear, binoculars, qbx_hud, qbx_visuals, qbx_radialmenu, qbx_management, qbx_smallresources, qbx_pawnshop, qbx_storerobbery, qbx_houserobbery, qbx_bankrobbery, qbx_truckrobbery, qbx_customs, qbx_vehicles, qbx_vehiclesales, qbx_scoreboard, qbx_adminmenu, qbx_cityhall, qbx_spawn, qbx_seatbelt, qbx_idcard, qbx_chat_theme). Volgende golf. |

### Testplan voor Tim (aanvulling op sessie 7 aug)

1. **ps-housing toegang:** loop als speler B naar een huis/appartement van speler A (geen toegang) en klik "Enter". Verwacht: je wordt NIET naar binnen geteleporteerd, alleen een doorbell-melding. Laat speler A vervolgens de deurbel beantwoorden — nu moet B wel binnenkomen.
2. **ps-housing access-menu:** probeer als niet-eigenaar `addAccess`/`removeAccess` op andermans pand te forceren (zou hiervoor altijd doorgaan). Verwacht: geweigerd met "You are not the owner".
3. **NPWD telefoon:** open het telefoonmenu, tik op Garages en Mail. Verwacht: beide apps laden nu daadwerkelijk (voorheen: permanent leeg/error).
4. **md-drugs dealer:** wacht een rotatie uit (of verlaag `rotateMinutes` tijdelijk) en ga naar de NIEUWE locatie. Verwacht: de ped staat er ook echt, niet nog op de oude plek.
5. **ps-mdt verzekering:** trek een voertuigprofiel op van een auto met en zonder polis. Verwacht: toont nu echt Insured/Uninsured i.p.v. altijd "Valid".
6. **los_wipe:** niet in productie testen. Bij de eerstvolgende geplande wipe: controleer dat het snapshot-JSON-bestand nu ook inventory- en property-inhoud bevat, niet alleen tellingen.

---

## SESSIE 7 augustus 2026 — vervolg-controlepas (renzu + AI ambulance/taxi)

Tim was een week weg en meldde: renzu-scripts en AI-ambulance/AI-taxi werkten
niet goed. **Server nog steeds niet vanaf deze machine te draaien** (geen
FXServer-artifact, geen MySQL hier) — dit is wéér een statische pas, geen
runtime-bevestiging. Zes parallelle deelaudits (renzu_shops/clothes,
renzu_garage/vehicleshop, renzu_jobs/customs, de 7 kleine renzu tuning-
scripts, ND_Ambulance+los_aidoctor, los_aitaxi) tegen de bekende faalpatronen
uit HANDOVER.md §4, plus verificatie of de 5 commits van de vorige sessie
(taxi-spawn, garage-crash, ps-housing SQL, ambulance-revive, anticheat/
taxi-carjacking) echt compleet waren. Alles gefixt is `luac`-schoon en
gecommit (9 commits, één per logische fix — zie `git log`).

### Gefixt

| Sev | Resource | Wat | Fix |
|---|---|---|---|
| HIGH | renzu_shops | Shop-ped draaide niet mee met de speler (R8). `TASK_TURN_PED_TO_FACE_ENTITY` is een one-shot turn, geen continue look-at — werd maar één keer aangeroepen bij binnenkomst | herroepen elke near-tick (500ms) |
| HIGH | renzu_shops | Elk kassa/koop/stash-punt zonder ped was een 1×1m ox_target **boxzone met rotation=0.0**, terwijl geen enkele shop-config een heading meegeeft — stond bijna overal scheef (R3) | vervangen door sphere-zone (geen rotatie nodig) |
| HIGH | renzu_garage | `client/keys.lua:828` crashte op een undefined variabele (`vehicle` i.p.v. loopvariabele `v`) → scripterror bij elke wijziging van iemands `keys`-itemcount | typefout gefixt |
| HIGH | renzu_garage | Boot-thread kon crashen als `impound_garage` ontbreekt (`for k,v in pairs(impoundget)` had als enige van 6 queries geen `or {}`) | fallback toegevoegd |
| HIGH | renzu_customs | Society-payout (tuning betalen vanuit/naar de shopkas) riep `GetAccount`/`AddMoney`/`RemoveMoney` op resource `qb-management` — bestaat niet. Renewed-Banking heet zelf zo en exporteert lowercase `getAccountMoney`/`addAccountMoney`/`removeAccountMoney`. Klant betaalde, shop-kas kreeg nooit iets | juiste resource/exportnamen; job-account wordt nu ook automatisch aangemaakt bij eerste gebruik (`CreateJobAccount`) |
| MED | renzu_customs | `societyTransfer` gaf altijd `true` terug zolang de pcall niet crashte, ook als `removeAccountMoney` `false` gaf wegens te weinig saldo | echte returnwaarde doorgegeven |
| MED | renzu_jobs | `vehicle_interaction`-menu (impound, hijack, repair, ...) had 11 dode knoppen zonder `unimplemented = true`, in tegenstelling tot `citizen_interaction` ernaast | zelfde vlag erbij |
| LOW | renzu_jobs | Kitchen-recept `burger` vroeg om item `meat`, dat niet bestaat — permanent oncraftbaar | → `burgerpatty` (bestaat al, betere match) |
| MED | los_aitaxi | `SetPedFleeAttributes(driver, 0, false)` — clear-flag stond op `false`, dus het wiste niks. De anti-vlucht-fix van vorige sessie leunde alleen op de andere 4 calls | clear=true |
| LOW | los_aitaxi | Geen timeout op de wachtlus na `CreateVehicle`; bij een geweigerde spawn (entity-cap, of ooit `los_anticheat` block-unregistered-vehicles) hing dit voor altijd | 5s timeout → `rideFailed` |
| MED | ND_Ambulance | `canUseWeapons` is overal gefixt, maar `los_anticheat`'s `ExpectHeal` en `los_aidoctor`'s ride-cancel liepen alleen via EMS-treat/AI-dokter, niet via txAdmin-heal/admin-menu-revive/self-respawn | die twee paden triggeren nu ook `ND_Ambulance:playerRevived` |
| **HIGH (security)** | renzu_bag | `buybag` vertrouwde een door de client meegestuurde tabel inclusief **prijs en slots** — iedereen kon zelf het event aanroepen met `price = 0` en een willekeurig grote bag krijgen | client stuurt alleen een index, server zoekt de entry zelf op in `Config.item` |
| MED | items.lua | `fakeplate` (renzu_garage) en `cloth` (renzu_jobs bandage-recept) werden gebruikt maar stonden niet geregistreerd → stille no-op | beide toegevoegd |
| LOW | items.lua | `stancerkit`/`enginegago`/turbo-items stonden dubbel gedefinieerd (kalere kopie zonder image, overschreven door een rijkere verderop) | dode kopie verwijderd |
| LOW | economie | `turboultimate` + 6 nitro-items bestonden als item maar waren nergens te koop | toegevoegd aan renzu_shops MechanicSupply |

### Bevestigd al goed (geen actie), inclusief verificatie vorige-sessie-fixes

- renzu_clothes kassa/pasgoed-fix (vorige sessie) — correct.
- los_aitaxi spawn-logica, pathfinding (geen herhaalde `TaskVehicleDriveToCoordLongrange`), modelnamen, geen verzonnen coördinaten, on-duty check, npwd-contactregistratie — allemaal correct.
- renzu_garage `00_migrate.lua` (impound-kolom), doorslockstate-check, proefrit-timing, sleutel-items via `los_vehiclekeys` — correct.
- ND_Ambulance `canUseWeapons`-fix dekt nu echt alle 5 revive-paden; `stop qbx_medical` staat er; `signalSent` is server-naar-server; `los_aidoctor` config heeft `return Config`; prijzen kloppen met Tims besluit.
- De 7 kleine renzu tuning-scripts (motels/stancer/turbo/nitro/itemback/bag/engine): geen crash-bugs, `CreateUseableItem`-signatuur overal correct.
- renzu_jobs restraints staan niet in het menu (blijven items); geen statebag-botsing met ND_Police (renzu_jobs raakt `handsUp`/`cuffed` nergens aan).

### Nog open — needs Tim of vergt in-game verificatie

| # | Wat |
|---|---|
| 53 | **renzu_shops-peds spawnen nog steeds pas laat / op een onduidelijke plek** (het andere deel van R8 — alleen de "draait niet mee"-helft is deze sessie gefixt). Niet aangepakt: vergt weten wélke shops te laat spawnen, en dat is alleen in-game te zien. |
| 54 | **`cloth`-item (nieuw, voor het bandage-recept) staat nog nergens te koop.** Zelfde categorie als de al bekende ontbrekende-verkooppunten. |
| 55 | **`los_anticheat` staat nog op dry-run** (zie #19) — de ND_Ambulance revive-pipeline-fix van deze sessie is dus nu nog onzichtbaar in de praktijk; wordt pas relevant als dry-run uit gaat. |
| 56 | **De renzu_bag-fix is alleen tegen de huidige `buybag`-payload getest via codelezen, niet in-game.** Testplan hieronder. |

### Testplan voor Tim

1. **renzu_shops ped-tracking:** loop bij een shop-ped heen en weer terwijl je binnen ~12m blijft. Verwacht: hij blijft je aankijken, niet bevroren in één richting.
2. **renzu_shops target-zones:** loop naar een kassa/koop-punt vanuit een andere hoek dan pal ervoor. Verwacht: de ox_target-optie verschijnt zodra je binnen bereik bent, ongeacht vanuit welke kant je nadert.
3. **renzu_garage:** laat je `keys`-itemcount wijzigen (oppakken/laten vallen) terwijl je bij een voertuig staat dat niet van jou is. Verwacht: geen script error in F8.
4. **renzu_customs:** laat een monteur *on duty* gratis (van de zaak) tunen bij zijn eigen shop. Check daarna het shop-saldo (ps-mdt of admin) — moet gedaald zijn met de kosten. Doe ook een normale klant-betaling en check dat het shop-saldo daarna gestegen is.
5. **renzu_jobs:** open het interactiemenu bij een voertuig als politie/monteur/EMS — de oude 11 knoppen (impound, hijack, repair...) mogen niet meer verschijnen. Probeer het `bandage`-recept bij het Police Workbench (vergt `cloth`, nog niet te koop — geef jezelf er admin een paar om te testen).
6. **los_aitaxi:** bel 4747, stap in. Verwacht: de chauffeur rijdt weg zonder te schrikken/vluchten (dit was eerder de carjacking-false-positive; nu getest of de fix ook echt klopt).
7. **AI-ambulance:** ga dood, laat een **txAdmin-heal** of **admin-menu revive** doen (niet EMS). Verwacht: je kan meteen weer een wapen pakken (canUseWeapons), en als er toevallig een AI-ambulance onderweg was, keert die om.
8. **renzu_bag:** koop een bag normaal via de winkel bij `421.69, -809.66, 29.49`. Verwacht: werkt zoals voorheen, prijs/slots kloppen met het menu.
9. **Economie:** check `turboultimate` en de nitro-items in de MechanicSupply-shop — moeten nu gewoon in de lijst staan.

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
| R3 | ~~HIGH~~ | ~~renzu_shops werkt bijna niet; ox_target staat verkeerd / te ver.~~ **Root cause gevonden (sessie 7 aug):** ongeroteerde boxzones zonder heading-data. **GEFIXT** → sphere-zones, zie sessie 7 augustus bovenaan dit bestand. | breuk |
| R4 | **HIGH** | **ps-housing werkt niet.** Ziet álle appartementen, kan met de lift naar appartementen die hij niet bezit. | breuk |
| R5 | **HIGH** | **AI-dokter (los_aidoctor) komt niet opdagen** als je down bent. Hangt deels aan R2 (death-flow). | breuk |
| R6 | **HIGH** | **AI-taxi (los_aitaxi) werkt niet + staat niet in npwd-contacten.** | breuk |
| R7 | MED | **Black market moet via de NPWD DarkChat/IRC-app** (Tim: "dit is de black market app van npwd"), NIET via SMS 4040. Nu: md-drugs TravellingMerchant gebruikt `npwd:onMessage`/`emitMessage` op een nummer. NPWD heeft een **DarkChat**-app (anonieme IRC-chat) — daar moet de black market naartoe. Te doen: onderzoek NPWD DarkChat server-API en herbedraad md-drugs erheen. Taxi blijft een **contact** (AI taxi, nr 4747) — dat is los van de black market. | ontwerp |
| R8 | MED | **Shop-peds spawnen te laat en op onbekende plek** (clothes, vehicleshop) — **nog open, zie #53**. ~~renzu_shops-ped draait niet mee met de speler~~ **GEFIXT (sessie 7 aug)**: turn-task werd maar één keer gegeven, nu elke near-tick. | breuk |
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

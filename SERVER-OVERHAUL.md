# Los Balos RP — Server Overhaul Specification

> **Voor Tim:** plak de KICKOFF PROMPT (sectie 1) in Claude Code. Daarna hoef je per fase alleen
> nog `Start FASE 3` te typen. Claude leest de rest zelf uit dit bestand. Dat scheelt enorm veel credits.

---

## 0. GROUND TRUTH — geverifieerde feiten over deze server

Dit is gecontroleerd op de echte filesystem. Claude: neem dit als waarheid aan, maar verifieer
altijd opnieuw voordat je een bestand aanpast.

**Server root:** `D:\New folder\Qbox_630A49.base`
**Framework:** Qbox (qbx_core) + ox_lib + ox_inventory + ox_target + oxmysql
**Game build:** `sv_enforceGameBuild 3258`
**Database:** MySQL `qbox` op `127.0.0.1`, user `qboxuser`

### Resource-indeling (echt aanwezig)

- `resources/[qbx]/` — qbx_core, qbx_hud, qbx_visuals, qbx_vehiclekeys, qbx_taxijob,
  qbx_jewelery, qbx_radialmenu, qbx_management, qbx_medical, qbx_smallresources,
  qbx_pawnshop, qbx_storerobbery, qbx_houserobbery, qbx_bankrobbery, qbx_truckrobbery,
  qbx_customs, qbx_vehicles, qbx_vehiclesales, qbx_scoreboard, qbx_adminmenu, qbx_cityhall,
  qbx_spawn, qbx_seatbelt, qbx_idcard, qbx_weed, qbx_diving, qbx_divegear, qbx_binoculars,
  qbx_busjob, qbx_carwash, qbx_garbagejob, qbx_recyclejob, qbx_scrapyard, qbx_towjob,
  qbx_truckerjob, qbx_newsjob, qbx_lapraces, qbx_streetraces, qbx_vineyard, qbx_fireworks,
  qbx_chat_theme
- `resources/[ox]/` — ox_lib, ox_inventory, ox_target, ox_doorlock, ox_fuel, oxmysql
- `resources/[ps]/` — ps-dispatch, ps-housing, ps-mdt, ps-realtor, ps_lib, fivem-freecam
- `resources/[npwd]/` — npwd, qbx_npwd
- `resources/[npwd-apps]/` — npwd_qbx_garages, npwd_qbx_mail
- `resources/[standalone]/` — ND_Police, ND_Ambulance, ND_GunAnims, renzu_shops,
  renzu_clothes, renzu_garage, renzu_vehicleshop, renzu_jobs, renzu_customs, md-drugs,
  community_bridge, illenium-appearance, Renewed-Banking, Renewed-Weathersync,
  scully_emotemenu, xt-prison, safecracker, mhacking, ultra-voltlab, vehiclehandler,
  bob74_ipl, mana_audio, MugShotBase64, screencapture, loadscreen
- `resources/[assets]/` — mnr_cayo, NT_stoplichten, phmc, props
- `resources/[voice]/` — pma-voice, mm_radio

### KRITIEKE BEVINDINGEN (dit is waarom dingen stuk zijn)

1. **`ensure [ps]` ONTBREEKT VOLLEDIG in `server.cfg`.** ps-dispatch, ps-mdt, ps-housing,
   ps-realtor en ps_lib draaien dus helemaal niet. Dat is de hoofdoorzaak van "ps-housing werkt
   niet" en "geen dispatch meldingen". Dit MOET fase 1 zijn — niet refactoren wat niet draait.
2. **Geen git repository.** Er is geen enkele undo-mogelijkheid. `git init` + baseline commit is
   verplicht vóór welke wijziging dan ook.
3. **Geen escrow.** Alle renzu_* scripts en md-drugs zijn plain Lua, geen `.fxap`, dus volledig
   aanpasbaar. renzu_clothes en renzu_jobs zijn al herschreven voor qbx_core/ox_lib.
4. **Verwijderde qbx resources.** `qbx_police`, `qbx_ambulancejob`, `qbx_garages`,
   `qbx_vehicleshop`, `qbx_drugs`, `qbx_density`, `qbx_mechanicjob`, `qbx_properties` staan
   ALLEEN nog in `cache/files/` (oude download-cache), NIET in `resources/`. Ze zijn bewust
   vervangen door ND_Police, ND_Ambulance, renzu_garage, renzu_vehicleshop, md-drugs.
   Verwijs nooit naar deze resources in nieuwe code. Exports/events ernaar zijn dode links.
5. **Dubbele ensure.** `ensure [standalone]` start ND_Police en ND_Ambulance al; onderaan
   server.cfg staan ze nóg een keer. Opruimen.
6. **Laadvolgorde fout.** `ensure [npwd-apps]` staat vóór `ensure npwd` en `qbx_npwd`.
   Apps moeten ná de phone core starten.
7. **Alle security convars in `misc.cfg` staan uitgecommentarieerd** en `sv_scriptHookAllowed`
   ontbreekt volledig in server.cfg. Gratis anti-cheat winst die nu niet wordt gepakt.
8. **`inventory:accounts ["money"]`** in `ox.cfg` — er is dus géén `black_money` account
   geregistreerd bij ox_inventory. Dirty money moet expliciet ontworpen worden (item
   `markedbills` met metadata, óf account toevoegen). Nu bestaat het niet consistent.
9. `qbx_taxijob` bestaat → AI-taxi moet checken op job `taxi` on duty.
10. `qbx_jewelery` bestaat → dat is de juwelier-overval locatie die hergebruikt moet worden.

---

## 1. KICKOFF PROMPT — dit plak je als eerste bericht

```
Je bent senior FiveM/Qbox developer. Je werkt in D:\New folder\Qbox_630A49.base — een
draaiende Qbox RP-server ("Los Balos RP"). Dit is een groot, meerdaags refactor-traject.

Lees eerst SERVER-OVERHAUL.md in de server root volledig. Dat bestand bevat de geverifieerde
staat van de server en de volledige opdracht, opgedeeld in fases.

Doe in DEZE sessie alleen het volgende, in deze volgorde:

1. Maak een veiligheidsnet:
   - `git init`, een `.gitignore` (negeer cache/, db/, logs, *.log, sv_licenseKey mag NIET
     gecommit worden — haal hem uit server.cfg en zet hem in een niet-getrackte include-cfg).
   - Baseline commit "baseline: server as-is before overhaul".
   Vraag mij eerst om bevestiging voordat je git init draait.

2. Maak een CLAUDE.md in de root met: architectuur, resource-map, welke resources vervangen
   zijn door wat, de standing rules uit sectie 2 van SERVER-OVERHAUL.md, en de conventies
   (ox_lib, ox_target, ox_inventory, qbx_core exports) zoals ze in deze codebase ECHT worden
   gebruikt — lees daarvoor 3-4 bestaande resources en kopieer hun stijl.

3. Voer FASE 0 uit uit SERVER-OVERHAUL.md (de audit). Lever het resultaat op als
   AUDIT.md + BACKLOG.md.

Doe verder NIETS. Geen refactors, geen nieuwe scripts, geen config-wijzigingen buiten
fase 0. Aan het eind geef je mij een korte samenvatting en de top 10 blockers.
```

---

## 2. STANDING RULES — gelden voor élke fase

Claude: hou je hier altijd aan, ook als een fase-prompt het niet herhaalt.

1. **Verifiëren vóór wijzigen.** Lees het bestand echt. Nooit code schrijven op basis van hoe
   een resource "meestal" werkt. Deze server is fors aangepast.
2. **Eén fase per sessie.** Nooit meerdere fases tegelijk starten. Klaar = getest + gecommit.
3. **Commit per logische stap** met een duidelijke message. Nooit één mega-commit.
4. **Nooit een core-bestand herschrijven** (qbx_core, ox_inventory, ox_lib, npwd core) zonder
   het eerst voor te leggen. Bouw liever een bridge/wrapper-resource ernaast.
5. **Geen dode verwijzingen.** Refereer nooit aan qbx_police/qbx_ambulancejob/qbx_garages/
   qbx_vehicleshop/qbx_drugs — die bestaan niet meer (zie sectie 0, punt 4).
6. **Server is autoriteit.** Geld, items, health, positie, jobs: alle mutaties server-side, met
   validatie. Client stuurt intentie, nooit resultaat.
7. **Eerlijk rapporteren.** Als iets niet werkt, niet getest is, of je het niet kunt oplossen:
   zeg dat expliciet. Nooit "done" claimen zonder verificatie. Zet onopgeloste dingen in
   BACKLOG.md.
8. **Prestatiedoel realistisch:** idle < 0.01ms, actief piek < 0.5ms per resource. "Alles 0.00ms"
   bestaat niet — een resource die iets doet, kost tijd. Optimaliseer waar het meet.
9. **Geen nieuwe dependency** toevoegen zonder te melden waarom, en alleen als het al in de
   stack past (ox_*, qbx_*, ps_lib).
10. **Elke externe GitHub-resource** die geconverteerd wordt: strip ESX/QB/ND/standalone
    branches volledig, hou alleen het Qbox-pad over. Geen `if Config.Framework ==` ketens.
11. **Locale:** server is EN/NL. Nieuwe UI-strings via ox_lib locales, met `en.json` en `nl.json`.
12. **Nooit de database wipen of ALTER draaien** zonder mijn expliciete akkoord en een dump.

---

## 3. FASE 0 — Audit (eerst, altijd)

Doel: weten wat er stuk is vóór je iets aanraakt. Lever `AUDIT.md` en `BACKLOG.md` op.

1. Parse `server.cfg`, `ox.cfg`, `misc.cfg`, `permissions.cfg`. Maak een lijst van elke resource
   in `resources/` en of hij daadwerkelijk gestart wordt. Markeer alle niet-gestarte resources.
2. Lees elke `fxmanifest.lua`. Bouw een dependency-graaf. Meld:
   - dependencies die niet bestaan in deze server
   - verkeerde laadvolgorde
   - resources met `game 'gta5'` conflicts of oude `fx_version`
3. Grep de hele `resources/` op verwijzingen naar de verwijderde resources uit sectie 0 punt 4
   (`qb-policejob`, `qbx_police`, `qbx_ambulancejob`, `qbx_garages`, `qbx_vehicleshop`,
   `qbx_drugs`, `qb-garages`, `qb-ambulancejob`). Elke hit = kapotte integratie. Lijst maken.
4. Check `community_bridge`: welke resources gebruiken het echt, en welke modules ervan zijn
   dood gewicht? md-drugs is de vermoedelijke gebruiker.
5. Check ox_inventory `data/items.lua` (+ eventuele extra item-files) tegen alle
   item-referenties in scripts. Lijst alle items die code gebruikt maar niet geregistreerd zijn,
   en alle geregistreerde items zonder image.
6. Check `ps-dispatch`: welke events verwacht het, en welke resources vuren die af.
7. Client-side risico-scan: `RegisterCommand` client-side, `TriggerServerEvent` zonder
   server-side validatie, client-side geld/item mutaties. Top 25 gevaarlijkste.
8. Lijst alle SQL-bestanden die nooit geïmporteerd lijken (tabellen die code verwacht).

**Output `BACKLOG.md`:** elk gevonden probleem als item met `[FASE-x]` tag, severity
(BLOCKER/HIGH/MED/LOW), bestand+regel, en 1 zin fix-richting. Dit wordt de werklijst voor de
rest van het traject en wordt elke fase bijgewerkt.

---

## 4. FASE 1 — Fundament & server.cfg (hoogste prioriteit)

Zonder dit werkt de helft van de rest sowieso niet.

1. **`ensure [ps]` toevoegen** aan server.cfg, op de juiste plek in de laadvolgorde
   (na qbx_core en ox_*, vóór resources die dispatch/mdt gebruiken). ps_lib moet vóór de
   andere ps-resources.
2. **Laadvolgorde herstellen:** `npwd` en `qbx_npwd` vóór `[npwd-apps]`.
3. **Dubbele `ensure ND_Police` / `ensure ND_Ambulance` weghalen** (zitten al in `[standalone]`).
4. **ps-housing crash-onderzoek.** Start hem, lees de fout, fix hem écht (niet uitzetten).
   Verwacht: ontbrekende SQL-tabellen, ps_lib-versie, of qb-core bridge-calls die qbx niet
   levert. Voer benodigde SQL uit na mijn akkoord.
5. **SQL-audit:** elke resource die een tabel verwacht → check of hij bestaat in de `qbox`
   database. Lever één `install/missing_tables.sql` op, draai hem pas na akkoord.
6. **Security convars aanzetten** in server.cfg/misc.cfg:
   - `sv_scriptHookAllowed 0`
   - `set sv_filterRequestControl 3`
   - `set sv_enableNetworkedScriptEntityStates false` (test op sync-regressies)
   - `set sv_enablePhoneExplosions false`
   - `set sv_enableNetworkedSounds false`
   - `set sv_requestParanoia 1`
   - OneSync infinity aan, entity lockdown overwegen (`relaxed` eerst, niet meteen `strict` —
     dat breekt scripts die client-side spawnen; documenteer wat breekt)
   - `sv_licenseKey` uit de gecommitte cfg halen.
7. Server opstarten, **volledige console-log schoon maken**: elk `SCRIPT ERROR`, elke warning,
   elke ontbrekende dependency. Doorgaan tot de startup-log foutloos is. Dit is de
   acceptatietest van fase 1.

---

## 5. FASE 2 — Anti-cheat (server-side authority)

**Eerlijke verwachting die je aan mij moet communiceren:** een custom client-side anti-cheat
houdt betaalde/kernel-level menu's niet tegen — die draaien onder jouw detectie. Wat wél
werkt en permanent is: server-side autoriteit, event-validatie, convar-hardening en logging,
zodat een cheat wel kan injecteren maar niets kan bereiken dat blijvend is. Bouw dáárop.
Client-side heuristiek is een bonus-laag, geen fundament. Zeg dit expliciet in je plan.

Nieuwe resource: `los_anticheat` (server-authoritative, modulair).

1. **Event firewall.** Inventariseer elk `RegisterNetEvent` in de hele server. Bouw een
   whitelist met per event: verwachte argument-types, rate-limit, en of de speler in een
   geldige state is. Alles buiten de whitelist → log + kick. Lever ook een rapport van events
   die nu volledig onbeveiligd zijn.
2. **Geld-autoriteit.** Grep élke plek waar geld wordt toegevoegd. Alles moet door één
   server-side `AddMoney` gateway met reden, bron-resource en plafond per transactietype.
   Client-getriggerde geld-events zonder server-side bewijs → verwijderen.
3. **Inventory-autoriteit.** Idem voor ox_inventory: geen item kan ontstaan zonder een
   server-side bron (shop/craft/loot/job-payout) die het bedrag zelf bepaalt.
4. **Vehicle-autoriteit.** Registreer server-side elk voertuig dat een script spawnt. Voertuigen
   die verschijnen zonder registratie → flag + delete. Werk samen met qbx_vehicles.
5. **Movement/damage heuristiek** (server-side, op basis van state bags en periodieke checks):
   teleport-afstand per tick, snelheid buiten voertuig, val zonder schade, health/armor die
   omhoog gaat zonder bron, damage hoger dan het wapen kan doen. Geen instant ban — score.
6. **Scoring + auto-ban engine.** Elke anomalie geeft punten met een decay. Drempels:
   log → warn admin → kick → ban. Ban opslaan in DB met bewijs (welke checks, waardes,
   timestamps). Discord-webhook per flag.
7. **Admin-review UI** via ox_lib: flags bekijken, false positives markeren (die feedback
   verlaagt de score-weging van die check).
8. Adviseer mij daarnaast één bewezen externe anti-cheat als tweede laag, met voor/nadelen.
   Bouw geen namaak van iets dat al goed bestaat.

**Niet doen:** `GetNumResources()` mismatch-checks en thread-timing detectie als
hoofdverdediging — dat is trivially bypassable en geeft false positives. Alleen als
scoringssignaal met laag gewicht, of weglaten.

---

## 6. FASE 3 — Shops, kleding & economie

1. **renzu_shops**
   - Kooppunt van een shop: **geen ped**, alleen een losse `ox_target` zone.
   - Shop-NPC's: fix ped-rotatie zodat ze meedraaien met de speler (kopieer de werkende
     implementatie uit renzu_vehicleshop / renzu_garage — die doen dit al goed).
   - Assortiment realistisch maken: **geen mes of taser in Ammunation**. Loop élke shop-entry
     na op logica en prijs.
   - Alle legale items uit md-drugs (zaadjes, gereedschap, etc.) naar de tool shop.
   - Items afstemmen op ND_Police en ND_Ambulance (de juiste item-namen die díe scripts
     verwachten, niet de qbx_police/qbx_ambulancejob namen).
2. **renzu_clothes**
   - Terug naar **één kassa per winkel**. Kleding kiezen mag overal in de winkel, afrekenen
     gebeurt op één punt. Herstel de oorspronkelijke checkout-flow.
   - Volledige vanilla-kleding-audit: alle categorieën aanwezig, correct gecategoriseerd
     (geen broeken onder shirts), per geslacht kloppend.
   - **Fix de ontbrekende vanilla clothing images** (waarschijnlijk een pad/naming mismatch
     in de NUI — onderzoek eerst hoe de images geladen worden).
   - Realistische prijzen per categorie (t-shirt ≠ pak ≠ horloge).
   - **Sieraden eruit** → naar de nieuwe juwelier.
3. **Juwelier**: nieuwe renzu_clothes-shop op de locatie van de `qbx_jewelery` overval, met
   alle sieraden/accessoires. De overval moet blijven werken; zorg dat winkel en overval
   elkaar niet in de weg zitten (winkel dicht tijdens overval).
4. **Economie-rebalance server-breed.** Maak eerst één `ECONOMY.md` met het model
   (uurloon per job, prijsniveaus, drugs-marges, verzekeringspremies) en leg dat aan mij voor
   vóór je waardes doorvoert. Daarna alle job-payouts, shopprijzen en drugsprijzen aanpassen
   volgens dat model. Doel: geen grind, wel schaarste.
5. **ox_inventory item-audit:** elk item dat een script gebruikt bestaat, heeft correct gewicht,
   image, en `client.export` waar nodig. Lijst met ontbrekende images oplossen of melden.
6. **Externe resources converteren naar puur Qbox** (ESX/QB/ND-paden volledig strippen):
   - `s4t4n667/s4t4n667_moneywash` — toegang alleen voor renzu_shops eigenaren, via een
     sleutel/permissie uit het management-menu.
   - `s4t4n667/s4t4n667_elevators` — koppelen aan ps-housing appartementen.
   - `Coffeelot/cw-crafting` — volledig op ox_inventory/qbx.
7. **Dirty money ontwerpen.** Er is nu geen `black_money`. Kies één consistent model
   (aanbeveling: item `markedbills` met bedrag-metadata, want ox_inventory accounts zijn hier
   op `["money"]` gezet) en pas ALLE illegale inkomsten daarop aan: drugs, overvallen,
   chopshop, rob-npcs, cayo crates. Alleen moneywash zet het om naar clean.

---

## 7. FASE 4 — Gangs, drugs & illegale activiteiten

1. **md-drugs**
   - Legale spullen → renzu_shops tool shop. Illegale spullen → de md-drugs NPC.
   - NPC krijgt een **roterende locatie**; spelers krijgen die via NPWD "black market" als
     **straatnaam/omschrijving**, niet als coördinaten.
   - **Plukken mag iedereen. Verwerken alleen gangs.** Toewijzing:
     Ballas, The Families, Marabunta Grande, Varrios Los Aztecas krijgen elk hun eigen
     verwerkbare drug; **cocaïne exclusief voor de mafia**. Config-driven, makkelijk uit te
     breiden.
   - community_bridge: uitzoeken wat md-drugs er écht van gebruikt, de rest niet laden.
     Als het weinig is: direct op qbx_core/ox_* zetten en de bridge-dependency slopen.
   - Het voertuig dat je bij een drugsrun krijgt moet player-owned zijn en volledig werken met
     qbx_vehiclekeys + renzu_garage (nu breekt de sleutel bij job-voertuigen).
   - Alle drugs-events → ps-dispatch meldingen naar politie.
2. **Junkies** (basis: `TheErrantVenture/gtzombies_qbx-V1.0.4a`, volledig ombouwen)
   - Zombies worden **junkies**: NPC's die drugs kopen via `ox_target`.
   - Elke speler kan klein verkopen aan junkies; gangs doen de bulk via md-drugs.
   - Aanvallen van een junkie → kleine drop drugs/geld.
   - Gedrag: schichtig, wankelend, onvoorspelbaar — maar **niet zomaar spelers aanvallen**.
     Alleen escaleren na provocatie of bij een lage random kans in specifieke zones.
   - Zwaar optimaliseren: geen dure loops, ped-culling op afstand, pool-limiet.
3. **renzu_jobs — gangs toevoegen**: Ballas, The Families, Marabunta Grande, Varrios Los
   Aztecas, Mafia, met grades en gang-interacties (ziptie, doorzoeken, meenemen).
   - **Cruciaal:** deze interacties mogen NIET botsen met ND_Police en ND_Ambulance.
     Onderzoek waar beide dezelfde keybind/target/state gebruiken en bouw één gedeelde
     "restraint state" die alle drie de resources respecteren. Interacties blijven behouden.
4. **`xT-Development/xt-robnpcs`** — alleen QBX, alle andere frameworks eruit. Realistische
   loot: kleine bedragen cash, soms een telefoon, eten/drinken. Geen wapens, geen jackpots.
   Cooldown per NPC en per speler, dispatch-melding bij getuigen.
5. **`stevoscriptsteam/stevo_chopshop`** — volledig Qbox, koppelen aan het dirty-money model
   en aan renzu_garage (gestolen voertuigen mogen niet in de garage van de dief belanden).
6. **`stevoscriptsteam/stevo_cayocrates`** — loot: ~$10.000 (dirty), één klein pistool, wat ammo.
7. **Scenario peds / gang-NPC's**: NPC-gangleden in hun eigen territorium herkennen spelers
   met de bijbehorende gang-job als vriendelijk, en schieten op wie die spelers aanvalt —
   zoals vanilla GTA. Ze vallen niet zomaar willekeurige spelers aan.
   Realiteitscheck: dit is met relationship groups te doen maar is fragiel bij hoge
   spelersaantallen — bouw het config-schakelbaar en meld eerlijk de beperkingen.

---

## 8. FASE 5 — Hulpdiensten, medisch & verzekering

1. **ND_Ambulance**
   - Bij neergaan **direct** een duidelijke UI in beeld: timer, wat er gebeurt bij respawnen,
     en expliciet dat je je items verliest. Niet pas na X seconden.
   - Volledig doorlopen op werking en performance.
   - Dispatch: ND_Ambulance krijgt nu géén ps-dispatch meldingen. Fixen.
2. **AI-dokter** (concept van `yukkunn611/siro_aidoctor`, opnieuw bouwen voor ND_Ambulance):
   revive door AI-NPC **alleen** als er 0 echte EMS-spelers on duty zijn. Kosten in rekening
   brengen via het billing-systeem (fase 7).
3. **ND_Police** volledig doorlopen: werking, performance, juiste items uit renzu_shops,
   dispatch-integratie.
4. **`s4t4n667/s4t4n667_lawmenu`** — Qbox-only, via ox_lib, aangepast op deze server.
5. **Verzekeringen** (concept van `Muhaddil/muhaddil_insurance`, praktisch herbouwen voor Qbox):
   - **Zorgverzekering én autoverzekering**, beide in de database, met premies en dekking.
   - Politie kan verzekering controleren via **ps-mdt** én via een **ox_lib radial menu**
     (kentekencheck op een voertuig, persoonscheck op een speler).
   - Onverzekerde spelers krijgen periodiek een **NPWD SMS van "de overheid"**: dat rijden
     zonder verzekering strafbaar is, en wat het kost als je gewond raakt of schade rijdt.
   - Koppeling met billing: onverzekerd = volledige rekening zelf betalen.
6. **`fruitmob/murderface-pets`** — Qbox-only. K9 exclusief voor politie-job, met werkende
   functies (zoeken/detectie) die aansluiten op ND_Police. Rest van de breeds als civiele
   huisdieren.
7. **Wanted-systeem**, config-driven:
   - 0 echte politiespelers → AI-politie functioneert volledig.
   - Weinig echte politiespelers → AI-politie spawnt wel, maar schiet niet.
   - Veel echte politiespelers → geen AI-politie.
   - Alle wanted-events naar ps-dispatch.
   - Als dit niet stabiel te bouwen is, zeg dat eerlijk en lever de simpelere variant.

---

## 9. FASE 6 — Voertuigen, sleutels & vervoer

1. **qbx_vehiclekeys → item-based.**
   - Sleutel is een echt ox_inventory item met metadata (kenteken, model).
   - Je krijgt de sleutel bij aankoop in renzu_vehicleshop.
   - Sleutel wordt ingenomen bij het wegzetten in renzu_garage, en teruggegeven bij uithalen.
   - Job/gang-voertuigen (o.a. md-drugs) krijgen een tijdelijke sleutel die werkt zonder dat
     het voertuig player-owned hoeft te zijn. Dit is nu kapot.
   - **NPC carjacking fixen:** wapen richten op een NPC in een auto → realistische reactie,
     afhankelijk van scenario en NPC-type: uitstappen en vluchten, óf gas geven en hard
     wegrijden. Nu werkt dit niet omdat renzu_garage/vehicleshop alle voertuigen locked en
     alles op "search for keys" staat. Onderzoek de lock-logica eerst.
2. **renzu_vehicleshop:** proefrit maximaal **60 seconden**, harde timeout, voertuig verdwijnt
   en speler wordt teruggezet.
3. **renzu_garage + NPWD garage-app:**
   - `npwd_qbx_garages` geeft errors → fixen en écht koppelen aan renzu_garage (niet aan het
     verwijderde qbx_garages).
   - De **locatie-knop doet nu niets**. Hij moet een waypoint zetten op de kaart naar de
     garage waar dat voertuig staat, plus een notificatie met garage-naam en status
     (in garage / buiten / in beslag genomen).
4. **`mooons9992/mns-aitaxi`:**
   - `/aitaxi` command volledig weghalen.
   - Integreren in NPWD als vast contact ("Downtown Cab Co.") dat je kunt bellen.
   - Alleen een AI-taxi sturen als er **0 spelers met job `taxi` on duty** zijn (qbx_taxijob).
   - Zwaar optimaliseren: geen permanente client-loop, alleen actief tijdens een rit.
5. **Impound** volledig laten kloppen tussen renzu_garage, ps-mdt en politie.

---

## 10. FASE 7 — HUD, visuals & systemen

1. **HUD.** qbx_hud is te kaal. Bouw hem uit (of vervang door een eigen HUD in de stijl van
   `Project-Sloth/ps-hud`, maar dan modern en Qbox-native):
   - Rechtsboven permanent: **job** en **cash/bank**.
   - Nette minimap-styling.
   - Instellingenmenu waarin spelers elementen aan/uit kunnen zetten.
   - Advies eerst: qbx_hud uitbreiden vs. ps-hud porten. ps-hud is oud; onderbouw je keuze.
2. **`renzuzu/renzu_hygiene`** — omzetten naar Qbox, statussen douchen/plassen/poepen
   toevoegen aan de HUD.
   - **Kritisch:** ALLE statussen langzamer laten aflopen, inclusief honger en dorst. RP boven
     survival-grind. Maak de decay-rates centraal configureerbaar.
3. **[ps] scripts** (draaien nu niet — zie fase 1):
   - `ps-housing`: crash fixen, werkend maken met Qbox, koppelen aan de lift-resource voor
     appartementen.
   - `ps-dispatch`: volledig doorlopen. Meldingen koppelen aan ND_Police, ND_Ambulance,
     md-drugs, junkies, chopshop, robnpcs, wanted-systeem en alle qbx-overvallen.
   - `ps-mdt`: koppelen aan NPWD, renzu_garage, impound en het verzekeringssysteem.
   - `ps-realtor` en `ps_lib`: werkend en up-to-date maken.
4. **Billing-systeem** (concept van `ars_billing`, nieuw bouwen voor Qbox):
   - Bedrijven/hulpdiensten kunnen rekeningen sturen; verzekering betaalt automatisch wat
     gedekt is.
   - Speler krijgt een UI: betalen, uitstellen, of weigeren — sommige rekeningen (boetes,
     medisch) zijn niet te weigeren.
   - **Anti-misbruik:** limieten per job/grade, maximumbedrag, logging, cooldown, en een
     admin-audit van verstuurde facturen.
   - Onbetaald → rente + NPWD SMS van een deurwaarder, oplopend.
5. **qbx_visuals:** de overdreven lichtreflectie fixen. Onderzoek eerst wat het veroorzaakt
   (timecycle modifiers, verkeerde `SetTimecycleModifier` stacking, of conflict met
   Renewed-Weathersync) voordat je waardes gaat gokken. Daarna optimaliseren.
6. **Monthly wipe:** script dat op de 1e van de maand draait. Wipet geld, inventories, en
   voertuigen/eigendommen (configureerbaar). **Characters, identiteiten en spelersaccounts
   blijven bestaan.** Vereisten: dry-run modus, automatische DB-dump vóór de wipe,
   aankondiging in-game en op Discord, en een handmatige admin-trigger. Draai nooit een echte
   wipe zonder mijn akkoord.

---

## 11. FASE 8 — Discord-integratie

Discord server ID: `1067817202578890802`

1. Bouw een Discord-koppeling in twee delen: een FiveM-resource (logging + rolcheck) en een
   los Node-botproces voor alles wat de Discord API vereist. Leg uit wat ik zelf moet doen
   (bot aanmaken in de developer portal, token, intents, permissies) — vraag mij nooit om een
   token in de chat te plakken; ik zet hem zelf in een `.env` die niet gecommit wordt.
2. **Rol-sync:** in-game gang/job ↔ Discord-rol, beide richtingen, met een interval-sync.
   Ballas-rol, Vagos-rol, politie, EMS, etc.
3. **Kanaalzichtbaarheid:** gang-kanalen alleen zichtbaar voor members van die gang
   (Ballas ziet geen Vagos-kanaal). Bot beheert de permissie-overrides.
4. **Logging naar Discord:** ps-dispatch meldingen (o.a. schietpartijen), NPWD-berichten,
   tickets, reports, facturen, anti-cheat flags, wipe-aankondigingen — elk naar zijn eigen
   kanaal, met rate-limiting zodat je niet in de Discord API-limiet loopt.
5. **Privacy-check:** log geen persoonsgegevens of tokens naar Discord. Beslis bewust wat
   publiek, wat staff-only is.

---

## 12. ACCEPTATIE — wanneer is het klaar

Een fase is pas af als:

- [ ] Server start met een **volledig schone console** — geen SCRIPT ERROR, geen warnings.
- [ ] `resmon 1` gecontroleerd: elke aangeraakte resource idle < 0.01ms, piek < 0.5ms.
      Uitschieters gedocumenteerd met reden.
- [ ] Handmatig testscenario doorlopen en beschreven in de samenvatting.
- [ ] Alle wijzigingen gecommit met duidelijke messages.
- [ ] BACKLOG.md bijgewerkt: afgeronde items af, nieuwe bevindingen erbij.
- [ ] Eerlijke lijst van wat NIET is gelukt of niet getest kon worden.

---

## 13. REALITEITSCHECKS — lees dit vóór je iets belooft

Claude: benoem deze punten actief richting mij in plaats van ze stilzwijgend te omzeilen.

1. **"Alles 0.00ms" bestaat niet.** Idle 0.00ms is haalbaar, actief nooit. Gebruik de doelen
   uit sectie 12.
2. **Waterdichte anti-cheat bestaat niet.** Zie fase 2. Server-side autoriteit is de echte
   verdediging; client-detectie is bijvangst.
3. **Dit past niet in één sessie.** Reken op meerdere lange sessies. Eén fase per keer.
4. **Externe GitHub-resources moeten eerst gedownload worden.** Ze staan nog niet op schijf.
   Zet ze in `_external/<naam>/` (niet in `resources/`) als referentie-bron, en bouw de
   Qbox-versie schoon opnieuw in `resources/[standalone]/`. Kopieer nooit blind.
5. **Testen kan ik alleen zelf.** Jij kunt geen FiveM-client draaien. Lever bij elke fase een
   concreet testplan dat ik kan uitvoeren, met wat ik precies moet zien.
6. **Sommige wensen kunnen conflicteren** (bv. scenario-peds + hoge speleraantallen +
   0.01ms). Als iets niet samengaat, zeg het en geef opties in plaats van een half werkend
   compromis.

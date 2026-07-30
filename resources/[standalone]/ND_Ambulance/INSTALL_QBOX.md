# ND_Ambulance — QBox (qbx_core) installatie

Dit script is omgebouwd naar **QBox-only**. De `bridge/framework/` map (ND, ESX, ox, qb, qbx)
is verwijderd; alle core-specifieke code staat nu in `shared/bridge.lua`.

## 1. Resource plaatsen

Map moet exact `ND_Ambulance` heten — de item-exports verwijzen naar die naam.

```
resources/[standalone]/ND_Ambulance
```

In `server.cfg`, na `qbx_core`, `ox_lib`, `ox_target` en `ox_inventory`:

```
ensure ND_Ambulance
```

## 2. Items toevoegen aan ox_inventory

Plak de inhoud van `_INVENTORY/items.lua` in je `ox_inventory/data/items.lua`, binnen de
bestaande `return { ... }`.

Items: `stretcher`, `defib`, `medbag`, `burndressing`, `splint`, `gauze`, `tourniquet`.

Geen van deze namen botst met de standaard qbx itemlijst. Het `bandage` item dat de medbag
gebruikt (`data/medbag.lua`) zit al standaard in ox_inventory.

## 3. Item-afbeeldingen

Kopieer alles uit `_INVENTORY/images/` naar `ox_inventory/web/images/`.

## 4. Jobs

`data/jobs.lua` staat op `{"ambulance"}` — de standaard qbx EMS job. Je kunt hier jobnamen,
gangnamen of job types (`"ems"`) zetten. Deze lijst bepaalt wie:
- blessures van levende spelers kan bekijken
- een brancard weer kan oppakken met `/stretcher`

## 5. Voertuigen

`data/vehicles.lua` verwacht `ambulance` (basisgame) en `emsswift` (uit de MRSA pack).
Heb je die pack niet, haal `emsswift` er dan uit of vervang hem door je eigen ambulance model.

## 6. Optionele resources

| Resource | Waarvoor | Zonder deze resource |
|---|---|---|
| `ps-dispatch` | noodoproep van spelers (distress signal) | fallback: alle spelers met een EMS job uit `data/jobs.lua` krijgen een ox_lib melding + tijdelijke blip (3 min) |
| `spawnmanager` | eerste spawn bij join | wordt overgeslagen; zie `spawnmanagerFirstSpawn` in `data/death.lua` |
| `ModernHUD` / `nearest-postal` | postcode in de noodoproep | alleen straat + zone |

## 7. Let op: overlap met `qbx_medical` / `qbx_ambulancejob`

Beide hebben hun eigen death-, injury- en revive-systeem. Draai je die naast ND_Ambulance,
dan vecht je om dezelfde `isdead` metadata en krijg je dubbele deathscreens. Kies er één.

## Wat er is gefixt t.o.v. de originele qbx bridge

- Metadata werd weggeschreven als `isDead` terwijl qbx `isdead` gebruikt. Daardoor wist geen
  enkele andere resource dat de speler dood was, werkte de `canUseWeapons` statebag niet, en
  las het script zijn eigen waarde nooit terug.
- `Bridge.notify` gaf `description` door als titel en `title` als omschrijving — die stonden omgedraaid.
- Het `/revive` commando reviveerde de admin die het typte in plaats van de opgegeven speler.
- `/stretcher` crashte: er werd `player.groups` uitgelezen, een NDCore-veld dat op QBox niet
  bestaat. De jobcheck stond bovendien omgekeerd (alleen spelers *zonder* EMS job kwamen erdoor).
- `client/**` in de fxmanifest laadde `client/modules/death.lua` als gewoon client script én
  nog eens via `lib.load`, waardoor elk sterfgeval dubbel werd afgehandeld.
- Op login werd `ND:characterLoaded` afgewacht, een ND_Core event. Op QBox betekende dat een
  speler die dood uitlogde weer levend inlogde.
- Uitloggen tijdens CPR liet de andere speler in een vastgelopen CPR-status achter.
- De noodoproep ging alleen naar `ND_MDT`.

## Ronde 2: het deathsysteem werkte helemaal niet

Symptomen: je bleef na doodgaan op de grond liggen, er kwam geen deathscreen of respawntimer,
`R` respawnde direct en oneindig vaak, en de noodoproep gaf nergens een melding.

- `client/main.lua` wachtte nog op de ND_Core events `ND:playerEliminated` en `ND:revivePlayer`,
  terwijl `client/modules/death.lua` en `shared/bridge.lua` `ND_Ambulance:...` versturen. Gevolg:
  **geen enkele** doodgaan- of revive-handler liep. Geen deathscreen, geen timer, en na een revive
  bleef je lokaal "dood" (statebags, geblokkeerde acties, deathanimatie in een loop).
- `Teleport()` zette `FreezeEntityPosition(ped, true)` en haalde dat er nooit meer af — na respawnen
  of behandeling in het ziekenhuis stond je vast op je plek. Er zit nu ook een timeout op het
  wachten op collision, zodat je niet bevriest als de map niet inlaadt.
- De respawn keybind las `state.timeSinceDeath or 0`. Was die niet gezet (dus altijd, want de
  `eliminated` state werd nooit bereikt), dan slaagde de timercheck meteen. Daarom kon je direct
  en herhaaldelijk respawnen. Nu is `timeSinceDeath` verplicht, moet je echt `eliminated` zijn,
  en blokkeert een flag herhaald indrukken.
- De keybindletter voor de UI werd opgehaald met `GetControlInstructionalButton` direct na
  `lib.addKeybind`, voordat de game de toets kende — dat gaf een lege string, dus "PRESS  TO
  RESPAWN". Wordt nu lazy opgehaald met `data/death.lua` als fallback.
- Na een succesvolle defibrillator bleef de speler onsterfelijk en onbeschadigbaar (dat zet de
  `eliminated`-loop aan en niks zette het terug), waardoor je nooit meer kon doodbloeden.
- De doodbloed-check stond op `deathState == "down"`, een state die niet bestaat, en de
  tijdsvergelijking stond omgekeerd (`timer - nu` i.p.v. `nu - timer`).
- De noodoproep deed letterlijk niets zonder `ps-dispatch`, en de verzender kreeg nooit
  bevestiging. Nu: bevestiging voor de verzender, fallback naar melding + blip voor EMS, en een
  serverlog met hoeveel EMS'ers bereikt zijn.
- De UI-teksten bevatten `\n` maar de CSS had geen `white-space`, dus alles plakte op één regel.
- `spawnmanager`: het script kaapte `setAutoSpawnCallback`, wat de apartment/last-position spawn
  van qbx kon overrulen. Autospawn wordt nu alleen uitgezet (zodat je bij doodgaan niet automatisch
  respawnt); de eerste spawn overnemen is opt-in via `spawnmanagerFirstSpawn`.

### Losse fouten die onderweg opvielen

- `server/treatment.lua` gebruikte `inventory.id` in een functie waar die variabele niet bestaat —
  elke behandeling van een *andere* speler crashte daarop. Er zit nu ook een afstandscheck op.
- `server/medbag.lua` vergeleek `item == medbag` (ongedefinieerde variabele i.p.v. de string
  `"medbag"`), waardoor het medbag-gewicht altijd 0 bleef. En `while not DoesEntityExist and ...`
  riep de functie niet aan, dus de wachtlus deed niets.
- `client/cpr.lua` gaf geen ped mee aan `IsEntityPlayingAnim`, waardoor de CPR-animatie elke
  500 ms opnieuw begon.

## Ronde 3: death/respawn-flow herontworpen

Het oude ontwerp had twee death-states: "knocked" (gewond op de grond) en "eliminated" (echt
dood). De respawntimer liep **alleen** in "eliminated" — maar daar kwam je pas na minutenlang
doodbloeden. In de praktijk lag je dus eeuwig op de grond zonder timer en deed `R` niets.

Nieuw gedrag:

1. **Doodgaan** → je ligt gewond op de grond, rood schermeffect, "YOU ARE INJURED".
2. **Timer start direct** bij neergaan (standaard 60s, `timer` in `data/death.lua`) en telt
   af in beeld, ongeacht de death-state.
3. Na 10s verschijnt **"PRESS G TO SEND A DISTRESS SIGNAL"** (blijft werken zolang je down bent).
4. Na de timer: **"PRESS R TO RESPAWN - $2000 AND YOU LOSE YOUR BELONGINGS / WAIT FOR EMS TO
   KEEP YOUR BELONGINGS"**. `R` werkt vanaf dat moment in beide death-states.
5. **Respawnen** = ziekenhuisrekening van `prices.respawn` ($2000) + inventory blijft als drop
   achter op de plek waar je stierf (`dropInventory`). Beide met een notificatie.
6. **Wachten op EMS** (behandeling, defib, ziekenhuis) = je houdt je spullen.

Overige wijzigingen in deze ronde:

- **Rood schermeffect toegevoegd**: timecycle `damage` terwijl je gewond ligt, `DeathFailOut`
  postfx als je echt dood bent, plus een sterkere pulserende rode NUI-vignette. (Het "rode
  scherm" dat er eerst was, was het vanilla GTA-doodseffect — dat verdwijnt zodra het script de
  ped resurrect om de animatie te spelen, dus dat moest vervangen worden.)
- **Vangnet voor gemiste death-events**: `CEventNetworkEntityDamage` vuurt niet bij elke
  doodsoorzaak (vallen, verdrinken, sommige explosies). Een watchdog checkt elke 250 ms of de
  ped fataal gewond is en start dan alsnog de death-flow. Dezelfde watchdog escaleert "knocked"
  spelers die nogmaals sterven naar "eliminated".
- **Dubbele resurrect gefixt**: zowel `client/modules/death.lua` als `client/main.lua` hadden
  een handler op `ND_Ambulance:revivePlayer` die de ped resurrectte. Geconsolideerd in
  `client/main.lua`.
- **Debug-logging**: `debug = true` in `data/death.lua` print elke stap (death gedetecteerd,
  state gezet, respawn geweigerd/geaccepteerd met reden, signal verstuurd) naar de F8-console
  en serverconsole. Zet op `false` als alles werkt.
- De ongebruikte `mourgeRespawn` locaties zijn verwijderd; respawnen gebeurt bij de
  dichtstbijzijnde locatie uit `hospitalRespawns`.

## Ronde 4: timer, respawn en het rode scherm

Symptomen: de timer liep niet, `R` deed niets (of gaf een gratis respawn), en het rode
deathscreen was weg.

- **De timer-loop stopte meteen.** De lus stond op
  `while LocalPlayer.state.dead and deathState == newDeathState`. Die statebag wordt één
  frame eerder geschreven en leest niet gegarandeerd al terug — deed hij dat niet, dan viel
  de lus direct uit en kreeg je geen animatie, geen aftelling en geen deathscreen. De lus
  kijkt nu alleen nog naar de lokale `deathState`.
- **De aftelling hing aan twee verschillende klokken.** De client rekende met
  `GetCloudTimeAsInt()` (spelklok) en de server controleerde met `os.time()` (machineklok).
  Liepen die uit elkaar, dan werd de respawn permanent geweigerd. De client telt nu af met
  `GetGameTimer()` (monotoon, puur lokaal) en de server houdt zijn eigen `os.time()` bij,
  gezet via het nieuwe event `ND_Ambulance:playerDown`. Er worden geen klokken meer
  vergeleken.
- **Gratis respawn bij afwijzing.** `R` stuurde `ND_Ambulance:respawnPlayer` als
  fire-and-forget en resette daarna hoe dan ook lokaal + teleporteerde. Weigerde de server,
  dan respawnde je alsnog: geen rekening, geen inventory-drop. Het is nu een
  `lib.callback`: de client reset en teleporteert pas als de server `true` teruggeeft, dus
  ná het afschrijven en het droppen.
- **De respawntijd kwam uit de statebag van de speler zelf**, die de client zelf schrijft —
  dus door de speler te vervalsen. De server houdt die tijd nu zelf bij en vergeet hem weer
  bij revive (`ND_Ambulance:playerRevived`) en bij disconnect.
- **Dubbele resurrect bij respawnen**: de server riep `Bridge.revivePlayer` (die het
  client-revive-event stuurt) terwijl de client zichzelf ook al resette. De respawn gebruikt
  nu `Bridge.clearDeadMetadata`, dat alleen de metadata opschoont.
- **Het rode scherm.** In de `eliminated`-state stond `ClearTimecycleModifier()` plus
  `AnimpostfxPlay("DeathFailOut")` — dat is het grijze/vervaagde "wasted"-effect, precies het
  tegenovergestelde van rood. Nu staat de `damage`-timecycle in beide death-states aan
  (sterkte 0.6 gewond, 1.0 dood) en wordt hij elke seconde opnieuw gezet, omdat andere
  resources en de schermfades hem wissen.
- **De NUI is opnieuw opgebouwd**: aparte rode vignette-laag die pulseert (donkerder en
  zwaarder als je echt dood bent) en een grote aftelteller in beeld in plaats van een regel
  tekst onderaan.
- **De zwarte fade elke 4 seconden** gebeurde ook als je niet bloedde, waardoor het
  deathscreen constant knipperde. Gebeurt nu alleen nog als er echt bloedverlies is.
- **Meldingen**: je krijgt nu ook bericht zodra respawnen beschikbaar is (met de prijs en de
  keuze), en bij een revive door EMS/defib/ziekenhuis dat je je spullen hebt behouden. De
  rekening- en inventory-meldingen bestonden al.
- `data/walks.lua` had een kapotte regel: `move_m@swagger` wees naar de niet-bestaande
  clipset `"move"` en `move_m@swagger@b` stond als `_m@swagger@b` in de tabel. Spelers met
  die loopstijl kregen na een revive een kapotte walk.

### Samengevat het gedrag nu

| Moment | Wat er gebeurt |
|---|---|
| Neergaan | Rood scherm, "YOU ARE INJURED", timer start op 60s |
| Na 10s | "PRESS G TO SEND A DISTRESS SIGNAL" |
| Na 60s | "PRESS R TO RESPAWN" + melding met prijs en keuze |
| `R` indrukken | Server schrijft $2000 af, dropt je inventory op de plek waar je stierf, daarna spawn je in het ziekenhuis |
| Wachten op EMS | Je houdt je spullen en krijgt daar een melding van |

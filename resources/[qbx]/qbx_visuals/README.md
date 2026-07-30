# qbx_visuals

Fotorealistische kleurcorrectie, betere voertuigverlichting, scherpere
schaduwen, adaptieve kwaliteit, precies instelbare ped-/voertuigdichtheid en
verplicht first person voor een Qbox-server.

Alle gebruikte natives zijn geverifieerd tegen de officiële `citizenfx/natives`
lijst. De Lua-bestanden zijn door `luac` gehaald, de XML is gevalideerd, en de
visualsettings-parser en de first-person logica zijn met testharnassen
gedraaid.

Eén klein server-script (`server/permissions.lua`) doet de admin-controle. De
rest is client-side.

---

## First person verplichten

Aan te zetten met `Config.FirstPerson.enabled`. De controle op wie vrijgesteld
is gebeurt **server-side** via de ACE-namen uit je `permissions.cfg`
(standaard `admin` en `mod`) — een client mag nooit zelf beslissen dat hij
admin is.

Per cameracontext instelbaar: te voet, in een voertuig, op een motor, in een
boot, vliegtuig, onderzeeër, heli en geschutskoepel. Turret staat standaard uit
omdat first person daar naar is.

De camera-wisseltoets wordt geblokkeerd in plaats van achteraf teruggezet, dus
je flitst niet eerst even naar derde persoon. Tijdens cutscenes, spectator,
player switch, het pauzemenu en bij dood laat het script los.

### Waarom je gezicht in beeld kwam

Dit is de belangrijkste bevinding, en het is goed nieuws.

**Er bestaat geen native om het blikveld van de gameplay-camera te zetten.** De
natives-lijst heeft alleen `GET_GAMEPLAY_CAM_FOV`, geen `SET`. `SetCamFov`
werkt uitsluitend op een camera die je zelf met `CreateCam` hebt gemaakt.

Scripts die toch een bredere FOV in first person leveren, doen dat dus met een
eigen camera. En dáár zit je probleem: in de échte first-person modus haalt GTA
het hoofd van je ped zelf weg, maar bij een zelfgemaakte camera doet het spel
dat niet. Vandaar je eigen gezicht in beeld tijdens het rijden.

Dit script gebruikt daarom bewust het echte first-person standpunt
(`SET_CAM_VIEW_MODE_FOR_CONTEXT`). **Daarmee verdwijnt het gezichtsprobleem
vanzelf.** Draait er nog een ander script dat een eigen first-person camera
maakt, zet dat uit — anders komt het probleem daarmee terug.

### En de FOV dan?

De FOV is een instelling van de speler zelf, niet iets wat een server kan
afdwingen. Het script zet daarom bij het joinen de client-convar
`profile_fpsFieldOfView` voor die sessie (`Config.FirstPerson.fov.autoApply`).

**Dit is het enige onderdeel dat ik niet heb kunnen verifiëren.** De convar
staat niet in de officiële natives-documentatie en de schaal ervan is nergens
beschreven. Test het live:

```bash
/gfx fov 85
```

Werkt dat, zet dan `Config.FirstPerson.fov.value` op de waarde die je bevalt.
Werkt het niet op jouw build, zet dan `notify = true`; spelers krijgen dan bij
het joinen eenmalig het console-commando te zien zodat ze het zelf kunnen
instellen.

### Toch een eigen camera: hoofd uit én FOV hoger

Kan wel, zit erin, staat standaard **uit**. Zet aan met `/gfx cam` of
`Config.FirstPerson.customCam.enabled`.

Een eigen camera geeft volledige FOV-controle, maar GTA verwijdert je hoofd
alleen in de echte modus. Dus doen we dat zelf, op twee manieren:

| Methode | Werking |
|---|---|
| **Near clip** (standaard) | Alles dichter bij de camera dan `nearClip` wordt weggeknipt. Je hoofd valt daarbinnen, je armen en lichaam niet. Je blijft dus je handen op het stuur zien. |
| **`hidePed = true`** | `SetEntityLocallyInvisible` verbergt je hele ped, alleen voor jezelf. Werkt gegarandeerd, maar dan zijn je armen ook weg. |

De camera hangt aan de hoofdbot (`SKEL_Head`, 31086) voor de **positie**; de
rotatie komt elke frame van de gameplay-camera, zodat muis- en
controllerbesturing gewoon blijven werken. Bewust `AttachCamToPedBone` en niet
de Hard-variant — anders draait de camera mee met de hoofdanimatie en daar word
je misselijk van.

**Wat je inlevert:** richten en drive-by werken niet goed op een zelfgemaakte
camera. Daarom springt hij standaard terug naar de echte camera zodra je richt,
en staat hij standaard alleen in voertuigen aan (`contexts.onFoot = false`).

Afstellen kan live:

```bash
/gfx cam on
```

| Commando | Doet |
|---|---|
| `/gfx cam [on\|off]` | Eigen camera aan, uit of omschakelen |
| `/gfx camfov <n>` | FOV van de eigen camera, bijv. `90` |
| `/gfx nearclip <n>` | Hoeveel er wordt weggeknipt, bijv. `0.15` |

Zie je nog een stukje hoofd? Verhoog `nearclip` in stapjes van 0,02. Kijk je
door het stuur of dashboard heen? Dan zit hij te hoog. Bruikbaar bereik is
ongeveer 0,12 – 0,20.

**Mijn advies blijft: test eerst `/gfx fov 85`.** Werkt die convar, dan heb je
de echte first-person modus mét breder blikveld, en dat is op elk punt beter dan
een zelfgemaakte camera.

### Exports

```lua
exports.qbx_visuals:setFirstPersonSuppressed(true)  -- tijdelijk uit
exports.qbx_visuals:isFirstPersonExempt()           -- is deze speler admin?
exports.qbx_visuals:setFieldOfView(90)              -- blikveld zetten
```

---

## Waarom je density-instellingen niet deden wat je verwachtte

Dit is de meest gestelde vraag over FiveM-density, dus hier staat het volledig.

### Je zag geen enkele ped bij 0.1

**Er zijn twee losse ped-systemen.** `SetPedDensityMultiplierThisFrame` regelt
alleen de *rondlopende* peds. De peds die ergens stáán — bushalte, bankje,
rokend tegen een muur — zijn **scenario-peds** met een eigen native
(`SetScenarioPedDensityMultiplierThisFrame`). Zet je allebei op 0.1, dan is de
stad compleet leeg.

Daar komt bij dat het aantal rondlopende peds per zone toch al laag ligt. Maal
0.1 blijft daar afgerond niemand van over. Bij auto's ligt dat basisaantal veel
hoger, dus dezelfde 0.1 laat daar nog een handjevol rijden. Zelfde getal,
totaal ander resultaat.

**Jouw instelling is nu:** rondlopende peds 0.35, scenario-peds 1.0. Rustige
straten, maar wel peds waar je scripts iets mee kunnen.

### Je zag nog aardig wat auto's bij 0.1

Drie oorzaken die alle drie meespelen:

1. **Een multiplier stopt alleen nieuwe spawns.** Alles wat al gespawnd is,
   blijft rijden of staan tot het normaal despawnt.
2. **Er zijn twee knoppen voor verkeer**, `SetVehicleDensityMultiplierThisFrame`
   en `SetRandomVehicleDensityMultiplierThisFrame`. Zet je er maar één, dan
   blijft de andere op vol staan. Dit script zet ze allebei.
3. **Geparkeerde auto's komen grotendeels uit "vehicle generators"**, een apart
   systeem dat maar half naar `parkedVehicles` luistert. Daarom staat
   `disableLowPriorityGenerators = true` aan. Dát is wat je geparkeerde auto's
   echt weghaalt.

### Twee dingen die elk density-script slopen

**Deze natives zijn allemaal `_THIS_FRAME`.** Ze moeten *elke frame* opnieuw
gezet worden — de officiële docs zeggen letterlijk "Call this native every
frame". Draait een density-script met `Wait(500)`, dan staat de waarde maar op
1 van de ~30 frames goed en valt hij de rest van de tijd terug op normaal. Dat
is precies het soort onvoorspelbaar gedrag dat je bij je oudere scripts zag.

**Draai er nooit twee tegelijk.** Twee resources die allebei elke frame
dezelfde multiplier zetten, vechten erom: de laatste die in die frame draait
wint, en welke dat is hangt af van de laadvolgorde. Dan lijkt je config willekeurig
te werken.

> Zet daarom de density-functie van je huidige qbx density-script uit voor je
> dit aanzet — of zet hier `Config.Population.enabled = false` en houd je oude
> script. Eén van de twee, nooit allebei.

### Voor je diefstal- en drugsverkoop-scripts

Bouw gameplay niet op rondlopende peds. Die despawnen wanneer het de
populatie-manager uitkomt, ook midden in je interactie. Twee betere routes:

- **Scenario-peds** (staan nu op 1.0) staan op vaste, voorspelbare plekken.
  Prima ankers voor een drugsverkoop-script.
- **Spawn je eigen peds** voor alles wat een missie moet overleven. Een ped die
  je zelf maakt, verdwijnt niet onder je handen vandaan.

`InstantlyFillPedPopulation()` wordt eenmalig aangeroepen na het spawnen, zodat
je meteen ziet wat je instellingen doen in plaats van minuten te wachten.

Alles zit in `Config.Population` in [config.lua](config.lua).

---

## Visualsettings

Je had gelijk dat dit werkt — alleen niet via `data_file`. Een
`VISUAL_SETTINGS_FILE` type bestaat niet. Het werkt via de native
`SET_VISUAL_SETTING_FLOAT`.

Die staat niet in de gedocumenteerde natives-lijst, maar bestaat wel:
`joaat("SET_VISUAL_SETTING_FLOAT")` = `0xD1D31681`, exact de hash waaronder
docs.fivem.net hem kent. Ik heb dat narekend voor ik het inbouwde, en roep hem
direct met die hash aan.

`data/visualsettings.dat` wordt op de client ingelezen en regel voor regel
toegepast. **Alleen de sleutels die erin staan worden overschreven**, de rest
houdt zijn standaardwaarde — een onvolledig bestand is dus veilig.

Wat er nu in staat is de emissive-sterkte van voertuiglampen. Dat is de grootste
winst die visualsettings geeft: koplampen, remlichten en knipperlichten worden
's nachts veel beter leesbaar en lopen mooi uit in de bloom. Kost niets.

Meer sleutels toevoegen: haal het originele `common/data/visualsettings.dat` uit
je eigen GTA V met OpenIV (die heb je staan) en kopieer de regels die je wilt
aanpassen naar ons bestand. Verzonnen sleutels doen simpelweg niets, dus je kunt
er weinig mee stukmaken.

Herladen zonder restart: `exports.qbx_visuals:reloadVisualSettings()`.

---

## Beeld

Elke twee seconden wordt bepaald in welke scene je zit; daarna zet het script de
bijpassende timecycle-modifier. Het overvloeien doet GTA zelf via
`SET_TRANSITION_TIMECYCLE_MODIFIER`, dus daar draait geen thread voor.

| Scene | Look |
|---|---|
| Dag, helder | Neutraal-koele schaduwen, meer contrast, subtiele grain |
| Zonsopgang | Koel naar warm, zacht licht |
| Zonsondergang | Gouden uur, meer bloom |
| Nacht | Zwarten iets opgetild, koele tint, bloom op straatverlichting |
| Bewolkt | Extra contrast, juist mínder ontzadigd |
| Regen overdag | Koel en ontzadigd, natte-asfalt look |
| Regen 's nachts | Veel bloom, neon en koplampen lopen uit over het wegdek |
| Mist / smog | Sterk ontzadigd, nauwelijks vignette |
| Sneeuw | Exposure omlaag, hoge bloom-drempel |
| Hoog in de lucht | Bijna geen vignette, helder zicht |
| Binnen | Geen kleurcorrectie, minimale vignette |

Verder: scherpere schaduwen, natte bandensporen en voetstappen bij regen en
sneeuw, vliegtuigmodus voor schaduwen als je hoog zit, en een constante subtiele
filmlaag.

Tijdens cutscenes, spectator, player switch, onder water en bij dood haalt het
script zichzelf weg.

---

## Installatie

1. Zet de map `qbx_visuals` in je `resources` folder.
2. Zet de density-functie van je bestaande script uit (zie hierboven).
3. In je `server.cfg`, ná ox_lib:

```bash
ensure qbx_visuals
```

4. Server volledig herstarten, niet alleen `refresh`. Een `data_file` wordt pas
   bij een echte resource-start geregistreerd.

**Dependency:** `ox_lib`.

---

## Gebruik

```bash
/gfx
```

Menu met aan/uit, look, kwaliteit en een statusregel. Direct schakelen kan ook:
`/gfx off`, `/gfx neutral`, `/gfx ultra`, `/gfx auto`.

De keybind heet "Visuals-menu openen" in de FiveM-instellingen en is standaard
leeg, zodat we geen bestaande bind afpakken. Keuzes worden per speler onthouden.

---

## Wat kost wat

| Onderdeel | Kosten |
|---|---|
| Context-loop | 1 tick per 2 seconden |
| Overgangen | Geen thread — GTA vloeit zelf over |
| Kleurcorrectie | Vrijwel gratis; die post-processing pass draait toch al |
| Visualsettings | Eenmalig bij het joinen, daarna niets |
| Per-frame thread | ~0,01 ms. Schaduwen én dichtheid zitten in dezelfde thread |
| FPS-meting (auto) | 2 metingen per seconde |
| Blijvende instellingen | Elke 10 seconden herbevestigd |

Er is bewust maar **één** `Wait(0)`-thread in de hele resource. Meerdere
per-frame threads naast elkaar is de klassieke manier om resmon vol te trekken.

Twee dingen kosten wél echt iets, beide in het ultra-profiel:
`shadowEntityTracker = false` (schaduwen vanaf verder weg) en `lodScale = 1.25`
(meer detail in de verte). Zet `lodScale` op `nil` als je ultra puur gratis wilt.

Minder peds en auto's is overigens ook gewoon winst: het performance-profiel
hoeft daar niets extra's voor te doen, jouw density-instellingen leveren dat al.

De kwaliteitsprofielen raken de populatie **niet** aan. Dat is expres — je wilt
niet dat een framerate-schuif achter je rug om verandert hoeveel peds er voor je
diefstal-script beschikbaar zijn.

---

## Afstellen

Begin altijd bij [config.lua](config.lua), niet bij de XML.

- **Te sterk of te zwak?** `Config.Presets[...].strength` (0.0 – 1.0).
- **Eén scene klopt niet?** `Config.ContextStrength`.
- **Schaduwen te scherp of poppen te vroeg?** `shadowBoundsScale`, bruikbaar
  bereik 0,55 – 0,90.

Geldige waardes voor `shadowSampleType` (letterlijk uit de native-docs):

```
CSM_ST_POINT, CSM_ST_LINEAR, CSM_ST_TWOTAP, CSM_ST_BOX3x3, CSM_ST_BOX4x4,
CSM_ST_DITHER2_LINEAR, CSM_ST_CUBIC, CSM_ST_DITHER4, CSM_ST_DITHER16,
CSM_ST_SOFT16, CSM_ST_DITHER16_RPDB, CSM_ST_POISSON16_RPDB_GNORM,
CSM_ST_HIGHRES_BOX4x4
```

Dit zijn de enige geldige namen; iets als `ShadowSampleType_Soft16` doet niets.

### De timecycle-XML aanpassen

Het formaat is gecontroleerd tegen het originele `timecycle_mods_1.xml` van
GTA V (273 modifiers, 5933 regels). De waarde staat **in het element**, niet in
een attribuut:

```xml
<postfx_exposure>0.050 0.000</postfx_exposure>
```

Van die 5933 regels in het spelbestand gebruikt er precies **nul** een
`value="..."` attribuut. De tweede float is bij al deze postfx-variabelen
`0.000` in vanilla.

Waardebereiken, afgeleid uit datzelfde bestand:

| Variabele | Bereik | Mediaan |
|---|---|---|
| `postfx_exposure` | -2.00 – 2.00 | 0.00 |
| `postfx_bright_pass_thresh` | 0.00 – 10.00 | 0.50 |
| `postfx_bright_pass_thresh_width` | 0.10 – 2.00 | 0.50 |
| `postfx_intensity_bloom` | 0.00 – 5.00 | 0.70 |
| `postfx_correct_col_r/g/b` | 0.00 – 1.00 | genormaliseerd RGB |
| `postfx_correct_cutoff` | 0.00 – 16.00 | 1.07 |
| `postfx_desaturation` | 0.00 – 4.15 | 0.68 |
| `postfx_vignetting_intensity` | 0.00 – 1.00 | 0.93 |
| `postfx_vignetting_radius` | 0.17 – 12.50 | 10.00 |
| `postfx_vignetting_contrast` | 0.00 – 1.00 | 0.04 |

Let op: `postfx_correct_cutoff` is **één** variabele, niet `_r`/`_g`/`_b`. En
bij `vignetting_radius` lijkt hoger juist subtieler — het zware gang-filter
`Vagos` gebruikt 5.0, het bredere `cops`-filter 10.0.

`numMods` moet exact gelijk zijn aan het aantal regels in die modifier.

Ik gebruik bewust alleen `postfx_*`-variabelen: pure post-processing, raakt de
wereldbelichting en skydome niet. Wil je verder — `lens_dist_coeff`,
`lens_dist_cube_coeff`, `chrom_aberration_coeff`, `chrom_aberration_coeff2` —
voeg die één voor één toe en houd je console in de gaten.

**Niet geverifieerd:** `postfx_noise` en `postfx_noise_size` bestaan wel als
geldige namen, maar staan in alle 273 vanilla-modifiers op `0.000`. Er is dus
geen bewijs dat ze echt iets doen. Ziet je beeld er raar uit, haal die twee
regels er dan als eerste uit en verlaag `numMods` navenant.

---

## Omgang met andere resources

De timecycle-hoofdslot wordt door veel scripts gebruikt (interieurs,
drugs-effecten, dood-scherm). Dit script pakt de slot alleen als die vrij is
(`GET_TIMECYCLE_MODIFIER_INDEX() == -1`), en laat los zodra een ander script hem
overneemt. Pas na `Config.Grading.yieldTime` wordt het opnieuw geprobeerd.

Het weer en de tijd worden **niet** aangestuurd. Dat hoort bij je
weathersync-resource.

---

## Als er iets niet werkt

Zet `Config.Debug = true` en kijk in F8. Je ziet dan contextwissels, het aantal
toegepaste visualsettings, en of de timecycle-slot is losgelaten.

- **Geen kleurcorrectie zichtbaar** — check bij het starten van de resource of
  `data/timecycle_mods_photoreal.xml` zonder klachten inlaadt.
- **Effect verdwijnt op bepaalde plekken** — dat is het loslaten van de slot,
  precies zoals bedoeld. Staat in de debug-log.
- **Dichtheid klopt niet** — draait er nog een tweede density-script? Dat is in
  negen van de tien gevallen de oorzaak.
- **Schakelt te vaak van profiel** — verhoog `Config.Auto.cooldown` of vergroot
  het gat tussen `downThreshold` en `upThreshold`.

---

## Grenzen

Een script kan de belichting, het beeld en de populatie sturen. Het kan geen
nieuwe textures, modellen of shaders toveren. De grote realisme-pakketten (NVE,
QuantV) vervangen textures en timecycles in bulk — die gaan verder, maar kosten
echt frames.

Voor de laatste stap richting foto-look gebruiken spelers meestal daarnaast nog
ReShade of GShade. Dat is client-side en kun je vanaf de server niet regelen.

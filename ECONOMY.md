# Economisch model — Los Balos RP

> **STATUS: goedgekeurd door Tim (aug 2026) en grotendeels doorgevoerd.**
>
> Beslissingen (zie §8):
> - Uurloon-model **$600 / $1.200 / $1.500** — doorgevoerd in `qbx_core/shared/jobs.lua`.
> - Supercars/top **sneller haalbaar, $300-500k top** — renzu_vehicleshop lag al goed
>   (median $36k, p95 $210k); enige uitschieter van $900k (vxr) naar $475k.
> - Verzekeringspremies **halveren naar $6 / $4** — doorgevoerd in `los_insurance/shared/config.lua`.
> - Illegaal **1,5x tot 2x** legaal (kleiner verschil) — leidend voor de drugs/crime-marges.
>
> Wat nog handmatig moet (per-item, subjectief — zie §7 en BACKLOG):
> - renzu_shops food/beverage/gadget catalogus volledig langs de $10-60 meetlat
>   (nu alleen de duidelijke uitschieters gefixt: tabak $1000->$45, latte $280->$25).
> - Drugs-prijsmagnitudes fijn afstellen op $/uur — kan alleen met in-game meting
>   van deal-duur. De STRUCTUUR (straat laag, bulk hoog) klopt al.
> - Dirty-money consistentie is wél volledig gefixt: alle illegale inkomsten lopen
>   nu via black_money (wholesale, cornerselling, oxyruns, kassa- en kluisoverval).

---

## 1. Het uitgangspunt

Uit de opdracht: **"Doel: geen grind, wel schaarste."** Dat zijn twee dingen die
elkaar niet uitsluiten maar wel makkelijk verward worden.

- **Geen grind** = je hoeft niet uren hetzelfde te doen om mee te kunnen doen.
  Een uur spelen levert genoeg op voor je vaste lasten en een beetje over.
- **Wel schaarste** = de dure dingen zijn écht duur. Een supercar of een huis is
  een project van weken, geen middagje.

Wat daar tussen zit — eten, kleding, benzine, een gewone auto — hoort haalbaar
te zijn zonder erover na te denken.

## 2. De rekeneenheid: het uur

Alles hieronder rekent in **wat een speler per uur binnenkrijgt**, want dat is de
enige maat die spelers zelf ook voelen.

qbx_core betaalt uit per `paycheckTimeout` = **10 minuten**, dus zes loonstroken
per uur.

| | Voorstel | Waarom |
|---|---|---|
| Instapjob, uurloon | **$600** (6 × $100) | Genoeg voor eten, benzine en wat over |
| Ervaren job, uurloon | **$1.200** | Verdubbelen over de grades heen |
| Hulpdienst, uurloon | **$1.500** | Hogere eis: opleiding, verantwoordelijkheid, en ze moeten on duty blijven |

Netto ligt dat lager: van elke loonstrook gaat belasting en verzekering af, samen
ongeveer 30% met een plafond van 35%. Dat staat al zo in `los_insurance` en is
een beslissing van Tim die hier niet in wordt teruggedraaid.

**Instapjob netto ≈ $420/uur. Ervaren ≈ $840/uur.**

## 3. Prijsniveaus

Uitgedrukt in **uren werk** voor een instapjob (netto $420/uur). Dat maakt
meteen zichtbaar of iets redelijk is.

| Categorie | Prijs | Uren werk |
|---|---|---|
| Maaltijd, drankje | $10 – $60 | minuten |
| Kleding, per stuk | $75 – $600 | < 1,5 uur |
| Pak, jas | $1.200 – $2.500 | 3 – 6 uur |
| Sieraad | $2.000 – $25.000 | 5 – 60 uur |
| Huisdier | $2.000 – $50.000 | 5 – 120 uur |
| Gewone auto | $15.000 – $45.000 | 35 – 105 uur |
| Sportwagen | $120.000 – $400.000 | maanden |
| Supercar | $800.000+ | een project |
| Woning | $150.000+ | een project |

Dat "een project" is het punt. Een supercar hoort iets te zijn waar mensen het
over hebben, niet iets wat je op een zaterdag bij elkaar rijdt.

## 4. Vaste lasten

Wat er sowieso af gaat, zodat verdienen ergens over gaat.

| Post | Bedrag | Frequentie |
|---|---|---|
| Zorgverzekering | $12 | per loonstrook |
| Autoverzekering | $8 per voertuig | per loonstrook |
| Inkomstenbelasting | % van het loon | per loonstrook |
| Wegenbelasting | per voertuig | per loonstrook |
| Benzine | ~$150 per volle tank | naar gebruik |

Bij zes loonstroken per uur is dat **$72/uur** aan zorgverzekering alleen. Dat
voelt veel. **Voorstel: premies naar $6 en $4**, oftewel $36 en $24 per uur.
Dat is ongeveer 8% van een instapinkomen — merkbaar, niet knellend.

## 5. Illegaal geld

Het uitgangspunt: illegaal werk betaalt **beter per uur** dan legaal werk, maar
met risico, wachttijd en een omzetverlies bij het witwassen.

| | Voorstel |
|---|---|
| Marge boven legaal | **2× tot 3×** het legale uurloon |
| Witwaskosten | **25%** eraf |
| Netto voordeel na wassen | ongeveer **1,5× tot 2,25×** |

Dat is genoeg om het aantrekkelijk te maken en te weinig om legaal spelen zinloos
te maken. Alle illegale inkomsten lopen al via `black_money`; alleen moneywash
zet het om.

**Drugs, per verwerkte eenheid:** verkoop aan junkies laag houden ($40 – $120)
en de winst in de **bulk via de dealer** leggen. Zo blijft straatverkoop RP en
wordt de gang-verwerking het echte verdienmodel — precies zoals fase 3 het
bedoeld heeft.

## 6. Wat al vastligt

Niet ter discussie, dit zijn beslissingen van Tim:

| Post | Bedrag |
|---|---|
| Medische behandeling | $1.000 |
| Behandeling door een ander | $1.500 |
| AI-dokter | $750 |
| Respawnen | $1.000 |
| Met verzekering | gratis (eigen bijdrage 0) |

Bij een netto instapinkomen van $420/uur is $1.000 respawnen **ruim twee uur
werk**. Dat is precies de bedoeling: sterven moet pijn doen. Het maakt de
verzekering ook meteen logisch — $36/uur premie tegenover $1.000 per keer.

## 7. Wat ik zou aanpassen

In volgorde van impact. Niets hiervan is doorgevoerd.

1. **Job-payouts gelijktrekken** op het uurmodel uit §2. Ze staan nu per job
   apart ingesteld zonder gemeenschappelijke maat.
2. **Verzekeringspremies halveren** ($12 → $6, $8 → $4). Zie §4.
3. **Drugsprijzen kantelen** naar bulk: straatverkoop omlaag, dealer omhoog.
4. **Voertuigprijzen spreiden** volgens de tabel in §3, zodat er echt een
   onderkant en een bovenkant is.
5. **Winkelprijzen** langs de meetlat van §3 leggen.

## 8. Beslissingen van Tim (aug 2026)

- Uurloon **$600 / $1.200 / $1.500** — akkoord. Doorgevoerd.
- Supercar/top: **sneller haalbaar, $300-500k top** (niet "project van weken").
- Premies **halveren** ($12->$6, $8->$4) — akkoord. Doorgevoerd.
- Illegaal op **1,5x tot 2x** legaal (kleiner verschil dan het 2-3x voorstel).

Deze vier zijn leidend voor alle verdere prijsaanpassingen.

---

## Herijking augustus 2026 — loon omhoog

Tim: spelers verdienen te weinig en kunnen nooit dure spullen kopen (auto's,
sieraden). Inhoudingen en belasting mogen iets omhoog, de ophaalkosten bij de
chopshop waren te duur.

### Wat er is gewijzigd

| | Was | Nu |
|---|---|---|
| Instapjob, per loonstrook | $100 | **$300** |
| Ervaren job | $200 | **$600** |
| Hulpdienst top | $250 | **$750** |
| Zorgverzekering | $6 | **$12** |
| Autoverzekering | $8 | **$8** (was al) |
| Inkomstenbelasting | 8% | **12%** |
| Motorrijtuigenbelasting | $3 | **$6** per voertuig |
| Ophaalkosten chopshop, onverzekerd | $12.000 | **$3.500** |
| Ophaalkosten, verzekerd (25% eigen risico) | $3.000 | **$875** |

Loon maal drie, inhoudingen ongeveer maal twee. Netto komt een speler er dus
flink op vooruit, terwijl de vaste lasten wel zwaarder meetellen dan eerst.

### Wat dat netto betekent

Zes loonstroken per uur, met een auto op naam:

| | Bruto/uur | Inhouding | Netto/uur |
|---|---|---|---|
| Instap | $1.800 | 21% | **~$1.430** |
| Ervaren | $3.600 | 16% | **~$3.010** |
| Hulpdienst | $4.500 | 15% | **~$3.830** |

Was: instap ~$420/uur netto.

### Prijzen in uren werk (instap, netto)

| Categorie | Prijs | Was | Nu |
|---|---|---|---|
| Sieraad | $2.000 – $25.000 | 5 – 60 uur | **1,5 – 17 uur** |
| Gewone auto | $15.000 – $45.000 | 35 – 105 uur | **10 – 31 uur** |
| Sportwagen | $120.000 – $400.000 | maanden | **84 – 280 uur** |
| Supercar | $475.000 | een project | **een project** |
| Woning | $150.000+ | een project | **105+ uur** |

Een sieraad is nu een avond spelen in plaats van een week. Een gewone auto een
stuk of vier sessies. De bovenkant blijft een project - dat was en is het punt
van "geen grind, wel schaarste".

### Voertuigprijzen herijkt

Ook na de loonsverhoging bleef een MEDIANE auto 27 uur werk en de top 332 uur.
Dat was precies de klacht. Daarom een oplopende korting op
`renzu_vehicleshop/vehicles.lua` (116 van de 169 voertuigen aangepast):

| Prijsdeel | Korting |
|---|---|
| tot $20.000 | geen |
| $20.000 – $100.000 | 45% over het deel boven $20.000 |
| boven $100.000 | 65% over het deel boven $100.000 |

Doorlopend en stijgend, dus de volgorde duur/goedkoop klapt nergens om.

| | Was | Nu | Uren instapwerk |
|---|---|---|---|
| Instapper | $4.000 | $4.000 | 3 |
| p25 | $18.000 | $18.000 | 13 |
| Mediaan | $38.000 | **$30.000** | 27 -> **21** |
| p75 | $60.000 | **$42.000** | 42 -> **29** |
| p90 | $125.000 | **$73.000** | 87 -> **51** |
| p95 | $220.000 | **$106.000** | 154 -> **74** |
| Duurste | $475.000 | **$195.000** | 332 -> **136** |

De goedkope kant is bewust ongemoeid gelaten: die was al haalbaar. De winst zit
in het midden en de top, en dat is waar de klacht zat. Het duurste voertuig is
nog steeds 136 uur werk - een project, maar wel een haalbaar project.

### Sieraden

Niet aangepast. De sieraad-items bestaan wel in `ox_inventory/data/items.lua`,
maar geen enkele winkel in `renzu_shops` verkoopt ze met een prijs. Er valt dus
niets te herijken; er moet eerst een juwelier komen die ze aanbiedt.

### Wat NIET is aangepast

Alle overige prijzen (eten, kleding, wapens, drugs) zijn ongemoeid gelaten. Die
schuiven mee met het loon. Blijkt er alsnog iets scheef, dan is dat een gerichte
aanpassing op die categorie in plaats van aan de loonknop draaien.

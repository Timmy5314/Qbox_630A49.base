# Economisch model — Los Balos RP

> **Dit is een voorstel. Er is nog niets doorgevoerd.**
>
> SERVER-OVERHAUL §6.4 vraagt om eerst een model en dat aan Tim voor te leggen
> vóór er waardes worden aangepast. Dit bestand is dat model. Zeg per onderdeel
> of je het eens bent, dan pas gaan de getallen de configs in.

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

## 8. Wat ik hiervoor van jou nodig heb

- Klopt **$600/$1.200/$1.500** per uur met wat je voor ogen hebt?
- Is een supercar op "een project van weken" goed, of mag dat sneller?
- Akkoord met de premies halveren?
- Illegaal op **2× tot 3×** legaal — te laag, te hoog?

Zeg het per punt, dan voer ik het door. Doe ik het zonder, dan verzin ik een
economie voor jouw server en dat is precies wat de opdracht niet vraagt.

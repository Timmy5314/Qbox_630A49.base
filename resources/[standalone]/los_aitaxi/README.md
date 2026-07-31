# los_aitaxi — Downtown Cab Co.

Volledig nieuw geschreven voor Qbox. `_external/mns-aitaxi` is alleen als
concept gebruikt en was als basis onbruikbaar: naast elk bestand staan daar ook
`_fixed`, `_new`, `_updated` en `standalone_` varianten van datzelfde bestand
(`spawn.lua`, `spawn_fixed.lua`, `spawn_new.lua`, `spawn_new_fixed.lua`, …) en
welke het origineel laadt is niet af te leiden.

## Hoe het loopt

1. Je belt **4040** met NPWD.
2. Rijdt er iemand met de job `taxi` on duty, dan krijg je een SMS dat er een
   echte chauffeur beschikbaar is. Er komt geen AI — spelers gaan voor.
3. Anders komt er na acht seconden een taxi naar je toe.
4. Je stapt in en zet een waypoint. De chauffeur rijdt erheen.
5. Bij aankomst betaal je; taxi en chauffeur verdwijnen.

**`/aitaxi` bestaat bewust niet.** De centrale bel je, net als elke andere dienst.

## De NPWD-koppeling

NPWD exporteert `onCall(nummer, cb)` vanuit zijn JS-bundle
(`server/calls/middleware/index.ts`). De callback krijgt `receiverNumber`,
`incomingCaller`, en de functies `next()`, `exit()`, `reply(msg)` en
`forward(nr, anoniem)`.

Deze resource hangt **altijd op** (`exit()`): er zit geen speler achter dat
nummer, dus doorverbinden zou alleen een gesprek opleveren dat niemand opneemt.
De bevestiging komt per SMS, en dat is meteen het bewijs dat je oproep is
aangekomen.

> **Let op bij `getPlayerData`.** Die wil een *locator-object* —
> `{source=…}`, `{identifier=…}` of `{phoneNumber=…}` — en geeft een platte
> tabel met `phoneNumber` terug, geen object met `getPhoneNumber()`. Er een
> getal in stoppen levert stilzwijgend `null` op. Daar is `los_insurance` al
> een keer in getrapt.

Het nummer staat niet automatisch in de contactenlijst van spelers. Dat is een
rij in NPWD's eigen contacten-tabel; zet hem er handmatig in of laat spelers het
nummer intoetsen.

## Waar de taxi vandaan komt

`Config.depots` is **leeg gelaten, en dat is een keuze**. qbx_taxijob heeft
alleen ophaal- en afzetpunten voor NPC-ritten in zijn config, geen depot, en er
worden hier geen coördinaten uit het hoofd opgeschreven.

Zolang die lijst leeg is spawnt de taxi op een wegknooppunt tussen 150 en 350
meter van de speler, buiten beeld. Dat werkt overal op de kaart en is sneller
dan vanuit Los Santos naar Paleto rijden. Wil je een echt depot, zet er dan
`vec4`'s in die je in-game hebt opgemeten.

## Prestatie

Geen enkele permanente lus. Alles zit in de rit-thread van de speler die belt,
en die stopt zodra de rit klaar is, mislukt, of de speler uitstapt. Zonder rit
kost deze resource niets.

## Afrekenen

Starttarief $50, $35 per kilometer hemelsbreed tussen instap- en uitstappunt,
afgetopt op $900. De client meldt de afstand; de server begrenst hem. Een
aangepaste client kan zichzelf hooguit een goedkopere rit geven — nooit een
duurdere of een negatieve.

Stap je onderweg uit, dan stopt de rit en wordt er niets afgeschreven.

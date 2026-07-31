--[[
    los_aitaxi - Downtown Cab Co.

    Volledig nieuw geschreven voor Qbox. `_external/mns-aitaxi` is alleen als
    concept gebruikt en is als basis onbruikbaar: naast elk bestand staan daar
    ook _fixed, _new, _updated en standalone_ varianten van datzelfde bestand,
    en welke het origineel laadt is niet af te leiden.

    HOE HET LOOPT
      1. Je belt het nummer van de taxicentrale met NPWD.
      2. Rijdt er iemand met de job `taxi` on duty, dan krijg je een SMS dat er
         een echte chauffeur beschikbaar is. Er komt geen AI. Spelers gaan voor.
      3. Anders rijdt er een taxi uit het dichtstbijzijnde depot naar je toe.
      4. Je stapt in en zet een waypoint op de kaart. De chauffeur rijdt erheen.
      5. Bij aankomst betaal je de ritprijs; taxi en chauffeur verdwijnen.

    GEEN COMMANDO
    `/aitaxi` bestaat bewust niet. De centrale bel je, net als elke andere
    dienst.

    GEEN PERMANENTE LUSSEN
    Alles wat draait zit in de rit-thread van de speler die belt, en die stopt
    als de rit klaar is. Zonder rit kost deze resource niets.
]]

Config = {}

Config.debug = false

--- Jobnaam die als taxichauffeur telt. Is hiervan iemand on duty, dan komt de
--- AI niet. `taxi` staat zo in qbx_core/shared/jobs.lua; die job heeft geen
--- `type`, dus dit is bewust een naam en geen jobtype.
Config.taxiJob = 'taxi'

--- Het nummer van de centrale in NPWD. Bellen naar dit nummer start een rit.
---
--- LET OP: 4040 is al van de black market (md-drugs, shared/DrugData) en 1500
--- van de overheidswaarschuwingen (los_insurance). Controleer bij het wijzigen
--- dat het nummer nergens anders als senderNumber staat.
Config.phoneNumber = '4747'

--- Naam waarmee de centrale terugbericht.
Config.companyName = 'Downtown Cab Co.'

--[[
    Het nummer als vast contact in de telefoon.

    NPWD heeft hier geen export voor - de tien server-exports in de bundle zijn
    emitMessage, generatePhoneNumber, getPhoneNumber, getPlayerData,
    isPhoneNumberBusy, isPlayerBusy, newPlayer, onCall, onMessage en
    unloadPlayer. Contacten zijn puur een rij in `npwd_phone_contacts`, met de
    citizenid als identifier (zo registreert qbx_npwd de speler).

    Daarom zet deze resource het contact er bij het inladen zelf in, één keer per
    character. Zet op false als je liever hebt dat spelers het nummer moeten
    horen van iemand anders.
]]
Config.addContact = true

--- Avatar-URL voor het contact. Leeg laten mag; NPWD toont dan een letter.
Config.contactAvatar = ''

--- Seconden tussen het telefoontje en het uitrijden van de taxi.
Config.responseDelay = 8

--- Seconden waarna een rit wordt afgebroken als de taxi de speler niet bereikt.
Config.pickupTimeout = 180

--- Seconden dat de taxi op je blijft wachten nadat hij is aangekomen.
Config.waitTimeout = 90

--- Seconden waarna een rit naar de bestemming wordt afgebroken.
Config.rideTimeout = 900

--- Hoe dicht de taxi moet zijn voordat hij als "aangekomen" telt.
Config.arriveDistance = 15.0

--- Hoe dicht bij de bestemming de rit eindigt.
Config.dropoffDistance = 25.0

Config.models = {
    vehicle = `taxi`,
    driver  = `a_m_m_indian_01`,
}

--[[
    Waar de taxi vandaan komt.

    LEEG GELATEN, EN DAT IS EEN KEUZE. qbx_taxijob heeft alleen ophaal- en
    afzetpunten voor NPC-ritten in zijn config, geen depot. Ik ga geen
    coordinaten uit mijn hoofd opschrijven - dat is precies waar Tim eerder
    terecht op corrigeerde.

    Zolang deze lijst leeg is spawnt de taxi op een wegknooppunt tussen
    `spawnMinDistance` en `spawnMaxDistance` van de speler, buiten beeld. Dat
    werkt overal op de kaart en is bovendien sneller dan uit Los Santos naar
    Paleto rijden.

    Wil je een echt depot, zet er dan vec4's in die je in-game hebt opgemeten;
    de dichtstbijzijnde wint dan.
]]
Config.depots = {}

--- Alleen gebruikt als `depots` leeg is.
Config.spawnMinDistance = 150.0
Config.spawnMaxDistance = 350.0

Config.fare = {
    --- Vast starttarief.
    base = 50,

    --- Per kilometer hemelsbreed tussen instappen en uitstappen.
    perKm = 35,

    --- Waar de rekening heen gaat.
    account = 'bank',

    --- Bovengrens, zodat een rit naar Paleto geen halve maandhuur kost.
    max = 900,
}

-- ox_lib require geeft de returnwaarde van dit bestand terug. Zonder deze regel
-- krijgt `local config = require "shared.config"` de boolean true.
return Config

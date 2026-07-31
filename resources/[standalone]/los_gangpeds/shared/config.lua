--[[
    los_gangpeds - wereld-gangleden herkennen spelers van hun eigen gang.

    HOE DIT WERKT
    GTA deelt peds in relationship groups in. Ambient gangleden zitten in
    groepen als AMBIENT_GANG_BALLAS, en die groepen haten elkaar al in de
    basis. Zet je de ped van een speler in dezelfde groep, dan behandelt de
    wereld hem als lid: eigen gang laat hem met rust en verdedigt hem, rivalen
    worden vijandig. Precies het vanilla-gedrag.

    LEES DIT VOORDAT JE HET AANZET
    Dit is de fragielste feature van het hele traject. Eerlijk over de grenzen:

    1. Relationship groups zijn CLIENT-SIDE. Het gedrag van een ped wordt
       berekend op de client die die ped bezit. Twee spelers kunnen dezelfde
       ped zich net anders zien gedragen.

    2. De speler uit de PLAYER-groep halen raakt meer dan gangs. Politie-AI,
       het wanted-systeem en willekeurige burgers reageren op die groep. Zet
       `keepPoliceNeutral` aan om dat deels te herstellen.

    3. Ambient gangleden spawnen alleen in hun eigen wijk. Buiten die wijk
       gebeurt er niets, hoe hoog je grade ook is.

    4. Bij veel spelers tegelijk in dezelfde straat wordt dit rommelig. Het is
       leuk, geen fundament.

    Werkt het niet prettig? Zet `enabled = false` en er verandert niets aan de
    rest van de server.
]]

Config = {}

Config.enabled = true

--- Debugprints bij elke groepswissel.
Config.debug = false

--[[
    Gangnaam uit qbx_core/shared/gangs.lua -> GTA relationship group.

    mafia staat er bewust NIET in: GTA heeft geen ambient maffia-peds, dus er
    is geen groep om bij aan te sluiten. Een bestaande groep lenen zou de
    maffia laten samenvallen met een straatgang, wat verkeerd voelt.
]]
Config.groups = {
    ballas    = 'AMBIENT_GANG_BALLAS',
    families  = 'AMBIENT_GANG_FAMILY',
    vagos     = 'AMBIENT_GANG_MEXICAN',
    marabunta = 'AMBIENT_GANG_MARABUNTE',
    lostmc    = 'AMBIENT_GANG_LOST',
}

--- Groep waar de speler in zit als hij geen (herkende) gang heeft.
Config.defaultGroup = 'PLAYER'

--[[
    Relatie tussen de speler en zijn eigen gang.
    0 = companion, 1 = respect, 2 = like, 3 = neutral, 4 = dislike, 5 = hate

    `respect` is het vanilla-niveau voor "eigen gang". Op `companion` gaan ze je
    achterna lopen, wat je niet wilt.
]]
Config.ownGangRelation = 1

--- Relatie tot rivaliserende gangs. 5 = hate, zoals vanilla.
Config.rivalRelation = 5

--[[
    Politie neutraal houden tegenover ganggroepen.

    Zonder dit gaan ambient gangleden op agenten schieten zodra een speler in
    hun groep zit, en dat levert chaos op waar niemand om vroeg.
]]
Config.keepPoliceNeutral = true

--- Politie-relationship groups die neutraal blijven.
Config.policeGroups = {
    'COP',
    'SECURITY_GUARD',
    'ARMY',
}

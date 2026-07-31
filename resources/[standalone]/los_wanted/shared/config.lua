--[[
    los_wanted - AI-politie die meebeweegt met het aantal echte agenten.

    WAAROM DIT ER IS
    qbx_disableservices zet SetMaxWantedLevel(0) en schakelt elke
    politie-dispatchservice uit. Er is op deze server dus helemaal geen
    AI-politie, ook niet als er nul agenten online zijn. Dat maakt criminaliteit
    op een leeg uur gratis.

    DE DRIE STANDEN
      full     0 agenten on duty        AI-politie doet alles, tot en met de
                                        maximale wanted level.
      passive  1 t/m fewOfficersUpTo    AI-politie komt wel opdagen, maar
                                        schiet niet. Ze rijden, achtervolgen en
                                        blokkeren; de echte agenten doen het
                                        werk dat telt.
      off      meer dan fewOfficersUpTo geen AI-politie.

    EERLIJK OVER "SCHIET NIET"
    Daar bestaat geen server-instelling voor. De peds die GTA zelf spawnt worden
    client-side ontwapend en op accuracy 0 gezet zodra ze in beeld komen. Dat
    werkt, maar het is een heuristiek: tussen het spawnen van een agent en de
    eerstvolgende scan (zie passive.scanInterval) kan er een schot vallen. Wil
    je die kans nul hebben, zet dan `passive` gelijk aan `off` - dan komt er in
    die stand simpelweg geen AI-politie.

    WAT DEZE RESOURCE BEHEERT
    De politie-dispatchservices en SetMaxWantedLevel. De rest van
    qbx_disableservices - ambulance, brandweer, gangs - blijft van
    qbx_disableservices. Zie de comment in dat config-bestand.
]]

Config = {}

Config.debug = false

--- Jobtype dat als politie telt. qbx_core kent 'leo' als type; de jobnamen
--- police, bcso en sasp vallen daar allemaal onder. Dus geen lijst met
--- jobnamen hier - dat is precies de fout die ps-dispatch ook al maakte.
Config.policeJobType = 'leo'

--- Seconden tussen twee tellingen van de agenten on duty.
Config.checkInterval = 20

--- Tot en met dit aantal agenten on duty geldt de stand `passive`.
--- Daarboven verdwijnt de AI-politie helemaal.
Config.fewOfficersUpTo = 2

--- Maximale wanted level per stand. 0 betekent: geen sterren, dus geen politie.
Config.maxWantedLevel = {
    full = 5,
    passive = 3,
    off = 0,
}

--- Dispatchservices die deze resource aan- en uitzet.
--- 1 PoliceAutomobile · 2 PoliceHelicopter · 4 SwatAutomobile ·
--- 6 PoliceRiders · 7 PoliceVehicleRequest · 8 PoliceRoadBlock ·
--- 9 PoliceAutomobileWaitPulledOver · 10 PoliceAutomobileWaitCruising ·
--- 12 SwatHelicopter · 13 PoliceBoat
--- Bewust NIET: 3 FireDepartment, 5 AmbulanceDepartment, 11 Gangs,
--- 14 ArmyVehicle, 15 BikerBackup. Die blijven van qbx_disableservices.
Config.policeServices = { 1, 2, 4, 6, 7, 8, 9, 10, 12, 13 }

--- In de stand `passive`: hoe vaak er gekeken wordt of er nieuwe politie-peds
--- in de buurt zijn, en binnen welke straal. De scan draait alleen als je zelf
--- sterren hebt, dus normaal gesproken nooit.
Config.passive = {
    scanInterval = 1500,
    radius = 120.0,
}

--- Melding naar ps-dispatch zodra iemand gezocht raakt.
Config.dispatch = {
    enabled = true,

    --- Vanaf hoeveel sterren er een melding uitgaat. Een ster krijg je al van
    --- te hard rijden; vanaf drie is het de moeite waard.
    minLevel = 3,

    --- Seconden voordat dezelfde speler opnieuw een melding kan veroorzaken.
    cooldown = 90,
}

-- ox_lib require geeft de returnwaarde van dit bestand terug. Zonder deze regel
-- krijgt `local config = require "shared.config"` de boolean true.
return Config

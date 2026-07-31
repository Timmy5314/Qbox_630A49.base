--[[
    los_wipe - maandelijkse wipe.

    WAT ER WEG GAAT EN WAT BLIJFT
    Weg:    geld, inventories, voertuigen, eigendommen (elk apart aan/uit).
    Blijft: characters, identiteiten en spelersaccounts. Altijd. Daar zit geen
            schakelaar op, want dat is het hele punt van een wipe die spelers
            niet wegjaagt.

    DRIE SLOTEN VOOR HET ECHT DRAAIT
      1. Config.dryRun staat op true. Dan wordt alles berekend en gelogd, maar
         niets aangepast.
      2. Config.armed staat op false. Ook met dryRun = false gebeurt er niets
         zolang dit uit staat.
      3. Er moet een dumpbevestiging staan. Zie hieronder.

    OVER DE DATABASE-DUMP
    Deze resource kan GEEN mysqldump draaien. FiveM's Lua heeft geen os.execute
    en geen shell; dat is geen instelling maar een harde grens. Wat hij wel doet:
      - weigeren te draaien tot `Config.dumpConfirmed` op de datum van vandaag
        staat, zodat het een bewuste handeling is;
      - vlak voor de wipe een JSON-momentopname wegschrijven van precies de
        rijen die hij gaat aanraken, via SaveResourceFile.
    Die momentopname is een vangnet, geen vervanging van een echte dump.
]]

Config = {}

Config.debug = false

--- Alles berekenen en loggen, niets wijzigen. Laat dit op true tot je de
--- droogloop-uitvoer hebt gelezen.
Config.dryRun = true

--- Tweede slot. Ook met dryRun = false gebeurt er niets zolang dit false is.
Config.armed = false

--[[
    Derde slot. Zet dit op de datum waarop jij een dump hebt gemaakt, in de vorm
    'YYYY-MM-DD'. De wipe weigert als deze datum niet die van vandaag is.

    Zo kan een wipe nooit draaien op een dump van vorige maand, en kan hij ook
    niet per ongeluk opnieuw draaien nadat je hem een keer hebt uitgevoerd.
]]
Config.dumpConfirmed = ''

--- Dag van de maand waarop de wipe draait.
Config.dayOfMonth = 1

--- Uur (serverzijde, 24-uurs) waarop hij draait.
Config.hour = 6

--- Wat er gewipet wordt.
Config.wipe = {
    money = true,       -- cash, bank en black_money terug naar de startwaardes
    inventories = true, -- speler-inventories, kluizen, kofferbakken, dashboardkastjes
    vehicles = true,    -- player_vehicles
    properties = false, -- ps-housing; standaard UIT, dat is een grote ingreep
}

--- Waar geld op terugkomt na een wipe.
Config.startingMoney = {
    cash = 500,
    bank = 5000,
    black_money = 0,
}

--- Minuten voor de wipe waarop er gewaarschuwd wordt.
Config.warnMinutes = { 30, 15, 5, 1 }

--- Discord-webhook voor de aankondiging. Leeg = geen Discord.
--- Zet hem in secrets.cfg als convar en lees hem daar uit; niet hier hardcoderen.
Config.webhookConvar = 'los_wipe:webhook'

return Config

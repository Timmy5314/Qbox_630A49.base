--[[
    Items die GEEN afbeelding hebben in ox_inventory/web/images, maar wel in de
    carmap-repo. Voor precies deze namen valt modules/items/shared.lua terug op
    de carmap-URL (zie de convar carmap:baseurl in server.cfg).

    Bewust een lijst en geen "probeer altijd carmap": items die hier WEL een
    lokaal bestand hebben moeten dat lokale bestand houden. Dat scheelt een
    HTTP-request per item en voorkomt dat de look verandert.

    Gegenereerd door de bestandsnamen in web/images te vergelijken met
    github.com/Timmy5314/carmap -> carmap/items. Komt er een afbeelding lokaal
    bij, haal de naam dan hier weg.
]]

return {
    ['beef'] = true,
    ['bread'] = true,
    ['cappuccino'] = true,
    ['cheese'] = true,
    ['chocolate'] = true,
    ['coca_leaf'] = true,
    ['coke'] = true,
    ['energy_drink'] = true,
    ['fixkit'] = true,
    ['heroin'] = true,
    ['hotdog'] = true,
    ['hotsauce'] = true,
    ['keys'] = true,
    ['latte'] = true,
    ['marlboro'] = true,
    ['martini'] = true,
    ['milk'] = true,
    ['morphine'] = true,
    ['needle'] = true,
    ['pasta'] = true,
    ['poppyresin'] = true,
    ['redw'] = true,
    ['sugar'] = true,
    ['taco'] = true,
    ['tomato'] = true,
    ['tomato_seed'] = true,
    ['vicodin'] = true,
    ['weaponlicense'] = true,
    ['wheat_seed'] = true,
    ['xanax'] = true,
}

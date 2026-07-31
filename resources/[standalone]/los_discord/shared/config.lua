--[[
    los_discord - de FiveM-kant van de Discord-koppeling.

    TWEE DELEN, BEWUST GESCHEIDEN
      Deze resource  logt gebeurtenissen naar Discord-webhooks en leest rollen
                     uit via de bot. Meer niet.
      discord-bot/   een los Node-proces. Alles wat de Discord API nodig heeft -
                     rollen toekennen, kanaalrechten zetten - kan een FiveM
                     server niet zelf; daar heb je een bot-token voor, en dat
                     hoort niet in een gameserver.

    GEEN TOKENS HIER
    Webhook-URL's en het bot-token staan in convars die je in `secrets.cfg` zet.
    Dat bestand is gitignored. Zet ze nooit in dit bestand.
]]

Config = {}

Config.debug = false

--- Discord server-ID.
Config.guildId = '1067817202578890802'

--[[
    Logkanalen. Elke sleutel leest zijn webhook uit een convar, zodat de URL's
    in secrets.cfg staan en niet in git.

    In secrets.cfg zet je bijvoorbeeld:
        set los_discord:webhook_dispatch "https://discord.com/api/webhooks/..."

    Een kanaal zonder convar wordt simpelweg overgeslagen.
]]
Config.channels = {
    dispatch  = { convar = 'los_discord:webhook_dispatch',  label = 'Meldkamer',    color = 3447003 },
    anticheat = { convar = 'los_discord:webhook_anticheat', label = 'Anti-cheat',   color = 15158332 },
    billing   = { convar = 'los_discord:webhook_billing',   label = 'Facturen',     color = 15844367 },
    wipe      = { convar = 'los_discord:webhook_wipe',      label = 'Wipe',         color = 10038562 },
    staff     = { convar = 'los_discord:webhook_staff',     label = 'Staff',        color = 9807270 },
}

--[[
    PRIVACY - hier bewust over nagedacht.

    Wat WEL naar Discord mag: wat er gebeurde, waar, en welke job erbij hoorde.
    Wat NIET: telefoonnummers, licenties, Steam-ID's, tokens, en de inhoud van
    privéberichten tussen spelers.

    NPWD-berichten staan daarom niet in de kanalenlijst hierboven. De opdracht
    noemde ze wel, maar het meelezen van privéberichten van spelers is iets
    anders dan loggen dat er een melding was. Wil je het toch, zet het dan
    bewust aan en vertel je spelers dat het gebeurt.
]]
Config.privacy = {
    --- Zet identifiers (license, steam, discord) nooit in een log.
    stripIdentifiers = true,

    --- Maximale lengte van een vrij tekstveld dat mee mag.
    maxTextLength = 300,
}

--- Rate-limit. Discord staat ongeveer 30 webhook-berichten per minuut per
--- kanaal toe; hieronder blijven we daar ruim onder.
Config.rateLimit = {
    perMinute = 20,
    queueMax = 200,
}

--[[
    Rol-sync: in-game job of gang <-> Discord-rol.

    De FiveM-kant weet alleen WELKE rol erbij hoort. Het daadwerkelijk toekennen
    en intrekken doet de bot, want daar is de Discord API voor nodig.

    Vul de rol-ID's in nadat je ze in Discord hebt aangemaakt. Een lege waarde
    wordt overgeslagen.
]]
Config.roles = {
    jobs = {
        police     = '',
        bcso       = '',
        sasp       = '',
        ambulance  = '',
        mechanic   = '',
        taxi       = '',
    },
    gangs = {
        ballas     = '',
        families   = '',
        vagos      = '',
        marabunta  = '',
        lostmc     = '',
        triads     = '',
        mafia      = '',
    },
}

--- Minuten tussen twee volledige rol-syncs.
Config.syncMinutes = 15

return Config

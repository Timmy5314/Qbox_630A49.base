--[[
    /makehouse - zet op de plek waar je staat een huis TE KOOP.

    WAAROM DIT ER IS
    Huizen bestaan in ps-housing alleen als rij in de tabel `properties`. Er zit
    geen standaardlijst met locaties in, ook niet in de officiele repo: wat daar
    in `Config.Shells` staat (Office, Store, House 1..4, Trailer) zijn
    INTERIEURTYPES, geen plekken op de kaart. De `doorOffset` daarin is waar de
    deur BINNEN dat interieur zit.

    De bedoelde weg is de makelaar (ps-realtor, job `realestate`). Die werkt, maar
    is omslachtig als je alleen even de kaart wilt vullen of iets wilt testen.
    Dit commando doet precies dat ene ding: een pand aanmaken op je eigen positie,
    te koop, met de juiste straatnaam en regio erbij.

    Gebruik:
        /makehouse                     -- 'House 1', prijs 150000
        /makehouse 250000              -- andere prijs
        /makehouse 250000 "2 Floor House"

    Geldige shells staan in shared/config.lua -> Config.Shells.
    Alleen voor group.admin.
]]

local DEFAULT_SHELL = 'House 1'
local DEFAULT_PRICE = 150000

lib.addCommand('makehouse', {
    help = 'Zet een huis te koop op de plek waar je staat (admin)',
    restricted = 'group.admin',
    params = {
        { name = 'price', type = 'number', help = 'Vraagprijs', optional = true },
        { name = 'shell', type = 'string', help = 'Interieurtype uit Config.Shells', optional = true },
    },
}, function(source, args)
    local shell = args.shell or DEFAULT_SHELL

    if not Config.Shells[shell] then
        local names = {}
        for name in pairs(Config.Shells) do names[#names + 1] = name end
        table.sort(names)

        return exports.qbx_core:Notify(source,
            ('Onbekend interieur "%s". Keuze uit: %s'):format(shell, table.concat(names, ', ')),
            'error', 12000)
    end

    -- De client weet de straatnaam en de regio; de server niet.
    local place = lib.callback.await('ps-housing:cb:makehousePlace', source)
    if not place then
        return exports.qbx_core:Notify(source, 'Kon je positie niet bepalen.', 'error')
    end

    local price = math.floor(tonumber(args.price) or DEFAULT_PRICE)
    if price < 0 then price = 0 end

    local id = RegisterProperty({
        street = place.street,
        region = place.region,
        description = ('Te koop via de gemeente. %s, %s.'):format(place.street, place.region),
        for_sale = 1,
        price = price,
        shell = shell,

        -- length/width bepalen de grootte van de deurzone waar je op target.
        -- 1 x 2 is wat de officiele config voor appartementsdeuren gebruikt.
        door_data = {
            x = place.coords.x,
            y = place.coords.y,
            z = place.coords.z,
            h = place.heading,
            length = 1.0,
            width = 2.0,
        },
    })

    if not id then
        return exports.qbx_core:Notify(source, 'Aanmaken mislukt, zie de serverconsole.', 'error')
    end

    exports.qbx_core:Notify(source,
        ('Huis #%s te koop gezet voor $%s (%s) op %s.')
            :format(id, price, shell, place.street),
        'success', 10000)

    lib.print.info(('%s maakte pand #%s aan: %s, %s (%s, $%d)')
        :format(GetPlayerName(source), id, place.street, place.region, shell, price))
end)

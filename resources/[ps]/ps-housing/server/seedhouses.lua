--[[
    /seedhouses - zet in een keer een woonwijk met kant-en-klare huizen te koop.

    WAAR DE COORDINATEN VANDAAN KOMEN
    Uit esx_property (github.com/zaphosting/esx_12 -> esx_property/esx_property.sql),
    de tabel `properties`. Dat script draait al jaren en die deuren zijn dus in de
    praktijk beproefd - dat is precies waarom ze hier gebruikt worden en niet een
    lijst die ik zelf bij elkaar zoek.

    Overgenomen zijn alleen de rijen met is_single = 1 en is_gateway = 0: de losse
    villa's. De appartementen uit dat bestand zijn overgeslagen, want die regelt
    ps-housing zelf al via Config.Apartments (zie shared/config.lua).

    Het zijn er acht en ze liggen allemaal in Vinewood Hills en Richman, dicht bij
    elkaar - een woonwijk, zoals bedoeld.

    VELD-VERTALING
      esx `entering`   -> ps-housing door_data (x, y, z)  de deur op straat
      esx `outside`    -> alleen gebruikt om de kijkrichting van de deur uit te
                          rekenen; ps-housing slaat die zelf niet op
      esx `room_menu`  -> NIET gebruikt. Dat is de positie van het kamermenu
                          binnen het pand, geen oprit.

    GARAGE
    garage_data staat voorlopig gelijk aan de deur. Dat is een plaatshouder: het
    veld is gevuld en klopt qua pand, maar het is niet opgemeten. Meet de echte
    oprit op en pas hem aan.

    Draai dit een keer. Bij een tweede keer worden bestaande adressen overgeslagen,
    dus je krijgt geen dubbele huizen.
]]

---@type { street: string, region: string, shell: string, price: number, enter: vector3, out: vector3 }[]
local HOUSES = {
    {
        street = '2677 Whispymound Drive', region = 'Vinewood Hills',
        shell = '2 Floor House', price = 1500000,
        enter = vec3(119.384, 564.89, 182.959),
        out = vec3(119.249, 567.798, 182.131),
    },
    {
        street = '2045 North Conker Avenue', region = 'Vinewood Hills',
        shell = '2 Floor House', price = 1500000,
        enter = vec3(372.796, 428.327, 144.685),
        out = vec3(372.454, 432.886, 143.443),
    },
    {
        street = '2044 North Conker Avenue', region = 'Vinewood Hills',
        shell = '2 Floor House', price = 1500000,
        enter = vec3(346.964, 440.8, 146.702),
        out = vec3(350.535, 443.329, 145.764),
    },
    {
        street = '3655 Wild Oats Drive', region = 'Vinewood Hills',
        shell = '2 Floor House', price = 1500000,
        enter = vec3(-176.003, 502.696, 136.421),
        out = vec3(-177.927, 506.412, 135.0664),
    },
    {
        street = '2862 Hillcrest Avenue', region = 'Vinewood Hills',
        shell = 'House 2', price = 1500000,
        enter = vec3(-686.554, 596.58, 142.641),
        out = vec3(-689.492, 599.019, 142.059),
    },
    {
        street = '2868 Hillcrest Avenue', region = 'Vinewood Hills',
        shell = 'House 2', price = 1500000,
        enter = vec3(-752.82, 620.494, 141.588),
        out = vec3(-750.919, 621.281, 141.254),
    },
    {
        street = '2874 Hillcrest Avenue', region = 'Vinewood Hills',
        shell = 'House 2', price = 1500000,
        enter = vec3(-853.346, 696.678, 147.782),
        out = vec3(-855.007, 701.628, 147.773),
    },
    {
        street = '2113 Mad Wayne Thunder', region = 'Richman',
        shell = '2 Floor House', price = 1500000,
        enter = vec3(-1294.433, 454.955, 96.462),
        out = vec3(-1298.851, 455.453, 96.517),
    },
}

--- esx_property slaat geen heading op. De richting waarin de deur kijkt is af te
--- leiden uit het punt waar je naar buiten komt: dat ligt per definitie voor de
--- deur. In GTA is de voorwaartse vector (-sin(h), cos(h)).
---@param from vector3 de deur
---@param to vector3 het punt ervoor
---@return number heading 0-360
local function headingBetween(from, to)
    local dx, dy = to.x - from.x, to.y - from.y
    if dx == 0 and dy == 0 then return 0.0 end

    return (math.deg(math.atan(-dx, dy)) + 360.0) % 360.0
end

---@param street string
---@return boolean
local function alreadyExists(street)
    for _, property in pairs(PropertiesTable) do
        local data = property.propertyData
        if data and not data.apartment and data.street == street then return true end
    end
    return false
end

lib.addCommand('seedhouses', {
    help = 'Zet de Vinewood Hills woonwijk in een keer te koop (admin)',
    restricted = 'group.admin',
}, function(source)
    local made, skipped, failed = 0, 0, 0

    for i = 1, #HOUSES do
        local house = HOUSES[i]

        if alreadyExists(house.street) then
            skipped = skipped + 1
            goto continue
        end

        if not Config.Shells[house.shell] then
            lib.print.error(('seedhouses: interieur "%s" bestaat niet, %s overgeslagen')
                :format(house.shell, house.street))
            failed = failed + 1
            goto continue
        end

        local id = RegisterProperty({
            street = house.street,
            region = house.region,
            description = ('%s, %s. Te koop.'):format(house.street, house.region),
            for_sale = 1,
            price = house.price,
            shell = house.shell,
            door_data = {
                x = house.enter.x,
                y = house.enter.y,
                z = house.enter.z,
                h = headingBetween(house.enter, house.out),
                length = 1.0,
                width = 2.0,
            },
            -- Plaatshouder: zelfde punt als de deur. Zie de kop van dit bestand.
            garage_data = { x = house.enter.x, y = house.enter.y, z = house.enter.z },
        })

        if id then
            made = made + 1
        else
            failed = failed + 1
        end

        ::continue::
    end

    local message = ('%d huizen te koop gezet, %d bestonden al'):format(made, skipped)
    if failed > 0 then message = ('%s, %d mislukt (zie console)'):format(message, failed) end

    exports.qbx_core:Notify(source, message, failed > 0 and 'warning' or 'success', 12000)
    lib.print.info(('seedhouses door %s: %s'):format(GetPlayerName(source), message))
end)

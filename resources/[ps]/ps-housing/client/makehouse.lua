--[[
    Levert de gegevens die /makehouse nodig heeft en die alleen de client weet:
    positie, kijkrichting, straatnaam en regio.

    De heading is die van de SPELER, niet van de camera. Ga dus met je rug naar
    het huis staan zoals je naar buiten zou stappen - dan wijst de deurzone de
    goede kant op.
]]

lib.callback.register('ps-housing:cb:makehousePlace', function()
    local coords = GetEntityCoords(cache.ped)

    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)

    if crossingHash and crossingHash ~= 0 then
        local crossing = GetStreetNameFromHashKey(crossingHash)
        if crossing and crossing ~= '' then
            street = ('%s / %s'):format(street, crossing)
        end
    end

    return {
        coords = coords,
        heading = GetEntityHeading(cache.ped),
        street = street ~= '' and street or 'Unknown Street',
        region = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z)),
    }
end)

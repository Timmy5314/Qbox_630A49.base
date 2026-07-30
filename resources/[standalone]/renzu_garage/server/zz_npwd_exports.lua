--[[
    renzu_garage — locatie-exports voor externe resources (NPWD garage-app, ps-mdt).

    De configs `garagecoord` (conf/public_garage.lua) en `impoundcoord` (conf/impound.lua)
    zijn shared_scripts en dus alleen binnen renzu_garage zichtbaar. Andere resources
    hebben de coördinaten nodig om een waypoint te kunnen zetten. Deze file publiceert
    een read-only kopie.

    Bestandsnaam begint met zz_ zodat hij als laatste laadt in de `server/*.lua` glob —
    de config-globals zijn dan gegarandeerd gevuld.
]]

local function buildGarageIndex()
    local index = {}

    for i = 1, #(garagecoord or {}) do
        local g = garagecoord[i]
        if g and g.garage then
            index[g.garage] = {
                id       = g.garage,
                label    = g.name or ('Garage ' .. g.garage),
                type     = g.Type or 'car',
                kind     = 'public',
                coords   = vec3(g.garage_x or 0.0, g.garage_y or 0.0, g.garage_z or 0.0),
                job      = g.job,
            }
        end
    end

    for i = 1, #(impoundcoord or {}) do
        local g = impoundcoord[i]
        if g and g.garage then
            index[g.garage] = {
                id       = g.garage,
                label    = g.name or ('Impound ' .. g.garage),
                type     = g.Type or 'car',
                kind     = 'impound',
                coords   = vec3(g.garage_x or 0.0, g.garage_y or 0.0, g.garage_z or 0.0),
                job      = g.job,
            }
        end
    end

    -- Let op: de globale `heli` in conf/heli_garage.lua is een job->modellen lijst,
    -- geen locatielijst. Helikoptergarages staan gewoon in `garagecoord` met Type='heli'.

    return index
end

local garageIndex

--- Alle garages (publiek + impound + heli) op id.
--- @return table<string, {id:string,label:string,type:string,kind:string,coords:vector3,job:string?}>
local function getGarageIndex()
    if not garageIndex then garageIndex = buildGarageIndex() end
    return garageIndex
end

exports('GetGarageIndex', getGarageIndex)

--- Eén garage opzoeken op id.
exports('GetGarageById', function(id)
    if not id then return nil end
    return getGarageIndex()[id]
end)

--- Het eerste impound-punt, als fallback voor in beslag genomen voertuigen.
exports('GetDefaultImpound', function()
    for _, g in pairs(getGarageIndex()) do
        if g.kind == 'impound' then return g end
    end
    return nil
end)

--- Laatst bekende parkeerpositie van een voertuig (realistic park / parking meter).
--- @param plate string
--- @return vector3?
exports('GetParkedCoords', function(plate)
    if not plate then return nil end
    local trimmed = plate:gsub('^%s*(.-)%s*$', '%1'):upper()

    local row = MySQL.single.await(
        'SELECT coord FROM parking_meter WHERE TRIM(UPPER(plate)) = ? LIMIT 1',
        { trimmed }
    )
    if not row or not row.coord then return nil end

    local ok, decoded = pcall(json.decode, row.coord)
    if not ok or type(decoded) ~= 'table' then return nil end

    local x = decoded.x or decoded[1]
    local y = decoded.y or decoded[2]
    local z = decoded.z or decoded[3]
    if not x or not y then return nil end

    return vec3(x + 0.0, y + 0.0, (z or 0.0) + 0.0)
end)

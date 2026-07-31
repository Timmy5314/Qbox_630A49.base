local config = require 'shared.config'

local ox = exports.ox_inventory

---Kentekens uit natives hebben trailing spaces; ox.cfg draait met
---inventory:trimplate. Zonder normaliseren matcht 'ABC123 ' niet op 'ABC123'.
---@param plate string?
---@return string?
local function normalize(plate)
    if type(plate) ~= 'string' then return end
    local trimmed = plate:gsub('^%s+', ''):gsub('%s+$', '')
    return trimmed ~= '' and trimmed:upper() or nil
end

---@param src number
---@param plate string
---@return table? slot
local function findKey(src, plate)
    plate = normalize(plate)
    if not plate then return end

    local slots = ox:Search(src, 'slots', config.item)
    if type(slots) ~= 'table' then return end

    local now = os.time()

    for i = 1, #slots do
        local slot = slots[i]
        local meta = slot.metadata

        if meta and normalize(meta.plate) == plate then
            -- Een verlopen tijdelijke sleutel telt niet meer mee, maar wordt
            -- hier niet weggegooid: dat gebeurt pas als hij echt gebruikt wordt,
            -- zodat de speler ziet dat hij een dode sleutel bij zich heeft.
            if not meta.expires or meta.expires > now then
                return slot
            end
        end
    end
end

-- =========================================================================
--  Exports
-- =========================================================================

---@param src number
---@param plate string
---@param model? string label van het voertuig
---@param temporary? boolean job- of gangvoertuig
---@return boolean
local function giveKeyItem(src, plate, model, temporary)
    plate = normalize(plate)
    if not plate then return false end

    local existing = findKey(src, plate)

    if existing then
        -- Geen tweede sleutel voor hetzelfde kenteken. Wel mag een tijdelijke
        -- sleutel vervangen worden door een vaste - koop je het busje waarin je
        -- reed, dan hou je geen sleutel over die na vier uur vervalt. Andersom
        -- niet: een job-run degradeert je eigen sleutel niet.
        if temporary or not existing.metadata.temporary then return true end

        ox:RemoveItem(src, config.item, 1, nil, existing.slot)
    end

    local metadata = {
        plate = plate,
        model = model or nil,
        label = ('%s'):format(plate),
        description = model and ('%s - %s'):format(model, plate) or plate,
    }

    if temporary and config.temporaryLifetime > 0 then
        metadata.expires = os.time() + config.temporaryLifetime
        metadata.temporary = true
    end

    return ox:AddItem(src, config.item, 1, metadata) and true or false
end

exports('GiveKeyItem', giveKeyItem)

---@param src number
---@param plate string
---@return boolean removed
local function removeKeyItem(src, plate)
    local slot = findKey(src, plate)
    if not slot then return false end

    return ox:RemoveItem(src, config.item, 1, nil, slot.slot) and true or false
end

exports('RemoveKeyItem', removeKeyItem)

---@param src number
---@param plate string
---@return boolean
exports('HasKeyItem', function(src, plate)
    return findKey(src, plate) ~= nil
end)

-- =========================================================================
--  De koppeling met qbx_vehiclekeys
-- =========================================================================

---De client meldt dat hij achter het stuur zit. De server bepaalt of daar een
---sleutel bij hoort: het meegestuurde netId wordt getoetst op afstand, en het
---kenteken komt van het voertuig zelf - niet uit het event.
RegisterNetEvent('los_vehiclekeys:requestKeys', function(netId)
    local src = source

    netId = tonumber(netId)
    if not netId then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    if #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > config.maxDistance then return end

    local plate = normalize(GetVehicleNumberPlateText(vehicle))
    if not plate or not findKey(src, plate) then return end

    -- qbx_vehiclekeys houdt de daadwerkelijke toegang bij; wij bepalen alleen
    -- dat deze speler er recht op heeft.
    exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true)

    if config.debug then
        lib.print.info(('sleutel toegekend aan %s voor %s'):format(src, plate))
    end
end)

---Staat er een voertuig met dit kenteken naast de speler?
---@param src number
---@param plate string
---@return boolean
local function nearbyPlateMatches(src, plate)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local vehicles = GetAllVehicles()

    for i = 1, #vehicles do
        local veh = vehicles[i]

        if normalize(GetVehicleNumberPlateText(veh)) == plate
            and #(coords - GetEntityCoords(veh)) <= config.maxDistance then
            return true
        end
    end

    return false
end

--[[
    Job-, missie- en drugsvoertuigen.

    md-drugs vraagt zijn sleutels aan via community_bridge, en die gebruikt
    daarvoor het qb-event `qb-vehiclekeys:server:AcquireVehicleKeys`. Dat event
    is de gemeenschappelijke ingang voor alles wat een voertuig uitdeelt zonder
    dat het op iemands naam staat.

    Hier hangt nu een TIJDELIJKE sleutel aan. Een drugsrun-busje legt dus net als
    elke andere auto iets in je zak, alleen vervalt die vanzelf - anders houd je
    na elke run een sleutel over van een voertuig dat allang weg is.

    Bewust RegisterNetEvent en geen AddEventHandler: qbx_vehiclekeys registreert
    dit event ook, maar een resource die zelf registreert krijgt het gegarandeerd
    binnen. Beide handlers draaien naast elkaar; qbx_vehiclekeys regelt de
    toegang, wij het item.
]]
RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = source

    plate = normalize(plate)
    if not plate then return end

    -- Zelfde eis als de bridge van qbx_vehiclekeys stelt aan een client-aanvraag.
    if not nearbyPlateMatches(src, plate) then return end

    giveKeyItem(src, plate, nil, true)
end)

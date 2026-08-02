--[[
    Wat er gebeurt als je auto gesloopt wordt bij de chopshop.

    DE KETEN
      stevo_chopshop sloopt het laatste onderdeel af
        -> vuurt `los_insurance:server:vehicleChopped` met het kenteken
        -> hier: eigenaar opzoeken, voertuig naar de impound met ophaalkosten,
           en de eigenaar inlichten

    WAAROM DE AUTO ALTIJD TERUGKOMT
    Een dure auto definitief kwijtraken is te hard - dan durft niemand nog iets
    anders dan een goedkope bak te rijden. De auto komt dus altijd terug, maar
    je moet ervoor betalen bij de impound. Dat kost geld en tijd zonder dat je
    je bezit kwijt bent.

    WAT DE VERZEKERING DOET
    Die verlaagt de ophaalkosten. Verzekerd betaal je alleen je eigen risico,
    onverzekerd het volle bedrag. Er gaat geen geld naar de eigenaar toe; het
    verschil zit in wat hij moet ophoesten. Dat scheelt ook het hele probleem
    van uitbetalen aan iemand die net is uitgelogd.

    De dief houdt zijn onderdelen. Was het een NPC-auto van straat, dan gebeurt
    hier niets - dat is het normale geval bij een chopshop.
]]

local config = require 'shared.config'

---@param msg string
local function dbg(msg)
    if config.debug then lib.print.info(msg) end
end

---@param plate string?
---@return string?
local function normalizePlate(plate)
    if type(plate) ~= 'string' then return end
    local trimmed = plate:gsub('^%s+', ''):gsub('%s+$', '')
    return trimmed ~= '' and trimmed:upper() or nil
end

--- Zelfde aanpak als server/warnings.lua: de npwd-export is async, dus zowel een
--- tabel als een promise kan terugkomen.
---@param src number
---@return string?
local function phoneNumberOf(src)
    local ok, result = pcall(function()
        return exports.npwd:getPlayerData({ source = src })
    end)

    if not ok or type(result) ~= 'table' then return end

    if result.phoneNumber == nil and type(result.next) == 'function' then
        local awaited
        local awaitOk = pcall(function() awaited = Citizen.Await(result) end)
        result = awaitOk and awaited or nil
    end

    return type(result) == 'table' and result.phoneNumber or nil
end

---@param src number
---@param message string
local function sms(src, message)
    local number = phoneNumberOf(src)
    if not number then return false end

    return pcall(function()
        exports.npwd:emitMessage({
            senderNumber = config.theft.senderNumber,
            targetNumber = number,
            message = message,
        })
    end)
end

---@param plate string
local function vehicleChopped(plate)
    plate = normalizePlate(plate)
    if not plate then return end

    -- pcall: een ontbrekende tabel of kolom geeft bij oxmysql een exception en
    -- geen nil, en dan zou de hele chopshop stukgaan op een verzekeringsdetail.
    local ok, row = pcall(MySQL.single.await, [[
        SELECT citizenid FROM player_vehicles
        WHERE TRIM(UPPER(plate)) = ? LIMIT 1
    ]], { plate })

    if not ok then
        return lib.print.error(('los_insurance: kon %s niet opzoeken: %s'):format(plate, row))
    end

    if not row or not row.citizenid then
        dbg(('%s gesloopt, geen eigenaar - niets te doen'):format(plate))
        return
    end

    local citizenid = row.citizenid

    -- ── Verzekerd of niet ────────────────────────────────────────────────
    local policy = MySQL.single.await([[
        SELECT id FROM los_insurance_policies
        WHERE type = 'vehicle' AND plate = ? AND expires > ?
        LIMIT 1
    ]], { plate, os.time() })

    -- Verzekerd betaal je alleen je eigen risico: het deel dat de polis NIET
    -- dekt. Onverzekerd het volle bedrag.
    local fee = policy
        and math.floor(config.theft.recoveryFee * (1.0 - config.policies.vehicle.coverage))
        or math.floor(config.theft.recoveryFee)

    if fee < 0 then fee = 0 end

    -- ── Naar de impound ──────────────────────────────────────────────────
    -- renzu_garage regelt het ophalen tegen betaling. Zonder garage-id pakt hij
    -- de eerste impound uit zijn eigen config.
    local impounded, reason = false, nil

    if config.theft.impound then
        local callOk, result, why = pcall(function()
            return exports.renzu_garage:ImpoundVehicle(plate, {
                garage = config.theft.impoundGarage,
                fine = fee,
                reason = locale('theft_impound_reason'),
                impounder = locale('theft_impounder'),
            })
        end)

        impounded = callOk and result == true
        reason = callOk and why or result

        if not impounded then
            lib.print.error(('los_insurance: %s niet in beslag kunnen nemen (%s)')
                :format(plate, tostring(reason)))
        end
    end

    -- ── Vastleggen en de eigenaar inlichten ──────────────────────────────
    MySQL.insert('INSERT INTO los_insurance_claims (citizenid, type, plate, amount, reason) VALUES (?, ?, ?, ?, ?)',
        { citizenid, 'vehicle', plate, fee,
          policy and 'Vehicle theft - recovery fee (insured)' or 'Vehicle theft - recovery fee (uninsured)' })

    local owner = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    local src = owner and owner.PlayerData.source

    if src then
        if policy then
            exports.qbx_core:Notify(src, locale('theft_insured', plate, fee), 'inform', 15000)
            sms(src, locale('theft_sms_insured', plate, fee))
        else
            exports.qbx_core:Notify(src, locale('theft_uninsured', plate, fee), 'error', 15000)
            sms(src, locale('theft_sms_uninsured', plate, fee))
        end
    end

    dbg(('%s gesloopt, eigenaar %s, %s, ophaalkosten %d, impound %s')
        :format(plate, citizenid, policy and 'verzekerd' or 'onverzekerd', fee,
                impounded and 'ok' or 'MISLUKT'))
end

--[[
    Bewust AddEventHandler en GEEN RegisterNetEvent.

    Zonder RegisterNetEvent kan een client dit event niet bereiken - en dat is
    hier het hele punt: wie het wel kon afvuren zou een willekeurige auto naar
    de impound kunnen sturen.

    Een `source ~= 0`-controle helpt daar niet bij: stevo_chopshop vuurt dit af
    vanuit een callback-handler, en daar is `source` de speler die aan het
    slopen is. Die controle zou juist de echte aanroep tegenhouden.
]]
AddEventHandler('los_insurance:server:vehicleChopped', function(plate)
    vehicleChopped(plate)
end)

exports('vehicleChopped', function(plate)
    vehicleChopped(plate)
end)

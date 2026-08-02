--[[
    Wat er gebeurt als je auto gesloopt wordt bij de chopshop.

    DE KETEN
      stevo_chopshop sloopt het voertuig af
        -> vuurt `los_insurance:server:vehicleChopped` met het kenteken
        -> hier: eigenaar opzoeken, voertuig terug in de garage, uitkeren,
           en de eigenaar een SMS sturen

    WAAROM HET VOERTUIG TERUGKOMT
    Een gestolen auto die definitief weg is, is geen roleplay maar verlies. De
    dief houdt zijn onderdelen, de eigenaar krijgt zijn auto terug in de garage
    plus een uitkering als hij verzekerd was. Onverzekerd: auto terug, geen geld,
    en een SMS die uitlegt waarom.

    OFFLINE EIGENAREN
    Wie op dat moment niet online is kan geen geld ontvangen. De claim wordt dan
    als openstaand weggeschreven en bij de eerstvolgende login alsnog uitbetaald.
    Zonder dat verdampt de uitkering van iedereen die net uitgelogd was.
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

-- =========================================================================
--  Telefoon
-- =========================================================================

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

-- =========================================================================
--  Uitbetalen
-- =========================================================================

---@param src number
---@param amount number
---@param plate string
local function payOut(src, amount, plate)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    player.Functions.AddMoney('bank', amount, ('Insurance payout %s'):format(plate))

    exports.qbx_core:Notify(src,
        locale('theft_paid', amount, plate), 'success', 12000)

    sms(src, locale('theft_sms_insured', plate, amount))
    return true
end

--- Openstaande uitkeringen van deze burger uitbetalen. Draait bij het inladen.
---@param src number
---@param citizenid string
local function payPending(src, citizenid)
    local rows = MySQL.query.await([[
        SELECT id, plate, amount FROM los_insurance_claims
        WHERE citizenid = ? AND type = 'vehicle' AND reason = ?
    ]], { citizenid, config.theft.pendingReason }) or {}

    for i = 1, #rows do
        local row = rows[i]

        if payOut(src, row.amount, row.plate or '?') then
            MySQL.query.await('UPDATE los_insurance_claims SET reason = ? WHERE id = ?',
                { 'Vehicle theft payout', row.id })
        end
    end

    if rows[1] then
        dbg(('%d openstaande diefstaluitkeringen betaald aan %s'):format(#rows, citizenid))
    end
end

-- =========================================================================
--  De hoofdafhandeling
-- =========================================================================

---@param plate string
local function vehicleChopped(plate)
    plate = normalizePlate(plate)
    if not plate then return end

    -- pcall: een ontbrekende tabel of kolom geeft bij oxmysql een exception en
    -- geen nil, en dan zou de hele chopshop stukgaan op een verzekeringsdetail.
    local ok, row = pcall(MySQL.single.await, [[
        SELECT citizenid, vehicle, `garage` FROM player_vehicles
        WHERE TRIM(UPPER(plate)) = ? LIMIT 1
    ]], { plate })

    if not ok then
        return lib.print.error(('los_insurance: kon %s niet opzoeken: %s'):format(plate, row))
    end

    -- Geen eigenaar: een NPC-auto van straat. Niets te vergoeden, niets terug
    -- te zetten. Dat is het normale geval bij een chopshop.
    if not row or not row.citizenid then
        dbg(('%s gesloopt, geen eigenaar - niets te doen'):format(plate))
        return
    end

    local citizenid = row.citizenid

    -- ── Voertuig terug in de garage ──────────────────────────────────────
    -- `state` = 1 is "staat in de garage" (renzu_garage conf/main.lua: stored).
    -- impound en isparked op 0, anders staat hij in beslag genomen of op straat
    -- geparkeerd te wachten op een auto die niet meer bestaat.
    if config.theft.returnToGarage then
        local garage = row.garage
        if not garage or garage == '' then garage = config.theft.fallbackGarage end

        pcall(MySQL.query.await, [[
            UPDATE player_vehicles
            SET `state` = 1, `garage` = ?, impound = 0, isparked = 0
            WHERE TRIM(UPPER(plate)) = ?
        ]], { garage, plate })

        dbg(('%s teruggezet in garage %s'):format(plate, garage))
    end

    -- ── Verzekering ──────────────────────────────────────────────────────
    local policy = MySQL.single.await([[
        SELECT id FROM los_insurance_policies
        WHERE type = 'vehicle' AND plate = ? AND expires > ?
        LIMIT 1
    ]], { plate, os.time() })

    local payout = policy
        and math.floor(config.theft.vehicleValue * config.policies.vehicle.coverage)
        or 0

    -- ── De eigenaar inlichten ────────────────────────────────────────────
    local owner = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    local src = owner and owner.PlayerData.source

    if payout <= 0 then
        MySQL.insert('INSERT INTO los_insurance_claims (citizenid, type, plate, amount, reason) VALUES (?, ?, ?, ?, ?)',
            { citizenid, 'vehicle', plate, 0, 'Vehicle theft - uninsured' })

        if src then
            exports.qbx_core:Notify(src, locale('theft_uninsured', plate), 'error', 15000)
            sms(src, locale('theft_sms_uninsured', plate))
        end

        dbg(('%s gesloopt, %s was niet verzekerd'):format(plate, citizenid))
        return
    end

    if src then
        MySQL.insert('INSERT INTO los_insurance_claims (citizenid, type, plate, amount, reason) VALUES (?, ?, ?, ?, ?)',
            { citizenid, 'vehicle', plate, payout, 'Vehicle theft payout' })

        payOut(src, payout, plate)
    else
        -- Offline: als openstaand wegschrijven, betalen bij de volgende login.
        MySQL.insert('INSERT INTO los_insurance_claims (citizenid, type, plate, amount, reason) VALUES (?, ?, ?, ?, ?)',
            { citizenid, 'vehicle', plate, payout, config.theft.pendingReason })

        dbg(('%s gesloopt, %s offline - uitkering %d in de wacht'):format(plate, citizenid, payout))
    end
end

--[[
    Bewust AddEventHandler en GEEN RegisterNetEvent.

    Zonder RegisterNetEvent kan een client dit event niet bereiken - en dat is
    hier het hele punt: wie het wel kon afvuren zou zichzelf een uitkering
    kunnen bezorgen door een willekeurig kenteken te sturen.

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

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    local citizenid = player and player.PlayerData and player.PlayerData.citizenid
    if not src or not citizenid then return end

    SetTimeout(5000, function()
        if not exports.qbx_core:GetPlayer(src) then return end
        payPending(src, citizenid)
    end)
end)

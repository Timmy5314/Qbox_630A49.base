--[[
    Server is autoriteit voor alles: polissen, premies en claims. De client
    vraagt alleen en toont.
]]

lib.locale()

local config = require 'shared.config'

---@param msg string
local function dbg(msg)
    if config.debug then lib.print.info(msg) end
end

-- =========================================================================
--  Opzoeken
-- =========================================================================

---@param src number
---@return string?
local function citizenIdOf(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

---Normaliseert een kenteken. ox.cfg draait met inventory:trimplate en de
---natives geven soms trailing spaces terug, dus zonder dit matcht 'ABC123 '
---niet op 'ABC123'.
---@param plate string?
---@return string?
local function normalizePlate(plate)
    if type(plate) ~= 'string' then return end
    local trimmed = plate:gsub('^%s+', ''):gsub('%s+$', '')
    return trimmed ~= '' and trimmed:upper() or nil
end

---@param citizenid string
---@param policyType string
---@param plate string?
---@return table? policy
local function findPolicy(citizenid, policyType, plate)
    if not citizenid then return end

    local row = MySQL.single.await([[
        SELECT * FROM los_insurance_policies
        WHERE citizenid = ? AND type = ? AND (plate <=> ?) AND expires > ?
        LIMIT 1
    ]], { citizenid, policyType, plate, os.time() })

    return row
end

---@param plate string
---@return table? policy
local function findVehiclePolicy(plate)
    plate = normalizePlate(plate)
    if not plate then return end

    return MySQL.single.await([[
        SELECT * FROM los_insurance_policies
        WHERE type = 'vehicle' AND plate = ? AND expires > ?
        LIMIT 1
    ]], { plate, os.time() })
end

-- =========================================================================
--  Exports voor andere resources
-- =========================================================================

---@param src number
---@return boolean
local function hasMedicalInsurance(src)
    local citizenid = citizenIdOf(src)
    if not citizenid then return false end

    return findPolicy(citizenid, 'medical', nil) ~= nil
end

exports('hasMedicalInsurance', hasMedicalInsurance)

---@param plate string
---@return boolean
exports('hasVehicleInsurance', function(plate)
    return findVehiclePolicy(plate) ~= nil
end)

---Boekt een medische claim. Geeft false als er geen geldige polis is, zodat de
---aanroeper weet dat hij de speler zelf moet belasten.
---@param src number
---@param amount number
---@return boolean
exports('claimMedical', function(src, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    local citizenid = citizenIdOf(src)
    if not citizenid or not findPolicy(citizenid, 'medical', nil) then return false end

    MySQL.insert('INSERT INTO los_insurance_claims (citizenid, type, amount, reason) VALUES (?, ?, ?, ?)',
        { citizenid, 'medical', math.floor(amount), 'Medical treatment' })

    dbg(('medische claim %s: %d'):format(citizenid, amount))
    return true
end)

---@param src number
---@param plate string
---@param amount number
---@return boolean
exports('claimVehicle', function(src, plate, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    local policy = findVehiclePolicy(plate)
    if not policy then return false end

    local covered = math.floor(amount * config.policies.vehicle.coverage)

    MySQL.insert('INSERT INTO los_insurance_claims (citizenid, type, plate, amount, reason) VALUES (?, ?, ?, ?, ?)',
        { policy.citizenid, 'vehicle', policy.plate, covered, 'Vehicle damage' })

    dbg(('autoclaim %s (%s): %d van %d'):format(policy.citizenid, policy.plate, covered, amount))
    return true, covered
end)

---Alle polissen van een burger. Gebruikt door ps-mdt en het eigen menu.
---@param citizenid string
---@return table[]
local function getPolicies(citizenid)
    if not citizenid then return {} end

    return MySQL.query.await([[
        SELECT type, plate, premium, expires
        FROM los_insurance_policies
        WHERE citizenid = ?
        ORDER BY type, plate
    ]], { citizenid }) or {}
end

exports('getPolicies', getPolicies)

-- =========================================================================
--  Kopen en verlengen
-- =========================================================================

lib.callback.register('los_insurance:getOwnPolicies', function(src)
    return getPolicies(citizenIdOf(src))
end)

---Voertuigen van de speler, zodat hij weet wat hij kan verzekeren.
lib.callback.register('los_insurance:getOwnVehicles', function(src)
    local citizenid = citizenIdOf(src)
    if not citizenid then return {} end

    local rows = MySQL.query.await(
        'SELECT plate, vehicle FROM player_vehicles WHERE citizenid = ?', { citizenid }) or {}

    local now = os.time()

    for i = 1, #rows do
        local plate = normalizePlate(rows[i].plate)
        rows[i].plate = plate

        local policy = plate and MySQL.single.await([[
            SELECT expires FROM los_insurance_policies
            WHERE type = 'vehicle' AND plate = ? AND expires > ?
        ]], { plate, now })

        rows[i].insuredUntil = policy and policy.expires or nil
    end

    return rows
end)

lib.callback.register('los_insurance:buy', function(src, policyType, plate)
    local settings = config.policies[policyType]
    if not settings then return false, locale('unknown_policy') end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    local citizenid = player.PlayerData.citizenid

    if policyType == 'vehicle' then
        plate = normalizePlate(plate)
        if not plate then return false, locale('no_plate') end

        -- Alleen je eigen voertuig verzekeren.
        local owns = MySQL.single.await(
            'SELECT 1 FROM player_vehicles WHERE citizenid = ? AND TRIM(UPPER(plate)) = ? LIMIT 1',
            { citizenid, plate })

        if not owns then return false, locale('not_your_vehicle') end
    else
        plate = nil
    end

    if (player.PlayerData.money[config.account] or 0) < settings.premium then
        return false, locale('cannot_afford', settings.premium)
    end

    if not player.Functions.RemoveMoney(config.account, settings.premium, 'Insurance premium') then
        return false, locale('payment_failed')
    end

    local expires = os.time() + (settings.days * 86400)

    -- Bestaat er al een polis, dan verlengen we vanaf nu. ON DUPLICATE KEY
    -- werkt op de unique key (citizenid, type, plate).
    MySQL.query.await([[
        INSERT INTO los_insurance_policies (citizenid, type, plate, premium, expires)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE expires = VALUES(expires), premium = VALUES(premium)
    ]], { citizenid, policyType, plate, settings.premium, expires })

    dbg(('%s kocht %s%s tot %s'):format(citizenid, policyType, plate and (' ' .. plate) or '', expires))

    return true, locale('purchased', settings.label, settings.days)
end)

-- =========================================================================
--  Politiecontrole
-- =========================================================================

---@param src number
---@return boolean
local function isPolice(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    local jobType = player.PlayerData.job and player.PlayerData.job.type
    if not jobType then return false end

    for i = 1, #config.police.jobTypes do
        if config.police.jobTypes[i] == jobType then return true end
    end

    return false
end

lib.callback.register('los_insurance:checkPerson', function(src, targetSrc)
    if not isPolice(src) then return end

    targetSrc = tonumber(targetSrc)
    if not targetSrc then return end

    -- Moet er wel bij staan.
    local ped, targetPed = GetPlayerPed(src), GetPlayerPed(targetSrc)
    if not ped or not targetPed or ped == 0 or targetPed == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 5.0 then return end

    local target = exports.qbx_core:GetPlayer(targetSrc)
    if not target then return end

    local charinfo = target.PlayerData.charinfo

    return {
        name = ('%s %s'):format(charinfo.firstname, charinfo.lastname),
        policies = getPolicies(target.PlayerData.citizenid),
    }
end)

lib.callback.register('los_insurance:checkPlate', function(src, plate)
    if not isPolice(src) then return end

    plate = normalizePlate(plate)
    if not plate then return end

    local policy = findVehiclePolicy(plate)

    local owner
    local row = MySQL.single.await([[
        SELECT p.charinfo FROM player_vehicles v
        JOIN players p ON p.citizenid = v.citizenid
        WHERE TRIM(UPPER(v.plate)) = ? LIMIT 1
    ]], { plate })

    if row and row.charinfo then
        local charinfo = json.decode(row.charinfo)
        if charinfo then
            owner = ('%s %s'):format(charinfo.firstname, charinfo.lastname)
        end
    end

    return {
        plate = plate,
        owner = owner,
        insured = policy ~= nil,
        expires = policy and policy.expires or nil,
    }
end)

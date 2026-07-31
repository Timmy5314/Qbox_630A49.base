--[[
    Inhoudingen op de loonstrook.

    qbx_core betaalt uit via config.sendPaycheck en vuurt daarna
    'qbx_core:server:onPaycheck' met (source, payment). Daar haken we op in.

    VOLGORDE
    De loonmelding komt eerst, van qbx_core zelf. Een paar seconden later boeken
    wij de inhoudingen af met een eigen melding. Zo ziet de speler eerst wat hij
    verdient en daarna wat eraf gaat, in plaats van twee meldingen door elkaar.

    GRENS
    Er wordt nooit meer ingehouden dan `maxShareOfPaycheck` van het loon. Wie
    weinig verdient betaalt naar rato en houdt altijd iets over. Het alternatief
    is dat een speler met een klein loon netto niets overhoudt en stopt met
    werken, en dan int de verzekeraar helemaal niets meer.
]]

lib.locale()

local config = require 'shared.config'
if not config.deductions.enabled then return end

---@param citizenid string
---@return table[]
local function activePolicies(citizenid)
    return MySQL.query.await([[
        SELECT id, type, plate FROM los_insurance_policies
        WHERE citizenid = ? AND expires > ?
    ]], { citizenid, os.time() }) or {}
end

---@param citizenid string
---@return number
local function vehicleCount(citizenid)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ?', { citizenid }) or 0
end

---Bouwt de lijst inhoudingen op. Geeft de posten terug plus het totaal, nog
---zonder rekening te houden met het plafond.
---@param citizenid string
---@param payment number
---@return {label: string, amount: number}[] lines, number total, table[] policies
local function calculate(citizenid, payment)
    local lines, total = {}, 0
    local policies = activePolicies(citizenid)

    for i = 1, #policies do
        local settings = config.policies[policies[i].type]

        if settings and settings.premium > 0 then
            local label = settings.label
            if policies[i].plate then
                label = ('%s (%s)'):format(label, policies[i].plate)
            end

            lines[#lines + 1] = { label = label, amount = settings.premium }
            total = total + settings.premium
        end
    end

    local tax = config.deductions.tax

    if tax.enabled then
        local income = math.floor(payment * tax.incomeRate)
        if income > 0 then
            lines[#lines + 1] = { label = locale('tax_income'), amount = income }
            total = total + income
        end

        local vehicles = math.min(vehicleCount(citizenid), tax.maxVehiclesTaxed)
        local roadTax = vehicles * tax.perVehicle

        if roadTax > 0 then
            lines[#lines + 1] = { label = locale('tax_vehicle', vehicles), amount = roadTax }
            total = total + roadTax
        end
    end

    return lines, total, policies
end

---Schuift de einddatum van elke betaalde polis op.
---@param policies table[]
local function extendPolicies(policies)
    if #policies == 0 then return end

    local expires = os.time() + config.policyExtendHours * 3600

    -- Per polis bijwerken; het zijn er hooguit een handvol per speler.
    for i = 1, #policies do
        MySQL.update('UPDATE los_insurance_policies SET expires = ? WHERE id = ?',
            { expires, policies[i].id })
    end
end

AddEventHandler('qbx_core:server:onPaycheck', function(src, payment)
    payment = tonumber(payment)
    if not payment or payment <= 0 then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    local lines, total, policies = calculate(citizenid, payment)
    if total <= 0 then return end

    -- Nooit meer dan het afgesproken deel van het loon.
    local cap = math.floor(payment * config.deductions.maxShareOfPaycheck)
    local capped = total > cap

    if capped then total = cap end
    if total <= 0 then return end

    SetTimeout(config.deductions.delaySeconds * 1000, function()
        -- Speler kan intussen weg zijn.
        if not exports.qbx_core:GetPlayer(src) then return end

        if not player.Functions.RemoveMoney('bank', total, 'Insurance and tax') then
            -- Niet kunnen betalen betekent geen verlenging: de polis loopt af.
            return exports.qbx_core:Notify(src, locale('deduction_failed'), 'error', 12000)
        end

        extendPolicies(policies)

        local parts = {}
        for i = 1, #lines do
            parts[#parts + 1] = ('%s $%d'):format(lines[i].label, lines[i].amount)
        end

        local description = table.concat(parts, '\n')
        if capped then
            description = description .. '\n' .. locale('deduction_capped')
        end

        exports.qbx_core:Notify(src, {
            title = locale('deduction_title', total),
            description = description,
        }, 'inform', 12000)
    end)
end)

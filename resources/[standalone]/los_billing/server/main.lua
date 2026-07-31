local config = require 'shared.config'

local lastSent = {}

---@param msg string
local function dbg(msg)
    if config.debug then lib.print.info(msg) end
end

---Stuurt een SMS namens de deurwaarder.
---
---`getPlayerData` wil een LOCATOR-object en geeft een platte tabel met
---`phoneNumber` terug - geen getal, en geen object met getPhoneNumber(). Zie
---npwd/dist/game/server/server.js. Twee resources zijn hier al in getrapt.
---@param src number
---@param message string
local function sms(src, message)
    if not GetResourceState('npwd'):find('start') then return end

    local ok, data = pcall(function()
        return exports.npwd:getPlayerData({ source = src })
    end)

    if not ok or type(data) ~= 'table' then return end

    if data.phoneNumber == nil and type(data.next) == 'function' then
        local awaited
        local awaitOk = pcall(function() awaited = Citizen.Await(data) end)
        data = awaitOk and awaited or nil
    end

    local number = type(data) == 'table' and data.phoneNumber
    if not number then return end

    pcall(function()
        exports.npwd:emitMessage({
            senderNumber = config.overdue.senderNumber,
            targetNumber = number,
            message = message,
        })
    end)
end

---Laat de verzekering betalen wat ze dekt.
---@param src number
---@param job string
---@param amount number
---@param plate string? alleen nodig voor een autoverzekering
---@return number covered
local function claimInsurance(src, job, amount, plate)
    local kind = config.insured[job]
    if not kind or not GetResourceState('los_insurance'):find('start') then return 0 end

    -- claimVehicle zoekt de polis OP KENTEKEN; zonder kenteken vindt hij niets
    -- en geeft hij altijd false terug. Geen kenteken = geen dekking, en dat
    -- moet je hier afvangen in plaats van een claim te doen die nooit lukt.
    if kind == 'vehicle' and (type(plate) ~= 'string' or plate == '') then return 0 end

    local ok, claimed = pcall(function()
        if kind == 'medical' then
            return exports.los_insurance:claimMedical(src, amount)
        end

        return exports.los_insurance:claimVehicle(src, plate, amount)
    end)

    if not ok or not claimed then return 0 end

    dbg(('verzekering dekte %d voor %s'):format(amount, src))
    return amount
end

-- =========================================================================
--  Versturen
-- =========================================================================

lib.callback.register('los_billing:send', function(src, targetSrc, amount, reason, plate)
    local sender = exports.qbx_core:GetPlayer(src)
    if not sender then return false, locale('error_generic') end

    local job = sender.PlayerData.job
    local settings = job and config.senders[job.name]

    if not settings then return false, locale('not_allowed') end
    if not job.onduty then return false, locale('not_on_duty') end
    if (job.grade and job.grade.level or 0) < settings.minGrade then
        return false, locale('grade_too_low')
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, locale('invalid_amount') end
    if amount > settings.maxAmount then return false, locale('over_max', settings.maxAmount) end

    if type(reason) ~= 'string' or reason == '' then return false, locale('reason_required') end
    if #reason > 190 then reason = reason:sub(1, 190) end

    -- Cooldown per afzender, niet per ontvanger: anders factureer je iedereen
    -- om de beurt vol en merkt niemand het.
    local now = os.time()
    local last = lastSent[src]
    if last and now - last < settings.cooldown then return false, locale('cooldown') end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or targetSrc == src then return false, locale('target_not_found') end

    local target = exports.qbx_core:GetPlayer(targetSrc)
    if not target then return false, locale('target_not_found') end

    local ped, targetPed = GetPlayerPed(src), GetPlayerPed(targetSrc)
    if ped == 0 or targetPed == 0 then return false, locale('target_not_found') end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 10.0 then return false, locale('too_far') end

    lastSent[src] = now

    local covered = claimInsurance(targetSrc, job.name, amount, plate)
    local owed = amount - covered

    local charinfo = sender.PlayerData.charinfo
    local senderName = ('%s %s'):format(charinfo.firstname, charinfo.lastname)

    MySQL.insert.await([[
        INSERT INTO los_billing_invoices
            (citizenid, sender_job, sender_name, sender_cid, amount, covered, reason, unrefusable)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        target.PlayerData.citizenid, job.name, senderName, sender.PlayerData.citizenid,
        owed, covered, reason, settings.unrefusable and 1 or 0,
    })

    -- De societykas krijgt het volle bedrag. Of de speler betaalt is zijn
    -- probleem, niet dat van het bedrijf.
    if settings.society and GetResourceState('Renewed-Banking'):find('start') then
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney(job.name, amount)
        end)
    end

    exports.qbx_core:Notify(targetSrc, locale('invoice_received', settings.label, owed), 'inform', 12000)

    if covered > 0 then
        exports.qbx_core:Notify(targetSrc, locale('insurance_covered', covered), 'success', 10000)
    end

    dbg(('%s factureerde %s voor %d (%d gedekt)'):format(senderName, target.PlayerData.citizenid, owed, covered))
    return true, locale('invoice_sent', owed)
end)

-- =========================================================================
--  Betalen, weigeren
-- =========================================================================

lib.callback.register('los_billing:list', function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return {} end

    return MySQL.query.await([[
        SELECT id, sender_job, sender_name, amount, interest, covered, reason, unrefusable
        FROM los_billing_invoices
        WHERE citizenid = ? AND status = 'open'
        ORDER BY created_at
    ]], { player.PlayerData.citizenid }) or {}
end)

lib.callback.register('los_billing:pay', function(src, invoiceId)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false end

    local row = MySQL.single.await([[
        SELECT id, amount, interest FROM los_billing_invoices
        WHERE id = ? AND citizenid = ? AND status = 'open'
    ]], { invoiceId, player.PlayerData.citizenid })

    if not row then return false, locale('invoice_not_found') end

    local total = row.amount + row.interest

    if not player.Functions.RemoveMoney(config.account, total, 'Invoice ' .. row.id) then
        return false, locale('not_enough_money')
    end

    MySQL.update.await("UPDATE los_billing_invoices SET status = 'paid' WHERE id = ?", { row.id })
    return true, locale('invoice_paid', total)
end)

lib.callback.register('los_billing:refuse', function(src, invoiceId)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    invoiceId = tonumber(invoiceId)
    if not invoiceId then return false end

    local row = MySQL.single.await([[
        SELECT id, unrefusable FROM los_billing_invoices
        WHERE id = ? AND citizenid = ? AND status = 'open'
    ]], { invoiceId, player.PlayerData.citizenid })

    if not row then return false, locale('invoice_not_found') end

    -- Boetes en medische rekeningen weiger je niet. Deze controle staat hier en
    -- niet in de client, want de client is geen autoriteit.
    if row.unrefusable == 1 then return false, locale('cannot_refuse') end

    MySQL.update.await("UPDATE los_billing_invoices SET status = 'refused' WHERE id = ?", { row.id })
    return true, locale('invoice_refused')
end)

-- =========================================================================
--  Rente en deurwaarder
-- =========================================================================

CreateThread(function()
    Wait(30000)

    while true do
        local rows = MySQL.query.await([[
            SELECT id, amount, interest FROM los_billing_invoices
            WHERE status = 'open' AND created_at < (NOW() - INTERVAL ? HOUR)
        ]], { config.overdue.afterHours }) or {}

        for i = 1, #rows do
            local row = rows[i]
            local cap = math.floor(row.amount * config.overdue.maxInterestShare)
            local added = math.floor(row.amount * config.overdue.interest)
            local newInterest = math.min(row.interest + added, cap)

            if newInterest > row.interest then
                MySQL.update.await('UPDATE los_billing_invoices SET interest = ? WHERE id = ?',
                    { newInterest, row.id })
            end
        end

        -- Alleen wie online is krijgt een SMS. Offline heeft geen zin.
        local players = GetPlayers()

        for i = 1, #players do
            local src = tonumber(players[i])
            local player = src and exports.qbx_core:GetPlayer(src)

            if player then
                local total = MySQL.scalar.await([[
                    SELECT SUM(amount + interest) FROM los_billing_invoices
                    WHERE citizenid = ? AND status = 'open'
                      AND created_at < (NOW() - INTERVAL ? HOUR)
                ]], { player.PlayerData.citizenid, config.overdue.afterHours })

                if total and tonumber(total) and tonumber(total) > 0 then
                    sms(src, locale('debt_collector', math.floor(tonumber(total))))
                end
            end
        end

        Wait(config.overdue.checkMinutes * 60000)
    end
end)

AddEventHandler('playerDropped', function()
    lastSent[source] = nil
end)

-- =========================================================================
--  Audit
-- =========================================================================

lib.addCommand('billaudit', {
    help = 'Laatste 20 verstuurde rekeningen (admin)',
    restricted = 'group.admin',
}, function(source)
    local rows = MySQL.query.await([[
        SELECT sender_name, sender_job, amount, reason, status, created_at
        FROM los_billing_invoices ORDER BY id DESC LIMIT 20
    ]]) or {}

    for i = 1, #rows do
        local r = rows[i]
        print(('[los_billing] %s | %s (%s) | $%d | %s | %s')
            :format(r.created_at, r.sender_name, r.sender_job, r.amount, r.status, r.reason))
    end

    exports.qbx_core:Notify(source, ('%d rekeningen naar de console geschreven'):format(#rows), 'inform')
end)

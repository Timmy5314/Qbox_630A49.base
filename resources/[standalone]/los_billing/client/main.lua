--[[
    Client: het overzicht en het factureerscherm. Geen loops - alles hangt aan
    een toets en een commando.
]]

local config = require 'shared.config'

-- =========================================================================
--  Mijn rekeningen
-- =========================================================================

local function openInvoices()
    local invoices = lib.callback.await('los_billing:list', false) or {}

    if #invoices == 0 then
        return lib.notify({ description = locale('no_invoices'), type = 'inform' })
    end

    local options = {}

    for i = 1, #invoices do
        local invoice = invoices[i]
        local total = invoice.amount + invoice.interest

        local description = locale('invoice_line', invoice.sender_name, invoice.reason)

        if invoice.interest > 0 then
            description = ('%s\n%s'):format(description, locale('with_interest', invoice.interest))
        end

        if invoice.covered > 0 then
            description = ('%s\n%s'):format(description, locale('was_covered', invoice.covered))
        end

        options[#options + 1] = {
            title = ('%s - $%d'):format(invoice.sender_job, total),
            description = description,
            icon = invoice.unrefusable == 1 and 'file-invoice-dollar' or 'file-invoice',
            onSelect = function()
                local choices = { locale('pay') }
                if invoice.unrefusable ~= 1 then choices[#choices + 1] = locale('refuse') end

                local picked = lib.inputDialog(('$%d'):format(total), {
                    {
                        type = 'select',
                        label = locale('what_to_do'),
                        options = (function()
                            local out = {}
                            for c = 1, #choices do out[c] = { value = tostring(c), label = choices[c] } end
                            return out
                        end)(),
                        required = true,
                    },
                })

                if not picked then return end

                local ok, message
                if picked[1] == '1' then
                    ok, message = lib.callback.await('los_billing:pay', false, invoice.id)
                else
                    ok, message = lib.callback.await('los_billing:refuse', false, invoice.id)
                end

                lib.notify({
                    description = message or locale('error_generic'),
                    type = ok and 'success' or 'error',
                    duration = 8000,
                })
            end,
        }
    end

    lib.registerContext({ id = 'los_billing_list', title = locale('my_invoices'), options = options })
    lib.showContext('los_billing_list')
end

lib.addKeybind({
    name = 'invoices',
    description = locale('open_invoices'),
    defaultKey = config.menuKey,
    onPressed = openInvoices,
})

RegisterCommand('invoices', openInvoices, false)

-- =========================================================================
--  Factureren
-- =========================================================================

local function sendInvoice(targetServerId)
    local job = QBX.PlayerData.job
    local wantsPlate = job and config.insured[job.name] == 'vehicle'

    local fields = {
        { type = 'number', label = locale('amount'), icon = 'dollar-sign', required = true, min = 1 },
        { type = 'input', label = locale('reason'), icon = 'file-lines', required = true, max = 190 },
    }

    -- Alleen bij een autoverzekering: die polis wordt op kenteken gezocht, dus
    -- zonder kenteken kan de verzekeraar niets dekken.
    if wantsPlate then
        fields[#fields + 1] = {
            type = 'input',
            label = locale('plate'),
            description = locale('plate_help'),
            icon = 'car',
            max = 16,
        }
    end

    local input = lib.inputDialog(locale('send_invoice'), fields)

    if not input then return end

    local ok, message = lib.callback.await('los_billing:send', false,
        targetServerId, input[1], input[2], wantsPlate and input[3] or nil)

    lib.notify({
        description = message or locale('error_generic'),
        type = ok and 'success' or 'error',
        duration = 8000,
    })
end

--- Op de speler zelf: zo hoef je geen server-id over te typen.
exports.ox_target:addGlobalPlayer({
    {
        name = 'los_billing:send',
        icon = 'fa-solid fa-file-invoice-dollar',
        label = locale('send_invoice'),
        distance = 2.5,
        canInteract = function()
            local job = QBX.PlayerData.job
            return job and config.senders[job.name] ~= nil and job.onduty
        end,
        onSelect = function(data)
            local target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            if not target or target <= 0 then return end

            sendInvoice(target)
        end,
    },
})

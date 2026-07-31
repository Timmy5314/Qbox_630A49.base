--[[
    Client: het kantoor en de politiecontrole. Geen loops - alles hangt aan
    ox_target en het radial menu.
]]

lib.locale()

local config = require 'shared.config'

---@param expires number?
---@return string
local function expiryText(expires)
    if not expires then return locale('not_insured') end

    local remaining = expires - os.time()
    if remaining <= 0 then return locale('expired') end

    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)

    if days > 0 then return locale('valid_days', days, hours) end
    return locale('valid_hours', hours)
end

-- =========================================================================
--  Kantoor
-- =========================================================================

local function showOwnPolicies()
    local policies = lib.callback.await('los_insurance:getOwnPolicies', false) or {}
    local options = {}

    for i = 1, #policies do
        local policy = policies[i]
        local settings = config.policies[policy.type]

        options[#options + 1] = {
            title = settings and settings.label or policy.type,
            description = ('%s%s'):format(
                policy.plate and (policy.plate .. ' - ') or '',
                expiryText(policy.expires)),
            icon = policy.type == 'medical' and 'briefcase-medical' or 'car',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('cancel_policy'),
                    content = settings and settings.label or policy.type,
                    centered = true,
                    cancel = true,
                })

                if confirm ~= 'confirm' then return end

                local ok, message = lib.callback.await('los_insurance:cancel', false, policy.type, policy.plate)
                lib.notify({ description = message or locale('failed'), type = ok and 'success' or 'error' })
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = locale('no_policies'), readOnly = true }
    end

    lib.registerContext({
        id = 'los_insurance_own',
        title = locale('my_policies'),
        menu = 'los_insurance_main',
        options = options,
    })

    lib.showContext('los_insurance_own')
end

local function buyVehiclePolicy()
    local vehicles = lib.callback.await('los_insurance:getOwnVehicles', false) or {}
    local options = {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        options[#options + 1] = {
            title = ('%s - %s'):format(vehicle.plate, vehicle.vehicle or '?'),
            description = expiryText(vehicle.insuredUntil),
            icon = 'car',
            onSelect = function()
                local ok, message = lib.callback.await('los_insurance:buy', false, 'vehicle', vehicle.plate)
                lib.notify({ description = message or locale('failed'), type = ok and 'success' or 'error' })
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = locale('no_vehicles'), readOnly = true }
    end

    lib.registerContext({
        id = 'los_insurance_vehicles',
        title = locale('insure_vehicle'),
        menu = 'los_insurance_main',
        options = options,
    })

    lib.showContext('los_insurance_vehicles')
end

local function openOffice()
    local medical = config.policies.medical
    local vehicle = config.policies.vehicle

    lib.registerContext({
        id = 'los_insurance_main',
        title = locale('office_title'),
        options = {
            {
                title = medical.label,
                description = ('%s  -  %s'):format(medical.description, locale('premium_per_paycheck', medical.premium)),
                icon = 'briefcase-medical',
                onSelect = function()
                    local ok, message = lib.callback.await('los_insurance:buy', false, 'medical')
                    lib.notify({ description = message or locale('failed'), type = ok and 'success' or 'error' })
                end,
            },
            {
                title = vehicle.label,
                description = ('%s  -  %s'):format(vehicle.description, locale('premium_per_paycheck', vehicle.premium)),
                icon = 'car',
                onSelect = buyVehiclePolicy,
            },
            {
                title = locale('my_policies'),
                icon = 'folder-open',
                onSelect = showOwnPolicies,
            },
        },
    })

    lib.showContext('los_insurance_main')
end

CreateThread(function()
    lib.requestModel(config.office.ped)

    local ped = CreatePed(4, config.office.ped,
        config.office.coords.x, config.office.coords.y, config.office.coords.z - 1.0,
        config.office.coords.w, false, true)

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedConfigFlag(ped, 17, true)
    SetModelAsNoLongerNeeded(config.office.ped)
    TaskStartScenarioInPlace(ped, config.office.scenario, 0, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = locale('talk_to_agent'),
            icon = 'fa-solid fa-file-shield',
            distance = 2.0,
            onSelect = openOffice,
        },
    })

    if config.office.blip.enabled then
        local blip = AddBlipForCoord(config.office.coords.x, config.office.coords.y, config.office.coords.z)
        SetBlipSprite(blip, config.office.blip.sprite)
        SetBlipColour(blip, config.office.blip.colour)
        SetBlipScale(blip, config.office.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(config.office.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- =========================================================================
--  Politiecontrole
-- =========================================================================

local function showResult(title, lines)
    local options = {}

    for i = 1, #lines do
        options[i] = { title = lines[i], readOnly = true }
    end

    lib.registerContext({ id = 'los_insurance_result', title = title, options = options })
    lib.showContext('los_insurance_result')
end

local function checkNearestPerson()
    local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 5.0, false)

    if #players == 0 then
        return lib.notify({ description = locale('nobody_nearby'), type = 'error' })
    end

    local target = GetPlayerServerId(players[1].id)
    local result = lib.callback.await('los_insurance:checkPerson', false, target)

    if not result then
        return lib.notify({ description = locale('check_failed'), type = 'error' })
    end

    local lines = {}
    local medical

    for i = 1, #result.policies do
        if result.policies[i].type == 'medical' then medical = result.policies[i] end
    end

    lines[#lines + 1] = ('%s: %s'):format(locale('medical'), expiryText(medical and medical.expires))

    for i = 1, #result.policies do
        local policy = result.policies[i]
        if policy.type == 'vehicle' then
            lines[#lines + 1] = ('%s: %s'):format(policy.plate, expiryText(policy.expires))
        end
    end

    showResult(result.name, lines)
end

local function checkVehicleInFront()
    local coords = GetEntityCoords(cache.ped)
    local vehicle = cache.vehicle

    if not vehicle then
        local forward = coords + (GetEntityForwardVector(cache.ped) * 3.0)
        local handle = GetClosestVehicle(forward.x, forward.y, forward.z, 5.0, 0, 71)
        vehicle = handle ~= 0 and handle or nil
    end

    if not vehicle then
        return lib.notify({ description = locale('no_vehicle_nearby'), type = 'error' })
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local result = lib.callback.await('los_insurance:checkPlate', false, plate)

    if not result then
        return lib.notify({ description = locale('check_failed'), type = 'error' })
    end

    showResult(result.plate, {
        ('%s: %s'):format(locale('owner'), result.owner or locale('unregistered')),
        ('%s: %s'):format(locale('vehicle'), expiryText(result.expires)),
    })
end

if config.police.radial.enabled then
    lib.addRadialItem({
        id = config.police.radial.id,
        label = config.police.radial.label,
        icon = config.police.radial.icon,
        menu = 'los_insurance_radial',
    })

    lib.registerRadial({
        id = 'los_insurance_radial',
        items = {
            {
                id = 'los_insurance_person',
                label = locale('check_person'),
                icon = 'user-shield',
                onSelect = checkNearestPerson,
            },
            {
                id = 'los_insurance_vehicle',
                label = locale('check_vehicle'),
                icon = 'car-on',
                onSelect = checkVehicleInFront,
            },
        },
    })
end

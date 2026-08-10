--[[
    Client doet alleen presentatie: targets, teleport en de invoerdialoog.
    Elke beslissing (mag je naar binnen, klopt het bedrag, sta je bij de
    machine) valt server-side. Wat hier gecontroleerd wordt is puur om de
    speler niet voor niets te laten klikken.

    Geoptimaliseerd: geen enkele permanente loop. Alles hangt aan ox_target
    zones, die ox_target zelf al efficient afhandelt.
]]

lib.locale()

local config = lib.require 'config'

--- Welke ingang deze restart actief is.
local exterior = config.exteriors[math.random(#config.exteriors)]

local inside = false
local zones = {}

-- =========================================================================
--  Teleport
-- =========================================================================

---@param coords vector4|vector3
---@param heading number?
local function fadeTo(coords, heading)
    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    if heading then SetEntityHeading(cache.ped, heading) end

    Wait(250)
    DoScreenFadeIn(250)
end

local function enterLaundry()
    local granted, reason = lib.callback.await('s4t4n667_moneywash:canEnter', false)

    if not granted then
        return lib.notify({ description = reason or locale('access_denied'), type = 'error' })
    end

    fadeTo(config.interior.spawn, config.interior.spawn.w)
    inside = true
end

local function exitLaundry()
    fadeTo(exterior, exterior.w)
    inside = false
end

-- =========================================================================
--  Acties
-- =========================================================================

local function washMoney()
    local dirty = exports.ox_inventory:Search('count', config.washing.dirtyMoney) or 0

    if dirty < config.washing.minAmount then
        return lib.notify({
            description = locale('minimum_is', config.washing.minAmount),
            type = 'error',
        })
    end

    local input = lib.inputDialog(locale('wash_title'), {
        {
            type = 'number',
            label = locale('wash_amount'),
            description = locale('wash_amount_help', config.washing.minAmount, math.min(dirty, config.washing.maxAmount)),
            min = config.washing.minAmount,
            max = math.min(dirty, config.washing.maxAmount),
            required = true,
        },
    })

    if not input or not input[1] then return end

    if lib.progressCircle({
        duration = config.washing.duration,
        label = locale('wash_progress'),
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, combat = true },
    }) == false then return end

    local ok, payout = lib.callback.await('s4t4n667_moneywash:wash', false, input[1])
    if ok then
        lib.notify({ description = locale('wash_done', payout), type = 'success' })
    end
end

local function dryMoney()
    local wet = exports.ox_inventory:Search('count', config.washing.wetMoney) or 0

    if wet < 1 then
        return lib.notify({ description = locale('no_wet_bills'), type = 'error' })
    end

    if lib.progressCircle({
        duration = config.drying.duration,
        label = locale('dry_progress'),
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, combat = true },
    }) == false then return end

    local ok, amount = lib.callback.await('s4t4n667_moneywash:dry', false, wet)
    if ok then
        lib.notify({ description = locale('dry_done', amount), type = 'success' })
    end
end

local function openShop()
    local options = {}

    for i = 1, #config.shop.items do
        local entry = config.shop.items[i]
        options[i] = {
            title = entry.label,
            description = locale('price_dirty', entry.price),
            icon = entry.icon,
            onSelect = function()
                lib.callback.await('s4t4n667_moneywash:buy', false, entry.item)
            end,
        }
    end

    lib.registerContext({ id = 'moneywash_shop', title = locale('shop_title'), options = options })
    lib.showContext('moneywash_shop')
end

-- =========================================================================
--  Wereld
-- =========================================================================

CreateThread(function()
    -- Ingang
    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = vec3(exterior.x, exterior.y, exterior.z),
        size = vec3(1.5, 1.5, 2.0),
        rotation = exterior.w,
        options = {
            {
                label = locale('target_enter'),
                icon = 'fa-solid fa-soap',
                distance = 2.5,
                onSelect = enterLaundry,
                canInteract = function()
                    return not inside
                end,
            },
        },
    })

    -- Uitgang
    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = config.interior.exit,
        size = vec3(2.0, 2.0, 2.0),
        options = {
            {
                label = locale('target_exit'),
                icon = 'fa-solid fa-door-open',
                distance = 2.0,
                onSelect = exitLaundry,
                canInteract = function() return inside end,
            },
        },
    })

    -- Wasmachine
    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = config.interior.wash,
        size = vec3(2.0, 2.0, 2.0),
        options = {
            {
                label = locale('target_wash'),
                icon = 'fa-solid fa-money-bill',
                distance = 2.0,
                onSelect = washMoney,
                canInteract = function() return inside end,
            },
        },
    })

    -- Droger en telmachine
    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = config.interior.count,
        size = vec3(1.5, 1.5, 2.0),
        options = {
            {
                label = locale('target_dry'),
                icon = 'fa-solid fa-wind',
                distance = 2.5,
                onSelect = dryMoney,
                canInteract = function() return inside end,
            },
        },
    })

    -- Verkoper buiten
    if config.shop.enabled then
        lib.requestModel(config.shop.pedModel)

        local ped = CreatePed(4, config.shop.pedModel,
            config.shop.coords.x, config.shop.coords.y, config.shop.coords.z - 1.0,
            config.shop.coords.w, false, true)

        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedConfigFlag(ped, 17, true)
        SetModelAsNoLongerNeeded(config.shop.pedModel)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_SMOKING', 0, true)

        zones[#zones + 1] = exports.ox_target:addLocalEntity(ped, {
            {
                label = locale('target_shop'),
                icon = 'fa-solid fa-cart-shopping',
                distance = 2.0,
                onSelect = openShop,
            },
        })
    end

    if config.blip.enabled then
        local blip = AddBlipForCoord(exterior.x, exterior.y, exterior.z)
        SetBlipSprite(blip, config.blip.sprite)
        SetBlipColour(blip, config.blip.colour)
        SetBlipScale(blip, config.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(config.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

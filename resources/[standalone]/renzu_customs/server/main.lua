--[[
    renzu_customs :: server
    Qbox (qbx_core) + oxmysql + ox_lib
]]

local RESOURCE = GetCurrentResourceName()

---@class Session
---@field shop string
---@field netId integer
---@field props table  props of the vehicle as it was when the menu opened
---@field free boolean admin opened the menu for free

---@type table<number, Session>
local sessions = {}

---@type table<number, number> model hash -> price
local vehiclePrices = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  Boot
-- ─────────────────────────────────────────────────────────────────────────────

local function loadVehiclePrices()
    local ok, vehicles = pcall(function()
        return exports.qbx_core:GetVehiclesByName()
    end)

    if ok and type(vehicles) == 'table' then
        for name, data in pairs(vehicles) do
            local price = tonumber(data.price)
            if price then
                vehiclePrices[joaat(name)] = price
            end
        end
    else
        lib.print.warn('could not read the qbx_core vehicle list, only Config.VehicleValueList will be used for pricing')
    end

    for _, entry in ipairs(Config.VehicleValueList) do
        vehiclePrices[joaat(entry.model)] = tonumber(entry.value) or 0
    end
end

local function ensureShopRows()
    for shop in pairs(Config.Customs) do
        MySQL.prepare.await('INSERT IGNORE INTO renzu_customs (shop, inventory) VALUES (?, ?)', { shop, '{}' })
    end
end

CreateThread(function()
    Wait(500)
    loadVehiclePrices()

    local ok, err = pcall(ensureShopRows)
    if not ok then
        lib.print.error(('the `renzu_customs` table is missing - import sql/renzu_customs.sql (%s)'):format(err))
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@param src number
---@return table? player qbx player object
local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

---@param player table
---@return string job, number grade
local function getJob(player)
    local job = player.PlayerData.job
    return job and job.name or 'unemployed', job and job.grade and job.grade.level or 0
end

---@param shop string
---@return table? config
local function getShop(shop)
    return type(shop) == 'string' and Config.Customs[shop] or nil
end

---Is this player actually standing at the shop they claim to be at?
---@param src number
---@param shop string
---@return boolean
local function isAtShop(src, shop)
    local shopCfg = getShop(shop)
    if not shopCfg then return false end

    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local center = vec3(shopCfg.shopcoord.x, shopCfg.shopcoord.y, shopCfg.shopcoord.z)
    -- a generous margin: the tuning bays sit at the edge of the shop radius
    return #(GetEntityCoords(ped) - center) <= (shopCfg.radius or 30.0) + 20.0
end

---Society account name for a shop (qbx_management).
---@param job string
local function societyAccount(job)
    return Config.SocietyPrefix ~= '' and (Config.SocietyPrefix .. job) or job
end

---@param job string
---@return number
local function getSocietyMoney(job)
    if not Config.UseSociety then return 0 end
    local ok, money = pcall(function()
        return exports[Config.SocietyResource]:GetAccountMoney(societyAccount(job))
    end)
    return ok and tonumber(money) or 0
end

---@param job string
---@param amount number
---@param add boolean
local function societyTransfer(job, amount, add)
    if not Config.UseSociety or amount <= 0 then return false end
    local ok = pcall(function()
        if add then
            exports[Config.SocietyResource]:AddMoney(societyAccount(job), amount)
        else
            exports[Config.SocietyResource]:RemoveMoney(societyAccount(job), amount)
        end
    end)
    return ok
end

---Trim a GTA plate the same way the client does so lookups match.
---@param plate string
local function normalisePlate(plate)
    if type(plate) ~= 'string' then return nil end
    plate = plate:upper()
    if not Config.PlateSpace then
        plate = plate:gsub('^%s*(.-)%s*$', '%1')
    end
    return plate
end

---@param modelHash number
---@return number
local function getVehicleValue(modelHash)
    return (vehiclePrices[modelHash] or 0) * Config.VehicleValuePercent
end

--- kept for other resources that used exports.renzu_customs:GetVehicleValue
lib.callback.register('renzu_customs:server:getVehicleValue', function(_, modelHash)
    return vehiclePrices[tonumber(modelHash) or 0] or 0
end)

exports('GetVehicleValue', function(modelHash)
    return vehiclePrices[tonumber(modelHash) or 0] or 0
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Pricing (authoritative - the client only ever shows an estimate)
-- ─────────────────────────────────────────────────────────────────────────────

--- native mod index -> key inside the props table
local MOD_PROPERTY = {
    [0] = 'modSpoilers', [1] = 'modFrontBumper', [2] = 'modRearBumper', [3] = 'modSideSkirt',
    [4] = 'modExhaust', [5] = 'modFrame', [6] = 'modGrille', [7] = 'modHood', [8] = 'modFender',
    [9] = 'modRightFender', [10] = 'modRoof', [11] = 'modEngine', [12] = 'modBrakes',
    [13] = 'modTransmission', [14] = 'modHorns', [15] = 'modSuspension', [16] = 'modArmor',
    [22] = false, -- handled by the `headlight` entry
    [23] = 'modFrontWheels', [24] = 'modBackWheels', [25] = 'modPlateHolder',
    [26] = 'modVanityPlate', [27] = 'modTrimA', [28] = 'modOrnaments', [29] = 'modDashboard',
    [30] = 'modDial', [31] = 'modDoorSpeaker', [32] = 'modSeats', [33] = 'modSteeringWheel',
    [34] = 'modShifterLeavers', [35] = 'modAPlate', [36] = 'modSpeakers', [37] = 'modTrunk',
    [38] = 'modHydrolic', [39] = 'modEngineBlock', [40] = 'modAirFilter', [41] = 'modStruts',
    [42] = 'modArchCover', [43] = 'modAerials', [44] = 'modTrimB', [45] = 'modTank',
    [46] = 'modWindows', [48] = 'modLivery',
}

---@param modCfg table
---@param vehicleValue number
---@param job string
---@return number
local function baseCost(modCfg, vehicleValue, job)
    local cost = tonumber(modCfg.cost) or 0

    if Config.VehicleValuetoFormula then
        cost = cost + (vehicleValue / (tonumber(modCfg.percent_cost) or 1))
    end

    if Config.EnableDiscounts then
        local discount = (modCfg.discount and modCfg.discount[job]) or Config.JobDiscounts[job]
        if discount then
            cost = cost * (1 - discount)
        end
    end

    return math.floor(cost + 0.5)
end

local function numOr(value, fallback)
    return tonumber(value) or fallback
end

local function listEqual(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for i = 1, math.max(#a, #b) do
        if a[i] ~= b[i] then return false end
    end
    return true
end

local function tablesEqual(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

---Rebuild the invoice by diffing the vehicle as it was against the vehicle as it is now.
---@param old table
---@param new table
---@param vehicleValue number
---@param job string
---@param class number
---@return number total, table items
local function calculateCost(old, new, vehicleValue, job, class)
    local items = {}
    local total = 0

    if Config.FreeUpgradeToClass[class] then
        return 0, items
    end

    local function add(label, amount)
        if amount <= 0 then return end
        total = total + amount
        items[#items + 1] = { label = label, cost = amount }
    end

    for key, mod in pairs(Config.VehicleMod) do
        local cost = baseCost(mod, vehicleValue, job)
        local property = type(key) == 'number' and MOD_PROPERTY[key] or nil

        if property then
            local before, after = numOr(old[property], -1), numOr(new[property], -1)
            if after ~= before and after >= 0 then
                add(mod.label, mod.multicostperlvl and cost * (after + 1) or cost)
            end
        elseif key == 18 then
            if new.modTurbo and not old.modTurbo then add(mod.label, cost) end
        elseif key == 'paint1' then
            if new.color1 ~= old.color1
                or new.pearlescentColor ~= old.pearlescentColor
                or not listEqual(new.rgb, old.rgb) then
                add(mod.label, cost)
            end
        elseif key == 'paint2' then
            if new.color2 ~= old.color2 or not listEqual(new.rgb2, old.rgb2) then
                add(mod.label, cost)
            end
        elseif key == 'headlight' then
            if (new.modXenon and not old.modXenon) or new.xenonColor ~= old.xenonColor then
                add(mod.label, cost)
            end
        elseif key == 'plate' then
            if new.plateIndex ~= old.plateIndex then add(mod.label, cost) end
        elseif key == 'neon' then
            -- only the kit is paid for, recolouring it afterwards is free (same as
            -- wheel colour and tyre smoke, and it keeps the UI estimate honest)
            local wasOn = old.neonEnabled and (old.neonEnabled[1] or old.neonEnabled[2] or old.neonEnabled[3] or old.neonEnabled[4])
            local isOn = new.neonEnabled and (new.neonEnabled[1] or new.neonEnabled[2] or new.neonEnabled[3] or new.neonEnabled[4])
            if isOn and not wasOn then
                add(mod.label, cost)
            end
        elseif key == 'window' then
            if new.windowTint ~= old.windowTint then add(mod.label, cost) end
        elseif key == 'extra' then
            if not tablesEqual(new.extras, old.extras) then add(mod.label, cost) end
        elseif key == 'custom_engine' then
            local engine = new.custom_engine
            if engine and engine ~= 'Default' and engine ~= old.custom_engine then
                for _, entry in pairs(mod.list) do
                    if entry.model == engine then
                        add(('%s (%s)'):format(mod.label, engine), tonumber(entry.value) or cost)
                        break
                    end
                end
            end
        elseif key == 'custom_turbo' or key == 'custom_tires' then
            local field = key == 'custom_turbo' and 'custom_turbo' or 'custom_tire'
            local choice = new[field]
            if choice and choice ~= 'Default' and choice ~= old[field] then
                local entry = mod.list[choice]
                add(('%s (%s)'):format(mod.label, choice), entry and tonumber(entry.value) or cost)
            end
        end
    end

    -- tyre options are charged under the wheel entry
    local wheels = Config.VehicleMod[23]
    if wheels then
        if new.drift_tire and not old.drift_tire then
            add('Drift Tyres', baseCost(wheels, vehicleValue, job))
        end
        if new.modCustomTires and not old.modCustomTires then
            add('Custom Tyre Walls', baseCost(wheels, vehicleValue, job))
        end
    end

    return math.floor(total + 0.5), items
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Shop stock
-- ─────────────────────────────────────────────────────────────────────────────

---@param shop string
---@return table<string, number>
local function readInventory(shop)
    local row = MySQL.single.await('SELECT inventory FROM renzu_customs WHERE shop = ?', { shop })
    if not row or not row.inventory then return {} end
    local ok, decoded = pcall(json.decode, row.inventory)
    return (ok and type(decoded) == 'table') and decoded or {}
end

---@param shop string
---@param inventory table
local function writeInventory(shop, inventory)
    MySQL.prepare.await('UPDATE renzu_customs SET inventory = ? WHERE shop = ?', { json.encode(inventory), shop })
end

lib.callback.register('renzu_customs:server:getInventory', function(source, shop)
    if not isAtShop(source, shop) then return {} end
    return readInventory(shop)
end)

--- Takes one part out of the shop stock. Returns true when the player may carry it.
lib.callback.register('renzu_customs:server:takePart', function(source, shop, item)
    if not isAtShop(source, shop) or type(item) ~= 'string' then return false end

    local inventory = readInventory(shop)
    local amount = tonumber(inventory[item]) or 0
    if amount <= 0 then return false end

    inventory[item] = amount - 1
    if inventory[item] <= 0 then inventory[item] = nil end

    writeInventory(shop, inventory)
    return true
end)

--- Puts a part into the shop stock. `store` is false when the part was fitted to a car instead.
RegisterNetEvent('renzu_customs:server:storePart', function(shop, modName, level, store)
    local src = source
    if not isAtShop(src, shop) or type(modName) ~= 'string' then return end
    if type(level) ~= 'number' or level < 1 or level > 100 then return end

    local player = getPlayer(src)
    if not player then return end

    local label = modName
    if store then
        local item = ('%s-%s'):format(modName, tostring(level))
        local inventory = readInventory(shop)
        inventory[item] = (tonumber(inventory[item]) or 0) + 1
        writeInventory(shop, inventory)
        label = item
    end

    exports.qbx_core:Notify(src, store
        and ('Stored %s in the shop stock'):format(label)
        or ('Fitted %s'):format(label), 'success')
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Tuning session
-- ─────────────────────────────────────────────────────────────────────────────

--- Opens a session: remembers the untouched vehicle so we can price the diff and
--- restore the car if the player disconnects mid-tune.
lib.callback.register('renzu_customs:server:openSession', function(source, shop, netId, props, free)
    local player = getPlayer(source)
    if not player then return end

    local job = getJob(player)
    -- `free` only counts when /freecustoms already flagged this player server side
    local isFree = free == true and sessions[source] ~= nil and sessions[source].free == true

    if not isFree and not isAtShop(source, shop) then return end

    sessions[source] = {
        shop = shop,
        netId = netId,
        props = props,
        free = isFree,
    }

    local money = isFree and 0 or (player.PlayerData.money[Config.MoneyType] or 0)
    if Config.JobPermissionAll and Config.UseSociety and shop and Config.Customs[shop].job == job then
        money = getSocietyMoney(job)
    end

    return {
        money = money,
        vehicleValue = getVehicleValue(tonumber(props and props.model) or 0),
        free = isFree,
    }
end)

lib.callback.register('renzu_customs:server:repair', function(source, shop)
    local player = getPlayer(source)
    if not player then return false end

    local session = sessions[source]
    if session and session.free then return true end

    local job = getJob(player)
    local shopCfg = getShop(shop)

    -- mechanics repair their own shop's cars for free
    if shopCfg and shopCfg.job == job then return true end

    local cost = Config.RepairCost
    if (player.PlayerData.money[Config.MoneyType] or 0) < cost then
        return false
    end

    if not player.Functions.RemoveMoney(Config.MoneyType, cost, 'renzu-customs-repair') then
        return false
    end

    if shopCfg then societyTransfer(shopCfg.job, cost, true) end
    return true
end)

--- Charges the player and writes the new props to the database.
--- The price is recalculated here, the client value is never trusted.
lib.callback.register('renzu_customs:server:pay', function(source, props, vehicleClass)
    local src = source
    local player = getPlayer(src)
    if not player then return { success = false, message = 'Player not loaded' } end

    local session = sessions[src]
    if not session or type(props) ~= 'table' then
        return { success = false, message = 'No active tuning session' }
    end

    local plate = normalisePlate(props.plate)
    if not plate then
        return { success = false, message = 'Invalid plate' }
    end

    local job = getJob(player)
    local shopCfg = getShop(session.shop)
    local class = tonumber(vehicleClass) or -1
    local cost, items = calculateCost(session.props or {}, props, getVehicleValue(tonumber(props.model) or 0), job, class)

    if session.free then cost = 0 end

    local ownsVehicle = MySQL.single.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate }) ~= nil
    if not ownsVehicle and Config.OwnedVehiclesOnly and not session.free then
        return { success = false, message = 'This vehicle is not registered' }
    end

    -- who pays: the shop's society when the mechanic tunes on the clock, otherwise the customer
    local payFromSociety = Config.JobPermissionAll and Config.UseSociety
        and shopCfg ~= nil and shopCfg.job == job

    if cost > 0 then
        if payFromSociety then
            if getSocietyMoney(job) < cost then
                return { success = false, cost = cost, message = 'The shop cannot afford this' }
            end
            societyTransfer(job, cost, false)
        else
            if (player.PlayerData.money[Config.MoneyType] or 0) < cost then
                return { success = false, cost = cost, message = 'Not enough money' }
            end
            if not player.Functions.RemoveMoney(Config.MoneyType, cost, 'renzu-customs') then
                return { success = false, cost = cost, message = 'Payment failed' }
            end
            if shopCfg then societyTransfer(shopCfg.job, cost, true) end
        end
    end

    if ownsVehicle then
        MySQL.prepare.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(props), plate })
    end

    sessions[src] = nil

    return { success = true, cost = cost, items = items, owned = ownsVehicle }
end)

RegisterNetEvent('renzu_customs:server:closeSession', function()
    sessions[source] = nil
end)

--- Restore the vehicle for everyone if a player drops while the menu is open,
--- otherwise the car keeps the un-paid preview mods.
AddEventHandler('playerDropped', function()
    local src = source
    local session = sessions[src]
    if session and session.netId and session.props then
        TriggerClientEvent('renzu_customs:client:restoreProps', -1, session.netId, session.props)
    end
    sessions[src] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end
    for src, session in pairs(sessions) do
        if session.netId and session.props then
            TriggerClientEvent('renzu_customs:client:restoreProps', -1, session.netId, session.props)
        end
        sessions[src] = nil
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Turbo blow-off sound relay
-- ─────────────────────────────────────────────────────────────────────────────

local soundCooldown = {}

RegisterNetEvent('renzu_customs:server:turboSound', function(payload)
    local src = source
    if not Config.useturbosound or not Config.turbosoundSync then return end
    if type(payload) ~= 'table' or type(payload.file) ~= 'string' then return end

    local now = GetGameTimer()
    if (soundCooldown[src] or 0) > now then return end
    soundCooldown[src] = now + 250

    local origin = GetEntityCoords(GetPlayerPed(src))

    for _, target in ipairs(GetPlayers()) do
        target = tonumber(target)
        if target and target ~= src then
            local distance = #(origin - GetEntityCoords(GetPlayerPed(target)))
            if distance <= 30.0 then
                TriggerClientEvent('renzu_customs:client:playSound', target, {
                    file = payload.file,
                    volume = (tonumber(payload.volume) or 0.4) * (1.0 - (distance / 30.0)),
                })
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    soundCooldown[source] = nil
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin
-- ─────────────────────────────────────────────────────────────────────────────

lib.addCommand('freecustoms', {
    help = 'Open the tuning menu without paying (admin only)',
    restricted = 'group.admin',
}, function(source)
    sessions[source] = { free = true }
    TriggerClientEvent('renzu_customs:client:openMenu', source, true)
end)

--[[
    renzu_customs :: hands-on parts (shop stock, stock room, carrying, spraying)
    All menus are ox_lib contexts, all interactions run through ox_target.
]]

local CARRY_DICT = 'anim@heists@box_carry@'
local CARRY_CLIP = 'idle'
local REPAIR_ANIM = { dict = 'mini@repair', clip = 'fixing_a_ped' }

---@param key string|number
---@return table? mod
local function getMod(key)
    return Config.VehicleMod[tonumber(key) or key]
end

---Splits "frontbumpers-3" into name and level.
---@param item string
---@return string? name, integer? level
local function parseItem(item)
    local name, level = item:match('^(.-)%-(%d+)$')
    return name, tonumber(level)
end

---Finds the Config.VehicleMod key belonging to a mod name.
---@param name string
---@return (string|number)?, table?
local function findModByName(name)
    for key, mod in pairs(Config.VehicleMod) do
        if mod.name and mod.name:lower() == name:lower() then
            return key, mod
        end
    end
end

---@param key string|number
---@return string
local function partIcon(key)
    local mod = getMod(key)
    return ('https://cfx-nui-%s/html/img/%s.svg'):format(GetCurrentResourceName(), mod and mod.index or 0)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Carrying a part
-- ─────────────────────────────────────────────────────────────────────────────

local function playCarryAnim()
    CreateThread(function()
        while Customs.carrying do
            if not IsEntityPlayingAnim(cache.ped, CARRY_DICT, CARRY_CLIP, 3) then
                if Customs.load(lib.requestAnimDict, CARRY_DICT, 2000) then
                    TaskPlayAnim(cache.ped, CARRY_DICT, CARRY_CLIP, 3.0, 3.0, -1, 50, 0, false, false, false)
                end
            end
            Wait(500)
        end
    end)
end

---@param key string|number Config.VehicleMod key
---@param level integer 1 = first upgrade level
---@param item string inventory key
---@param fromStock boolean
function Customs.carryPart(key, level, item, fromStock)
    if Customs.carrying then
        return Customs.notify('Your hands are already full', 'error')
    end

    local mod = getMod(key)
    if not mod then return end

    local model = mod.prop or Config.DefaultProp
    if not Customs.load(lib.requestModel, model) then
        return Customs.notify('Could not load the part model', 'error')
    end

    local coords = GetEntityCoords(cache.ped)
    local object = CreateObject(joaat(model), coords.x, coords.y, coords.z - 5.0, true, true, false)

    SetEntityCollision(object, false, false)
    AttachEntityToEntity(object, cache.ped, GetPedBoneIndex(cache.ped, 28422),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(joaat(model))

    Customs.carrying = {
        key = key,
        level = level,
        item = item,
        object = object,
        fromStock = fromStock == true,
    }

    playCarryAnim()
    Customs.notify(('Carrying %s (level %d)'):format(mod.label, level), 'inform')
end

function Customs.dropCarried()
    if not Customs.carrying then return end
    Customs.deleteEntity(Customs.carrying.object)
    Customs.carrying = nil
    ClearPedTasks(cache.ped)
end

---Puts the carried part into the shop stock.
function Customs.storeCarried()
    local carrying = Customs.carrying
    if not carrying or not Customs.shop then return end

    local mod = getMod(carrying.key)
    if not mod then return end

    if not lib.progressBar({
            duration = 3000,
            label = ('Storing %s'):format(mod.label),
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = REPAIR_ANIM,
        }) then
        return
    end

    TriggerServerEvent('renzu_customs:server:storePart', Customs.shop, mod.name, carrying.level, true)
    Customs.dropCarried()
end

---Fits the carried part onto a vehicle.
---@param vehicle integer
function Customs.installCarried(vehicle)
    local carrying = Customs.carrying
    if not carrying or not DoesEntityExist(vehicle) then return end

    local mod = getMod(carrying.key)
    if not mod then return end

    if not Customs.prepareVehicle(vehicle) then
        return Customs.notify('Could not take control of this vehicle', 'error')
    end

    local available = GetNumVehicleMods(vehicle, mod.index)
    if carrying.level > available then
        return Customs.notify('This part does not fit this vehicle', 'error')
    end

    if not lib.progressBar({
            duration = 6000,
            label = ('Fitting %s'):format(mod.label),
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = REPAIR_ANIM,
        }) then
        return
    end

    SetVehicleMod(vehicle, mod.index, carrying.level - 1, false)

    TriggerServerEvent('renzu_customs:server:storePart', Customs.shop, mod.name, carrying.level, false)
    Customs.dropCarried()
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Shop stock (garage_inventory)
-- ─────────────────────────────────────────────────────────────────────────────

function Customs.openShopInventory()
    local shopId = Customs.shop
    if not shopId then return end

    local inventory = lib.callback.await('renzu_customs:server:getInventory', false, shopId)
    local options = {}

    for item, amount in pairs(inventory or {}) do
        local name, level = parseItem(item)
        if name and level and (tonumber(amount) or 0) > 0 then
            local key, mod = findModByName(name)
            if mod then
                options[#options + 1] = {
                    title = ('%s - Level %d'):format(mod.label, level),
                    description = ('%s in stock  |  %s'):format(amount, mod.type or 'part'),
                    icon = 'box',
                    image = partIcon(key),
                    arrow = true,
                    onSelect = function()
                        if lib.callback.await('renzu_customs:server:takePart', false, shopId, item) then
                            Customs.carryPart(key, level, item, false)
                        else
                            Customs.notify('That part is no longer in stock', 'error')
                        end
                    end,
                }
            end
        end
    end

    if #options == 0 then
        return Customs.notify('The parts storage is empty', 'error')
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'renzu_customs_inventory',
        title = 'Parts Storage',
        options = options,
    })
    lib.showContext('renzu_customs_inventory')
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Stock room (every part that fits the cars parked in the shop)
-- ─────────────────────────────────────────────────────────────────────────────

---@param vehicle integer
---@param key string|number
local function showStockRoomLevels(vehicle, key)
    local mod = getMod(key)
    if not mod or not DoesEntityExist(vehicle) then return end

    Customs.prepareVehicle(vehicle)

    local levels = Customs.buildModLevels(vehicle, mod.index, mod.name)
    local options = {}

    for i = 2, #levels do -- skip "Stock"
        local entry = levels[i]
        options[#options + 1] = {
            title = entry.label,
            description = ('Level %d'):format(entry.level + 1),
            image = partIcon(key),
            onSelect = function()
                Customs.carryPart(key, entry.level + 1, ('%s-%d'):format(mod.name, entry.level + 1), true)
            end,
        }
    end

    if #options == 0 then
        return Customs.notify('No parts available for this slot', 'error')
    end

    lib.registerContext({
        id = 'renzu_customs_stock_levels',
        title = mod.label,
        menu = 'renzu_customs_stock_mods',
        options = options,
    })
    lib.showContext('renzu_customs_stock_levels')
end

---@param vehicle integer
local function showStockRoomMods(vehicle)
    if not DoesEntityExist(vehicle) then return end

    Customs.prepareVehicle(vehicle)

    local options = {}
    for key, mod in pairs(Config.VehicleMod) do
        local index = tonumber(mod.index)
        if index and index <= 48 and index ~= 18 and index ~= 22 then
            local count = GetNumVehicleMods(vehicle, index)
            if count > 0 then
                options[#options + 1] = {
                    title = mod.label,
                    description = ('%d part%s available'):format(count, count == 1 and '' or 's'),
                    image = partIcon(key),
                    arrow = true,
                    onSelect = function() showStockRoomLevels(vehicle, key) end,
                }
            end
        end
    end

    if #options == 0 then
        return Customs.notify('This vehicle has no compatible parts', 'error')
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'renzu_customs_stock_mods',
        title = Customs.vehicleLabel(vehicle),
        menu = 'renzu_customs_stockroom',
        options = options,
    })
    lib.showContext('renzu_customs_stock_mods')
end

function Customs.openStockRoom()
    local coords = GetEntityCoords(cache.ped)
    local options = {}

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(coords - GetEntityCoords(vehicle)) < 60.0 and IsVehicleStopped(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            options[#options + 1] = {
                title = Customs.vehicleLabel(vehicle),
                description = ('Plate %s  |  %s'):format(plate, Customs.className(GetVehicleClass(vehicle))),
                icon = 'car',
                arrow = true,
                onSelect = function() showStockRoomMods(vehicle) end,
            }
        end
    end

    if #options == 0 then
        return Customs.notify('No vehicles parked nearby', 'error')
    end

    lib.registerContext({
        id = 'renzu_customs_stockroom',
        title = 'Stock Room',
        options = options,
    })
    lib.showContext('renzu_customs_stockroom')
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Pulling parts off a vehicle
-- ─────────────────────────────────────────────────────────────────────────────

---@param vehicle integer
---@param key string|number
local function removePart(vehicle, key)
    local mod = getMod(key)
    if not mod or not DoesEntityExist(vehicle) then return end

    local level = GetVehicleMod(vehicle, mod.index) + 1
    if level <= 0 then
        return Customs.notify('That part is already stock', 'error')
    end

    if not Customs.prepareVehicle(vehicle) then
        return Customs.notify('Could not take control of this vehicle', 'error')
    end

    if not lib.progressBar({
            duration = 6000,
            label = ('Removing %s'):format(mod.label),
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = REPAIR_ANIM,
        }) then
        return
    end

    SetVehicleMod(vehicle, mod.index, -1, false)
    Customs.carryPart(key, level, ('%s-%d'):format(mod.name, level), false)
end

---@param vehicle integer
function Customs.inspectVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end

    Customs.prepareVehicle(vehicle)

    local options = {}
    for key, mod in pairs(Config.VehicleMod) do
        local index = tonumber(mod.index)
        if index and index <= 48 and index ~= 18 and index ~= 22 then
            local level = GetVehicleMod(vehicle, index) + 1
            if level > 0 then
                options[#options + 1] = {
                    title = ('%s - Level %d'):format(mod.label, level),
                    description = 'Remove this part',
                    image = partIcon(key),
                    onSelect = function() removePart(vehicle, key) end,
                }
            end
        end
    end

    if #options == 0 then
        return Customs.notify('This vehicle is completely stock', 'inform')
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'renzu_customs_vehicle_parts',
        title = Customs.vehicleLabel(vehicle),
        options = options,
    })
    lib.showContext('renzu_customs_vehicle_parts')
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Spray can painting
-- ─────────────────────────────────────────────────────────────────────────────

local PTFX_DICT = 'scr_recartheft'

---@param color number[] rgb
local function sprayParticles(color)
    if not Customs.load(lib.requestNamedPtfxAsset, PTFX_DICT, 2000) then return end

    local forward = GetEntityForwardVector(cache.ped)
    local coords = GetEntityCoords(cache.ped) + forward * 0.5

    UseParticleFxAssetNextCall(PTFX_DICT)
    SetParticleFxNonLoopedColour(color[1] / 255, color[2] / 255, color[3] / 255)
    SetParticleFxNonLoopedAlpha(1.0)
    StartNetworkedParticleFxNonLoopedAtCoord('scr_wheel_burnout',
        coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, GetEntityHeading(cache.ped), 0.7, false, false, false)
end

---@param colorName string key inside Config.Pilox
---@param vehicle integer
local function paintVehicle(colorName, vehicle)
    local color = Config.Pilox[colorName:lower()]
    if not color or not DoesEntityExist(vehicle) then return end

    if not Customs.prepareVehicle(vehicle) then
        return Customs.notify('Could not take control of this vehicle', 'error')
    end

    Customs.spraying = true

    CreateThread(function()
        while Customs.spraying do
            sprayParticles(color)
            Wait(1200)
        end
        RemoveNamedPtfxAsset(PTFX_DICT)
    end)

    local done = lib.progressBar({
        duration = 12000,
        label = ('Spraying %s'):format(colorName),
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_01_inspector' },
    })

    Customs.spraying = false

    if done then
        SetVehicleCustomPrimaryColour(vehicle, color[1], color[2], color[3])
        Customs.notify(('Sprayed the vehicle %s'):format(colorName), 'success')
    end

    Customs.deleteEntity(Customs.sprayCan)
    Customs.sprayCan = nil
    Customs.paintColor = nil
    ClearPedTasks(cache.ped)
end

---@param colorName string
local function takeSprayCan(colorName)
    if Customs.paintColor then
        return Customs.notify('You are already holding a spray can', 'error')
    end

    if colorName == 'custom' then
        Customs.customPaintDone = false
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openSprayPicker' })

        local timeout = GetGameTimer() + 60000
        while not Customs.customPaintDone and GetGameTimer() < timeout do Wait(100) end

        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeSprayPicker' })

        if not Customs.customPaintDone then return end
    end

    if not Customs.load(lib.requestModel, 'ng_proc_spraycan01a') then
        return Customs.notify('Could not load the spray can', 'error')
    end

    local coords = GetEntityCoords(cache.ped)
    Customs.sprayCan = CreateObject(`ng_proc_spraycan01a`, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(Customs.sprayCan, cache.ped, GetPedBoneIndex(cache.ped, 57005),
        0.072, 0.041, -0.06, 33.0, 38.0, 0.0, true, true, false, true, 1, true)

    Customs.paintColor = colorName
    Customs.notify(('Holding a %s spray can, target a vehicle'):format(colorName), 'inform')
end

function Customs.openPaintMenu()
    local options = {}

    for name in pairs(Config.Pilox) do
        options[#options + 1] = {
            title = name:upper(),
            description = name == 'custom' and 'Pick your own RGB colour' or 'Take a spray can',
            icon = 'spray-can',
            iconColor = ('rgb(%d,%d,%d)'):format(table.unpack(Config.Pilox[name])),
            onSelect = function() takeSprayCan(name) end,
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'renzu_customs_paint',
        title = 'Spray Paints',
        options = options,
    })
    lib.showContext('renzu_customs_paint')
end

---@param vehicle integer
function Customs.sprayVehicle(vehicle)
    if not Customs.paintColor then return end
    paintVehicle(Customs.paintColor, vehicle)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Cleanup
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Customs.carrying then Customs.deleteEntity(Customs.carrying.object) end
    if Customs.sprayCan then Customs.deleteEntity(Customs.sprayCan) end
end)

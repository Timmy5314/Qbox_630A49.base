--[[
    renzu_customs :: tuning menu (camera + NUI payload)
]]

local TUNER_DLC = GetGameBuildNumber() >= 2372

--- Config.VehicleMod key -> svg file inside html/img
local ICONS = {
    paint1 = 'paint1',
    paint2 = 'paint2',
    headlight = 'headlight',
    plate = 'plate',
    neon = 'neon',
    window = 'window',
    extra = 'extra',
    custom_engine = 'custom_engine',
    custom_turbo = 'custom_turbo',
    custom_tires = 'custom_tires',
}

--- order the categories show up in, anything unlisted lands at the end
local CATEGORY_ORDER = {
    ['PERFORMANCE PARTS'] = 1,
    ['CUSTOM ENGINE'] = 2,
    ['CUSTOM TURBO'] = 3,
    ['CUSTOM TIRES'] = 4,
    ['WHEEL PARTS'] = 5,
    ['EXTERIOR'] = 6,
    ['COSMETIC'] = 7,
    ['INTERIOR'] = 8,
    ['SHELL'] = 9,
    ['PRIMARY COLOR'] = 10,
    ['SECONDARY COLOR'] = 11,
    ['HEADLIGHTS'] = 12,
    ['NEON LIGHTS'] = 13,
    ['WINDOW TINTS'] = 14,
    ['PLATE'] = 15,
    ['EXTRAS'] = 16,
}

---Turns a config key into a readable label.
--- `custom_turbo` -> `Custom Turbo`, `BikeWheel` -> `Bike Wheel`, `SUV` stays `SUV`.
--- Only the first letter of each word is touched, so acronyms and model names survive.
---@param text string
---@return string
local function prettify(text)
    local clean = tostring(text)
        :gsub('[_\t]', ' ')
        :gsub('(%l)(%u)', '%1 %2')
        :gsub('%s+', ' ')
        :gsub('^%s*(.-)%s*$', '%1')

    return (clean:gsub('%S+', function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

---Turns a `{ [label] = value }` config table into a sorted array the UI can render.
--- `icon` keeps the raw key, because the svg filenames are case sensitive.
---@param source table
---@param sortByValue? boolean
---@return table[]
local function toSortedList(source, sortByValue)
    local list = {}
    for label, value in pairs(source) do
        list[#list + 1] = { label = prettify(label), value = value, icon = tostring(label) }
    end

    table.sort(list, function(a, b)
        if sortByValue and type(a.value) == 'number' and type(b.value) == 'number' then
            return a.value < b.value
        end
        return a.label < b.label
    end)

    return list
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Camera
-- ─────────────────────────────────────────────────────────────────────────────

---@param view string
---@param x number
---@param y number
---@param z number
---@param width number
---@param length number
---@param height number
---@return number, number, number
local function viewOffset(view, x, y, z, width, length, height)
    if view == 'left' then return -(width / 2) + x, y, z end
    if view == 'right' then return (width / 2) + x, y, z end
    if view == 'front' then return x, (length / 2) + y, z end
    if view == 'front-top' then return x, (length / 2) + y, height + z end
    if view == 'back' then return x, -(length / 2) + y, z end
    if view == 'back-top' then return x, -(length / 2) + y, (height / 2) + z end
    return x, y, (height / 2) + z -- middle
end

---@param view string
---@param x number
---@param y number
---@param z number
function Customs.setCamView(view, x, y, z)
    local vehicle = Customs.vehicle
    if not Customs.cam or not vehicle or not DoesEntityExist(vehicle) then return end

    local dimensions = GetModelDimensions(GetEntityModel(vehicle))
    local width, length, height = dimensions.x * -2, dimensions.y * -2, dimensions.z * -2
    local coords = vec3(viewOffset(view, x, y, z, width, length, height))
    local world = GetOffsetFromEntityInWorldCoords(vehicle, coords.x, coords.y, coords.z)

    Customs.camView = view
    SetCamCoord(Customs.cam, world.x, world.y, world.z)
    PointCamAtCoord(Customs.cam, GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, 0.0))
    RenderScriptCams(true, true, 900, true, true)
end

---@param bone string?
function Customs.setCamBone(bone)
    local vehicle = Customs.vehicle
    if not bone or not Customs.cam or not vehicle or not DoesEntityExist(vehicle) then return end

    local boneIndex = GetEntityBoneIndexByName(vehicle, bone)
    if boneIndex == -1 and bone == 'wheel_rf' then
        boneIndex = GetEntityBoneIndexByName(vehicle, 'engine')
    end
    if boneIndex == -1 then return end

    local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, GetWorldPositionOfEntityBone(vehicle, boneIndex))
    local world = GetOffsetFromEntityInWorldCoords(vehicle, offset.x + 1.0, offset.y + 1.0, offset.z + 1.0)

    SetCamCoord(Customs.cam, world.x, world.y, world.z)
    PointCamAtCoord(Customs.cam, GetOffsetFromEntityInWorldCoords(vehicle, 0.0, offset.y, offset.z))
    RenderScriptCams(true, true, 900, true, true)
end

function Customs.openCamera()
    if not Customs.cam then
        Customs.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end
    SetCamActive(Customs.cam, true)
    Customs.setCamView('front', -2.5, 0.1, 1.3)
end

function Customs.closeCamera()
    RenderScriptCams(false, true, 500, true, true)
    if Customs.cam then
        DestroyCam(Customs.cam, true)
        Customs.cam = nil
    end
    Customs.camView = nil
    ClearFocus()
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Pricing (mirror of the server formula - the server always has the last word)
-- ─────────────────────────────────────────────────────────────────────────────

---@param mod table
---@param class integer
---@return integer
function Customs.modCost(mod, class)
    if Config.FreeUpgradeToClass[class] or Customs.freeMode then return 0 end

    local cost = tonumber(mod.cost) or 0

    if Config.VehicleValuetoFormula then
        cost = cost + (Customs.vehicleValue / (tonumber(mod.percent_cost) or 1))
    end

    if Config.EnableDiscounts then
        local job = Customs.getJob()
        local discount = (mod.discount and job and mod.discount[job]) or (job and Config.JobDiscounts[job])
        if discount then cost = cost * (1 - discount) end
    end

    return math.floor(cost + 0.5)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Mod lists
-- ─────────────────────────────────────────────────────────────────────────────

---Builds the level list of a native mod index.
---@param vehicle integer
---@param index integer
---@param fallbackName string
---@return table[] levels, integer max
function Customs.buildModLevels(vehicle, index, fallbackName)
    local levels = { { label = 'Stock', level = -1 } }
    local max = GetNumVehicleMods(vehicle, index)
    local liveryMode = false

    if index == 48 and max <= 0 then
        max = GetVehicleLiveryCount(vehicle)
        liveryMode = max > 0
    end

    for level = 0, max - 1 do
        local label

        if liveryMode then
            label = GetLabelText(GetLiveryName(vehicle, level))
        else
            label = GetLabelText(GetModTextLabel(vehicle, index, level))
        end

        if not label or label == '' or label == 'NULL' then
            label = ('%s %d'):format(prettify(fallbackName or 'Mod'), level + 1)
        end

        levels[#levels + 1] = { label = label, level = level }
    end

    return levels, max
end

---@param vehicle integer
---@return table[]
local function buildExtras(vehicle)
    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            extras[#extras + 1] = {
                label = ('Extra %d'):format(extraId),
                value = extraId,
                enabled = IsVehicleExtraTurnedOn(vehicle, extraId) == 1,
            }
        end
    end
    return extras
end

---@param mod table
---@return table[]
local function buildPaintGroups(mod)
    local groups = {}

    for label, colors in pairs(mod.list) do
        groups[#groups + 1] = {
            label = prettify(label),
            option = label, -- Pearlescent / Chameleon change how the colour is applied
            colors = toSortedList(colors, true),
        }
    end

    table.sort(groups, function(a, b) return a.label < b.label end)
    return groups
end

---@param mod table
---@return table[]
local function buildCustomList(mod)
    local list = {}

    for label, entry in pairs(mod.list) do
        if label == 'Default' then
            list[#list + 1] = { label = 'Remove', key = 'Default', value = 0, model = 'Default' }
        else
            list[#list + 1] = {
                label = prettify(label),
                key = label,
                value = tonumber(entry.value) or 0,
                model = entry.model or label,
            }
        end
    end

    table.sort(list, function(a, b) return a.value < b.value end)
    return list
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Payload
-- ─────────────────────────────────────────────────────────────────────────────

---@param vehicle integer
---@param shopId string?
---@return table
function Customs.buildPayload(vehicle, shopId)
    local class = GetVehicleClass(vehicle)
    local categories = {}

    for key, mod in pairs(Config.VehicleMod) do
        if Customs.canUseMod(mod) then
            local index = tonumber(mod.index) or 0
            local icon = ICONS[key] or tostring(index)
            local cost = Customs.modCost(mod, class)

            local item = {
                key = key,
                index = index,
                label = mod.label or tostring(key),
                name = mod.name or tostring(key),
                icon = icon,
                cost = cost,
                multicost = mod.multicostperlvl == true,
                bone = mod.bone,
                action = mod.action,
                camera = mod.camera,
            }

            local include = true

            if key == 'paint1' or key == 'paint2' then
                local primary, secondary = GetVehicleColours(vehicle)
                item.kind = 'paint'
                item.groups = buildPaintGroups(mod)
                item.target = key == 'paint1' and 'primary' or 'secondary'
                item.current = key == 'paint1' and primary or secondary
            elseif key == 'headlight' then
                item.kind = 'headlight'
                item.colors = toSortedList(mod.list.XenonColor, true)
                item.enabled = IsToggleModOn(vehicle, 22)
                item.current = GetVehicleXenonLightsColour(vehicle)
            elseif key == 'plate' then
                item.kind = 'plate'
                item.options = toSortedList(mod.list, true)
                item.current = GetVehicleNumberPlateTextIndex(vehicle)
            elseif key == 'neon' then
                item.kind = 'neon'
                item.enabled = IsVehicleNeonLightEnabled(vehicle, 0)
            elseif key == 'window' then
                item.kind = 'window'
                item.options = toSortedList(mod.list, true)
                item.current = GetVehicleWindowTint(vehicle)
            elseif key == 'extra' then
                item.kind = 'extra'
                item.options = buildExtras(vehicle)
                include = #item.options > 0
            elseif key == 'custom_engine' or key == 'custom_turbo' or key == 'custom_tires' then
                item.kind = 'custom'
                item.slot = key
                item.options = buildCustomList(mod)
                item.current = key == 'custom_engine' and Customs.getVehicleEngine(vehicle)
                    or key == 'custom_turbo' and Customs.getVehicleTurbo(vehicle)
                    or Customs.getVehicleTireType(vehicle)
            elseif index == 18 then
                item.kind = 'toggle'
                item.callback = 'ToggleTurbo'
                item.enabled = IsToggleModOn(vehicle, 18)
            elseif index == 23 then
                item.kind = 'wheels'
                -- bikes only accept the bike wheel set
                item.wheelTypes = class == 8
                    and { { label = 'Bike Wheel', value = 6, icon = 'BikeWheel' } }
                    or toSortedList(mod.list.WheelType, true)
                item.colors = toSortedList(mod.list.WheelColor, true)
                item.accessories = {}
                item.currentType = GetVehicleWheelType(vehicle)

                for accessory in pairs(mod.list.Accessories) do
                    if accessory ~= 'DriftTires' or TUNER_DLC then
                        item.accessories[#item.accessories + 1] = { label = prettify(accessory), value = accessory }
                    end
                end
                table.sort(item.accessories, function(a, b) return a.label < b.label end)

                item.levels = Customs.buildModLevels(vehicle, index, mod.name)
                item.current = GetVehicleMod(vehicle, index)
                item.customTires = GetVehicleModVariation(vehicle, 23)
                item.driftEnabled = TUNER_DLC and GetDriftTyresEnabled(vehicle) or false
            else
                item.kind = 'mod'
                item.levels = Customs.buildModLevels(vehicle, index, mod.name)
                item.current = GetVehicleMod(vehicle, index)
                -- nothing but "Stock" means this vehicle has no parts for that slot
                include = #item.levels > 1
            end

            if include then
                -- config mixes 'Interior' and 'interior', so group on the upper case
                -- key but show the readable form
                local categoryType = mod.type or 'Cosmetic'
                local categoryKey = categoryType:upper()
                local category = categories[categoryKey]

                if not category then
                    category = {
                        id = categoryKey,
                        label = prettify(categoryType:lower()),
                        icon = icon,
                        order = CATEGORY_ORDER[categoryKey] or 99,
                        items = {},
                    }
                    categories[categoryKey] = category
                end

                category.items[#category.items + 1] = item
            end
        end
    end

    local sorted = {}
    for _, category in pairs(categories) do
        table.sort(category.items, function(a, b) return a.label < b.label end)
        category.icon = category.items[1].icon -- deterministic, pairs() order is not
        sorted[#sorted + 1] = category
    end

    table.sort(sorted, function(a, b)
        if a.order == b.order then return a.label < b.label end
        return a.order < b.order
    end)

    local shop = shopId and Config.Customs[shopId]

    return {
        shop = shopId or 'Admin',
        shopLabel = shop and (shop.label or shopId) or 'Admin Garage',
        vehicle = Customs.vehicleLabel(vehicle),
        vehicleClass = Customs.className(class),
        plate = GetVehicleNumberPlateText(vehicle),
        free = Customs.freeMode,
        categories = sorted,
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Open / close
-- ─────────────────────────────────────────────────────────────────────────────

---@param shopId string?
---@param free? boolean opened through /freecustoms
function Customs.openMenu(shopId, free)
    if Customs.inMenu then return end

    local vehicle = Customs.currentVehicle()
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return Customs.notify('You need to be in a vehicle', 'error')
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then
        return Customs.notify('Only the driver can use the tuning menu', 'error')
    end

    if not Customs.prepareVehicle(vehicle) then
        return Customs.notify('Could not take control of this vehicle', 'error')
    end

    local props = Customs.getVehicleProperties(vehicle)
    local netId = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or nil

    local session = lib.callback.await('renzu_customs:server:openSession', false, shopId, netId, props, free == true)
    if not session then
        return Customs.notify('The shop is not available right now', 'error')
    end

    Customs.freeMode = session.free == true
    Customs.vehicleValue = session.vehicleValue or 0
    Customs.vehicle = vehicle
    Customs.oldProps = props
    Customs.shopSession = shopId

    -- build the payload before committing to `inMenu`, otherwise a broken config
    -- entry would leave the player locked out of the menu until a resource restart
    local ok, payload = pcall(Customs.buildPayload, vehicle, shopId)
    if not ok then
        Customs.vehicle, Customs.oldProps, Customs.shopSession, Customs.freeMode = nil, nil, nil, false
        TriggerServerEvent('renzu_customs:server:closeSession')
        lib.print.error(payload)
        return Customs.notify('Could not build the tuning menu, check your Config.VehicleMod', 'error')
    end

    Customs.inMenu = true

    local health = GetVehicleBodyHealth(vehicle)
    local needsRepair = not Config.DisableRepair and health < 1000.0

    payload.money = Customs.comma(session.money or 0)
    payload.needsRepair = needsRepair
    payload.repairCost = Customs.comma(Config.RepairCost)

    FreezeEntityPosition(vehicle, true)
    Customs.openCamera()
    DisplayRadar(false)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload })
end

---@param restore boolean restore the props the vehicle had when the menu opened
function Customs.closeMenu(restore)
    if not Customs.inMenu then return end
    Customs.inMenu = false

    local vehicle = Customs.vehicle

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })

    if vehicle and DoesEntityExist(vehicle) then
        if restore and Customs.oldProps then
            Customs.setVehicleProperties(vehicle, Customs.oldProps)
        end
        FreezeEntityPosition(vehicle, false)
    end

    Customs.closeCamera()
    DisplayRadar(true)

    Customs.vehicle = nil
    Customs.oldProps = nil
    Customs.freeMode = false
    Customs.shopSession = nil

    TriggerServerEvent('renzu_customs:server:closeSession')
end

RegisterNetEvent('renzu_customs:client:openMenu', function(free)
    Customs.openMenu(Customs.getShopAt(), free)
end)

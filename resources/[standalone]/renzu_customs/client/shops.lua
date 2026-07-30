--[[
    renzu_customs :: shops, blips, ox_target zones and player data
]]

local RESOURCE = GetCurrentResourceName()

local GLOBAL_VEHICLE_OPTIONS = {
    'renzu_customs:inspect',
    'renzu_customs:install',
    'renzu_customs:spray',
}

-- ─────────────────────────────────────────────────────────────────────────────
--  Player data
-- ─────────────────────────────────────────────────────────────────────────────

local function refreshPlayerData()
    local data = exports.qbx_core:GetPlayerData()
    Customs.playerData = data or {}
    Customs.loaded = data ~= nil and data.citizenid ~= nil
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Customs.playerData = {}
    Customs.loaded = false
    if Customs.inMenu then Customs.closeMenu(true) end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Customs.playerData.job = job
end)

-- qb-core fires 'QBCore:Player:SetPlayerData'; register both spellings so a rename
-- upstream cannot silently leave us with stale job data.
local function onPlayerDataChanged(data)
    if type(data) == 'table' then Customs.playerData = data end
end

RegisterNetEvent('QBCore:Player:SetPlayerData', onPlayerDataChanged)
RegisterNetEvent('QBCore:Client:SetPlayerData', onPlayerDataChanged)

-- ─────────────────────────────────────────────────────────────────────────────
--  Blips
-- ─────────────────────────────────────────────────────────────────────────────

local function createBlips()
    if not Config.Blips.enabled then return end

    for id, shop in pairs(Config.Customs) do
        local blip = AddBlipForCoord(shop.shopcoord.x, shop.shopcoord.y, shop.shopcoord.z)

        SetBlipSprite(blip, Config.Blips.sprite)
        SetBlipDisplay(blip, Config.Blips.display)
        SetBlipScale(blip, Config.Blips.scale)
        SetBlipColour(blip, Config.Blips.color)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.label or ('Mechanic: %s'):format(id))
        EndTextCommandSetBlipName(blip)

        Customs.blips[#Customs.blips + 1] = blip
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Zones
-- ─────────────────────────────────────────────────────────────────────────────

---@param coords vector4
---@param size vector3
---@param options table[]
local function addZone(coords, size, options)
    Customs.zones[#Customs.zones + 1] = exports.ox_target:addBoxZone({
        coords = vec3(coords.x, coords.y, coords.z),
        size = size,
        rotation = coords.w or 0.0,
        debug = Config.Debug,
        drawSprite = true,
        options = options,
    })
end

---@param shopId string
---@param shop table
local function createShopZones(shopId, shop)
    -- tuning bays
    for index, bay in ipairs(shop.mod or {}) do
        addZone(bay.coord, bay.size or Config.Target.modBaySize, { {
            name = ('renzu_customs:tune:%s:%d'):format(shopId, index),
            icon = 'fa-solid fa-screwdriver-wrench',
            label = 'Open tuning menu',
            distance = 5.0,
            canInteract = function()
                return not Customs.inMenu
                    and cache.vehicle ~= nil
                    and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped
                    and Customs.canTune(shopId)
            end,
            onSelect = function() Customs.openMenu(shopId) end,
        } })
    end

    -- stock room
    if Config.InteractiveFeature.stockroom and shop.stockroom then
        addZone(shop.stockroom.coord, shop.stockroom.size or Config.Target.stationSize, { {
            name = ('renzu_customs:stockroom:%s'):format(shopId),
            icon = 'fa-solid fa-warehouse',
            label = 'Open stock room',
            distance = Config.Target.distance,
            canInteract = function()
                return not cache.vehicle and Customs.hasShopAccess(shopId, 'stockroom')
            end,
            onSelect = function() Customs.openStockRoom() end,
        } })
    end

    -- spray paint station
    if Config.InteractiveFeature.paintmenu and shop.paintmenu then
        addZone(shop.paintmenu.coord, shop.paintmenu.size or Config.Target.stationSize, { {
            name = ('renzu_customs:paint:%s'):format(shopId),
            icon = 'fa-solid fa-spray-can',
            label = 'Spray paints',
            distance = Config.Target.distance,
            canInteract = function()
                return not cache.vehicle and not Customs.paintColor and Customs.hasShopAccess(shopId, 'paintmenu')
            end,
            onSelect = function() Customs.openPaintMenu() end,
        } })
    end

    -- parts storage
    if Config.InteractiveFeature.garage_inventory and shop.garage_inventory then
        addZone(shop.garage_inventory.coord, shop.garage_inventory.size or Config.Target.stationSize, {
            {
                name = ('renzu_customs:inventory:%s'):format(shopId),
                icon = 'fa-solid fa-boxes-stacked',
                label = 'Parts storage',
                distance = Config.Target.distance,
                canInteract = function()
                    return not cache.vehicle and not Customs.carrying
                        and Customs.hasShopAccess(shopId, 'garage_inventory')
                end,
                onSelect = function() Customs.openShopInventory() end,
            },
            {
                name = ('renzu_customs:store:%s'):format(shopId),
                icon = 'fa-solid fa-box-archive',
                label = 'Store the part you are carrying',
                distance = Config.Target.distance,
                canInteract = function()
                    return not cache.vehicle and Customs.carrying ~= nil
                        and Customs.hasShopAccess(shopId, 'garage_inventory')
                end,
                onSelect = function() Customs.storeCarried() end,
            },
        })
    end
end

local function createGlobalVehicleOptions()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'renzu_customs:inspect',
            icon = 'fa-solid fa-wrench',
            label = 'Inspect vehicle parts',
            distance = 2.5,
            canInteract = function()
                return Config.InteractiveFeature.vehicle_parts
                    and Customs.shop ~= nil
                    and not cache.vehicle
                    and not Customs.carrying
                    and not Customs.paintColor
                    and Customs.hasShopAccess(Customs.shop, 'garage_inventory')
            end,
            onSelect = function(data) Customs.inspectVehicle(data.entity) end,
        },
        {
            name = 'renzu_customs:install',
            icon = 'fa-solid fa-screwdriver',
            label = 'Fit the part you are carrying',
            distance = 2.5,
            canInteract = function()
                return Customs.carrying ~= nil and not cache.vehicle
            end,
            onSelect = function(data) Customs.installCarried(data.entity) end,
        },
        {
            name = 'renzu_customs:spray',
            icon = 'fa-solid fa-spray-can',
            label = 'Spray this vehicle',
            distance = 2.5,
            canInteract = function()
                return Customs.paintColor ~= nil and not cache.vehicle and not Customs.spraying
            end,
            onSelect = function(data) Customs.sprayVehicle(data.entity) end,
        },
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Shop presence (ox_lib points, no polling loop)
-- ─────────────────────────────────────────────────────────────────────────────

local function createShopPoints()
    for id, shop in pairs(Config.Customs) do
        lib.points.new({
            coords = vec3(shop.shopcoord.x, shop.shopcoord.y, shop.shopcoord.z),
            distance = shop.radius or 30.0,
            shopId = id,
            onEnter = function(self)
                Customs.shop = self.shopId
            end,
            onExit = function(self)
                if Customs.shop == self.shopId then
                    Customs.shop = nil
                end
            end,
        })
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Boot / cleanup
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    createBlips()
    createShopPoints()
    createGlobalVehicleOptions()

    for id, shop in pairs(Config.Customs) do
        createShopZones(id, shop)
    end

    while not LocalPlayer.state.isLoggedIn do Wait(250) end
    refreshPlayerData()
end)

--- carrying a part through a respawn would leave the prop stuck to the ped
CreateThread(function()
    while true do
        if Customs.carrying and IsPedDeadOrDying(cache.ped, true) then
            Customs.dropCarried()
        end
        Wait(2000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end

    if Customs.inMenu then Customs.closeMenu(true) end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
    lib.hideTextUI()

    for _, blip in ipairs(Customs.blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end

    for _, zone in ipairs(Customs.zones) do
        exports.ox_target:removeZone(zone)
    end

    exports.ox_target:removeGlobalVehicle(GLOBAL_VEHICLE_OPTIONS)
end)

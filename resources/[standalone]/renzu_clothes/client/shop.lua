---@diagnostic disable: undefined-global
--- Shop points in the world: blips, zones, racks, register and wardrobe.
--- Points are only created once you get near a shop.

local useTarget = GetResourceState('ox_target'):find('start') ~= nil

local activePoints = {}
local activePeds = {}
local activeTargets = {}

-- ── Interaction helpers ───────────────────────────────────────────────────

local textUiOpen = false

local function showHint(label)
    if textUiOpen then return end
    textUiOpen = true

    lib.showTextUI(('[E]  %s'):format(label), {
        position = 'right-center',
        icon = 'shirt',
        style = {
            borderRadius = 8,
            backgroundColor = '#12141c',
            color = '#e8eaf2',
        },
    })
end

local function hideHint()
    if not textUiOpen then return end
    textUiOpen = false
    lib.hideTextUI()
end

-- ── Points ────────────────────────────────────────────────────────────────

---@param shop table
---@param entry table { coord, label, categories, kind }
local function createPoint(shop, entry)
    local point = lib.points.new({
        coords = entry.coord,
        distance = 8.0,
    })

    function point:onExit()
        if self.hinted then
            self.hinted = false
            hideHint()
        end
    end

    function point:nearby()
        if Shop.isOpen() then
            if self.hinted then
                self.hinted = false
                hideHint()
            end
            return
        end

        local marker = Config.ShopSettings.marker
        DrawMarker(marker.type, self.coords.x, self.coords.y, self.coords.z + 0.02,
            0.0, 0.0, 0.0, 180.0, 0.0, 0.0,
            marker.scale, marker.scale, marker.scale,
            marker.r, marker.g, marker.b, marker.a,
            false, true, 2, false, nil, nil, false)

        local close = self.currentDistance < Config.ShopSettings.interactDistance

        if close and not self.hinted then
            self.hinted = true

            local count = Shop.cartCount()
            if entry.kind == 'register' and count > 0 then
                showHint(('%s (%d)'):format(entry.label, count))
            else
                showHint(entry.label)
            end
        elseif not close and self.hinted then
            self.hinted = false
            hideHint()
        end

        if close and IsControlJustReleased(0, 38) then -- E
            self.hinted = false
            hideHint()

            -- Own thread: opening waits on the server and this runs inside
            -- the ox_lib points loop, which we must not block.
            CreateThread(function()
                if entry.kind == 'wardrobe' then
                    Outfits.openMenu()
                else
                    Shop.open(shop, entry.categories, entry.opts)
                end
            end)
        end
    end

    activePoints[#activePoints + 1] = point
end

---@param shop table
---@param entry table
local function createTarget(shop, entry)
    local name = ('renzu_clothes:%s:%s'):format(shop.name, entry.label)

    local id = exports.ox_target:addBoxZone({
        name = name,
        -- The rack coords sit on the floor. Raising the box by a metre puts it
        -- where the player actually aims, otherwise the eye ray misses it.
        coords = vec3(entry.coord.x, entry.coord.y, entry.coord.z + 1.0),
        size = Config.ShopSettings.targetSize,
        rotation = 0,
        options = {
            {
                name = name,
                label = entry.label,
                icon = entry.kind == 'wardrobe' and 'fa-solid fa-box-archive'
                    or entry.kind == 'register' and 'fa-solid fa-cash-register'
                    or 'fa-solid fa-shirt',
                distance = Config.ShopSettings.targetDistance,
                onSelect = function()
                    if entry.kind == 'wardrobe' then
                        Outfits.openMenu()
                    else
                        Shop.open(shop, entry.categories, entry.opts)
                    end
                end,
            },
        },
    })

    -- addBoxZone returns a numeric id; that is the only thing removeZone
    -- accepts later on.
    activeTargets[#activeTargets + 1] = id
end

---@param shop table
---@param entry table
local function createInteraction(shop, entry)
    if useTarget then
        createTarget(shop, entry)
    else
        createPoint(shop, entry)
    end
end

-- ── Shop clerk ────────────────────────────────────────────────────────────

---@param shop table
local function spawnPed(shop)
    if not Config.ShopSettings.ped.spawn or not shop.ped then return end

    local model = joaat(Config.ShopSettings.ped.model)
    local ok = pcall(lib.requestModel, model, 5000)
    if not ok or not HasModelLoaded(model) then return end

    local ped = CreatePed(4, model, shop.ped.x, shop.ped.y, shop.ped.z, 0.0, false, false)
    SetModelAsNoLongerNeeded(model)

    -- Deliberately NOT frozen: a frozen ped cannot turn towards the player.
    -- SetBlockingOfNonTemporaryEvents keeps it from wandering off or fleeing.
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedFleeAttributes(ped, 0, false)

    local target = shop.cashier or shop.coord
    local baseHeading = GetHeadingFromVector_2d(target.x - shop.ped.x, target.y - shop.ped.y)
    SetEntityHeading(ped, baseHeading)

    activePeds[#activePeds + 1] = ped

    -- De verkoper is puur decoratief: het enige koop-punt is de kassa-zone
    -- (zie buildShop). Zo is er precies één plek om te winkelen én af te rekenen,
    -- geen losse target op elk kledingrek meer.

    -- The clerk turns to face you when you walk up, and turns back to the
    -- register once you leave (same behaviour as renzu_garage).
    CreateThread(function()
        local faceDistance = Config.ShopSettings.ped.faceDistance or 3.0
        local facing = false

        while DoesEntityExist(ped) do
            local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(ped))

            if dist < faceDistance then
                if not facing then
                    facing = true
                    TaskTurnPedToFaceEntity(ped, cache.ped, -1)
                end
            elseif facing then
                facing = false
                ClearPedTasks(ped)
                TaskAchieveHeading(ped, baseHeading, 1500)
            end

            Wait(dist < 10.0 and 400 or 1200)
        end
    end)
end

-- ── Zones ─────────────────────────────────────────────────────────────────

local function clearShop()
    for i = 1, #activePoints do
        activePoints[i]:remove()
    end
    activePoints = {}

    for i = 1, #activeTargets do
        local id = activeTargets[i]
        pcall(function() exports.ox_target:removeZone(id) end)
    end
    activeTargets = {}

    for i = 1, #activePeds do
        if DoesEntityExist(activePeds[i]) then
            if useTarget then
                pcall(function() exports.ox_target:removeLocalEntity(activePeds[i]) end)
            end
            DeleteEntity(activePeds[i])
        end
    end
    activePeds = {}

    hideHint()

    -- Leaving the store is what drops the cart and undoes the fitting room.
    Shop.leave()
end

--- Alle categorieën die een winkel verkoopt. Een expliciete `shop.categories`
--- wint; anders de unie van de rekken (zodat een kledingwinkel álle kleding
--- verkoopt, maar de juwelier/maskerwinkel beperkt blijft tot hun eigen rekken).
--- nil = de hele catalogus.
---@param shop table
---@return table?
local function resolveCategories(shop)
    if shop.categories then return shop.categories end
    if shop.racks and next(shop.racks) then
        local seen, out = {}, {}
        for _, rack in pairs(shop.racks) do
            for _, cat in ipairs(rack.categories or {}) do
                if not seen[cat] then
                    seen[cat] = true
                    out[#out + 1] = cat
                end
            end
        end
        -- Rekken zonder `categories` leveren een lege lijst op. Die als filter
        -- doorgeven maakt de winkel leeg in plaats van compleet, dus dan liever
        -- nil (= hele catalogus).
        return out[1] and out or nil
    end
    return nil
end

---@param shop table
local function buildShop(shop)
    spawnPed(shop)

    -- Kassa-only: één interactiepunt bij de kassa opent de hele winkel (bladeren
    -- én afrekenen in de UI). Geen losse koop-target per kledingrek meer, en geen
    -- aparte "cart"-only kassamenu (dat deed raar). De winkel verkoopt precies wat
    -- hij in de rekken had staan (unie van de rek-categorieën).
    createInteraction(shop, {
        coord = shop.cashier or shop.coord,
        label = shop.name,
        categories = resolveCategories(shop),
        kind = 'shop',
    })

    if shop.wardrobe then
        createInteraction(shop, {
            coord = shop.wardrobe,
            label = 'Wardrobe',
            kind = 'wardrobe',
        })
    end
end

CreateThread(function()
    for _, shop in pairs(Config.Shop) do
        if Config.ShopSettings.blips and shop.blip then
            local blip = AddBlipForCoord(shop.coord.x, shop.coord.y, shop.coord.z)
            SetBlipSprite(blip, shop.blip.sprite or 73)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.ShopSettings.blipScale)
            SetBlipColour(blip, shop.blip.color or 1)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.name)
            EndTextCommandSetBlipName(blip)
        end

        local shopRef = shop

        lib.zones.sphere({
            coords = shop.coord,
            radius = Config.ShopSettings.zoneRadius,
            debug = Config.Debug,
            onEnter = function()
                clearShop()
                buildShop(shopRef)
            end,
            onExit = function()
                clearShop()
            end,
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearShop()
end)

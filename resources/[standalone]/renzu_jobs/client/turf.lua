---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - turf wars (client)

    Visuals:
      * a coloured area blip per owned territory, always on the map
      * during a war: a radius blip + a ground marker on the capture point
      * a HUD panel with the timer, the live scores and the contested state

    The old version drew an ox_lib debug sphere (that big purple ball) and ran a
    1ms loop. This version draws a flat capture marker only while you are within
    50 metres of it, and the HUD is driven by state bag updates.
]]

TurfClient = {}

--- turf id -> { area = blip, radius = blip }
local ownerBlips = {}

--- Active war visuals
local warBlips = { area = nil, radius = nil }
local warZone = nil
local capturePoint = nil
local inZone = false
local respawning = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Blips
-- ─────────────────────────────────────────────────────────────────────────────

---@param turfId string
---@param owner table?
local function drawOwnerBlip(turfId, owner)
    local turf = Config.Turfs[turfId]
    if not turf then return end

    -- Clean up the previous pair before drawing new ones.
    for _, blip in pairs(ownerBlips[turfId] or {}) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    ownerBlips[turfId] = nil

    if not owner then return end

    local colour = Config.TurfColors[owner.owner] or 0

    local radius = AddBlipForRadius(turf.zone.coord.x, turf.zone.coord.y, turf.zone.coord.z, turf.zone.radius + 0.0)
    SetBlipColour(radius, colour)
    SetBlipAlpha(radius, 70)

    local area = AddBlipForCoord(turf.zone.coord.x, turf.zone.coord.y, turf.zone.coord.z)
    SetBlipSprite(area, 437)
    SetBlipColour(area, colour)
    SetBlipScale(area, 0.8)
    SetBlipAsShortRange(area, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('%s - %s'):format(turf.label, owner.ownerLabel or owner.owner))
    EndTextCommandSetBlipName(area)

    ownerBlips[turfId] = { area = area, radius = radius }
end

local function clearWarVisuals()
    for key, blip in pairs(warBlips) do
        if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
        warBlips[key] = nil
    end

    if warZone then warZone:remove() warZone = nil end
    if capturePoint then capturePoint:remove() capturePoint = nil end

    inZone = false
    Nui.hud({ action = 'turf', show = false })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Respawn handling
-- ─────────────────────────────────────────────────────────────────────────────

--- Dying inside a war zone drags you out of the area instead of leaving you on
--- the floor in the middle of the fight. One check a second, and only while a
--- war is running and you are inside the zone.
CreateThread(function()
    while true do
        Wait(1000)

        if not inZone or not Config.TurfWar.respawn.enabled then
            goto continue
        end
        if not IsPedDeadOrDying(cache.ped, true) then
            goto continue
        end
        if respawning then
            goto continue
        end

        respawning = true

        local war = GlobalState.TurfWar
        local turf = war and Config.Turfs[war.turf]
        if not turf then
            respawning = false
            goto continue
        end

        Bridge.notify('warning', 'Turf War',
            ('You went down. You will be pulled out of the area in %d seconds.'):format(Config.TurfWar.respawn.delay))

        local waited = 0
        while waited < Config.TurfWar.respawn.delay and IsPedDeadOrDying(cache.ped, true) do
            Wait(1000)
            waited = waited + 1
        end

        if IsPedDeadOrDying(cache.ped, true) then
            local offset = Config.TurfWar.respawn.offset
            local target = vec3(turf.zone.coord.x - offset, turf.zone.coord.y + offset, turf.zone.coord.z + 50.0)

            local found, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z, true)
            SetEntityCoords(cache.ped, target.x, target.y, found and groundZ or turf.zone.coord.z, false, false, false, false)

            -- Let whatever ambulance script runs on this server do the revive.
            TriggerEvent('renzu_jobs:turfDown')
            Bridge.notify('inform', 'Turf War', 'You have been dragged out of the fight.')
        end

        respawning = false
        ::continue::
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- War lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

---@param war table state bag payload
local function startWarVisuals(war)
    clearWarVisuals()

    local turf = Config.Turfs[war.turf]
    if not turf then return end

    local settings = Config.TurfWar.activeBlip

    warBlips.radius = AddBlipForRadius(turf.zone.coord.x, turf.zone.coord.y, turf.zone.coord.z, turf.zone.radius + 0.0)
    SetBlipColour(warBlips.radius, settings.color)
    SetBlipAlpha(warBlips.radius, settings.alpha)

    warBlips.area = AddBlipForCoord(turf.capture.x, turf.capture.y, turf.capture.z)
    SetBlipSprite(warBlips.area, settings.sprite)
    SetBlipColour(warBlips.area, settings.color)
    SetBlipScale(warBlips.area, settings.scale)
    SetBlipFlashes(warBlips.area, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Turf War - %s'):format(turf.label))
    EndTextCommandSetBlipName(warBlips.area)

    -- The zone is only used to know whether the HUD should be visible. No debug
    -- rendering, so no giant sphere in the middle of the map.
    warZone = lib.zones.sphere({
        coords = turf.zone.coord,
        radius = turf.zone.radius,
        debug  = false,
        onEnter = function()
            inZone = true
            Bridge.notify('warning', 'Turf War', ('You entered the %s war zone.'):format(turf.label))
        end,
        onExit = function()
            inZone = false
            Nui.hud({ action = 'turf', show = false })
        end,
    })

    -- The capture marker is drawn only when you are close enough to see it.
    capturePoint = lib.points.new({
        coords   = turf.capture,
        distance = 50.0,
    })

    function capturePoint:nearby()
        local state = GlobalState.TurfWar
        if not state then return end

        local r, g, b = 90, 200, 120
        if state.contested then
            r, g, b = 235, 180, 40
        elseif state.leader and Bridge.job and state.leader ~= Bridge.job.name then
            r, g, b = 220, 70, 70
        end

        local radius = Config.TurfWar.captureRadius
        DrawMarker(1, self.coords.x, self.coords.y, self.coords.z - 1.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            radius * 2.0, radius * 2.0, 1.5,
            r, g, b, 90, false, false, 2, false, nil, nil, false)
    end
end

--- Push the HUD once a second while the player is inside the zone.
CreateThread(function()
    while true do
        local war = GlobalState.TurfWar

        if war and inZone then
            local scores = {}
            for job, points in pairs(war.scores or {}) do
                scores[#scores + 1] = {
                    job    = job,
                    label  = job,
                    points = points,
                    mine   = Bridge.job and Bridge.job.name == job,
                }
            end
            table.sort(scores, function(a, b) return a.points > b.points end)

            Nui.hud({
                action    = 'turf',
                show      = true,
                label     = war.label,
                remaining = math.max(0, war.endsAt - os.time()),
                contested = war.contested == true,
                scores    = scores,
            })
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Turf interaction points
-- ─────────────────────────────────────────────────────────────────────────────

--- Rebuild the vault/stash/garage/wardrobe points. They only appear for the gang
--- that actually owns the territory.
function TurfClient.buildPoints()
    Targets.clear('turf')

    local owners = GlobalState.TurfOwners or {}

    for turfId, turf in pairs(Config.Turfs) do
        local owner = owners[turfId]
        local mine = owner and Bridge.job and owner.owner == Bridge.job.name

        -- The capture point is always interactable during a war.
        Targets.register('turf', {
            id = ('renzu_turf_capture_%s'):format(turfId),
            coord = turf.capture,
            label = ('Turf: %s'):format(turf.label),
            icon = 'flag',
            ped = false,
            radius = Config.TurfWar.captureRadius,
            canInteract = function()
                local war = GlobalState.TurfWar
                return war and war.turf == turfId
            end,
            onSelect = function()
                local war = GlobalState.TurfWar
                if not war or war.turf ~= turfId then return end
                Bridge.notify('inform', 'Turf War',
                    war.contested and 'The point is contested. Clear the area to score.'
                                   or 'Hold this point to score for your gang.')
            end,
        })

        if not mine then goto continue end

        for key, point in pairs(turf.points or {}) do
            if point.type == 'vault' then
                Targets.register('turf', {
                    id = ('renzu_turf_vault_%s'):format(turfId),
                    coord = point.coord, label = point.label, icon = 'vault', ped = false,
                    onSelect = function() TurfClient.openVault(turfId) end,
                })
            elseif point.type == 'stash' then
                Targets.register('turf', {
                    id = ('renzu_turf_stash_%s'):format(turfId),
                    coord = point.coord, label = point.label, icon = 'box-archive', ped = false,
                    onSelect = function() TurfClient.openStash(turfId) end,
                })
            elseif point.type == 'wardrobe' then
                Targets.register('turf', {
                    id = ('renzu_turf_wardrobe_%s'):format(turfId),
                    coord = point.coord, label = point.label, icon = 'shirt', ped = false,
                    onSelect = function() TurfClient.openWardrobe(turfId) end,
                })
            elseif point.type == 'garage' then
                Targets.register('turf', {
                    id = ('renzu_turf_garage_%s'):format(turfId),
                    coord = point.coord, label = point.label, icon = 'warehouse', ped = false,
                    onSelect = function() TurfClient.openGarage(turfId, point) end,
                })
            end
        end

        ::continue::
        drawOwnerBlip(turfId, owner)
    end
end

---@param turfId string
function TurfClient.openVault(turfId)
    local completed = lib.progressCircle({
        duration = math.random(5000, 9000),
        label    = 'Opening the vault',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab' },
    })
    ClearPedTasks(cache.ped)

    if not completed then
        Bridge.notify('warning', 'Turf Vault', 'You stopped before getting it open.')
        return
    end

    lib.callback.await('renzu_jobs:turfVault', false, turfId)
end

---@param turfId string
function TurfClient.openStash(turfId)
    local stash = lib.callback.await('renzu_jobs:turfStash', false, turfId)
    if not stash then return end
    exports.ox_inventory:openInventory('stash', { id = stash.id })
end

---@param turfId string
function TurfClient.openWardrobe(turfId)
    if not lib.callback.await('renzu_jobs:turfAccess', false, turfId) then
        Bridge.notify('error', 'Turf', 'Your gang does not control this territory.')
        return
    end
    Wardrobe.open()
end

---@param turfId string
---@param point table
function TurfClient.openGarage(turfId, point)
    if not lib.callback.await('renzu_jobs:turfAccess', false, turfId) then
        Bridge.notify('error', 'Turf', 'Your gang does not control this territory.')
        return
    end

    local resource = Config.GarageResource
    if resource and GetResourceState(resource) == 'started' then
        TriggerEvent('renzu_garage:property', ('%s_turf'):format(turfId), point.coord, point.spawn)
        return
    end

    Bridge.notify('error', 'Turf Garage', ('The garage resource "%s" is not running.'):format(tostring(resource)))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- State bag handlers
-- ─────────────────────────────────────────────────────────────────────────────

AddStateBagChangeHandler('TurfWar', 'global', function(_, _, value)
    if value then
        startWarVisuals(value)
    else
        clearWarVisuals()
    end
end)

AddStateBagChangeHandler('TurfOwners', 'global', function()
    TurfClient.buildPoints()
end)

Bridge.onJobChange(function()
    TurfClient.buildPoints()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    clearWarVisuals()
    for _, blips in pairs(ownerBlips) do
        for _, blip in pairs(blips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
    end
end)

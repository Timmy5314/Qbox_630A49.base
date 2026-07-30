---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - interaction points

    Every job point is registered here. Points with `ped` get a clerk NPC that is
    spawned only while you are nearby (ox_lib points handles the distance check),
    with the ox_target option living on the NPC itself. Points without a ped get
    a plain ox_target sphere.

    Falls back to ox_lib textUI + [E] when Config.UseTarget is off.
]]

Targets = {}

--- group -> array of registered handles
local groups = {}

---@param group string
local function ensureGroup(group)
    groups[group] = groups[group] or {}
    return groups[group]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Peds
-- ─────────────────────────────────────────────────────────────────────────────

---@param settings table|boolean
---@return table? resolved ped settings
local function resolvePed(settings)
    if not Config.UsePeds or settings == false or settings == nil then return nil end

    local resolved = {}
    for key, value in pairs(Config.DefaultPed) do resolved[key] = value end
    if type(settings) == 'table' then
        for key, value in pairs(settings) do resolved[key] = value end
    end
    return resolved
end

---@param settings table
---@param coord vector3|vector4
---@return number? ped
local function spawnPed(settings, coord)
    local model = settings.model
    if not lib.requestModel(model, 10000) then
        lib.print.warn(('could not load ped model "%s"'):format(tostring(model)))
        return nil
    end

    local heading = settings.heading or (coord.w or 0.0)
    -- Peds are placed 1 unit below the interaction coord so they stand on the floor.
    local ped = CreatePed(0, model, coord.x, coord.y, coord.z - 1.0, heading, false, false)

    SetModelAsNoLongerNeeded(model)

    if settings.freeze then FreezeEntityPosition(ped, true) end
    if settings.invincible then SetEntityInvincible(ped, true) end
    if settings.ignore then
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        SetPedDiesWhenInjured(ped, false)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, false)
    end

    SetEntityAsMissionEntity(ped, true, true)

    if settings.scenario then
        TaskStartScenarioInPlace(ped, settings.scenario, 0, true)
    end

    return ped
end

---@param ped number?
local function removePed(ped)
    if not ped or not DoesEntityExist(ped) then return end
    exports.ox_target:removeLocalEntity(ped)
    DeleteEntity(ped)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Registration
-- ─────────────────────────────────────────────────────────────────────────────

--- Register an interaction point.
---@param group string 'job' | 'public' | 'turf'
---@param point { id: string, coord: vector3|vector4, label: string, icon: string?, radius: number?, ped: table|boolean|nil, onSelect: function, canInteract: function? }
function Targets.register(group, point)
    local handles = ensureGroup(group)
    local pedSettings = resolvePed(point.ped)

    local targetOptions = {
        {
            name        = point.id,
            label       = point.label,
            icon        = ('fas fa-%s'):format(point.icon or 'circle'),
            distance    = point.radius or Config.InteractDistance,
            onSelect    = point.onSelect,
            canInteract = point.canInteract,
        },
    }

    -- ── Ped point ────────────────────────────────────────────────────────────
    if pedSettings then
        local ped
        local handle = lib.points.new({
            coords   = vec3(point.coord.x, point.coord.y, point.coord.z),
            distance = Config.PedRenderDistance,
        })

        function handle:onEnter()
            if ped then return end
            ped = spawnPed(pedSettings, point.coord)
            if not ped then return end

            if Config.UseTarget then
                exports.ox_target:addLocalEntity(ped, targetOptions)
            end
        end

        function handle:onExit()
            removePed(ped)
            ped = nil
        end

        -- Non-target servers still need a prompt, so drive it from the point.
        if not Config.UseTarget then
            local shown = false
            function handle:nearby()
                local close = self.currentDistance < (point.radius or Config.InteractDistance)
                if close and not shown then
                    shown = true
                    lib.showTextUI(('[E] %s'):format(point.label), { position = 'left-center' })
                elseif not close and shown then
                    shown = false
                    lib.hideTextUI()
                end
                if close and IsControlJustReleased(0, 38) then
                    lib.hideTextUI()
                    shown = false
                    point.onSelect()
                end
            end
        end

        handles[#handles + 1] = {
            kind = 'point',
            remove = function()
                if not Config.UseTarget then lib.hideTextUI() end
                handle:remove()
                removePed(ped)
                ped = nil
            end,
        }
        return
    end

    -- ── Plain zone ───────────────────────────────────────────────────────────
    if Config.UseTarget then
        local zoneId = exports.ox_target:addSphereZone({
            coords  = vec3(point.coord.x, point.coord.y, point.coord.z),
            radius  = point.radius or Config.InteractDistance,
            debug   = false,
            options = targetOptions,
        })

        handles[#handles + 1] = {
            kind = 'zone',
            remove = function() exports.ox_target:removeZone(zoneId) end,
        }
        return
    end

    local shown = false
    local handle = lib.points.new({
        coords   = vec3(point.coord.x, point.coord.y, point.coord.z),
        distance = (point.radius or Config.InteractDistance) + 4.0,
    })

    function handle:nearby()
        local close = self.currentDistance < (point.radius or Config.InteractDistance)
        if close and not shown then
            shown = true
            lib.showTextUI(('[E] %s'):format(point.label), { position = 'left-center' })
        elseif not close and shown then
            shown = false
            lib.hideTextUI()
        end
        if close and IsControlJustReleased(0, 38) then
            lib.hideTextUI()
            shown = false
            point.onSelect()
        end
    end

    function handle:onExit()
        if shown then
            shown = false
            lib.hideTextUI()
        end
    end

    handles[#handles + 1] = {
        kind = 'point',
        remove = function()
            if shown then lib.hideTextUI() end
            handle:remove()
        end,
    }
end

--- Remove every point in a group.
---@param group string
function Targets.clear(group)
    local handles = groups[group]
    if not handles then return end

    for i = 1, #handles do
        local ok, err = pcall(handles[i].remove)
        if not ok then lib.print.error(('failed to remove target: %s'):format(err)) end
    end
    groups[group] = {}
end

function Targets.clearAll()
    for group in pairs(groups) do Targets.clear(group) end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Building the job points
-- ─────────────────────────────────────────────────────────────────────────────

--- Points that only exist for the job you currently hold.
function Targets.buildJobPoints()
    Targets.clear('job')

    local job = Bridge.job
    if not job then return end

    local jobConfig = Config.Jobs[job.name]
    if not jobConfig then return end

    local function gradeCheck(feature)
        return function() return Bridge.canUse(feature) end
    end

    -- Boss office
    if jobConfig.bossmenu then
        local feature = jobConfig.bossmenu
        Targets.register('job', {
            id = 'renzu_boss', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() Boss.open() end,
        })
    end

    -- Storage
    for key, feature in pairs(jobConfig.stashes or {}) do
        Targets.register('job', {
            id = 'renzu_stash_' .. key, coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() JobStash.open(key) end,
        })
    end

    -- Armory
    if jobConfig.armory then
        local feature = jobConfig.armory
        Targets.register('job', {
            id = 'renzu_armory', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() ArmoryUI.open() end,
        })
    end

    -- Wardrobe
    if jobConfig.wardrobe then
        local feature = jobConfig.wardrobe
        Targets.register('job', {
            id = 'renzu_wardrobe', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() Wardrobe.open() end,
        })
    end

    -- Crafting
    if jobConfig.crafting then
        local feature = jobConfig.crafting
        Targets.register('job', {
            id = 'renzu_crafting', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() Crafting.open() end,
        })
    end

    -- Employee-only shops (public ones are registered for everybody below)
    for index, shop in ipairs(jobConfig.shops or {}) do
        if not shop.public then
            Targets.register('job', {
                id = 'renzu_shop_' .. index, coord = shop.coord, label = shop.label,
                icon = shop.icon, ped = shop.ped,
                canInteract = gradeCheck(shop),
                onSelect = function() Shop.open(job.name, index) end,
            })
        end
    end

    -- Vehicle shop
    if jobConfig.vehicleshop then
        local feature = jobConfig.vehicleshop
        Targets.register('job', {
            id = 'renzu_vehicleshop', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() VehicleShop.open() end,
        })
    end

    -- Garage: two behaviours from one point, driven by whether you are driving.
    if jobConfig.garage then
        local feature = jobConfig.garage
        Targets.register('job', {
            id = 'renzu_garage', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped, radius = 3.0,
            canInteract = gradeCheck(feature),
            onSelect = function() JobGarage.interact() end,
        })

        -- A second, larger point at the spawn so you can hand a vehicle back in
        -- without getting out first.
        if feature.spawn then
            Targets.register('job', {
                id = 'renzu_garage_store', coord = feature.spawn,
                label = ('Store vehicle - %s'):format(feature.label),
                icon = 'square-parking', ped = false, radius = 6.0,
                canInteract = function()
                    return Bridge.canUse(feature) and cache.vehicle ~= nil
                end,
                onSelect = function() JobGarage.store() end,
            })
        end
    end

    -- Duty clock
    if jobConfig.duty then
        local feature = jobConfig.duty
        Targets.register('job', {
            id = 'renzu_duty', coord = feature.coord, label = feature.label,
            icon = feature.icon, ped = feature.ped,
            canInteract = gradeCheck(feature),
            onSelect = function() Duty.toggle() end,
        })
    end
end

--- Points anybody can use, regardless of job. Built once on start.
function Targets.buildPublicPoints()
    Targets.clear('public')

    for jobName, jobConfig in pairs(Config.Jobs) do
        for key, feature in pairs(jobConfig.publicStashes or {}) do
            Targets.register('public', {
                id = ('renzu_pubstash_%s_%s'):format(jobName, key),
                coord = feature.coord, label = feature.label,
                icon = feature.icon, ped = feature.ped,
                onSelect = function() JobStash.openPublic(jobName, key) end,
            })
        end

        for index, shop in ipairs(jobConfig.shops or {}) do
            if shop.public then
                Targets.register('public', {
                    id = ('renzu_pubshop_%s_%d'):format(jobName, index),
                    coord = shop.coord, label = shop.label,
                    icon = shop.icon, ped = shop.ped,
                    onSelect = function() Shop.open(jobName, index) end,
                })
            end
        end
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Targets.clearAll()
end)

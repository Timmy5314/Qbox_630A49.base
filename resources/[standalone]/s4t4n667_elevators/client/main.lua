--[[
    Client: targets en de verplaatsing. De server beslist of een verdieping
    open is; hier wordt alleen gevraagd en uitgevoerd.

    Geen enkele permanente loop. Het origineel had een 3dtext-modus die per
    verdieping een while-true draaide; die is eruit, ox_target doet dit
    goedkoper en deze server draait toch overal op ox_target.
]]

lib.locale()

local config = lib.require 'config'

---Coordinaten mogen vec3 met los `heading` of vec4 zijn. Het origineel las
---altijd `.w` en kreeg nil bij vec3, waardoor SetEntityHeading faalde.
---@param floor table
---@return vector3 coords, number heading
local function resolve(floor)
    local c = floor.coords
    local heading = floor.heading or c.w or 0.0
    return vec3(c.x, c.y, c.z), heading + 0.0
end

---@return table<string, table[]>
local function buildElevators()
    local elevators = {}

    for name, floors in pairs(config.elevators) do
        elevators[name] = floors
    end

    if config.psHousing.enabled then
        for name, floors in pairs(config.psHousing.floors) do
            elevators[name] = floors
        end
    end

    return elevators
end

local elevators = buildElevators()

---@param elevatorName string
---@param floorIndex number
local function travel(elevatorName, floorIndex)
    local floors = elevators[elevatorName]
    local floor = floors and floors[floorIndex]
    if not floor then return end

    local allowed, reason = lib.callback.await('s4t4n667_elevators:useFloor', false, elevatorName, floorIndex)
    if not allowed then
        return lib.notify({ description = reason or locale('no_access'), type = 'error' })
    end

    if config.settings.animation ~= '' then
        ExecuteCommand(('e %s'):format(config.settings.animation))
        Wait(1500)
        ExecuteCommand('e c')
    end

    local coords, heading = resolve(floor)

    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z - 1.0, false, false, false, false)
    SetEntityHeading(cache.ped, heading)

    lib.progressBar({
        duration = config.settings.travelTime,
        label = locale('travelling'),
        useWhileDead = false,
        canCancel = false,
    })

    DoScreenFadeIn(500)

    lib.notify({
        description = locale('arrived', floor.floorTitle),
        type = 'success',
    })
end

---@param elevatorName string
---@param currentIndex number
local function openPanel(elevatorName, currentIndex)
    local floors = elevators[elevatorName]
    if not floors then return end

    local options = {}

    for index = 1, #floors do
        local floor = floors[index]
        options[#options + 1] = {
            title = floor.floorTitle,
            description = floor.label,
            icon = floor.icon or 'fa-solid fa-elevator',
            disabled = index == currentIndex,
            onSelect = function() travel(elevatorName, index) end,
        }
    end

    lib.registerContext({
        id = 'elevator_panel',
        title = elevatorName,
        options = options,
        position = 'top-right',
    })

    lib.showContext('elevator_panel')
end

CreateThread(function()
    for elevatorName, floors in pairs(elevators) do
        for index = 1, #floors do
            local coords, heading = resolve(floors[index])

            exports.ox_target:addBoxZone({
                name = ('elevator_%s_%d'):format(elevatorName, index),
                coords = coords,
                size = vec3(2.0, 2.0, 2.5),
                rotation = heading,
                debug = config.debug,
                options = {
                    {
                        label = locale('call_elevator'),
                        icon = config.settings.targetIcon,
                        distance = config.settings.targetDistance,
                        onSelect = function()
                            openPanel(elevatorName, index)
                        end,
                    },
                },
            })
        end
    end
end)

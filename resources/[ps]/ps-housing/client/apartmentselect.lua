--[[
    Apartment selection for brand new characters.

    This replaces the old "edit qbx_core / qbx_properties / qbx_spawn" instructions:
    qbx_core fires `apartments:client:setupSpawnUI` when a character is created with
    config.characters.startingApartment = true, and nothing in the core handles it.
    ps-housing picks it up here, so no core files have to be touched.

    Set Config.UseOwnApartmentSelect = false if another resource already does this.
]]

if not Config.UseOwnApartmentSelect then return end

local isSelecting = false
local showMenu -- forward declaration, "Back" reopens the menu

---Config.Apartments is a hash map, sort it so the menu order is stable
---@return {key: string, data: table}[]
local function getSortedApartments()
    local list = {}

    for key, data in pairs(Config.Apartments) do
        list[#list + 1] = { key = key, data = data }
    end

    table.sort(list, function(a, b)
        return (a.data.label or a.key) < (b.data.label or b.key)
    end)

    return list
end

---@param key string
---@return boolean confirmed
local function confirmApartment(key)
    local apartment = Config.Apartments[key]
    if not apartment then return false end

    return lib.alertDialog({
        header = 'Apartment Selection',
        content = ('Are you sure you want to live at **%s**?'):format(apartment.label),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Move in',
            cancel = 'Back'
        }
    }) == 'confirm'
end

---@param key string
local function moveIn(key)
    local door = Config.Apartments[key].door

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    FreezeEntityPosition(cache.ped, false)
    SetEntityCoords(cache.ped, door.x, door.y, door.z - 0.9, false, false, false, false)
    SetEntityHeading(cache.ped, door.h or 0.0)
    SetEntityVisible(cache.ped, true, false)

    -- The core expects the apartment resource to announce the player is in the world.
    -- This also makes ps-housing build its property list, which the shell needs.
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    if not WaitForProperties() then
        lib.print.error('Properties never finished loading, aborting apartment selection.')
        DoScreenFadeIn(500)
        return
    end

    if not lib.callback.await('ps-housing:cb:createApartment', false, key) then
        Framework.Notify('Something went wrong creating your apartment.', 'error')
    end

    Wait(500) -- let the shell spawn and the ped settle before showing the world again
    DoScreenFadeIn(500)
end

function OpenApartmentSelect()
    if isSelecting then return end
    isSelecting = true

    local apartments = getSortedApartments()
    local options = {}

    for i = 1, #apartments do
        local key, data = apartments[i].key, apartments[i].data

        options[#options + 1] = {
            title = data.label or key,
            description = data.description or 'Your new home in Los Santos.',
            image = data.imgs and data.imgs[1] and data.imgs[1].url,
            icon = 'building',
            arrow = true,
            onSelect = function()
                if not confirmApartment(key) then
                    showMenu()
                    return
                end

                moveIn(key)
                isSelecting = false
            end
        }
    end

    lib.registerContext({
        id = 'ps_housing_apartment_select',
        title = 'Choose your apartment',
        canClose = false,
        options = options
    })

    showMenu()
end

showMenu = function()
    lib.showContext('ps_housing_apartment_select')
end

-- Qbox: fired by qbx_core after character creation when startingApartment is enabled.
-- qbx_apartments fires the same event for existing characters, so check first.
RegisterNetEvent('apartments:client:setupSpawnUI', function()
    if not Config.StartingApartment then return end

    if not lib.callback.await('ps-housing:cb:needsStartingApartment', false) then
        Debug('Character already owns an apartment, skipping apartment select')
        return
    end

    OpenApartmentSelect()
end)

-- Fallback for setups where the core spawns the player without asking (qbx_spawn missing,
-- external character resources, ...). Only opens when the character owns no apartment yet.
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if not Config.StartingApartment or isSelecting then return end

    CreateThread(function()
        Wait(2000)
        if isSelecting then return end

        if lib.callback.await('ps-housing:cb:needsStartingApartment', false) then
            OpenApartmentSelect()
        end
    end)
end)

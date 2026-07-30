---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - NUI manager

    Single place that owns focus. Views never call SetNuiFocus themselves, which
    is what caused the stuck-cursor bugs in 1.x, and closing never reloads the
    page - it just hides the view and drops focus.
]]

Nui = {}

local currentView = nil
local onCloseCallbacks = {}

---@return boolean
function Nui.isOpen()
    return currentView ~= nil
end

---@return string?
function Nui.view()
    return currentView
end

--- Open a view. `data` is passed straight to the UI.
---@param view string
---@param data table
function Nui.open(view, data)
    if currentView then Nui.close(true) end

    currentView = view

    SendNUIMessage({
        action = 'open',
        view   = view,
        data   = data,
        theme  = {
            logo  = Config.Logo,
            items = Config.ItemImageUrl,
            fallback = Config.FallbackImage,
        },
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
end

--- Push fresh data into the view that is already open.
---@param view string
---@param data table
function Nui.update(view, data)
    if currentView ~= view then return end
    SendNUIMessage({ action = 'update', view = view, data = data })
end

--- Send a HUD message that does not take focus (turf timer, etc).
---@param payload table
function Nui.hud(payload)
    SendNUIMessage(payload)
end

---@param silent boolean? true when we are replacing one view with another
function Nui.close(silent)
    if not currentView then
        if not silent then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
        return
    end

    local closed = currentView
    currentView = nil

    SendNUIMessage({ action = 'close' })

    if not silent then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    local callback = onCloseCallbacks[closed]
    if callback then pcall(callback) end
end

--- Run something every time the given view closes. Registered once at load, so
--- the handler must stay in place rather than being consumed on first use.
---@param view string
---@param fn function
function Nui.onClose(view, fn)
    onCloseCallbacks[view] = fn
end

-- The UI asks to be closed (escape key or the X button).
RegisterNUICallback('close', function(_, cb)
    Nui.close()
    cb(true)
end)

--- Safety net: if the resource stops while a menu is open, give the mouse back.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

--- Dying with a menu open would leave the cursor stuck over the death screen.
--- Only polls while something is actually open.
CreateThread(function()
    while true do
        if currentView then
            if IsPedDeadOrDying(cache.ped, true) then Nui.close() end
            Wait(500)
        else
            Wait(2000)
        end
    end
end)

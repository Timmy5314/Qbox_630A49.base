--[[
    Server houdt de drie statussen bij en is de enige die ze mag wijzigen.
    De client vraagt een handeling aan; hier wordt bepaald of dat mag.
]]

local config = require 'shared.config'

local STATUSES = { 'hygiene', 'bladder', 'bowel' }

---@param msg string
local function dbg(msg)
    if config.debug then lib.print.info(msg) end
end

---@param value any
---@param fallback number
---@return number
local function clamp(value, fallback)
    value = tonumber(value)
    if not value then return fallback end
    if value < 0 then return 0 end
    if value > 100 then return 100 end
    return value
end

---Leest een status uit de metadata; vult hem aan als het character hem nog niet
---heeft (bestaande characters van vóór deze resource).
---@param player table
---@param status string
---@return number
local function get(player, status)
    local key = config.keys[status]
    local value = player.PlayerData.metadata[key]

    if value == nil then
        value = config.defaults[status]
        player.Functions.SetMetaData(key, value)
    end

    return clamp(value, config.defaults[status])
end

---@param src number
---@param status string
---@param value number
local function set(src, status, value)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    value = clamp(value, config.defaults[status])
    player.Functions.SetMetaData(config.keys[status], value)

    TriggerClientEvent('los_hygiene:update', src, {
        hygiene = get(player, 'hygiene'),
        bladder = get(player, 'bladder'),
        bowel = get(player, 'bowel'),
    })
end

---@param src number
---@param status string
---@param delta number
local function add(src, status, delta)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    set(src, status, get(player, status) + delta)
end

-- =========================================================================
--  Exports
-- =========================================================================

exports('GetStatuses', function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    return {
        hygiene = get(player, 'hygiene'),
        bladder = get(player, 'bladder'),
        bowel = get(player, 'bowel'),
    }
end)

exports('AddStatus', function(src, status, delta)
    if not config.keys[status] then return false end
    add(src, status, tonumber(delta) or 0)
    return true
end)

-- =========================================================================
--  Verval
-- =========================================================================

--- Gespreid over de spelers, zodat een volle server niet in één tick alle
--- metadata tegelijk wegschrijft. Zelfde patroon als qbx_core's loops.lua.
CreateThread(function()
    local interval = config.tickMinutes * 60000

    while true do
        Wait(interval)

        local players = exports.qbx_core:GetQBPlayers()
        local handled = 0

        for _, player in pairs(players) do
            local src = player.PlayerData.source

            if Player(src).state.isLoggedIn then
                for i = 1, #STATUSES do
                    local status = STATUSES[i]
                    add(src, status, config.rates[status])
                end
            end

            handled = handled + 1
            if handled % 10 == 0 then Wait(0) end
        end
    end
end)

-- =========================================================================
--  Handelingen
-- =========================================================================

---De client meldt dat hij klaar is met een handeling. De duur en de animatie
---zijn zijn zaak; wat de handeling met de statussen doet is die van de server.
lib.callback.register('los_hygiene:finishAction', function(src, action)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    if action == 'shower' then
        set(src, 'hygiene', config.actions.shower.hygiene)
    elseif action == 'washHands' then
        add(src, 'hygiene', config.actions.washHands.hygiene)
    elseif action == 'pee' then
        set(src, 'bladder', 0)
    elseif action == 'poo' then
        set(src, 'bowel', 0)
        -- Poepen leegt ook de blaas; dat scheelt een tweede handeling.
        set(src, 'bladder', 0)
    else
        return false
    end

    dbg(('%s deed %s'):format(src, action))
    return true
end)

--- Bij het inladen meteen de waarden doorgeven, anders staat de HUD op nul tot
--- de eerste tick - en die is vijf minuten later.
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if not src then return end

    SetTimeout(2000, function()
        if not exports.qbx_core:GetPlayer(src) then return end

        TriggerClientEvent('los_hygiene:update', src, {
            hygiene = get(player, 'hygiene'),
            bladder = get(player, 'bladder'),
            bowel = get(player, 'bowel'),
        })
    end)
end)

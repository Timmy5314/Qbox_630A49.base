--[[
    Qbox-versie. Renewed-Lib eruit, ESX en de losse ox-branch eruit.

    De dispatch-functie stond in het origineel volledig uitgecommentarieerd, dus
    een beroving werd nooit gemeld. Die is nu aangesloten op ps-dispatch.
]]

return {
    useSleeplessInteract = false,
    targetDistance = 20.0,
    reactionTime = 1000,
    robLength = 5,

    chancePedFlees = {
        min = 5,
        max = 25,
    },
    chancePedFights = {
        min = 5,
        max = 15,
    },
    chancePedIsArmedWhileFighting = {
        min = 80,
        max = 90,
    },
    pedWeapons = {
        'WEAPON_KNIFE',
        'WEAPON_BAT',
    },
    copsChance = {
        min = 80,
        max = 90,
    },
    allowedWeapons = {
        'WEAPON_KNIFE',
        'WEAPON_PISTOL',
    },

    -- Ped-types die met rust gelaten worden.
    -- https://docs.fivem.net/natives/?_0xFF059E1E4C01E63C
    blockedPedTypes = {
        6,  -- Cop
        20, -- Medic
        21, -- Fireman
        26, -- Mission
        27, -- Swat
        29, -- Army
    },

    ---@param groups string[]
    ---@return boolean
    isBlacklisted = function(groups)
        local ok, result = pcall(function()
            return exports.qbx_core:HasGroup(groups)
        end)

        return ok and result or false
    end,

    onPlayerLoad = function(cb)
        -- qbx_core vuurt deze naam zelf; het is niet qb-core.
        AddEventHandler('QBCore:Client:OnPlayerLoaded', cb)
    end,

    onPlayerUnload = function(cb)
        AddEventHandler('QBCore:Client:OnPlayerUnload', cb)
    end,

    ---@param coords vector3
    dispatch = function(coords)
        if GetResourceState('ps-dispatch') ~= 'started' then return end

        -- CustomAlert gebruikt `dispatchCode` als interne naam en `code` als de
        -- code die in beeld komt. Die twee niet verwisselen, anders toont de
        -- melding de standaardcode 10-80.
        -- ps-dispatch matcht op job TYPE, niet op jobnaam:
        -- client/main.lua doet lib.table.contains(data.jobs, PlayerData.job.type).
        -- police, bcso en sasp hebben allemaal type 'leo' in qbx_core.
        exports['ps-dispatch']:CustomAlert({
            coords = coords,
            jobs = { 'leo' },
            message = 'Street robbery',
            dispatchCode = 'streetrobbery',
            code = '10-31',
            icon = 'fas fa-user-injured',
            priority = 2,
            radius = 0,
            sprite = 58,
            color = 1,
            scale = 1.0,
            length = 3,
        })
    end,
}

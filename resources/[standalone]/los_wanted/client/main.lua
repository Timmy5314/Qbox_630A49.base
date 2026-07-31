local config = require 'shared.config'

local tier = 'off'
local passiveThread = false

-- Peds die al ontwapend zijn. Entity handles worden hergebruikt, dus deze tabel
-- wordt bij elke standwissel geleegd - anders slaat hij een nieuwe agent over
-- omdat een oude toevallig hetzelfde handle had.
local neutralised = {}

local COP_PED_TYPES = {
    [6] = true,  -- COP
    [27] = true, -- SWAT
    [29] = true, -- ARMY
}

---@param newTier string
local function applyTier(newTier)
    tier = newTier

    local maxLevel = config.maxWantedLevel[tier] or 0
    local enabled = maxLevel > 0

    SetMaxWantedLevel(maxLevel)

    for i = 1, #config.policeServices do
        EnableDispatchService(config.policeServices[i], enabled)
    end

    if not enabled then
        -- Sterren die je al had blijven anders staan terwijl er niemand meer
        -- op ze reageert.
        ClearPlayerWantedLevel(cache.playerId)
    end

    table.wipe(neutralised)

    if config.debug then
        lib.print.info(('stand %s -> max wanted %d, services %s')
            :format(tier, maxLevel, enabled and 'aan' or 'uit'))
    end
end

--- Ontwapent een politie-ped. Er bestaat geen instelling voor "spawnt wel maar
--- schiet niet", dus dit is wat er is: geen wapen, geen accuraatheid, en niet
--- meer geneigd het gevecht te zoeken.
---@param ped number
local function neutralise(ped)
    if neutralised[ped] or not DoesEntityExist(ped) or IsPedAPlayer(ped) then return end

    neutralised[ped] = true

    RemoveAllPedWeapons(ped, true)
    SetPedAccuracy(ped, 0)
    SetPedSeeingRange(ped, 30.0)
    SetPedCombatAttributes(ped, 5, false)  -- BF_AlwaysFight
    SetPedCombatAttributes(ped, 46, false) -- BF_CanFightArmedPedsWhenNotArmed
    SetPedCombatAttributes(ped, 1, true)   -- BF_CanUseCover
    SetPedCanSwitchWeapon(ped, false)
end

local function startPassiveThread()
    if passiveThread then return end
    passiveThread = true

    CreateThread(function()
        while tier == 'passive' and GetPlayerWantedLevel(cache.playerId) > 0 do
            local coords = GetEntityCoords(cache.ped)
            local pool = GetGamePool('CPed')

            for i = 1, #pool do
                local ped = pool[i]

                if COP_PED_TYPES[GetPedType(ped)]
                    and not neutralised[ped]
                    and #(coords - GetEntityCoords(ped)) < config.passive.radius then
                    neutralise(ped)
                end
            end

            Wait(config.passive.scanInterval)
        end

        passiveThread = false
    end)
end

--- Bewaakt de eigen wanted level. Loopt op 500 ms; GetPlayerWantedLevel is een
--- goedkope native en dit is de enige permanente lus in deze resource.
CreateThread(function()
    local reported = 0

    while true do
        local level = GetPlayerWantedLevel(cache.playerId)

        if level > 0 then
            if tier == 'passive' then
                startPassiveThread()
            end

            -- Alleen bij oplopen melden. Zakt het niveau en klimt het weer, dan
            -- mag er opnieuw een melding uit - de cooldown zit server-side.
            if level > reported and level >= config.dispatch.minLevel then
                TriggerServerEvent('los_wanted:report', level)
            end

            reported = level
        elseif reported ~= 0 then
            reported = 0
        end

        -- In de stand `off` bestaan er geen sterren en heeft snel kijken geen
        -- zin. Ook zonder sterren mag het rustiger; de melding gaat pas bij drie
        -- sterren uit en zo snel klim je niet.
        Wait(level > 0 and 500 or (tier == 'off' and 5000 or 2000))
    end
end)

RegisterNetEvent('los_wanted:sendAlert', function(level)
    exports['ps-dispatch']:CustomAlert({
        coords = GetEntityCoords(cache.ped),
        message = locale('wanted_alert', level),
        dispatchCode = 'wanted',
        code = '10-99',
        icon = 'fas fa-triangle-exclamation',
        priority = 1,
        radius = 0,
        sprite = 60,
        color = 1,
        scale = 1.0,
        length = 3,
        jobs = { 'leo' },
    })
end)

--- GlobalState is al gevuld voordat deze resource start, dus eerst uitlezen en
--- daarna pas op wijzigingen wachten.
AddStateBagChangeHandler('losWantedTier', 'global', function(_, _, value)
    if type(value) == 'string' then
        applyTier(value)
    end
end)

CreateThread(function()
    -- qbx_disableservices zet in zijn eigen CreateThread SetMaxWantedLevel(0) en
    -- alle services uit. Die draait bij het opstarten van de client. Wachten
    -- zodat wij daarna komen en niet andersom.
    Wait(3000)
    applyTier(GlobalState.losWantedTier or 'off')
end)

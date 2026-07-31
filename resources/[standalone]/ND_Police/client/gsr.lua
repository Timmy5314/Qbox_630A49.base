local timeEnteredWater = 0

local function checkGsr(state)
    local shot, lastShot = state.shot, state.lastShot
    if not shot or not lastShot then return end

    local time = GetCloudTimeAsInt()

    -- Zolang je niet in het water bent loopt de teller mee, dus telt alleen
    -- aaneengesloten tijd IN het water. Dat deed de originele versie ook, maar
    -- die zette `inWater = true` in de tak "niet in het water", waardoor het
    -- leek alsof de wasbeurt altijd doorliep.
    if not IsEntityInWater(cache.ped) then
        timeEnteredWater = time
    elseif time-timeEnteredWater > (Config.clearGSRinWater*60) then
        local ped = cache.ped
        ClearPedBloodDamage(ped)
        ClearPedEnvDirt(ped)
        ResetPedVisibleDamage(ped)
        lib.notify({
            type = 'inform',
            description = locale("gsr_washed_off")
        })
        return state:set('shot', false, true)
    end

    if time-lastShot > (Config.clearGSR*60) then
        lib.notify({
            type = 'inform',
            description = locale("gsr_worn_off")
        })
        state:set('shot', false, true)
    end
end

CreateThread(function()
	while true do
        Wait(1000)
        local state = Player(cache.serverId).state
        checkGsr(state)
    end
end)

exports.ox_target:addGlobalPlayer({
    {
        icon = 'fa-solid fa-gun',
        label = locale("gsr_test"),
        groups = Config.policeGroups,
	    distance = 1.5,
        onSelect = function(data)
            TriggerServerEvent('ND_Police:gsrTest', GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity)))
        end
    }
})

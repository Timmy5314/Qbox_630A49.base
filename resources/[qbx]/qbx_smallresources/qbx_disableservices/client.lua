local config = lib.load('qbx_disableservices.config')

-- los_wanted beheert de politie-dispatchservices en SetMaxWantedLevel: die
-- schakelen mee met het aantal agenten on duty. Zonder deze uitzondering zetten
-- twee resources dezelfde natives en wint degene die toevallig als laatste
-- draait - precies het soort conflict dat je pas op een draaiende server merkt.
--
-- De rest (brandweer, ambulance, gangs, leger, bikers) blijft hier.
local policeServices = {
    [1] = true,  -- PoliceAutomobile
    [2] = true,  -- PoliceHelicopter
    [4] = true,  -- SwatAutomobile
    [6] = true,  -- PoliceRiders
    [7] = true,  -- PoliceVehicleRequest
    [8] = true,  -- PoliceRoadBlock
    [9] = true,  -- PoliceAutomobileWaitPulledOver
    [10] = true, -- PoliceAutomobileWaitCruising
    [12] = true, -- SwatHelicopter
    [13] = true, -- PoliceBoat
}

CreateThread(function()
    local wantedHandled = GetResourceState('los_wanted'):find('start') ~= nil

    if not wantedHandled then
        SetMaxWantedLevel(config.maxWantedLevel)
    end

    for key, value in ipairs(config.enabledServices) do
        if not (wantedHandled and policeServices[key]) then
            EnableDispatchService(key, value)
        end
    end
end)

-- lib.versionCheck verwijderd: dat doet bij elke start een HTTP-call naar
-- GitHub. Niet nodig op een productieserver.
lib.locale()
local config = lib.require('config')

GlobalState.stevo_chopshop_cooldown = false

---@param source number
local function playerCheating(source)
    local identifier = Bridge.Server.GetPlayerIdentifier(source)
    local name = GetPlayerName(source)
    local warningMessage = (locale("cheater_warning")):format(name, identifier)
    lib.print.info(warningMessage)

    if not config.dropCheaters then return end

    return DropPlayer(source, 'Exploiting stevo_chopshop') 
end

---@param source number
---@param name string
local function giveRewards(source, name)
    local rewardTable = config.rewards[name]
    if not rewardTable then return end

    for _, reward in pairs(rewardTable) do
        local amount = reward.amount

        -- Bereik in plaats van een vast aantal, zodat niet elke deur exact
        -- hetzelfde oplevert.
        if reward.min and reward.max then
            amount = math.random(reward.min, reward.max)
        end

        Bridge.Server.AddItem(source, reward.item, amount)
    end
end

local function cooldown()
    CreateThread(function()
        if config.globalCooldown then 
            GlobalState.stevo_chopshop_cooldown = true 
            SetTimeout(config.globalCooldown*60000, function()
                GlobalState.stevo_chopshop_cooldown = false
            end)
        end
    end)
end

---@param source number
---@param _vehicle integer
lib.callback.register('stevo_chopshop:chopPart', function(source, data, _vehicle, doors)
    local vehicle = NetworkGetEntityFromNetworkId(_vehicle)

    if not DoesEntityExist(vehicle) then 
        return playerCheating(source)
    end 

    if not Entity(vehicle).state.currentlyChopping then 
        return playerCheating(source)
    end 
    
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local insideChopshop = false

    for i, chopshop in pairs(config.chopShops) do
        local dist = #(chopshop.securityCoords - playerCoords)
        if dist < 50 then 
            insideChopshop = true 
            break
        end
    end
    
    if not insideChopshop then 
        return playerCheating(source)
    end

    local choppingStage = Entity(vehicle).state.choppingStage

    -- 'name' bepaalt welke reward-tier je krijgt (config.rewards[name]) en
    -- kwam voorheen rechtstreeks van de client (data.name), zonder controle
    -- tegen de echte choppingStage. Iedereen kon dus 'stevo_chopshop:11'
    -- (chassis, de duurste tier) op elk moment doorsturen en die 9-11 keer
    -- per auto claimen i.p.v. de bedoelde spreiding over tiers - 3-5x de
    -- bedoelde opbrengst. 'name' volgt nu altijd de echte server-state.
    local name = 'stevo_chopshop:' .. tostring(choppingStage)

    if Entity(vehicle).state.choppingStage == 11 then
        --[[
            Laatste onderdeel: de auto verdwijnt. Als dit een voertuig van een
            speler was, is dat het moment om de verzekering in te lichten.

            Kenteken UITLEZEN VOOR de DeleteEntity - daarna bestaat de entity
            niet meer en krijg je een lege string terug.

            los_insurance zoekt de eigenaar op, zet het voertuig terug in zijn
            garage en keert uit als er een lopende polis is. Was het een
            NPC-auto van straat, dan gebeurt er niets. Zie
            los_insurance/server/theft.lua.

            pcall omdat de chopshop niet stuk hoort te gaan aan een
            verzekeringsdetail, en de resource ook zonder los_insurance moet
            kunnen draaien.
        ]]
        local plate = GetVehicleNumberPlateText(vehicle)

        DeleteEntity(vehicle)
        giveRewards(source, name)

        if plate and plate ~= '' then
            pcall(function()
                TriggerEvent('los_insurance:server:vehicleChopped', plate)
            end)
        end

        return true, locale("notify."..name)
    end


    if doors == 3 and choppingStage == 3 then
        Entity(vehicle).state:set('choppingStage', 7, true)
        giveRewards(source, name)

        return true, locale("notify.stevo_chopshop:6")
    end

    if doors == 4 and choppingStage == 3 then
        Entity(vehicle).state:set('choppingStage', 6, true)
        giveRewards(source, name)

        return true, locale("notify.stevo_chopshop:5")
    end


    Entity(vehicle).state:set('choppingStage', choppingStage + 1, true)
    giveRewards(source, name)

    return true, locale("notify."..name)
end)

---@return boolean
lib.callback.register('stevo_chopshop:canChop', function()

    if GlobalState.stevo_chopshop_cooldown then return false end

    -- Was `config.policeRequirement`, een naam die niet bestaat. Daardoor was
    -- deze tak altijd waar en werd de politie-eis nooit toegepast.
    local required = tonumber(config.policeRequired) or 0

    if required <= 0 then cooldown() return true end

    if Bridge.Server.GetJobCount(config.policeJob) >= required then
        cooldown()
        return true
    end

    return false
end)




 
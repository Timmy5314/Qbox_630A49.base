if not Config.Drugs['cornerselling'] then return end
if not Config.Junkies or not Config.Junkies.enabled then return end

--[[
    Junkies.

    Dit is bewust GEEN aparte zombie-resource. md-drugs kan met cornerselling al
    het belangrijkste: elke speler verkoopt drugs aan wereld-peds via ox_target,
    met reputatietiers, prijstabel en politiekans. Dat draait op bestaande peds
    uit GetGamePool('CPed') - er wordt niets gespawnd.

    Wat ontbrak waren twee dingen:
      1. junkies die iets laten vallen als je ze aanvalt
      2. schichtig gedrag

    Die staan hier en in client/junkies.lua. Een tweede resource met eigen
    ped-spawns, hordes en bosses ernaast zou dezelfde rol dubbel doen en veel
    meer kosten.
]]

---@type table<number, number> netId -> timestamp waarop dit lijk weer loot geeft
local looted = {}

---@type table<number, number> source -> timestamp waarop de speler weer mag looten
local cooldowns = {}

local cfg = Config.Junkies

---Kiest een drop uit de gewogen lijst.
---@return {item: string, min: number, max: number}?
local function pickDrop()
    local total = 0
    for i = 1, #cfg.drops do total = total + (cfg.drops[i].weight or 1) end
    if total <= 0 then return end

    local roll = math.random() * total
    local acc = 0

    for i = 1, #cfg.drops do
        acc = acc + (cfg.drops[i].weight or 1)
        if roll <= acc then return cfg.drops[i] end
    end
end

RegisterNetEvent('md-drugs:server:lootJunkie', function(netId)
    local src = source

    if type(netId) ~= 'number' or netId <= 0 then return end

    local now = os.time()

    -- Rate limit per speler. Zonder dit kan een client dit event spammen op
    -- hetzelfde lijk voordat de netId-cooldown geschreven is.
    if (cooldowns[src] or 0) > now then return end
    cooldowns[src] = now + cfg.playerCooldown

    if (looted[netId] or 0) > now then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 1 then return end

    -- Alleen van een dode ped, en alleen als je er echt bij staat.
    if GetEntityHealth(entity) > 0 then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > cfg.lootDistance then return end

    looted[netId] = now + cfg.pedCooldown

    local drop = pickDrop()
    if not drop then return end

    local amount = math.random(drop.min, drop.max)
    if amount <= 0 then return end

    exports.ox_inventory:AddItem(src, drop.item, amount)
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

---Opruimen. Net ids worden hergebruikt, dus een verdwenen ped moet vergeten
---worden of zijn id blokkeert de volgende ped die hem erft.
CreateThread(function()
    while true do
        Wait(60000)

        local now = os.time()

        for netId, expiry in pairs(looted) do
            local entity = NetworkGetEntityFromNetworkId(netId)
            if expiry <= now or not entity or entity == 0 or not DoesEntityExist(entity) then
                looted[netId] = nil
            end
        end

        for src, expiry in pairs(cooldowns) do
            if expiry <= now then cooldowns[src] = nil end
        end
    end
end)

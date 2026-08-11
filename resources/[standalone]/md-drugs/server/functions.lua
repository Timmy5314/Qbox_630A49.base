local timeOutPlayers = {}
local playerRep = {}
local playerWarnings = {}
local trollExploiters = true

local function trollPlayer(src)
    if not trollExploiters then return end
    CreateThread(function()
        local playerPed = GetPlayerPed(src)
        SetEntityCoords(playerPed, -3432.36, -6000.42, -2.0, false, false, false, true)
        Wait(30000)
        SetEntityCoords(playerPed, -1392.98, -2599.29, 2419.18, false, false, false, true)
        Wait(40000)
        DropPlayer(src, 'You have been caught trying to exploit md-drugs, get rekted.')
    end)
end

RegisterCommand('testTroll', function(source, args, rawCommand)
    local src = source
    trollPlayer(src)
end, false)

function checkDistance(src, coords, dist, event)
    local pcoords = GetEntityCoords(GetPlayerPed(src))
    coords = vector3(coords.x, coords.y, coords.z)
    if #(pcoords - coords) > dist then
        Bridge.Prints.Warn(Bridge.Language.Locale('Catches.outOfRangeWarn', Bridge.Framework.GetPlayerIdentifier(src), event))
        playerWarnings[src] = (playerWarnings[src] or 0) + 1
        if playerWarnings[src] >= 5 then
            trollPlayer(src)
        end
        return false
    end
    return true
end

local function timeOutThread(src)
    src = tonumber(src)
    CreateThread(function()
        timeOutPlayers[src] = true
        Wait(3000)
        timeOutPlayers[src] = nil
    end)
end

---Mag deze speler deze verwerkingsstap uitvoeren?
---
---Plukken en oogsten staat open voor iedereen; alleen de stappen die in
---Config.GangProcessing.events staan zijn gang-gebonden. Een event dat daar
---niet in staat wordt altijd toegestaan.
---@param src number
---@param event string
---@return boolean
function canProcess(src, event)
    local gate = Config.GangProcessing
    if not gate or not gate.enabled then return true end

    local drug = gate.events[event]
    if not drug then return true end

    local allowed = gate.drugs[drug]
    if not allowed or #allowed == 0 then return true end

    local gang = exports.qbx_core:GetPlayer(src)?.PlayerData?.gang?.name
    if gang then
        for i = 1, #allowed do
            if allowed[i] == gang then return true end
        end
    end

    Bridge.Notify.SendNotify(src, Bridge.Language.Locale('Catches.notYourTurf') or
        'Je weet niet hoe je dit verwerkt. Dit is werk voor een andere organisatie.', 'error')

    return false
end

function timeOut(src, event)
    -- De gang-check hangt hier omdat timeOut het enige punt is dat elke
    -- verwerkingsstap als eerste aanroept en dat de eventnaam meekrijgt.
    -- true teruggeven breekt de handler af, precies wat we willen.
    if not canProcess(src, event) then return true end

    if timeOutPlayers[src] then
        Bridge.Prints.Warn(Bridge.Language.Locale('Catches.onCooldownWarn', Bridge.Framework.GetPlayerIdentifier(src), event))
        playerWarnings[src] = (playerWarnings[src] or 0) + 1
        if playerWarnings[src] >= 5 then
            trollPlayer(src)
        end
        return true
    end
    timeOutThread(src)
    return false
end

function craft(source, recipe)
    local need, have, oops = 0,0,{}
    for item, amount in pairs (recipe.take) do
        need = need + 1
        local count = Bridge.Inventory.GetItemCount(source, item)
        if count >= amount then
            have = have + 1
        else
            table.insert(oops, 'You Need ' .. amount .. ' X ' .. Bridge.Inventory.GetItemInfo(item).label)
        end
    end
    if have ~= need then
        for index, text in pairs (oops) do
            Bridge.Notify.SendNotify(source, text, 'error')
        end
        return false
    end
    for item, amount in pairs (recipe.take) do
        if not Bridge.Inventory.RemoveItem(source, item, amount) then
            return false
        end
    end
    for item, amount in pairs (recipe.give) do 
        Bridge.Inventory.AddItem(source, item, amount)
    end
    return true
end

local function handleFresh(source)
    local id = Bridge.Framework.GetPlayerIdentifier(source)
    local player = {
        coke = 0,
        lsd = 0,
        heroin = 0,
        dealerrep = 0,
        cornerselling = { 
            price = Config.Cornerselling.CornerSellLevel[1].price,
            rep = 0,
            label = Config.Cornerselling.CornerSellLevel[1].label,
            level = 1
        }
    }
    playerRep[id] = player
    local first, last = Bridge.Framework.GetPlayerName(source)
    MySQL.insert('INSERT INTO drugrep SET cid = ?, drugrep = ?, name = ?', {id, json.encode(player), first .. ' ' .. last})
end

local function loadRep(source)
    local id = Bridge.Framework.GetPlayerIdentifier(source)
    local hasRep = MySQL.query.await('SELECT * FROM drugrep WHERE cid = ?', {id})
    if hasRep and not hasRep[1] then
        handleFresh(source)
    end
    if hasRep and hasRep[1] then
        playerRep[id] = json.decode(hasRep[1].drugrep)
    end
end

function getRep(source, type)
    local id = Bridge.Framework.GetPlayerIdentifier(source)
    if not playerRep[id] then
        loadRep(source)
    end
    return playerRep[id][type]
end

function GetAllRep(source)
    local id = Bridge.Framework.GetPlayerIdentifier(source)
    if not playerRep[id] then
        loadRep(source)
    end
    return playerRep[id]
end

function AddRep(source, type, amount)
    if not Config.TierSystem then return false end
    if not amount then amount = 1 end
    local id = Bridge.Framework.GetPlayerIdentifier(source)
    if not playerRep[id] then
        loadRep(source)
    end
    if type == 'cornerselling' then
        local rep = playerRep[id].cornerselling
        local cornerData = Config.Cornerselling.CornerSellLevel[rep.level]
        -- Was Config.CornerSellLevel (bestaat niet) -> indexeren van nil crashte de
        -- hele uitbetaling zodra een cornerseller een level omhoog ging (na RemoveItem,
        -- vóór AddAccountBalance -> drugs kwijt, geen geld). Juiste pad + guard tegen
        -- het hoogste level (geen volgende entry).
        if cornerData and rep.rep + amount >= cornerData.maxrep then
            local nextLevel = Config.Cornerselling.CornerSellLevel[rep.level + 1]
            if nextLevel then
                rep.level = rep.level + 1
                rep.label = nextLevel.label
                rep.price = nextLevel.price
            end
        end
        rep.rep = rep.rep + amount
    else
        playerRep[id][type] = playerRep[id][type] + amount
    end
    MySQL.query.await('UPDATE drugrep SET drugrep = ? WHERE cid = ?', {json.encode(playerRep[id]), id})
end

Bridge.Callback.Register('md-drugs:server:GetCoppers', function(source, cb, args)
   return #Bridge.Framework.GetPlayersByJob('police')
end)

Bridge.Callback.Register('md-drugs:server:GetRep', function(source, cb, args)
    local rep = GetAllRep(source)
    return rep
end)
--TODO: fix versioncheck
Bridge.Version.VersionChecker('Mustachedom/md-drugs', false)
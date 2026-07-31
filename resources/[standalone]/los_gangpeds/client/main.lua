if not Config.enabled then return end

--[[
    Zet de relationship group van de speler op basis van zijn gang.

    Volledig client-side; er is geen serverkant nodig. De gang komt uit
    qbx_core's playerdata, die de client al bijhoudt.

    Er draait GEEN loop. Alles hangt aan de events die qbx_core al vuurt bij
    laden, gang-wissel en uitloggen.
]]

---@type table<string, number>
local groupHashes = {}

---@type number?
local currentGroup

---Zet de onderlinge relaties tussen alle ganggroepen goed. Eenmalig.
local function seedRelationships()
    for _, name in pairs(Config.groups) do
        groupHashes[name] = GetHashKey(name)
    end

    groupHashes[Config.defaultGroup] = GetHashKey(Config.defaultGroup)

    -- Rivalen haten elkaar. Vanilla doet dit al, maar niet elke groep-
    -- combinatie is standaard ingevuld en dat is precies wat je hier wilt.
    for _, a in pairs(Config.groups) do
        for _, b in pairs(Config.groups) do
            if a ~= b then
                SetRelationshipBetweenGroups(Config.rivalRelation, groupHashes[a], groupHashes[b])
            end
        end
    end

    if not Config.keepPoliceNeutral then return end

    -- Zonder dit schieten ambient gangleden op agenten zodra een speler in hun
    -- groep zit.
    for i = 1, #Config.policeGroups do
        local police = GetHashKey(Config.policeGroups[i])

        for _, gang in pairs(Config.groups) do
            SetRelationshipBetweenGroups(3, groupHashes[gang], police) -- neutral
            SetRelationshipBetweenGroups(3, police, groupHashes[gang])
        end
    end
end

---@param gangName string?
local function applyGang(gangName)
    local groupName = gangName and Config.groups[gangName] or Config.defaultGroup
    local hash = groupHashes[groupName] or GetHashKey(groupName)

    if hash == currentGroup then return end

    currentGroup = hash
    SetPedRelationshipGroupHash(cache.ped, hash)

    -- Eigen gang laat je met rust en verdedigt je.
    if gangName and Config.groups[gangName] then
        SetRelationshipBetweenGroups(Config.ownGangRelation, hash, hash)
    end

    if Config.debug then
        lib.print.info(('gangpeds: relationship group -> %s'):format(groupName))
    end
end

---@return string?
local function currentGangName()
    local data = exports.qbx_core:GetPlayerData()
    return data and data.gang and data.gang.name or nil
end

CreateThread(function()
    seedRelationships()

    -- Bij een resource-restart terwijl je al ingelogd bent.
    if LocalPlayer.state.isLoggedIn then
        applyGang(currentGangName())
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    applyGang(currentGangName())
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    applyGang(gang and gang.name or nil)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    applyGang(nil)
end)

--- De ped verandert bij respawn en bij een modelwissel; de groep gaat dan
--- verloren. Opnieuw zetten zodra dat gebeurt, zonder een eigen loop.
lib.onCache('ped', function()
    currentGroup = nil
    applyGang(currentGangName())
end)

--[[
    Controlecommando.

    De AMBIENT_GANG_*-namen zijn GTA-gamedata en niet uit de serverbestanden te
    verifieren. Staat er een naam verkeerd, dan komt de speler in een groep die
    niet bestaat: geen crash, maar ambient gangleden negeren hem gewoon. Dat is
    stil falen, en daar is dit commando voor.

    /gangped toont wat er is gezet en of het overeenkomt met wat er zou moeten
    staan. Klopt de regel `ped groep` niet met `verwacht`, dan is de groepsnaam
    in de config fout.
]]
RegisterCommand('gangped', function()
    local gang = currentGangName()
    local expectedName = gang and Config.groups[gang] or Config.defaultGroup
    local expected = GetHashKey(expectedName)
    local actual = GetPedRelationshipGroupHash(cache.ped)

    local lines = {
        ('gang: %s'):format(gang or 'geen'),
        ('verwacht: %s (%s)'):format(expectedName, expected),
        ('ped groep: %s'):format(actual),
        ('match: %s'):format(actual == expected and 'JA' or 'NEE'),
    }

    if gang and not Config.groups[gang] then
        lines[#lines + 1] = 'let op: deze gang staat niet in Config.groups'
    end

    lib.print.info(table.concat(lines, ' | '))

    lib.notify({
        title = 'Gang peds',
        description = table.concat(lines, '\n'),
        type = actual == expected and 'success' or 'error',
        duration = 10000,
    })
end, false)

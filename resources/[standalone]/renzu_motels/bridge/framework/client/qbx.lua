-- Qbox client framework bridge (renzu_motels)
-- Vervangt de oude esx.lua / qbcore.lua. Praat rechtstreeks met qbx_core.
local kvpname = GetCurrentServerEndpoint()..'_inshells'

-- Normaliseer de Qbox playerdata naar de vorm die de rest van de resource verwacht:
--   PlayerData.identifier -> citizenid
--   PlayerData.job.grade  -> grade.level (getal)
local function normalize(data)
    if not data then return end
    PlayerData = data
    PlayerData.identifier = data.citizenid
    if PlayerData.job and type(PlayerData.job.grade) == 'table' then
        PlayerData.job.grade = PlayerData.job.grade.level
    end
    return PlayerData
end

-- Directe uitlezing bij resource-start (speler is mogelijk al ingelogd)
normalize(exports.qbx_core:GetPlayerData())

local function restoreShellIfLoggedIn()
    local login = GetResourceKvpString(kvpname)
    if not login then return end
    local data = json.decode(login)
    LocalPlayer.state:set('inshell', true, true)
    LocalPlayer.state:set('lastloc', data.lastloc, false)
    DoScreenFadeOut(0)
    EnterShell(data, true)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1500)
    normalize(exports.qbx_core:GetPlayerData())
    restoreShellIfLoggedIn()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not PlayerData then PlayerData = {} end
    PlayerData.job = job
    if PlayerData.job and type(PlayerData.job.grade) == 'table' then
        PlayerData.job.grade = PlayerData.job.grade.level
    end
end)

-- Qbox vuurt deze bij elke playerdata-wijziging; beide spellingen registreren
-- zodat een hernoeming in qbx_core ons niet stil breekt.
local function onSetPlayerData(data)
    normalize(data or exports.qbx_core:GetPlayerData())
end
RegisterNetEvent('QBCore:Player:SetPlayerData', onSetPlayerData)
RegisterNetEvent('QBCore:Client:SetPlayerData', onSetPlayerData)

-- Inventaris-uitlezing via ox_inventory (motels draait altijd op ox_inventory).
GetInventoryItems = function(name)
    return exports.ox_inventory:Search('slots', name) or {}
end

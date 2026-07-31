--[[
    Qbox-only. De qb-core- en ESX-blokken zijn verwijderd.

    Let op: het qb-core-blok stond op
        GetResourceState("qb-core") == "started" and not qbx_core started
    Met qbx:enableBridge geeft die eerste check hier ook 'started' terug, dus de
    tweede voorwaarde was het enige dat dubbele handlers voorkwam. Nu is er nog
    maar een pad.
]]

Bridge.Client.PlayerData = {}

---@param job table?
local function setJob(job)
  Bridge.Client.PlayerData.job = job and job.name or nil
  LoadChopShops()
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
  -- Dit is qbx_core's eigen event; Qbox houdt de oude naam aan voor compat.
  setJob(exports.qbx_core:GetPlayerData().job)
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
  setJob(job)
end)

AddEventHandler('onResourceStart', function(resource)
  if resource ~= cache.resource then return end

  setJob(exports.qbx_core:GetPlayerData().job)
end)

function Bridge.Client.HideRadar(shouldHide)
  DisplayHud(shouldHide)
  DisplayRadar(shouldHide)
end

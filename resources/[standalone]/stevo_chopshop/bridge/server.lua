--[[
    Qbox-only bridge. De QBCore- en ESX-takken zijn verwijderd.

    Twee echte bugs uit het origineel zaten in AddItem:

        function Bridge.Server.AddItem(source, item, amount)
          local amount = 0                                   -- overschrijft de parameter
          ...
          return exports.ox_inventory:AddItem(source, item, count)  -- `count` bestaat niet

    De parameter werd geschaduwd door een lokale 0, en vervolgens werd een
    ongedefinieerde `count` doorgegeven. Elke chopshop-beloning kwam dus met nil
    binnen in plaats van het geconfigureerde aantal.
]]

local config = require('config')

---@param src integer
---@param msg string
---@param type "success" | "warning" | "error"
function Bridge.Server.Notify(src, title, msg, type)
  TriggerClientEvent("stevo_chopshops:client:notify", src, title, msg, type, 5000)
end

---@param model string|integer
---@param plate string
---@return integer|nil vehicleId
function Bridge.Server.SaveVehicleToGarage(src, model, plate)
  local props = json.encode({
    model = convertModelToHash(model),
    plate = plate
  })

  local player = Bridge.Server.GetPlayer(src)
  if not player then return end

  local playerData = player.PlayerData

  return MySQL.insert.await(
    "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate) VALUES(?, ?, ?, ?, ?, ?)",
    {playerData.license, playerData.citizenid, model, joaat(model), props, plate}
  )
end

---@param vehicle table
---@return string | number | false model
function Bridge.Server.GetModelColumn(vehicle)
  if not vehicle then return false end
  return vehicle.vehicle or tonumber(vehicle.hash) or false
end

--
-- Player Functions
--

---@param src integer
function Bridge.Server.GetPlayer(src)
  return exports.qbx_core:GetPlayer(src)
end

---@param src integer
function Bridge.Server.GetPlayerInfo(src)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return false end

  local charinfo = player.PlayerData.charinfo

  return {
    name = charinfo.firstname .. " " .. charinfo.lastname
  }
end

---@param identifier string
function Bridge.Server.GetPlayerInfoFromIdentifier(identifier)
  local player = MySQL.single.await("SELECT * FROM " .. Bridge.PlayersTable .. " WHERE " .. Bridge.PlayersTableId .. " = ?", {identifier})
  if not player then return false end

  local charinfo = json.decode(player.charinfo)
  if not charinfo then return false end

  return {
    name = charinfo.firstname .. " " .. charinfo.lastname
  }
end

---@param src integer
function Bridge.Server.GetPlayerIdentifier(src)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return false end

  return player.PlayerData.citizenid
end

---@param src integer
function Bridge.Server.GetPlayerName(src)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return false end

  local charinfo = player.PlayerData.charinfo

  return charinfo.firstname .. ' ' .. charinfo.lastname
end

---@param src integer
function Bridge.Server.GetPlayerRank(src)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return false end

  local grade = player.PlayerData.job.grade

  return grade.name, grade.level
end

---@param identifier string
---@return integer | false src
function Bridge.Server.GetPlayerFromIdentifier(identifier)
  local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
  if not player then return false end

  return player.PlayerData.source
end

---@param src integer
---@param type "cash" | "bank" | "black_money"
function Bridge.Server.GetPlayerBalance(src, type)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return 0 end

  return player.PlayerData.money[type] or 0
end

---@param source number
---@param item string
---@param amount number
---@return boolean
function Bridge.Server.AddItem(source, item, amount)
  return exports.ox_inventory:AddItem(source, item, amount or 1)
end

---Telt spelers met deze job die ON DUTY zijn.
---Het origineel liep alle spelers langs en keek alleen naar de jobnaam, dus een
---uitgeklokte agent telde ook mee.
---@param job string
---@return integer
function Bridge.Server.GetJobCount(job)
  local ok, count = pcall(function()
    return exports.qbx_core:GetDutyCountJob(job)
  end)

  return (ok and type(count) == 'number') and count or 0
end

---@param src integer
---@param amount number
---@param account "cash" | "bank" | "black_money"
function Bridge.Server.PlayerRemoveMoney(src, amount, account)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return end

  player.Functions.RemoveMoney(account or "bank", round(amount, 0))
end

---@param src integer
---@param amount number
---@param account "cash" | "bank" | "black_money"
function Bridge.Server.PlayerAddMoney(src, amount, account)
  local player = Bridge.Server.GetPlayer(src)
  if not player then return end

  player.Functions.AddMoney(account or "cash", round(amount, 0))
end

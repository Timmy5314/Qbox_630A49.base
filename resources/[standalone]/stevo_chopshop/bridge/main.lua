--[[
    Qbox-only. De QBCore- en ESX-detectie is verwijderd: die frameworks draaien
    niet op deze server en de if/elseif-ketens die eraan hingen zijn overal
    weggehaald.

    Let op bij de qb-core-tak die hier stond: qbx_core draait met
    qbx:enableBridge, waardoor GetResourceState("qb-core") ook 'started' kan
    teruggeven. De volgorde ving dat op, maar nu is de vraag niet meer relevant.
]]

local config = require('config')

Bridge = {
  Client = {},
  Server = {}
}

if GetResourceState("qbx_core") ~= "started" then
  error("stevo_chopshop vereist qbx_core.")
end

config.Framework = "Qbox"

Bridge.VehiclesTable = "player_vehicles"
Bridge.VehProps = "mods"
Bridge.PlayerId = "citizenid"
Bridge.PlayersTable = "players"
Bridge.PlayersTableId = "citizenid"

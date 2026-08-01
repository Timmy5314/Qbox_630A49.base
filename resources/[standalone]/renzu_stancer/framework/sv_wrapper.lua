-- Qbox server wrapper (renzu_stancer)
-- Vervangt de oude ESX/QBCORE-wrapper. Levert alleen wat server.lua nodig heeft:
--   Initialized()          - zet de globale RegisterUsableItem
--   RegisterUsableItem(...) - registreert een bruikbaar item via qbx_core
--   GetPlayerFromId(src)    - minimale wrapper met removeInventoryItem (ox_inventory)

function Initialized()
    RegisterUsableItem = function(item, cb)
        exports.qbx_core:CreateUseableItem(item, cb)
    end
end

function GetPlayerFromId(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    return {
        source = src,
        removeInventoryItem = function(item, count)
            exports.ox_inventory:RemoveItem(src, item, count or 1)
        end,
    }
end

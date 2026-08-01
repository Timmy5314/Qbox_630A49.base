-- Qbox server wrapper (renzu_turbo)
-- Vervangt de oude ESX/QBCORE-wrapper. Levert alleen wat server.lua nodig heeft:
--   Initialized()          - zet de globale RegisterUsableItem
--   RegisterUsableItem(...) - registreert een bruikbaar item via qbx_core
--   GetPlayerFromId(src)    - wrapper met .job, .getGroup(), removeInventoryItem
Using = {}

function Initialized()
    RegisterUsableItem = function(item, cb)
        exports.qbx_core:CreateUseableItem(item, cb)
    end
end

function GetPlayerFromId(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local pd = player.PlayerData
    return {
        source = src,
        job = pd.job,
        -- Alleen admins mogen het /changeturbo debug-commando gebruiken.
        getGroup = function()
            return IsPlayerAceAllowed(src, 'group.admin') and 'admin' or 'user'
        end,
        removeInventoryItem = function(item, count)
            exports.ox_inventory:RemoveItem(src, item, count or 1)
        end,
    }
end

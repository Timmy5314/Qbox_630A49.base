-- Qbox server framework bridge (renzu_motels)
-- Vervangt de oude esx.lua / qbcore.lua. Levert een xPlayer-achtige wrapper
-- rond exports.qbx_core zodat server/main.lua ongewijzigd kan blijven.

-- Qbox kent 'cash' en 'bank'. De resource geeft soms 'money' door als cash-alias.
local function accountType(t)
    if t == nil or t == 'money' then return 'cash' end
    return t
end

-- Bouw de wrapper met de exacte methodes die server/main.lua aanroept.
local function wrap(player)
    if not player then return end
    local pd = player.PlayerData

    return {
        source = pd.source,
        identifier = pd.citizenid,
        name = pd.charinfo and pd.charinfo.firstname or ('#'..tostring(pd.source)),

        getMoney = function()
            return pd.money['cash'] or 0
        end,

        getAccount = function(t)
            return { money = pd.money[accountType(t)] or 0 }
        end,

        addMoney = function(amount)
            return player.Functions.AddMoney('cash', tonumber(amount), 'renzu_motels')
        end,

        removeAccountMoney = function(t, amount)
            return player.Functions.RemoveMoney(accountType(t), tonumber(amount), 'renzu_motels')
        end,
    }
end

-- src kan een server-id (getal) of een citizenid (string) zijn.
GetPlayerFromId = function(src)
    if type(src) == 'string' then
        return wrap(exports.qbx_core:GetPlayerByCitizenId(src))
    end
    return wrap(exports.qbx_core:GetPlayer(src))
end

---Admin-review via ox_lib.
---
---False positives markeren is geen cosmetische functie: elke keer dat een admin
---een check als onterecht markeert, halveert het gewicht van die check. Zo zakt
---een check die op deze server structureel misgaat vanzelf naar irrelevant in
---plaats van dat hij spelers blijft kicken.

---@param source number
---@return boolean
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, Config.adminAce)
end

lib.callback.register('los_anticheat:getOverview', function(source)
    if not isAdmin(source) then return end

    local result = {}
    local players = GetPlayers()

    for i = 1, #players do
        local src = tonumber(players[i])
        local score = AC_GetScore(src)
        if score > 0 then
            result[#result + 1] = {
                source = src,
                name = GetPlayerName(src),
                score = score,
                flags = AC_GetFlags(src),
            }
        end
    end

    table.sort(result, function(a, b) return a.score > b.score end)
    return result
end)

lib.callback.register('los_anticheat:getHistory', function(source, limit)
    if not isAdmin(source) then return end

    local ok, rows = pcall(MySQL.query.await, [[
        SELECT name, check_name, points, detail, created_at
        FROM los_anticheat_flags
        ORDER BY id DESC
        LIMIT ?
    ]], { limit or 50 })

    return ok and rows or {}
end)

RegisterNetEvent('los_anticheat:markFalsePositive', function(check)
    local src = source
    if not isAdmin(src) then return end
    if type(check) ~= 'string' then return end

    AC_MarkFalsePositive(check)
    exports.qbx_core:Notify(src, locale('fp_marked', check, Config.weights[check] or 0))
end)

---Console- en in-game commando. Zonder argument: overzicht van actieve sessies.
RegisterCommand('acflags', function(source)
    if not isAdmin(source) then return end

    if source == 0 then
        local players = GetPlayers()
        print('--- los_anticheat: actieve scores ---')
        for i = 1, #players do
            local src = tonumber(players[i])
            local score = AC_GetScore(src)
            if score > 0 then
                print(('%-24s score %d'):format(GetPlayerName(src), score))
            end
        end
        return
    end

    TriggerClientEvent('los_anticheat:openMenu', source)
end, false)

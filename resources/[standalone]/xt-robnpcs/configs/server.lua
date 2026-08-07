--[[
    Qbox-versie. Het origineel draaide op Renewed-Lib; die resource staat niet
    op deze server. Alle groepschecks lopen nu via qbx_core.

    De loot is aangepast naar wat een willekeurige voorbijganger echt op zak
    heeft: wat kleingeld, soms een telefoon, vaker iets te eten of te drinken.
    Het origineel liet elke NPC een rolex dragen.
]]

return {
    payOut = {
        min = 15,
        max = 75,
    },
    payOutChance = {
        min = 70,
        max = 80,
    },
    chanceItemsFound = {
        min = 55,
        max = 70,
    },

    -- Gewogen door herhaling: eten en drinken komen vaak voor, een telefoon
    -- zelden. Geen wapens, geen sieraden, geen jackpots.
    lootableItems = {
        { item = 'water',    min = 1, max = 1 },
        { item = 'water',    min = 1, max = 1 },
        { item = 'cola',     min = 1, max = 1 },
        { item = 'cola',     min = 1, max = 1 },
        { item = 'sandwich', min = 1, max = 1 },
        { item = 'sandwich', min = 1, max = 1 },
        { item = 'burger',   min = 1, max = 1 },
        { item = 'donut',    min = 1, max = 1 },
        { item = 'coffee',   min = 1, max = 1 },
        { item = 'lighter',  min = 1, max = 1 },
        { item = 'phone',    min = 1, max = 1 },
    },

    robCooldown = 45,
    pedCooldown = 600,
    robDistance = 5.0,

    ---@param src number
    ---@param groups string[] job- en gangnamen
    ---@return boolean
    hasGroup = function(src, groups)
        -- qbx_core:HasGroup accepteert een lijst en kijkt naar job en gang.
        local ok, result = pcall(function()
            return exports.qbx_core:HasGroup(src, groups)
        end)

        return ok and result or false
    end,

    ---@param src number
    ---@param amount number
    -- Muggen is illegaal inkomen; hoorde net als chopshop/cayocrates/turfs
    -- black_money te zijn, niet schone cash (SERVER-OVERHAUL 6.7). Stond niet
    -- op de "al consistent"-lijst in BACKLOG - nooit gefixt.
    addCash = function(src, amount)
        return exports.ox_inventory:AddItem(src, 'black_money', amount)
    end,

    ---@param src number
    ---@param item string
    ---@param amount number
    addItem = function(src, item, amount)
        return exports.ox_inventory:AddItem(src, item, amount)
    end,
}

---Inventory- en ammo-autoriteit.
---
---WAT HIER WEL KAN
---ox_inventory doet alle mutaties al server-side; een client kan niet zomaar een
---item aanmaken. Wat een client wel kan is een legitiem server-event misbruiken
---(een shop-aankoop honderd keer per seconde, een craft zonder wachttijd). Deze
---module kijkt daarom naar het TEMPO en de PLAUSIBILITEIT van veranderingen, niet
---naar de mutatie zelf.
---
---WAT HIER NIET KAN
---Een sluitende "geen item ontstaat zonder server-side bron" garantie vergt dat
---elke resource zijn AddItem-aanroepen via een gateway laat lopen. Dat is een
---refactor van tientallen resources, niet iets wat deze module kan afdwingen.
---Zie AC_TrackGrant hieronder voor de opt-in variant.

---Items die per definitie verdacht zijn in spelershanden.
---@type table<string, boolean>
local restrictedItems = {
    ['weapon_railgun'] = true,
    ['weapon_minigun'] = true,
    ['weapon_rpg'] = true,
    ['weapon_grenadelauncher'] = true,
    ['weapon_hominglauncher'] = true,
    ['weapon_raypistol'] = true,
    ['weapon_rayminigun'] = true,
    ['weapon_raycarbine'] = true,
}

---@type table<number, {money: number, black: number, lastCheck: number}>
local wealth = {}

---@type table<number, table<string, number>> source -> item -> laatst bekende aantal
local grants = {}

-- =========================================================================
--  Geld: plotselinge sprongen
-- =========================================================================
-- Dit vervangt geen gateway. Het vangt het geval dat een script of exploit geld
-- toekent zonder plafond. Legitieme grote bedragen (huisverkoop, autoverkoop)
-- melden zich via AC_ExpectIncome.

---@type table<number, number> source -> timestamp tot wanneer een grote som verwacht wordt
local expectedIncome = {}

---Meldt aan dat een speler zo meteen legitiem een groot bedrag ontvangt.
---
---   exports.los_anticheat:ExpectIncome(source, 15)
---@param source number
---@param seconds number?
function AC_ExpectIncome(source, seconds)
    expectedIncome[source] = os.time() + (seconds or 15)
end

exports('ExpectIncome', AC_ExpectIncome)

---Maximale toename per controle-interval zonder melding.
local MAX_CASH_JUMP = 250000
local CHECK_INTERVAL = 10000

---@param source number
local function checkWealth(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local money = player.PlayerData.money
    if not money then return end

    local cash = (money.cash or 0) + (money.bank or 0)
    local black = money.black_money or 0

    local previous = wealth[source]
    wealth[source] = { money = cash, black = black, lastCheck = os.time() }

    if not previous then return end
    if (expectedIncome[source] or 0) >= os.time() then return end

    local cashGain = cash - previous.money
    if cashGain > MAX_CASH_JUMP then
        AC_Flag(source, 'moneyJump',
            ('cash+bank steeg met %d in %d s'):format(cashGain, CHECK_INTERVAL / 1000),
            { gain = cashGain, total = cash })
    end

    local blackGain = black - previous.black
    if blackGain > MAX_CASH_JUMP then
        AC_Flag(source, 'moneyJump',
            ('black_money steeg met %d in %d s'):format(blackGain, CHECK_INTERVAL / 1000),
            { gain = blackGain, total = black })
    end
end

-- =========================================================================
--  Items: verboden spullen en onverklaarde toename
-- =========================================================================

---@param source number
local function checkInventory(source)
    local ok, items = pcall(function()
        return exports.ox_inventory:GetInventoryItems(source)
    end)

    if not ok or type(items) ~= 'table' then return end

    local seen = {}
    local previous = grants[source] or {}

    for _, item in pairs(items) do
        local name = item.name and item.name:lower()
        if name then
            seen[name] = (seen[name] or 0) + (item.count or 0)

            if restrictedItems[name] then
                AC_Flag(source, 'restrictedItem',
                    ('bezit %s x%d'):format(name, item.count or 0),
                    { item = name, count = item.count })
            end
        end
    end

    grants[source] = seen

    -- Ammo die sneller stijgt dan een winkel kan leveren.
    for name, count in pairs(seen) do
        if name:sub(1, 5) == 'ammo-' then
            local gained = count - (previous[name] or 0)
            if gained > 2000 then
                AC_Flag(source, 'ammoSync',
                    ('%s steeg met %d in %d s'):format(name, gained, CHECK_INTERVAL / 1000),
                    { item = name, gained = gained })
            end
        end
    end
end

-- =========================================================================
--  Ammo-sync: geschoten zonder munitie te verliezen
-- =========================================================================
-- Wordt gevoed vanuit damage.lua bij elk geldig schot. Een speler die blijft
-- vuren terwijl zijn ammo-item niet daalt, heeft infinite ammo.

---@type table<number, {shots: number, ammo: number?, weapon: string?}>
local firing = {}

---Cache van wapen -> munitie-item. ox_inventory kent dit al via het veld
---`ammoname` in data/weapons.lua; die waarheid overschrijven we niet.
---@type table<string, string|false>
local ammoCache = {}

---@param weaponName string Uppercase, bijvoorbeeld WEAPON_PISTOL
---@return string? ammoName
local function ammoForWeapon(weaponName)
    local cached = ammoCache[weaponName]
    if cached ~= nil then
        return cached or nil
    end

    local ok, item = pcall(function()
        return exports.ox_inventory:Items(weaponName)
    end)

    local ammo = ok and type(item) == 'table' and item.ammoname or nil
    ammoCache[weaponName] = ammo or false

    return ammo
end

---Registreert een geldig schot. Aangeroepen vanuit damage.lua.
---@param source number
---@param weaponName string
function AC_RecordShot(source, weaponName)
    local entry = firing[source]

    -- Bij wisselen van wapen begint de telling opnieuw; de ammo-baseline van het
    -- vorige wapen zegt niets over het nieuwe.
    if not entry or entry.weapon ~= weaponName then
        firing[source] = { shots = 1, ammo = nil, weapon = weaponName }
        return
    end

    entry.shots = entry.shots + 1
end

---Drempel: zoveel schoten binnen een interval voordat we naar de munitie kijken.
---Ruim genomen omdat ox_inventory de ammo-teller met vertraging bijwerkt.
local SHOTS_BEFORE_CHECK = 30

---@param source number
local function checkAmmo(source)
    local entry = firing[source]
    if not entry or not entry.weapon then return end

    local ammoName = ammoForWeapon(entry.weapon)
    if not ammoName then
        -- Melee, throwables en wapens zonder munitie-item: niets te meten.
        firing[source] = nil
        return
    end

    local ok, count = pcall(function()
        return exports.ox_inventory:Search(source, 'count', ammoName)
    end)

    if not ok or type(count) ~= 'number' then return end

    -- Genoeg geschoten en de voorraad is niet gedaald: infinite ammo.
    if entry.ammo and entry.shots >= SHOTS_BEFORE_CHECK and count >= entry.ammo then
        AC_Flag(source, 'ammoSync',
            ('%d schoten met %s zonder %s te verbruiken (%d -> %d)')
                :format(entry.shots, entry.weapon, ammoName, entry.ammo, count),
            { weapon = entry.weapon, shots = entry.shots, before = entry.ammo, after = count })
    end

    entry.ammo = count
    entry.shots = 0
end

-- =========================================================================
--  Levenscyclus
-- =========================================================================

AddEventHandler('playerDropped', function()
    local src = source
    wealth[src] = nil
    grants[src] = nil
    firing[src] = nil
    expectedIncome[src] = nil
end)

CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)

        local players = GetPlayers()
        for i = 1, #players do
            local src = tonumber(players[i])
            checkWealth(src)
            checkInventory(src)
            checkAmmo(src)
        end
    end
end)

if not Config.Drugs['TravellingMerchant'] then return end

--[[
    De dealer stond op een vaste plek: `loc` werd een keer bij resource-start
    gekozen en veranderde daarna nooit meer. Hij verhuist nu op een interval.

    Spelers krijgen nooit coordinaten. Ze sms'en het black market-nummer in NPWD
    en krijgen een omschrijving van de buurt terug. De GetMerchant-callback
    blijft de coordinaten leveren, want de client heeft ze nodig om de ped te
    plaatsen zodra je in de buurt bent.
]]

local locations = Config.Merchant.Locations.Travellingmerchant
local market = Config.Merchant.blackMarket or {}

local index = math.random(1, #locations)
local loc = locations[index]

---@return string
local function currentHint()
    local hints = market.hints or {}
    return hints[index] or 'Nobody knows where he is right now.'
end

Bridge.Callback.Register('md-drugs:server:GetMerchant', function(source)
	return {loc = loc, items = Config.Merchant.stores}
end)

RegisterServerEvent("md-drugs:server:purchaseGoods", function(item)
	local src = source
	if not checkDistance(src, loc, 10, 'md-drugs:server:purchaseGoods') then
		return
	end
	if not Config.Merchant.stores[item] then
		Bridge.Prints.Warn(Bridge.Language.Locale('merchant.itemDoesntExist', Bridge.Framework.GetPlayerIdentifier(src), item))
		return
	end
	if Bridge.Framework.RemoveAccountBalance(src, 'cash', Config.Merchant.stores[item]) then
		Bridge.Inventory.AddItem(src, item, 1)
	else
		Bridge.Notify.SendNotify(src, Bridge.Language.Locale('Catches.notEnoughMoney'), "error")
	end
end)

-- =========================================================================
--  Verhuizen
-- =========================================================================

if (market.rotateMinutes or 0) > 0 and #locations > 1 then
    CreateThread(function()
        while true do
            Wait(market.rotateMinutes * 60000)

            -- Nooit twee keer achter elkaar dezelfde plek: dan lijkt het alsof
            -- hij niet verhuisd is.
            local nextIndex = index
            while nextIndex == index do
                nextIndex = math.random(1, #locations)
            end

            index = nextIndex
            loc = locations[index]

            -- Zonder dit bleef de ped bij al ingelogde spelers op de oude
            -- plek staan (bevroren door client/TravellingMerchant.lua's
            -- eenmalige spawn()), terwijl purchaseGoods hierboven al tegen
            -- de nieuwe `loc` controleert.
            TriggerClientEvent('md-drugs:client:merchantMoved', -1)
        end
    end)
end

-- =========================================================================
--  Black market SMS
-- =========================================================================
-- NPWD stelt drie server-exports beschikbaar die we hier gebruiken:
--   onMessage(number, cb)  vangt berichten die naar `number` gestuurd worden
--   emitMessage({...})     stuurt een bericht namens een nummer
--   getPlayerData(locator) haalt de spelersdata op, inclusief telefoonnummer

if market.enabled then
    CreateThread(function()
        -- Wachten tot npwd geladen is; anders bestaat de export nog niet.
        while GetResourceState('npwd') ~= 'started' do Wait(500) end
        Wait(1000)

        local ok, err = pcall(function()
            -- Signatuur uit de npwd-bundle (server/messages/messages.controller):
            --     funcRef({ data = { ...reqObj.data, tgtPhoneNumber }, source })
            -- Het afzendernummer heet sourcePhoneNumber en zit een niveau
            -- dieper. Terugsturen op nummer en niet op source, want de speler
            -- kan tussendoor gedisconnect zijn.
            exports.npwd:onMessage(market.number, function(payload)
                local inner = payload and payload.data
                local sender = inner and inner.sourcePhoneNumber
                if not sender then return end

                exports.npwd:emitMessage({
                    senderNumber = market.number,
                    targetNumber = sender,
                    message = (market.replyPrefix or '') .. currentHint(),
                })
            end)
        end)

        if not ok then
            lib.print.warn(('md-drugs: black market SMS kon niet worden geregistreerd: %s'):format(err))
        end
    end)
end

---Geeft de huidige tip terug. Handig voor andere scripts of een admin-check.
---@return string hint, number index
exports('GetBlackMarketHint', function()
    return currentHint(), index
end)

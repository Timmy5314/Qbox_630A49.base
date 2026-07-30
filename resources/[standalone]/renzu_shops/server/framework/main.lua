insertstr = 'INSERT INTO %s (%s) VALUES (%s)'
vehicletable = 'player_vehicles'
vehiclemod = 'mods'
owner = 'license'
stored = 'state'
garage_id = 'garage'
type_ = 'vehicle'
playertable = 'players'
playeridentifier = 'citizenid'
playeraccounts = 'money'
garage = 'pillboxgarage'
columns = '`plate`, `'..vehiclemod..'`, `'..owner..'`, `'..stored..'`, `job`, `citizenid`, `hash`, `garage`, `vehicle`, `type`'
values = '?, ?, ?, ?, ?, ?, ?, ?, ?, ?'

function GetPlayerFromIdentifier(identifier)
	self = {}
	local getsrc = QBCore.Functions.GetSource(identifier)
	if not getsrc then return end
	self.src = getsrc
	return GetPlayerFromId(self.src)
end

function GetPlayerFromId(src)
	self = {}
	self.src = src
	xPlayer = QBCore.Functions.GetPlayer(self.src)
	if not xPlayer then return end
	if xPlayer.identifier == nil then
		xPlayer.identifier = xPlayer.PlayerData.license
	end
	if xPlayer.citizenid == nil then
		xPlayer.citizenid = xPlayer.PlayerData.citizenid
	end
	if xPlayer.job == nil then
		xPlayer.job = xPlayer.PlayerData.job
	end

	xPlayer.getMoney = function(value)
		return xPlayer.PlayerData.money['cash']
	end
	xPlayer.addMoney = function(value)
			QBCore.Functions.GetPlayer(self.src).Functions.AddMoney('cash',tonumber(value))
		return true
	end
	xPlayer.addAccountMoney = function(type, value)
		type = type:gsub('money', 'cash')
		QBCore.Functions.GetPlayer(self.src).Functions.AddMoney(type,tonumber(value))
		return true
	end
	xPlayer.removeMoney = function(value)
		QBCore.Functions.GetPlayer(self.src).Functions.RemoveMoney('cash',tonumber(value))
		return true
	end
	xPlayer.getAccount = function(type)
		if type == 'money' then
			type = 'cash'
		end
		return {money = xPlayer.PlayerData.money[type]}
	end
	xPlayer.removeAccountMoney = function(type,val)
		if type == 'money' then
			type = 'cash'
		end
		QBCore.Functions.GetPlayer(self.src).Functions.RemoveMoney(type,tonumber(val))
		return true
	end
	xPlayer.showNotification = function(msg)
		TriggerEvent('QBCore:Notify',self.src, msg)
		return true
	end
	xPlayer.addInventoryItem = function(item,amount,info,slot)
		local info = info
		QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddItem(item,amount,slot or false,info)
	end
	xPlayer.removeInventoryItem = function(item,amount,slot)
		QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveItem(item, amount, slot or false)
	end
	xPlayer.getInventoryItem = function(item)
		local gi = QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.GetItemByName(item) or {count = 0}
		gi.count = gi.amount or 0
		return gi
	end
	xPlayer.getGroup = function()
		return QBCore.Functions.GetPermission(self.src)
	end
	if xPlayer.source == nil then
		xPlayer.source = self.src
	end
	return xPlayer
end

Inventory.AddItem = function(source,item,count,metadata,slot)
	return exports.ox_inventory:AddItem(source,item,count,metadata,slot)
end

Inventory.RemoveItem = function(source,item,count,metadata,slot)
	return exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
end

QBCore = nil
shared = {}
shared.lang = 'en' -- look config/locales/%s.lua eg. 'en' for en.lua | to create new language, create a new file ex. es.lua
shared.allowplayercreateitem = false -- if false only admin can create new items via /stores
shared.FinanceMinimum = 500000 -- minimum amount for financing to be enable
shared.FinanceDownPayment = 20 -- 20%. this is the amount of minimum initial payment
shared.FinanceInterest = 10 -- 10%
shared.FinanceMaxDays = 30
shared.MaxDebt = 1000000 -- max amount of total debt from player in able to finance
shared.cashierCap = 500 -- max cash a store's till can hold before overflowing straight into its vault (also keeps robbery payouts sane)
shared.defaultStock = {
	General = 15,
	Ammunation = 20,
	VehicleShop = 10,
} -- default to all items in store when newly purchased
shared.SendtoBank = false -- if true owner will receive money to owned bank account
shared.VehicleKeysType = {
	['export'] = false, -- if false it will use trigger events
	['client'] = true, -- if false it will use server event or server exports
}
shared.VehicleKeys = function(plate,source) -- vehicle keys
	-- first parameter expected is plate
	local sendvehiclekeys
	if IsDuplicityVersion() then
		if shared.VehicleKeysType['export'] then -- server export edit this if your using server exports vehicle keys
			func = function()
				sendvehiclekeys = exports.renzu_garage.GiveVehicleKey -- replace this
			end
			if pcall(func, result or false) then
				return sendvehiclekeys(nil,plate,source)
			end
		elseif shared.VehicleKeysType['client'] and shared.VehicleKeysType['export'] then -- do not edit this condition
			TriggerClientEvent('renzu_shops:Vehiclekeys', source, plate)

		elseif shared.VehicleKeysType['client'] then -- client events from server   edit this if your using client events vehicle keys
			-- Server Events Keys
			TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate) -- this is non existing and example only

		else -- server events from server edit this
			-- Server Events Keys
			-- ex TriggerEvent('GiveKeys', plate, source) -- this is non existing and example only

		end
	elseif not IsDuplicityVersion() then -- client exports edit this if your using exports in client
		if shared.VehicleKeysType['export'] then
			func = function()
				sendvehiclekeys = exports.renzu_garage.GiveVehicleKey -- replace this
			end
			if pcall(func, result or false) then
				return sendvehiclekeys(nil,plate)
			end
		else -- if triggered using client
			TriggerEvent('vehiclekeys:client:SetOwner', plate) -- this is non existing and example only
		end
	end
end

-- QBox (qbx_core) only. qbx_core does NOT expose GetCoreObject on itself -
-- its built-in qb-core compatibility bridge only ever exposes that export
-- under the 'qb-core' name (even though the actual resource is qbx_core),
-- so this call must stay exports['qb-core'] regardless of which one is running.
if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
	QBCore = exports['qb-core']:GetCoreObject()
end
if not QBCore then
	print('^1[renzu_shops] Could not get the QBCore object - is qbx_core started before renzu_shops, and is its qb-core bridge enabled (qbx:enablebridge)?^0')
end

shared.inventory = 'ox_inventory'

MultiCategory = function(blacklist,whitelist,data,...)
	local newtable = {}
	local i = 1
	local whitelisted = false
	for k,v in pairs(whitelist) do whitelisted = true end
	if not whitelisted then
		local t = {...}
		for k,v in pairs(t) do
			if type(v) == 'table' then
				for k,v in pairs(v) do
					if not blacklist[v.type] then
						newtable[i] = v
						i += 1
					end
				end
			end
		end
	else
		for k,v in pairs(data) do
			if whitelist[v.type] then
				newtable[i] = v
				i += 1
			end
		end
	end
	return newtable
end

function request(file)
	local name = ('%s.lua'):format(file)
	local content = LoadResourceFile(GetCurrentResourceName(),name)
	local f, err = load(content)
	return f()
end

-- do not edit
shared.Storeitems = request('config/storeitems')
shared.Shops = request('config/defaultshops')
shared.OwnedShops = request('config/ownedshops/init')
shared.MovableShops = request('config/movableshop')
shared.locales = request('config/locales/'..shared.lang)
shared.playerbooth = request('config/stalls')
request('config/shipping')
-- insert additional datas
for k,v in pairs(Components) do
	table.insert(shared.Storeitems.Ammunation,v)
end

Utils = {}
if not IsDuplicityVersion() then
	Utils.CreateMenu = function(data)
		lib.registerContext({
			id = data.id,
			title = data.title,
			onExit = function()
				--data.OnExit()
			end,
			options = data.options
		})
		lib.showContext(data.id)
	end
	Utils.Proccesed = function(data)
		lib.progressBar({
			duration = data.duration,
			label = data.label,
			useWhileDead = false,
			canCancel = false,
			anim = {
				dict = data.dict,
				clip = data.clip
			},
			disable = {
				car = true,
			}
		})
		local callback = lib.callback.await('renzu_shops:proccessed',100, data)
		if not callback then
			lib.notify({
				title = 'Not Enough Ingredients',
				type = 'error'
			})
		end
	end
	--[[
	    Wees hardcoded naar cfx-nui-ox_inventory/web/images en negeerde daarmee
	    de convar `inventory:imagepath`. Sinds die naar carmap wijst kwam de
	    shop dus nog steeds bij de lokale map uit, en zag je een leeg vakje voor
	    elk item waarvan het plaatje daar niet stond - het merendeel.

	    ox_inventory lost het nu op, met dezelfde regels als de inventory zelf:
	    carmap tenzij de afbeelding alleen lokaal bestaat.
	]]
	self.ImagesPath = function(item)
		local ok, path = pcall(function()
			return exports.ox_inventory:ItemImage(item)
		end)

		if ok and path then
			return item and path or (path .. '/')
		end

		-- Terugval als ox_inventory nog niet gestart is.
		if item then
			return 'https://cfx-nui-ox_inventory/web/images/'..item..'.png'
		end
		return 'https://cfx-nui-ox_inventory/web/images/'
	end
	self.LoadJobShops = function()
		for k,zone in pairs(self.JobSpheres) do
			if zone and zone.remove then
				zone:remove()
			end
		end
		local jobshop = GlobalState.JobShop
		for k,shops in pairs(shared.OwnedShops) do
			for k,shop in pairs(shops) do
				if self.PlayerData and self.PlayerData.job and jobshop[shop.label] == self.PlayerData.job?.name then
					self.temporalspheres[shop.label] = ShopTargets.AddShopTarget(shop.coord,'My Store '..shop.label,self.StoreOwner,shop,{npc = {model = ShopTargets.NpcModelFor(k)}})
					self.JobSpheres[self.PlayerData.job?.name] = self.temporalspheres[shop.label]
				end
			end
		end
	end
	self.Playerloaded = function()
		RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
			Wait(1500)
			self.PlayerData = QBCore.Functions.GetPlayerData()
			if self.PlayerData.job ~= nil then
				self.PlayerData.job.grade = self.PlayerData.job.grade.level
			end
			if self.PlayerData.identifier == nil then
				self.PlayerData.identifier = self.PlayerData.license
			end
			self.LoadShops()
			self.LoadJobShops()
			self.LoadDefaultShops()
		end)
	end

	self.GetPlayerData = function()
		local Player = QBCore.Functions.GetPlayerData()
		if Player.job ~= nil then
			Player.job.grade = Player.job.grade.level
		end
		if Player.identifier == nil then
			Player.identifier = Player.license
		end
		return Player
	end

	self.SetJob = function()
		RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
			self.PlayerData.job = job
			self.PlayerData.job.grade = self.PlayerData.job.grade.level
			self.LoadDefaultShops()
			self.LoadJobShops()
			self.LoadShops()
		end)
	end

	self.getInventoryItems = function(name)
		return exports.ox_inventory:Search('count', name)
	end

	-- RUN RESOURCE
	self.Playerloaded()
	self.SetJob()
	self.Handlers()
	self.StartUp()

	-- EXPORTS FOR ALL FUNCTION
	exports('Shops', function ()
		return self
	end)

	-- SHITY 3dME
	RegisterCommand('bubble', function(source,args)
		local Functions = exports.renzu_shops:Shops()
		Functions.CreateBubbleSpeechSync({id = GetPlayerServerId(PlayerId()), title = GetPlayerName(PlayerId()), message = args[1], bagname = 'player:', ms = 5000})
	end)
end
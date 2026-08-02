local currentWeapon = nil
local loaded = false
local compodata = {}
local itemsdb = {}
local PlayerData = {}
Citizen.CreateThread(function()
	Wait(1)
	itemsdb = exports.ox_inventory:Items()
	PlayerData = exports.qbx_core:GetPlayerData() or {}
	local componentitems = {}
	for item,v in pairs(itemsdb) do
		if v.client and v.client.component then
			componentitems[item] = v.client.component
		end
	end
	for k,v in pairs(components_data) do
		local compo = GetHashKey(v.name)
		v.model = GetHashKey(v.model)
		v.name = GetHashKey(v.name)
		for item,v2 in pairs(componentitems) do
			for k,v3 in pairs(v2) do
				if compo == v3 then
					v.item = item
				end
			end
		end
		compodata[compo] = v
	end
end)

local onback = {}
local items = {}
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	for k,v in pairs(onback) do
		if DoesEntityExist(v.entity) then
			DeleteAttachments(v)
			ReqAndDelete(v.entity)
		end
	end
	PlayerData = exports.qbx_core:GetPlayerData()
	onback = {}
end)

startingup = true
RegisterNetEvent("ox_inventory:setPlayerInventory", function(currentDrops, inventory, weight, esxItem, player, source)
	items = inventory
	PlayerData.inventory = inventory
	for k,v in pairs(items) do
		ItemBack(v.name)
	end
	startingup = false
	LocalPlayer.state:set('ownedobjects',onback,true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	for k,v in pairs(onback) do
		if DoesEntityExist(v.entity) then
			DeleteAttachments(v)
			ReqAndDelete(v.entity)
		end
	end
	onback = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
	PlayerData.job = job
end)

GetWeaponComponents = function(weapon)
	local components = {}
	local hascomponents = false
	local data = exports.ox_inventory:Search('slots', weapon:lower())
    if data then
        for k,v in pairs(data) do
			for k,v2 in pairs(v) do
				if v2.metadata and v2.metadata.components then
					for k,v3 in pairs(v2.metadata.components) do
						for k,v4 in pairs(compodata) do
							if v4.item == v3 then
								components[v3] = v4
								hascomponents = true
							end
						end
						
					end
				end
			end
		end
    end
	return hascomponents, components
end

ItemBack = function(name)
	local itemname = name
	local data = Config[itemname]
	local save = false
	if data and not onback[itemname] and currentWeapon and itemname ~= currentWeapon.name 
		or currentWeapon == nil and data and not onback[itemname] then
		local model = data["model"]
		local ped = cache.ped
		local bone = GetPedBoneIndex(ped, data["back_bone"])
		lib.requestModel(model)
		SetModelAsNoLongerNeeded(model)
		local ent = CreateObject(GetHashKey(model), GetEntityCoords(cache.ped)-vec3(0.0,0.0,5.0), true, true, false)

		--[[
		    Deze twee lussen hadden GEEN uitweg.

		    Dat is hier geen schoonheidsfoutje. `ox_inventory:currentWeapon` wordt
		    synchroon afgehandeld, dus zolang deze functie blijft draaien staat de
		    equip-routine van ox_inventory stil. Lukt het aanmaken of het
		    netwerken van het rugprop-object niet - een model dat niet laadt,
		    entity lockdown, de anticheat - dan draaide dit eeuwig door en kreeg je
		    het WAPEN NIET IN JE HANDEN, terwijl het gewoon in je inventory zit.

		    Nu met een grens. Lukt het niet, dan gaat het prop niet op je rug maar
		    werkt je wapen wel. Dat is de goede kant om op te falen.
		]]
		local deadline = GetGameTimer() + 2000

		while not DoesEntityExist(ent) and GetGameTimer() < deadline do Wait(0) end

		if not DoesEntityExist(ent) then
			lib.print.warn(('renzu_itemback: kon het rugprop voor %s niet aanmaken (%s)')
				:format(itemname, model))
			onback[itemname] = nil
			return
		end

		while not NetworkGetEntityIsNetworked(ent) and GetGameTimer() < deadline do
			Wait(0)
			NetworkRegisterEntityAsNetworked(ent)
		end
		if not onback[itemname] then onback[itemname] = {} end
		onback[itemname] = {net = NetworkGetNetworkIdFromEntity(ent), entity = ent}
		save = true
		local y = data["y"]  
		AttachEntityToEntity(ent, ped, bone, data["x"], y, data["z"], data["x_rotation"], data["y_rotation"], data["z_rotation"], 0, 1, 0, 1, 0, 1)
		SetEntityCompletelyDisableCollision(ent, false, true)	
		if string.find(itemname:upper(), "WEAPON_") then
			local hascompo, components = GetWeaponComponents(itemname)
			if hascompo then
				for k,v in pairs(components) do
					if compodata[v.name].item == k and IsModelInCdimage(v.model) then
						local bone = GetEntityBoneIndexByName(ent, v.bone)
						lib.requestModel(v.model)
						local componentEntity = CreateObjectNoOffset(v.model,GetEntityCoords(cache.ped)-vec3(0.0,0.0,5.0), true, true)

						-- Zelfde verhaal als bij het wapenprop hierboven: begrensd,
						-- anders houdt een attachment dat niet spawnt de hele
						-- equip-routine van ox_inventory tegen.
						local compDeadline = GetGameTimer() + 1000

						while not DoesEntityExist(componentEntity) and GetGameTimer() < compDeadline do Wait(0) end

						if not DoesEntityExist(componentEntity) then goto nextComponent end

						NetworkRegisterEntityAsNetworked(componentEntity)
						while not NetworkGetEntityIsNetworked(componentEntity) and GetGameTimer() < compDeadline do
							Wait(0)
							NetworkRegisterEntityAsNetworked(componentEntity)
						end
						if onback[itemname]['components'] == nil then
							onback[itemname]['components'] = {}
						end
						table.insert(onback[itemname]['components'],NetworkGetNetworkIdFromEntity(componentEntity))
						SetEntityCollision(componentEntity, false, false)
						AttachEntityToEntity(componentEntity, ent, bone, 0.0 , 0.0 , 0.00, 0.0 , 0.0 , 0.0, true, true, false, false, 1, true)
					end
					::nextComponent::
				end
			end
		end
	end
	if save and not startingup then
		LocalPlayer.state:set('ownedobjects',onback,true)
	end
end

lastweapon = nil

DeleteAttachments = function(data)
	if data and data.components then
		for k,v in pairs(data.components) do
			if DoesEntityExist(NetworkGetEntityFromNetworkId(v)) then
				DeleteEntity(NetworkGetEntityFromNetworkId(v))
			end
		end
	end
end

AddEventHandler('ox_inventory:currentWeapon', function(cw)
	if currentWeapon and lastweapon and lastweapon ~= currentWeapon.name then
		ItemBack(lastweapon)
		lastweapon = currentWeapon.name
		currentWeapon = nil
	end
	currentWeapon = cw
	if currentWeapon ~= nil and GetHashKey(currentWeapon.name) ~= GetHashKey('WEAPON_UNARMED') then
		local ped = cache.ped
		ItemBack(lastweapon)
		for k,v in pairs(items) do
			if onback[v.name] and v.name == currentWeapon.name then
				DeleteAttachments(onback[v.name])
				ReqAndDelete(onback[v.name].entity)
				onback[v.name] = nil
			end
		end

		-- `lastweapon = v.name` stond IN de lus hierboven, buiten de if. Daardoor
		-- eindigde het op de naam van het laatste item in de tabel in plaats van
		-- het wapen dat je net pakte, en ging bij de volgende wissel het verkeerde
		-- prop op je rug.
		lastweapon = currentWeapon.name
	elseif currentWeapon and GetHashKey(currentWeapon.name) == GetHashKey('WEAPON_UNARMED') then
		ItemBack(lastweapon)
		lastweapon = currentWeapon.name
		currentWeapon = nil
	elseif currentWeapon == nil and not onback[lastweapon] and lastweapon then
		ItemBack(lastweapon)
	end
end)

-- ox_inventory meldt per gewijzigd item de nieuwe totaalstand via itemCount.
-- Dit vervangt de ESX add/removeInventoryItem-events, die op Qbox nooit vuren
-- (ox_inventory triggert die alleen als shared.framework == 'esx').
RegisterNetEvent('ox_inventory:itemCount', function(name, count)
	if count and count > 0 then
		local exist = false
		for k,v in pairs(items) do
			if name == v.name then
				exist = true
				items[k].count = count
				break
			end
		end
		if not exist then
			table.insert(items, {name = name, count = count})
		end
		ItemBack(name)
	elseif onback[name] then
		DeleteAttachments(onback[name])
		ReqAndDelete(onback[name].entity)
		onback[name] = nil
		for k,v in pairs(items) do
			if name == v.name then
				items[k] = nil
			end
		end
	end
end)

ToggleItemBack = function(bool)
	for k,v in pairs(onback) do
		SetEntityVisible(v.entity,bool)
	end
end

-- used for clothing shops or if you dont want to show the objects
RegisterNetEvent('toggleprops', ToggleItemBack)
exports('ToggleItemBack', ToggleItemBack)

ToggleItemBackSingle = function(name,bool)
	for k,v in pairs(onback) do
		if k == name then
			SetEntityVisible(v.entity,bool)
		end
	end
end

-- same with above but to toggle single object only
RegisterNetEvent('togglesingle', ToggleItemBackSingle)
exports('ToggleItemBackSingle', ToggleItemBackSingle)

local bool = true
RegisterCommand('toggleprops', function (source, args)
	ToggleItemBack(not bool)
	bool = not bool
end)

function ReqAndDelete(object, detach)
    if NetworkGetEntityIsNetworked(object) then
        if DoesEntityExist(object) and NetworkGetEntityOwner(object) == PlayerId() then
            TriggerServerEvent('deleteentity', NetworkGetNetworkIdFromEntity(object))
        end
    else
        DeleteEntity(object)
		SetEntityCoords(object,0.0,0.0,0.0)
    end
end
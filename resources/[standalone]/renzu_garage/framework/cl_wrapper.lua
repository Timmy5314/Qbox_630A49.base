function Framework()
	QBCore = exports['qb-core']:GetCoreObject()
	QBCore.Functions.GetPlayerData(function(p)
		PlayerData = p
		if PlayerData.job ~= nil then
			PlayerData.job.grade = PlayerData.job.grade.level
		end
		if PlayerData.identifier == nil then
			PlayerData.identifier = PlayerData.license
		end
	end)
	vehicletable = 'player_vehicles'
	vehiclemod = 'mods'
	owner = 'license'
	stored = 'state'
	garage__id = 'garage'
	type_ = 'vehicle'

	TriggerServerCallback_ = function(...)
		QBCore.Functions.TriggerCallback(...)
	end
end

SetBlips = function(x,y,z,sprite,scale,color,name,display)
	local blip = AddBlipForCoord(x,y,z,sprite,scale,color,name)
	SetBlipSprite (blip, sprite)
	SetBlipDisplay(blip, display or 4)
	SetBlipScale  (blip, scale)
	SetBlipColour (blip, color)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
	if Config.BlipNamesStatic then
		AddTextComponentSubstringPlayerName('Garage')
	else
		AddTextComponentSubstringPlayerName('Garage'..": "..name.."")
	end
	EndTextCommandSetBlipName(blip)
end

local garageped = {}
local targetid = nil
local textactive = false
AddTarget = function(data)
	function onEnter(self)
		if DoesEntityExist(garageped[data.garage]) then DeleteEntity(garageped[data.garage]) end
		local model = `a_m_m_skater_01`
		lib.requestModel(model)
		local ped = CreatePed(4,model,self.coords.x,self.coords.y,self.coords.z,0.0,false,true)
		while not DoesEntityExist(ped) do Wait(0) end
		SetPedConfigFlag(ped,17,true)
		TaskTurnPedToFaceEntity(ped,cache.ped,-1)
		Wait(1000)
		TaskStandGuard(ped,self.coords,GetEntityHeading(ped),'WORLD_HUMAN_GUARD_STAND')
		garageped[data.garage] = ped
		local options = {
			{
				name = data.garage,
				onSelect = function()
					tid = data.id
					TID(data.id)
					TriggerEvent(data.event,data.id,data.args or false)
				end,
				icon = 'fas fa-warehouse',
				label = data.label,
			}
		}
		-- Altijd tonen (niet alleen als je toevallig al in een auto zat toen de NPC
		-- verscheen): anders mist deze optie zodra je er later pas mee aan komt rijden.
		table.insert(options,{
			name = 'storevehicle',
			onSelect = function()
				if not cache.vehicle then
					Config.Notify('error', 'You are not in a vehicle')
					return
				end
				tid = data.id
				TID(data.id)
				TriggerEvent(data.event,data.id,true)
			end,
			icon = 'fas fa-parking',
			label = 'Store Last Vehicle',
		})
		if Config.target and GetResourceState('ox_target') ~= 'started' and GetResourceState('qb-target') == 'started' then -- needed to be like this instead of relying ox_target compatibility with qb-target. since ox does not support AddTargetEntity to local entity during convert.
			for k,v in pairs(options) do if v.onSelect then v.action = v.onSelect end end
			targetid = exports['qb-target']:AddTargetEntity(ped, {
				options = options,
				distance = 3.0
			})
		elseif GetResourceState('ox_target') == 'started' then
			targetid = exports['ox_target']:addLocalEntity(ped, options)
		end
	end
	
	function onExit(self)
		DeleteEntity(garageped[data.garage])
		if targetid then
			exports.ox_target:removeZone(targetid)
		end
		lib.hideTextUI()
		Wait(1000)
		textactive = false
	end
	
	-- Press [E] om in te leveren, terug op verzoek (de ox_target-menu-optie werkte niet
	-- betrouwbaar). Twee dingen gefixt t.o.v. de oude versie: gebruikt nu data.event
	-- i.p.v. een hardcoded 'opengarage' (die was bij private/huis-garages gewoon fout),
	-- en de afstand is groter (was 7) zodat de prompt niet meer verdwijnt als je iets
	-- te ver van de NPC staat/rijdt.
	local STORE_RANGE = 15
	function inside(self)
		local coord = GetEntityCoords(garageped[data.garage])
		local storing = cache.vehicle and self.distance < STORE_RANGE
		DrawMarker(1, coord.x, coord.y, coord.z-0.4, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, storing and vec3(0, 255, 51) or vec3(200, 255, 255), 50, false, true, 2, nil, nil, false)
		if storing then
			OxlibTextUi('[E] Store Vehicle', true)
			if IsControlJustPressed(0,38) then
				lib.hideTextUI()
				textactive = false
				tid = data.id
				TID(data.id)
				TriggerEvent(data.event, data.id, true)
			end
		elseif textactive then
			lib.hideTextUI()
			textactive = false
		end
	end
	lib.zones.box({
		coords = vec3(data.coord.x,data.coord.y,data.coord.z),
		size = vec3(160, 160, 160), -- groter dan voorheen (55): de NPC moet al staan ruim voordat de speler dichtbij komt, niet pas op het laatste moment verschijnen
		rotation = 45,
		debug = false,
		inside = inside,
		onEnter = onEnter,
		onExit = onExit
	})
end

GarageZone = {}
GarageZone.Spheres = {}
GarageZone.__index = {}
GarageZone.CheckZone = function(garage,f)
	if GarageZone.Spheres[garage] then
		inGarage = false
		local job = GarageZone.Spheres[garage].job
		GarageZone.Spheres[garage]:remove()
		if job == nil or job == PlayerData.job.name then
			f.check()
		end
	end
end
GarageZone.PrivateAdd = function(coord,garage,dist,job,id,data)
	if not Config.Oxlib then return end
	if Config.target and GetResourceState('ox_target') == 'started' or Config.target and GetResourceState('qb-target') == 'started' then
		return AddTarget{id = id, coord = coord, label = data.name, event = 'renzu_garage:opengaragemenu', args = data, garage = garage}
	end
	local garage = data.name
	function onEnter(self)
		CreateThread(function() -- create thread to suport multi zones
			local self = self local garage = data.name local coord = coord local job = job local dist = dist local tid = tid
			tid = id
			TID(id)
			local msg = '[E] - Open '
			if IsPedInAnyVehicle(cache.ped) then
				msg = Message[7]..' [E] '..Message[6]
			else
				msg = ''..Message[7]..' [E] '..data.name..''
			end
			OxlibTextUi(msg)
			local close = DrawInteraction_(id,coord,{3,4},msg,'renzu_garage:opengaragemenu',false,data,false)
			local data = {check = function() return GarageZone.PrivateAdd(coord,garage,dist,job,id,data) end}
			GarageZone.CheckZone(garage,data)
			lib.hideTextUI()
		end)
    end
    
    function onExit(self)
        lib.hideTextUI()
    end
    local sphere = lib.zones.sphere({ coords = coord, radius = dist or 4, debug = false, inside = false, onEnter = onEnter, onExit = onExit })
	sphere.job = job
    GarageZone.Spheres[garage] = sphere
end
GarageZone.RealParkAdd = function(coord,garage,dist,job)
	if not Config.Oxlib then return end
	local garage = garage
    local coord = coord
	local job = job
	local dist = dist or 4
    function onEnter(self)
		CreateThread(function() -- create thread to suport multi zones
			local self = self local garage = garage local coord = coord local job = job local dist = dist local tid = tid
			RealPark()
		end)
    end
    
    function onExit(self)
        lib.hideTextUI()
    end

    local sphere = lib.zones.sphere({ coords = coord, radius = dist or 4, debug = false, inside = false, onEnter = onEnter, onExit = onExit })
	sphere.job = job
    GarageZone.Spheres[garage] = sphere
    return GarageZone.Spheres[garage]
end

GarageZone.AddZone = function(coord,garage,dist,job,id)
	if not Config.Oxlib then return end
	if Config.target and GetResourceState('ox_target') == 'started' or Config.target and GetResourceState('qb-target') == 'started' then
		return AddTarget{id = id, coord = coord, label = 'Request Vehicle Keys', event = 'requestvehkey', garage = garage}
	end
    function onEnter(self)
		CreateThread(function() -- create thread to suport multi zones
			local self = self local garage = garage local coord = coord local job = job local dist = dist local tid = tid
			tid = id
			TID(id)
			local msg = '[E] - Request Vehicle Keys'
			OxlibTextUi(msg)
			local close = DrawInteraction_(garage,coord,{dist,dist+1},msg,'requestvehkey',false,false,false)
			local data = {check = function() return GarageZone.AddZone(coord,garage,dist,job,tid) end}
			GarageZone.CheckZone(garage,data)
			lib.hideTextUI()
		end)
    end
    
    function onExit(self)
        lib.hideTextUI()
    end
    
	local sphere = lib.zones.box({ coords = coord, size = vec3(1, 1, 1), rotation = 45, radius = dist or 4, debug = false, inside = false, onEnter = onEnter, onExit = onExit })
    GarageZone.Spheres[garage] = sphere
    return GarageZone.Spheres[garage]
end

GarageZone.Add = function(coord,garage,dist,job,id)
	if not Config.Oxlib then return end
	if Config.target and GetResourceState('ox_target') == 'started' or Config.target and GetResourceState('qb-target') == 'started' then
		return AddTarget{id = id, coord = coord, label = Message[2]..' '..garage, event = 'opengarage', garage = garage}
	end
    local garage = garage
    local coord = coord
	local job = job
	local dist = dist or 4
	local id = id
    function onEnter(self)
		CreateThread(function() -- create thread to suport multi zones
			local self = self local garage = garage local coord = coord local job = job local dist = dist local tid = tid
			tid = id
			TID(id)
			local msg = '[E] - Open Garage'
			if IsPedInAnyVehicle(cache.ped) then
				msg = Message[7]..' [E] '..Message[6]
			else
				msg = ''..Message[7]..' [E] '..Message[2]..' '..garage..''
			end
			OxlibTextUi(msg)
			local close = DrawInteraction_(garage,coord,{dist,dist+1},msg,'opengarage',false,false,false)
			local data = {check = function() return GarageZone.Add(coord,garage,dist,job,tid) end}
			GarageZone.CheckZone(garage,data)
			lib.hideTextUI()
		end)
    end
    
    function onExit(self)
        lib.hideTextUI()
    end
    
    function inside(self)
    end
	local sphere = lib.zones.box({ coords = coord, size = vec3(1, 1, 1), rotation = 45, radius = dist or 4, debug = false, inside = false, onEnter = onEnter, onExit = onExit })
	sphere.job = job
    GarageZone.Spheres[garage] = sphere
    return GarageZone.Spheres[garage]
end

RecreateGarageInfo = function()
	if Config.Oxlib then
		lib.hideTextUI()
		for k,v in pairs(garagecoord) do
			if GarageZone.Spheres[v.garage] and GarageZone.Spheres[v.garage].remove then
				GarageZone.Spheres[v.garage]:remove()
			end
			if v.job ~= nil and v.job == PlayerData.job.name or v.job == nil and GarageZone.Spheres[v.garage] then
				GarageZone.Add(vector3(v.garage_x, v.garage_y, v.garage_z),v.garage,4,v.job ~= nil and v.job == PlayerData.job.name and v.job or nil,tid)
			end
		end
		if Config.EnableHeliGarage and PlayerData.job ~= nil and helispawn[PlayerData.job.name] ~= nil then
			for k,v in pairs(helispawn[PlayerData.job.name]) do
				GarageZone.Add(vector3(v.coords.x,v.coords.y,v.coords.z),v.garage,5,PlayerData.job.name,v.garage)
			end
		end
	end
end

OxlibTextUi = function(msg,block)
	if textactive and block then return end
	lib.showTextUI(msg, {
		position = "left-center",
		icon = 'car',
		style = {
			borderRadius = 5,
			backgroundColor = '#212121',
			color = 'white'
		}
	})
	textactive = true
end

function Playerloaded()
	RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
	AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
		playerloaded = true
		QBCore.Functions.GetPlayerData(function(p)
			PlayerData = p
			if PlayerData.job ~= nil then
				PlayerData.job.grade = PlayerData.job.grade.level
			end
			if PlayerData.identifier == nil then
				PlayerData.identifier = PlayerData.license
			end
		end)
		LocalPlayer.state:set( 'loaded', true, true)
		LocalPlayer.state.loaded = true
		if Config.EnableHeliGarage and PlayerData.job ~= nil and helispawn[PlayerData.job.name] ~= nil then
			for k, v in pairs (helispawn[PlayerData.job.name]) do
				local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
				SetBlipSprite (blip, v.Blip.sprite)
				SetBlipDisplay(blip, 4)
				SetBlipScale  (blip, v.Blip.scale)
				SetBlipColour (blip, v.Blip.color)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName(""..v.garage.."")
				EndTextCommandSetBlipName(blip)
			end
		end
		if Config.Realistic_Parking then
			TriggerServerEvent('renzu_garage:GetParkedVehicles')
		end
	end)
end

function SetJob()
	RegisterNetEvent('QBCore:Client:OnJobUpdate')
	AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
		PlayerData.job = job
		PlayerData.job.grade = PlayerData.job.grade.level
		playerjob = PlayerData.job.name
		inmark = false
		cancel = true
		markers = {}
		if Config.EnableHeliGarage and PlayerData.job ~= nil and helispawn[PlayerData.job.name] ~= nil then
			for k, v in pairs (helispawn[PlayerData.job.name]) do
				local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
				SetBlipSprite (blip, v.Blip.sprite)
				SetBlipDisplay(blip, 4)
				SetBlipScale  (blip, v.Blip.scale)
				SetBlipColour (blip, v.Blip.color)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName(Message[2]..": "..v.garage.."")
				EndTextCommandSetBlipName(blip)
			end
		end
		CloseNui()
		RecreateGarageInfo()
	end)
end

MathRound = function(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

ShowNotification = function(msg)
	TriggerEvent('QBCore:Notify', msg)
end

Framework()
SetJob()
Playerloaded()
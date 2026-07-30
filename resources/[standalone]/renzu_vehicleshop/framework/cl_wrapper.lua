function Framework()
	QBCore = exports['qb-core']:GetCoreObject()
	QBCore.Functions.GetPlayerData(function(p)
		PlayerData = p
		if PlayerData.job ~= nil then
			PlayerData.job.grade = PlayerData.job.grade.level
		end
	end)
	TriggerServerCallback_ = function(...)
		QBCore.Functions.TriggerCallback(...)
	end
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
		end)
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
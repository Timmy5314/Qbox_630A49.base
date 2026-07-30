--[[
	Unified ox_target + NPC helper for renzu_shops.

	Every interactive shop point (default shops, owned shops, stalls, movable
	shops) is created and removed through ShopTargets.AddShopTarget/RemoveZone.
	AddShopTarget always removes whatever was previously registered under the
	same id before creating anything new, which is what stops zones and NPCs
	from stacking on every reload/job-change/relog. Every handle this returns
	exposes the same :remove() shape, so call sites don't need to know
	whether a given point spawned an NPC or is a plain box zone.

	(Named ShopTargets rather than Shops to avoid clashing with the
	'Shops' resource export, which returns the unrelated `self` shop-state table.)
]]

ShopTargets = ShopTargets or {}
ShopTargets.targets = {}

local DEFAULT_PED_MODEL = `a_m_m_bevhills_01`
local DEFAULT_SCENARIO = 'WORLD_HUMAN_STAND_IMPATIENT'

-- sensible default shopkeeper models per preset shop type, used only when a
-- shop config doesn't specify its own npc.model
local NPC_MODELS = {
	General = `mp_m_shopkeep_01`,
	LiquorStore = `mp_m_shopkeep_01`,
	Ammunation = `s_m_y_ammucity_01`,
	BlackMarketArms = `g_m_importexport_01`,
	VehicleShop = `s_m_m_autoshop_01`,
	ClothingShop = `s_f_y_shop_mid`,
	PoliceArmoury = `s_m_y_cop_01`,
	MechanicSupply = `s_m_y_xmech_02`,
	PondCafe = `a_f_y_hipster_02`,
	Balls8 = `a_m_y_business_02`,
	YouTool = `s_m_y_dealer_01`,
}

ShopTargets.NpcModelFor = function(shoptype)
	return shoptype and NPC_MODELS[shoptype]
end

local function spawnNpc(coords, npc)
	local model = (npc and npc.model) or DEFAULT_PED_MODEL
	lib.requestModel(model)
	local heading = (npc and npc.heading) or 0.0
	local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, heading, false, true)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, true)
	SetModelAsNoLongerNeeded(model)
	TaskStartScenarioInPlace(ped, (npc and npc.scenario) or DEFAULT_SCENARIO, 0, true)
	return ped
end

-- Safe to call even when nothing was ever registered under `id` - that's
-- what makes AddShopTarget idempotent.
ShopTargets.RemoveZone = function(id)
	local entry = ShopTargets.targets[id]
	if not entry then return end
	if entry.target then
		pcall(function() exports.ox_target:removeZone(entry.target) end)
	end
	if entry.ped and DoesEntityExist(entry.ped) then
		DeleteEntity(entry.ped)
	end
	ShopTargets.targets[id] = nil
end

--[[
	coords: vec3 point to spawn the ped / anchor the box zone
	msg: label shown on the ox_target option
	callback: function(var) invoked on select
	var: data forwarded to callback (and to self.Active, matching legacy behaviour)
	opts (optional):
		id       - explicit registry id (defaults to msg - keep ids unique per interaction point)
		npc      - false to skip spawning a ped, or {model=,heading=,scenario=}
		entity   - attach to an existing entity instead of coords/npc (movable shops, stalls)
		size     - vec3 box zone size (only used without npc/entity)
		rotation - box zone rotation (only used without npc/entity)
		distance - ox_target interact distance (default 2.5)
		icon     - fontawesome icon (default shopping basket)
		groups   - job/group name (or list) required to see the option
]]
ShopTargets.AddShopTarget = function(coords, msg, callback, var, opts)
	opts = opts or {}
	local id = opts.id or msg
	ShopTargets.RemoveZone(id)

	local entry = {}
	local entity = opts.entity

	if not entity and opts.npc ~= false then
		entry.ped = spawnNpc(coords, opts.npc)
		entity = entry.ped
	end

	local options = {
		{
			icon = opts.icon or 'fas fa-shopping-basket',
			label = msg,
			distance = opts.distance or 2.5,
			canInteract = opts.groups and function()
				return self.GetJobFromData(opts.groups) == self.PlayerData?.job?.name
			end or nil,
			onSelect = function()
				self.Active = lib.table.deepclone(var)
				self.lastdata = var and var.index
				self.movabletype = var and var.type
				SetNuiFocus(false, false)
				SetNuiFocusKeepInput(false)
				if callback == self.OpenShop then
					TriggerEvent('ox_inventory:closeInventory')
				end
				SetTimeout(100, function() callback(var) end)
			end
		}
	}

	if entity then
		entry.target = exports.ox_target:addLocalEntity(entity, options)
	else
		entry.target = exports.ox_target:addBoxZone({
			coords = coords,
			size = opts.size or vec3(1.0, 1.0, 2.0),
			rotation = opts.rotation or 0.0,
			debug = false,
			options = options
		})
	end

	entry.remove = function(self) ShopTargets.RemoveZone(id) end
	ShopTargets.targets[id] = entry
	return entry
end

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	for id in pairs(ShopTargets.targets) do
		ShopTargets.RemoveZone(id)
	end
end)

-- PLACEHOLDER - not registered in config/ownedshops/init.lua yet.
-- Fill in real coord/purchase/spawn/restock/showcase locations, then
-- uncomment the matching lines in config/ownedshops/init.lua and
-- config/defaultshops.lua to activate.
return {
	[1] = {
		vehicletype = 'boat',
		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Boat Shop',
		coord = vec3(0.0,0.0,0.0), -- TODO: owner manage coord
		purchase = vec4(0.0,0.0,0.0,0.0), -- TODO: buy point
		spawn = vec4(0.0,0.0,0.0,0.0), -- TODO: where bought boats spawn
		restock = vec4(0.0,0.0,0.0,0.0), -- TODO: where delivered stock is placed
		blip = {
			id = 356, colour = 69, scale = 0.8
		},
		price = 4000000,
		supplieritem = MultiCategory(
			{}, -- blacklisted types
			{['boats'] = true}, -- whitelisted types - only boats show up
			AllVehicles
		),
		camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
	},
}

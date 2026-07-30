-- PLACEHOLDER - not registered in config/ownedshops/init.lua yet.
-- Fill in real coord/purchase/spawn/restock/showcase locations, then
-- uncomment the matching lines in config/ownedshops/init.lua and
-- config/defaultshops.lua to activate.
return {
	[1] = {
		vehicletype = 'helicopter',
		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Helicopter Shop',
		coord = vec3(0.0,0.0,0.0), -- TODO: owner manage coord
		purchase = vec4(0.0,0.0,0.0,0.0), -- TODO: buy point
		spawn = vec4(0.0,0.0,0.0,0.0), -- TODO: where bought helicopters spawn
		restock = vec4(0.0,0.0,0.0,0.0), -- TODO: where delivered stock is placed
		blip = {
			id = 359, colour = 69, scale = 0.8
		},
		price = 5000000,
		supplieritem = MultiCategory(
			{}, -- blacklisted types
			{['helicopters'] = true}, -- whitelisted types - only helicopters show up
			AllVehicles
		),
		camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
	},
}

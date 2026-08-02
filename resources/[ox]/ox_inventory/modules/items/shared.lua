local function useExport(resource, export)
	return function(...)
		return exports[resource][export](nil, ...)
	end
end

local ItemList = {}
local isServer = IsDuplicityVersion()

--[[
    ── Waar itemafbeeldingen vandaan komen ──────────────────────────────────

    `inventory:imagepath` wijst naar de carmap-repo (zie ox.cfg). Alles komt
    daar vandaan, ook wat renzu_shops, renzu_vehicleshop en renzu_garage tonen:
    die lezen dezelfde itemdata.

    Uitzondering: een paar honderd afbeeldingen staan wel in web/images maar
    niet in carmap. Die zouden een leeg vakje geven terwijl het plaatje er
    gewoon is. Voor die bestandsnamen valt dit terug op nui://. De lijst staat
    in data/local_images.lua.

    Een pad met een schema (https://, nui://) wordt nooit aangeraakt - dat is
    een expliciete keuze in items.lua.
]]
local localImages = lib.load('data.local_images') or {}

local function setImagePath(path)
    if not path then return end
    if path:match('^[%w]+://') then return path end

    -- Bewust https://cfx-nui- en niet nui://. Allebei werken binnen de NUI van
    -- ox_inventory zelf, maar andere resources (renzu_shops) zetten deze string
    -- rechtstreeks in een <img src> en daar werkt nui:// niet.
    if localImages[path] then
        return ('https://cfx-nui-ox_inventory/web/images/%s'):format(path)
    end

    return ('%s/%s'):format(client.imagepath, path)
end

---@param data OxItem
local function newItem(data)
	data.weight = data.weight or 0

	if data.close == nil then
		data.close = true
	end

	if data.stack == nil then
		data.stack = true
	end

	local clientData, serverData = data.client, data.server
	---@cast clientData -nil
	---@cast serverData -nil

	if not data.consume and (clientData and (clientData.status or clientData.usetime or clientData.export) or serverData?.export) then
		data.consume = 1
	end

	if isServer then
        ---@cast data OxServerItem
        serverData = data.server
		data.client = nil

		if not data.durability then
			if data.degrade or (data.consume and data.consume ~= 0 and data.consume < 1) then
				data.durability = true
			end
		end

        if not serverData then goto continue end

        if serverData.export then
            data.cb = useExport(string.strsplit('.', serverData.export))
        end
	else
        ---@cast data OxClientItem
        clientData = data.client
		data.server = nil
		data.count = 0

        if not clientData then goto continue end

        if clientData.export then
            data.export = useExport(string.strsplit('.', clientData.export))
        end

        clientData.image = setImagePath(clientData.image)

        if clientData.propTwo then
            clientData.prop = clientData.prop and { clientData.prop, clientData.propTwo } or clientData.propTwo
            clientData.propTwo = nil
        end
	end

    ::continue::
	ItemList[data.name] = data
end

for type, data in pairs(lib.load('data.weapons') or {}) do
	for k, v in pairs(data) do
		v.name = k
		v.close = type == 'Ammo' and true or false
        v.weight = v.weight or 0

		if type == 'Weapons' then
			---@cast v OxWeapon
			v.model = v.model or k -- actually weapon type or such? model for compatibility
			v.hash = joaat(v.model)
			v.stack = v.throwable and true or false
			v.durability = v.durability or 0.05
			v.weapon = true
		else
			v.stack = true
		end

		v[type == 'Ammo' and 'ammo' or type == 'Components' and 'component' or type == 'Tints' and 'tint' or 'weapon'] = true

		if isServer then v.client = nil else
			v.count = 0
			v.server = nil
			local clientData = v.client

			if clientData?.image then
                clientData.image = setImagePath(clientData.image)
			end
		end

		ItemList[k] = v
	end
end

for k, v in pairs(lib.load('data.items') or {}) do
	v.name = k

	--[[
	    Heeft een item geen eigen client.image, dan bouwt de NUI zelf
	    `<imagepath>/<naam>.png` - en die wijst nu naar carmap. Voor items
	    waarvan de afbeelding alleen lokaal bestaat klopt dat niet, dus die
	    krijgen hier alsnog een expliciete verwijzing. setImagePath() maakt er
	    dan een nui://-pad van.

	    Een client-tabel met alleen een image is onschadelijk: zonder usetime
	    valt de gebruik-callback net zo door als bij een item helemaal zonder
	    client-tabel.
	]]
	if not v.client?.image and localImages[k .. '.png'] then
		v.client = v.client or {}
		v.client.image = k .. '.png'
	end

	local success, response = pcall(newItem, v)

    if not success then
        warn(('An error occurred while creating item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(k, response))
    end
end

ItemList.cash = ItemList.money

return ItemList

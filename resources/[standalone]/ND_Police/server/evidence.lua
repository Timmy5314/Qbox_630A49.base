local evidence = {}
local evidenceTime = {}
local addEvidence = {}
local clearEvidence = {}
local evidenceMetadata = lib.load("data.evidence")
local config = lib.load("data.config")

local bulletText = {
    projectile = locale("projectile_from"),
    casing = locale("casing_from"),
}

-- Nodes komen van de client. Een aangepaste client kan er dus willekeurig veel
-- sturen, en sleutels die hier helemaal niet bestaan.
local MAX_DISTRIBUTE_NODES = 64
local MAX_COLLECT_NODES = 64
local MAX_COLLECT_DISTANCE = 10.0

Ox_inventory:registerHook('createItem', function(payload)
    local name = payload.item.name
    local text = bulletText[name]
    if not text then return end

    local metadata = payload.metadata
    local evidence = evidenceMetadata[metadata.type]
    if not evidence then return end

    local image = evidence[name]
    if not image then return end

    return {
        label = text:format(evidence.label),
        weight = evidence.weight,
        image = image
    }
end, {
    itemFilter = {
        projectile = true,
        casing = true
    }
})

---@param coords vector3|vector4
---@return vector3?
local function nodeWorldCoords(coords)
    local kind = type(coords)

    if kind == 'vector4' then
        -- Aan een entity gekoppeld spoor; de offset kan de server niet omrekenen,
        -- dus toetsen we op de entity zelf.
        local entity = NetworkGetEntityFromNetworkId(coords.w)
        if not DoesEntityExist(entity) then return end
        return GetEntityCoords(entity)
    end

    if kind == 'vector3' then return coords end
end

CreateThread(function()
    while true do
        Wait(1000)

        if next(addEvidence) or next(clearEvidence) then
            TriggerClientEvent('ND_Police:updateEvidence', -1, addEvidence, clearEvidence)

            table.wipe(addEvidence)
            table.wipe(clearEvidence)
        end
    end
end)

-- Sporen bleven eeuwig staan: elk schot dat ooit gevallen is bleef een node op
-- de server en een ox_target-zone bij elke client. Over een lange sessie loopt
-- dat alleen maar op.
if config.evidenceLifetime and config.evidenceLifetime > 0 then
    local lifetime = config.evidenceLifetime * 60

    CreateThread(function()
        while true do
            Wait(60000)

            local now = os.time()

            for coords, created in pairs(evidenceTime) do
                if now - created > lifetime then
                    evidence[coords] = nil
                    evidenceTime[coords] = nil
                    addEvidence[coords] = nil
                    clearEvidence[coords] = true
                end
            end
        end
    end)
end

RegisterServerEvent('ND_Police:distributeEvidence', function(nodes)
    local src = source
    if type(nodes) ~= 'table' then return end

    local state = Player(src).state
    state.lastShot = os.time()

    if not state.shot then
        state.shot = true
    end

    local handled = 0

    for coords, items in pairs(nodes) do
        handled = handled + 1
        if handled > MAX_DISTRIBUTE_NODES then break end

        local kind = type(coords)

        if (kind == 'vector3' or kind == 'vector4') and type(items) == 'table' then
            if evidence[coords] then
                lib.table.merge(evidence[coords], items)
            else
                evidence[coords] = items
                addEvidence[coords] = true
            end

            evidenceTime[coords] = state.lastShot
        end
    end
end)

RegisterServerEvent('ND_Police:collectEvidence', function(nodes)
    local src = source
    if type(nodes) ~= 'table' then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local pedCoords = GetEntityCoords(ped)
    local items = {}

    for i = 1, math.min(#nodes, MAX_COLLECT_NODES) do
        local coords = nodes[i]
        local node = evidence[coords]
        local worldCoords = node and nodeWorldCoords(coords)

        -- Onbekende sleutel gaf hier een exception: lib.table.merge loopt over
        -- pairs(nil). De afstandscheck ontbrak volledig, dus je kon sporen van de
        -- andere kant van de map oprapen.
        if node and worldCoords and #(pedCoords - worldCoords) <= MAX_COLLECT_DISTANCE then
            lib.table.merge(items, node)

            clearEvidence[coords] = true
            evidence[coords] = nil
            evidenceTime[coords] = nil
        end
    end

    local success = false
    for item, data in pairs(items) do
        -- ox_inventory maakt van een niet-tabel metadata `{type = waarde}`; dat is
        -- precies wat de createItem-hook hierboven uitleest.
        for ammoType, count in pairs(data) do
            if Ox_inventory:AddItem(src, item, count, ammoType) then
                success = true
            end
        end
    end

    if not success then return end

    Bridge.notify(src, {type = 'success', title = locale("evidence_collected")})
end)

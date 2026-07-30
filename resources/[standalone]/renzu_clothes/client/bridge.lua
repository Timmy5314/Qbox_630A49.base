---@diagnostic disable: undefined-global
--- Framework detection and native clothing helpers.

Bridge = {}

local PROP_IDS = { 0, 1, 2, 6, 7 }
local COMPONENT_IDS = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

-- ── Framework ─────────────────────────────────────────────────────────────

local function detectFramework()
    if GetResourceState('qbx_core'):find('start') then return 'qbx' end
    if GetResourceState('qb-core'):find('start') then return 'qb' end
    if GetResourceState('es_extended'):find('start') then return 'esx' end
    return 'standalone'
end

Bridge.framework = detectFramework()

if Config.Debug then
    lib.print.info(('detected framework: %s'):format(Bridge.framework))
end

local QBCore, ESX

if Bridge.framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Bridge.framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

--- Is the player loaded (character selected)?
---@return boolean
function Bridge.isPlayerLoaded()
    if Bridge.framework == 'qbx' or Bridge.framework == 'qb' then
        return LocalPlayer.state.isLoggedIn == true
    elseif Bridge.framework == 'esx' then
        return ESX.IsPlayerLoaded()
    end
    return true
end

--- Current job name, or nil.
---@return string|nil
function Bridge.getJob()
    if Bridge.framework == 'qbx' then
        local data = exports.qbx_core:GetPlayerData()
        return data and data.job and data.job.name
    elseif Bridge.framework == 'qb' then
        local data = QBCore.Functions.GetPlayerData()
        return data and data.job and data.job.name
    elseif Bridge.framework == 'esx' then
        local data = ESX.GetPlayerData()
        return data and data.job and data.job.name
    end
    return nil
end

-- ── Reading and writing clothing ──────────────────────────────────────────
--
-- This goes through natives on purpose. renzu_clothes therefore needs NO
-- appearance resource: illenium-appearance, fivem-appearance or nothing at
-- all will work. Those stay responsible for face, hair and model; this
-- resource only owns the clothing components.

--- Reads every component and prop straight off the ped.
---@param ped number
---@return table
function Bridge.readPed(ped)
    local components, props = {}, {}

    for i = 1, #COMPONENT_IDS do
        local id = COMPONENT_IDS[i]
        components[#components + 1] = {
            component_id = id,
            drawable = GetPedDrawableVariation(ped, id),
            texture = GetPedTextureVariation(ped, id),
        }
    end

    for i = 1, #PROP_IDS do
        local id = PROP_IDS[i]
        props[#props + 1] = {
            prop_id = id,
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id),
        }
    end

    return {
        model = GetEntityModel(ped),
        components = components,
        props = props,
    }
end

--- Applies a single component or prop to the ped.
---@param ped number
---@param component integer
---@param drawable integer
---@param texture integer
---@param isProp boolean
function Bridge.applyPiece(ped, component, drawable, texture, isProp)
    if isProp then
        if drawable == nil or drawable < 0 then
            ClearPedProp(ped, component)
        else
            SetPedPropIndex(ped, component, drawable, texture or 0, true)
        end
    else
        SetPedComponentVariation(ped, component, drawable or 0, texture or 0, 0)
    end
end

--- Restores a snapshot from `Bridge.readPed` through natives. Deliberately
--- not through an appearance resource: those expect their own format and
--- would also touch face and hair, while we only changed components.
---@param ped number
---@param snapshot table
function Bridge.applySnapshot(ped, snapshot)
    if not snapshot then return end

    for _, c in pairs(snapshot.components or {}) do
        SetPedComponentVariation(ped, c.component_id, c.drawable, c.texture, 0)
    end

    for _, p in pairs(snapshot.props or {}) do
        if p.drawable < 0 then
            ClearPedProp(ped, p.prop_id)
        else
            SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture, true)
        end
    end
end

--- Ped model name ('mp_m_freemode_01' / 'mp_f_freemode_01').
---@param ped number
---@return string
function Bridge.getModelName(ped)
    return GetEntityModel(ped) == joaat('mp_f_freemode_01') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
end

--- Default value for a component or prop according to Config.DefaultOutfit.
---@param ped number
---@param component integer
---@param isProp boolean
---@return integer drawable, integer texture
function Bridge.getDefaultPiece(ped, component, isProp)
    local outfit = Config.DefaultOutfit[Bridge.getModelName(ped)]
    local entry = outfit and (isProp and outfit.props[component] or outfit.components[component])
    if entry then return entry.drawable, entry.texture end
    return isProp and -1 or 0, 0
end

-- ── Notifications ─────────────────────────────────────────────────────────

---@param message string
---@param type? 'success'|'error'|'inform'|'warning'
function Bridge.notify(message, type)
    lib.notify({
        title = 'Clothing',
        description = message,
        type = type or 'inform',
        position = 'top-right',
        icon = 'shirt',
    })
end

---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - weapon armory (client)

    Attachment compatibility is worked out here because
    DoesWeaponTakeWeaponComponent is a client native. The server only validates
    that the item is a real attachment before handing it over.
]]

ArmoryUI = {}

local opening = false
local cached = nil

---@param weaponName string
---@param attachments table[]
---@return table[] compatible attachments
local function compatibleWith(weaponName, attachments)
    local weaponHash = joaat(weaponName)
    local list = {}

    for _, attachment in ipairs(attachments) do
        for _, componentHash in ipairs(attachment.components or {}) do
            if DoesWeaponTakeWeaponComponent(weaponHash, componentHash) then
                list[#list + 1] = {
                    name  = attachment.name,
                    label = attachment.label,
                    image = attachment.image,
                }
                break
            end
        end
    end

    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

---@param data table server payload
local function decorate(data)
    for _, weapon in ipairs(data.weapons) do
        weapon.attachments = compatibleWith(weapon.name, data.attachments)
    end
    data.attachments = nil -- the UI only needs the per-weapon list
    return data
end

function ArmoryUI.open()
    if opening or Nui.isOpen() then return end
    opening = true

    local data = lib.callback.await('renzu_jobs:getArmory', false)
    opening = false

    if not data then return end

    cached = decorate(data)
    Nui.open('armory', cached)
end

RegisterNetEvent('renzu_jobs:openweapons', function() ArmoryUI.open() end)

local function refresh()
    local data = lib.callback.await('renzu_jobs:getArmory', false)
    if not data then return end
    cached = decorate(data)
    Nui.update('armory', cached)
end

RegisterNUICallback('armory:toggleWeapon', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:toggleWeapon', false, data.weapon)
    if ok then refresh() end
    cb(ok)
end)

RegisterNUICallback('armory:takeAttachment', function(data, cb)
    local ok = lib.callback.await('renzu_jobs:takeAttachment', false, data.item)
    cb(ok)
end)

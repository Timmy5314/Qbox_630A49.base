if not Config.Drugs['TravellingMerchant'] then return end

-- De server verhuist `loc` intern op een interval (zie server/TravellingMerchant.lua)
-- maar zei dat nooit tegen al ingelogde clients. spawn() liep hier maar één
-- keer, bij resource-start, en bevroor de ped voorgoed op die eerste plek -
-- na de eerste rotatie stond de ped dus nog op de oude locatie terwijl
-- purchaseGoods server-side al tegen de NIEUWE loc een afstandscheck deed.
local merchantPed = nil

local function despawn()
    if not merchantPed then return end
    Bridge.Target.RemoveLocalEntity(merchantPed)
    if DoesEntityExist(merchantPed) then
        DeleteEntity(merchantPed)
    end
    for i = 1, #targets do
        if targets[i] == merchantPed then
            table.remove(targets, i)
            break
        end
    end
    merchantPed = nil
end

local function spawn()
    despawn()

    local data = Bridge.Callback.Trigger('md-drugs:server:GetMerchant')
    local model = 's_m_m_trucker_01'
    requestModel(model)
    local ped = CreatePed(4, model, data.loc.x, data.loc.y, data.loc.z, data.loc.w, false, true)
    Freeze(ped, true, data.loc.w)
    Bridge.Target.AddLocalEntity(ped, {
        {
            icon = Bridge.Language.Locale('merchant.targetIcon'),
            label = Bridge.Language.Locale('merchant.targetOpen'),
            action = function()
                local options = {}
                for k, v in pairs (data.items) do
                    local itemInfo = Bridge.Inventory.GetItemInfo(k)
                    options[#options+1] = {
                        title = itemInfo.label,
                        description = '$'..v,
                        icon = itemInfo.image,
                        onSelect = function()
                            TriggerServerEvent('md-drugs:server:purchaseGoods', k)
                        end
                    }
                end
                Bridge.Menu.Open({
                    id = 'merchant_menu',
                    title = Bridge.Language.Locale('merchant.menuTitle'),
                    options = options
                })
            end
        }
    })
    merchantPed = ped
    targets[#targets+1] = ped
end
spawn()

RegisterNetEvent('md-drugs:client:merchantMoved', spawn)

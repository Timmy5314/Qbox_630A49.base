--[[ renzu_customs :: helpers ]]

local VEHICLE_CLASSES = {
    [0] = 'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports',
    'Super', 'Motorcycles', 'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats',
    'Helicopters', 'Planes', 'Service', 'Emergency', 'Military', 'Commercial', 'Trains',
}

---@param description string
---@param notifyType? 'success'|'error'|'inform'|'warning'
---@param title? string
function Customs.notify(description, notifyType, title)
    lib.notify({
        id = 'renzu_customs',
        title = title or 'Customs',
        description = description,
        type = notifyType or 'inform',
        icon = 'wrench',
    })
end

---@param value number
---@param decimals? integer
---@return number
function Customs.round(value, decimals)
    if decimals then
        local power = 10 ^ decimals
        return math.floor((value * power) + 0.5) / power
    end
    return math.floor(value + 0.5)
end

---@param value number
---@return string
function Customs.comma(value)
    local formatted = tostring(math.floor(tonumber(value) or 0))
    local matches
    repeat
        formatted, matches = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
    until matches == 0
    return formatted
end

---@param class integer
---@return string
function Customs.className(class)
    return VEHICLE_CLASSES[class] or 'Vehicle'
end

---Readable vehicle name. Addon vehicles often have no gxt entry, in which case
---GetLabelText returns 'NULL' - fall back to the model's display name.
---@param vehicle integer
---@return string
function Customs.vehicleLabel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local label = GetLabelText(displayName)

    if not label or label == '' or label == 'NULL' then
        return displayName
    end

    return label
end

---@return string? job, integer grade
function Customs.getJob()
    local job = Customs.playerData and Customs.playerData.job
    if not job then return nil, 0 end
    return job.name, (job.grade and job.grade.level) or 0
end

---Does the player own this shop (and reach the grade needed for `feature`)?
---@param shopId string
---@param feature? 'stockroom'|'paintmenu'|'garage_inventory'
---@return boolean
function Customs.hasShopAccess(shopId, feature)
    local shop = Config.Customs[shopId]
    if not shop then return false end

    local jobName, grade = Customs.getJob()
    if not jobName or shop.job ~= jobName then return false end

    local minGrade = shop.min_grade or Config.DefaultJobGradePermmission
    if feature and shop[feature] and shop[feature].grade then
        minGrade = shop[feature].grade
    end

    return grade >= minGrade
end

---May this player open the tuning menu at this shop?
---@param shopId string
---@return boolean
function Customs.canTune(shopId)
    if not Config.JobPermissionAll then return true end
    if Customs.hasShopAccess(shopId) then return true end

    -- a mod flagged for 'all' opens the menu to everyone
    local jobName, grade = Customs.getJob()
    for _, mod in pairs(Config.VehicleMod) do
        local grades = mod.job_grade
        if grades then
            if grades.all then return true end
            if jobName and grades[jobName] and grade >= grades[jobName] then return true end
        end
    end

    return false
end

---May this player buy/fit this specific mod?
---@param mod table entry of Config.VehicleMod
---@return boolean
function Customs.canUseMod(mod)
    if Customs.freeMode or not Config.JobPermissionAll then return true end

    local grades = mod.job_grade
    if not grades then return true end
    if grades.all then return true end

    local jobName, grade = Customs.getJob()
    return jobName ~= nil and grades[jobName] ~= nil and grade >= grades[jobName]
end

---Shop the player is standing in, based on `radius`.
---@param coords? vector3
---@return string? shopId
function Customs.getShopAt(coords)
    coords = coords or GetEntityCoords(cache.ped)
    for id, shop in pairs(Config.Customs) do
        if #(coords - vec3(shop.shopcoord.x, shop.shopcoord.y, shop.shopcoord.z)) <= (shop.radius or 30.0) then
            return id
        end
    end
end

---Takes network control of a vehicle and unlocks its mod kit.
---@param vehicle integer
---@return boolean
function Customs.prepareVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end

    if NetworkGetEntityIsNetworked(vehicle) and not NetworkHasControlOfEntity(vehicle) then
        local attempts = 0
        repeat
            NetworkRequestControlOfEntity(vehicle)
            attempts = attempts + 1
            Wait(0)
        until NetworkHasControlOfEntity(vehicle) or attempts > 200 or not DoesEntityExist(vehicle)
    end

    if not DoesEntityExist(vehicle) then return false end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleModKit(vehicle, 0)
    return true
end

---The vehicle the player is in, falling back to the last vehicle.
---@return integer
function Customs.currentVehicle()
    local vehicle = cache.vehicle or GetVehiclePedIsIn(cache.ped, false)
    if vehicle == 0 then
        vehicle = GetVehiclePedIsIn(cache.ped, true)
    end
    return vehicle
end

---ox_lib's streaming helpers raise an error when the asset never loads instead of
---returning false, which would kill whatever handler we are in. This keeps it a boolean.
---@param loader function lib.requestModel / lib.requestAnimDict / lib.requestNamedPtfxAsset
---@param asset string|number
---@param timeout? integer
---@return boolean
function Customs.load(loader, asset, timeout)
    local ok = pcall(loader, asset, timeout or 5000)
    if not ok then
        lib.print.warn(('could not load asset "%s"'):format(tostring(asset)))
    end
    return ok
end

---Deletes an entity this client created.
---@param entity integer?
function Customs.deleteEntity(entity)
    if not entity or not DoesEntityExist(entity) then return end
    DetachEntity(entity, true, false)
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end

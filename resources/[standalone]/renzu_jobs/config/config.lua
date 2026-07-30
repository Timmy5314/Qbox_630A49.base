---@diagnostic disable: lowercase-global
--[[
    renzu_jobs - main configuration
    Framework: QBox (qbx_core)

    Every value in here is shared between client and server. Anything that must
    never reach the client (webhook urls) lives in Config.Webhooks and is stripped
    before the config is handed to the NUI.
]]

Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Integrations
-- ─────────────────────────────────────────────────────────────────────────────

--- Clothing script used by the wardrobe points. Must export `openWardrobe`.
--- Give it a list and the first one that is actually running wins.
---
--- NOTE: a folder like `[renzuzu]` is only a grouping folder in FiveM. The
--- resource name is the INNER folder, so `[renzuzu]/renzu_garage` is a resource
--- called `renzu_garage`, not `renzuzu_garage`. Both spellings are listed here
--- so it works either way.
--- Set to false to disable wardrobe points entirely.
Config.ClothingResource = { 'renzuzu_clothes', 'renzu_clothes' }

--- Garage script. Used only to hand out / take back vehicle keys so job
--- vehicles behave exactly like garage vehicles.
--- Set to false to skip the key system (vehicles then work without keys).
Config.GarageResource = { 'renzuzu_garage', 'renzu_garage' }

--- Return the first candidate resource that is actually started.
--- Works on both client and server.
---@param candidates string|string[]|false
---@return string? name
function Config.resolveResource(candidates)
    if not candidates then return nil end
    if type(candidates) == 'string' then candidates = { candidates } end

    for _, name in ipairs(candidates) do
        if GetResourceState(name) == 'started' then return name end
    end
    return nil
end

--- Item name used as the vehicle key by the garage resource.
Config.KeyItem = 'keys'

-- ─────────────────────────────────────────────────────────────────────────────
-- Money
-- ─────────────────────────────────────────────────────────────────────────────

--- qbx_core account used when a player pays out of pocket.
Config.CashAccount = 'cash'
Config.BankAccount = 'bank'

--- QBox has no black money account, so it is handled as an ox_inventory item.
--- Set to false to remove black money from the boss menu completely.
Config.BlackMoneyItem = 'black_money'

--- Money types the job treasury can hold. Keys are internal, labels are shown in the UI.
Config.JobAccounts = {
    { name = 'money',       label = 'Cash' },
    { name = 'black_money', label = 'Black Money' },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Interaction (ox_target + peds)
-- ─────────────────────────────────────────────────────────────────────────────

--- Use ox_target for every job point. When false, ox_lib textUI + [E] is used.
Config.UseTarget = true

--- Spawn a clerk ped at every job point that defines `ped` in config/jobs.lua.
--- Peds are only created when you are within Config.PedRenderDistance and are
--- destroyed again when you walk away, change job or the resource stops.
Config.UsePeds = true
Config.PedRenderDistance = 40.0

--- Default appearance for job peds. Individual points may override any of these
--- by setting `ped = { model = ..., scenario = ... }` in config/jobs.lua.
Config.DefaultPed = {
    model    = 's_m_m_ammucountry',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    freeze   = true,
    invincible = true,
    ignore   = true, -- ped ignores all events (no reacting to guns/crashes)
}

--- Distance for ox_target interaction and for the non-target [E] prompt.
Config.InteractDistance = 2.0

-- ─────────────────────────────────────────────────────────────────────────────
-- Interaction menu (the /interaction command)
-- ─────────────────────────────────────────────────────────────────────────────

Config.EnableInteractions = false
Config.InteractionCommand = 'interaction'
Config.InteractionKey     = 'F6'

-- ─────────────────────────────────────────────────────────────────────────────
-- Images / branding
-- ─────────────────────────────────────────────────────────────────────────────

Config.Logo = 'https://forum.cfx.re/uploads/default/original/4X/b/1/9/b196908c7e5dfcd60aa9dca0020119fa55e184cb.png'

--- Item images. ox_inventory serves them from its own web folder.
Config.ItemImageUrl = 'nui://ox_inventory/web/images/'

--- Vehicle images. Anything ending in <model>.png works.
Config.VehicleImageUrl = 'https://raw.githubusercontent.com/renzuzu/carmap/main/carmap/vehicle/'

--- Shown when an image 404s.
Config.FallbackImage = 'https://raw.githubusercontent.com/renzuzu/carmap/main/carmap/items/placeholder.png'

-- ─────────────────────────────────────────────────────────────────────────────
-- Job garage
-- ─────────────────────────────────────────────────────────────────────────────

Config.Garage = {
    --- Fee charged to the player when a job vehicle is missing in the world and
    --- has to be recovered. Set to 0 to make recovery free.
    recoveryFee = 500,

    --- Paid out of the JOB treasury instead of the player's pocket.
    recoveryFromJobFunds = false,

    --- Hand a key item to whoever takes the vehicle out.
    giveKeys = true,

    --- Remove the key again when the vehicle is stored.
    removeKeysOnStore = true,

    --- Only the employee who took a vehicle out (or a grade >= this) may store it
    --- back in. Set to 0 to let anyone in the job store any job vehicle.
    storeAnyoneGrade = 0,

    --- Vehicles left outside are automatically returned to the garage after this
    --- many minutes of nobody driving them. 0 disables the cleanup.
    autoReturnMinutes = 30,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Paycheck
-- ─────────────────────────────────────────────────────────────────────────────

--- renzu_jobs can run its own paycheck that pays employees out of the job
--- treasury, which is what makes the salary manager in the boss menu meaningful.
--- LEAVE THIS OFF unless you disabled the qbx_core paycheck, otherwise players
--- get paid twice.
Config.Paycheck = {
    enabled         = false,
    intervalMinutes = 10,
    --- Pay from the job treasury (true) or print new money (false).
    fromJobFunds    = true,
    --- Account the salary lands in.
    account         = 'bank',
    --- Only pay employees that are clocked in.
    requireDuty     = true,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Crafting
-- ─────────────────────────────────────────────────────────────────────────────

Config.Crafting = {
    --- Cancelling the ox_lib progress bar refunds the ingredients.
    refundOnCancel = true,
    --- Player must stay near the crafting bench for the whole duration.
    maxDistance = 5.0,
    --- Animation played while crafting.
    anim = { dict = 'amb@prop_human_parking_meter@male@base', clip = 'base' },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Notifications
-- ─────────────────────────────────────────────────────────────────────────────

Config.Notify = {
    position = 'top-right',
    duration = 5000,
    --- Show a bigger, longer notification for server-wide announcements.
    announceDuration = 9000,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Discord logging
--
-- Webhook urls live in server/logging.lua, NOT here. This file is a
-- shared_script, so anything in it is downloaded by every client - a webhook
-- url in a shared file is a webhook url anyone can spam.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- Misc
-- ─────────────────────────────────────────────────────────────────────────────

--- Job assigned to somebody who gets fired.
Config.DefaultJob = 'unemployed'

--- ace permission required for /jobcreator.
Config.AdminGroups = { 'admin', 'god' }

--- Avatar colours used for the employee list when a player has no pedshot.
Config.RandomAvatars = {
    { background = 'ffffff', color = '308BFF' },
    { background = 'E2E519', color = '222222' },
    { background = 'FF306E', color = 'ffffff' },
    { background = 'F000FF', color = 'ffffff' },
    { background = '2F2730', color = 'ffffff' },
}

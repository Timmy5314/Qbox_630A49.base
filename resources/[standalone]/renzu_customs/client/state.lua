--[[
    renzu_customs :: shared client state
    Every client file attaches to this single table instead of leaking globals.
]]

---@class CarriedPart
---@field key string|number key inside Config.VehicleMod
---@field level integer      level of the part (1 = first upgrade)
---@field item string        inventory key, e.g. "spoiler-2"
---@field object integer     prop entity currently attached to the ped
---@field fromStock boolean  true when it came from a car instead of the shop stock

Customs = {
    --- qbx player data
    playerData = {},
    loaded = false,

    --- id of the shop the player is currently standing in (nil when outside)
    shop = nil,

    --- tuning menu
    inMenu = false,
    freeMode = false,
    oldProps = nil,
    vehicle = nil,
    vehicleValue = 0,

    --- camera
    cam = nil,
    camView = nil,

    --- part carrying / spraying
    ---@type CarriedPart?
    carrying = nil,
    spraying = false,
    sprayCan = nil,
    paintColor = nil,
    customPaintDone = nil,

    --- shop id the current tuning session belongs to
    shopSession = nil,

    --- handling.min.json, loaded once on start
    handling = nil,

    --- ox_target zone handles so we can clean them up on resource stop
    zones = {},
    blips = {},

    --- cache of engine sounds already forced onto a vehicle
    engineAudio = {},
}

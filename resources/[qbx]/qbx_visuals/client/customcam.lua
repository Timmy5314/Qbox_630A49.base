--[[
    qbx_visuals - eigen first-person camera (optioneel, standaard uit)

    Dit is het antwoord op "kan het hoofd niet gewoon uit, en de FOV hoger?".
    Ja, dat kan, en zo werkt het:

    Een eigen camera (CreateCam) geeft wel volledige controle over de FOV, maar
    GTA verwijdert je hoofd alleen in de ECHTE first-person modus. Bij een eigen
    camera moet je dat zelf doen. Twee manieren, allebei ingebouwd:

      1. Near clip - alles dichter bij de camera dan die afstand wordt
         weggeknipt. Je hoofd valt daarbinnen, je armen en lichaam niet.
         Dit is de aanrader.
      2. SetEntityLocallyInvisible - verbergt je hele ped, alleen voor jezelf.
         Werkt gegarandeerd, maar dan zie je ook je armen op het stuur niet.

    De camera hangt aan de hoofdbot voor de POSITIE; de rotatie komt van de
    gameplay-camera, zodat muisbesturing gewoon blijft werken.

    Wat je hiermee inlevert: richten en drive-by werken niet goed op een eigen
    camera. Daarom springt hij standaard terug naar de echte camera zodra je
    richt, en staat hij standaard alleen in voertuigen aan.
]]

local cc = Config.FirstPerson.customCam

local SKEL_HEAD <const> = 0x796E -- 31086

local cam         = nil
local attachedPed = nil

-- ---------------------------------------------------------------------------
-- Camera aan en uit
-- ---------------------------------------------------------------------------

local function destroyCam()
    if not cam then return end

    RenderScriptCams(false, false, 0, true, true)
    if DoesCamExist(cam) then DestroyCam(cam, false) end

    cam         = nil
    attachedPed = nil
    QV.state.customCamActive = false
end

local function createCam(ped)
    destroyCam()

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, cc.fov + 0.0)

    -- Zo verdwijnt het hoofd: het valt binnen het near plane.
    SetCamNearClip(cam, cc.nearClip + 0.0)

    -- Let op: AttachCamToPedBone (niet de Hard-variant) koppelt alleen de
    -- POSITIE. De rotatie houden we vrij zodat SetCamRot hem elke frame op de
    -- gameplay-camera kan zetten. Met HardAttach zou de camera met de
    -- hoofdanimatie meedraaien, en daar word je misselijk van.
    AttachCamToPedBone(cam, ped, GetPedBoneIndex(ped, SKEL_HEAD),
        cc.offset.x + 0.0, cc.offset.y + 0.0, cc.offset.z + 0.0, true)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    attachedPed = ped
    QV.state.customCamActive = true
    QV.debug('eigen camera aan (fov %.1f, nearclip %.2f)', cc.fov, cc.nearClip)
end

-- ---------------------------------------------------------------------------
-- Wanneer wel, wanneer niet
-- ---------------------------------------------------------------------------

local function wanted()
    if not cc.enabled then return false end

    -- Alleen als first person daadwerkelijk afgedwongen wordt. Een admin of
    -- iemand in derde persoon krijgt geen hoofdcamera.
    if not QV.state.fpActive then return false end

    local ped = PlayerPedId()

    if cc.releaseWhenAiming then
        if IsAimCamActive() or IsPlayerFreeAiming(PlayerId()) or IsPedDoingDriveby(ped) then
            return false
        end
    end

    if IsPedInAnyVehicle(ped, false) then
        return cc.contexts.inVehicle
    end

    return cc.contexts.onFoot
end

-- ---------------------------------------------------------------------------
-- Per frame, aangeroepen vanuit render.lua zodat er maar een Wait(0)-thread is
-- ---------------------------------------------------------------------------

function QV.customCamTick()
    if not cam then return end

    -- Rotatie van de gameplay-camera overnemen: muis- en controllerbesturing
    -- blijven zo gewoon werken.
    local rot = GetGameplayCamRot(2)
    SetCamRot(cam, rot.x, rot.y, rot.z, 2)

    if cc.hidePed then
        -- Deze native geldt per frame, vandaar hier.
        SetEntityLocallyInvisible(PlayerPedId())
    end
end

-- ---------------------------------------------------------------------------
-- Trage loop: bepaalt alleen of de camera aan of uit moet
-- ---------------------------------------------------------------------------

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end

    while true do
        local sleep = 250

        -- Niet vroegtijdig stoppen als hij uit staat: /gfx cam kan hem
        -- tijdens de sessie alsnog aanzetten.
        if not cc.enabled then
            if cam then destroyCam() end
            sleep = 1000
        elseif wanted() then
            local ped = PlayerPedId()
            -- Na een respawn of modelwissel is de koppeling weg.
            if not cam or attachedPed ~= ped then
                createCam(ped)
            end
        elseif cam then
            destroyCam()
        end

        Wait(sleep)
    end
end)

-- ---------------------------------------------------------------------------
-- Live aanpassen om af te stellen
-- ---------------------------------------------------------------------------

function QV.setCustomCamFov(value)
    local number = tonumber(value)
    if not number then return false end

    cc.fov = number + 0.0
    if cam and DoesCamExist(cam) then SetCamFov(cam, cc.fov) end
    return true
end

function QV.setCustomCamNearClip(value)
    local number = tonumber(value)
    if not number then return false end

    cc.nearClip = number + 0.0
    if cam and DoesCamExist(cam) then SetCamNearClip(cam, cc.nearClip) end
    return true
end

function QV.toggleCustomCam(state)
    if state == nil then state = not cc.enabled end
    cc.enabled = state and true or false
    if not cc.enabled then destroyCam() end
    return cc.enabled
end

exports('setCustomCamFov', function(v) return QV.setCustomCamFov(v) end)
exports('toggleCustomCam', function(v) return QV.toggleCustomCam(v) end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    destroyCam()
end)

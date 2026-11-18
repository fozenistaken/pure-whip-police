local NECK = 39317
local LOOK = 4.0
local feed = nil

local function stop()
    if not feed then return end
    local f = feed
    feed = nil
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(f.cam, false)
    ClearFocus()
    ClearTimecycleModifier()
    Whip.core:HideText()
    TriggerServerEvent(PWP.event('unwatch'))
end

local function overlay(f, warn)
    local text = ('%s · %s | %02d:%02d:%02d%s · [Backspace] leave'):format(
        f.kind == 'cam' and ('CAM %02d'):format(f.id) or 'BODY CAM', warn or f.label,
        GetClockHours(), GetClockMinutes(), GetClockSeconds(), f.kind == 'cam' and ' · [Q] [E] camera' or '')
    Whip.core:ShowText(text, { position = 'top', icon = 'camera', tone = warn and 'warn' or nil })
end

local function switch(step)
    local f = feed
    if not f or f.kind ~= 'cam' or f.count < 2 then return end
    local nextId = (f.id - 1 + step) % f.count + 1
    CreateThread(function()
        local ok, why = Whip.core:Callback(PWP.RES .. ':mdt:watch', { kind = 'cam', id = nextId })
        if not ok then Whip.core:Notify(tostring(why or 'That camera is dark'), 'error') end
    end)
end

local function targetPed(f)
    local p = GetPlayerFromServerId(f.target)
    if p == -1 then return nil end
    local ped = GetPlayerPed(p)
    return DoesEntityExist(ped) and ped or nil
end

local function run(f)
    local lost = 0
    while feed == f do
        DisableAllControlActions(0)
        if f.kind == 'cam' then
            f.yaw = f.yaw - GetDisabledControlNormal(0, 1) * LOOK
            f.pitch = math.max(-75.0, math.min(15.0, f.pitch - GetDisabledControlNormal(0, 2) * LOOK))
            f.yaw = math.max(f.heading - 70.0, math.min(f.heading + 70.0, f.yaw))
            if IsDisabledControlJustPressed(0, 241) then f.fov = math.max(15.0, f.fov - 5.0) end
            if IsDisabledControlJustPressed(0, 242) then f.fov = math.min(90.0, f.fov + 5.0) end
            SetCamRot(f.cam, f.pitch, 0.0, f.yaw, 2)
            SetCamFov(f.cam, f.fov)
            if IsDisabledControlJustPressed(0, 44) then switch(-1) end
            if IsDisabledControlJustPressed(0, 38) then switch(1) end
        else
            local ped = targetPed(f)
            if ped then
                lost = 0
                if f.attached ~= ped then
                    AttachCamToPedBone(f.cam, ped, GetPedBoneIndex(ped, NECK), 0.0, 0.11, 0.06, true)
                    SetFocusEntity(ped)
                    f.attached = ped
                end
                SetCamRot(f.cam, -6.0, 0.0, GetEntityHeading(ped), 2)
            else
                lost = lost + 1
                if lost == 1 then overlay(f, 'No signal') end
                if lost > 300 then return stop() end
            end
        end
        if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 202) or IsEntityDead(PlayerPedId()) then
            return stop()
        end
        if GetGameTimer() >= f.tick then
            f.tick = GetGameTimer() + 1000
            if lost == 0 then overlay(f) end
        end
        Wait(0)
    end
end

RegisterNetEvent(PWP.event('feed'), function(spec)
    if type(spec) ~= 'table' then return end
    local switching = feed ~= nil
    if feed then
        local old = feed
        feed = nil
        DestroyCam(old.cam, false)
    end
    if not switching then
        if GetResourceState('whip_phone') == 'started' then exports.whip_phone:Close() end
        DoScreenFadeOut(200)
        Wait(220)
    end
    local f = { kind = spec.kind, id = spec.id, label = spec.label, target = spec.target, count = spec.count or 1, tick = 0 }
    f.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    if f.kind == 'cam' then
        local c = spec.coords
        f.heading, f.yaw, f.pitch, f.fov = spec.heading + 0.0, spec.heading + 0.0, spec.pitch + 0.0, spec.fov + 0.0
        SetCamCoord(f.cam, c.x, c.y, c.z)
        SetCamRot(f.cam, f.pitch, 0.0, f.yaw, 2)
        SetCamFov(f.cam, f.fov)
        SetFocusPosAndVel(c.x, c.y, c.z, 0.0, 0.0, 0.0)
    else
        SetCamFov(f.cam, 75.0)
    end
    SetTimecycleModifier('helicamfirst')
    SetTimecycleModifierStrength(0.7)
    RenderScriptCams(true, false, 0, true, false)
    feed = f
    overlay(f)
    if not switching then DoScreenFadeIn(250) end
    run(f)
end)

AddEventHandler('whip_core:job:clockedOn', function()
    if Config.Feeds.bodycam and GetResourceState('bodycam') == 'started' and PWP.isDept(LocalPlayer.state.whipJob) then
        exports.bodycam:SetEnabled(true)
    end
end)

AddEventHandler('whip_core:job:clockedOff', function()
    if Config.Feeds.bodycam and GetResourceState('bodycam') == 'started' then exports.bodycam:SetEnabled(false) end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and feed then
        RenderScriptCams(false, false, 0, true, false)
        ClearFocus()
        ClearTimecycleModifier()
    end
end)

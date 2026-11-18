local MODEL = joaat('pwp_wheel_clamp')
local CLAMP = PWP.name('clamp')
local props = {}

local function send(ctx, how)
    local id = ctx.entity and Whip.core:GetVehicleId(ctx.entity)
    if not id then return Whip.core:Notify('That car is not registered', 'error') end
    TriggerServerEvent(PWP.event('policecar'), id, how)
end

local function fit(veh)
    if not HasModelLoaded(MODEL) then
        RequestModel(MODEL)
        return
    end
    local bone = GetEntityBoneIndexByName(veh, 'wheel_lf')
    if bone == -1 then return end
    local off = GetOffsetFromEntityGivenWorldCoords(veh, GetWorldPositionOfEntityBone(veh, bone))
    local obj = CreateObjectNoOffset(MODEL, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(obj, false, false)
    AttachEntityToEntity(obj, veh, 0, off.x, off.y, off.z, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
    props[veh] = obj
end

local function sweep()
    local me = PlayerPedId()
    local here = GetEntityCoords(me)
    for veh, obj in pairs(props) do
        if not DoesEntityExist(veh) or not Entity(veh).state.pwpClamp then
            if DoesEntityExist(obj) then DeleteObject(obj) end
            props[veh] = nil
        end
    end
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if Entity(veh).state.pwpClamp and not props[veh] and #(GetEntityCoords(veh) - here) < 80.0 then fit(veh) end
    end
    local veh = GetVehiclePedIsIn(me, false)
    if veh ~= 0 and props[veh] and GetPedInVehicleSeat(veh, -1) == me then SetVehicleHandbrake(veh, true) end
end

CreateThread(function()
    while true do
        Wait(1500)
        sweep()
    end
end)

Whip.register(function()
    Whip.core:AddAction({
        id = PWP.name('policecar'),
        at = { vehiclePart = 'door_dside_f' },
        label = 'Police',
        options = {
            { id = 'clamp', label = 'Clamp a wheel', require = { job = PWP.deptKeys(), onDuty = true, item = CLAMP } },
            { id = 'unclamp', label = 'Remove the clamp', require = { job = PWP.deptKeys(), onDuty = true } },
            { id = 'impound', label = 'Impound', require = { job = PWP.deptKeys(), onDuty = true } },
        },
        onSelect = function(ctx) send(ctx, ctx.option) end,
    })
    Whip.core:AddAction({
        id = PWP.name('clampcut'),
        at = { vehiclePart = 'door_dside_f' },
        label = 'Wheel clamp',
        options = { { id = 'cut', label = 'Cut the clamp', require = { item = 'lockpick' } } },
        canInteract = function(ctx) return ctx.entity and Entity(ctx.entity).state.pwpClamp == true end,
        onSelect = function(ctx) send(ctx, 'cut') end,
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, obj in pairs(props) do if DoesEntityExist(obj) then DeleteObject(obj) end end
end)

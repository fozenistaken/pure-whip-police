local PIECES = {
    { model = joaat('pwp_wheel_clamp'), radiiUp = 0 },
    { model = joaat('pwp_wheel_clamp_top'), radiiUp = 1 },
    { model = joaat('pwp_wheel_clamp_arm'), radiiUp = -1 },
}
local CLAMP = PWP.name('clamp')
local props = {}

local function send(ctx, how)
    local id = ctx.entity and Whip.core:GetVehicleId(ctx.entity)
    if not id then return Whip.core:Notify('That car is not registered', 'error') end
    TriggerServerEvent(PWP.event('policecar'), id, how)
end

local function remove(objs)
    for _, obj in ipairs(objs) do if DoesEntityExist(obj) then DeleteObject(obj) end end
end

local function fit(veh)
    local ready = true
    for _, p in ipairs(PIECES) do
        if not HasModelLoaded(p.model) then RequestModel(p.model) ready = false end
    end
    if not ready then return end
    local bone = GetEntityBoneIndexByName(veh, 'wheel_lf')
    if bone == -1 then return end
    local off = GetOffsetFromEntityGivenWorldCoords(veh, GetWorldPositionOfEntityBone(veh, bone))
    local radius = GetVehicleWheelTireColliderSize(veh, 0)
    local x = off.x - GetVehicleWheelTireColliderWidth(veh, 0) / 2
    local objs = {}
    for i, p in ipairs(PIECES) do
        local obj = CreateObjectNoOffset(p.model, 0.0, 0.0, 0.0, false, false, false)
        SetEntityCollision(obj, false, false)
        AttachEntityToEntity(obj, veh, 0, x, off.y, off.z + p.radiiUp * radius, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
        objs[i] = obj
    end
    props[veh] = objs
end

local function sweep()
    local me = PlayerPedId()
    local here = GetEntityCoords(me)
    for veh, objs in pairs(props) do
        if not DoesEntityExist(veh) or not Entity(veh).state.pwpClamp then
            remove(objs)
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

RegisterNetEvent(PWP.event('impoundForm'), function(form)
    if type(form) ~= 'table' then return end
    CreateThread(function()
        local _, why = exports.whip_phone:RunApp('pwpmdt', { impound = form })
        if why and why ~= 'busy' then Whip.core:Notify('MDT: ' .. tostring(why), 'error') end
    end)
end)

RegisterCommand('mdtimpound', function()
    local me = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(GetEntityCoords(veh) - me)
        if d <= 6.0 and (not bestDist or d < bestDist) then best, bestDist = veh, d end
    end
    local id = best and Whip.core:GetVehicleId(best)
    if not id then return Whip.core:Notify('Stand next to the car', 'error') end
    TriggerServerEvent(PWP.event('policecar'), id, 'impound')
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, objs in pairs(props) do remove(objs) end
end)

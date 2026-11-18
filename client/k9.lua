local C = Config.K9
local SIT = { dict = 'creatures@rottweiler@amb@world_dog_sitting@base', clip = 'base' }
local dog = nil
local busy = false

local function load(kind, name)
    if kind == 'model' then
        local m = joaat(name)
        RequestModel(m)
        local tries = 0
        while not HasModelLoaded(m) and tries < 100 do Wait(20); tries = tries + 1 end
        return HasModelLoaded(m) and m or nil
    end
    RequestAnimDict(name)
    local tries = 0
    while not HasAnimDictLoaded(name) and tries < 100 do Wait(20); tries = tries + 1 end
    return HasAnimDictLoaded(name)
end

local function sendHome()
    if dog and DoesEntityExist(dog) then DeleteEntity(dog) end
    dog = nil
end

local function follow()
    if not dog then return end
    ClearPedTasks(dog)
    SetPedAsGroupMember(dog, GetPedGroupIndex(PlayerPedId()))
    SetPedNeverLeavesGroup(dog, true)
end

local function sit()
    if not dog or not load('dict', SIT.dict) then return end
    RemovePedFromGroup(dog)
    ClearPedTasks(dog)
    TaskPlayAnim(dog, SIT.dict, SIT.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

local function watch(d)
    while dog == d do
        Wait(1000)
        if not DoesEntityExist(d) then dog = nil return end
        if IsEntityDead(d) then
            TriggerServerEvent(PWP.event('k9down'))
            Whip.core:Notify('Your dog is hurt and goes home to rest', 'error')
            return sendHome()
        end
        if not PWP.isDept(LocalPlayer.state.whipJob) then return sendHome() end
    end
end

local function call()
    if dog then return Whip.core:Notify('Your dog is already with you', 'info') end
    local ok, why = Whip.core:Callback(PWP.event('k9'))
    if not ok then return Whip.core:Notify(tostring(why or 'No dog for you'), 'error') end
    local model = load('model', C.model)
    if not model then return Whip.core:Notify('The dog model is missing', 'error') end
    local me = PlayerPedId()
    local c = GetOffsetFromEntityInWorldCoords(me, 0.0, -1.5, 0.0)
    local d = CreatePed(28, model, c.x, c.y, c.z, GetEntityHeading(me), true, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(d, true, true)
    SetPedRelationshipGroupHash(d, GetPedRelationshipGroupHash(me))
    SetBlockingOfNonTemporaryEvents(d, true)
    SetEntityInvincible(d, C.protected == true)
    dog = d
    follow()
    CreateThread(function() watch(d) end)
end

local function inFront(range, list)
    local me = PlayerPedId()
    local here, fwd = GetEntityCoords(me), GetEntityForwardVector(me)
    local best, bestD = nil, range
    for _, e in ipairs(list) do
        if e ~= me and e ~= dog then
            local to = GetEntityCoords(e) - here
            local d = #to
            if d < bestD and d > 0.1 and (to.x * fwd.x + to.y * fwd.y) / d > 0.5 then best, bestD = e, d end
        end
    end
    return best
end

local function playerOf(ped)
    for _, p in ipairs(GetActivePlayers()) do
        if GetPlayerPed(p) == ped then return GetPlayerServerId(p) end
    end
    return nil
end

local function personTarget(range)
    local peds = {}
    for _, p in ipairs(GetActivePlayers()) do peds[#peds + 1] = GetPlayerPed(p) end
    local ped = inFront(range, peds)
    return ped, ped and playerOf(ped)
end

local function sniff()
    if not dog or busy then return end
    local ped, target = personTarget(6.0)
    local veh = not ped and inFront(8.0, GetGamePool('CVehicle')) or nil
    if not ped and not veh then return Whip.core:Notify('Face a person or a car for the dog to search', 'error') end
    busy = true
    RemovePedFromGroup(dog)
    TaskGoToEntity(dog, ped or veh, 6000, 1.2, 2.0, 0, 0)
    local t = GetGameTimer() + 6000
    while dog and GetGameTimer() < t and #(GetEntityCoords(dog) - GetEntityCoords(ped or veh)) > 2.2 do Wait(100) end
    if not dog then busy = false return end
    TaskTurnPedToFaceEntity(dog, ped or veh, C.sniffSeconds * 1000)
    Wait(C.sniffSeconds * 1000)
    local r, why
    if ped then
        r, why = Whip.core:Callback(PWP.event('k9person'), target)
    else
        local id = Whip.core:GetVehicleId(veh)
        if id then r, why = Whip.core:Callback(PWP.event('k9car'), id) else why = 'The dog loses interest' end
    end
    busy = false
    if not r then follow() return Whip.core:Notify(tostring(why or 'The dog finds nothing'), 'error') end
    if r.hit then
        sit()
        local where = r.where == 'pockets' and 'them' or ('the ' .. r.where)
        Whip.core:Notify(('The dog sits by %s: it smells something.'):format(where), 'warning', 7000)
        SetTimeout(6000, follow)
    else
        Whip.core:Notify('The dog finds nothing', 'info')
        follow()
    end
end

local function attack()
    if not dog then return end
    local ped, target = personTarget(40.0)
    if not ped then return Whip.core:Notify('Face the person to send the dog at', 'error') end
    local ok, why = Whip.core:Callback(PWP.event('k9attack'), target)
    if not ok then return Whip.core:Notify(tostring(why or 'The dog stays'), 'error') end
    RemovePedFromGroup(dog)
    TaskCombatPed(dog, ped, 0, 16)
    SetTimeout(20000, function() if dog and not busy then follow() end end)
end

local ORDERS = { call = call, home = sendHome, follow = follow, stay = sit, sniff = sniff, attack = attack }

Whip.register(function()
    Whip.core:AddAction({
        id = PWP.name('k9'),
        at = { radial = true },
        label = 'K9',
        icon = 'target',
        require = { job = PWP.deptKeys(), onDuty = true },
        options = {
            { id = 'call', label = 'Call the dog' },
            { id = 'follow', label = 'Heel' },
            { id = 'stay', label = 'Sit and stay' },
            { id = 'sniff', label = 'Search' },
            { id = 'attack', label = 'Take them down' },
            { id = 'home', label = 'Send home' },
        },
        onSelect = function(ctx)
            local fn = ORDERS[ctx.option]
            if fn then CreateThread(fn) end
        end,
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then sendHome() end
end)

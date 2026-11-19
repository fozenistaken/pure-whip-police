local RAD = Config.Radar
local LANE = 6.0
local HIT_MS = 8000
local on, locked = false, false
local shown = {}
local sent, sentCount = {}, 0
local hit = nil
local lastText = nil

local function targets(veh)
    local offsets = {}
    for _, other in ipairs(GetGamePool('CVehicle')) do
        if other ~= veh then
            local o = GetOffsetFromEntityGivenWorldCoords(veh, GetEntityCoords(other))
            offsets[#offsets + 1] = { x = o.x, y = o.y, z = o.z, item = other }
        end
    end
    return PWP.Radar.pick(offsets, RAD.range, LANE)
end

local function read(t)
    if not t then return nil end
    local plate = (GetVehicleNumberPlateText(t.item) or ''):gsub('^%s+', ''):gsub('%s+$', '')
    return { veh = t.item, plate = plate, speed = math.floor(GetEntitySpeed(t.item) * PWP.Radar.factor(RAD.unit) + 0.5) }
end

local function report(r)
    if not r or r.plate == '' or not NetworkGetEntityIsNetworked(r.veh) then return end
    local now = GetGameTimer()
    if sent[r.plate] and now - sent[r.plate] < RAD.seenSeconds * 1000 then return end
    if sentCount > 300 then sent, sentCount = {}, 0 end
    sent[r.plate], sentCount = now, sentCount + 1
    TriggerServerEvent(PWP.event('plate'), NetworkGetNetworkIdFromEntity(r.veh))
end

local function line(label, r)
    if not r then return label .. ' none' end
    return ('%s %d %s · %s'):format(label, r.speed, PWP.Radar.unitName(RAD.unit), r.plate)
end

local function draw()
    local warn = hit and GetGameTimer() < hit.untilMs
    local title = warn and ('%s · %s'):format(hit.plate, hit.why) or line('Front', shown.front)
    local rest = (warn and line('Front', shown.front) .. ' · ' or '') .. line('Rear', shown.rear)
        .. (locked and ' · Locked' or '')
    local text = title .. ' | ' .. rest
    if text == lastText then return end
    lastText = text
    Whip.core:ShowText(text, { position = 'top', icon = 'target', tone = warn and 'warn' or nil })
end

local function stop()
    on, locked, shown, lastText, hit = false, false, {}, nil, nil
    Whip.core:HideText()
end

local function run()
    while on do
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh == 0 or not PWP.isDept(LocalPlayer.state.whipJob) then return stop() end
        if not locked then
            local t = targets(veh)
            shown.front, shown.rear = read(t.front), read(t.rear)
            report(shown.front)
            report(shown.rear)
        end
        draw()
        Wait(RAD.readMs)
    end
end

local function toggle()
    if on then return stop() end
    if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then return Whip.core:Notify('Get in a car first', 'error') end
    if not PWP.isDept(LocalPlayer.state.whipJob) then return Whip.core:Notify('Go on duty first', 'error') end
    on = true
    CreateThread(run)
end

RegisterCommand('pwp_radar', toggle, false)
RegisterKeyMapping('pwp_radar', 'Police: radar on or off', 'keyboard', '')

RegisterCommand('pwp_radarlock', function()
    if not on then return end
    locked = not locked
    local r = shown.front or shown.rear
    if locked and r and r.plate ~= '' then
        PWP.RadarLock = { plate = r.plate, speed = r.speed, unit = PWP.Radar.unitName(RAD.unit), at = GetGameTimer() }
    end
    draw()
end, false)
RegisterKeyMapping('pwp_radarlock', 'Police: lock the radar reading', 'keyboard', '')

RegisterNetEvent(PWP.event('plateHit'), function(plate, why)
    hit = { plate = tostring(plate), why = tostring(why), untilMs = GetGameTimer() + HIT_MS }
    if on then draw() end
end)

Whip.register(function()
    Whip.core:AddAction({
        id = PWP.name('radar'),
        at = { radial = true },
        label = 'Radar',
        icon = 'target',
        require = { job = PWP.deptKeys(), onDuty = true, vehicle = 'in' },
        onSelect = toggle,
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and on then Whip.core:HideText() end
end)

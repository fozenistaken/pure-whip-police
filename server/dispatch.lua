local STATUSES = { available = true, enroute = true, onscene = true, busy = true }
local CALLSIGN = PWP.name('callsign')

local Dispatch = { alerts = {}, nextId = 0, units = {}, lastShot = {}, lastCall = {} }
PWP.Dispatch = Dispatch

local function provider()
    local res = Config.Providers.dispatch
    if res and res ~= 'builtin' then
        if GetResourceState(res) == 'started' then return res end
        print(('[%s] dispatch provider %s is not started: using the built-in dispatch'):format(PWP.RES, res))
    end
    return nil
end

local function phone(src, n)
    if GetResourceState('whip_phone') == 'started' then exports.whip_phone:Notify(src, n) end
end

local function push(src, event, data)
    if GetResourceState('whip_phone') == 'started' and Config.Providers.mdt == 'builtin' then
        exports.whip_phone:Push(src, 'pwpmdt', event, data)
    end
end

local function recipients(jobs)
    local list, seen = {}, {}
    for _, job in ipairs(jobs) do
        for _, e in ipairs(Whip.core:GetClockedOnEmployees(job) or {}) do
            if e.source and not seen[e.source] then seen[e.source] = true; list[#list + 1] = e.source end
        end
    end
    return list
end

local function view(a)
    local responders = {}
    for src in pairs(a.responders) do responders[#responders + 1] = { source = src, callsign = Dispatch.callsign(src) } end
    return { id = a.id, code = a.code, title = a.title, info = a.info, coords = { x = a.coords.x, y = a.coords.y, z = a.coords.z },
        priority = a.priority, jobs = a.jobs, createdAt = a.createdAt, expiresAt = a.expiresAt, responders = responders,
        maxResponders = a.maxResponders }
end

function Dispatch.callsign(src)
    return Whip.core:GetPlayerFlag(src, CALLSIGN) or ('#' .. tostring(src))
end

function Dispatch.send(alert)
    if type(alert) ~= 'table' then return false, 'an alert is a table' end
    local res = provider()
    if res then return exports[res]:SendAlert(alert) end
    local jobs = type(alert.jobs) == 'table' and alert.jobs or (alert.jobs and { alert.jobs }) or PWP.deptKeys()
    local c = alert.coords
    if not c or not tonumber(c.x) or not tonumber(c.y) then return false, 'an alert needs coords' end
    Dispatch.nextId = Dispatch.nextId + 1
    local now = os.time()
    local a = {
        id = Dispatch.nextId, jobs = jobs,
        code = PWP.Text.clean(alert.code, 12) or '10-00',
        title = PWP.Text.clean(alert.title, 60) or 'Call',
        info = {}, coords = vector3(c.x + 0.0, c.y + 0.0, (tonumber(c.z) or 0.0) + 0.0),
        priority = alert.priority == 'high' and 'high' or 'normal',
        maxResponders = math.max(1, math.min(20, math.floor(tonumber(alert.maxResponders) or Config.Dispatch.maxResponders))),
        createdAt = now,
        expiresAt = now + math.max(30, math.min(3600, math.floor(tonumber(alert.duration) or Config.Dispatch.duration))),
        responders = {},
    }
    for i, line in ipairs(type(alert.info) == 'table' and alert.info or {}) do
        if i > 6 then break end
        a.info[#a.info + 1] = PWP.Text.clean(tostring(line), 120)
    end
    Dispatch.alerts[a.id] = a
    local people = recipients(jobs)
    if #people > 0 then
        Whip.core:ShowBlip({ people = people }, 'alert_' .. a.id, {
            coords = a.coords, label = ('%s %s'):format(a.code, a.title), sprite = a.priority == 'high' and 526 or 161,
            color = a.priority == 'high' and 1 or 5, flash = a.priority == 'high', scale = 1.1,
        })
    end
    local v = view(a)
    for _, src in ipairs(people) do
        phone(src, { app = 'pwpmdt', title = ('%s %s'):format(a.code, a.title), text = a.info[1] or '',
            kind = a.priority == 'high' and 'command' or 'chat', args = { alert = a.id } })
        push(src, 'alert', v)
    end
    TriggerEvent(PWP.event('alert'), v)
    return a.id
end

function Dispatch.clear(id)
    local a = Dispatch.alerts[tonumber(id)]
    if not a then return false, 'No such call' end
    Dispatch.alerts[a.id] = nil
    Whip.core:HideBlip('alert_' .. a.id)
    for src in pairs(a.responders) do Whip.core:HideBlip(('route_%d_%d'):format(a.id, src)) end
    for _, src in ipairs(recipients(a.jobs)) do push(src, 'alertCleared', { id = a.id }) end
    return true
end

function Dispatch.list(job)
    local out = {}
    for _, a in pairs(Dispatch.alerts) do
        local match = not job
        for _, j in ipairs(a.jobs) do if j == job then match = true end end
        if match then out[#out + 1] = view(a) end
    end
    table.sort(out, function(x, y) return x.id > y.id end)
    return out
end

function Dispatch.setStatus(src, status, alertId)
    if not STATUSES[status] then return false, 'Unknown status' end
    Dispatch.units[src] = { status = status, alert = alertId, at = os.time() }
    TriggerEvent(PWP.event('unitStatus'), { source = src, status = status, alert = alertId })
    return true
end

function Dispatch.units_()
    local out = {}
    for _, o in ipairs(PWP.onDutyOfficers() or {}) do
        local u = Dispatch.units[o.source] or { status = 'available' }
        out[#out + 1] = { source = o.source, charId = o.charId, dept = o.dept, callsign = Dispatch.callsign(o.source),
            status = u.status, alert = u.alert }
    end
    return out
end

function Dispatch.attach(src, id)
    local a = Dispatch.alerts[tonumber(id)]
    if not a then return false, 'That call is over' end
    if a.responders[src] then return true end
    local n = 0
    for _ in pairs(a.responders) do n = n + 1 end
    if n >= a.maxResponders then return false, 'Enough units are on it' end
    a.responders[src] = true
    Dispatch.setStatus(src, 'enroute', a.id)
    Whip.core:ShowBlip({ people = { src } }, ('route_%d_%d'):format(a.id, src),
        { coords = a.coords, label = ('%s %s'):format(a.code, a.title), sprite = 1, color = 3, route = true })
    return true
end

function Dispatch.detach(src, id)
    local a = Dispatch.alerts[tonumber(id)]
    if a then a.responders[src] = nil end
    Whip.core:HideBlip(('route_%d_%d'):format(tonumber(id) or 0, src))
    return Dispatch.setStatus(src, 'available')
end

local function panic(src)
    local dept = PWP.Depts.ofSource(src)
    if not dept then return false, 'You are not on duty' end
    local jobs = PWP.deptKeys()
    for _, j in ipairs(Config.Dispatch.panicJobs or {}) do jobs[#jobs + 1] = j end
    local pos = GetEntityCoords(GetPlayerPed(src))
    local id = Dispatch.send({ jobs = jobs, code = '10-99', title = 'Officer needs help', priority = 'high',
        coords = pos, info = { ('%s %s'):format(PWP.dept(dept).short, Dispatch.callsign(src)) }, maxResponders = 20, duration = 600 })
    if id then
        CreateThread(function()
            for _ = 1, 30 do
                Wait(2000)
                local a = Dispatch.alerts[id]
                if not a or not GetPlayerPed(src) or GetPlayerPed(src) == 0 then return end
                a.coords = GetEntityCoords(GetPlayerPed(src))
                Whip.core:ShowBlip({ people = recipients(a.jobs) }, 'alert_' .. id,
                    { coords = a.coords, label = '10-99 Officer needs help', sprite = 526, color = 1, flash = true, scale = 1.2 })
            end
        end)
        TriggerEvent(PWP.event('panic'), { source = src, alert = id })
    end
    return id
end

CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for id, a in pairs(Dispatch.alerts) do
            if a.expiresAt <= now then
                Dispatch.clear(id)
            else
                for src in pairs(a.responders) do
                    local u = Dispatch.units[src]
                    local ped = GetPlayerPed(src)
                    if u and u.status == 'enroute' and ped and ped ~= 0 and #(GetEntityCoords(ped) - a.coords) <= Config.Dispatch.onSceneRange then
                        Dispatch.setStatus(src, 'onscene', id)
                        Whip.core:HideBlip(('route_%d_%d'):format(id, src))
                    end
                end
            end
        end
    end
end)

AddEventHandler('whip_gunny:weapon:fired', function(e)
    if not Config.Dispatch.shotsFired or not e or not e.source or not e.coords then return end
    if PWP.Depts.ofSource(e.source) then return end
    local cell = ('%d:%d'):format(math.floor(e.coords.x / 150), math.floor(e.coords.y / 150))
    local now = os.time()
    if (Dispatch.lastShot[cell] or 0) > now then return end
    Dispatch.lastShot[cell] = now + Config.Dispatch.shotsCooldown
    Dispatch.send({ code = '10-71', title = 'Shots fired', coords = e.coords, info = { 'Gunshots reported in the area' } })
end)

AddEventHandler(PWP.event('dutyChanged'), function(e)
    if not e.onDuty and e.source then Dispatch.units[e.source] = nil end
end)
AddEventHandler('playerDropped', function() Dispatch.units[source] = nil end)

Whip.register(function()
    Whip.core:SecureEvent(PWP.event('panic'), { rateLimit = 10000, whileDead = true }, function(source)
        local id, why = panic(source)
        if not id then return false, why end
        Whip.core:NotifyPlayer(source, 'Panic sent', 'warning')
    end)
end)

Whip.command('911', {}, function(source, args)
    if source == 0 then return end
    local now = os.time()
    if (Dispatch.lastCall[source] or 0) > now then
        return Whip.core:NotifyPlayer(source, 'Wait a moment before calling again', 'error')
    end
    local text = PWP.Text.clean(table.concat(args, ' '), 120)
    if not text then return Whip.core:NotifyPlayer(source, '/911 <what happened>', 'info') end
    Dispatch.lastCall[source] = now + Config.Dispatch.citizenCooldown
    local id = Dispatch.send({ code = '911', title = 'Emergency call', coords = GetEntityCoords(GetPlayerPed(source)),
        info = { text } })
    Whip.core:NotifyPlayer(source, id and 'Your call went through' or 'Nobody answered', id and 'success' or 'error')
end)

Whip.command('callsign', {}, function(source, args)
    if source == 0 then return end
    if not PWP.Depts.memberOf(source) then return Whip.core:NotifyPlayer(source, 'Only for officers', 'error') end
    local sign = PWP.Text.clean(args[1], 8)
    if not sign or sign:find('[^%w%-]') then return Whip.core:NotifyPlayer(source, '/callsign <1A-12>', 'info') end
    Whip.core:SetPlayerFlag(source, CALLSIGN, sign)
    Whip.core:NotifyPlayer(source, 'Call sign ' .. sign, 'success')
end)

exports('SendAlert', function(alert) return Dispatch.send(alert) end)
exports('ClearAlert', function(id) return Dispatch.clear(id) end)
exports('GetAlerts', function(job) return Dispatch.list(job) end)
exports('GetUnits', function() return Dispatch.units_() end)
exports('SetUnitStatus', function(src, status) return Dispatch.setStatus(tonumber(src), status) end)

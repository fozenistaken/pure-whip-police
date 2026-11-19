local STATUSES = { available = true, enroute = true, onscene = true, busy = true }
local CALLSIGN = PWP.name('callsign')
local HISTORY = 'pure_whip_police_calls'
local PRIORITY = { critical = 0, high = 1, normal = 2, low = 3 }
local BLIP = { [0] = { 526, 1, true }, [1] = { 526, 1, true }, [2] = { 161, 5, false }, [3] = { 161, 3, false } }
local OUTCOMES = { resolved = true, report = true, arrest = true, unfounded = true, no_contact = true, gone = true, expired = true }

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
        priority = a.priority, level = PRIORITY[a.priority], count = a.count, jobs = a.jobs, createdAt = a.createdAt,
        expiresAt = a.expiresAt, responders = responders, maxResponders = a.maxResponders }
end

function Dispatch.callsign(src)
    return Whip.core:GetPlayerFlag(src, CALLSIGN) or ('#' .. tostring(src))
end

local function showBlip(a, people)
    local b = BLIP[PRIORITY[a.priority]]
    Whip.core:ShowBlip({ people = people }, 'alert_' .. a.id, {
        coords = a.coords, label = ('%s %s%s'):format(a.code, a.title, a.count > 1 and (' x' .. a.count) or ''),
        sprite = b[1], color = b[2], flash = b[3], scale = a.priority == 'critical' and 1.2 or 1.1,
    })
end

local function repeatOf(code, coords, now)
    if Config.Dispatch.mergeMetres <= 0 then return nil end
    for _, a in pairs(Dispatch.alerts) do
        if a.code == code and a.priority ~= 'critical' and now - a.createdAt <= Config.Dispatch.mergeSeconds
            and #(a.coords - coords) <= Config.Dispatch.mergeMetres then
            return a
        end
    end
    return nil
end

function Dispatch.send(alert)
    if type(alert) ~= 'table' then return false, 'an alert is a table' end
    local res = provider()
    if res then return exports[res]:SendAlert(alert) end
    local jobs = type(alert.jobs) == 'table' and alert.jobs or (alert.jobs and { alert.jobs }) or PWP.deptKeys()
    local c = alert.coords
    if not c or not tonumber(c.x) or not tonumber(c.y) then return false, 'an alert needs coords' end
    local now = os.time()
    local code = PWP.Text.clean(alert.code, 12) or '10-00'
    local at = vector3(c.x + 0.0, c.y + 0.0, (tonumber(c.z) or 0.0) + 0.0)
    local same = alert.priority ~= 'critical' and repeatOf(code, at, now)
    if same then
        same.count = same.count + 1
        local line = type(alert.info) == 'table' and PWP.Text.clean(tostring(alert.info[1] or ''), 120)
        if line and #same.info < 8 then
            local dup = false
            for _, l in ipairs(same.info) do if l == line then dup = true end end
            if not dup then same.info[#same.info + 1] = line end
        end
        same.expiresAt = math.max(same.expiresAt, now + math.floor(tonumber(alert.duration) or Config.Dispatch.duration))
        local people = recipients(same.jobs)
        if #people > 0 then showBlip(same, people) end
        local v = view(same)
        for _, src in ipairs(people) do push(src, 'alert', v) end
        return same.id
    end
    Dispatch.nextId = Dispatch.nextId + 1
    local a = {
        id = Dispatch.nextId, jobs = jobs,
        code = code,
        title = PWP.Text.clean(alert.title, 60) or 'Call',
        info = {}, coords = at, count = 1,
        priority = PRIORITY[alert.priority] and alert.priority or 'normal',
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
    if #people > 0 then showBlip(a, people) end
    local v = view(a)
    for _, src in ipairs(people) do
        phone(src, { app = 'pwpmdt', title = ('%s %s'):format(a.code, a.title), text = a.info[1] or '',
            kind = PRIORITY[a.priority] <= 1 and 'command' or 'chat', args = { alert = a.id } })
        push(src, 'alert', v)
    end
    TriggerEvent(PWP.event('alert'), v)
    return a.id
end

function Dispatch.clear(id, outcome, note, by)
    local a = Dispatch.alerts[tonumber(id)]
    if not a then return false, 'No such call' end
    outcome = OUTCOMES[outcome] and outcome or 'resolved'
    Dispatch.alerts[a.id] = nil
    local units = {}
    for src in pairs(a.responders) do units[#units + 1] = Dispatch.callsign(src) end
    MySQL.insert.await(('INSERT INTO `%s` (`code`, `title`, `info`, `x`, `y`, `priority`, `count`, `jobs`, `units`, `createdAt`, `closedAt`, `outcome`, `note`, `closedBy`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(HISTORY),
        { a.code, a.title, json.encode(a.info), a.coords.x, a.coords.y, a.priority, a.count, table.concat(a.jobs, ','), table.concat(units, ', '),
          a.createdAt, os.time(), outcome, PWP.Text.clean(note, 200), by and Whip.core:GetCharId(by) or nil })
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
    local id = Dispatch.send({ jobs = jobs, code = '10-99', title = 'Officer needs help', priority = 'critical',
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
                Dispatch.clear(id, 'expired')
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

local function cellBusy(kind, coords)
    local cell = ('%s:%d:%d'):format(kind, math.floor(coords.x / 150), math.floor(coords.y / 150))
    local now = os.time()
    if (Dispatch.lastShot[cell] or 0) > now then return true end
    Dispatch.lastShot[cell] = now + Config.Dispatch.shotsCooldown
    return false
end

AddEventHandler('whip_core:vehicle:lockpicked', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.source then return end
    if math.random() >= Config.Dispatch.theftChance or PWP.Depts.ofSource(e.source) then return end
    local ped = GetPlayerPed(e.source)
    if not ped or ped == 0 then return end
    local c = GetEntityCoords(ped)
    if cellBusy('theft', c) then return end
    Dispatch.send({ code = '10-60', title = 'Car break-in', coords = c, priority = 'normal',
        info = { e.plate and ('A witness saw plate %s'):format(e.plate) or 'A witness saw someone break into a car' } })
end)

AddEventHandler('explosionEvent', function(_, ev)
    if not Config.Dispatch.explosions or type(ev) ~= 'table' or not ev.posX then return end
    local c = vector3(ev.posX + 0.0, ev.posY + 0.0, (ev.posZ or 0.0) + 0.0)
    if cellBusy('boom', c) then return end
    Dispatch.send({ code = '10-80', title = 'Explosion', coords = c, priority = 'high', info = { 'Loud blast reported' } })
end)

AddEventHandler(PWP.event('dutyChanged'), function(e)
    if not e.onDuty and e.source then Dispatch.units[e.source] = nil end
end)
AddEventHandler('playerDropped', function() Dispatch.units[source] = nil end)

function Dispatch.history(job, limit)
    local rows = MySQL.query.await(('SELECT * FROM `%s` WHERE FIND_IN_SET(?, `jobs`) ORDER BY `id` DESC LIMIT ?'):format(HISTORY),
        { job, math.max(1, math.min(200, limit or 50)) }) or {}
    for _, r in ipairs(rows) do
        local ok, info = pcall(json.decode, r.info or '[]')
        r.info = ok and info or {}
    end
    return rows
end

local function prune()
    local cutoff = os.time() - Config.Dispatch.keepDays * 86400
    for _ = 1, 20 do
        local n = MySQL.update.await(('DELETE FROM `%s` WHERE `closedAt` < ? LIMIT 500'):format(HISTORY), { cutoff }) or 0
        if n < 500 then return end
    end
end

CreateThread(function()
    while true do
        Wait(3600000)
        prune()
    end
end)

Whip.register(function()
    local ok = Whip.core:EnsureTable(HISTORY, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `code` VARCHAR(12) NOT NULL, `title` VARCHAR(60) NOT NULL,
        `info` VARCHAR(1200) NULL, `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `priority` VARCHAR(8) NOT NULL, `count` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        `jobs` VARCHAR(200) NOT NULL, `units` VARCHAR(300) NULL, `createdAt` INT UNSIGNED NOT NULL, `closedAt` INT UNSIGNED NOT NULL,
        `outcome` VARCHAR(12) NOT NULL, `note` VARCHAR(200) NULL, `closedBy` INT UNSIGNED NULL, INDEX (`closedAt`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(HISTORY))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, HISTORY)) end
    prune()
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

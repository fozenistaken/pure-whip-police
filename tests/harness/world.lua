local HERE = HARNESS
local json = dofile(HERE .. '/json.lua')
local W = {
    log = {}, missing = {}, notes = {}, client = {}, activity = {}, blips = {}, points = {}, items = {}, options = {},
    actions = {}, uses = {}, secure = {}, callbacks = {}, exports = {}, handlers = {}, registers = {}, commands = {},
    threads = {}, players = {}, entities = {}, netIds = {}, vehicles = {}, kvp = {}, started = {}, holds = {},
    vdata = {}, garages = {}, custody = {}, paid = {}, deposits = {}, culling = {}, flags = {}, waypoints = {},
    containers = {}, zones = {}, nextId = 1000, clockMs = 0, clockSec = 1800000000, progress = true, res = nil,
    invoking = nil, names = {},
}
_G.W = W

local rawtype = type
local V3, V4 = {}, {}
V3.__index = function(v, k) return rawget(v, '_')[k] end
V3.__add = function(a, b) return vector3(a.x + b.x, a.y + b.y, a.z + b.z) end
V3.__sub = function(a, b) return vector3(a.x - b.x, a.y - b.y, a.z - b.z) end
V3.__mul = function(a, b) if rawtype(a) == 'number' then a, b = b, a end return vector3(a.x * b, a.y * b, a.z * b) end
V3.__len = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
V3.__tostring = function(v) return ('vector3(%.2f, %.2f, %.2f)'):format(v.x, v.y, v.z) end
V3.__eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end
V4.__index = function(v, k) return rawget(v, '_')[k] end
function vector3(x, y, z) return setmetatable({ _ = { x = x + 0.0, y = y + 0.0, z = z + 0.0 } }, V3) end
function vector4(x, y, z, w) return setmetatable({ _ = { x = x + 0.0, y = y + 0.0, z = z + 0.0, w = w + 0.0 } }, V4) end
function type(v)
    local mt = getmetatable(v)
    if mt == V3 then return 'vector3' elseif mt == V4 then return 'vector4' end
    return rawtype(v)
end
_G.json = json

local function note(kind, ...) W.notes[#W.notes + 1] = { kind = kind, args = { ... } } end
local realPrint = print
function print(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    local line = table.concat(parts, ' ')
    W.log[#W.log + 1] = line
    if os.getenv('PWP_HARNESS_VERBOSE') then realPrint('  | ' .. line) end
end
W.realPrint = realPrint

local realTime = os.time
os.time = function(t) if t then return realTime(t) end return W.clockSec end

local DB = os.getenv('PWP_HARNESS_DB')
local MYSQL = os.getenv('PWP_HARNESS_MYSQL') or 'C:/MariaDB/bin/mysql.exe'
local TMP = (os.getenv('TEMP') or '.') .. '/pwp_harness_q.sql'
W.dbName = os.getenv('PWP_HARNESS_DBNAME') or 'pwp_harness'

local function lit(v)
    if v == nil then return 'NULL' end
    local t = rawtype(v)
    if t == 'boolean' then return v and '1' or '0' end
    if t == 'number' then
        if v % 1 == 0 and math.abs(v) < 1e15 then return string.format('%d', math.floor(v)) end
        return string.format('%.6f', v)
    end
    return "'" .. tostring(v):gsub('\\', '\\\\'):gsub("'", "\\'") .. "'"
end

local function bind(sql, args)
    local i = 0
    args = args or {}
    return (sql:gsub('%?', function() i = i + 1 return lit(args[i]) end))
end

local function run(sql, noUse)
    local f = assert(io.open(TMP, 'wb'))
    f:write((noUse and '' or ('USE `' .. W.dbName .. '`;\n')) .. sql .. '\n')
    f:close()
    local cmd = ('""%s" %s --batch --raw --default-character-set=utf8mb4 < "%s" 2>&1"'):format(MYSQL, DB, TMP)
    local p = assert(io.popen(cmd, 'r'))
    local out = p:read('a')
    p:close()
    if out:find('^ERROR') or out:find('\nERROR') then error('SQL: ' .. out:gsub('%s+$', '') .. '\n  in: ' .. sql:sub(1, 300), 3) end
    local lines = {}
    for line in out:gmatch('[^\r\n]+') do lines[#lines + 1] = line end
    if #lines == 0 then return {} end
    local cols = {}
    for c in (lines[1] .. '\t'):gmatch('([^\t]*)\t') do cols[#cols + 1] = c end
    local rows = {}
    for i = 2, #lines do
        local row, n = {}, 0
        for v in (lines[i] .. '\t'):gmatch('([^\t]*)\t') do
            n = n + 1
            if v ~= 'NULL' then row[cols[n]] = (v:match('^%-?%d+%.?%d*$') and tonumber(v)) or v end
        end
        rows[#rows + 1] = row
    end
    return rows
end
W.sql = run
function W.server(sql) return run(sql, true) end

MySQL = {
    query = { await = function(sql, args) return run(bind(sql, args)) end },
    single = { await = function(sql, args) return run(bind(sql, args))[1] end },
    scalar = { await = function(sql, args) local r = run(bind(sql, args))[1]; if not r then return nil end; local _, v = next(r); return v end },
    insert = { await = function(sql, args) local r = run(bind(sql, args) .. ';\nSELECT LAST_INSERT_ID() AS id;')[1]; return r and r.id end },
    update = { await = function(sql, args) local r = run(bind(sql, args) .. ';\nSELECT ROW_COUNT() AS n;')[1]; return r and r.n end },
    ready = function(cb) cb() end,
}

local function spawn(fn, ...)
    local co = coroutine.create(fn)
    W.coRes[co] = W.res
    local ok, err = coroutine.resume(co, ...)
    if not ok then W.errors = W.errors or {}; W.errors[#W.errors + 1] = debug.traceback(co, tostring(err)) end
    return co
end
W.spawn = spawn
W.coRes = setmetatable({}, { __mode = 'k' })

local function resumeAs(co, ...)
    local prev = W.res
    W.res = W.coRes[co] or prev
    local ok, err = coroutine.resume(co, ...)
    W.res = prev
    if not ok then W.errors = W.errors or {}; W.errors[#W.errors + 1] = debug.traceback(co, tostring(err)) end
end

function Wait(ms)
    local co, main = coroutine.running()
    if main then return end
    W.threads[#W.threads + 1] = { co = co, at = W.clockMs + (ms or 0) }
    coroutine.yield()
end
Citizen = { Wait = Wait, CreateThread = function(fn) spawn(fn) end }
GlobalState = {}
function CreateThread(fn) spawn(fn) end
function SetTimeout(ms, fn) spawn(function() Wait(ms) fn() end) end

function W.advance(ms)
    local target = W.clockMs + ms
    while true do
        local best, at
        for i, t in ipairs(W.threads) do
            if t.at <= target and (not at or t.at < at) then best, at = i, t.at end
        end
        if not best then break end
        local t = table.remove(W.threads, best)
        W.clockSec = W.clockSec + math.max(0, math.floor((t.at - W.clockMs) / 1000))
        W.clockMs = math.max(W.clockMs, t.at)
        resumeAs(t.co)
    end
    W.clockSec = W.clockSec + math.floor((target - W.clockMs) / 1000)
    W.clockMs = target
end

promise = { new = function()
    local p = { done = false }
    function p:resolve(v)
        if self.done then return end
        self.done, self.value = true, v
        if self.co then resumeAs(self.co, v) end
    end
    return p
end }
function Citizen.Await(p)
    if p.done then return p.value end
    p.co = coroutine.running()
    return coroutine.yield()
end

function GetGameTimer() return W.clockMs end
function GetCurrentResourceName() return W.res end
function GetInvokingResource() return W.invoking end
function GetResourceState(name) return W.started[name] and 'started' or 'missing' end
function GetResourceKvpString(k) return W.kvp[k] end
function SetResourceKvp(k, v) W.kvp[k] = v end
function joaat(s) return #s end
GetHashKey = joaat

function AddEventHandler(name, fn)
    W.handlers[name] = W.handlers[name] or {}
    table.insert(W.handlers[name], { fn = fn, res = W.res })
end
function RegisterNetEvent(name, fn) if fn then AddEventHandler(name, fn) end end
function TriggerEvent(name, ...)
    local by = W.res
    for _, h in ipairs(W.handlers[name] or {}) do
        local prevRes, prevInv = W.res, W.invoking
        W.res, W.invoking = h.res, by
        spawn(h.fn, ...)
        W.res, W.invoking = prevRes, prevInv
    end
end
function W.fire(name, from, src, ...)
    for _, h in ipairs(W.handlers[name] or {}) do
        local prevRes, prevInv = W.res, W.invoking
        W.res, W.invoking, source = h.res, from, src
        spawn(h.fn, ...)
        W.res, W.invoking = prevRes, prevInv
    end
end
function TriggerClientEvent(name, target, ...) W.client[#W.client + 1] = { name = name, target = target, args = { ... } } end

exports = setmetatable({}, {
    __call = function(_, name, fn)
        W.exports[W.res] = W.exports[W.res] or {}
        W.exports[W.res][name] = fn
    end,
    __index = function(_, res)
        return setmetatable({}, { __index = function(_, fname)
            local f = W.exports[res] and W.exports[res][fname]
            if not f then W.missing[#W.missing + 1] = 'export ' .. res .. '.' .. fname; return function() return nil end end
            return function(_, ...)
                local prevRes, prevInv = W.res, W.invoking
                W.invoking, W.res = W.res, res
                local r = table.pack(f(...))
                W.res, W.invoking = prevRes, prevInv
                return table.unpack(r, 1, r.n)
            end
        end })
    end,
})

function W.player(src, def)
    def.src = src
    def.coords = def.coords or vector3(0, 0, 0)
    def.health = def.health or 200
    def.items = def.items or {}
    def.money = def.money or 100000
    def.perms = def.perms or {}
    def.licences = def.licences or {}
    W.players[src] = def
    W.names[def.charId] = def.name
    return def
end

function W.car(def)
    W.nextId = W.nextId + 1
    def.id = def.id or W.nextId
    def.entity = def.entity or (50000 + def.id)
    def.netId = def.netId or (7000 + def.id)
    def.coords = def.coords or vector3(0, 0, 0)
    def.trunk, def.glovebox = def.trunk or {}, def.glovebox or {}
    W.vehicles[def.id] = def
    W.entities[def.entity] = def
    W.netIds[def.netId] = def.entity
    return def
end

local function pedOf(src) return W.players[src] and src * 100 or 0 end
local function playerOfPed(ped) return W.players[math.floor((ped or 0) / 100)] end

function GetPlayerPed(src) return pedOf(tonumber(src)) end
function GetEntityCoords(ent)
    local p = playerOfPed(ent)
    if p and ent % 100 == 0 then return p.coords end
    local e = W.entities[ent]
    return e and e.coords or vector3(0, 0, 0)
end
function DoesEntityExist(ent) return W.entities[ent] ~= nil or playerOfPed(ent) ~= nil end
function GetEntityType(ent) if W.entities[ent] then return 2 end return 1 end
function NetworkGetEntityFromNetworkId(n) return W.netIds[n] or 0 end
function GetVehicleNumberPlateText(ent) return W.entities[ent] and W.entities[ent].plate or '' end
function GetAllVehicles() local l = {} for e in pairs(W.entities) do l[#l + 1] = e end return l end
function GetEntityVelocity(ent) return W.entities[ent] and W.entities[ent].velocity or vector3(0, 0, 0) end
function IsVehicleSirenOn(ent) return W.entities[ent] and W.entities[ent].sirens == true end
function GetVehiclePedIsIn(ped) local p = playerOfPed(ped) return p and p.vehicle or 0 end
function GetPedInVehicleSeat(ent, seat) local e = W.entities[ent]; return e and e.driver and pedOf(e.driver) or 0 end
function GetEntityHealth(ped) local p = playerOfPed(ped) return p and p.health or 0 end
function GetEntityMaxHealth() return 200 end
function GetEntityHeading() return 0.0 end
function GetVehicleType() return 'automobile' end
function SetEntityCoords(ped, x, y, z) local p = playerOfPed(ped) if p then p.coords = vector3(x, y, z) end end
function SetEntityHeading() end
function SetPlayerCullingRadius(src, r) W.culling[tonumber(src)] = r end
function Entity(ent)
    local e = W.entities[ent] or {}
    e.statebag = e.statebag or {}
    return { state = setmetatable({ set = function(_, k, v) e.statebag[k] = v end }, { __index = e.statebag }) }
end
function Player(src) local p = W.players[tonumber(src)] or {} p.state = p.state or {} return { state = p.state } end

local function inv(src) return W.players[src].items end

local function storeOf(addr)
    if addr.kind == 'player' then
        local p = W.players[addr.id]
        if not p then return nil end
        if addr.sub == 'accessory' then p.accessory = p.accessory or {} return p.accessory end
        return p.items
    elseif addr.kind == 'vehicle' then
        local v = W.vehicles[addr.id]
        return v and (addr.sub == 'glovebox' and v.glovebox or v.trunk)
    elseif addr.kind == 'container' then
        W.containers[addr.id] = W.containers[addr.id] or {}
        return W.containers[addr.id]
    end
end

local function copy(t)
    if rawtype(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copy(v) end
    return o
end

local function nextSlot(store) local i = 1 while store[i] do i = i + 1 end return i end

local core = {}
W.core = core

function core.GetCharId(_, src) local p = W.players[tonumber(src)] return p and p.charId end
function core.GetPlayer(_, src) local p = W.players[tonumber(src)] return p and { session = p.session or 1, charId = p.charId, fullName = p.name } end
function core.IsSessionCurrent(_, src, session) local p = W.players[src] return p ~= nil and (p.session or 1) == session end
function core.GetPlayers() local o = {} for src, p in pairs(W.players) do o[src] = { charId = p.charId, fullName = p.name } end return o end
function core.GetCharacterNames(_, ids) local o = {} for _, id in ipairs(ids) do o[id] = W.names[id] end return o end
function core.NotifyPlayer(_, src, msg, kind) note('notify', src, msg, kind) return true end
function core.LogActivity(_, src, kind, data) W.activity[#W.activity + 1] = { src = src, kind = kind, detail = data and data.detail } return true end
function core.EnsureTable(_, name, sql) run(sql) return true end
function core.EnsureJob(_, key) return { key = key } end
function core.EnsureContainer(_, key) W.nextId = W.nextId + 1 return { containerId = W.nextId, key = key } end
function core.EnsureZone(_, key) return { key = key } end
function core.RegisterZone(_, id, data) W.zones[id] = data return true end
function core.ShowBlip(_, audience, id, spec) W.blips[id] = { audience = audience, spec = spec } return true end
function core.HideBlip(_, id) W.blips[id] = nil return true end
function core.AddPoint(_, def) W.nextId = W.nextId + 1 W.points[W.nextId] = def def.res = W.res return W.nextId end
function core.RemovePoint(_, id) W.points[id] = nil return true end
function core.RegisterItem(_, key, def) W.items[key] = def return true end
function core.AddItemOption(_, key, opt) W.options[key] = W.options[key] or {} table.insert(W.options[key], opt) return true end
function core.RegisterContextAction(_, key, fn) W.actions[key] = fn return true end
function core.RegisterUseHandler(_, key, fn) W.uses[key] = fn return true end
function core.SecureEvent(_, name, schema, fn) W.secure[name] = { schema = schema, fn = fn, res = W.res } return true end
function core.SecureCallback(_, name, schema, fn) W.callbacks[name] = { schema = schema, fn = fn, res = W.res } return true end
function core.HasItem(_, src, item) for _, s in pairs(inv(src)) do if s.item == item then return true end end return false end
function core.AddItem(_, src, item, n, meta) local st = inv(src) st[nextSlot(st)] = { item = item, amount = n or 1, metadata = copy(meta) } return 'inventory' end
function core.RemoveItem(_, src, item, n)
    for slot, s in pairs(inv(src)) do
        if s.item == item then s.amount = s.amount - (n or 1); if s.amount <= 0 then inv(src)[slot] = nil end return true end
    end
    return false, 'Not enough'
end
function core.StoreRead(_, addr) local st = storeOf(addr) if not st then return false, 'no store' end return { items = copy(st), slots = 30 } end
function core.GetItemAt(_, addr) local st = storeOf(addr) local s = st and st[addr.slot] return s and copy(s) or nil end
function core.SetItemMetadata(_, addr, meta, opts)
    local st = storeOf(addr) local s = st and st[addr.slot]
    if not s then return false, 'Empty slot' end
    s.metadata = s.metadata or {}
    for k, v in pairs(meta or {}) do s.metadata[k] = copy(v) end
    for _, k in ipairs(opts and opts.remove or {}) do s.metadata[k] = nil end
    return true
end
function core.StoreTake(_, addr) local st = storeOf(addr) local s = st and st[addr.slot] if not s then return false, 'Empty slot' end st[addr.slot] = nil return s end
function core.StoreGive(_, addr, item, n, meta) local st = storeOf(addr) st[nextSlot(st)] = { item = item, amount = n, metadata = meta } return 1 end
function core.StoreMove() return true end
function core.CommitWithAction(_, queries) for _, q in ipairs(queries) do run(bind(q.query, q.values)) end return true end
function core.ChargePlayer(_, src, amount, opts)
    local p = W.players[src]
    if not p then return false, 'Player not loaded' end
    if p.money < amount then return false, ('Not enough money (have $%d, need $%d)'):format(p.money, amount) end
    p.money = p.money - amount
    W.nextId = W.nextId + 1
    W.paid[#W.paid + 1] = { src = src, amount = -amount, reason = opts and opts.reason }
    return { id = W.nextId, amount = amount }
end
function core.RefundPlayer(_, receipt) W.paid[#W.paid + 1] = { refund = receipt.id } return true end
function core.PayPlayer(_, who, amount, opts)
    W.paid[#W.paid + 1] = { who = who, amount = amount, reason = opts and opts.reason }
    for _, p in pairs(W.players) do if rawtype(who) == 'table' and p.charId == who.charId then p.money = p.money + amount end end
    return { amount = amount }
end
function core.BankSystemDeposit(_, acc, amount) W.deposits[#W.deposits + 1] = { acc = acc, amount = amount } return true end
function core.GetBankAccount() return nil end
function core.Progress(_, src, opts) note('progress', src, opts and opts.label) if W.progress then return true end return false, 'cancelled' end
function core.GetPlayerRole(_, src, job) local p = W.players[src] if p and p.jobs and p.jobs[job] then return { name = p.jobs[job].name, level = p.jobs[job].level } end return nil end
function core.HasJobPermission(_, src, job, perm) local p = W.players[src] if p and p.jobs and p.jobs[job] and p.perms[perm] then return true end return false, 'no permission' end
function core.IsPlayerClockedOn(_, src, job) local p = W.players[src] return p and p.dept == job or false end
function core.GetClockedOnEmployees(_, job) local o = {} for src, p in pairs(W.players) do if p.dept == job then o[#o + 1] = { source = src, charId = p.charId } end end return o end
function core.GetJobEmployees(_, job) local o = {} for _, p in pairs(W.players) do if p.jobs and p.jobs[job] then o[p.charId] = { charId = p.charId, onDuty = p.dept == job } end end return o end
function core.GetItemDef(_, key) return W.items[key] or { name = key } end
function core.GetItemDefs() return W.items end
local function vref(ref)
    if rawtype(ref) == 'number' then return W.vehicles[ref] end
    if rawtype(ref) == 'table' then
        if ref.id or ref.vehicleId then return W.vehicles[ref.id or ref.vehicleId] end
        if ref.entity then return W.entities[ref.entity] end
        if ref.plate then for _, v in pairs(W.vehicles) do if v.plate == ref.plate then return v end end end
    end
end
function core.GetVehicle(_, ref)
    local v = vref(ref)
    if not v then return nil end
    return { id = v.id, vehicleId = v.id, plate = v.plate, owner = v.owner and { charId = v.owner } or nil, entity = v.out ~= false and v.entity or nil, session = v.session }
end
function core.HoldVehicleEngine(_, id, key, reason) W.holds[id .. ':' .. key] = reason return true end
function core.ReleaseVehicleEngine(_, id, key) W.holds[id .. ':' .. (key or '')] = nil return true end
function core.DespawnVehicle(_, id, opts) local v = vref(id) if not v then return false, 'Vehicle not found' end v.out = false v.garage = opts and opts.garage return true end
function core.SetVehicleCustody(_, ref, held) local v = vref(ref) W.custody[v.id] = held or nil return true end
function core.RetrieveVehicle(_, ref, garage) local v = vref(ref) if W.custody[v.id] then return false, 'Vehicle is in custody' end if v.garage ~= garage then return false, 'Wrong garage' end return true end
function core.SpawnVehicle(_, ref, at) local v = vref(ref) v.out = true v.spawnedAt = at return true end
function core.GetGarage(_, key) return W.garages[key] end
function core.CreateGarage(_, data) W.garages[data.key] = data return data end
function core.GetVehicleData(_, ref, key) local v = vref(ref) W.vdata[v.id] = W.vdata[v.id] or {} return copy(W.vdata[v.id][key]) end
function core.SetVehicleData(_, ref, key, value) local v = vref(ref) W.vdata[v.id] = W.vdata[v.id] or {} W.vdata[v.id][key] = copy(value) return true end
function core.CreateGroundItem(_, def)
    local id = MySQL.insert.await('INSERT INTO `ground_items` (`item`, `amount`, `metadata`, `x`, `y`, `z`) VALUES (?, ?, ?, ?, ?, ?)',
        { def.item, def.amount or 1, json.encode(def.metadata or {}), def.coords.x, def.coords.y, def.coords.z })
    return { id = id, item = def.item, amount = def.amount }
end
function core.DeleteGroundItem(_, id) MySQL.update.await('DELETE FROM `ground_items` WHERE `id` = ?', { id }) return true end
function core.SetPlayerFlag(_, src, k, v) W.flags[src .. ':' .. k] = v return true end
function core.GetPlayerFlag(_, src, k) return W.flags[src .. ':' .. k] end
function core.BlockHands() return true end
function core.UnblockHands() return true end
function core.SetPlayerWaypoint(_, src, c) W.waypoints[src] = c return true end
function core.GetPlayerJobs(_, src) return {} end
function core.OpenStore() return true end
function core.SetNpcState() return true end
function core.SpawnNpc() W.nextId = W.nextId + 1 return W.nextId, W.nextId end
function core.GetShop() return nil end
function core.DeleteShop() return true end
function core.HasExport() return true end
function core.IsPlayerDead(_, src) return W.players[src] and W.players[src].dead == true end
function W.as(res, fn, ...) local prev = W.res W.res = res local r = table.pack(fn(...)) W.res = prev return table.unpack(r, 1, r.n) end
function core.GetInventory(_, src) return { player = copy(W.players[src].items) } end

Whip = setmetatable({
    core = setmetatable({}, { __index = function(_, k)
        local f = core[k]
        if not f then
            W.missing[#W.missing + 1] = 'Whip.core:' .. k
            return function() return nil end
        end
        return f
    end }),
    register = function(fn) W.registers[#W.registers + 1] = { res = W.res, fn = fn } end,
    registerWith = function() end,
    configPage = function() end,
    onConfigChanged = function() end,
    command = function(name, _, fn) W.commands[name] = fn end,
    ready = function() return true end,
    isReady = function() return true end,
}, { __index = function(_, k) return function() return true end end })

local fakeExports = { whip_core = { GetCharacterInfo = function(ids) local o = {} for _, id in ipairs(ids or {}) do o[id] = { charId = id, name = W.names[id] } end return o end }, whip_phone = { Notify = function(src, n) note('phone', src, n) return true end, Push = function(src, app, ev, d) note('push', src, app, ev) return true end } }
for res, list in pairs(fakeExports) do W.exports[res] = list; W.started[res] = true end

function W.load(root, res)
    W.res = res
    W.started[res] = true
    local files = {}
    local noop = function() return function() end end
    local env = setmetatable({}, { __index = function() return noop end })
    local function list(kind) return function(t) for _, f in ipairs(t) do files[#files + 1] = { kind = kind, file = f } end end end
    env.shared_scripts, env.server_scripts, env.client_scripts = list('shared'), list('server'), list('client')
    local chunk = assert(loadfile(root .. '/fxmanifest.lua', 't', env))
    chunk()
    for _, f in ipairs(files) do
        if f.kind ~= 'client' and f.file:sub(1, 1) ~= '@' then
            local fn, err = loadfile(root .. '/' .. f.file)
            if not fn then error('load ' .. f.file .. ': ' .. err) end
            local ok, e = xpcall(fn, debug.traceback)
            if not ok then error('run ' .. f.file .. ': ' .. e) end
        end
    end
end

function W.boot()
    for _, r in ipairs(W.registers) do
        W.res = r.res
        spawn(r.fn)
    end
    W.res = nil
end

local function call(tbl, name, src, ...)
    local h = tbl[name]
    if not h then error('no handler ' .. name) end
    local prev = W.res
    W.res = h.res
    local out
    local co = coroutine.create(function(...) out = table.pack(h.fn(src, W.players[src], ...)) end)
    local ok, err = coroutine.resume(co, ...)
    W.res = prev
    if not ok then error(debug.traceback(co, tostring(err))) end
    return table.unpack(out or {}, 1, out and out.n or 0)
end
function W.event(name, src, ...) return call(W.secure, name, src, ...) end
function W.cb(name, src, ...) return call(W.callbacks, name, src, ...) end

function W.notesFor(src, kind)
    local o = {}
    for _, n in ipairs(W.notes) do if n.kind == (kind or 'notify') and n.args[1] == src then o[#o + 1] = n.args[2] end end
    return o
end
function W.lastNote(src) local l = W.notesFor(src) return l[#l] end

return W

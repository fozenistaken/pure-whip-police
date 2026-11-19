HARNESS = arg[1] .. '/tests/harness'
local ROOT = arg[1]
local json = dofile(HARNESS .. '/json.lua')
_G.json = json
local realPrint = print
local pass, fail = 0, 0
local function check(name, cond, detail)
    if cond then pass = pass + 1 else fail = fail + 1; realPrint('FAIL ' .. name .. (detail and (': ' .. tostring(detail)) or '')) end
end

local C = { natives = {}, server = {}, actions = {}, shown = {}, notes = {}, threads = {}, handlers = {}, commands = {}, clockMs = 0, errors = {}, entities = {}, cams = {} }
local rawtype = type
local V3 = {}
V3.__index = function(v, k) return rawget(v, '_')[k] end
V3.__add = function(a, b) return vector3(a.x + b.x, a.y + b.y, a.z + b.z) end
V3.__sub = function(a, b) return vector3(a.x - b.x, a.y - b.y, a.z - b.z) end
V3.__len = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
function vector3(x, y, z) return setmetatable({ _ = { x = x + 0.0, y = y + 0.0, z = z + 0.0 } }, V3) end
function type(v) if getmetatable(v) == V3 then return 'vector3' end return rawtype(v) end
function vector4(x, y, z, w) local v = vector3(x, y, z) rawget(v, '_').w = w + 0.0 return v end
function print(...) end

local function spawn(fn, ...)
    local co = coroutine.create(fn)
    local ok, err = coroutine.resume(co, ...)
    if not ok then C.errors[#C.errors + 1] = debug.traceback(co, tostring(err)) end
end
function Wait(ms)
    local co, main = coroutine.running()
    if main then return end
    C.threads[#C.threads + 1] = { co = co, at = C.clockMs + math.max(ms or 0, 16) }
    coroutine.yield()
end
function CreateThread(fn) spawn(fn) end
function SetTimeout(ms, fn) spawn(function() Wait(ms) fn() end) end
Citizen = { Wait = Wait, CreateThread = CreateThread }
GlobalState = {}
local function advance(ms)
    local target = C.clockMs + ms
    while true do
        local best, at
        for i, t in ipairs(C.threads) do if t.at <= target and (not at or t.at < at) then best, at = i, t.at end end
        if not best then break end
        local t = table.remove(C.threads, best)
        C.clockMs = math.max(C.clockMs, t.at)
        local ok, err = coroutine.resume(t.co)
        if not ok then C.errors[#C.errors + 1] = debug.traceback(t.co, tostring(err)) end
    end
    C.clockMs = target
end

function GetGameTimer() return C.clockMs end
function GetCurrentResourceName() return 'pure-whip-police' end
function GetResourceState(n) return (n == 'whip_phone' or n == 'bodycam') and 'started' or 'missing' end
function AddEventHandler(name, fn) C.handlers[name] = C.handlers[name] or {} table.insert(C.handlers[name], fn) end
function RegisterNetEvent(name, fn) if fn then AddEventHandler(name, fn) end end
local function fire(name, ...) for _, fn in ipairs(C.handlers[name] or {}) do spawn(fn, ...) end end
function TriggerServerEvent(name, ...) C.server[#C.server + 1] = { name = name, args = { ... } } end
function RegisterCommand(name, fn) C.commands[name] = fn end
function RegisterKeyMapping() end
function RegisterNUICallback() end
function SendNUIMessage() end
function SetNuiFocus() end
function ExecuteCommand(c) if C.commands[c] then C.commands[c](0, {}) end end
function joaat(s) return #s end
GetHashKey = joaat
LocalPlayer = { state = { whipJob = 'lspd' } }

C.ped = 1
C.veh = 0
C.pool = {}
C.impact = nil
function PlayerPedId() return C.ped end
function GetEntityCoords(e) local x = C.entities[e] return x and x.coords or vector3(0, 0, 30) end
function GetEntityHeading() return 90.0 end
function GetEntityForwardVector() return vector3(0, 1, 0) end
function GetOffsetFromEntityGivenWorldCoords(e, c) return vector3(c.x, c.y, c.z) end
function GetVehicleWheelTireColliderSize() return 0.36 end
function GetVehicleWheelTireColliderWidth() return 0.26 end
function AttachEntityToEntity(obj, veh, bone, x, y, z) C.natives.AttachEntityToEntity = (C.natives.AttachEntityToEntity or 0) + 1 C.attached = C.attached or {} C.attached[#C.attached + 1] = { x = x, z = z } end
function GetOffsetFromEntityInWorldCoords(e, x, y, z) return vector3(x, y, z) end
function GetWorldPositionOfEntityBone() return vector3(0.8, 1.2, 0.3) end
function GetGamePool(kind) return kind == 'CVehicle' and C.pool or {} end
function GetVehiclePedIsIn() return C.veh end
function GetPedInVehicleSeat() return C.ped end
function GetEntitySpeed(e) local x = C.entities[e] return x and x.speed or 0 end
function GetVehicleNumberPlateText(e) local x = C.entities[e] return x and x.plate or '' end
function NetworkGetEntityIsNetworked() return true end
function NetworkGetNetworkIdFromEntity(e) return e + 1000 end
function GetPedLastWeaponImpactCoord() if C.impact then return true, C.impact end return false, vector3(0, 0, 0) end
function GetEntityHealth() return C.health or 200 end
function GetEntityMaxHealth() return 200 end
function IsEntityDead(e) return C.dead == e end
function DoesEntityExist(e) return e ~= 0 and e ~= nil and not C.gone[e] end
C.gone = {}
function GetActivePlayers() return C.players or {} end
function GetPlayerPed(p) return 100 + p end
function GetPlayerServerId(p) return p end
function GetPlayerFromServerId(id) return C.serverPlayers and C.serverPlayers[id] or -1 end
function GetEntityBoneIndexByName() return 3 end
function GetPedBoneIndex() return 4 end
function HasModelLoaded() return true end
function HasAnimDictLoaded() return true end
function CreatePed() C.dog = 777 return 777 end
function CreateObjectNoOffset() return 888 end
function CreateCam() C.cams[#C.cams + 1] = true return #C.cams end
function GetClockHours() return 21 end
function GetClockMinutes() return 7 end
function GetClockSeconds() return 33 end
function GetDisabledControlNormal(_, ctrl) return C.look and C.look[ctrl] or 0 end
function IsDisabledControlJustPressed(_, ctrl) if C.press == ctrl then C.press = nil return true end return false end
function Entity(e) local x = C.entities[e] or {} return { state = x.state or {} } end
setmetatable(_G, { __index = function(_, k)
    if rawtype(k) == 'string' and k:match('^%u') then
        return function(...) C.natives[k] = (C.natives[k] or 0) + 1 return 0 end
    end
end })

local client = {}
function client.AddAction(_, def) C.actions[def.id] = def return def.id end
function client.RemoveAction(_, id) C.actions[id] = nil return true end
function client.Notify(_, text, kind) C.notes[#C.notes + 1] = { text = text, kind = kind } return true end
function client.ShowText(_, text, opts) C.shown[#C.shown + 1] = { text = text, opts = opts } return true end
function client.HideText() C.hidden = (C.hidden or 0) + 1 return true end
function client.GetVehicleId(_, ent) return C.entities[ent] and C.entities[ent].id or nil end
function client.Callback(_, name, ...) C.calls = C.calls or {} C.calls[#C.calls + 1] = { name = name, args = { ... } } local r = C.answers and C.answers[name] if rawtype(r) == 'function' then return r(...) end if r == nil then return true end return table.unpack(r) end
function client.GetPlayerJobs() return { { key = 'lspd' } } end
function client.GetItemDef(_, key) return { name = key } end
function client.SetScreenOpen() return true end
function client.BlockControls() return true end
function client.UnblockControls() return true end
C.missing = {}
local registers = {}
Whip = setmetatable({ core = setmetatable({}, { __index = function(_, k)
    if client[k] then return client[k] end
    C.missing[#C.missing + 1] = k
    return function() return nil end
end }), register = function(fn) registers[#registers + 1] = fn end }, { __index = function() return function() return true end end })
exports = setmetatable({}, { __call = function() end, __index = function(_, res)
    return setmetatable({}, { __index = function(_, fn) return function(_, ...) C.exportCalls = C.exportCalls or {} C.exportCalls[#C.exportCalls + 1] = res .. '.' .. fn return true end end })
end })

local files = {}
local env = setmetatable({}, { __index = function() return function() return function() end end end })
env.shared_scripts = function(t) for _, f in ipairs(t) do files[#files + 1] = f end end
env.client_scripts = function(t) for _, f in ipairs(t) do files[#files + 1] = f end end
env.server_scripts = function() end
assert(loadfile(ROOT .. '/fxmanifest.lua', 't', env))()
for _, f in ipairs(files) do
    if f:sub(1, 1) ~= '@' then
        local fn, err = loadfile(ROOT .. '/' .. f)
        if not fn then error(f .. ': ' .. err) end
        local ok, e = xpcall(fn, debug.traceback)
        check('loads ' .. f, ok, e)
    end
end
for _, fn in ipairs(registers) do spawn(fn) end
advance(100)

check('radar action', C.actions['pure-whip-police_radar'] ~= nil)
check('k9 action', C.actions['pure-whip-police_k9'] ~= nil)
check('police car action', C.actions['pure-whip-police_policecar'] ~= nil)
check('clamp cut action', C.actions['pure-whip-police_clampcut'] ~= nil)
check('prints action', C.actions['pure-whip-police_cardoor'] ~= nil)

C.entities[501] = { coords = vector3(0, 30, 0), plate = ' BOLO 1 ', speed = 25, id = 9001 }
C.entities[502] = { coords = vector3(1, -15, 0), plate = 'BEHIND', speed = 10, id = 9002 }
C.entities[503] = { coords = vector3(20, 10, 0), plate = 'OTHERLN', speed = 30 }
C.pool = { 500, 501, 502, 503 }
C.veh = 500
C.actions['pure-whip-police_radar'].onSelect({})
advance(300)
local last = C.shown[#C.shown]
check('radar shows front and rear', last and last.text:find('Front 90 km/h · BOLO 1', 1, true) and last.text:find('Rear 36 km/h · BEHIND', 1, true), last and last.text)
local plates = 0
for _, s in ipairs(C.server) do if s.name == 'pure-whip-police:plate' then plates = plates + 1 end end
check('both plates sent once', plates == 2, plates)
advance(1000)
plates = 0
for _, s in ipairs(C.server) do if s.name == 'pure-whip-police:plate' then plates = plates + 1 end end
check('not sent again', plates == 2, plates)
fire('pure-whip-police:plateHit', 'BOLO 1', 'BOLO: robbery')
last = C.shown[#C.shown]
check('hit turns the capsule amber', last and last.opts.tone == 'warn' and last.text:find('BOLO: robbery', 1, true), last and last.text)
C.commands.pwp_radarlock(0, {})
advance(300)
last = C.shown[#C.shown]
check('lock shows', last and last.text:find('Locked', 1, true))
C.veh = 0
advance(300)
check('leaving the car stops the radar', (C.hidden or 0) >= 1)

local before = #C.server
C.actions['pure-whip-police_k9'].onSelect({ option = 'call' })
advance(100)
check('dog called', C.dog == 777)
C.players = { 2 }
C.entities[102] = { coords = vector3(0, 3, 30) }
C.answers = { ['pure-whip-police:k9person'] = { { hit = true, where = 'pockets' } } }
C.actions['pure-whip-police_k9'].onSelect({ option = 'sniff' })
advance(10000)
local said = C.notes[#C.notes]
check('dog search reports', said and said.text:find('smells something', 1, true), said and said.text)
C.answers['pure-whip-police:k9attack'] = { true }
C.actions['pure-whip-police_k9'].onSelect({ option = 'attack' })
advance(100)
check('attack ordered', (C.natives.TaskCombatPed or 0) >= 1)
C.dead = 777
advance(1500)
local down = false
for i = before + 1, #C.server do if C.server[i].name == 'pure-whip-police:k9down' then down = true end end
check('a hurt dog goes home', down)

C.entities[600] = { coords = vector3(0, 5, 0), state = { pwpClamp = true }, id = 9100 }
C.pool = { 600 }
advance(1600)
advance(1600)
local at = C.attached or {}
check('clamp fitted in three pieces', #at == 3, #at)
check('clamp pieces sit on the tyre face', at[1] and math.abs(at[1].x - (0.8 - 0.13)) < 1e-6, at[1] and at[1].x)
check('hook on top, arm on the ground', at[3] and math.abs(at[2].z - at[1].z - 0.36) < 1e-6 and math.abs(at[1].z - at[3].z - 0.36) < 1e-6)
C.entities[600].state.pwpClamp = nil
advance(1600)
check('clamp removed when the state clears', (C.natives.DeleteObject or 0) >= 3, C.natives.DeleteObject)
C.actions['pure-whip-police_policecar'].onSelect({ option = 'impound', entity = 600 })
local sentCar = C.server[#C.server]
check('police car action sends the car id', sentCar.name == 'pure-whip-police:policecar' and sentCar.args[1] == 9100 and sentCar.args[2] == 'impound')

fire('pure-whip-police:feed', { kind = 'cam', id = 1, label = 'Cam one', coords = vector3(1, 2, 3), heading = 90, pitch = -10, fov = 60, count = 2 })
advance(400)
check('camera feed renders', (C.natives.RenderScriptCams or 0) >= 1)
C.look = { [1] = 10 }
advance(100)
C.look = nil
C.press = 38
advance(100)
check('E switches camera', C.calls and C.calls[#C.calls].name == 'pure-whip-police:mdt:watch' and C.calls[#C.calls].args[1].id == 2, C.calls and json.encode(C.calls[#C.calls].args))
C.press = 177
advance(100)
local left = false
for _, s in ipairs(C.server) do if s.name == 'pure-whip-police:unwatch' then left = true end end
check('Backspace leaves and tells the server', left)

C.serverPlayers = { [7] = 3 }
C.entities[103] = { coords = vector3(5, 5, 5) }
fire('pure-whip-police:feed', { kind = 'unit', target = 7, label = '2B-04' })
advance(400)
check('body cam attaches to the officer', (C.natives.AttachCamToPedBone or 0) >= 1)
C.gone[103] = true
advance(7000)
C.press = 177
advance(100)

fire('whip_gunny:weapon:drawn')
C.impact = vector3(5, 5, 5)
advance(250)
local hits = 0
for _, s in ipairs(C.server) do if s.name == 'pure-whip-police:hit' then hits = hits + 1 end end
check('impact reported once', hits == 1, hits)
C.impact = vector3(9, 5, 5)
advance(400)
hits = 0
for _, s in ipairs(C.server) do if s.name == 'pure-whip-police:hit' then hits = hits + 1 end end
check('a new impact is reported', hits == 2, hits)
fire('whip_gunny:weapon:holstered')
advance(200)

C.health = 150
fire('gameEventTriggered', 'CEventNetworkEntityDamage', { 1 })
fire('gameEventTriggered', 'CEventNetworkEntityDamage', { 1 })
local hurt = 0
for _, s in ipairs(C.server) do if s.name == 'pure-whip-police:hurt' then hurt = hurt + 1 end end
check('injury reported once per cooldown', hurt == 1, hurt)

check('no unknown client WHIP calls', #C.missing == 0, table.concat(C.missing, ', '))
for _, e in ipairs(C.errors) do fail = fail + 1; realPrint('THREAD ERROR: ' .. e) end
realPrint(fail == 0 and ('CLIENT HARNESS PASS (' .. pass .. ' checks)') or ('CLIENT HARNESS FAILED ' .. fail .. ', passed ' .. pass))
os.exit(fail == 0 and 0 or 1)

local TABLE = 'pure_whip_police_feedlog'
local C = Config.Feeds
local Feeds = { dark = {}, points = {}, watching = {}, logged = {} }
PWP.Feeds = Feeds

local LABEL = { casing = 'Shots fired', blood = 'Someone bleeding', hole = 'Shots fired', speed = 'Speeding car',
    dark = 'Feed cut', repaired = 'Camera repaired', fired = 'Fired', cuffed = 'Cuffed someone', jailed = 'Sent to prison' }

local function now() return os.time() end

function Feeds.log(key, kind, text, coords)
    MySQL.insert.await(('INSERT INTO `%s` (`feed`, `kind`, `text`, `x`, `y`, `z`, `at`) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(TABLE),
        { key, kind, PWP.Text.clean(text, 200) or LABEL[kind] or kind, coords and coords.x, coords and coords.y, coords and coords.z, now() })
end

function Feeds.recent(key, limit)
    return MySQL.query.await(('SELECT `kind`, `text`, `at` FROM `%s` WHERE `feed` = ? ORDER BY `id` DESC LIMIT %d'):format(TABLE, limit or 5),
        { key }) or {}
end

local function at(cam) local c = cam.coords return vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0) end

local function live(i) return not Feeds.dark[i] or Feeds.dark[i] <= now() end

local function seenBy(coords)
    local list = {}
    for i, cam in ipairs(Config.Cameras) do
        if live(i) and #(at(cam) - coords) <= C.seeMetres then list[#list + 1] = i end
    end
    return list
end

local function witness(kind, coords, text)
    if not coords then return end
    coords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    for _, i in ipairs(seenBy(coords)) do
        local key = ('%d:%s'):format(i, kind)
        if not Feeds.logged[key] or now() - Feeds.logged[key] >= 30 then
            Feeds.logged[key] = now()
            Feeds.log('cam:' .. i, kind, text or LABEL[kind], coords)
        end
    end
end

AddEventHandler(PWP.event('evidenceCreated'), function(e)
    if GetInvokingResource() ~= PWP.RES or type(e) ~= 'table' then return end
    witness(e.kind, e.coords)
end)

AddEventHandler(PWP.event('speedTicket'), function(e)
    if GetInvokingResource() ~= PWP.RES or type(e) ~= 'table' or not e.source then return end
    witness('speed', GetEntityCoords(GetPlayerPed(e.source)), ('Speeding: %s at %d'):format(e.plate or '?', e.speed or 0))
end)

local function bodylog(src, kind, text)
    local charId = Whip.core:GetCharId(src)
    if not charId or not PWP.Depts.ofSource(src) then return end
    Feeds.log('unit:' .. charId, kind, text, GetEntityCoords(GetPlayerPed(src)))
end

AddEventHandler('whip_gunny:weapon:fired', function(e)
    if GetInvokingResource() ~= 'whip_gunny' or type(e) ~= 'table' or not e.source then return end
    local key = 'fire:' .. e.source
    if Feeds.logged[key] and now() - Feeds.logged[key] < 10 then return end
    Feeds.logged[key] = now()
    bodylog(e.source, 'fired', ('Fired %s'):format(e.item and (Whip.core:GetItemDef(e.item) or {}).name or 'a weapon'))
end)

AddEventHandler(PWP.event('cuffed'), function(e)
    if GetInvokingResource() ~= PWP.RES or type(e) ~= 'table' or not e.by then return end
    bodylog(e.by, 'cuffed', 'Cuffed someone')
end)

AddEventHandler(PWP.event('jailed'), function(e)
    if GetInvokingResource() ~= PWP.RES or type(e) ~= 'table' or not e.by then return end
    bodylog(e.by, 'jailed', ('Sent someone to prison for %d months'):format(e.months or 0))
end)

local function readPlates()
    if #Config.Cameras == 0 then return end
    for _, veh in ipairs(GetAllVehicles()) do
        local c = GetEntityCoords(veh)
        local seen = seenBy(c)
        if #seen > 0 then
            local plate = PWP.Plates.norm(GetVehicleNumberPlateText(veh))
            if plate then PWP.Traffic.sight('cam' .. seen[1] .. ':' .. plate, plate, c, nil) end
        end
    end
end

local function cut(src, i, cam)
    local player = Whip.core:GetPlayer(src)
    if not player then return false, 'Not loaded' end
    CreateThread(function()
        local done = Whip.core:Progress(src, { label = 'Cutting the feed...', duration = 6000, near = { coords = at(cam), range = 5.0 } })
        if not done or not Whip.core:IsSessionCurrent(src, player.session) then return end
        Feeds.dark[i] = now() + C.darkMinutes * 60
        Feeds.log('cam:' .. i, 'dark', 'Feed cut', at(cam))
        Whip.core:LogActivity(src, 'camera_cut', { detail = cam.label })
        PWP.Dispatch.send({ code = '10-90', title = 'Camera offline', coords = at(cam), priority = 'normal',
            info = { cam.label .. ' stopped sending' } })
    end)
    return true
end

local function repair(src, i, cam)
    CreateThread(function()
        local done = Whip.core:Progress(src, { label = 'Repairing the camera...', duration = 4000, near = { coords = at(cam), range = 5.0 } })
        if not done then return end
        Feeds.dark[i] = nil
        Feeds.log('cam:' .. i, 'repaired', 'Camera repaired', at(cam))
        Whip.core:NotifyPlayer(src, cam.label .. ' is back online', 'success')
    end)
    return true
end

function Feeds.list()
    local cams = {}
    for i, cam in ipairs(Config.Cameras) do
        cams[#cams + 1] = { id = i, label = cam.label, dark = not live(i), log = Feeds.recent('cam:' .. i, 3) }
    end
    local units = {}
    for _, u in ipairs(PWP.Dispatch.units_()) do
        units[#units + 1] = { source = u.source, callsign = u.callsign, dept = u.dept, status = u.status,
            log = Feeds.recent('unit:' .. u.charId, 2) }
    end
    return { cameras = cams, units = units }
end

local function cullTo(src, coords)
    local d = #(GetEntityCoords(GetPlayerPed(src)) - coords)
    SetPlayerCullingRadius(tostring(src), math.min(5000.0, d + 200.0))
    Feeds.watching[src] = true
end

function Feeds.watch(src, a)
    if a.kind == 'cam' then
        local i = tonumber(a.id)
        local cam = i and Config.Cameras[i]
        if not cam then return false, 'No such camera' end
        if not live(i) then return false, cam.label .. ' is dark' end
        cullTo(src, at(cam))
        local spec = { kind = 'cam', id = i, label = cam.label, coords = at(cam), heading = cam.heading or 0.0,
            pitch = cam.pitch or -15.0, fov = cam.fov or 60.0, count = #Config.Cameras }
        TriggerClientEvent(PWP.event('feed'), src, spec)
        return true
    end
    local target = tonumber(a.target)
    local unit
    for _, u in ipairs(PWP.Dispatch.units_()) do if u.source == target then unit = u end end
    if not unit then return false, 'That officer is not on duty' end
    if target == src then return false, 'That is your own camera' end
    cullTo(src, GetEntityCoords(GetPlayerPed(target)))
    TriggerClientEvent(PWP.event('feed'), src, { kind = 'unit', target = target, label = unit.callsign })
    return true
end

function Feeds.unwatch(src)
    if not Feeds.watching[src] then return end
    Feeds.watching[src] = nil
    SetPlayerCullingRadius(tostring(src), 0.0)
end

AddEventHandler('playerDropped', function() Feeds.watching[source] = nil end)

Whip.register(function()
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `feed` VARCHAR(24) NOT NULL, `kind` VARCHAR(12) NOT NULL,
        `text` VARCHAR(200) NOT NULL, `x` FLOAT NULL, `y` FLOAT NULL, `z` FLOAT NULL, `at` INT UNSIGNED NOT NULL,
        INDEX (`feed`, `id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end

    for _, id in pairs(Feeds.points) do Whip.core:RemovePoint(id) end
    Feeds.points = {}
    for i, cam in ipairs(Config.Cameras) do
        local id, why = Whip.core:AddPoint({
            at = { coords = at(cam) }, label = cam.label .. ' camera', icon = 'camera', audience = 'everyone',
            reach = 4.0, seeFrom = 8.0,
            options = {
                { id = 'cut', label = 'Cut the feed', require = { item = 'lockpick' } },
                { id = 'repair', label = 'Repair the camera', require = { job = PWP.deptKeys(), onDuty = true } },
            },
            onUse = function(source, use)
                if use.option == 'repair' then return repair(source, i, cam) end
                if not live(i) then return false, 'It is already dark' end
                return cut(source, i, cam)
            end,
        })
        if id then Feeds.points[i] = id else print(('[%s] camera %d: %s'):format(PWP.RES, i, tostring(why))) end
    end

    Whip.core:SecureEvent(PWP.event('unwatch'), { rateLimit = 500 }, function(source) Feeds.unwatch(source) end)
end)

CreateThread(function()
    Whip.ready()
    while true do
        Wait(C.plateSeconds * 1000)
        local ok, err = pcall(readPlates)
        if not ok then print(('[%s] camera plates: %s'):format(PWP.RES, tostring(err))) end
    end
end)

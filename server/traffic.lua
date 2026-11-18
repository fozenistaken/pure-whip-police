local R, F = PWP.Records, PWP.Fines
local Plates = PWP.Plates
local TABLE = 'pure_whip_police_sightings'
local ZONE = PWP.RES .. ':speedcam:'
local TICKET_GAP = 60
local REACH_SLACK = 20.0

local Traffic = { seen = {}, tickets = {}, cams = {} }
PWP.Traffic = Traffic

local function unitName() return PWP.Radar.unitName(Config.Radar.unit) end

function Traffic.check(plate)
    plate = Plates.norm(plate)
    if not plate then return false, 'No plate' end
    local bolo = R.boloForPlate(plate)
    local v = Whip.core:GetVehicle({ plate = plate })
    local owner = v and v.owner and v.owner.charId or nil
    local wanted = owner and #R.warrants(owner, true) > 0 or false
    return { plate = plate, bolo = bolo, owner = owner, wanted = wanted }
end

function Traffic.lastSeen(plate)
    plate = Plates.norm(plate)
    if not plate then return nil end
    return MySQL.single.await(('SELECT `x`, `y`, `z`, UNIX_TIMESTAMP(`seenAt`) AS `at`, `seenBy` AS `by` FROM `%s` WHERE `plate` = ?')
        :format(TABLE), { plate })
end

local function remember(src, plate, c)
    local key = src .. ':' .. plate
    local now = os.time()
    if Traffic.seen[key] and now - Traffic.seen[key] < Config.Radar.seenSeconds then return false end
    Traffic.seen[key] = now
    MySQL.query.await(('INSERT INTO `%s` (`plate`, `x`, `y`, `z`, `seenBy`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `x` = VALUES(`x`), `y` = VALUES(`y`), `z` = VALUES(`z`), `seenBy` = VALUES(`seenBy`), `seenAt` = CURRENT_TIMESTAMP')
        :format(TABLE), { plate, c.x, c.y, c.z, Whip.core:GetCharId(src) })
    return true
end

local function read(src, netId)
    local ok, dept = PWP.Depts.can(src, 'records')
    if not ok then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end
    local c = GetEntityCoords(veh)
    if #(GetEntityCoords(GetPlayerPed(src)) - c) > Config.Radar.range + REACH_SLACK then return end
    local plate = Plates.norm(GetVehicleNumberPlateText(veh))
    if not plate or not remember(src, plate, c) then return end
    local info = Traffic.check(plate)
    TriggerEvent(PWP.event('plateSeen'), { source = src, plate = plate, coords = c })
    if not info or not (info.bolo or info.wanted) then return end
    local why = info.bolo and ('BOLO: ' .. (info.bolo.reason or 'look out')) or 'Owner has an active warrant'
    Whip.core:NotifyPlayer(src, ('Plate reader: %s, %s'):format(plate, why), 'error')
    TriggerClientEvent(PWP.event('plateHit'), src, plate, why)
    Whip.core:LogActivity(src, 'plate_hit', { detail = ('%s (%s)'):format(plate, why) })
    TriggerEvent(PWP.event('plateHit'), { source = src, dept = dept, plate = plate, coords = c, bolo = info.bolo,
        owner = info.owner, wanted = info.wanted })
end

local function driverOf(src)
    local ped = GetPlayerPed(src)
    local veh = ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

local function exempt(src, veh)
    return PWP.Depts.ofSource(src) ~= nil and IsVehicleSirenOn(veh)
end

local function ticket(src, cam)
    local veh = driverOf(src)
    if not veh or exempt(src, veh) then return end
    local speed = math.floor(#GetEntityVelocity(veh) * PWP.Radar.factor(Config.Radar.unit) + 0.5)
    if speed <= cam.limit + (cam.tolerance or 0) then return end
    local plate = Plates.norm(GetVehicleNumberPlateText(veh)) or '?'
    local key = cam.index .. ':' .. plate
    local now = os.time()
    if Traffic.tickets[key] and now - Traffic.tickets[key] < TICKET_GAP then return end
    Traffic.tickets[key] = now
    local v = Whip.core:GetVehicle({ entity = veh })
    local charId = v and v.owner and v.owner.charId or Whip.core:GetCharId(src)
    if not charId then return end
    local reason = ('Speed camera, %s: %d %s in a %d zone, %s'):format(cam.label or 'road', speed, unitName(), cam.limit, plate)
    local id, why = F.issue(charId, cam.fine, { reason = reason })
    if not id then return print(('[%s] speed camera %d: %s'):format(PWP.RES, cam.index, tostring(why))) end
    Whip.core:NotifyPlayer(src, ('Speed camera: %d %s in a %d zone. A $%d fine went to the registered owner.')
        :format(speed, unitName(), cam.limit, cam.fine), 'error')
    TriggerEvent(PWP.event('speedTicket'), { source = src, charId = charId, plate = plate, speed = speed,
        limit = cam.limit, fine = cam.fine, fineId = id, camera = cam.index })
end

AddEventHandler('whip_core:zone:entered', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.source then return end
    local cam = Traffic.cams[e.zoneId]
    if cam then ticket(e.source, cam) end
end)

AddEventHandler('playerDropped', function()
    local prefix = source .. ':'
    for key in pairs(Traffic.seen) do
        if key:sub(1, #prefix) == prefix then Traffic.seen[key] = nil end
    end
end)

Whip.register(function()
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `plate` VARCHAR(12) NOT NULL PRIMARY KEY, `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
        `seenBy` INT UNSIGNED NULL, `seenAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end

    Whip.core:SecureEvent(PWP.event('plate'), {
        rateLimit = math.max(100, Config.Radar.readMs - 50),
        params = { { 'netId', 'id', 1, 65535 } },
    }, function(source, _, netId) read(source, netId) end)

    Traffic.cams = {}
    for i, cam in ipairs(Config.SpeedCameras) do
        local id = ZONE .. i
        local ok2, why = Whip.core:RegisterZone(id, { type = 'sphere', pos = cam.coords,
            radius = math.max(10.0, math.min(60.0, tonumber(cam.radius) or 25.0)),
            label = cam.label or 'Speed camera', trackPlayers = true })
        if ok2 then
            Traffic.cams[id] = { index = i, label = cam.label, limit = tonumber(cam.limit) or 80,
                tolerance = tonumber(cam.tolerance) or 0, fine = math.max(1, math.floor(tonumber(cam.fine) or 100)) }
            if Config.SpeedCameraBlips then
                Whip.core:ShowBlip('everyone', 'speedcam_' .. i, { coords = cam.coords, label = 'Speed camera',
                    sprite = 184, color = 1, shortRange = true })
            end
        else
            print(('[%s] speed camera %d: %s'):format(PWP.RES, i, tostring(why)))
        end
    end
end)

exports('CheckPlate', function(plate)
    return Traffic.check(plate)
end)

exports('GetLastSeen', function(plate)
    local row = Traffic.lastSeen(plate)
    if not row then return false, 'No plate reader has seen it' end
    return row
end)

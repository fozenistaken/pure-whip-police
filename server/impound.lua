local T = { clamps = 'pure_whip_police_clamps', impound = 'pure_whip_police_impound' }
local CLAMP = PWP.name('clamp')
local GARAGE = 'pwp_impound'
local HOLD = 'clamp'
local Impound = {}
PWP.Impound = Impound

local function money(n) return '$' .. tostring(math.floor(n)) end

local function clampedRow(vehicleId)
    return MySQL.single.await(('SELECT * FROM `%s` WHERE `vehicleId` = ?'):format(T.clamps), { vehicleId })
end

local function mark(vehicleId, on)
    local v = Whip.core:GetVehicle(vehicleId)
    local ent = v and v.entity
    if ent and DoesEntityExist(ent) then Entity(ent).state:set('pwpClamp', on or nil, true) end
end

local function holdText(row)
    return row.fineId and 'Wheel clamp: pay your fines at a police front desk or kiosk' or 'Wheel clamp: call the police'
end

function Impound.clamp(src, veh, dept)
    local id = veh.id or veh.vehicleId
    if clampedRow(id) then return false, 'It is already clamped' end
    if not Whip.core:HasItem(src, CLAMP) then return false, 'You have no wheel clamp' end
    local ok, why = Whip.core:RemoveItem(src, CLAMP, 1)
    if not ok then return false, why end
    local owner = veh.owner and veh.owner.charId
    local fineId = owner and Config.Clamp.fine > 0
        and PWP.Fines.issue(owner, Config.Clamp.fine, { reason = 'Wheel clamp, ' .. (veh.plate or ''), by = src, dept = dept }) or nil
    local saved = Whip.core:CommitWithAction({ {
        query = ('INSERT INTO `%s` (`vehicleId`, `plate`, `ownerCharId`, `fineId`, `byCharId`, `at`) VALUES (?, ?, ?, ?, ?, ?)'):format(T.clamps),
        values = { id, veh.plate, owner, fineId or nil, Whip.core:GetCharId(src), os.time() },
    } }, { source = src })
    if not saved then
        Whip.core:AddItem(src, CLAMP, 1, nil, { reason = 'clamp not fitted' })
        if fineId then PWP.Fines.void(fineId) end
        return false, 'The clamp could not be saved'
    end
    Whip.core:HoldVehicleEngine(id, HOLD, holdText({ fineId = fineId }))
    mark(id, true)
    Whip.core:LogActivity(src, 'clamped', { detail = veh.plate })
    local ownerSrc = owner and PWP.sourceOf(owner)
    if ownerSrc then
        Whip.core:NotifyPlayer(ownerSrc, ('Your car %s was clamped. Pay the %s fine and it comes off.'):format(veh.plate or '', money(Config.Clamp.fine)), 'warning', 10000)
    end
    return true
end

function Impound.unclamp(vehicleId, why)
    local row = clampedRow(vehicleId)
    if not row then return false, 'That car has no clamp' end
    MySQL.update.await(('DELETE FROM `%s` WHERE `vehicleId` = ?'):format(T.clamps), { vehicleId })
    Whip.core:ReleaseVehicleEngine(vehicleId, HOLD)
    mark(vehicleId, false)
    TriggerEvent(PWP.event('unclamped'), { vehicleId = vehicleId, plate = row.plate, why = why })
    return true, row
end

function Impound.tow(src, veh, dept, reason)
    local id = veh.id or veh.vehicleId
    if clampedRow(id) then Impound.unclamp(id, 'impounded') end
    if not veh.owner or not veh.owner.charId or veh.session then
        local ok, why = Whip.core:DespawnVehicle(id)
        if not ok then return false, why end
        if src then Whip.core:LogActivity(src, 'towed', { detail = veh.plate }) end
        return true, 'towed'
    end
    local ok, why = Whip.core:DespawnVehicle(id, { garage = GARAGE, refuseOccupied = true })
    if not ok then return false, why end
    local held, err = Whip.core:SetVehicleCustody(id, true)
    if not held then print(('[%s] impound custody %s: %s'):format(PWP.RES, tostring(veh.plate), tostring(err))) end
    MySQL.insert.await(('INSERT INTO `%s` (`vehicleId`, `plate`, `ownerCharId`, `fee`, `reason`, `dept`, `byCharId`, `at`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(T.impound),
        { id, veh.plate, veh.owner.charId, Config.Impound.fee, PWP.Text.clean(reason, 120) or 'Impounded', dept, src and Whip.core:GetCharId(src), os.time() })
    if src then Whip.core:LogActivity(src, 'impounded', { detail = veh.plate }) end
    TriggerEvent(PWP.event('impounded'), { vehicleId = id, plate = veh.plate, owner = veh.owner.charId, by = src })
    return true, 'impounded'
end

function Impound.of(vehicleId)
    return MySQL.single.await(('SELECT `fee`, `reason`, `at` FROM `%s` WHERE `vehicleId` = ?'):format(T.impound), { vehicleId })
end

function Impound.release(vehicleId)
    local ok, why = Whip.core:SetVehicleCustody(vehicleId, false)
    if not ok then return false, why end
    MySQL.update.await(('DELETE FROM `%s` WHERE `vehicleId` = ?'):format(T.impound), { vehicleId })
    return true
end

local function spawnSpot()
    local s = Config.Impound.spawn
    if s then return s end
    local c, h = Config.Impound.coords, math.rad(Config.Impound.heading or 0.0)
    return vector4(c.x - math.sin(h) * 6.0, c.y + math.cos(h) * 6.0, c.z, (Config.Impound.heading or 0.0) + 90.0)
end

local function collect(src)
    local charId = Whip.core:GetCharId(src)
    local row = charId and MySQL.single.await(('SELECT * FROM `%s` WHERE `ownerCharId` = ? ORDER BY `at` LIMIT 1'):format(T.impound), { charId })
    if not row then return false, 'Nothing of yours is impounded' end
    local player = Whip.core:GetPlayer(src)
    local receipt
    if row.fee > 0 then
        local r, why = Whip.core:ChargePlayer(src, row.fee, { reason = 'Impound fee, ' .. row.plate })
        if not r then return false, why end
        receipt = r
    end
    local ok, why = Impound.release(row.vehicleId)
    if ok then ok, why = Whip.core:RetrieveVehicle(row.vehicleId, GARAGE) end
    if ok then ok, why = Whip.core:SpawnVehicle(row.vehicleId, spawnSpot()) end
    if not ok then
        if receipt and Whip.core:IsSessionCurrent(src, player.session) then Whip.core:RefundPlayer(receipt) end
        return false, why
    end
    Whip.core:NotifyPlayer(src, ('%s is waiting outside.'):format(row.plate), 'success')
    return true
end

AddEventHandler(PWP.event('finesPaid'), function(e)
    if GetInvokingResource() ~= PWP.RES or type(e) ~= 'table' then return end
    for _, fineId in ipairs(e.ids or {}) do
        local row = MySQL.single.await(('SELECT `vehicleId` FROM `%s` WHERE `fineId` = ?'):format(T.clamps), { fineId })
        if row then
            Impound.unclamp(row.vehicleId, 'paid')
            Whip.core:NotifyPlayer(e.source, 'The wheel clamp is off your car.', 'success')
        end
    end
end)

AddEventHandler('whip_core:vehicle:spawned', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.vehicleId then return end
    if clampedRow(e.vehicleId) then mark(e.vehicleId, true) end
end)

local function cut(src, veh)
    local id = veh.id or veh.vehicleId
    if not clampedRow(id) then return false, 'That car has no clamp' end
    if not Whip.core:HasItem(src, 'lockpick') then return false, 'You need a lockpick' end
    local player = Whip.core:GetPlayer(src)
    CreateThread(function()
        local done = Whip.core:Progress(src, { label = 'Cutting the clamp...', duration = Config.Clamp.cutSeconds * 1000,
            near = { vehicle = id, range = 4.0 } })
        if not done or not Whip.core:IsSessionCurrent(src, player.session) then return end
        Impound.unclamp(id, 'cut')
        Whip.core:LogActivity(src, 'clamp_cut', { detail = veh.plate })
        local c = GetEntityCoords(GetPlayerPed(src))
        PWP.Dispatch.send({ code = '10-66', title = 'Wheel clamp cut', coords = c, info = { 'Plate ' .. (veh.plate or '?') } })
        Whip.core:NotifyPlayer(src, 'The clamp is off', 'success')
    end)
    return true
end

Whip.register(function()
    local ok = Whip.core:EnsureTable(T.clamps, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `vehicleId` INT UNSIGNED NOT NULL PRIMARY KEY, `plate` VARCHAR(12) NULL, `ownerCharId` INT UNSIGNED NULL,
        `fineId` INT UNSIGNED NULL, `byCharId` INT UNSIGNED NULL, `at` INT UNSIGNED NOT NULL, INDEX (`fineId`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.clamps))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T.clamps)) end
    ok = Whip.core:EnsureTable(T.impound, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `vehicleId` INT UNSIGNED NOT NULL PRIMARY KEY, `plate` VARCHAR(12) NULL, `ownerCharId` INT UNSIGNED NOT NULL,
        `fee` INT NOT NULL DEFAULT 0, `reason` VARCHAR(120) NULL, `dept` VARCHAR(50) NULL, `byCharId` INT UNSIGNED NULL,
        `at` INT UNSIGNED NOT NULL, INDEX (`ownerCharId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.impound))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T.impound)) end

    Whip.core:RegisterItem(CLAMP, { name = 'Wheel Clamp', desc = 'Locks a wheel. The owner pays a fine to have it removed.',
        weight = 4.0, type = 'tool', stack = true, maxStack = 4, prop = 'pwp_wheel_clamp' })

    for _, row in ipairs(MySQL.query.await(('SELECT `vehicleId`, `fineId` FROM `%s`'):format(T.clamps)) or {}) do
        Whip.core:HoldVehicleEngine(row.vehicleId, HOLD, holdText(row))
        mark(row.vehicleId, true)
    end

    local c = Config.Impound.coords
    if not Whip.core:GetGarage(GARAGE) then
        local g, why = Whip.core:CreateGarage({ key = GARAGE, name = 'Police Impound', x = c.x, y = c.y, z = c.z,
            heading = Config.Impound.heading })
        if not g then print(('[%s] impound garage: %s'):format(PWP.RES, tostring(why))) end
    end
    local id, why = Whip.core:AddPoint({
        at = { coords = vector3(c.x, c.y, c.z) }, label = 'Impound office', icon = 'car', audience = 'everyone',
        reach = 2.5, seeFrom = 12.0,
        options = { { id = 'collect', label = ('Get my car back (%s)'):format(money(Config.Impound.fee)) } },
        onUse = function(source) return collect(source) end,
    })
    if not id then print(('[%s] impound office: %s'):format(PWP.RES, tostring(why))) end

    Whip.core:SecureEvent(PWP.event('policecar'), {
        rateLimit = 1500,
        params = { { 'veh', 'vehicle', { anyOwner = true, session = true } }, { 'how', 'enum', { 'clamp', 'unclamp', 'impound', 'cut' } } },
        near = { at = 'vehicle', range = 4.5 },
    }, function(source, _, veh, how)
        if how == 'cut' then return cut(source, veh) end
        local ok2, dept = PWP.Depts.can(source, 'fine')
        if not ok2 then return false, dept end
        if how == 'clamp' then
            local done, err = Impound.clamp(source, veh, dept)
            if not done then return false, err end
            return Whip.core:NotifyPlayer(source, 'Clamped ' .. (veh.plate or ''), 'success')
        elseif how == 'unclamp' then
            local done, err = Impound.unclamp(veh.id or veh.vehicleId, 'officer')
            if not done then return false, err end
            Whip.core:AddItem(source, CLAMP, 1, nil, { reason = 'clamp removed' })
            return Whip.core:NotifyPlayer(source, 'Clamp removed', 'success')
        end
        local done, kind = Impound.tow(source, veh, dept, 'Impounded by ' .. (PWP.dept(dept).short or 'police'))
        if not done then return false, kind end
        Whip.core:NotifyPlayer(source, kind == 'towed' and 'Towed away' or ('Impounded ' .. (veh.plate or '')), 'success')
    end)
end)

exports('Impound', function(vehicleId, opts)
    opts = type(opts) == 'table' and opts or {}
    local v = Whip.core:GetVehicle(tonumber(vehicleId))
    if not v then return false, 'No such vehicle' end
    return Impound.tow(tonumber(opts.by), v, opts.dept, opts.reason)
end)
exports('ReleaseImpound', function(vehicleId) return Impound.release(tonumber(vehicleId)) end)
exports('IsClamped', function(vehicleId) return clampedRow(tonumber(vehicleId)) ~= nil end)

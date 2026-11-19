local T = { clamps = 'pure_whip_police_clamps', impounds = 'pure_whip_police_impounds', legacy = 'pure_whip_police_impound' }
local CLAMP = PWP.name('clamp')
local HOLD = 'clamp'
local DAY = 86400
local CFG = Config.Impound
local TL = PWP.TicketLogic
local Impound = { hauled = {}, shift = {}, plates = {} }
PWP.Impound = Impound

local function money(n) return '$' .. tostring(math.floor(n)) end
local function now() return os.time() end

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
        values = { id, veh.plate, owner, fineId or nil, Whip.core:GetCharId(src), now() },
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

local function lotOf(id)
    for i, l in ipairs(CFG.lots) do
        if l.id == id then return l, i end
    end
    return CFG.lots[1], 1
end

local function garageOf(lotId)
    local lot, i = lotOf(lotId)
    return i == 1 and 'pwp_impound' or ('pwp_impound_' .. lot.id)
end

local function reasonOf(id)
    for _, r in ipairs(CFG.reasons) do
        if r.id == id then return r end
    end
    return nil
end

local function storage() return { perDay = CFG.perDay, maxDays = CFG.maxDays } end

local TOW = Config.Tow
local function towOnDuty()
    if type(TOW.job) ~= 'string' or TOW.job == '' then return false end
    return #(Whip.core:GetClockedOnEmployees(TOW.job) or {}) > 0
end
local function towBlip(row) return 'pwp_tow_' .. row.id end
local function towMark(vehicleId, on)
    local v = Whip.core:GetVehicle(vehicleId)
    if v and v.entity and DoesEntityExist(v.entity) then Entity(v.entity).state:set('pwpTow', on or nil, true) end
end

local function active(vehicleId)
    return MySQL.single.await(('SELECT * FROM `%s` WHERE `vehicleId` = ? AND `releasedAt` IS NULL ORDER BY `id` DESC LIMIT 1'):format(T.impounds),
        { tonumber(vehicleId) })
end

local function rowById(id)
    return MySQL.single.await(('SELECT * FROM `%s` WHERE `id` = ?'):format(T.impounds), { tonumber(id) })
end

local function decorate(row)
    if not row then return nil end
    local lot = lotOf(row.lot)
    row.lotLabel = lot.label
    row.bill = TL.bill(row, now(), storage())
    local held, untilAt = TL.held(row, now())
    row.held, row.heldUntil = held, untilAt
    row.paid = row.paidAt ~= nil
    return row
end

function Impound.of(vehicleId) return decorate(active(vehicleId)) end

local function deptName(dept) return (PWP.dept(dept) or {}).short or 'Police' end

local function holdWords(row)
    if row.holdOpen == 1 then return 'It is held until the police release it.' end
    if row.holdUntil and row.holdUntil > now() then return ('It is held until %s.'):format(os.date('%d %b %H:%M', row.holdUntil)) end
    return 'You can collect it once the fee is paid.'
end

function Impound.preview(vehicleId)
    local v = Whip.core:GetVehicle(tonumber(vehicleId))
    if not v then return false, 'No such vehicle' end
    local owner = v.owner and v.owner.charId
    local bolo = v.plate and PWP.Records.boloForPlate(v.plate)
    local times = MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `vehicleId` = ?'):format(T.impounds), { v.id or v.vehicleId }) or 0
    local lots, reasons = {}, {}
    for _, l in ipairs(CFG.lots) do lots[#lots + 1] = { id = l.id, label = l.label } end
    for _, r in ipairs(CFG.reasons) do reasons[#reasons + 1] = { id = r.id, label = r.label, fee = r.fee, holdDays = r.holdDays, hold = r.hold } end
    return {
        vehicleId = v.id or v.vehicleId, plate = v.plate, model = v.model, state = v.state,
        owner = owner, ownerName = owner and (Whip.core:GetCharacterNames({ owner }) or {})[owner] or nil,
        bolo = bolo and { reason = bolo.reason, stolen = bolo.stolen == 1 } or nil, times = times, impounded = active(v.id or v.vehicleId) ~= nil,
        lots = lots, reasons = reasons, maxFee = CFG.maxFee, perDay = CFG.perDay, maxDays = CFG.maxDays, maxHoldDays = CFG.maxHoldDays,
        tow = v.entity ~= nil and towOnDuty(),
    }
end

local function park(src, v, via, lotId)
    local id = v.id or v.vehicleId
    local garage = garageOf(lotId)
    if via == 'garage' then
        if v.state ~= 'garaged' then return false, 'It is not in a garage: impound it where it stands' end
        local ok, why = Whip.core:SetVehicleGarage(id, garage)
        if not ok then return false, why end
    else
        if not v.entity or not DoesEntityExist(v.entity) then return false, 'The car is not out' end
        if via == 'street' and #(GetEntityCoords(v.entity) - GetEntityCoords(GetPlayerPed(src))) > 8.0 then return false, 'Stand by the car' end
        Whip.core:ReleaseVehicleEngine(id, 'tow')
        towMark(id, false)
        local ok, why = Whip.core:DespawnVehicle(id, { garage = garage, refuseOccupied = true })
        if not ok then return false, why end
    end
    local held, err = Whip.core:SetVehicleCustody(id, true)
    if not held then print(('[%s] impound custody %s: %s'):format(PWP.RES, tostring(v.plate), tostring(err))) end
    return true
end

function Impound.file(src, dept, spec)
    if type(spec) ~= 'table' then return false, 'Fill in the form' end
    local v = Whip.core:GetVehicle(tonumber(spec.vehicleId))
    if not v then return false, 'No such vehicle' end
    local id = v.id or v.vehicleId
    local owner = v.owner and v.owner.charId
    if not owner then return false, 'Nobody owns that car: tow it away instead' end
    if active(id) then return false, 'It is impounded already' end
    local reason = reasonOf(spec.reason)
    if not reason then return false, 'Pick a reason' end
    local lot = lotOf(spec.lot)
    local fee = math.floor(tonumber(spec.fee) or reason.fee)
    if fee < 0 or fee > CFG.maxFee then return false, ('The fee is $0 to $%d'):format(CFG.maxFee) end
    local photo = spec.photo and tostring(spec.photo) or ''
    if photo ~= '' and (#photo > 300 or not photo:find('^https?://%S+$')) then return false, 'The photo link must start with https://' end
    local holdOpen = (reason.hold == 'officer' or spec.holdOpen == true) and 1 or 0
    local holdDays = holdOpen == 1 and 0 or math.max(0, math.min(CFG.maxHoldDays, math.floor(tonumber(spec.holdDays) or reason.holdDays or 0)))
    local via = spec.via == 'garage' and 'garage' or (spec.via == 'export' and 'export' or 'street')
    local towing = spec.tow == true and via == 'street' and towOnDuty()
    if clampedRow(id) then Impound.unclamp(id, 'impounded') end
    if towing then
        if not v.entity or not DoesEntityExist(v.entity) then return false, 'The car is not out' end
        if #(GetEntityCoords(v.entity) - GetEntityCoords(GetPlayerPed(src))) > 8.0 then return false, 'Stand by the car' end
        Whip.core:HoldVehicleEngine(id, 'tow', 'Waiting for the tow truck')
        towMark(id, true)
    else
        local ok, why = park(src, v, via, lot.id)
        if not ok then return false, why end
    end
    local byChar = src and Whip.core:GetCharId(src)
    local rowId = MySQL.insert.await(('INSERT INTO `%s` (`vehicleId`, `plate`, `model`, `ownerCharId`, `lot`, `reason`, `fee`, `notes`, `photo`, `dept`, `byCharId`, `at`, `holdUntil`, `holdOpen`, `via`, `towState`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(T.impounds),
        { id, v.plate, v.model, owner, lot.id, reason.label, fee, PWP.Text.clean(spec.notes, 300), photo ~= '' and photo or nil, dept, byChar, now(),
          holdDays > 0 and now() + holdDays * DAY or nil, holdOpen, via, towing and 'waiting' or nil })
    if towing then
        local c = GetEntityCoords(v.entity)
        Whip.core:ShowBlip({ job = TOW.job, onDuty = true }, towBlip({ id = rowId }), { coords = c, label = 'Tow: ' .. (v.plate or 'car'), sprite = 68, color = 47 })
        for _, e in ipairs(Whip.core:GetClockedOnEmployees(TOW.job) or {}) do
            if GetResourceState('whip_phone') == 'started' then
                exports.whip_phone:Notify(e.source, { app = 'pwptow', title = 'Tow job', text = ('%s to %s'):format(v.plate or 'A car', lot.label), kind = 'command' })
            end
        end
    end
    local bolo = v.plate and PWP.Records.boloForPlate(v.plate)
    if bolo then PWP.Records.closeBolo(bolo.id, src) end
    local row = decorate(rowById(rowId))
    PWP.Mail.send(owner, deptName(dept), 'Impounded: ' .. (v.plate or ''),
        ('Your car %s was impounded at %s.\nReason: %s.\nFee: %s, plus %s a day for storage (at most %s).\n%s\nPay in the Courts app or at the lot office.')
            :format(v.plate or '', lot.label, reason.label, money(fee), money(CFG.perDay), money(row.bill.most), holdWords(row)))
    if src then Whip.core:LogActivity(src, 'impounded', { detail = ('%s (%s)'):format(v.plate or '?', reason.label) }) end
    TriggerEvent(PWP.event('impounded'), { vehicleId = id, plate = v.plate, owner = owner, by = src, impoundId = rowId, bolo = bolo and bolo.id or nil })
    return { id = rowId, plate = v.plate, bolo = bolo ~= nil, tow = towing or nil }
end

local function finishTow(src, v, row, byTow)
    local ok, why = park(src, v, 'tow', row.lot)
    if not ok then return false, why end
    MySQL.update.await(('UPDATE `%s` SET `towState` = \'done\', `towBy` = ? WHERE `id` = ?'):format(T.impounds),
        { byTow and Whip.core:GetCharId(src) or nil, row.id })
    Whip.core:HideBlip(towBlip(row))
    return true
end

function Impound.towJobs()
    local rows = MySQL.query.await(('SELECT `id`, `vehicleId`, `plate`, `model`, `lot`, `reason`, `at` FROM `%s` WHERE `towState` = \'waiting\' AND `releasedAt` IS NULL ORDER BY `at`'):format(T.impounds)) or {}
    for _, r in ipairs(rows) do
        r.lotLabel = lotOf(r.lot).label
        local v = Whip.core:GetVehicle(r.vehicleId)
        local c = v and v.entity and DoesEntityExist(v.entity) and GetEntityCoords(v.entity)
        if c then r.x, r.y = math.floor(c.x + 0.5), math.floor(c.y + 0.5) end
    end
    return rows
end

function Impound.towIt(src, veh)
    if not Whip.core:IsPlayerClockedOn(src, TOW.job) then return false, 'Go on duty as a tow driver' end
    local id = veh.id or veh.vehicleId
    local row = active(id)
    if not row or row.towState ~= 'waiting' then return false, 'Nobody asked for this car to be towed' end
    local player = Whip.core:GetPlayer(src)
    CreateThread(function()
        local done = Whip.core:Progress(src, { label = 'Hooking up the car...', duration = TOW.towSeconds * 1000, near = { vehicle = id, range = 6.0 } })
        if not done or not Whip.core:IsSessionCurrent(src, player.session) then return end
        local v = Whip.core:GetVehicle(id)
        local fresh = active(id)
        if not v or not fresh or fresh.towState ~= 'waiting' then return end
        local ok, why = finishTow(src, v, fresh, true)
        if not ok then return Whip.core:NotifyPlayer(src, why, 'error') end
        if TOW.pay > 0 then Whip.core:PayPlayer(src, TOW.pay, { reason = 'Tow to ' .. lotOf(fresh.lot).label }) end
        Whip.core:LogActivity(src, 'towed_to_lot', { detail = fresh.plate })
        Whip.core:NotifyPlayer(src, ('%s is at %s%s'):format(fresh.plate or 'The car', lotOf(fresh.lot).label, TOW.pay > 0 and (': ' .. money(TOW.pay) .. ' paid') or ''), 'success')
    end)
    return true
end

local function shiftOf(src)
    local charId = Whip.core:GetCharId(src)
    Impound.shift[charId] = Impound.shift[charId] or 0
    return charId
end

function Impound.haul(src, veh)
    local id = veh.id or veh.vehicleId
    if clampedRow(id) then Impound.unclamp(id, 'hauled') end
    local paid = false
    local h = CFG.haul
    local charId = shiftOf(src)
    local last = Impound.hauled[charId]
    local fresh = not veh.session and veh.plate and not Impound.plates[veh.plate]
    local ok, why = Whip.core:DespawnVehicle(id)
    if not ok then return false, why end
    if fresh and h.pay > 0 and (not last or now() - last >= h.cooldownSeconds) and Impound.shift[charId] < h.perShift then
        local done = Whip.core:PayPlayer(src, h.pay, { reason = 'Hauled an abandoned car' })
        if done then
            paid = true
            Impound.hauled[charId] = now()
            Impound.shift[charId] = Impound.shift[charId] + 1
        end
    end
    if veh.plate then Impound.plates[veh.plate] = now() end
    Whip.core:LogActivity(src, 'towed', { detail = veh.plate })
    return true, paid
end

function Impound.tow(src, veh, dept, reason)
    if not veh.owner or not veh.owner.charId or veh.session then
        local ok, why = Whip.core:DespawnVehicle(veh.id or veh.vehicleId)
        if not ok then return false, why end
        if src then Whip.core:LogActivity(src, 'towed', { detail = veh.plate }) end
        return true, 'towed'
    end
    local r = reasonOf(reason) or CFG.reasons[1]
    local done, why = Impound.file(src, dept, { vehicleId = veh.id or veh.vehicleId, reason = r.id, via = 'export' })
    if not done then return false, why end
    return true, 'impounded'
end

function Impound.release(vehicleId, by, note)
    local row = active(vehicleId)
    if not row then return false, 'It is not impounded' end
    local ok, why = Whip.core:SetVehicleCustody(row.vehicleId, false)
    if not ok then return false, why end
    MySQL.update.await(('UPDATE `%s` SET `releasedAt` = ?, `releasedBy` = ?, `releaseNote` = ? WHERE `id` = ?'):format(T.impounds),
        { now(), by and Whip.core:GetCharId(by) or nil, PWP.Text.clean(note, 200), row.id })
    return true, row
end

local paying = {}

local function charge(src, row)
    local bill = TL.bill(row, now(), storage())
    if bill.total <= 0 then return true, 0 end
    if MySQL.scalar.await(('SELECT `paidAt` FROM `%s` WHERE `id` = ?'):format(T.impounds), { row.id }) then return false, 'It was paid already' end
    local receipt, why = Whip.core:ChargePlayer(src, bill.total, { reason = 'Impound, ' .. (row.plate or '') })
    if not receipt then return false, why end
    local saved = Whip.core:CommitWithAction({ {
        query = ('UPDATE `%s` SET `paidAt` = ?, `paidAmount` = ? WHERE `id` = ? AND `paidAt` IS NULL'):format(T.impounds),
        values = { now(), bill.total, row.id },
    } }, { source = src })
    if not saved then
        Whip.core:RefundPlayer(receipt)
        return false, 'Could not save that: your money is back'
    end
    return true, bill.total, receipt
end

local function deposit(row, total)
    local acc = total > 0 and PWP.Fines.account(row.dept)
    if acc then Whip.core:BankSystemDeposit(acc, total, { reason = 'Impound fee ' .. (row.plate or '') }) end
end

function Impound.pay(src, id)
    local row = rowById(id)
    local charId = Whip.core:GetCharId(src)
    if not row or row.ownerCharId ~= charId or row.releasedAt then return false, 'That is not your impounded car' end
    if row.paidAt then return false, 'It is paid already' end
    if paying[charId] then return false, 'Already paying' end
    paying[charId] = true
    local ok, done, total = pcall(charge, src, row)
    paying[charId] = nil
    if not ok then print(('[%s] impound pay: %s'):format(PWP.RES, tostring(done))) return false, 'Could not pay' end
    if not done then return false, total end
    deposit(row, total)
    row = decorate(rowById(id))
    PWP.Mail.send(row.ownerCharId, 'Impound', 'Paid: ' .. (row.plate or ''),
        ('You paid %s for %s. %s'):format(money(row.paidAmount or 0), row.plate or '', row.held and holdWords(row) or ('Collect it at ' .. row.lotLabel .. '.')))
    return { paid = row.paidAmount }
end

local function spawnSpot(lot)
    if lot.spawn then return lot.spawn end
    local c, h = lot.coords, math.rad(lot.heading or 0.0)
    return vector4(c.x - math.sin(h) * 6.0, c.y + math.cos(h) * 6.0, c.z, (lot.heading or 0.0) + 90.0)
end

local function collect(src, lotId)
    local charId = Whip.core:GetCharId(src)
    local row = charId and MySQL.single.await(('SELECT * FROM `%s` WHERE `ownerCharId` = ? AND `lot` = ? AND `releasedAt` IS NULL ORDER BY `at` LIMIT 1'):format(T.impounds),
        { charId, lotId })
    if not row then return false, 'Nothing of yours is held here' end
    if row.towState == 'waiting' then return false, 'It is still on its way to the lot' end
    local held, untilAt = TL.held(row, now())
    if held then return false, untilAt and ('It is held until %s'):format(os.date('%d %b %H:%M', untilAt)) or 'It is held until the police release it' end
    local player = Whip.core:GetPlayer(src)
    local receipt, paidNow
    if not row.paidAt then
        local ok, total, r = charge(src, row)
        if not ok then return false, total end
        receipt, paidNow = r, total
    end
    local lot = lotOf(lotId)
    local ok, why = Impound.release(row.vehicleId, nil, 'collected')
    local released = ok
    if ok then ok, why = Whip.core:RetrieveVehicle(row.vehicleId, garageOf(lotId)) end
    if ok then ok, why = Whip.core:SpawnVehicle(row.vehicleId, spawnSpot(lot)) end
    if not ok then
        if released then
            Whip.core:SetVehicleCustody(row.vehicleId, true)
            MySQL.update.await(('UPDATE `%s` SET `releasedAt` = NULL, `releaseNote` = NULL WHERE `id` = ?'):format(T.impounds), { row.id })
        end
        if receipt and Whip.core:IsSessionCurrent(src, player.session) then
            Whip.core:RefundPlayer(receipt)
            MySQL.update.await(('UPDATE `%s` SET `paidAt` = NULL, `paidAmount` = NULL WHERE `id` = ?'):format(T.impounds), { row.id })
        end
        return false, why
    end
    if paidNow then deposit(row, paidNow) end
    PWP.Mail.send(charId, 'Impound', 'Released: ' .. (row.plate or ''), ('%s left %s.'):format(row.plate or 'Your car', lot.label))
    Whip.core:NotifyPlayer(src, ('%s is waiting outside.'):format(row.plate), 'success')
    return true
end

function Impound.lift(src, dept, id, note)
    local row = rowById(id)
    if not row or row.releasedAt then return false, 'It is not impounded' end
    local held = TL.held(row, now())
    if not held then return false, 'There is no hold to lift' end
    local can, why = Whip.core:HasJobPermission(src, dept, 'impound_override')
    if not can then return false, why or 'Your rank cannot lift a hold early' end
    note = PWP.Text.clean(note, 200)
    if not note or #note < 5 then return false, 'Say why the hold is lifted early' end
    MySQL.update.await(('UPDATE `%s` SET `holdOpen` = 0, `holdUntil` = NULL, `override` = 1, `liftedBy` = ?, `liftNote` = ? WHERE `id` = ?'):format(T.impounds),
        { Whip.core:GetCharId(src), note, row.id })
    Whip.core:LogActivity(src, 'impound_override', { detail = ('%s: %s'):format(row.plate or '?', note) })
    PWP.Mail.send(row.ownerCharId, deptName(dept), 'Hold lifted: ' .. (row.plate or ''),
        ('The hold on %s is lifted. Pay the fee and collect it at %s.'):format(row.plate or 'your car', lotOf(row.lot).label))
    return true
end

function Impound.lot(lotId)
    local sql = ('SELECT * FROM `%s` WHERE `releasedAt` IS NULL'):format(T.impounds)
    local args = {}
    if lotId then sql = sql .. ' AND `lot` = ?'; args[1] = lotId end
    local rows = MySQL.query.await(sql .. ' ORDER BY `at` DESC LIMIT 200', args) or {}
    local ids = {}
    for _, r in ipairs(rows) do decorate(r); ids[#ids + 1] = r.ownerCharId end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, r in ipairs(rows) do r.owner = names[r.ownerCharId] end
    return rows
end

function Impound.history(vehicleId)
    local rows = MySQL.query.await(('SELECT * FROM `%s` WHERE `vehicleId` = ? ORDER BY `id` DESC LIMIT 30'):format(T.impounds), { tonumber(vehicleId) }) or {}
    for _, r in ipairs(rows) do decorate(r) end
    return rows
end

function Impound.mine(charId)
    local rows = MySQL.query.await(('SELECT * FROM `%s` WHERE `ownerCharId` = ? AND `releasedAt` IS NULL ORDER BY `at`'):format(T.impounds), { tonumber(charId) }) or {}
    for _, r in ipairs(rows) do decorate(r) end
    return rows
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

AddEventHandler('whip_core:job:clockedOn', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.charId then return end
    Impound.shift[e.charId] = 0
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

local function adoptLegacy()
    local exists = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { T.legacy })
    if (exists or 0) == 0 then return end
    MySQL.query.await(([[INSERT INTO `%s` (`vehicleId`, `plate`, `ownerCharId`, `lot`, `reason`, `fee`, `dept`, `byCharId`, `at`, `holdOpen`, `via`)
        SELECT l.`vehicleId`, l.`plate`, l.`ownerCharId`, ?, COALESCE(l.`reason`, 'Impounded'), l.`fee`, l.`dept`, l.`byCharId`, l.`at`, 0, 'street'
        FROM `%s` l WHERE NOT EXISTS (SELECT 1 FROM `%s` n WHERE n.`vehicleId` = l.`vehicleId` AND n.`at` = l.`at`)]]):format(T.impounds, T.legacy, T.impounds),
        { CFG.lots[1].id })
end

Whip.register(function()
    local ok = Whip.core:EnsureTable(T.clamps, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `vehicleId` INT UNSIGNED NOT NULL PRIMARY KEY, `plate` VARCHAR(12) NULL, `ownerCharId` INT UNSIGNED NULL,
        `fineId` INT UNSIGNED NULL, `byCharId` INT UNSIGNED NULL, `at` INT UNSIGNED NOT NULL, INDEX (`fineId`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.clamps))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T.clamps)) end
    ok = Whip.core:EnsureTable(T.impounds, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `vehicleId` INT UNSIGNED NOT NULL, `plate` VARCHAR(12) NULL,
        `model` VARCHAR(40) NULL, `ownerCharId` INT UNSIGNED NOT NULL, `lot` VARCHAR(32) NOT NULL, `reason` VARCHAR(120) NOT NULL,
        `fee` INT UNSIGNED NOT NULL DEFAULT 0, `notes` VARCHAR(300) NULL, `photo` VARCHAR(300) NULL, `dept` VARCHAR(50) NULL,
        `byCharId` INT UNSIGNED NULL, `at` INT UNSIGNED NOT NULL, `via` VARCHAR(8) NOT NULL DEFAULT 'street',
        `holdUntil` INT UNSIGNED NULL, `holdOpen` TINYINT(1) NOT NULL DEFAULT 0, `override` TINYINT(1) NOT NULL DEFAULT 0,
        `liftedBy` INT UNSIGNED NULL, `liftNote` VARCHAR(200) NULL, `paidAt` INT UNSIGNED NULL, `paidAmount` INT UNSIGNED NULL,
        `releasedAt` INT UNSIGNED NULL, `releasedBy` INT UNSIGNED NULL, `releaseNote` VARCHAR(200) NULL,
        `towState` VARCHAR(8) NULL, `towBy` INT UNSIGNED NULL,
        INDEX (`vehicleId`, `releasedAt`), INDEX (`ownerCharId`, `releasedAt`), INDEX (`lot`, `releasedAt`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.impounds), {
        { id = 'impounds_tow', statements = {
            { sql = ('ALTER TABLE `%s` ADD COLUMN `towState` VARCHAR(8) NULL'):format(T.impounds), unless = { column = { T.impounds, 'towState' } } },
            { sql = ('ALTER TABLE `%s` ADD COLUMN `towBy` INT UNSIGNED NULL'):format(T.impounds), unless = { column = { T.impounds, 'towBy' } } },
        } },
    })
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T.impounds)) end
    adoptLegacy()
    for _, row in ipairs(MySQL.query.await(('SELECT `id`, `vehicleId`, `plate` FROM `%s` WHERE `towState` = \'waiting\' AND `releasedAt` IS NULL'):format(T.impounds)) or {}) do
        Whip.core:HoldVehicleEngine(row.vehicleId, 'tow', 'Waiting for the tow truck')
        towMark(row.vehicleId, true)
    end

    Whip.core:RegisterItem(CLAMP, { name = 'Wheel Clamp', desc = 'Locks a wheel. The owner pays a fine to have it removed.',
        weight = 4.0, type = 'tool', stack = true, maxStack = 4, prop = 'pwp_wheel_clamp' })

    for _, row in ipairs(MySQL.query.await(('SELECT `vehicleId`, `fineId` FROM `%s`'):format(T.clamps)) or {}) do
        Whip.core:HoldVehicleEngine(row.vehicleId, HOLD, holdText(row))
        mark(row.vehicleId, true)
    end

    for i, lot in ipairs(CFG.lots) do
        local key, c = garageOf(lot.id), lot.coords
        if not Whip.core:GetGarage(key) then
            local g, why = Whip.core:CreateGarage({ key = key, name = lot.label, x = c.x, y = c.y, z = c.z, heading = lot.heading })
            if not g then print(('[%s] impound garage %d: %s'):format(PWP.RES, i, tostring(why))) end
        end
        local id, why = Whip.core:AddPoint({
            at = { coords = vector3(c.x, c.y, c.z) }, label = lot.label, icon = 'car', audience = 'everyone',
            reach = 2.5, seeFrom = 12.0,
            options = { { id = 'collect', label = 'Get my car back' } },
            onUse = function(source) return collect(source, lot.id) end,
        })
        if not id then print(('[%s] impound office %d: %s'):format(PWP.RES, i, tostring(why))) end
    end

    Whip.core:SecureEvent(PWP.event('policecar'), {
        rateLimit = 1500,
        params = { { 'veh', 'vehicle', { anyOwner = true, session = true } }, { 'how', 'enum', { 'clamp', 'unclamp', 'impound', 'cut', 'tow' } } },
        near = { at = 'vehicle', range = 6.0 },
    }, function(source, _, veh, how)
        if how == 'cut' then return cut(source, veh) end
        if how == 'tow' then
            local ok3, why3 = Impound.towIt(source, veh)
            if not ok3 then return false, why3 end
            return
        end
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
        if not veh.owner or not veh.owner.charId or veh.session then
            local done, paid = Impound.haul(source, veh)
            if not done then return false, paid end
            return Whip.core:NotifyPlayer(source, paid and ('Hauled away: %s paid'):format(money(CFG.haul.pay)) or 'Hauled away', 'success')
        end
        local waiting = active(veh.id or veh.vehicleId)
        if waiting and waiting.towState == 'waiting' then
            local done, err = finishTow(source, veh, waiting, false)
            if not done then return false, err end
            return Whip.core:NotifyPlayer(source, 'Impounded ' .. (veh.plate or '') .. ' without the tow truck', 'success')
        end
        local form, why = Impound.preview(veh.id or veh.vehicleId)
        if not form then return false, why end
        if form.impounded then return false, 'It is impounded already' end
        form.via = 'street'
        TriggerClientEvent(PWP.event('impoundForm'), source, form)
    end)
end)

Whip.register(function()
    for action, fn in pairs({
        jobs = function() return Impound.towJobs() end,
        waypoint = function(source, a)
            local x, y = tonumber(a.x), tonumber(a.y)
            if not x or not y then return false, 'That car is not out' end
            return Whip.core:SetPlayerWaypoint(source, vector3(x + 0.0, y + 0.0, 0.0))
        end,
    }) do
        Whip.core:SecureCallback(PWP.RES .. ':tow:' .. action, { rateLimit = 500, params = { { 'args', 'any' } } }, function(source, _, args)
            if not Whip.core:IsPlayerClockedOn(source, TOW.job) then return false, 'Go on duty as a tow driver' end
            local ok, result, why = pcall(fn, source, type(args) == 'table' and args or {})
            if not ok then print(('[%s] tow %s: %s'):format(PWP.RES, action, tostring(result))) return false, 'Something went wrong' end
            if result == false then return false, why end
            return result
        end)
    end
end)

exports('Impound', function(vehicleId, opts)
    opts = type(opts) == 'table' and opts or {}
    local v = Whip.core:GetVehicle(tonumber(vehicleId))
    if not v then return false, 'No such vehicle' end
    return Impound.tow(tonumber(opts.by), v, opts.dept, opts.reason)
end)
exports('ReleaseImpound', function(vehicleId) return Impound.release(tonumber(vehicleId)) end)
exports('IsClamped', function(vehicleId) return clampedRow(tonumber(vehicleId)) ~= nil end)
exports('GetImpound', function(vehicleId) return Impound.of(tonumber(vehicleId)) end)
exports('GetMyImpounds', function(charId) return Impound.mine(charId) end)
exports('PayImpound', function(src, id) return Impound.pay(tonumber(src), id) end)

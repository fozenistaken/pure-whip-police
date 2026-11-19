HARNESS = arg[1] .. '/tests/harness'
local POLICE = arg[1]
local COURTS = arg[2]
local W = dofile(HARNESS .. '/world.lua')

local pass, fail = 0, 0
local function check(name, cond, detail)
    if cond then pass = pass + 1 else fail = fail + 1; W.realPrint('FAIL ' .. name .. (detail and (': ' .. tostring(detail)) or '')) end
end
local function scenario(name, fn)
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then fail = fail + 1; W.realPrint('CRASH ' .. name .. ': ' .. tostring(err)) end
    if W.errors and #W.errors > 0 then
        for _, e in ipairs(W.errors) do fail = fail + 1; W.realPrint('THREAD ERROR in ' .. name .. ': ' .. e) end
        W.errors = {}
    end
end
local function rows(sql, args) return MySQL.query.await(sql, args) end
local function count(sql, args) return MySQL.scalar.await(sql, args) or 0 end

W.server('DROP DATABASE IF EXISTS `' .. W.dbName .. '`; CREATE DATABASE `' .. W.dbName .. '` CHARACTER SET utf8mb4')
W.sql([[CREATE TABLE `characters` (`charId` INT PRIMARY KEY, `firstName` VARCHAR(40), `lastName` VARCHAR(40),
    `dateOfBirth` VARCHAR(20), `gender` VARCHAR(10), `deleted` DATETIME NULL)]])
W.sql([[CREATE TABLE `vehicles` (`vehicleId` INT PRIMARY KEY, `ownerCharId` INT, `model` VARCHAR(40), `plate` VARCHAR(12), `state` VARCHAR(12))]])
W.sql([[CREATE TABLE `ground_items` (`id` INT AUTO_INCREMENT PRIMARY KEY, `item` VARCHAR(60), `amount` INT,
    `metadata` LONGTEXT, `x` FLOAT, `y` FLOAT, `z` FLOAT)]])

local ALL = { cuff = true, search = true, jail = true, fine = true, fine_custom = true, armory = true, fleet = true,
    records = true, warrants = true, command = true, prison_staff = true, dispatch = true }
W.player(1, { charId = 1, name = 'Ava Reyes', dept = 'lspd', jobs = { lspd = { name = 'Captain', level = 80 } }, perms = ALL, coords = vector3(10, 10, 30) })
W.player(2, { charId = 2, name = 'Marcus Vale', coords = vector3(11, 10, 30) })
W.player(3, { charId = 3, name = 'Ruth Okafor', dept = 'doj', jobs = { doj = { name = 'Judge', level = 60 } },
    perms = { rule = true, bail = true, schedule = true, prosecute = true }, coords = vector3(500, 500, 30) })
W.player(4, { charId = 4, name = 'Dana Whitfield', dept = 'lawyer', jobs = { lawyer = { name = 'Attorney', level = 40 } },
    perms = { represent = true }, coords = vector3(600, 600, 30) })
W.player(5, { charId = 5, name = 'Lena Ortiz', coords = vector3(12, 11, 30) })
W.player(6, { charId = 6, name = 'Cody Park', dept = 'lspd', jobs = { lspd = { name = 'Cadet', level = 1 } }, perms = { records = true, cuff = true }, coords = vector3(9, 9, 30) })
for _, p in pairs(W.players) do
    local f, l = p.name:match('(%S+) (%S+)')
    W.sql(("INSERT INTO characters VALUES (%d, '%s', '%s', '1990-01-01', 'male', NULL)"):format(p.charId, f, l))
end

W.load(POLICE, 'pure-whip-police')
Config.SpeedCameras = { { label = 'Test cam', coords = vector3(100, 0, 0), radius = 25, limit = 60, tolerance = 0, fine = 200 } }
Config.Cameras = { { label = 'Cam one', coords = vector3(10, 10, 32), heading = 0, pitch = -10, fov = 60 },
    { label = 'Cam two', coords = vector3(300, 300, 32), heading = 90, pitch = -10, fov = 60 } }
local policeConfig = Config
W.load(COURTS, 'pure-whip-courts')
local courtsConfig = Config
Config = policeConfig
for k, v in pairs(courtsConfig) do if Config[k] == nil then Config[k] = v end end
W.boot()

local P = 'pure-whip-police'
local function ev(n) return P .. ':' .. n end

scenario('boot', function()
    check('no missing exports at boot', #W.missing == 0, table.concat(W.missing, ', '))
    check('penal code seeded', #PWP.Records.penalList > 10, #PWP.Records.penalList)
    check('evidence locker made', next(W.points) ~= nil)
    check('speed camera zone', W.zones['pure-whip-police:speedcam:1'] ~= nil)
    check('impound garage', W.garages.pwp_impound ~= nil)
    check('court jobs registered', W.exports['pure-whip-courts'] and W.exports['pure-whip-courts'].Arraign ~= nil)
end)

scenario('casings from shots', function()
    W.fire('whip_gunny:weapon:fired', 'whip_gunny', nil, { source = 2, serial = 'SER123', item = 'gunny_pistol', shots = 3, coords = vector3(10, 10, 30) })
    W.advance(500)
    W.fire('whip_gunny:weapon:fired', 'whip_gunny', nil, { source = 2, serial = 'SER123', item = 'gunny_pistol', shots = 2, coords = vector3(12, 10, 30) })
    W.advance(4000)
    local r = rows("SELECT * FROM ground_items WHERE item = 'pure-whip-police_casing'")
    check('one pile for the burst', #r == 1, #r)
    check('pile holds 5 casings', r[1] and r[1].amount == 5, r[1] and r[1].amount)
    local meta = r[1] and json.decode(r[1].metadata) or {}
    check('casing carries the serial', meta.serial == 'SER123')
end)

local function slotOf(src, item)
    for slot, s in pairs(W.players[src].items) do if s.item == item then return slot, s end end
end

scenario('bag a casing and analyse it', function()
    W.core.AddItem(nil, 1, 'pure-whip-police_evidence_bags', 5)
    W.core.AddItem(nil, 1, 'pure-whip-police_casing', 5, { serial = 'SER123', gun = 'gunny_pistol', at = os.time() })
    local slot, s = slotOf(1, 'pure-whip-police_casing')
    local ok, why = W.actions['pure-whip-police_bag'](1, nil, s, { kind = 'player', id = 1, sub = 'player', slot = slot })
    check('bagging works', ok == true, why)
    local _, bag = slotOf(1, 'pure-whip-police_evidence')
    check('bag holds the casing', bag and bag.metadata.kind == 'casing' and bag.metadata.serial == 'SER123', bag and json.encode(bag.metadata))
    check('one bag used', select(2, slotOf(1, 'pure-whip-police_evidence_bags')).amount == 4)
    local lab
    for _, pt in pairs(W.points) do if pt.label == 'Evidence room' then lab = pt end end
    check('evidence room point exists', lab ~= nil)
    if lab then lab.onUse(1, { option = 'lab' }) end
    local _, done = slotOf(1, 'pure-whip-police_evidence')
    check('lab wrote a result', done and done.metadata.result ~= nil, done and json.encode(done.metadata))
    check('evidence row saved', count("SELECT COUNT(*) FROM pure_whip_police_evidence WHERE serial = 'SER123'") >= 1)
end)

scenario('blood on death, swab and samples', function()
    W.fire('whip_core:player:died', 'whip_core', nil, { source = 2, charId = 2 })
    local blood
    for _, pt in pairs(W.points) do if pt.label == 'Blood' then blood = pt end end
    check('blood mark appears', blood ~= nil)
    if blood then blood.onUse(1, { option = 'collect' }) end
    local found
    for _, s in pairs(W.players[1].items) do if s.item == 'pure-whip-police_evidence' and s.metadata.kind == 'blood' then found = s end end
    check('blood swabbed into a bag', found ~= nil)
    PWP.Contact.cuff(1, 2, 'hard')
    local got, why = W.cb('pure-whip-police:mdt:takeSamples', 1, { charId = 2 })
    check('samples taken from a cuffed suspect', got and got.dna == found.metadata.dna, why)
    local lab
    for _, pt in pairs(W.points) do if pt.label == 'Evidence room' then lab = pt end end
    lab.onUse(1, { option = 'lab' })
    local r = W.cb('pure-whip-police:mdt:evidence', 1, { q = found.metadata.dna })
    check('DNA search names the person', r and r.owner == 2, r and json.encode(r))
    PWP.Contact.uncuff(1, 2)
end)

scenario('plate reader and speed camera', function()
    local car = W.car({ plate = 'VALE 77', owner = 2, coords = vector3(20, 10, 30) })
    PWP.Records.addBolo({ plate = 'VALE 77', reason = 'Robbery getaway', hours = 2, by = 1 })
    W.event(ev('plate'), 1, car.netId)
    local hit = false
    for _, c in ipairs(W.client) do if c.name == ev('plateHit') and c.target == 1 then hit = true end end
    check('BOLO plate hits', hit)
    check('sighting stored', PWP.Traffic.lastSeen('VALE 77') ~= nil)
    local speeder = W.car({ plate = 'FAST 1', owner = 5, coords = vector3(100, 0, 0), velocity = vector3(30, 0, 0), driver = 5 })
    W.players[5].vehicle = speeder.entity
    W.fire('whip_core:zone:entered', 'whip_core', nil, { zoneId = 'pure-whip-police:speedcam:1', source = 5 })
    check('speeding fine to the owner', count('SELECT COUNT(*) FROM pure_whip_police_fines WHERE charId = 5') == 1)
    W.fire('whip_core:zone:entered', 'whip_core', nil, { zoneId = 'pure-whip-police:speedcam:1', source = 5 })
    check('no second fine within a minute', count('SELECT COUNT(*) FROM pure_whip_police_fines WHERE charId = 5') == 1)
    W.players[5].vehicle = nil
end)

local CASE
scenario('booking, not guilty, bail, lawyer, hearing, deal', function()
    W.as('pure-whip-police', PWP.Contact.cuff, 1, 2, 'hard')
    local r, why = W.cb('pure-whip-police:mdt:book', 1, { charId = 2, charges = { { code = 'T107', count = 1 } } })
    check('booking asks for a plea', r and r.pending, why)
    local token
    for _, c in ipairs(W.client) do if c.name == 'pure-whip-courts:plea' and c.target == 2 then token = c.args[1] end end
    check('plea question reached the suspect', token ~= nil)
    W.event('pure-whip-courts:plea', 2, token, false)
    local c = rows("SELECT * FROM pure_whip_courts_cases WHERE charId = 2 AND status = 'open'")[1]
    check('case opened', c ~= nil)
    CASE = c and c.id
    check('bail due', c and c.bailState == 'due' and c.bail > 0, c and c.bailState)
    check('held for court', PWP.Prison.jailed[2] ~= nil and PWP.Prison.jailed[2].months == 0)
    local before = W.players[5].money
    local ok, err = W.cb('pure-whip-courts:app:postBail', 5, { id = CASE })
    check('someone else posts bail', ok == true, err)
    check('bail money taken', W.players[5].money == before - c.bail)
    check('released from remand', PWP.Prison.jailed[2] == nil)
    check('lawyer request', W.cb('pure-whip-courts:app:requestLawyer', 2, { id = CASE, lawyer = 4 }) == true)
    check('lawyer takes it', W.cb('pure-whip-courts:app:answerLawyer', 4, { id = CASE, accept = true }) == true)
    ok, err = W.cb('pure-whip-courts:app:schedule', 3, { id = CASE, at = os.time() + 3600, room = 'Courtroom 1' })
    check('judge sets a hearing', ok == true, err)
    W.advance(1000 * 60 * 47)
    check('reminder sent before the hearing', #W.notesFor(2, 'phone') > 0)
    ok, err = W.cb('pure-whip-courts:app:deal', 3, { id = CASE, codes = { 'T107' } })
    check('deal offered', ok == true, err)
    ok, err = W.cb('pure-whip-courts:app:answerDeal', 2, { id = CASE, accept = true })
    check('deal taken', ok == true, err)
    local done = rows('SELECT * FROM pure_whip_courts_cases WHERE id = ?', { CASE })[1]
    check('case closed as a deal', done and done.status == 'closed' and done.outcome == 'deal', done and done.outcome)
    check('sentenced to prison with the discount', PWP.Prison.jailed[2] and PWP.Prison.jailed[2].months == 11, PWP.Prison.jailed[2] and PWP.Prison.jailed[2].months)
    check('bail paid the fine or came back', done and (done.bailState == 'applied' or done.bailState == 'returned'), done and done.bailState)
    PWP.Prison.release(2, { early = true })
end)

scenario('guilty plea, no-show and double ruling', function()
    W.players[2].coords = vector3(11, 10, 30)
    W.as('pure-whip-police', PWP.Contact.cuff, 1, 2, 'hard')
    local mark = #W.client
    W.cb('pure-whip-police:mdt:book', 1, { charId = 2, charges = { { code = 'P105', count = 1 } } })
    local token
    for i = mark + 1, #W.client do local c = W.client[i] if c.name == 'pure-whip-courts:plea' and c.target == 2 then token = c.args[1] end end
    W.event('pure-whip-courts:plea', 2, token, true)
    check('guilty plea jails at once with the cut', PWP.Prison.jailed[2] and PWP.Prison.jailed[2].months == 4, PWP.Prison.jailed[2] and PWP.Prison.jailed[2].months)
    PWP.Prison.release(2, { early = true })
    local id = exports['pure-whip-courts']:OpenCase({ charId = 2, charges = { { code = 'P103', count = 1 } }, byCharId = 1, dept = 'lspd' })
    check('open case export', tonumber(id) ~= nil, id)
    local ok1 = W.cb('pure-whip-courts:app:rule', 3, { id = id, verdict = 'no_show' })
    local ok2, why2 = W.cb('pure-whip-courts:app:rule', 3, { id = id, verdict = 'not_guilty' })
    check('no-show ruled', ok1 == true)
    check('second ruling refused', ok2 == false, why2)
    check('warrant for the no-show', count("SELECT COUNT(*) FROM pure_whip_police_warrants WHERE charId = 2 AND reason LIKE 'Failed to appear%'") == 1)
end)

scenario('clamp, pay, impound and collect', function()
    local car = W.car({ plate = 'CLMP 1', owner = 5, coords = vector3(12, 10, 30) })
    W.core.AddItem(nil, 1, 'pure-whip-police_clamp', 1)
    W.event(ev('policecar'), 1, W.core.GetVehicle(nil, car.id), 'clamp')
    check('clamp saved', count('SELECT COUNT(*) FROM pure_whip_police_clamps WHERE vehicleId = ?', { car.id }) == 1)
    check('engine held', W.holds[car.id .. ':clamp'] ~= nil)
    check('clamp item used', slotOf(1, 'pure-whip-police_clamp') == nil)
    check('owner fined', count("SELECT COUNT(*) FROM pure_whip_police_fines WHERE charId = 5 AND reason LIKE 'Wheel clamp%'") == 1)
    W.as('pure-whip-police', PWP.Fines.payAll, 5, 1)
    check('paying removes the clamp', count('SELECT COUNT(*) FROM pure_whip_police_clamps WHERE vehicleId = ?', { car.id }) == 0)
    check('engine free', W.holds[car.id .. ':clamp'] == nil)
    local sent = #W.client
    W.event(ev('policecar'), 1, W.core.GetVehicle(nil, car.id), 'impound')
    local form
    for i = sent + 1, #W.client do if W.client[i].name == ev('impoundForm') then form = W.client[i].args[1] end end
    check('street impound opens the form', form and form.via == 'street' and form.ownerName == 'Lena Ortiz', form and json.encode(form))
    check('nothing impounded before the form is sent', not W.custody[car.id])
    local r, why = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = car.id, reason = 'parking', lot = 'davis', via = 'street', notes = 'On the kerb' } })
    check('impound filed from the form', r and r.id, why)
    check('impounded under custody', W.custody[car.id] == true)
    check('owner gets a letter', count("SELECT COUNT(*) FROM pure_whip_police_mail WHERE charId = 5 AND title LIKE 'Impounded%'") == 1)
    local office
    for _, pt in pairs(W.points) do if pt.label == 'Davis Impound' then office = pt end end
    local before = W.players[5].money
    local ok
    ok, why = office.onUse(5, { option = 'collect' })
    check('owner collects the car', ok == true, why)
    check('reason fee charged', W.players[5].money == before - 250, before - W.players[5].money)
    check('custody released and car out', not W.custody[car.id] and car.out == true)
    check('history kept after release', count('SELECT COUNT(*) FROM pure_whip_police_impounds WHERE vehicleId = ? AND releasedAt IS NOT NULL', { car.id }) == 1)
end)

scenario('impound holds, override, garage path, lot, BOLO, haul', function()
    local car = W.car({ plate = 'HOLD 1', owner = 5, coords = vector3(12, 10, 30) })
    W.cb('pure-whip-police:mdt:addBolo', 1, { plate = 'HOLD 1', reason = 'Seen leaving a robbery', stolen = true })
    local pv = W.cb('pure-whip-police:mdt:impoundPreview', 1, { vehicleId = car.id })
    check('preview warns of a stolen BOLO', pv and pv.bolo and pv.bolo.stolen == true, pv and json.encode(pv.bolo))
    check('preview counts earlier impounds', pv and pv.times == 0)
    local r, why = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = car.id, reason = 'dui', fee = 99999999, via = 'street' } })
    check('fee over the cap refused', r == false)
    r = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = car.id, reason = 'dui', fee = 1200, via = 'street', photo = 'javascript:x' } })
    check('bad photo link refused', r == false)
    r, why = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = car.id, reason = 'dui', fee = 1200, via = 'street', photo = 'https://i.example/x.png' } })
    check('impounded with a 2-day hold', r and r.id and r.bolo == true, why)
    check('BOLO closed by the impound', count("SELECT COUNT(*) FROM pure_whip_police_bolos WHERE plate = 'HOLD 1' AND status = 'active'") == 0)
    local office
    for _, pt in pairs(W.points) do if pt.label == 'Davis Impound' then office = pt end end
    local ok, err = office.onUse(5, { option = 'collect' })
    check('held car cannot be collected', ok == false and tostring(err):find('held until') ~= nil, err)
    local paid, perr = W.as('pure-whip-police', PWP.Impound.pay, 5, r.id)
    check('owner pays in the app while held', paid and paid.paid == 1200, perr)
    ok = W.cb('pure-whip-police:mdt:liftHold', 6, { id = r.id, note = 'Wrong car' })
    check('a cadet cannot lift a hold', ok == false)
    ok = W.cb('pure-whip-police:mdt:liftHold', 1, { id = r.id, note = 'no' })
    check('lifting needs a reason', ok == false)
    W.players[1].perms.impound_override = true
    ok, err = W.cb('pure-whip-police:mdt:liftHold', 1, { id = r.id, note = 'Driver was not drunk after all' })
    check('captain lifts the hold early', ok == true, err)
    check('override logged', count('SELECT COUNT(*) FROM pure_whip_police_impounds WHERE id = ? AND override = 1', { r.id }) == 1)
    local lot = W.cb('pure-whip-police:mdt:lot', 1, {})
    local held
    for _, row in ipairs(lot and lot.rows or {}) do if row.plate == 'HOLD 1' then held = row end end
    check('lot lists the held car with its bill', held and held.bill.total == 1200, held and json.encode(held))
    local before = W.players[5].money
    ok, err = office.onUse(5, { option = 'collect' })
    check('paid car collected without paying again', ok == true and W.players[5].money == before, err)
    local parked = W.car({ plate = 'GRG 1', owner = 5, coords = vector3(500, 500, 30) })
    parked.out = false
    r, why = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = parked.id, reason = 'evidence', via = 'garage' } })
    check('MDT impounds a garaged car', r and r.id and parked.garage == 'pwp_impound', why)
    check('evidence hold is until an officer lifts it', count('SELECT COUNT(*) FROM pure_whip_police_impounds WHERE id = ? AND holdOpen = 1', { r and r.id or 0 }) == 1)
    local outCar = W.car({ plate = 'OUT 1', owner = 5, coords = vector3(500, 500, 30) })
    r = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = outCar.id, reason = 'parking', via = 'garage' } })
    check('MDT cannot impound a car that is out', r == false)
    r = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = outCar.id, reason = 'parking', via = 'street' } })
    check('street impound needs the officer by the car', r == false)
    local hist = W.cb('pure-whip-police:mdt:impoundHistory', 1, { vehicleId = car.id })
    check('history lists the earlier impound', hist and #hist == 1)
    local junk = W.car({ plate = 'JUNK 1', coords = vector3(12, 10, 30) })
    local paidBefore = #W.paid
    W.event(ev('policecar'), 1, W.core.GetVehicle(nil, junk.id), 'impound')
    check('ownerless car hauled with a payout', junk.out == false and #W.paid == paidBefore + 1 and W.paid[#W.paid].amount == Config.Impound.haul.pay)
    local junk2 = W.car({ plate = 'JUNK 2', coords = vector3(12, 10, 30) })
    W.event(ev('policecar'), 1, W.core.GetVehicle(nil, junk2.id), 'impound')
    check('second haul inside the cooldown pays nothing', junk2.out == false and #W.paid == paidBefore + 1)
end)

scenario('tow truck job', function()
    local car = W.car({ plate = 'TOW 1', owner = 2, coords = vector3(12, 10, 30) })
    W.players[1].coords = vector3(10, 10, 30)
    local pv = W.cb('pure-whip-police:mdt:impoundPreview', 1, { vehicleId = car.id })
    check('no tow offered with no driver on duty', pv and pv.tow == false)
    W.players[5].dept, W.players[5].coords = 'tow', vector3(13, 10, 30)
    pv = W.cb('pure-whip-police:mdt:impoundPreview', 1, { vehicleId = car.id })
    check('tow offered when a driver is on duty', pv and pv.tow == true)
    local r, why = W.cb('pure-whip-police:mdt:impoundFile', 1, { spec = { vehicleId = car.id, reason = 'parking', via = 'street', tow = true } })
    check('tow called, the car waits with its engine off', r and r.tow and car.out ~= false and W.holds[car.id .. ':tow'] ~= nil, why)
    check('tow drivers get a map marker', r and W.blips['pwp_tow_' .. r.id] ~= nil)
    local jobs = W.cb('pure-whip-police:tow:jobs', 5, {})
    check('tow app lists the car', jobs and #jobs == 1 and jobs[1].plate == 'TOW 1', jobs and json.encode(jobs))
    check('only tow drivers read the tow list', W.cb('pure-whip-police:tow:jobs', 1, {}) == false)
    local office
    for _, pt in pairs(W.points) do if pt.label == 'Davis Impound' then office = pt end end
    local ok, err = office.onUse(2, { option = 'collect' })
    check('a car on its way cannot be collected', ok == false and tostring(err):find('on its way') ~= nil, err)
    W.progress = true
    local before = #W.paid
    W.event(ev('policecar'), 5, W.core.GetVehicle(nil, car.id), 'tow')
    W.advance(Config.Tow.towSeconds * 1000 + 500)
    check('towed into the lot', car.out == false and W.custody[car.id] == true and W.holds[car.id .. ':tow'] == nil)
    check('tow driver paid', #W.paid == before + 1 and W.paid[#W.paid].amount == Config.Tow.pay)
    check('tow marker gone', r and W.blips['pwp_tow_' .. r.id] == nil)
    check('tow list empty again', #(W.cb('pure-whip-police:tow:jobs', 5, {}) or { 1 }) == 0)
    W.players[5].dept = nil
end)

scenario('tickets, signing, contest and court ruling', function()
    W.players[1].coords, W.players[2].coords = vector3(10, 10, 30), vector3(11, 10, 30)
    local near = W.cb('pure-whip-police:ticket:nearby', 1, { people = { 2, 3 }, cars = {} })
    check('ticket book lists only who is near', near and #near.people == 1 and near.people[1].name == 'Marcus Vale', near and json.encode(near.people))
    check('ticket book offers ticket charges only', near and #near.penal > 0)
    local bad = W.cb('pure-whip-police:ticket:write', 1, { kind = 'citation', target = 2, codes = { 'V106' } })
    check('a felony cannot go on a citation', bad == false)
    bad = W.cb('pure-whip-police:ticket:write', 1, { kind = 'citation', target = 2, codes = { 'K101' } })
    check('a parking charge cannot go on a citation', bad == false)
    local t, why = W.cb('pure-whip-police:ticket:write', 1, { kind = 'citation', target = 2, codes = { 'T101', 'T102' }, place = 'Vinewood Blvd', notes = '65 in a 40' })
    check('citation written', t and t.number and t.number:find('^CIT%-') and t.amount == 550, why or (t and json.encode(t)))
    check('both sides get paper', slotOf(1, 'pure-whip-police_ticket') ~= nil and slotOf(2, 'pure-whip-police_ticket') ~= nil)
    local again = W.cb('pure-whip-police:ticket:write', 1, { kind = 'warning', target = 2, codes = { 'T101' } })
    check('cooldown between tickets', again == false)
    W.advance((Config.Tickets.cooldownSeconds + 30) * 1000)
    local warn = W.cb('pure-whip-police:ticket:write', 1, { kind = 'warning', target = 2, codes = { 'T101' } })
    check('warning written with no fine', warn and warn.amount == 0 and warn.number:find('^WRN%-'))
    W.advance((Config.Tickets.cooldownSeconds + 30) * 1000)
    local car = W.car({ plate = 'PARK 1', owner = 5, coords = vector3(14, 10, 30) })
    local pk = W.cb('pure-whip-police:ticket:write', 1, { kind = 'parking', vehicleId = car.id, codes = { 'K102' } })
    check('parking ticket goes to the owner', pk and pk.number:find('^PRK%-') and count('SELECT COUNT(*) FROM pure_whip_police_fines WHERE id = ? AND charId = 5', { pk.id }) == 1)
    check('owner mailed about the parking ticket', count("SELECT COUNT(*) FROM pure_whip_police_mail WHERE charId = 5 AND title LIKE 'Parking ticket%'") == 1)
    local ok, err = W.as('pure-whip-police', PWP.Fines.contest, 2, t.id, 'too short')
    check('contest needs a reason', ok == false)
    ok = W.as('pure-whip-police', PWP.Fines.contest, 2, warn.id, 'I was not speeding at all, the radar was wrong.')
    check('a warning cannot be contested', ok == false)
    ok, err = W.as('pure-whip-police', PWP.Fines.contest, 2, t.id, 'I was not speeding at all, the radar was wrong.')
    check('unsigned citation contested', ok == true, err)
    check('issuing officer told to add a statement', count("SELECT COUNT(*) FROM pure_whip_police_mail WHERE charId = 1 AND title LIKE 'Contested%'") == 1)
    ok = W.cb('pure-whip-police:mdt:ticketStatement', 1, { id = t.id, text = 'Radar read 65 in a 40, twice.' })
    check('officer statement saved', ok == true)
    local paid = W.as('pure-whip-police', PWP.Fines.pay, 2, 1, t.id)
    check('a contested ticket cannot be paid yet', paid == false)
    ok = W.as('pure-whip-police', PWP.Fines.rule, t.id, 'reduce', 900, 3)
    check('court cannot raise a fine', ok == false)
    ok, err = W.as('pure-whip-police', PWP.Fines.rule, t.id, 'reduce', 200, 3)
    check('court reduces the fine', ok == true and count('SELECT amount FROM pure_whip_police_fines WHERE id = ?', { t.id }) == 200, err)
    local before = W.players[2].money
    paid, err = W.as('pure-whip-police', PWP.Fines.pay, 2, 1, t.id)
    check('reduced ticket paid', paid == 200 and W.players[2].money == before - 200, err)
    W.advance((Config.Tickets.cooldownSeconds + 30) * 1000)
    local signed, swhy = W.cb('pure-whip-police:ticket:write', 1, { kind = 'citation', target = 2, codes = { 'T101' } })
    check('third citation written', signed, swhy)
    W.as('pure-whip-police', PWP.Fines.sign, 2, signed.id, true)
    ok = W.as('pure-whip-police', PWP.Fines.contest, 2, signed.id, 'I want to contest it even though I signed.')
    check('a signed ticket cannot be contested', ok == false)
    ok = W.as('pure-whip-police', PWP.Fines.contest, 5, pk.id, 'My car was parked legally in a marked bay.')
    check('owner contests the parking ticket', ok == true)
    W.sql(('UPDATE pure_whip_police_fines SET contestDue = %d WHERE id = %d'):format(os.time() - 1, pk.id))
    W.as('pure-whip-police', PWP.Fines.sweep)
    check('unheard contest lapses in the citizen favour', count("SELECT COUNT(*) FROM pure_whip_police_fines WHERE id = ? AND status = 'void' AND contest = 'lapsed'", { pk.id }) == 1)
    W.sql(('UPDATE pure_whip_police_fines SET dueAt = %d WHERE id = %d'):format(os.time() - 1, signed.id))
    W.as('pure-whip-police', PWP.Fines.sweep)
    check('overdue ticket becomes a warrant', count('SELECT COUNT(*) FROM pure_whip_police_fines WHERE id = ? AND warrantId IS NOT NULL', { signed.id }) == 1)
    check('warrant names the ticket', count("SELECT COUNT(*) FROM pure_whip_police_warrants WHERE charId = 2 AND reason LIKE 'Unpaid citation CIT-%'") == 1)
end)

scenario('k9 search', function()
    PWP.Licences.set(1, 1, 'lspd', 'k9', true)
    W.core.AddItem(nil, 5, 'gunny_pistol', 1, { serial = 'X1', attachments = {} })
    local r, why = W.cb(ev('k9person'), 1, 5)
    check('dog alerts on a gun', r and r.hit == true, why)
    local car = W.car({ plate = 'K9 TEST', owner = 2, coords = vector3(14, 10, 30) })
    car.trunk[1] = { item = 'ammo_9mm', amount = 30 }
    r = W.cb(ev('k9car'), 1, W.core.GetVehicle(nil, car.id))
    check('dog alerts on the boot', r and r.hit and r.where == 'boot', r and json.encode(r))
    local ok, nope = W.cb(ev('k9'), 6)
    check('no licence, no dog', ok == false, nope)
end)

scenario('investigation board', function()
    local made = W.cb('pure-whip-police:mdt:boardNew', 1, { title = 'Test case' })
    check('board made', made and made.id)
    local a = W.cb('pure-whip-police:mdt:boardAdd', 1, { id = made.id, kind = 'person', ref = 2, label = 'Marcus Vale' })
    local b = W.cb('pure-whip-police:mdt:boardAdd', 1, { id = made.id, kind = 'vehicle', ref = 'VALE 77', label = 'VALE 77' })
    local l = W.cb('pure-whip-police:mdt:boardLink', 1, { a = a.itemId, b = b.itemId })
    check('tied', l and l.linked == true)
    l = W.cb('pure-whip-police:mdt:boardLink', 1, { a = b.itemId, b = a.itemId })
    check('tying again unties', l and l.linked == false)
    check('move', W.cb('pure-whip-police:mdt:boardMove', 1, { itemId = a.itemId, x = 300, y = 5 }) == true)
    local board = W.cb('pure-whip-police:mdt:board', 1, { id = made.id })
    check('move clamped to the board', board.items[1].x == 200, board.items[1].x)
    check('remove', W.cb('pure-whip-police:mdt:boardRemove', 1, { itemId = b.itemId }) == true)
    board = W.cb('pure-whip-police:mdt:board', 1, { id = made.id })
    check('one item left', #board.items == 1)
end)

scenario('academy exam', function()
    W.players[6].dept = 'lspd'
    local exam, why = W.cb('pure-whip-police:mdt:examStart', 6, {})
    check('exam starts', exam and #exam.questions == Config.Academy.questions, why)
    check('no answers sent', exam and exam.questions[1].answer == nil)
    local key = PWP.Exams.sessions[6].key
    local res = W.cb('pure-whip-police:mdt:examSubmit', 6, { answers = key })
    check('all right passes', res and res.passed == true and res.right == res.total, res and json.encode(res))
    local again, no = W.cb('pure-whip-police:mdt:examStart', 6, {})
    check('cannot retake after passing', again == false, no)
    local results = W.cb('pure-whip-police:mdt:academy', 1, {})
    check('command sees results', results and results.results and #results.results == 1)
end)

scenario('prison escape', function()
    W.players[2].coords = vector3(1700, 2570, 45)
    PWP.Prison.jail(2, 5, { by = 1, dept = 'lspd', reason = 'test' })
    check('jailed', PWP.Prison.jailed[2] ~= nil)
    W.core.AddItem(nil, 2, 'pure-whip-police_cutters', 1)
    W.uses['pure-whip-police_cutters'](2)
    check('refused away from the fence', PWP.Prison.jailed[2].escaping == nil)
    W.players[2].coords = vector3(1825, 2570, 45)
    W.uses['pure-whip-police_cutters'](2)
    check('fence cut, run started', PWP.Prison.jailed[2] and PWP.Prison.jailed[2].escaping ~= nil)
    check('cutters used up', slotOf(2, 'pure-whip-police_cutters') == nil)
    W.players[2].coords = vector3(1850, 2570, 45)
    W.advance(6000)
    check('escaped', PWP.Prison.jailed[2] == nil)
    check('escape warrant', count("SELECT COUNT(*) FROM pure_whip_police_warrants WHERE charId = 2 AND reason LIKE 'Escaped%'") == 1)
end)

scenario('cctv', function()
    W.fire('whip_gunny:weapon:fired', 'whip_gunny', nil, { source = 5, serial = 'CAMTEST', item = 'gunny_pistol', shots = 1, coords = vector3(12, 12, 30) })
    W.advance(4000)
    check('camera logged the shots', count("SELECT COUNT(*) FROM pure_whip_police_feedlog WHERE feed = 'cam:1' AND kind = 'casing'") >= 1)
    check('far camera did not', count("SELECT COUNT(*) FROM pure_whip_police_feedlog WHERE feed = 'cam:2'") == 0)
    local ok, why = W.cb('pure-whip-police:mdt:watch', 1, { kind = 'cam', id = 1 })
    check('watch a camera', ok == true, why)
    check('culling widened while watching', (W.culling[1] or 0) > 0)
    W.event(ev('unwatch'), 1)
    check('culling reset', W.culling[1] == 0)
    local cam
    for _, pt in pairs(W.points) do if pt.label == 'Cam one camera' then cam = pt end end
    W.players[5].coords = vector3(10, 10, 30)
    cam.onUse(5, { option = 'cut' })
    ok, why = W.cb('pure-whip-police:mdt:watch', 1, { kind = 'cam', id = 1 })
    check('a cut camera is dark', ok == false, why)
    local list = W.cb('pure-whip-police:mdt:feeds', 1, {})
    check('feeds list shows it dark', list and list.cameras[1].dark == true)
end)

scenario('bullet holes and blood from injuries', function()
    W.players[2].coords = vector3(40, 40, 30)
    W.fire('whip_gunny:weapon:fired', 'whip_gunny', nil, { source = 2, serial = 'HOLE1', item = 'gunny_pistol', shots = 1, coords = vector3(40, 40, 30) })
    W.event(ev('hit'), 2, 45.0, 40.0, 31.0)
    local hole
    for _, pt in pairs(W.points) do if pt.label == 'Bullet hole' then hole = pt end end
    check('bullet hole appears', hole ~= nil)
    W.event(ev('hit'), 2, 900.0, 40.0, 31.0)
    local holes = 0
    for _, pt in pairs(W.points) do if pt.label == 'Bullet hole' then holes = holes + 1 end end
    check('a hit out of range is ignored', holes == 1, holes)
    W.players[1].coords = vector3(45, 40, 30)
    hole.onUse(1, { option = 'collect' })
    local frag
    for _, s in pairs(W.players[1].items) do if s.item == 'pure-whip-police_evidence' and s.metadata.kind == 'fragment' then frag = s end end
    check('round dug out with the serial', frag and frag.metadata.serial == 'HOLE1')
    W.players[5].health = 150
    W.players[5].coords = vector3(60, 60, 30)
    W.event(ev('hurt'), 5)
    local blood = 0
    for _, pt in pairs(W.points) do if pt.label == 'Blood' then blood = blood + 1 end end
    check('blood from an injury', blood >= 1)
    W.players[5].health = 200
    W.players[1].coords = vector3(10, 10, 30)
end)

scenario('prints on cars and guns, wiping', function()
    local car = W.car({ plate = 'PRNT 1', owner = 5, coords = vector3(12, 10, 30) })
    W.fire('whip_core:vehicle:registered', 'whip_core', nil, { source = 5, vehicleId = car.id })
    check('driving leaves a print', W.vdata[car.id] and W.vdata[car.id].pwp_prints and #W.vdata[car.id].pwp_prints == 1)
    W.event(ev('door'), 1, W.core.GetVehicle(nil, car.id), 'dust')
    local card
    for _, s in pairs(W.players[1].items) do if s.item == 'pure-whip-police_evidence' and s.metadata.kind == 'prints' then card = s end end
    check('dusting bags the print', card and #card.metadata.prints == 1)
    W.core.AddItem(nil, 2, 'pure-whip-police_cloth', 1)
    W.players[2].coords = vector3(12, 11, 30)
    W.event(ev('door'), 2, W.core.GetVehicle(nil, car.id), 'wipe')
    check('wiping clears the car', W.vdata[car.id].pwp_prints == nil)
    W.players[5].items = {}
    W.core.AddItem(nil, 5, 'gunny_pistol', 1, { serial = 'GUN5', attachments = {} })
    W.fire('whip_gunny:weapon:drawn', 'whip_gunny', nil, { source = 5, serial = 'GUN5', item = 'gunny_pistol', slot = 1, pocket = 'player' })
    W.fire('whip_gunny:weapon:holstered', 'whip_gunny', nil, { source = 5, serial = 'GUN5', item = 'gunny_pistol', slot = 1, pocket = 'player', reason = 'holstered' })
    check('holstering stamps a print', W.players[5].items[1].metadata.prints and #W.players[5].items[1].metadata.prints == 1)
    W.core.AddItem(nil, 5, 'pure-whip-police_cloth', 1)
    W.fire('whip_gunny:weapon:drawn', 'whip_gunny', nil, { source = 5, serial = 'GUN5', item = 'gunny_pistol', slot = 1, pocket = 'player' })
    W.uses['pure-whip-police_cloth'](5)
    check('the cloth wipes the drawn gun', W.players[5].items[1].metadata.prints == nil)
    W.fire('whip_gunny:weapon:holstered', 'whip_gunny', nil, { source = 5, serial = 'GUN5', item = 'gunny_pistol', slot = 1, pocket = 'player', reason = 'holstered' })
    local gun = W.players[5].items[1]
    W.players[5].items[1] = nil
    W.players[1].items[90] = gun
    local ok, why = W.actions['pure-whip-police_baggun'](1, nil, gun, { kind = 'player', id = 1, sub = 'player', slot = 90 })
    check('a seized gun is bagged', ok == true, why)
    local bag, bagSlot
    for slot, s in pairs(W.players[1].items) do if s.item == 'pure-whip-police_evidence' and s.metadata.kind == 'gun' then bag, bagSlot = s, slot end end
    check('the bag holds the gun and its print', bag and bag.metadata.serial == 'GUN5' and #bag.metadata.prints == 1)
    ok, why = W.actions['pure-whip-police_unbag'](1, nil, bag, { kind = 'player', id = 1, sub = 'player', slot = bagSlot })
    check('the gun comes back out unchanged', ok == true and select(2, slotOf(1, 'gunny_pistol')).metadata.serial == 'GUN5', why)
end)

scenario('court: bail paying the fine, denied bail, expiry, serving at login', function()
    local id = exports['pure-whip-courts']:OpenCase({ charId = 5, charges = { { code = 'P104', count = 1 } }, byCharId = 1, dept = 'lspd' })
    W.cb('pure-whip-courts:app:postBail', 5, { id = id })
    local before = W.players[5].money
    local ok, why = W.cb('pure-whip-courts:app:rule', 3, { id = id, verdict = 'guilty', codes = { 'P104' }, applyBail = true })
    check('guilty with bail paying the fine', ok == true, why)
    local c = rows('SELECT * FROM pure_whip_courts_cases WHERE id = ?', { id })[1]
    check('bail went to the fine', c.bailState == 'applied', c.bailState)
    check('rest of the bail came back', W.players[5].money > before)
    check('no new unpaid fine when bail covered it', count("SELECT COUNT(*) FROM pure_whip_police_fines WHERE charId = 5 AND reason LIKE ? AND status = 'unpaid'", { c.charges and ('%' .. 'CR-%') or '%CR-%' }) == 0)
    PWP.Prison.release(5, { early = true })
    id = exports['pure-whip-courts']:OpenCase({ charId = 6, charges = { { code = 'T107', count = 1 } }, byCharId = 1, dept = 'lspd' })
    ok = W.cb('pure-whip-courts:app:setBail', 3, { id = id, deny = true })
    check('judge denies bail', ok == true and rows('SELECT bailState FROM pure_whip_courts_cases WHERE id = ?', { id })[1].bailState == 'denied')
    local nope, msg = W.cb('pure-whip-courts:app:postBail', 5, { id = id })
    check('denied bail cannot be posted', nope == false, msg)
    W.clockSec = W.clockSec + Config.CaseDays * 86400 + 60
    W.advance(31000)
    check('stale case dismissed', rows('SELECT outcome FROM pure_whip_courts_cases WHERE id = ?', { id })[1].outcome == 'expired')
    id = exports['pure-whip-courts']:OpenCase({ charId = 2, charges = { { code = 'P105', count = 1 } }, byCharId = 1, dept = 'lspd' })
    local away = W.players[2]
    W.players[2] = nil
    ok = W.cb('pure-whip-courts:app:rule', 3, { id = id, verdict = 'guilty', codes = { 'P105' } })
    check('guilty while away', ok == true)
    check('sentence kept for login', rows('SELECT serveMonths FROM pure_whip_courts_cases WHERE id = ?', { id })[1].serveMonths == 5)
    W.players[2] = away
    away.coords = vector3(11, 10, 30)
    W.fire('whip_core:player:loaded', 'whip_core', nil, { source = 2, charId = 2 })
    W.advance(6000)
    check('served on login', PWP.Prison.jailed[2] ~= nil and PWP.Prison.jailed[2].months == 5)
    check('nothing left to serve', rows('SELECT serveMonths FROM pure_whip_courts_cases WHERE id = ?', { id })[1].serveMonths == 0)
    PWP.Prison.release(2, { early = true })
end)

scenario('body cam, towing a street car, a clean plate', function()
    W.players[6].dept = 'lspd'
    local ok, why = W.cb('pure-whip-police:mdt:watch', 1, { kind = 'unit', target = 6 })
    check('watch another officer', ok == true, why)
    W.event(ev('unwatch'), 1)
    local street = W.car({ plate = 'STRT 1', session = true, coords = vector3(12, 10, 30) })
    W.event(ev('policecar'), 1, W.core.GetVehicle(nil, street.id), 'impound')
    check('a street car is towed, not impounded', street.out == false and not W.custody[street.id])
    local clean = W.car({ plate = 'CLEAN 1', owner = 5, coords = vector3(20, 12, 30) })
    local before = #W.client
    W.event(ev('plate'), 1, clean.netId)
    local hit = false
    for i = before + 1, #W.client do if W.client[i].name == ev('plateHit') then hit = true end end
    check('a clean plate does not hit', not hit)
    check('but it is still seen', PWP.Traffic.lastSeen('CLEAN 1') ~= nil)
end)

scenario('whip_evidence bridge', function()
    local image = 'data:image/jpeg;base64,' .. ('A'):rep(600 * 1024)
    local fake = { check = nil, closed = {}, items = {}, taken = {}, carried = {
        { ref = 'bag:AAA111', kind = 'casing', type = 'Casing', analysed = true, results = { weapon_serial = 'SER123', fingerprint = 'FPCODE000001' } },
        { ref = 'photo:P1', kind = 'photo', type = 'Photo', photo_id = 'P1', analysed = true },
        { ref = 'bag:BBB222', kind = 'blood', type = 'Blood', analysed = false },
    } }
    W.exports.whip_evidence = {
        SetCaseCheck = function(fn) fake.check = fn return true end,
        GetTraits = function(charId) return { fingerprint = 'FPCODE00000' .. charId, blood = 'O+' } end,
        GetUploadable = function() return fake.carried end,
        Upload = function(_, refs, caseId)
            local out = {}
            for _, ref in ipairs(refs) do
                for _, e in ipairs(fake.carried) do
                    if e.ref == ref then
                        local copy = { ref = e.ref, kind = e.kind, type = e.type, photo_id = e.photo_id, results = e.results, case = caseId }
                        fake.items[#fake.items + 1] = copy
                        out[#out + 1] = { ref = ref, ok = true, entry = copy }
                    end
                end
            end
            return out
        end,
        GetCase = function(caseId) return #fake.items > 0 and { id = caseId, closed = fake.closed[caseId], items = fake.items, taken = fake.taken } or nil end,
        OpenCaseLocker = function() return false end,
        CloseCase = function(caseId) fake.closed[caseId] = true return true end,
        ReopenCase = function(caseId) fake.closed[caseId] = nil return true end,
        GetPhotoImage = function(id) return id == 'P1' and image or nil end,
    }
    W.started.whip_evidence = true
    PWP.Forensics.init()
    local made = W.cb('pure-whip-police:mdt:boardNew', 1, { title = 'Forensics case' })
    local id = made.id
    check('case check hooked', type(fake.check) == 'function')
    check('case check knows the investigation', fake.check(tostring(id)) == true)
    check('case check refuses others', fake.check('999') == false and fake.check('0' .. id) == false)
    check('MDT says forensics is on', W.cb('pure-whip-police:mdt:me', 1).forensics == true)
    local c = W.cb('pure-whip-police:mdt:caseEvidence', 1, { id = id })
    check('empty locker', c and c.on == true and #c.items == 0, c and json.encode(c))
    local r, why = W.cb('pure-whip-police:mdt:fileEvidence', 1, { id = id, refs = { 'bag:AAA111', 'photo:P1' } })
    check('two items filed', r and r.done == 2, why or (r and json.encode(r)))
    local nope = W.cb('pure-whip-police:mdt:fileEvidence', 1, { id = id, refs = { 'bag:ZZZ999' } })
    check('not carried is refused', nope == false)
    nope = W.cb('pure-whip-police:mdt:fileEvidence', 1, { id = id, refs = { "bag:'; DROP" } })
    check('bad ref is refused', nope == false)
    W.players[1].coords, W.players[2].coords = vector3(10, 10, 30), vector3(11, 10, 30)
    PWP.Contact.cuff(1, 2, 'hard')
    local got, gwhy = W.cb('pure-whip-police:mdt:takeSamples', 1, { charId = 2 })
    PWP.Contact.uncuff(1, 2)
    check('fingerprints taken through whip_evidence', got and got.print == 'FPCODE000002', got and json.encode(got) or gwhy)
    fake.carried[1].results.fingerprint = 'FPCODE000002'
    fake.items[1].results.fingerprint = 'FPCODE000002'
    c = W.cb('pure-whip-police:mdt:caseEvidence', 1, { id = id })
    local bag
    for _, e in ipairs(c.items) do if e.ref == 'bag:AAA111' then bag = e end end
    check('filed bag listed with its uploader', bag and bag.uploader == 'Ava Reyes', bag and json.encode(bag))
    check('print on the bag names the person on file', bag and bag.printOwner == 2)
    local p1 = W.cb('pure-whip-police:mdt:casePhoto', 1, { id = id, photoId = 'P1', part = 1 })
    local p2 = p1 and p1.parts and W.cb('pure-whip-police:mdt:casePhoto', 1, { id = id, photoId = 'P1', part = 2 })
    local p3 = p1 and p1.parts and p1.parts >= 3 and W.cb('pure-whip-police:mdt:casePhoto', 1, { id = id, photoId = 'P1', part = 3 })
    check('photo comes in parts', p1 and p1.parts == 3, p1 and p1.parts)
    check('parts join to the picture', p1 and p2 and p3 and (p1.data .. p2.data .. p3.data) == image)
    check('a photo outside the case is refused', W.cb('pure-whip-police:mdt:casePhoto', 1, { id = id, photoId = 'P9', part = 1 }) == false)
    local s = W.cb('pure-whip-police:mdt:evidence', 1, { q = 'FPCODE000002' })
    check('print search names the person', s and s.owner == 2, s and json.encode(s))
    s = W.cb('pure-whip-police:mdt:evidence', 1, { q = 'SER123' })
    check('serial search finds the filed bag', s and s.cases and #s.cases == 1 and s.cases[1].caseId == id, s and json.encode(s))
    table.remove(fake.items, 1)
    W.fire('whip_evidence:caseChanged', 'whip_evidence', nil, tostring(id), 'taken')
    W.advance(600)
    c = W.cb('pure-whip-police:mdt:caseEvidence', 1, { id = id })
    for _, e in ipairs(c.items) do if e.ref == 'bag:AAA111' then bag = e end end
    check('a bag gone from the locker stays, marked gone', bag and bag.gone == true)
    W.cb('pure-whip-police:mdt:boardStatus', 1, { id = id, status = 'closed' })
    check('closing the investigation closes the locker', fake.closed[tostring(id)] == true)
    nope = W.cb('pure-whip-police:mdt:fileEvidence', 1, { id = id, refs = { 'bag:AAA111' } })
    check('nothing is filed into a closed investigation', nope == false)
    W.cb('pure-whip-police:mdt:boardStatus', 1, { id = id, status = 'open' })
    check('reopening reopens the locker', fake.closed[tostring(id)] == nil)
    W.started.whip_evidence = nil
end)

scenario('end state', function()
    local seen = {}
    for _, m in ipairs(W.missing) do seen[m] = true end
    local names = {}
    for m in pairs(seen) do names[#names + 1] = m end
    table.sort(names)
    check('no missing WHIP calls anywhere', #names == 0, table.concat(names, ', '))
end)

if os.getenv('PWP_HARNESS_KEEP') ~= '1' then W.server('DROP DATABASE IF EXISTS `' .. W.dbName .. '`') end
W.realPrint(fail == 0 and ('HARNESS PASS (' .. pass .. ' checks)') or ('HARNESS FAILED ' .. fail .. ', passed ' .. pass))
os.exit(fail == 0 and 0 or 1)

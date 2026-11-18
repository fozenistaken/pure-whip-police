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
    W.event(ev('policecar'), 1, W.core.GetVehicle(nil, car.id), 'impound')
    check('impounded under custody', W.custody[car.id] == true)
    local office
    for _, pt in pairs(W.points) do if pt.label == 'Impound office' then office = pt end end
    local before = W.players[5].money
    local ok, why = office.onUse(5, { option = 'collect' })
    check('owner collects the car', ok == true, why)
    check('fee charged', W.players[5].money == before - Config.Impound.fee)
    check('custody released and car out', not W.custody[car.id] and car.out == true)
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

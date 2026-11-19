local NS = PWP.RES .. ':mdt'
local R, D, F, P = PWP.Records, PWP.Dispatch, PWP.Fines, PWP.Prison
local PERMS = { 'records', 'warrants', 'fine', 'fine_custom', 'jail', 'command', 'prison_staff', 'dispatch' }

local sourceOf = PWP.sourceOf

local function samples() return PWP.forensics() and PWP.Forensics or PWP.EvidenceServer end

local function str(v, max) return PWP.Text.clean(type(v) == 'string' and v or tostring(v or ''), max) end
local function num(v) return tonumber(v) and math.floor(tonumber(v)) or nil end

local function names(ids)
    local list, seen = {}, {}
    for _, id in ipairs(ids) do
        if id and not seen[id] then seen[id] = true; list[#list + 1] = id end
    end
    if #list == 0 then return {} end
    return Whip.core:GetCharacterNames(list) or {}
end

local function decorate(rows, field, target)
    local ids = {}
    for _, r in ipairs(rows) do ids[#ids + 1] = r[field] end
    local n = names(ids)
    for _, r in ipairs(rows) do r[target] = n[r[field]] end
    return rows
end

local H = {}

function H.me(src, dept)
    local role = Whip.core:GetPlayerRole(src, dept) or {}
    local perms = {}
    for _, p in ipairs(PERMS) do perms[p] = Whip.core:HasJobPermission(src, dept, p) == true end
    local u = D.units[src] or { status = 'available' }
    local p = Whip.core:GetPlayers({ light = true })[src] or {}
    return { dept = dept, deptLabel = PWP.dept(dept).label, short = PWP.dept(dept).short, rank = role.name,
        level = role.level, name = p.fullName, callsign = D.callsign(src), status = u.status, perms = perms,
        courts = PWP.courts() ~= nil, academy = (role.level or 0) < Config.Academy.untilLevel,
        forensics = PWP.forensics() ~= nil, tags = Config.Records.tags, templates = Config.ReportTemplates,
        licenceKinds = Config.CitizenLicences, judge = Config.Warrants.judge == 'auto' and PWP.courts() ~= nil,
        charId = Whip.core:GetCharId(src), awards = Config.Awards }
end

function H.dashboard(src, dept)
    return {
        calls = D.list(dept), units = D.units_(),
        warrants = #R.activeWarrants(200), bolos = #R.activeBolos(),
        reports = R.listReports({ limit = 6 }),
    }
end

function H.people(_, _, a)
    local q = str(a.q, 40)
    if not q then return {} end
    local rows
    if tonumber(q) then
        rows = MySQL.query.await('SELECT `charId`, `firstName`, `lastName`, `dateOfBirth`, `gender` FROM `characters` WHERE `charId` = ? AND `deleted` IS NULL',
            { tonumber(q) })
    else
        rows = MySQL.query.await([[SELECT `charId`, `firstName`, `lastName`, `dateOfBirth`, `gender` FROM `characters`
            WHERE `deleted` IS NULL AND CONCAT(`firstName`, ' ', `lastName`) LIKE ? ORDER BY `lastName` LIMIT 25]], { '%' .. q .. '%' })
    end
    for _, r in ipairs(rows or {}) do r.warrant = #R.warrants(r.charId, true) > 0; r.tags = R.tags(r.charId) end
    return rows or {}
end

function H.person(_, _, a)
    local charId = num(a.charId)
    local row = charId and MySQL.single.await(
        'SELECT `charId`, `firstName`, `lastName`, `dateOfBirth`, `gender` FROM `characters` WHERE `charId` = ? AND `deleted` IS NULL', { charId })
    if not row then return false, 'No such person' end
    local rec = R.getRecord(charId) or {}
    row.warrants, row.reports, row.notes, row.fines, row.sentence = rec.warrants, rec.reports, rec.notes, rec.fines, rec.sentence
    row.tags, row.licences = rec.tags or {}, PWP.Permits.list(charId)
    row.mugshot = PWP.Mugshots.has(charId)
    row.weapons = PWP.Weapons.ofOwner(charId)
    decorate(row.notes or {}, 'authorCharId', 'author')
    row.vehicles = MySQL.query.await('SELECT `vehicleId`, `model`, `plate`, `state` FROM `vehicles` WHERE `ownerCharId` = ? LIMIT 20', { charId }) or {}
    row.online = sourceOf(charId) ~= nil
    row.samples = samples().samplesOf(charId)
    return row
end

H.takeSamples = { perm = 'records', fn = function(src, _, a)
    local target = sourceOf(num(a.charId))
    if not target then return false, 'They are not in town' end
    local got, why = samples().takeSamples(src, target)
    if not got then return false, why end
    Whip.core:LogActivity(src, 'samples_taken', { detail = ('charId %d'):format(got.charId) })
    return got
end }

function H.evidence(_, _, a)
    local q = str(a.q, 32)
    if not q then return { rows = {} } end
    if PWP.forensics() then
        local owner = PWP.Forensics.ownerOf(q)
        return { cases = PWP.Forensics.search(q), owner = owner, ownerName = owner and names({ owner })[owner] or nil, rows = {} }
    end
    q = q:upper()
    local rows = PWP.EvidenceServer.search(q)
    local owner = PWP.EvidenceServer.ownerOf(q)
    for _, r in ipairs(rows) do
        r.owner = r.code and PWP.EvidenceServer.ownerOf(r.code) or nil
        r.gunName = r.gun and (Whip.core:GetItemDef(r.gun) or {}).name or r.gun
    end
    decorate(rows, 'owner', 'ownerName')
    return { rows = rows, owner = owner, ownerName = owner and names({ owner })[owner] or nil }
end

function H.vehicles(_, _, a)
    local q = str(a.q, 8)
    if not q then return {} end
    local rows = MySQL.query.await('SELECT `vehicleId`, `ownerCharId`, `model`, `plate`, `state` FROM `vehicles` WHERE `plate` LIKE ? LIMIT 25',
        { '%' .. q:upper() .. '%' }) or {}
    decorate(rows, 'ownerCharId', 'owner')
    for _, r in ipairs(rows) do
        r.bolo, r.seen = R.boloForPlate(r.plate), PWP.Traffic.lastSeen(r.plate)
        local held = PWP.Impound.of(r.vehicleId)
        r.impound = held and { id = held.id, lot = held.lotLabel, reason = held.reason, held = held.held } or nil
    end
    return rows
end

function H.reports(_, _, a) return R.listReports({ search = str(a.q, 60), limit = 40 }) end

function H.report(_, _, a)
    local r = R.getReport(num(a.id))
    if not r then return false, 'No such report' end
    local ids = { r.authorCharId }
    for _, p in ipairs(r.people) do ids[#ids + 1] = p.charId end
    local n = names(ids)
    r.author = n[r.authorCharId]
    for _, p in ipairs(r.people) do p.name = n[p.charId] end
    return r
end

H.saveReport = { perm = 'records', fn = function(src, dept, a)
    local data = { title = a.title, body = a.body, status = a.status, people = a.people, charges = a.charges, plates = a.plates }
    if num(a.id) then
        local rev, why = R.updateReport(num(a.id), num(a.rev), data, src)
        if not rev then return false, why end
        return { id = num(a.id), rev = rev }
    end
    data.dept, data.by = dept, src
    local id, why = R.addReport(data)
    if not id then return false, why end
    Whip.core:LogActivity(src, 'report_written', { detail = ('report %d'):format(id) })
    return { id = id, rev = 1 }
end }

function H.warrants() return decorate(R.activeWarrants(100), 'charId', 'name') end

H.issueWarrant = { perm = 'warrants', fn = function(src, dept, a)
    local judge = Config.Warrants.judge == 'auto' and PWP.courts() ~= nil
    local opts = { reason = a.reason, days = a.days, dept = dept, by = src, reportId = a.reportId }
    local id, why
    if judge then id, why = R.requestWarrant(num(a.charId), opts) else id, why = R.issueWarrant(num(a.charId), opts) end
    if not id then return false, why end
    Whip.core:LogActivity(src, judge and 'warrant_requested' or 'warrant_issued', { detail = ('warrant %d on charId %s'):format(id, tostring(a.charId)) })
    return { id = id, requested = judge or nil }
end }

H.mugshot = { perm = 'records', fn = function(src, _, a) return PWP.Mugshots.ask(src, num(a.charId)) end }
function H.mugshotImage(_, _, a) return { image = PWP.Mugshots.image(num(a.charId)) } end
H.weapon = { perm = 'records', fn = function(_, _, a) return { weapon = PWP.Weapons.get(a.serial) } end }
H.weaponStatus = { perm = 'records', fn = function(src, _, a)
    local ok, why = PWP.Weapons.setStatus(a.serial, a.status, Whip.core:GetCharId(src), a.note)
    if not ok then return false, why end
    Whip.core:LogActivity(src, 'weapon_' .. tostring(a.status), { detail = tostring(a.serial) })
    return true
end }
local C = PWP.Command
function H.roster(_, dept) return C.roster(dept) end
function H.officer(src, dept, a)
    local id = num(a.charId) or Whip.core:GetCharId(src)
    local p, why = C.profile(id, dept)
    if not p then return false, why end
    p.self = id == Whip.core:GetCharId(src)
    if p.self then p.sop = C.sop(dept, id) end
    return p
end
function H.news(_, dept) return C.news(dept) end
H.announce = { perm = 'command', fn = function(src, dept, a) return C.announce(src, dept, a.text, a.urgent == true, a.hours) end }
H.endNews = { perm = 'command', fn = function(_, dept, a) return C.endNews(num(a.id), dept) end }
H.award = { perm = 'command', fn = function(src, dept, a) return C.award(src, dept, num(a.charId), a.award, a.note) end }
H.complaints = { perm = 'command', fn = function() return C.complaints() end }
H.reviewComplaint = { perm = 'command', fn = function(src, _, a) return C.reviewComplaint(src, num(a.id), a.status, num(a.officerCharId), a.note) end }
function H.sop(src, dept)
    local doc = C.sop(dept, Whip.core:GetCharId(src))
    if Whip.core:HasJobPermission(src, dept, 'command') then doc.readers = C.sopReaders(dept) end
    return doc
end
H.setSop = { perm = 'command', fn = function(src, dept, a) return C.setSop(src, dept, a.text) end }
function H.ackSop(src, dept) return C.ackSop(Whip.core:GetCharId(src), dept) end
H.permitApps = { perm = 'command', fn = function() return PWP.Permits.apps() end }
H.decidePermit = { perm = 'command', fn = function(src, _, a) return PWP.Permits.decide(src, num(a.id), a.approve == true, a.note) end }
H.setTag = { perm = 'records', fn = function(src, _, a) return R.setTag(num(a.charId), a.tag, a.on == true, src) end }
H.licence = { perm = 'records', fn = function(src, dept, a)
    if a.act ~= 'suspend' then
        local ok, why = Whip.core:HasJobPermission(src, dept, 'command')
        if not ok then return false, why or 'Only command issues, revokes and reinstates licences' end
    end
    local ok, why = PWP.Permits.act(num(a.charId), a.kind, a.act, { days = a.days, note = a.note }, src)
    if not ok then return false, why end
    Whip.core:LogActivity(src, 'licence_' .. tostring(a.act), { detail = ('%s for charId %s'):format(tostring(a.kind), tostring(a.charId)) })
    return true
end }

H.closeWarrant = { perm = 'warrants', fn = function(src, _, a)
    local ok, why = R.closeWarrant(num(a.id), a.status, src)
    if not ok then return false, why end
    return true
end }

function H.bolos() return decorate(R.activeBolos(), 'charId', 'name') end

H.addBolo = { perm = 'records', fn = function(src, dept, a)
    local id, why = R.addBolo({ charId = num(a.charId), plate = a.plate, reason = a.reason, hours = a.hours, stolen = a.stolen == true, dept = dept, by = src })
    if not id then return false, why end
    return { id = id }
end }

H.closeBolo = { perm = 'records', fn = function(src, _, a) return R.closeBolo(num(a.id), src) end }

H.addNote = { perm = 'records', fn = function(src, _, a)
    local id, why = R.addNote(num(a.charId), a.text, src)
    if not id then return false, why end
    return { id = id }
end }

local function chargesTotal(charges)
    local list = {}
    for _, c in ipairs(type(charges) == 'table' and charges or {}) do
        if type(c) == 'table' and R.penal[c.code] then list[#list + 1] = { code = c.code, count = num(c.count) or 1 } end
    end
    return PWP.Penal.totals(list, R.penal), list
end

H.fine = { perm = 'fine', fn = function(src, dept, a)
    local charId = num(a.charId)
    local totals = chargesTotal(a.charges)
    local amount = totals.fine
    if num(a.amount) then
        if not Whip.core:HasJobPermission(src, dept, 'fine_custom') then return false, 'Only command writes custom amounts' end
        amount = num(a.amount)
    end
    if amount < 1 then return false, 'Pick at least one charge' end
    local id, why = F.issue(charId, amount, { by = src, dept = dept, reason = a.reason or 'Penal code', reportId = num(a.reportId) })
    if not id then return false, why end
    Whip.core:LogActivity(src, 'fined', { detail = ('$%d to charId %d'):format(amount, charId) })
    local target = sourceOf(charId)
    if target then Whip.core:NotifyPlayer(target, ('You were fined $%d. Pay at a police front desk.'):format(amount), 'warning') end
    return { id = id, amount = amount }
end }

H.book = { perm = 'jail', fn = function(src, dept, a)
    local courts = PWP.courts()
    if not courts then return false, 'There are no courts on this server' end
    local charId = num(a.charId)
    local target = charId and sourceOf(charId)
    if not target then return false, 'They must be here, in your custody' end
    if #(GetEntityCoords(GetPlayerPed(target)) - GetEntityCoords(GetPlayerPed(src))) > 5.0 then return false, 'They must be with you' end
    if not PWP.Contact.isCuffed(target) then return false, 'Cuff them first' end
    local _, list = chargesTotal(a.charges)
    if #list == 0 then return false, 'Pick at least one charge' end
    local ok, why = exports[courts]:Arraign({ officer = src, suspect = target, charges = list, dept = dept,
        reportId = num(a.reportId) })
    if not ok then return false, why end
    Whip.core:LogActivity(src, 'booked', { detail = ('charId %d'):format(charId) })
    return { pending = true }
end }

H.jail = { perm = 'jail', fn = function(src, dept, a)
    local charId = num(a.charId)
    local target = charId and sourceOf(charId)
    if not target then return false, 'They must be here, in your custody' end
    local tped, sped = GetPlayerPed(target), GetPlayerPed(src)
    if #(GetEntityCoords(tped) - GetEntityCoords(sped)) > 5.0 then return false, 'They must be with you' end
    if not PWP.Contact.isCuffed(target) then return false, 'Cuff them first' end
    local totals = chargesTotal(a.charges)
    local months = totals.months
    if num(a.months) then
        if not Whip.core:HasJobPermission(src, dept, 'command') then return false, 'Only command sets custom months' end
        months = num(a.months)
    end
    if months < 1 then return false, 'Those charges carry no prison time' end
    local ok, minutes = P.jail(target, months, { by = src, dept = dept, reason = a.reason, reportId = num(a.reportId) })
    if not ok then return false, minutes end
    Whip.core:LogActivity(src, 'jailed', { detail = ('charId %d for %d months'):format(charId, months) })
    return { months = months, minutes = minutes }
end }

function H.penal() return R.penalList end
H.savePenal = { perm = 'command', fn = function(_, _, a) return R.setPenal(a) end }
H.removePenal = { perm = 'command', fn = function(_, _, a) return R.removePenal(str(a.code, 10)) end }

function H.calls(_, dept) return { calls = D.list(dept), units = D.units_() } end
H.attach = { perm = 'dispatch', fn = function(src, _, a) return D.attach(src, num(a.id)) end }
H.detach = { perm = 'dispatch', fn = function(src, _, a) return D.detach(src, num(a.id)) end }
H.clearCall = { perm = 'dispatch', fn = function(src, _, a) return D.clear(num(a.id), a.outcome, a.note, src) end }
function H.callHistory(_, dept) return D.history(dept, 60) end
function H.status(src, _, a) return D.setStatus(src, a.status) end

local KINDS = { boat = 'boat', submarine = 'boat', heli = 'air', plane = 'air' }

local function where(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    local kind, sirens, speed = 'foot', nil, 0
    if veh and veh ~= 0 then
        kind = KINDS[GetVehicleType(veh)] or 'car'
        sirens = IsVehicleSirenOn(veh) or nil
        speed = math.floor(GetEntitySpeed(veh) * PWP.Radar.factor(Config.Radar.unit) + 0.5)
    end
    return { x = math.floor(c.x * 10 + 0.5) / 10, y = math.floor(c.y * 10 + 0.5) / 10,
        h = math.floor(GetEntityHeading(ped) + 0.5), kind = kind, sirens = sirens, speed = speed }
end

function H.map(src, dept)
    local units = {}
    for _, u in ipairs(D.units_()) do
        local at = where(u.source)
        if at then
            at.callsign, at.dept, at.status, at.alert, at.me = u.callsign, u.dept, u.status, u.alert, u.source == src or nil
            units[#units + 1] = at
        end
    end
    local bolos = {}
    for _, b in ipairs(R.activeBolos()) do
        local seen = b.plate and PWP.Traffic.lastSeen(b.plate)
        if seen then bolos[#bolos + 1] = { plate = b.plate, x = seen.x, y = seen.y, stolen = b.stolen == 1 or nil } end
    end
    return { calls = D.list(dept), units = units, bolos = bolos }
end

function H.waypoint(src, dept, a)
    local id = num(a.id)
    if not id then
        local x, y = tonumber(a.x), tonumber(a.y)
        if not x or not y or math.abs(x) > 9000 or math.abs(y) > 9000 then return false, 'Pick a place on the map' end
        return Whip.core:SetPlayerWaypoint(src, vector3(x + 0.0, y + 0.0, 0.0))
    end
    for _, c in ipairs(D.list(dept)) do
        if c.id == id then return Whip.core:SetPlayerWaypoint(src, vector3(c.coords.x, c.coords.y, c.coords.z)) end
    end
    return false, 'That call is over'
end

H.feeds = { perm = 'records', fn = function() return PWP.Feeds.list() end }
H.watch = { perm = 'records', fn = function(src, _, a) return PWP.Feeds.watch(src, a) end }

H.prisoners = { perm = 'prison_staff', fn = function()
    local rows = MySQL.query.await("SELECT `charId`, `months`, `minutesLeft`, `reason`, `createdAt` FROM `pure_whip_police_sentences` WHERE `status` = 'active' ORDER BY `id` DESC LIMIT 100") or {}
    for _, r in ipairs(rows) do
        local live = P.sentenceOf(r.charId)
        if live and live.online then r.minutesLeft = live.minutesLeft; r.online = true end
    end
    return decorate(rows, 'charId', 'name')
end }

H.boards = { perm = 'records', fn = function() return PWP.Board.list() end }
H.board = { perm = 'records', fn = function(src, _, a) return PWP.Board.open(num(a.id), src) end }
H.boardNew = { perm = 'records', fn = function(src, dept, a) return PWP.Board.create(src, dept, a.title) end }
H.boardAdd = { perm = 'records', fn = function(src, _, a) return PWP.Board.add(src, a) end }
H.boardMove = { perm = 'records', fn = function(src, _, a) return PWP.Board.move(src, a) end }
H.boardRemove = { perm = 'records', fn = function(src, _, a) return PWP.Board.remove(src, a) end }
H.boardLink = { perm = 'records', fn = function(src, _, a) return PWP.Board.link(src, a) end }
H.boardStatus = { perm = 'records', fn = function(src, _, a) return PWP.Board.setStatus(src, a) end }
function H.boardLeave(src) PWP.Board.leave(src) return true end
H.boardAssign = { perm = 'records', fn = function(src, _, a) return PWP.Board.assign(src, a) end }
H.boardNote = { perm = 'records', fn = function(src, _, a) return PWP.Board.note(src, a) end }
H.impoundPreview = { perm = 'fine', fn = function(_, _, a) return PWP.Impound.preview(num(a.vehicleId)) end }
H.impoundFile = { perm = 'fine', fn = function(src, dept, a)
    local spec = type(a.spec) == 'table' and a.spec or {}
    spec.via = spec.via == 'garage' and 'garage' or 'street'
    return PWP.Impound.file(src, dept, spec)
end }
H.lot = { perm = 'records', fn = function(_, _, a) return { rows = PWP.Impound.lot(type(a.lot) == 'string' and a.lot or nil), lots = Config.Impound.lots } end }
H.impoundHistory = { perm = 'records', fn = function(_, _, a) return PWP.Impound.history(num(a.vehicleId)) end }
H.liftHold = { perm = 'fine', fn = function(src, dept, a) return PWP.Impound.lift(src, dept, num(a.id), a.note) end }
H.ticketStatement = { perm = 'records', fn = function(src, _, a) return F.statement(src, num(a.id), a.text) end }
H.voidTicket = { perm = 'command', fn = function(src, _, a)
    local ok, why = F.void(num(a.id))
    if not ok then return false, why end
    Whip.core:LogActivity(src, 'ticket_voided', { detail = tostring(a.id) })
    return true
end }
H.caseEvidence = { perm = 'records', fn = function(_, _, a) return PWP.Forensics.case(num(a.id)) end }
H.uploadable = { perm = 'records', fn = function(src) return PWP.Forensics.uploadable(src) end }
H.fileEvidence = { perm = 'records', fn = function(src, _, a) return PWP.Forensics.upload(src, num(a.id), a.refs) end }
H.caseLocker = { perm = 'records', fn = function(src, _, a) return PWP.Forensics.openLocker(src, num(a.id)) end }
H.casePhoto = { perm = 'records', fn = function(_, _, a) return PWP.Forensics.photo(num(a.id), a.photoId, a.part) end }

function H.academy(src, dept)
    local out = { last = PWP.Exams.last(Whip.core:GetCharId(src), dept), questions = Config.Academy.questions, pass = Config.Academy.pass }
    if Whip.core:HasJobPermission(src, dept, 'command') then out.results = PWP.Exams.results(dept) end
    return out
end
function H.examStart(src, dept) return PWP.Exams.start(src, dept) end
function H.examSubmit(src, _, a) return PWP.Exams.submit(src, a.answers) end

H.release = { perm = 'prison_staff', fn = function(src, _, a)
    local target = sourceOf(num(a.charId))
    if not target then return false, 'They are not online' end
    local ok, why = P.release(target, { early = true, by = src })
    if not ok then return false, why end
    return true
end }

Whip.register(function()
    for action, h in pairs(H) do
        local fn, perm = h, nil
        if type(h) == 'table' then fn, perm = h.fn, h.perm end
        Whip.core:SecureCallback(NS .. ':' .. action, { rateLimit = 300, params = { { 'args', 'any' } } }, function(source, _, args)
            local dept = PWP.Depts.ofSource(source)
            if not dept then return false, 'Go on duty to use the MDT' end
            if Config.Providers.mdt ~= 'builtin' then return false, 'This MDT is turned off' end
            if perm then
                local ok, why = Whip.core:HasJobPermission(source, dept, perm)
                if not ok then return false, why or 'Your rank cannot do that' end
            end
            local a = type(args) == 'table' and args or {}
            local ok, result, why = pcall(fn, source, dept, a)
            if not ok then
                print(('[%s] mdt %s failed: %s'):format(PWP.RES, action, tostring(result)))
                return false, 'Something went wrong'
            end
            if result == false then return false, why end
            if result == nil then return true end
            return result
        end)
    end
end)

PWP.MDT = { ns = NS }

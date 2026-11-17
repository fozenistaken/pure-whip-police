local NS = PWP.RES .. ':mdt'
local R, D, F, P = PWP.Records, PWP.Dispatch, PWP.Fines, PWP.Prison
local PERMS = { 'records', 'warrants', 'fine', 'fine_custom', 'jail', 'command', 'prison_staff', 'dispatch' }

local function sourceOf(charId)
    charId = tonumber(charId)
    for src, p in pairs(Whip.core:GetPlayers({ light = true }) or {}) do
        if p.charId == charId then return tonumber(src) end
    end
    return nil
end

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
        level = role.level, name = p.fullName, callsign = D.callsign(src), status = u.status, perms = perms }
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
    for _, r in ipairs(rows or {}) do r.warrant = #R.warrants(r.charId, true) > 0 end
    return rows or {}
end

function H.person(_, _, a)
    local charId = num(a.charId)
    local row = charId and MySQL.single.await(
        'SELECT `charId`, `firstName`, `lastName`, `dateOfBirth`, `gender` FROM `characters` WHERE `charId` = ? AND `deleted` IS NULL', { charId })
    if not row then return false, 'No such person' end
    local rec = R.getRecord(charId) or {}
    row.warrants, row.reports, row.notes, row.fines, row.sentence = rec.warrants, rec.reports, rec.notes, rec.fines, rec.sentence
    decorate(row.notes or {}, 'authorCharId', 'author')
    row.vehicles = MySQL.query.await('SELECT `vehicleId`, `model`, `plate`, `state` FROM `vehicles` WHERE `ownerCharId` = ? LIMIT 20', { charId }) or {}
    row.online = sourceOf(charId) ~= nil
    return row
end

function H.vehicles(_, _, a)
    local q = str(a.q, 8)
    if not q then return {} end
    local rows = MySQL.query.await('SELECT `vehicleId`, `ownerCharId`, `model`, `plate`, `state` FROM `vehicles` WHERE `plate` LIKE ? LIMIT 25',
        { '%' .. q:upper() .. '%' }) or {}
    decorate(rows, 'ownerCharId', 'owner')
    for _, r in ipairs(rows) do r.bolo = R.boloForPlate(r.plate) end
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
    local data = { title = a.title, body = a.body, status = a.status, people = a.people, charges = a.charges }
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
    local id, why = R.issueWarrant(num(a.charId), { reason = a.reason, days = a.days, dept = dept, by = src, reportId = a.reportId })
    if not id then return false, why end
    Whip.core:LogActivity(src, 'warrant_issued', { detail = ('warrant %d on charId %s'):format(id, tostring(a.charId)) })
    return { id = id }
end }

H.closeWarrant = { perm = 'warrants', fn = function(src, _, a)
    local ok, why = R.closeWarrant(num(a.id), a.status, src)
    if not ok then return false, why end
    return true
end }

function H.bolos() return decorate(R.activeBolos(), 'charId', 'name') end

H.addBolo = { perm = 'records', fn = function(src, dept, a)
    local id, why = R.addBolo({ charId = num(a.charId), plate = a.plate, reason = a.reason, hours = a.hours, dept = dept, by = src })
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
H.clearCall = { perm = 'dispatch', fn = function(_, _, a) return D.clear(num(a.id)) end }
function H.status(src, _, a) return D.setStatus(src, a.status) end

H.prisoners = { perm = 'prison_staff', fn = function()
    local rows = MySQL.query.await("SELECT `charId`, `months`, `minutesLeft`, `reason`, `createdAt` FROM `pure_whip_police_sentences` WHERE `status` = 'active' ORDER BY `id` DESC LIMIT 100") or {}
    for _, r in ipairs(rows) do
        local live = P.sentenceOf(r.charId)
        if live and live.online then r.minutesLeft = live.minutesLeft; r.online = true end
    end
    return decorate(rows, 'charId', 'name')
end }

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

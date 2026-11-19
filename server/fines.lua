local TABLE = 'pure_whip_police_fines'
local TL = PWP.TicketLogic
local C = Config.Tickets
local PAPER = PWP.name('ticket')
local DAY = 86400
local KIND_LABEL = { citation = 'Citation', parking = 'Parking ticket', warning = 'Warning', fine = 'Fine' }
local Fines = {}
PWP.Fines = Fines

local function q(sql) return (sql:gsub('{t}', '`' .. TABLE .. '`')) end
local function now() return os.time() end

local function shape(row)
    if not row then return nil end
    row.kind = row.kind or 'fine'
    row.number = TL.number(row.kind, row.id)
    row.label = KIND_LABEL[row.kind] or 'Fine'
    if type(row.charges) == 'string' then
        local ok, list = pcall(json.decode, row.charges)
        row.charges = ok and list or nil
    end
    return row
end

local function deptName(dept) return (PWP.dept(dept) or {}).short or 'Police' end

function Fines.get(id)
    return shape(MySQL.single.await(q('SELECT * FROM {t} WHERE `id` = ?'), { tonumber(id) }))
end

function Fines.issue(charId, amount, opts)
    opts = opts or {}
    charId = tonumber(charId)
    if not charId or not PWP.Records.person(charId) then return false, 'No such character' end
    local kind = TL.KINDS[opts.kind] and opts.kind or 'fine'
    amount = math.floor(tonumber(amount) or 0)
    if kind == 'warning' then
        amount = 0
    elseif amount < 1 or amount > 10000000 then
        return false, 'A fine is $1 to $10,000,000'
    end
    local reason = PWP.Text.clean(opts.reason, 200) or KIND_LABEL[kind]
    local due = kind ~= 'fine' and kind ~= 'warning' and now() + C.dueDays * DAY or nil
    local id = MySQL.insert.await(q([[INSERT INTO {t} (`charId`, `amount`, `original`, `reason`, `dept`, `issuedBy`, `reportId`, `kind`,
        `vehicleId`, `plate`, `charges`, `place`, `notes`, `dueAt`, `status`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]]),
        { charId, amount, amount, reason, opts.dept, PWP.Records.charOf(opts.by), tonumber(opts.reportId), kind,
          tonumber(opts.vehicleId), opts.plate, opts.charges and json.encode(opts.charges) or nil,
          PWP.Text.clean(opts.place, 80), PWP.Text.clean(opts.notes, 300), due, kind == 'warning' and 'warning' or 'unpaid' })
    if not id then return false, 'Could not save the fine' end
    TriggerEvent(PWP.event('fined'), { id = id, charId = charId, amount = amount, by = opts.by, dept = opts.dept, kind = kind })
    return id
end

function Fines.list(charId, unpaidOnly)
    local sql = 'SELECT * FROM {t} WHERE `charId` = ?'
    if unpaidOnly then sql = sql .. " AND `status` = 'unpaid'" end
    local rows = MySQL.query.await(q(sql .. ' ORDER BY `id` DESC LIMIT 100'), { tonumber(charId) }) or {}
    for _, r in ipairs(rows) do shape(r) end
    return rows
end

local function account(dept)
    local number = (Config.Fines.accounts or {})[dept] or Config.Fines.account
    if type(number) ~= 'string' or number == '' then return nil end
    local acc = Whip.core:GetBankAccount({ number = number })
    return acc and acc.accountId or nil
end
Fines.account = account

local function deposit(rows, why)
    local byDept = {}
    for _, f in ipairs(rows) do byDept[f.dept or ''] = (byDept[f.dept or ''] or 0) + f.amount end
    for dept, sum in pairs(byDept) do
        local acc = account(dept ~= '' and dept or nil)
        if acc and sum > 0 then Whip.core:BankSystemDeposit(acc, sum, { reason = why }) end
    end
end

local paying = {}

local function settle(src, session, charId, rows, why)
    local total, ids = 0, {}
    for _, f in ipairs(rows) do total = total + f.amount; ids[#ids + 1] = f.id end
    local receipt, err = Whip.core:ChargePlayer(src, total, { reason = why })
    if not receipt then return false, err end
    if not Whip.core:IsSessionCurrent(src, session) then
        Whip.core:RefundPlayer(receipt)
        return false
    end
    local values = { charId }
    for _, id in ipairs(ids) do values[#values + 1] = id end
    local saved = Whip.core:CommitWithAction({ {
        query = q(("UPDATE {t} SET `status` = 'paid', `paidAt` = NOW() WHERE `charId` = ? AND `status` = 'unpaid' AND `id` IN (%s)"):format(('?,'):rep(#ids):sub(1, -2))),
        values = values,
    } }, { source = src })
    if not saved then
        Whip.core:RefundPlayer(receipt)
        return false, 'Could not save that: your money is back'
    end
    return true, total, ids
end

local function payRows(src, session, rows, why)
    local charId = Whip.core:GetCharId(src)
    if not charId then return false, 'Not loaded' end
    if #rows == 0 then return false, 'You have no fines to pay' end
    if paying[charId] then return false, 'Already paying' end
    paying[charId] = true
    local ok, done, total, ids = pcall(settle, src, session, charId, rows, why)
    paying[charId] = nil
    if not ok then print(('[%s] paying fines failed: %s'):format(PWP.RES, tostring(done))) return false, 'Could not pay' end
    if not done then return false, total end
    deposit(rows, 'Fines paid')
    Whip.core:LogActivity(src, 'fines_paid', { detail = ('$%d for %d fines'):format(total, #ids) })
    TriggerEvent(PWP.event('finesPaid'), { source = src, charId = charId, ids = ids, total = total })
    return total, #ids
end

function Fines.payAll(src, session)
    local rows = {}
    for _, f in ipairs(Fines.list(Whip.core:GetCharId(src), true)) do
        if f.contest ~= 'open' then rows[#rows + 1] = f end
    end
    return payRows(src, session, rows, ('Fines (%d)'):format(#rows))
end

function Fines.pay(src, session, id)
    local f = Fines.get(id)
    if not f or f.charId ~= Whip.core:GetCharId(src) then return false, 'That is not your ticket' end
    if f.status ~= 'unpaid' then return false, 'That ticket is not open' end
    if f.contest == 'open' then return false, 'It is before the court: wait for the ruling' end
    return payRows(src, session, { f }, 'Ticket ' .. f.number)
end

local function chargeTitles(codes)
    local out = {}
    for _, code in ipairs(codes or {}) do
        local c = PWP.Records.penal[code]
        if c then out[#out + 1] = c.title end
    end
    return table.concat(out, ', ')
end

local function mailTicket(f, officerName)
    local lines = {
        ('%s %s, %s.'):format(f.label, f.number, f.kind == 'warning' and 'no fine' or ('$' .. f.amount)),
        chargeTitles(f.charges) ~= '' and ('For: %s.'):format(chargeTitles(f.charges)) or nil,
        f.plate and ('Vehicle: %s.'):format(f.plate) or nil,
        f.place and ('Where: %s.'):format(f.place) or nil,
        officerName and ('Officer: %s.'):format(officerName) or nil,
        f.dueAt and ('Pay by %s in the Courts app or at a police kiosk. Not signed? You may contest it there until then.'):format(os.date('%d %b', f.dueAt)) or nil,
    }
    local text = {}
    for _, l in ipairs(lines) do if l then text[#text + 1] = l end end
    PWP.Mail.send(f.charId, deptName(f.dept), f.label .. ' ' .. f.number, table.concat(text, '\n'))
end

local function givePaper(src, f, copy)
    if not src then return end
    Whip.core:AddItem(src, PAPER, 1, { number = f.number, ticket = f.id, copy = copy }, { reason = 'ticket written' })
end

local cooldown = {}

local function within(a, b, range) return #(a - b) <= range end

function Fines.nearby(src, people, cars)
    local me = GetEntityCoords(GetPlayerPed(src))
    local out = { people = {}, cars = {} }
    local ids = {}
    for _, target in ipairs(type(people) == 'table' and people or {}) do
        target = tonumber(target)
        local ped = target and target ~= src and GetPlayerPed(target)
        local charId = ped and ped ~= 0 and Whip.core:GetCharId(target)
        if charId and within(me, GetEntityCoords(ped), C.personMetres) and #out.people < 8 then
            out.people[#out.people + 1] = { source = target, charId = charId }
            ids[#ids + 1] = charId
        end
    end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, p in ipairs(out.people) do p.name = names[p.charId] end
    for _, vid in ipairs(type(cars) == 'table' and cars or {}) do
        local v = tonumber(vid) and Whip.core:GetVehicle(tonumber(vid))
        if v and v.entity and DoesEntityExist(v.entity) and within(me, GetEntityCoords(v.entity), C.vehicleMetres) and #out.cars < 8 then
            out.cars[#out.cars + 1] = { vehicleId = v.id or v.vehicleId, plate = v.plate, model = v.model, owned = v.owner ~= nil and v.owner.charId ~= nil }
        end
    end
    local penal = {}
    for _, c in ipairs(PWP.Records.penalList) do
        if c.citation == 1 or c.parking == 1 then penal[#penal + 1] = { code = c.code, title = c.title, fine = c.fine, citation = c.citation == 1, parking = c.parking == 1 } end
    end
    out.penal, out.maxAmount = penal, C.maxAmount
    return out
end

function Fines.write(src, dept, spec)
    if type(spec) ~= 'table' or not TL.KINDS[spec.kind] then return false, 'Pick citation, parking ticket or warning' end
    local at = cooldown[src]
    if at and now() - at < C.cooldownSeconds then return false, 'Finish the last ticket first' end
    local codes, seen = {}, {}
    for _, code in ipairs(type(spec.codes) == 'table' and spec.codes or {}) do
        local c = type(code) == 'string' and PWP.Records.penal[code]
        if not c or not TL.allowed(spec.kind, c) then return false, 'That charge does not go on this ticket' end
        if not seen[code] then seen[code] = true; codes[#codes + 1] = code end
        if #codes > 6 then return false, 'Six charges at most' end
    end
    if #codes == 0 then return false, 'Pick at least one charge' end
    local me = GetEntityCoords(GetPlayerPed(src))
    local charId, target, vehicle
    if spec.kind == 'parking' then
        vehicle = Whip.core:GetVehicle(tonumber(spec.vehicleId))
        if not vehicle or not vehicle.entity or not DoesEntityExist(vehicle.entity) then return false, 'That car is gone' end
        if not within(me, GetEntityCoords(vehicle.entity), C.vehicleMetres) then return false, 'Walk up to the car' end
        charId = vehicle.owner and vehicle.owner.charId
        if not charId then return false, 'Nobody owns that car: tow it instead' end
    else
        target = tonumber(spec.target)
        local ped = target and target ~= src and GetPlayerPed(target)
        if not ped or ped == 0 then return false, 'Pick who the ticket is for' end
        if not within(me, GetEntityCoords(ped), C.personMetres) then return false, 'They walked off: stand next to them' end
        charId = Whip.core:GetCharId(target)
        if not charId then return false, 'They are not here' end
    end
    local amount = TL.total(spec.kind, codes, PWP.Records.penal, C.maxAmount)
    local id, why = Fines.issue(charId, amount, { kind = spec.kind, by = src, dept = dept, charges = codes,
        reason = chargeTitles(codes), vehicleId = vehicle and (vehicle.id or vehicle.vehicleId), plate = vehicle and vehicle.plate,
        place = spec.place, notes = spec.notes })
    if not id then return false, why end
    cooldown[src] = now()
    local f = Fines.get(id)
    local officer = (Whip.core:GetPlayers({ light = true })[src] or {}).fullName
    givePaper(src, f, 'carbon')
    if target then
        givePaper(target, f, 'copy')
        if f.kind ~= 'warning' then
            TriggerClientEvent(PWP.event('ticketSign'), target, { id = f.id, number = f.number, label = f.label, amount = f.amount,
                charges = chargeTitles(codes), officer = officer, due = f.dueAt and os.date('%d %b', f.dueAt) or nil })
        end
    end
    mailTicket(f, officer)
    Whip.core:LogActivity(src, 'ticket_written', { detail = ('%s $%d to charId %d'):format(f.number, f.amount, charId) })
    return { id = f.id, number = f.number, amount = f.amount }
end

function Fines.sign(src, id, yes)
    local f = Fines.get(id)
    if not f or f.charId ~= Whip.core:GetCharId(src) or f.signedAt or f.status ~= 'unpaid' then return false end
    if not yes then return true end
    MySQL.update.await(q('UPDATE {t} SET `signedAt` = ? WHERE `id` = ? AND `signedAt` IS NULL'), { now(), f.id })
    return true
end

function Fines.contest(src, id, reason)
    local f = Fines.get(id)
    if not f or f.charId ~= Whip.core:GetCharId(src) then return false, 'That is not your ticket' end
    local ok, why = TL.canContest(f, now())
    if not ok then return false, why end
    reason = PWP.Text.clean(reason, 500)
    if not reason or #reason < 20 then return false, 'Tell the court why, in at least a sentence' end
    local changed = MySQL.update.await(q([[UPDATE {t} SET `contest` = 'open', `contestReason` = ?, `contestedAt` = ?, `contestDue` = ?
        WHERE `id` = ? AND `contest` = 'none' AND `status` = 'unpaid']]), { reason, now(), now() + C.contestDays * DAY, f.id })
    if changed ~= 1 then return false, 'It changed meanwhile: look again' end
    if f.issuedBy then
        PWP.Mail.send(f.issuedBy, 'Courts', 'Contested: ' .. f.number,
            ('Your %s %s was contested. Add your statement in the MDT before the court rules.'):format(f.label:lower(), f.number))
    end
    TriggerEvent(PWP.event('ticketContested'), { id = f.id, number = f.number, charId = f.charId })
    return true
end

function Fines.statement(src, id, text)
    local f = Fines.get(id)
    if not f or f.contest ~= 'open' then return false, 'No open contest on that ticket' end
    text = PWP.Text.clean(text, 1000)
    if not text then return false, 'Write your statement' end
    MySQL.update.await(q('UPDATE {t} SET `statement` = ?, `statementBy` = ? WHERE `id` = ?'), { text, Whip.core:GetCharId(src), f.id })
    return true
end

function Fines.rule(id, verdict, amount, judgeCharId, note)
    local f = Fines.get(id)
    if not f or f.contest ~= 'open' then return false, 'No open contest on that ticket' end
    local r, why = TL.ruling(f, verdict, amount)
    if not r then return false, why end
    local due = r.restart and now() + C.dueDays * DAY or f.dueAt
    MySQL.update.await(q([[UPDATE {t} SET `contest` = ?, `status` = ?, `amount` = ?, `dueAt` = ?, `ruledBy` = ?, `ruledAt` = ?, `ruling` = ?
        WHERE `id` = ? AND `contest` = 'open']]),
        { r.contest, r.status or f.status, r.amount or f.amount, due, judgeCharId, now(), PWP.Text.clean(note, 300), f.id })
    local text = ({
        dismissed = 'The court dismissed it. You owe nothing.',
        reduced = r.status == 'void' and 'The court reduced it to nothing. You owe nothing.' or ('The court reduced it to $%d. Pay by %s.'):format(r.amount or 0, os.date('%d %b', due)),
        upheld = ('The court upheld it. Pay $%d by %s.'):format(f.amount, os.date('%d %b', due)),
    })[r.contest]
    PWP.Mail.send(f.charId, 'Courts', 'Ruling on ' .. f.number, text)
    return true
end

function Fines.contests()
    local rows = MySQL.query.await(q("SELECT * FROM {t} WHERE `contest` = 'open' ORDER BY `contestDue` LIMIT 100")) or {}
    for _, r in ipairs(rows) do shape(r) end
    return rows
end

function Fines.void(id)
    local changed = MySQL.update.await(q("UPDATE {t} SET `status` = 'void' WHERE `id` = ? AND `status` = 'unpaid'"), { tonumber(id) })
    if changed ~= 1 then return false, 'No unpaid fine with that id' end
    return true
end

local function sweep()
    local t = now()
    for _, f in ipairs(MySQL.query.await(q("SELECT * FROM {t} WHERE `contest` = 'open' AND `contestDue` <= ?"), { t }) or {}) do
        shape(f)
        if TL.lapsed(f, t) then
            MySQL.update.await(q("UPDATE {t} SET `contest` = 'lapsed', `status` = 'void' WHERE `id` = ? AND `contest` = 'open'"), { f.id })
            PWP.Mail.send(f.charId, 'Courts', 'Dropped: ' .. f.number, 'The court did not hear your contest in time. The ticket is dropped and you owe nothing.')
        end
    end
    if not C.overdue.enabled then return end
    for _, f in ipairs(MySQL.query.await(q("SELECT * FROM {t} WHERE `status` = 'unpaid' AND `dueAt` IS NOT NULL AND `dueAt` <= ? AND `warrantId` IS NULL AND `contest` <> 'open' LIMIT 50"), { t }) or {}) do
        shape(f)
        if TL.overdue(f, t) then
            local months = TL.warrantMonths(f.amount, C.overdue)
            local wid = PWP.Records.issueWarrant(f.charId, { reason = ('Unpaid %s %s ($%d): %d months'):format(f.label:lower(), f.number, f.amount, months),
                days = 14, dept = f.dept })
            if wid then
                MySQL.update.await(q('UPDATE {t} SET `warrantId` = ? WHERE `id` = ?'), { wid, f.id })
                PWP.Mail.send(f.charId, deptName(f.dept), 'Warrant: ' .. f.number,
                    ('%s %s was not paid in time. A warrant is out for you. Pay it or hand yourself in.'):format(f.label, f.number))
            end
        end
    end
end
Fines.sweep = sweep

CreateThread(function()
    while true do
        Wait(60000)
        local ok, err = pcall(sweep)
        if not ok then print(('[%s] ticket sweep: %s'):format(PWP.RES, tostring(err))) end
    end
end)

PWP.Points.kind('kiosk', {
    icon = 'dollar',
    public = true,
    options = {
        { id = 'check', label = 'Check my fines' },
        { id = 'pay', label = 'Pay all fines' },
    },
    onUse = function(source, _, _, use)
        CreateThread(function()
            local player = Whip.core:GetPlayer(source)
            if not player then return end
            if use.option == 'check' then
                local unpaid, total = Fines.list(player.charId, true), 0
                for _, f in ipairs(unpaid) do total = total + f.amount end
                Whip.core:NotifyPlayer(source, #unpaid == 0 and 'You have no fines' or
                    ('%d unpaid fines, $%d in all'):format(#unpaid, total), 'info')
                return
            end
            local paid, count = Fines.payAll(source, player.session)
            if not paid then
                if count then Whip.core:NotifyPlayer(source, count, 'error') end
                return
            end
            Whip.core:NotifyPlayer(source, ('Paid $%d (%d fines)'):format(paid, count), 'success')
        end)
        return true
    end,
})

AddEventHandler('playerDropped', function() cooldown[source] = nil end)

Whip.register(function()
    local ok, why = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `charId` INT NOT NULL, `amount` INT UNSIGNED NOT NULL,
        `reason` VARCHAR(200) NOT NULL, `dept` VARCHAR(50) NULL, `issuedBy` INT NULL, `reportId` INT UNSIGNED NULL,
        `status` ENUM('unpaid','paid','void','warning') NOT NULL DEFAULT 'unpaid', `paidAt` DATETIME NULL,
        `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `kind` ENUM('fine','citation','parking','warning') NOT NULL DEFAULT 'fine', `original` INT UNSIGNED NULL,
        `vehicleId` INT UNSIGNED NULL, `plate` VARCHAR(12) NULL, `charges` VARCHAR(400) NULL, `place` VARCHAR(80) NULL,
        `notes` VARCHAR(300) NULL, `dueAt` INT UNSIGNED NULL, `signedAt` INT UNSIGNED NULL,
        `contest` ENUM('none','open','dismissed','reduced','upheld','lapsed') NOT NULL DEFAULT 'none',
        `contestReason` VARCHAR(500) NULL, `contestedAt` INT UNSIGNED NULL, `contestDue` INT UNSIGNED NULL,
        `statement` VARCHAR(1000) NULL, `statementBy` INT NULL, `ruledBy` INT NULL, `ruledAt` INT UNSIGNED NULL,
        `ruling` VARCHAR(300) NULL, `warrantId` INT UNSIGNED NULL,
        PRIMARY KEY (`id`), KEY `charId` (`charId`, `status`), KEY `contest` (`contest`, `contestDue`),
        KEY `due` (`status`, `dueAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE), {
        { id = 'fines_tickets', statements = (function()
            local list = { q("ALTER TABLE {t} MODIFY `status` ENUM('unpaid','paid','void','warning') NOT NULL DEFAULT 'unpaid'") }
            for _, col in ipairs({
                { 'kind', "ENUM('fine','citation','parking','warning') NOT NULL DEFAULT 'fine'" }, { 'original', 'INT UNSIGNED NULL' },
                { 'vehicleId', 'INT UNSIGNED NULL' }, { 'plate', 'VARCHAR(12) NULL' }, { 'charges', 'VARCHAR(400) NULL' },
                { 'place', 'VARCHAR(80) NULL' }, { 'notes', 'VARCHAR(300) NULL' }, { 'dueAt', 'INT UNSIGNED NULL' },
                { 'signedAt', 'INT UNSIGNED NULL' },
                { 'contest', "ENUM('none','open','dismissed','reduced','upheld','lapsed') NOT NULL DEFAULT 'none'" },
                { 'contestReason', 'VARCHAR(500) NULL' }, { 'contestedAt', 'INT UNSIGNED NULL' }, { 'contestDue', 'INT UNSIGNED NULL' },
                { 'statement', 'VARCHAR(1000) NULL' }, { 'statementBy', 'INT NULL' }, { 'ruledBy', 'INT NULL' },
                { 'ruledAt', 'INT UNSIGNED NULL' }, { 'ruling', 'VARCHAR(300) NULL' }, { 'warrantId', 'INT UNSIGNED NULL' },
            }) do
                list[#list + 1] = { sql = q(('ALTER TABLE {t} ADD COLUMN `%s` %s'):format(col[1], col[2])), unless = { column = { TABLE, col[1] } } }
            end
            list[#list + 1] = { sql = q('ALTER TABLE {t} ADD KEY `contest` (`contest`, `contestDue`)'), unless = { index = { TABLE, 'contest' } } }
            list[#list + 1] = { sql = q('ALTER TABLE {t} ADD KEY `due` (`status`, `dueAt`)'), unless = { index = { TABLE, 'due' } } }
            list[#list + 1] = q('UPDATE {t} SET `original` = `amount` WHERE `original` IS NULL')
            return list
        end)() },
    })
    if not ok then print(('[%s] fines table: %s'):format(PWP.RES, tostring(why))) end

    Whip.core:RegisterItem(PAPER, { name = 'Ticket', desc = 'A police ticket. Use it to read where it stands.', weight = 0.01,
        type = 'misc', stack = false, usable = true,
        metaFields = { { key = 'number', label = 'Number', format = 'uppercase' }, { key = 'copy', label = 'Copy' } } })
    Whip.core:RegisterUseHandler(PAPER, function(source, _, slot)
        local m = slot and slot.metadata or {}
        local f = m.ticket and Fines.get(m.ticket)
        if not f then Whip.core:NotifyPlayer(source, 'This ticket is no longer on file', 'info') return false end
        local state = ({ unpaid = f.contest == 'open' and 'before the court' or ('$%d to pay by %s'):format(f.amount, f.dueAt and os.date('%d %b', f.dueAt) or '-'),
            paid = 'paid', void = 'dropped', warning = 'a warning, nothing to pay' })[f.status] or f.status
        Whip.core:NotifyPlayer(source, ('%s %s: %s'):format(f.label, f.number, state), 'info', 7000)
        return false
    end)

    Whip.core:SecureEvent(PWP.event('ticketSigned'), { rateLimit = 1000, params = { { 'id', 'number', 1, 4294967295 }, { 'yes', 'bool' } } },
        function(source, _, id, yes) Fines.sign(source, id, yes) end)
    for action, fn in pairs({
        nearby = function(source, _, a) return Fines.nearby(source, a.people, a.cars) end,
        write = function(source, dept, a) return Fines.write(source, dept, a) end,
    }) do
        Whip.core:SecureCallback(PWP.RES .. ':ticket:' .. action, { rateLimit = 1000, params = { { 'args', 'any' } } }, function(source, _, args)
            local ok2, dept = PWP.Depts.can(source, 'fine')
            if not ok2 then return false, dept end
            local ok3, result, why = pcall(fn, source, dept, type(args) == 'table' and args or {})
            if not ok3 then print(('[%s] ticket %s: %s'):format(PWP.RES, action, tostring(result))) return false, 'Something went wrong' end
            if result == false then return false, why end
            return result
        end)
    end
end)

exports('Fine', function(charId, amount, opts) return Fines.issue(charId, amount, opts) end)
exports('GetFines', function(charId) return Fines.list(charId, false) end)
exports('VoidFine', function(id) return Fines.void(id) end)
exports('GetTicket', function(id) return Fines.get(id) end)
exports('PayTicket', function(src, id)
    local p = Whip.core:GetPlayer(tonumber(src))
    if not p then return false, 'Not loaded' end
    return Fines.pay(tonumber(src), p.session, id)
end)
exports('ContestTicket', function(src, id, reason) return Fines.contest(tonumber(src), id, reason) end)
exports('GetContests', function() return Fines.contests() end)
exports('RuleTicket', function(id, verdict, amount, judgeCharId, note) return Fines.rule(id, verdict, amount, judgeCharId, note) end)

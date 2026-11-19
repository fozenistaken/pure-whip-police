local T = {
    penal = 'pure_whip_police_penal',
    reports = 'pure_whip_police_reports',
    people = 'pure_whip_police_report_people',
    charges = 'pure_whip_police_report_charges',
    warrants = 'pure_whip_police_warrants',
    bolos = 'pure_whip_police_bolos',
    notes = 'pure_whip_police_notes',
}
local ROLES = { suspect = true, victim = true, witness = true, officer = true }
local Text, Plates = PWP.Text, PWP.Plates

local Records = { penal = {}, penalList = {} }
PWP.Records = Records
Records.T = T

local function q(sql) return (sql:gsub('{(%w+)}', function(k) return '`' .. T[k] .. '`' end)) end

local function charOf(by)
    if type(by) == 'number' and by > 0 then return Whip.core:GetCharId(by) end
    if type(by) == 'table' and by.charId then return tonumber(by.charId) end
    return nil
end
Records.charOf = charOf

local function ensure(name, sql, migrations)
    local ok, why = Whip.core:EnsureTable(T[name], q(sql), migrations)
    if not ok then print(('[%s] table %s: %s'):format(PWP.RES, T[name], tostring(why))) end
    return ok
end

function Records.loadPenal()
    local rows = MySQL.query.await(q('SELECT * FROM {penal} ORDER BY `sort`, `code`')) or {}
    Records.penal, Records.penalList = {}, rows
    for _, r in ipairs(rows) do Records.penal[r.code] = r end
end

local function ticketable(c)
    if c.parking then return 0 end
    return (c.months == 0 and c.category ~= 'felony') and 1 or 0
end

local function seedPenal()
    local n = MySQL.scalar.await(q('SELECT COUNT(*) FROM {penal}')) or 0
    if n > 0 then return end
    for i, c in ipairs(PenalSeed or {}) do
        MySQL.insert.await(q('INSERT IGNORE INTO {penal} (`code`, `title`, `category`, `fine`, `months`, `sort`, `citation`, `parking`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'),
            { c.code, c.title, c.category, c.fine, c.months, i, ticketable(c), c.parking and 1 or 0 })
    end
end

local function parkingSeed()
    local list = {}
    for i, c in ipairs(PenalSeed or {}) do
        if c.parking then
            list[#list + 1] = { sql = q('INSERT IGNORE INTO {penal} (`code`, `title`, `category`, `fine`, `months`, `sort`, `citation`, `parking`) VALUES (?, ?, ?, ?, ?, ?, 0, 1)'),
                values = { c.code, c.title, c.category, c.fine, c.months, i } }
        end
    end
    return list
end

function Records.setPenal(entry)
    local code = Text.clean(entry.code, 10)
    local title = Text.clean(entry.title, 80)
    if not code or not title then return false, 'A charge needs a code and a title' end
    local category = entry.category
    if category ~= 'infraction' and category ~= 'misdemeanor' and category ~= 'felony' then
        return false, "category is 'infraction', 'misdemeanor' or 'felony'"
    end
    local fine = math.floor(tonumber(entry.fine) or -1)
    local months = math.floor(tonumber(entry.months) or -1)
    if fine < 0 or fine > 10000000 or months < 0 or months > 1200 then return false, 'Fine or months out of range' end
    local citation = entry.citation == nil and ticketable({ months = months, category = category }) or (entry.citation and 1 or 0)
    MySQL.insert.await(q([[INSERT INTO {penal} (`code`, `title`, `category`, `fine`, `months`, `sort`, `citation`, `parking`) VALUES (?, ?, ?, ?, ?, 999, ?, ?)
        ON DUPLICATE KEY UPDATE `title` = VALUES(`title`), `category` = VALUES(`category`), `fine` = VALUES(`fine`), `months` = VALUES(`months`),
        `citation` = VALUES(`citation`), `parking` = VALUES(`parking`)]]),
        { code, title, category, fine, months, citation, entry.parking and 1 or 0 })
    Records.loadPenal()
    return true
end

function Records.removePenal(code)
    MySQL.update.await(q('DELETE FROM {penal} WHERE `code` = ?'), { code })
    Records.loadPenal()
    return true
end

local function cleanPeople(list)
    local out, seen = {}, {}
    for _, p in ipairs(list or {}) do
        local charId, role = tonumber(p.charId), p.role
        if charId and ROLES[role] and not seen[charId .. role] and #out < 24 then
            seen[charId .. role] = true
            out[#out + 1] = { charId = math.floor(charId), role = role }
        end
    end
    return out
end

local function cleanCharges(list)
    local out = {}
    for _, c in ipairs(list or {}) do
        local charId, code = tonumber(c.charId), c.code
        if charId and Records.penal[code] and #out < 60 then
            out[#out + 1] = { charId = math.floor(charId), code = code,
                count = math.max(1, math.min(20, math.floor(tonumber(c.count) or 1))) }
        end
    end
    return out
end

local function writeChildren(id, people, charges)
    local queries = {
        { query = q('DELETE FROM {people} WHERE `reportId` = ?'), values = { id } },
        { query = q('DELETE FROM {charges} WHERE `reportId` = ?'), values = { id } },
    }
    for _, p in ipairs(people) do
        queries[#queries + 1] = { query = q('INSERT INTO {people} (`reportId`, `charId`, `role`) VALUES (?, ?, ?)'),
            values = { id, p.charId, p.role } }
    end
    for _, c in ipairs(charges) do
        queries[#queries + 1] = { query = q('INSERT INTO {charges} (`reportId`, `charId`, `code`, `count`) VALUES (?, ?, ?, ?)'),
            values = { id, c.charId, c.code, c.count } }
    end
    return MySQL.transaction.await(queries)
end

function Records.addReport(opts)
    opts = opts or {}
    if not PWP.isDept(opts.dept) then return false, 'No such department' end
    local title = Text.clean(opts.title, 120)
    if not title then return false, 'A report needs a title' end
    local body = Text.clean(opts.body or '', 20000) or ''
    local id = MySQL.insert.await(q('INSERT INTO {reports} (`dept`, `authorCharId`, `title`, `body`) VALUES (?, ?, ?, ?)'),
        { opts.dept, charOf(opts.by), title, body })
    if not id then return false, 'Could not save the report' end
    if not writeChildren(id, cleanPeople(opts.people), cleanCharges(opts.charges)) then
        MySQL.update.await(q('DELETE FROM {reports} WHERE `id` = ?'), { id })
        return false, 'Could not save the report'
    end
    TriggerEvent(PWP.event('report'), { id = id, dept = opts.dept, by = opts.by })
    return id
end

function Records.updateReport(id, rev, patch, by)
    id = tonumber(id)
    if not id then return false, 'No such report' end
    local title = Text.clean(patch.title, 120)
    if not title then return false, 'A report needs a title' end
    local body = Text.clean(patch.body or '', 20000) or ''
    local status = patch.status == 'closed' and 'closed' or 'open'
    local changed = MySQL.update.await(q([[UPDATE {reports} SET `title` = ?, `body` = ?, `status` = ?, `rev` = `rev` + 1,
        `editedBy` = ? WHERE `id` = ? AND `rev` = ?]]), { title, body, status, charOf(by), id, tonumber(rev) or -1 })
    if changed ~= 1 then return false, 'Someone saved this report after you opened it: reopen it and try again' end
    if not writeChildren(id, cleanPeople(patch.people), cleanCharges(patch.charges)) then
        return false, 'The report saved but its people and charges did not: try again'
    end
    return (tonumber(rev) or 0) + 1
end

function Records.getReport(id)
    local r = MySQL.single.await(q('SELECT * FROM {reports} WHERE `id` = ?'), { tonumber(id) })
    if not r then return nil end
    r.people = MySQL.query.await(q('SELECT `charId`, `role` FROM {people} WHERE `reportId` = ?'), { r.id }) or {}
    r.charges = MySQL.query.await(q('SELECT `charId`, `code`, `count` FROM {charges} WHERE `reportId` = ?'), { r.id }) or {}
    return r
end

function Records.listReports(filter)
    filter = filter or {}
    local limit = math.max(1, math.min(100, math.floor(tonumber(filter.limit) or 30)))
    if filter.charId then
        return MySQL.query.await(q([[SELECT DISTINCT r.`id`, r.`title`, r.`status`, r.`dept`, r.`createdAt` FROM {reports} r
            JOIN {people} p ON p.`reportId` = r.`id` WHERE p.`charId` = ? ORDER BY r.`id` DESC LIMIT ?]]),
            { tonumber(filter.charId), limit }) or {}
    end
    if filter.search then
        return MySQL.query.await(q([[SELECT `id`, `title`, `status`, `dept`, `createdAt` FROM {reports}
            WHERE `title` LIKE ? ORDER BY `id` DESC LIMIT ?]]), { '%' .. filter.search .. '%', limit }) or {}
    end
    return MySQL.query.await(q('SELECT `id`, `title`, `status`, `dept`, `createdAt` FROM {reports} ORDER BY `id` DESC LIMIT ?'),
        { limit }) or {}
end

function Records.issueWarrant(charId, opts)
    opts = opts or {}
    charId = tonumber(charId)
    if not charId then return false, 'No such character' end
    local reason = Text.clean(opts.reason, 300)
    if not reason then return false, 'A warrant needs a reason' end
    local days = math.max(1, math.min(90, math.floor(tonumber(opts.days) or 14)))
    local id = MySQL.insert.await(q([[INSERT INTO {warrants} (`charId`, `reason`, `dept`, `issuedBy`, `reportId`, `expiresAt`)
        VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))]]),
        { charId, reason, opts.dept, charOf(opts.by), tonumber(opts.reportId), days })
    if not id then return false, 'Could not save the warrant' end
    TriggerEvent(PWP.event('warrant'), { id = id, charId = charId, by = opts.by, active = true })
    return id
end

function Records.warrants(charId, activeOnly)
    local sql = 'SELECT * FROM {warrants} WHERE `charId` = ?'
    if activeOnly then sql = sql .. " AND `status` = 'active' AND `expiresAt` > NOW()" end
    return MySQL.query.await(q(sql .. ' ORDER BY `id` DESC LIMIT 50'), { tonumber(charId) }) or {}
end

function Records.activeWarrants(limit)
    return MySQL.query.await(q([[SELECT * FROM {warrants} WHERE `status` = 'active' AND `expiresAt` > NOW()
        ORDER BY `id` DESC LIMIT ?]]), { limit or 50 }) or {}
end

function Records.closeWarrant(id, status, by)
    if status ~= 'served' and status ~= 'cancelled' then return false, "status is 'served' or 'cancelled'" end
    local w = MySQL.single.await(q('SELECT `charId` FROM {warrants} WHERE `id` = ?'), { tonumber(id) })
    if not w then return false, 'No such warrant' end
    MySQL.update.await(q('UPDATE {warrants} SET `status` = ?, `closedBy` = ? WHERE `id` = ?'), { status, charOf(by), tonumber(id) })
    TriggerEvent(PWP.event('warrant'), { id = tonumber(id), charId = w.charId, by = by, active = false, status = status })
    return true
end

function Records.addBolo(opts)
    opts = opts or {}
    local plate = opts.plate and Plates.norm(opts.plate)
    local charId = tonumber(opts.charId)
    if not plate and not charId then return false, 'A BOLO needs a person or a plate' end
    if opts.plate and not plate then return false, 'That is not a plate' end
    local reason = Text.clean(opts.reason, 300)
    if not reason then return false, 'A BOLO needs a reason' end
    local hours = math.max(1, math.min(720, math.floor(tonumber(opts.hours) or 48)))
    local id = MySQL.insert.await(q([[INSERT INTO {bolos} (`charId`, `plate`, `reason`, `stolen`, `dept`, `issuedBy`, `expiresAt`)
        VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))]]), { charId, plate, reason, plate and opts.stolen and 1 or 0, opts.dept, charOf(opts.by), hours })
    if not id then return false, 'Could not save the BOLO' end
    TriggerEvent(PWP.event('bolo'), { id = id, charId = charId, plate = plate, active = true })
    return id
end

function Records.activeBolos()
    return MySQL.query.await(q("SELECT * FROM {bolos} WHERE `status` = 'active' AND `expiresAt` > NOW() ORDER BY `id` DESC LIMIT 100")) or {}
end

function Records.boloForPlate(plate)
    plate = Plates.norm(plate)
    if not plate then return nil end
    return MySQL.single.await(q("SELECT * FROM {bolos} WHERE `plate` = ? AND `status` = 'active' AND `expiresAt` > NOW() LIMIT 1"), { plate })
end

function Records.closeBolo(id, by)
    local changed = MySQL.update.await(q("UPDATE {bolos} SET `status` = 'closed', `closedBy` = ? WHERE `id` = ?"), { charOf(by), tonumber(id) })
    if changed ~= 1 then return false, 'No such BOLO' end
    TriggerEvent(PWP.event('bolo'), { id = tonumber(id), active = false })
    return true
end

function Records.addNote(charId, text, by)
    text = Text.clean(text, 1000)
    if not tonumber(charId) or not text then return false, 'A note needs a person and some text' end
    return MySQL.insert.await(q('INSERT INTO {notes} (`charId`, `authorCharId`, `text`) VALUES (?, ?, ?)'),
        { tonumber(charId), charOf(by), text })
end

function Records.notes(charId)
    return MySQL.query.await(q('SELECT * FROM {notes} WHERE `charId` = ? ORDER BY `id` DESC LIMIT 50'), { tonumber(charId) }) or {}
end

function Records.person(charId)
    charId = tonumber(charId)
    if not charId then return nil end
    local infoExport = 'GetCharacterInfo'
    if Whip.core:HasExport(infoExport) then
        local info = exports.whip_core[infoExport](exports.whip_core, { charId })
        if info and info[charId] then return info[charId] end
    end
    local names = Whip.core:GetCharacterNames({ charId }) or {}
    if not names[charId] then return nil end
    return { name = names[charId] }
end

function Records.getRecord(charId)
    local person = Records.person(charId)
    if not person then return false, 'No such character' end
    return {
        charId = tonumber(charId),
        person = person,
        warrants = Records.warrants(charId, false),
        reports = Records.listReports({ charId = charId, limit = 30 }),
        notes = Records.notes(charId),
        fines = PWP.Fines and PWP.Fines.list(charId) or {},
        sentence = PWP.Prison and PWP.Prison.sentenceOf(charId) or nil,
    }
end

Whip.register(function()
    ensure('penal', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `code` VARCHAR(10) NOT NULL, `title` VARCHAR(80) NOT NULL,
        `category` ENUM('infraction','misdemeanor','felony') NOT NULL DEFAULT 'misdemeanor',
        `fine` INT UNSIGNED NOT NULL DEFAULT 0, `months` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
        `sort` SMALLINT NOT NULL DEFAULT 999, `citation` TINYINT(1) NOT NULL DEFAULT 0, `parking` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`code`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.penal), {
        { id = 'penal_ticket_flags', statements = {
            { sql = q('ALTER TABLE {penal} ADD COLUMN `citation` TINYINT(1) NOT NULL DEFAULT 0'), unless = { column = { T.penal, 'citation' } } },
            { sql = q('ALTER TABLE {penal} ADD COLUMN `parking` TINYINT(1) NOT NULL DEFAULT 0'), unless = { column = { T.penal, 'parking' } } },
            q("UPDATE {penal} SET `citation` = 1 WHERE `months` = 0 AND `category` <> 'felony'"),
        }, run = function()
            for _, st in ipairs(parkingSeed()) do MySQL.insert.await(st.sql, st.values) end
        end },
    })
    ensure('reports', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `rev` INT UNSIGNED NOT NULL DEFAULT 1,
        `dept` VARCHAR(50) NOT NULL, `authorCharId` INT NULL, `editedBy` INT NULL,
        `title` VARCHAR(120) NOT NULL, `body` MEDIUMTEXT NOT NULL,
        `status` ENUM('open','closed') NOT NULL DEFAULT 'open',
        `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`), KEY `title` (`title`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.reports))
    ensure('people', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `reportId` INT UNSIGNED NOT NULL, `charId` INT NOT NULL,
        `role` ENUM('suspect','victim','witness','officer') NOT NULL,
        PRIMARY KEY (`reportId`, `charId`, `role`), KEY `charId` (`charId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.people))
    ensure('charges', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `reportId` INT UNSIGNED NOT NULL, `charId` INT NOT NULL,
        `code` VARCHAR(10) NOT NULL, `count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
        PRIMARY KEY (`id`), KEY `reportId` (`reportId`), KEY `charId` (`charId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.charges))
    ensure('warrants', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `charId` INT NOT NULL, `reason` VARCHAR(300) NOT NULL,
        `dept` VARCHAR(50) NULL, `issuedBy` INT NULL, `closedBy` INT NULL, `reportId` INT UNSIGNED NULL,
        `status` ENUM('active','served','cancelled') NOT NULL DEFAULT 'active',
        `expiresAt` DATETIME NOT NULL, `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`), KEY `charId` (`charId`, `status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.warrants))
    ensure('bolos', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `charId` INT NULL, `plate` VARCHAR(8) NULL,
        `reason` VARCHAR(300) NOT NULL, `stolen` TINYINT(1) NOT NULL DEFAULT 0, `dept` VARCHAR(50) NULL, `issuedBy` INT NULL, `closedBy` INT NULL,
        `status` ENUM('active','closed') NOT NULL DEFAULT 'active',
        `expiresAt` DATETIME NOT NULL, `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`), KEY `plate` (`plate`, `status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.bolos), {
        { id = 'bolo_stolen', statements = {
            { sql = q('ALTER TABLE {bolos} ADD COLUMN `stolen` TINYINT(1) NOT NULL DEFAULT 0'), unless = { column = { T.bolos, 'stolen' } } },
        } },
    })
    ensure('notes', ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `charId` INT NOT NULL, `authorCharId` INT NULL,
        `text` VARCHAR(1000) NOT NULL, `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`), KEY `charId` (`charId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.notes))
    seedPenal()
    Records.loadPenal()
end)

exports('GetPenalCode', function() return Records.penalList end)
exports('PriceCharges', function(charges)
    local list = {}
    for _, c in ipairs(type(charges) == 'table' and charges or {}) do
        local def = type(c) == 'table' and Records.penal[c.code]
        if def then
            local count = math.max(1, math.min(20, math.floor(tonumber(c.count) or 1)))
            list[#list + 1] = { code = def.code, title = def.title, category = def.category, count = count,
                fine = def.fine * count, months = def.months * count }
        end
    end
    local totals = PWP.Penal.totals(list, Records.penal)
    return { charges = list, fine = totals.fine, months = totals.months }
end)
exports('GetRecord', function(charId) return Records.getRecord(charId) end)
exports('AddReport', function(opts) return Records.addReport(opts) end)
exports('GetReport', function(id)
    local r = Records.getReport(id)
    if not r then return false, 'No such report' end
    return r
end)
exports('IssueWarrant', function(charId, opts) return Records.issueWarrant(charId, opts) end)
exports('GetWarrants', function(charId) return Records.warrants(charId, true) end)
exports('HasWarrant', function(charId) return #Records.warrants(charId, true) > 0 end)
exports('CloseWarrant', function(id, status, opts) return Records.closeWarrant(id, status, (opts or {}).by) end)
exports('AddBolo', function(opts) return Records.addBolo(opts) end)
exports('IsBoloPlate', function(plate)
    local b = Records.boloForPlate(plate)
    if not b then return false end
    return true, b
end)
exports('AddNote', function(charId, text, opts) return Records.addNote(charId, text, (opts or {}).by) end)

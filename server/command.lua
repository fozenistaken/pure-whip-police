local T = {
    duty = 'pure_whip_police_duty', news = 'pure_whip_police_announcements', awards = 'pure_whip_police_awards',
    ia = 'pure_whip_police_complaints', sop = 'pure_whip_police_sop', ack = 'pure_whip_police_sop_ack',
}
local DAY = 86400
local IA_STATUS = { open = true, sustained = true, not_sustained = true, unfounded = true, closed = true }
local Command = {}
PWP.Command = Command

local function now() return os.time() end
local function q(sql) return (sql:gsub('{(%w+)}', function(k) return '`' .. T[k] .. '`' end)) end

AddEventHandler(PWP.event('dutyChanged'), function(e)
    if type(e) ~= 'table' or not e.charId or not e.dept then return end
    if e.onDuty then
        MySQL.insert.await(q('INSERT INTO {duty} (`charId`, `dept`, `onAt`) VALUES (?, ?, ?)'), { e.charId, e.dept, now() })
    else
        MySQL.update.await(q('UPDATE {duty} SET `offAt` = ? WHERE `charId` = ? AND `dept` = ? AND `offAt` IS NULL'), { now(), e.charId, e.dept })
    end
end)

function Command.hours(charId, dept, days)
    local since = now() - (days or 7) * DAY
    local secs = MySQL.scalar.await(q('SELECT COALESCE(SUM(COALESCE(`offAt`, ?) - GREATEST(`onAt`, ?)), 0) FROM {duty} WHERE `charId` = ? AND `dept` = ? AND COALESCE(`offAt`, ?) > ?'),
        { now(), since, charId, dept, now(), since }) or 0
    return math.floor(secs / 360 + 0.5) / 10
end

function Command.lastOn(charId, dept)
    return MySQL.scalar.await(q('SELECT MAX(COALESCE(`offAt`, ?)) FROM {duty} WHERE `charId` = ? AND `dept` = ?'), { now(), charId, dept })
end

function Command.roster(dept)
    local staff = Whip.core:GetJobEmployees(dept) or {}
    local ids, rows = {}, {}
    for charId, e in pairs(staff) do ids[#ids + 1] = tonumber(charId) or e.charId end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for charId, e in pairs(staff) do
        local id = tonumber(charId) or e.charId
        rows[#rows + 1] = { charId = id, name = names[id], rank = e.roleName, level = e.roleLevel or 0, onDuty = e.onDuty == true,
            callsign = e.source and PWP.Dispatch.callsign(e.source) or nil, hours = Command.hours(id, dept, 7), lastOn = Command.lastOn(id, dept) }
    end
    table.sort(rows, function(a, b)
        if a.onDuty ~= b.onDuty then return a.onDuty end
        if a.level ~= b.level then return a.level > b.level end
        return (a.name or '') < (b.name or '')
    end)
    return rows
end

local function count(sql, args) return MySQL.scalar.await(sql, args) or 0 end

function Command.profile(charId, dept)
    charId = tonumber(charId)
    if not charId then return false, 'No such officer' end
    local staff = Whip.core:GetJobEmployees(dept) or {}
    local e = staff[charId] or staff[tostring(charId)]
    if not e then return false, 'They do not work in your department' end
    local name = (Whip.core:GetCharacterNames({ charId }) or {})[charId]
    local awards = MySQL.query.await(q('SELECT `id`, `award`, `note`, `byCharId`, `at` FROM {awards} WHERE `charId` = ? ORDER BY `id` DESC LIMIT 30'), { charId }) or {}
    return {
        charId = charId, name = name, rank = e.roleName, level = e.roleLevel, onDuty = e.onDuty == true, hiredAt = e.hiredAt,
        hours7 = Command.hours(charId, dept, 7), hours30 = Command.hours(charId, dept, 30),
        stats = {
            reports = count('SELECT COUNT(*) FROM `pure_whip_police_reports` WHERE `authorCharId` = ?', { charId }),
            tickets = count("SELECT COUNT(*) FROM `pure_whip_police_fines` WHERE `issuedBy` = ? AND `kind` IN ('citation','parking','warning')", { charId }),
            arrests = count('SELECT COUNT(*) FROM `pure_whip_police_sentences` WHERE `sentencedBy` = ?', { charId }),
            impounds = count('SELECT COUNT(*) FROM `pure_whip_police_impounds` WHERE `byCharId` = ?', { charId }),
            calls = count('SELECT COUNT(*) FROM `pure_whip_police_calls` WHERE `closedBy` = ?', { charId }),
            complaints = count(q("SELECT COUNT(*) FROM {ia} WHERE `officerCharId` = ? AND `status` = 'sustained'"), { charId }),
        },
        awards = awards,
    }
end

function Command.announce(src, dept, text, urgent, hours)
    text = PWP.Text.clean(text, 300)
    if not text then return false, 'Write the announcement' end
    hours = math.max(1, math.min(168, math.floor(tonumber(hours) or 24)))
    local id = MySQL.insert.await(q('INSERT INTO {news} (`dept`, `text`, `urgent`, `byCharId`, `at`, `untilAt`) VALUES (?, ?, ?, ?, ?, ?)'),
        { dept, text, urgent and 1 or 0, Whip.core:GetCharId(src), now(), now() + hours * 3600 })
    for _, o in ipairs(PWP.onDutyOfficers() or {}) do
        if o.dept == dept and GetResourceState('whip_phone') == 'started' then
            exports.whip_phone:Notify(o.source, { app = 'pwpmdt', title = urgent and 'Urgent notice' or 'Notice', text = text, kind = urgent and 'command' or 'chat' })
            exports.whip_phone:Push(o.source, 'pwpmdt', 'news', {})
        end
    end
    return { id = id }
end

function Command.news(dept)
    local rows = MySQL.query.await(q('SELECT `id`, `text`, `urgent`, `byCharId`, `at` FROM {news} WHERE `dept` = ? AND `untilAt` > ? ORDER BY `urgent` DESC, `id` DESC LIMIT 10'),
        { dept, now() }) or {}
    local ids = {}
    for _, r in ipairs(rows) do ids[#ids + 1] = r.byCharId end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, r in ipairs(rows) do r.by, r.urgent = names[r.byCharId], r.urgent == 1 end
    return rows
end

function Command.endNews(id, dept)
    MySQL.update.await(q('UPDATE {news} SET `untilAt` = ? WHERE `id` = ? AND `dept` = ?'), { now(), tonumber(id), dept })
    return true
end

function Command.award(src, dept, charId, award, note)
    charId = tonumber(charId)
    local known = false
    for _, a in ipairs(Config.Awards) do if a == award then known = true end end
    if not known then return false, 'Pick one of the awards' end
    local staff = Whip.core:GetJobEmployees(dept) or {}
    if not (staff[charId] or staff[tostring(charId)]) then return false, 'They do not work in your department' end
    MySQL.insert.await(q('INSERT INTO {awards} (`charId`, `award`, `note`, `byCharId`, `at`) VALUES (?, ?, ?, ?, ?)'),
        { charId, award, PWP.Text.clean(note, 200), Whip.core:GetCharId(src), now() })
    if PWP.Mail then PWP.Mail.send(charId, (PWP.dept(dept) or {}).short or 'Police', 'Award: ' .. award, PWP.Text.clean(note, 200) or 'For your service.') end
    return true
end

function Command.complain(src, officer, text)
    officer = PWP.Text.clean(officer, 60)
    text = PWP.Text.clean(text, 1500)
    if not officer then return false, 'Who is it about? A name, call sign or badge' end
    if not text or #text < 30 then return false, 'Tell what happened, in a few sentences' end
    local by = Whip.core:GetCharId(src)
    if not by then return false, 'Not loaded' end
    local recent = MySQL.scalar.await(q('SELECT COUNT(*) FROM {ia} WHERE `byCharId` = ? AND `at` > ?'), { by, now() - DAY }) or 0
    if recent >= 3 then return false, 'You filed enough complaints today' end
    local id = MySQL.insert.await(q('INSERT INTO {ia} (`byCharId`, `officer`, `text`, `status`, `at`) VALUES (?, ?, ?, \'open\', ?)'),
        { by, officer, text, now() })
    return { id = id }
end

function Command.complaints()
    local rows = MySQL.query.await(q('SELECT * FROM {ia} ORDER BY `status` = \'open\' DESC, `id` DESC LIMIT 60')) or {}
    local ids = {}
    for _, r in ipairs(rows) do ids[#ids + 1] = r.byCharId; if r.officerCharId then ids[#ids + 1] = r.officerCharId end end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, r in ipairs(rows) do r.from, r.officerName = names[r.byCharId], r.officerCharId and names[r.officerCharId] or nil end
    return rows
end

function Command.reviewComplaint(src, id, status, officerCharId, note)
    if not IA_STATUS[status] then return false, 'Pick a finding' end
    local c = MySQL.single.await(q('SELECT * FROM {ia} WHERE `id` = ?'), { tonumber(id) })
    if not c then return false, 'No such complaint' end
    MySQL.update.await(q('UPDATE {ia} SET `status` = ?, `officerCharId` = COALESCE(?, `officerCharId`), `finding` = ?, `reviewedBy` = ?, `reviewedAt` = ? WHERE `id` = ?'),
        { status, tonumber(officerCharId), PWP.Text.clean(note, 500), Whip.core:GetCharId(src), now(), c.id })
    if status ~= 'open' and PWP.Mail then
        PWP.Mail.send(c.byCharId, 'Internal Affairs', 'Your complaint #' .. c.id, ('Finding: %s.%s'):format(status:gsub('_', ' '), note and ('\n' .. note) or ''))
    end
    return true
end

function Command.sop(dept, charId)
    local doc = MySQL.single.await(q('SELECT `text`, `version`, `at` FROM {sop} WHERE `dept` = ?'), { dept })
    local acked = doc and charId and MySQL.scalar.await(q('SELECT `version` FROM {ack} WHERE `dept` = ? AND `charId` = ?'), { dept, charId })
    return { text = doc and doc.text or '', version = doc and doc.version or 0, at = doc and doc.at or nil, acked = doc ~= nil and acked == doc.version }
end

function Command.setSop(src, dept, text)
    text = PWP.Text.clean(text, 20000)
    if not text then return false, 'Write the rules' end
    MySQL.query.await(q('INSERT INTO {sop} (`dept`, `text`, `version`, `byCharId`, `at`) VALUES (?, ?, 1, ?, ?) ON DUPLICATE KEY UPDATE `text` = VALUES(`text`), `version` = `version` + 1, `byCharId` = VALUES(`byCharId`), `at` = VALUES(`at`)'),
        { dept, text, Whip.core:GetCharId(src), now() })
    return true
end

function Command.ackSop(charId, dept)
    local v = MySQL.scalar.await(q('SELECT `version` FROM {sop} WHERE `dept` = ?'), { dept })
    if not v then return false, 'There are no rules to read yet' end
    MySQL.query.await(q('INSERT INTO {ack} (`dept`, `charId`, `version`, `at`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `version` = VALUES(`version`), `at` = VALUES(`at`)'),
        { dept, charId, v, now() })
    return true
end

function Command.sopReaders(dept)
    local v = MySQL.scalar.await(q('SELECT `version` FROM {sop} WHERE `dept` = ?'), { dept }) or 0
    return MySQL.scalar.await(q('SELECT COUNT(*) FROM {ack} WHERE `dept` = ? AND `version` = ?'), { dept, v }) or 0
end

Whip.register(function()
    for _, def in ipairs({
        { 'duty', [[CREATE TABLE IF NOT EXISTS {duty} (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `charId` INT NOT NULL,
            `dept` VARCHAR(50) NOT NULL, `onAt` INT UNSIGNED NOT NULL, `offAt` INT UNSIGNED NULL, INDEX (`charId`, `dept`, `onAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { 'news', [[CREATE TABLE IF NOT EXISTS {news} (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `dept` VARCHAR(50) NOT NULL,
            `text` VARCHAR(300) NOT NULL, `urgent` TINYINT(1) NOT NULL DEFAULT 0, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL,
            `untilAt` INT UNSIGNED NOT NULL, INDEX (`dept`, `untilAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { 'awards', [[CREATE TABLE IF NOT EXISTS {awards} (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `charId` INT NOT NULL,
            `award` VARCHAR(40) NOT NULL, `note` VARCHAR(200) NULL, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL, INDEX (`charId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { 'ia', [[CREATE TABLE IF NOT EXISTS {ia} (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `byCharId` INT NOT NULL,
            `officer` VARCHAR(60) NOT NULL, `officerCharId` INT NULL, `text` VARCHAR(1500) NOT NULL,
            `status` ENUM('open','sustained','not_sustained','unfounded','closed') NOT NULL DEFAULT 'open', `finding` VARCHAR(500) NULL,
            `reviewedBy` INT NULL, `reviewedAt` INT UNSIGNED NULL, `at` INT UNSIGNED NOT NULL, INDEX (`status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { 'sop', [[CREATE TABLE IF NOT EXISTS {sop} (`dept` VARCHAR(50) NOT NULL PRIMARY KEY, `text` MEDIUMTEXT NOT NULL,
            `version` INT UNSIGNED NOT NULL DEFAULT 1, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { 'ack', [[CREATE TABLE IF NOT EXISTS {ack} (`dept` VARCHAR(50) NOT NULL, `charId` INT NOT NULL, `version` INT UNSIGNED NOT NULL,
            `at` INT UNSIGNED NOT NULL, PRIMARY KEY (`dept`, `charId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    }) do
        local ok = Whip.core:EnsureTable(T[def[1]], q(def[2]))
        if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T[def[1]])) end
    end
    MySQL.update.await(q('UPDATE {duty} SET `offAt` = `onAt` WHERE `offAt` IS NULL'))
    for _, o in ipairs(PWP.onDutyOfficers() or {}) do
        if o.charId and o.dept then MySQL.insert.await(q('INSERT INTO {duty} (`charId`, `dept`, `onAt`) VALUES (?, ?, ?)'), { o.charId, o.dept, now() }) end
    end
end)

exports('FileComplaint', function(src, officer, text) return Command.complain(tonumber(src), officer, text) end)

local TABLE = 'pure_whip_police_academy'
local C = Config.Academy
local Exams = { sessions = {} }
PWP.Exams = Exams

function Exams.last(charId, dept)
    return MySQL.single.await(('SELECT `right`, `total`, `passed`, `at` FROM `%s` WHERE `charId` = ? AND `dept` = ? ORDER BY `id` DESC LIMIT 1'):format(TABLE),
        { charId, dept })
end

function Exams.results(dept)
    local rows = MySQL.query.await(('SELECT `charId`, `right`, `total`, `passed`, `at` FROM `%s` WHERE `dept` = ? ORDER BY `id` DESC LIMIT 40'):format(TABLE),
        { dept }) or {}
    local ids = {}
    for _, r in ipairs(rows) do ids[#ids + 1] = r.charId end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, r in ipairs(rows) do r.name = names[r.charId] end
    return rows
end

function Exams.start(src, dept)
    local charId = Whip.core:GetCharId(src)
    local last = Exams.last(charId, dept)
    if last and last.passed == 1 then return false, 'You already passed the academy' end
    if last and os.time() - last.at < C.retryMinutes * 60 then
        return false, ('You can retake it in %d min'):format(math.ceil((C.retryMinutes * 60 - (os.time() - last.at)) / 60))
    end
    local exam, key = PWP.Academy.build(PWP.Records.penalList, C.extra, C.questions, math.random)
    if #exam == 0 then return false, 'There are no questions yet: add charges to the penal code' end
    Exams.sessions[src] = { key = key, dept = dept, charId = charId }
    return { questions = exam, pass = C.pass }
end

function Exams.submit(src, answers)
    local s = Exams.sessions[src]
    if not s then return false, 'Start the exam first' end
    Exams.sessions[src] = nil
    local right, total = PWP.Academy.score(s.key, type(answers) == 'table' and answers or {})
    local passed = total > 0 and right / total >= C.pass
    MySQL.insert.await(('INSERT INTO `%s` (`charId`, `dept`, `right`, `total`, `passed`, `at`) VALUES (?, ?, ?, ?, ?, ?)'):format(TABLE),
        { s.charId, s.dept, right, total, passed and 1 or 0, os.time() })
    Whip.core:LogActivity(src, 'academy_exam', { detail = ('%d/%d %s'):format(right, total, passed and 'passed' or 'failed') })
    TriggerEvent(PWP.event('academy'), { source = src, charId = s.charId, dept = s.dept, right = right, total = total, passed = passed })
    return { right = right, total = total, passed = passed }
end

AddEventHandler('playerDropped', function() Exams.sessions[source] = nil end)

Whip.register(function()
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `charId` INT UNSIGNED NOT NULL, `dept` VARCHAR(50) NOT NULL,
        `right` TINYINT UNSIGNED NOT NULL, `total` TINYINT UNSIGNED NOT NULL, `passed` TINYINT(1) NOT NULL,
        `at` INT UNSIGNED NOT NULL, INDEX (`charId`, `dept`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end
end)

exports('GetAcademyResult', function(charId, dept)
    local r = Exams.last(tonumber(charId), dept)
    if not r then return false, 'No exam taken' end
    return { right = r.right, total = r.total, passed = r.passed == 1, at = r.at }
end)

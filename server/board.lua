local T = { cases = 'pure_whip_police_investigations', items = 'pure_whip_police_board_items', links = 'pure_whip_police_board_links',
    officers = 'pure_whip_police_board_officers', log = 'pure_whip_police_board_log' }
local KINDS = { person = true, vehicle = true, report = true, evidence = true, note = true }
local MAX_ITEMS = 60
local Board = { viewers = {} }
PWP.Board = Board

local function now() return os.time() end

local function tell(id, src)
    if GetResourceState('whip_phone') ~= 'started' then return end
    for viewer, at in pairs(Board.viewers) do
        if at == id and viewer ~= src then exports.whip_phone:Push(viewer, 'pwpmdt', 'board', { id = id }) end
    end
end

local function touch(id) MySQL.update.await(('UPDATE `%s` SET `updatedAt` = ? WHERE `id` = ?'):format(T.cases), { now(), id }) end

function Board.list()
    local rows = MySQL.query.await(('SELECT c.`id`, c.`title`, c.`status`, c.`dept`, c.`leadCharId`, c.`updatedAt`, (SELECT COUNT(*) FROM `%s` i WHERE i.`caseId` = c.`id`) AS `items` FROM `%s` c ORDER BY c.`status` = \'open\' DESC, c.`updatedAt` DESC LIMIT 60')
        :format(T.items, T.cases)) or {}
    local ids = {}
    for _, r in ipairs(rows) do ids[#ids + 1] = r.leadCharId end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, r in ipairs(rows) do r.lead = names[r.leadCharId] end
    return rows
end

function Board.open(id, src)
    local c = MySQL.single.await(('SELECT * FROM `%s` WHERE `id` = ?'):format(T.cases), { id })
    if not c then return false, 'No such investigation' end
    c.items = MySQL.query.await(('SELECT `id`, `kind`, `ref`, `label`, `sub`, `x`, `y` FROM `%s` WHERE `caseId` = ? ORDER BY `id`'):format(T.items), { id }) or {}
    c.links = MySQL.query.await(('SELECT `id`, `a`, `b`, `label` FROM `%s` WHERE `caseId` = ?'):format(T.links), { id }) or {}
    c.officers = MySQL.query.await(('SELECT `charId` FROM `%s` WHERE `caseId` = ? ORDER BY `at`'):format(T.officers), { id }) or {}
    c.log = MySQL.query.await(('SELECT `id`, `text`, `byCharId`, `at` FROM `%s` WHERE `caseId` = ? ORDER BY `id` DESC LIMIT 100'):format(T.log), { id }) or {}
    local ids = { c.leadCharId }
    for _, o in ipairs(c.officers) do ids[#ids + 1] = o.charId end
    for _, l in ipairs(c.log) do ids[#ids + 1] = l.byCharId end
    local list = {}
    for _, i in ipairs(ids) do if i then list[#list + 1] = i end end
    local names = #list > 0 and Whip.core:GetCharacterNames(list) or {}
    c.lead = c.leadCharId and names[c.leadCharId] or nil
    for _, o in ipairs(c.officers) do o.name = names[o.charId] end
    for _, l in ipairs(c.log) do l.by = l.byCharId and names[l.byCharId] or nil end
    if src then Board.viewers[src] = id end
    return c
end

function Board.create(src, dept, title)
    title = PWP.Text.clean(title, 80)
    if not title then return false, 'Give the investigation a name' end
    local id = MySQL.insert.await(('INSERT INTO `%s` (`title`, `status`, `dept`, `leadCharId`, `createdAt`, `updatedAt`) VALUES (?, \'open\', ?, ?, ?, ?)'):format(T.cases),
        { title, dept, Whip.core:GetCharId(src), now(), now() })
    if not id then return false, 'Could not save it' end
    PWP.Forensics.remember(id)
    Whip.core:LogActivity(src, 'investigation_opened', { detail = title })
    return { id = id }
end

function Board.add(src, a)
    local id = tonumber(a.id)
    if not id or not KINDS[a.kind] then return false, 'Pick what to pin' end
    local count = MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `caseId` = ?'):format(T.items), { id }) or 0
    if count >= MAX_ITEMS then return false, ('A board holds %d items'):format(MAX_ITEMS) end
    local label = PWP.Text.clean(a.label, 80)
    if not label then return false, 'It needs a label' end
    local x, y = tonumber(a.x) or (2 + (count % 6) * 13), tonumber(a.y) or (2 + math.floor(count / 6) * 9)
    local itemId = MySQL.insert.await(('INSERT INTO `%s` (`caseId`, `kind`, `ref`, `label`, `sub`, `x`, `y`, `byCharId`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(T.items),
        { id, a.kind, PWP.Text.clean(tostring(a.ref or ''), 40), label, PWP.Text.clean(a.sub, 120), x, y, Whip.core:GetCharId(src) })
    touch(id)
    tell(id, src)
    return { itemId = itemId, x = x, y = y }
end

function Board.move(src, a)
    local itemId, x, y = tonumber(a.itemId), tonumber(a.x), tonumber(a.y)
    if not itemId or not x or not y then return false, 'Nothing to move' end
    x, y = math.max(0, math.min(200, x)), math.max(0, math.min(140, y))
    local row = MySQL.single.await(('SELECT `caseId` FROM `%s` WHERE `id` = ?'):format(T.items), { itemId })
    if not row then return false, 'It is gone' end
    MySQL.update.await(('UPDATE `%s` SET `x` = ?, `y` = ? WHERE `id` = ?'):format(T.items), { x, y, itemId })
    tell(row.caseId, src)
    return true
end

function Board.remove(src, a)
    local itemId = tonumber(a.itemId)
    local row = itemId and MySQL.single.await(('SELECT `caseId` FROM `%s` WHERE `id` = ?'):format(T.items), { itemId })
    if not row then return false, 'It is gone' end
    MySQL.update.await(('DELETE FROM `%s` WHERE `a` = ? OR `b` = ?'):format(T.links), { itemId, itemId })
    MySQL.update.await(('DELETE FROM `%s` WHERE `id` = ?'):format(T.items), { itemId })
    touch(row.caseId)
    tell(row.caseId, src)
    return true
end

function Board.link(src, a)
    local ia, ib = tonumber(a.a), tonumber(a.b)
    if not ia or not ib or ia == ib then return false, 'Pick two different items' end
    local ra = MySQL.single.await(('SELECT `caseId` FROM `%s` WHERE `id` = ?'):format(T.items), { ia })
    local rb = MySQL.single.await(('SELECT `caseId` FROM `%s` WHERE `id` = ?'):format(T.items), { ib })
    if not ra or not rb or ra.caseId ~= rb.caseId then return false, 'Those are not on the same board' end
    local exists = MySQL.scalar.await(('SELECT `id` FROM `%s` WHERE (`a` = ? AND `b` = ?) OR (`a` = ? AND `b` = ?)'):format(T.links), { ia, ib, ib, ia })
    if exists then
        MySQL.update.await(('DELETE FROM `%s` WHERE `id` = ?'):format(T.links), { exists })
    else
        MySQL.insert.await(('INSERT INTO `%s` (`caseId`, `a`, `b`, `label`) VALUES (?, ?, ?, ?)'):format(T.links),
            { ra.caseId, ia, ib, PWP.Text.clean(a.label, 40) })
    end
    touch(ra.caseId)
    tell(ra.caseId, src)
    return { linked = not exists }
end

function Board.setStatus(src, a)
    local id = tonumber(a.id)
    if not id then return false, 'No such investigation' end
    local status = a.status == 'closed' and 'closed' or 'open'
    MySQL.update.await(('UPDATE `%s` SET `status` = ?, `updatedAt` = ? WHERE `id` = ?'):format(T.cases), { status, now(), id })
    tell(id, src)
    local ok, why = PWP.Forensics.setClosed(src, id, status == 'closed')
    if not ok then return { warn = 'Evidence locker: ' .. tostring(why or 'not changed') } end
    return true
end

Board.tell = tell

function Board.assign(src, a)
    local id, charId = tonumber(a.id), tonumber(a.charId)
    if not id or not charId then return false, 'Pick an officer' end
    if a.on then
        MySQL.insert.await(('INSERT IGNORE INTO `%s` (`caseId`, `charId`, `at`) VALUES (?, ?, ?)'):format(T.officers), { id, charId, now() })
        local target = PWP.sourceOf(charId)
        if target and GetResourceState('whip_phone') == 'started' then
            exports.whip_phone:Notify(target, { app = 'pwpmdt', title = 'Investigation #' .. id, text = 'You were put on this case', kind = 'command' })
        end
    else
        MySQL.update.await(('DELETE FROM `%s` WHERE `caseId` = ? AND `charId` = ?'):format(T.officers), { id, charId })
    end
    touch(id)
    tell(id, src)
    return true
end

function Board.note(src, a)
    local id = tonumber(a.id)
    local text = PWP.Text.clean(a.text, 1000)
    if not id or not text then return false, 'Write the note' end
    MySQL.insert.await(('INSERT INTO `%s` (`caseId`, `text`, `byCharId`, `at`) VALUES (?, ?, ?, ?)'):format(T.log), { id, text, Whip.core:GetCharId(src), now() })
    touch(id)
    tell(id, src)
    return true
end

function Board.leave(src) Board.viewers[src] = nil end

AddEventHandler('playerDropped', function() Board.viewers[source] = nil end)

Whip.register(function()
    for _, def in ipairs({
        { T.cases, [[CREATE TABLE IF NOT EXISTS `%s` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `title` VARCHAR(80) NOT NULL, `status` VARCHAR(8) NOT NULL DEFAULT 'open', `dept` VARCHAR(50) NULL,
            `leadCharId` INT UNSIGNED NULL, `createdAt` INT UNSIGNED NOT NULL, `updatedAt` INT UNSIGNED NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.items, [[CREATE TABLE IF NOT EXISTS `%s` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `caseId` INT UNSIGNED NOT NULL, `kind` VARCHAR(10) NOT NULL, `ref` VARCHAR(40) NULL, `label` VARCHAR(80) NOT NULL,
            `sub` VARCHAR(120) NULL, `x` FLOAT NOT NULL DEFAULT 0, `y` FLOAT NOT NULL DEFAULT 0, `byCharId` INT UNSIGNED NULL,
            INDEX (`caseId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.officers, [[CREATE TABLE IF NOT EXISTS `%s` (`caseId` INT UNSIGNED NOT NULL, `charId` INT NOT NULL, `at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`caseId`, `charId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.log, [[CREATE TABLE IF NOT EXISTS `%s` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `caseId` INT UNSIGNED NOT NULL,
            `text` VARCHAR(1000) NOT NULL, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL, INDEX (`caseId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.links, [[CREATE TABLE IF NOT EXISTS `%s` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `caseId` INT UNSIGNED NOT NULL, `a` INT UNSIGNED NOT NULL, `b` INT UNSIGNED NOT NULL, `label` VARCHAR(40) NULL,
            INDEX (`caseId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    }) do
        local ok = Whip.core:EnsureTable(def[1], def[2]:format(def[1]))
        if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, def[1])) end
    end
end)

local T = { entries = 'pure_whip_police_case_evidence', photos = 'pure_whip_police_case_photos', prints = 'pure_whip_police_prints' }
local MAX_UPLOAD = 30
local PHOTO_MAX = 4 * 1024 * 1024
local PHOTO_PART = 256 * 1024
local REF = '^%a+:[%w_%-]+$'

local Fx = { known = {}, syncing = {} }
PWP.Forensics = Fx

local function res()
    local r = PWP.forensics()
    return r and GetResourceState(r) == 'started' and r or nil
end

function Fx.on() return res() ~= nil end

local function call(name, ...)
    local r = res()
    if not r then return false, 'The forensics lab is offline' end
    local args = table.pack(...)
    local ok, a, b = pcall(function() return exports[r][name](exports[r], table.unpack(args, 1, args.n)) end)
    if not ok then
        print(('[%s] %s.%s failed: %s'):format(PWP.RES, r, name, tostring(a)))
        return false, 'The forensics lab did not answer'
    end
    return a, b
end

local function caseKey(id) return tostring(math.floor(id)) end

local function caseCheck(caseId)
    local id = tonumber(caseId)
    return id ~= nil and caseKey(id) == caseId and Fx.known[id] == true
end

local function hook()
    if not res() then return end
    local ok, why = call('SetCaseCheck', caseCheck)
    if ok then print(('[%s] %s found: case numbers are investigation numbers'):format(PWP.RES, res()))
    else print(('[%s] could not hook %s: %s'):format(PWP.RES, tostring(PWP.forensics()), tostring(why))) end
end

function Fx.remember(id) Fx.known[id] = true end

local function decode(s)
    local ok, v = pcall(json.decode, s or '')
    return ok and type(v) == 'table' and v or nil
end

local function store(id, e, charId)
    MySQL.query.await(('INSERT INTO `%s` (`caseId`, `ref`, `entry`, `gone`, `uploadedBy`, `createdAt`, `updatedAt`) VALUES (?, ?, ?, 0, ?, ?, ?) ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`), `gone` = 0, `updatedAt` = VALUES(`updatedAt`)')
        :format(T.entries), { id, e.ref, json.encode(e), charId, os.time(), os.time() })
end

function Fx.sync(id, deleted)
    local live = not deleted and call('GetCase', caseKey(id)) or nil
    if type(live) ~= 'table' and not deleted then return nil end
    local present = {}
    for _, e in ipairs(live and live.items or {}) do
        if type(e) == 'table' and type(e.ref) == 'string' then
            present[e.ref] = true
            store(id, e, nil)
        end
    end
    for ref in pairs(live and live.taken or {}) do present[ref] = true end
    local rows = MySQL.query.await(('SELECT `ref` FROM `%s` WHERE `caseId` = ? AND `gone` = 0'):format(T.entries), { id }) or {}
    for _, r in ipairs(rows) do
        if not present[r.ref] then
            MySQL.update.await(('UPDATE `%s` SET `gone` = 1, `updatedAt` = ? WHERE `caseId` = ? AND `ref` = ?'):format(T.entries), { os.time(), id, r.ref })
        end
    end
    return live
end

function Fx.case(id)
    if not Fx.known[id] then return false, 'No such investigation' end
    local live = Fx.on() and Fx.sync(id) or nil
    local rows = MySQL.query.await(('SELECT `ref`, `entry`, `gone`, `uploadedBy`, `createdAt` FROM `%s` WHERE `caseId` = ? ORDER BY `createdAt`, `ref`'):format(T.entries), { id }) or {}
    local items, ids = {}, {}
    for _, r in ipairs(rows) do
        local e = decode(r.entry)
        if e then
            e.gone = r.gone == 1 or r.gone == true or nil
            e.taken = live and live.taken and live.taken[r.ref] or nil
            e.uploadedBy, e.uploadedAt = r.uploadedBy, r.createdAt
            items[#items + 1] = e
            if r.uploadedBy then ids[#ids + 1] = r.uploadedBy end
        end
    end
    local prints, marks = {}, {}
    for _, e in ipairs(items) do
        local fp = e.results and e.results.fingerprint
        if type(fp) == 'string' and fp ~= '???' and not marks[fp] then marks[fp] = true; prints[#prints + 1] = fp end
    end
    local owners = {}
    if #prints > 0 then
        local rows2 = MySQL.query.await(('SELECT `charId`, `print` FROM `%s` WHERE `print` IN (%s)'):format(T.prints, ('?,'):rep(#prints):sub(1, -2)), prints) or {}
        for _, r in ipairs(rows2) do owners[r.print] = r.charId; ids[#ids + 1] = r.charId end
    end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, e in ipairs(items) do
        e.uploader = e.uploadedBy and names[e.uploadedBy] or nil
        local who = e.results and owners[e.results.fingerprint]
        if who then e.printOwner, e.printOwnerName = who, names[who] end
    end
    return { on = Fx.on(), closed = live and live.closed or nil, items = items }
end

function Fx.uploadable(src)
    local list = call('GetUploadable', src)
    if type(list) ~= 'table' then return {} end
    local out = {}
    for _, e in ipairs(list) do
        if type(e) == 'table' and type(e.ref) == 'string' then out[#out + 1] = e end
    end
    return out
end

function Fx.upload(src, id, refs)
    if not Fx.known[id] then return false, 'No such investigation' end
    local status = MySQL.scalar.await('SELECT `status` FROM `pure_whip_police_investigations` WHERE `id` = ?', { id })
    if status ~= 'open' then return false, 'Reopen the investigation to add evidence' end
    if type(refs) ~= 'table' or #refs == 0 then return false, 'Pick the evidence to add' end
    if #refs > MAX_UPLOAD then return false, ('Up to %d at a time'):format(MAX_UPLOAD) end
    local carried = {}
    for _, e in ipairs(Fx.uploadable(src)) do carried[e.ref] = true end
    local list = {}
    for _, ref in ipairs(refs) do
        if type(ref) ~= 'string' or #ref > 80 or not ref:find(REF) then return false, 'That is not evidence' end
        if not carried[ref] then return false, 'You no longer carry some of it' end
        list[#list + 1] = ref
    end
    local results, why = call('Upload', src, list, caseKey(id))
    if type(results) ~= 'table' then return false, why or 'The lab refused it' end
    local charId, done, failed = Whip.core:GetCharId(src), 0, {}
    for _, r in ipairs(results) do
        if r.ok and type(r.entry) == 'table' then
            store(id, r.entry, charId)
            done = done + 1
        else
            failed[#failed + 1] = { ref = r.ref, why = r.why }
        end
    end
    if done > 0 then
        Whip.core:LogActivity(src, 'evidence_filed', { detail = ('investigation %d: %d item(s)'):format(id, done) })
        PWP.Board.tell(id, src)
    end
    return { done = done, failed = failed }
end

function Fx.openLocker(src, id)
    if not Fx.known[id] then return false, 'No such investigation' end
    local ok, why = call('OpenCaseLocker', src, caseKey(id))
    if ok then return true end
    return false, why or 'Opening the locker was cancelled. Stand still at the evidence locker.'
end

function Fx.setClosed(src, id, closed)
    if not Fx.on() then return true end
    if type(call('GetCase', caseKey(id))) ~= 'table' then return true end
    return call(closed and 'CloseCase' or 'ReopenCase', caseKey(id), src)
end

local function photoOf(id, photoId)
    local rows = MySQL.query.await(('SELECT `entry` FROM `%s` WHERE `caseId` = ? AND `ref` = ?'):format(T.entries), { id, 'photo:' .. photoId }) or {}
    if #rows == 0 then return nil, 'That photo is not in this investigation' end
    local img = MySQL.scalar.await(('SELECT `image` FROM `%s` WHERE `photoId` = ?'):format(T.photos), { photoId })
    if img then return img end
    img = call('GetPhotoImage', photoId)
    if type(img) ~= 'string' or not img:find('^data:image/') then return nil, 'The picture is gone' end
    if #img <= PHOTO_MAX then
        MySQL.insert.await(('INSERT IGNORE INTO `%s` (`photoId`, `image`) VALUES (?, ?)'):format(T.photos), { photoId, img })
    end
    return img
end

function Fx.photo(id, photoId, part)
    if not Fx.known[id] then return false, 'No such investigation' end
    if type(photoId) ~= 'string' or not photoId:find('^[%w_%-]+$') or #photoId > 64 then return false, 'No such photo' end
    local img, why = photoOf(id, photoId)
    if not img then return false, why end
    local parts = math.max(1, math.ceil(#img / PHOTO_PART))
    part = math.max(1, math.min(parts, math.floor(tonumber(part) or 1)))
    return { parts = parts, part = part, data = img:sub((part - 1) * PHOTO_PART + 1, part * PHOTO_PART) }
end

function Fx.search(q)
    local like = '%' .. q:gsub('[%%_\\]', '\\%0') .. '%'
    local rows = MySQL.query.await(('SELECT `caseId`, `ref`, `entry`, `gone` FROM `%s` WHERE `entry` LIKE ? ORDER BY `updatedAt` DESC LIMIT 30'):format(T.entries), { like }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        local e = decode(r.entry)
        if e then out[#out + 1] = { caseId = r.caseId, ref = r.ref, type = e.type, kind = e.kind, street = e.street, time = e.time, gone = r.gone == 1 or nil } end
    end
    return out
end

function Fx.takeSamples(src, target)
    local charId = Whip.core:GetCharId(target)
    if not charId then return false, 'They are not here' end
    if not PWP.Contact.isCuffed(target) then return false, 'Cuff them first' end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > Config.Evidence.reach then return false, 'Stand next to them' end
    local traits = call('GetTraits', charId)
    if type(traits) ~= 'table' or not traits.fingerprint then return false, 'The forensics lab is offline' end
    MySQL.query.await(('INSERT INTO `%s` (`charId`, `print`, `blood`, `takenBy`, `takenAt`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `print` = VALUES(`print`), `blood` = VALUES(`blood`), `takenBy` = VALUES(`takenBy`), `takenAt` = VALUES(`takenAt`)')
        :format(T.prints), { charId, traits.fingerprint, traits.blood, Whip.core:GetCharId(src), os.time() })
    return { charId = charId, print = traits.fingerprint, blood = traits.blood }
end

function Fx.samplesOf(charId)
    return MySQL.single.await(('SELECT `print`, `blood`, `takenAt` FROM `%s` WHERE `charId` = ?'):format(T.prints), { charId })
end

function Fx.ownerOf(code)
    return MySQL.scalar.await(('SELECT `charId` FROM `%s` WHERE `print` = ?'):format(T.prints), { code })
end

AddEventHandler('whip_evidence:caseChanged', function(caseId, why)
    if not res() or GetInvokingResource() ~= res() then return end
    local id = tonumber(caseId)
    if not id or not Fx.known[id] or Fx.syncing[id] then return end
    Fx.syncing[id] = true
    SetTimeout(500, function()
        Fx.syncing[id] = nil
        Fx.sync(id, why == 'deleted')
        PWP.Board.tell(id)
    end)
end)

AddEventHandler('onResourceStart', function(name)
    if name == PWP.forensics() then SetTimeout(1000, hook) end
end)

function Fx.init()
    if not PWP.forensics() then return end
    for _, def in ipairs({
        { T.entries, [[CREATE TABLE IF NOT EXISTS `%s` (`caseId` INT UNSIGNED NOT NULL, `ref` VARCHAR(80) NOT NULL,
            `entry` MEDIUMTEXT NOT NULL, `gone` TINYINT(1) NOT NULL DEFAULT 0, `uploadedBy` INT UNSIGNED NULL,
            `createdAt` INT UNSIGNED NOT NULL, `updatedAt` INT UNSIGNED NOT NULL, PRIMARY KEY (`caseId`, `ref`),
            INDEX (`updatedAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.photos, [[CREATE TABLE IF NOT EXISTS `%s` (`photoId` VARCHAR(64) NOT NULL PRIMARY KEY,
            `image` MEDIUMTEXT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.prints, [[CREATE TABLE IF NOT EXISTS `%s` (`charId` INT UNSIGNED NOT NULL PRIMARY KEY,
            `print` VARCHAR(32) NOT NULL, `blood` VARCHAR(8) NULL, `takenBy` INT UNSIGNED NULL,
            `takenAt` INT UNSIGNED NOT NULL, INDEX (`print`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    }) do
        local ok = Whip.core:EnsureTable(def[1], def[2]:format(def[1]))
        if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, def[1])) end
    end
    Fx.known = {}
    for _, r in ipairs(MySQL.query.await('SELECT `id` FROM `pure_whip_police_investigations`') or {}) do Fx.known[r.id] = true end
    hook()
end

Whip.register(Fx.init)

local TABLE = 'pure_whip_police_citizen_licences'
local DAY = 86400
local Permits = {}
PWP.Permits = Permits

local function now() return os.time() end

local function row(charId, kind)
    return MySQL.single.await(('SELECT * FROM `%s` WHERE `charId` = ? AND `kind` = ?'):format(TABLE), { charId, kind })
end

local function settle(r)
    if r.status == 'suspended' and r.untilAt and r.untilAt <= now() then
        MySQL.update.await(('UPDATE `%s` SET `status` = \'valid\', `untilAt` = NULL WHERE `charId` = ? AND `kind` = ? AND `status` = \'suspended\''):format(TABLE),
            { r.charId, r.kind })
        r.status, r.untilAt = 'valid', nil
    end
    r.label = Config.CitizenLicences[r.kind] or r.kind
    return r
end

function Permits.list(charId)
    local rows = MySQL.query.await(('SELECT * FROM `%s` WHERE `charId` = ? ORDER BY `kind`'):format(TABLE), { tonumber(charId) }) or {}
    for _, r in ipairs(rows) do settle(r) end
    return rows
end

function Permits.valid(charId, kind)
    local r = row(tonumber(charId), kind)
    return r ~= nil and settle(r).status == 'valid'
end

local function tell(charId, title, text) if PWP.Mail then PWP.Mail.send(charId, 'Licensing', title, text) end end

function Permits.act(charId, kind, act, opts, by)
    charId = tonumber(charId)
    opts = opts or {}
    if not charId or not PWP.Records.person(charId) then return false, 'No such person' end
    local label = Config.CitizenLicences[kind]
    if not label then return false, 'No such licence' end
    local r = row(charId, kind)
    if r then settle(r) end
    local note = PWP.Text.clean(opts.note, 200)
    local byChar = by and Whip.core:GetCharId(by) or nil
    if act == 'grant' then
        if r and r.status == 'valid' then return false, 'They hold it already' end
        MySQL.insert.await(('INSERT INTO `%s` (`charId`, `kind`, `status`, `untilAt`, `note`, `byCharId`, `at`) VALUES (?, ?, \'valid\', NULL, ?, ?, ?) ON DUPLICATE KEY UPDATE `status` = \'valid\', `untilAt` = NULL, `note` = VALUES(`note`), `byCharId` = VALUES(`byCharId`), `at` = VALUES(`at`)'):format(TABLE),
            { charId, kind, note, byChar, now() })
        tell(charId, label .. ' issued', ('Your %s is valid.'):format(label:lower()))
        return true
    end
    if not r then return false, 'They do not hold that licence' end
    if act == 'suspend' then
        if r.status ~= 'valid' then return false, 'Only a valid licence can be suspended' end
        local days = math.max(1, math.min(90, math.floor(tonumber(opts.days) or 7)))
        if not note then return false, 'Say why it is suspended' end
        MySQL.update.await(('UPDATE `%s` SET `status` = \'suspended\', `untilAt` = ?, `note` = ?, `byCharId` = ?, `at` = ? WHERE `charId` = ? AND `kind` = ?'):format(TABLE),
            { now() + days * DAY, note, byChar, now(), charId, kind })
        tell(charId, label .. ' suspended', ('Your %s is suspended for %d day%s: %s'):format(label:lower(), days, days == 1 and '' or 's', note))
        return true
    elseif act == 'revoke' then
        if r.status == 'revoked' then return false, 'It is revoked already' end
        if not note then return false, 'Say why it is revoked' end
        MySQL.update.await(('UPDATE `%s` SET `status` = \'revoked\', `untilAt` = NULL, `note` = ?, `byCharId` = ?, `at` = ? WHERE `charId` = ? AND `kind` = ?'):format(TABLE),
            { note, byChar, now(), charId, kind })
        tell(charId, label .. ' revoked', ('Your %s is revoked: %s'):format(label:lower(), note))
        return true
    elseif act == 'reinstate' then
        if r.status == 'valid' then return false, 'It is valid already' end
        MySQL.update.await(('UPDATE `%s` SET `status` = \'valid\', `untilAt` = NULL, `note` = ?, `byCharId` = ?, `at` = ? WHERE `charId` = ? AND `kind` = ?'):format(TABLE),
            { note, byChar, now(), charId, kind })
        tell(charId, label .. ' reinstated', ('Your %s is valid again.'):format(label:lower()))
        return true
    end
    return false, 'Grant, suspend, revoke or reinstate'
end

local APPS = 'pure_whip_police_permit_apps'

local function applicable(kind)
    for _, k in ipairs(Config.Permits.apply) do if k == kind then return true end end
    return false
end

function Permits.apply(src, kind, reason)
    local charId = Whip.core:GetCharId(src)
    if not charId then return false, 'Not loaded' end
    if not applicable(kind) or not Config.CitizenLicences[kind] then return false, 'That licence is not applied for here' end
    reason = PWP.Text.clean(reason, 500)
    if not reason or #reason < 20 then return false, 'Say why you need it, in a sentence or two' end
    if Permits.valid(charId, kind) then return false, 'You hold it already' end
    local open = MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `charId` = ? AND `kind` = ? AND `status` = \'open\''):format(APPS), { charId, kind }) or 0
    if open > 0 then return false, 'Your application is waiting already' end
    local r = row(charId, kind)
    if r and settle(r).status == 'revoked' then return false, 'It was revoked: ask the police' end
    local id = MySQL.insert.await(('INSERT INTO `%s` (`charId`, `kind`, `reason`, `status`, `at`) VALUES (?, ?, ?, \'open\', ?)'):format(APPS),
        { charId, kind, reason, now() })
    return { id = id }
end

function Permits.apps(charId)
    local sql = ('SELECT * FROM `%s` WHERE '):format(APPS)
    local rows = charId and MySQL.query.await(sql .. '`charId` = ? ORDER BY `id` DESC LIMIT 20', { charId })
        or MySQL.query.await(sql .. "`status` = 'open' ORDER BY `id` LIMIT 60")
    rows = rows or {}
    local ids = {}
    for _, a in ipairs(rows) do ids[#ids + 1] = a.charId end
    local names = #ids > 0 and Whip.core:GetCharacterNames(ids) or {}
    for _, a in ipairs(rows) do a.name, a.label = names[a.charId], Config.CitizenLicences[a.kind] or a.kind end
    return rows
end

function Permits.decide(src, id, approve, note)
    local a = MySQL.single.await(('SELECT * FROM `%s` WHERE `id` = ? AND `status` = \'open\''):format(APPS), { tonumber(id) })
    if not a then return false, 'No open application with that number' end
    note = PWP.Text.clean(note, 200)
    if approve then
        local ok, why = Permits.act(a.charId, a.kind, 'grant', { note = note or 'Application approved' }, src)
        if not ok and why ~= 'They hold it already' then return false, why end
    elseif not note then
        return false, 'Say why it is denied'
    end
    MySQL.update.await(('UPDATE `%s` SET `status` = ?, `note` = ?, `decidedBy` = ?, `decidedAt` = ? WHERE `id` = ?'):format(APPS),
        { approve and 'approved' or 'denied', note, Whip.core:GetCharId(src), now(), a.id })
    if not approve then tell(a.charId, (Config.CitizenLicences[a.kind] or a.kind) .. ' denied', note) end
    return true
end

Whip.register(function()
    local okApps = Whip.core:EnsureTable(APPS, ([[CREATE TABLE IF NOT EXISTS `%s` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `charId` INT NOT NULL, `kind` VARCHAR(24) NOT NULL, `reason` VARCHAR(500) NOT NULL, `status` ENUM('open','approved','denied') NOT NULL DEFAULT 'open',
        `note` VARCHAR(200) NULL, `decidedBy` INT NULL, `decidedAt` INT UNSIGNED NULL, `at` INT UNSIGNED NOT NULL, INDEX (`status`), INDEX (`charId`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(APPS))
    if not okApps then print(('[%s] table %s could not be made'):format(PWP.RES, APPS)) end
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `charId` INT NOT NULL, `kind` VARCHAR(24) NOT NULL, `status` ENUM('valid','suspended','revoked') NOT NULL DEFAULT 'valid',
        `untilAt` INT UNSIGNED NULL, `note` VARCHAR(200) NULL, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`charId`, `kind`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end
end)

exports('ApplyForPermit', function(src, kind, reason) return Permits.apply(tonumber(src), kind, reason) end)
exports('GetMyPermitApps', function(charId) return Permits.apps(tonumber(charId)) end)
exports('GetPermitKinds', function()
    local out = {}
    for _, k in ipairs(Config.Permits.apply) do
        if Config.CitizenLicences[k] then out[#out + 1] = { kind = k, label = Config.CitizenLicences[k] } end
    end
    return out
end)
exports('GrantCitizenLicence', function(charId, kind) return Permits.act(charId, kind, 'grant', { note = 'Issued' }) end)
exports('GetCitizenLicences', function(charId) return Permits.list(charId) end)
exports('HasValidLicence', function(charId, kind) return Permits.valid(charId, kind) end)

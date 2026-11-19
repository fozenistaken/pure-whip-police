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

Whip.register(function()
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `charId` INT NOT NULL, `kind` VARCHAR(24) NOT NULL, `status` ENUM('valid','suspended','revoked') NOT NULL DEFAULT 'valid',
        `untilAt` INT UNSIGNED NULL, `note` VARCHAR(200) NULL, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`charId`, `kind`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end
end)

exports('GrantCitizenLicence', function(charId, kind) return Permits.act(charId, kind, 'grant', { note = 'Issued' }) end)
exports('GetCitizenLicences', function(charId) return Permits.list(charId) end)
exports('HasValidLicence', function(charId, kind) return Permits.valid(charId, kind) end)

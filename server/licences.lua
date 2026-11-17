local TABLE = 'pure_whip_police_licences'
local Licences = { cache = {} }
PWP.Licences = Licences

local function cacheKey(charId, dept) return charId .. ':' .. dept end

function Licences.load(charId, dept)
    local key = cacheKey(charId, dept)
    if Licences.cache[key] then return Licences.cache[key] end
    local rows = MySQL.query.await(('SELECT `licence` FROM `%s` WHERE `charId` = ? AND `dept` = ?'):format(TABLE),
        { charId, dept }) or {}
    local set = {}
    for _, r in ipairs(rows) do set[r.licence] = true end
    Licences.cache[key] = set
    return set
end

function Licences.has(charId, dept, licence)
    if not charId or not dept then return false end
    return Licences.load(charId, dept)[licence] == true
end

function Licences.list(charId, dept)
    local out = {}
    for key in pairs(Licences.load(charId, dept)) do out[#out + 1] = key end
    table.sort(out)
    return out
end

function Licences.set(byCharId, charId, dept, licence, on)
    if not Config.Licences[licence] then return false, 'No such licence' end
    if not PWP.isDept(dept) then return false, 'No such department' end
    if on then
        MySQL.insert.await(('INSERT IGNORE INTO `%s` (`charId`, `dept`, `licence`, `grantedBy`) VALUES (?, ?, ?, ?)')
            :format(TABLE), { charId, dept, licence, byCharId })
    else
        MySQL.update.await(('DELETE FROM `%s` WHERE `charId` = ? AND `dept` = ? AND `licence` = ?'):format(TABLE),
            { charId, dept, licence })
    end
    Licences.cache[cacheKey(charId, dept)] = nil
    TriggerEvent(PWP.event('licenceChanged'), { charId = charId, dept = dept, licence = licence, granted = on })
    return true
end

function Licences.forSource(src, dept)
    local charId = Whip.core:GetCharId(src)
    return function(licence) return Licences.has(charId, dept, licence) end
end

Whip.register(function()
    local ok, why = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `charId` INT NOT NULL,
        `dept` VARCHAR(50) NOT NULL,
        `licence` VARCHAR(40) NOT NULL,
        `grantedBy` INT NULL,
        `grantedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`charId`, `dept`, `licence`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] licences table: %s'):format(PWP.RES, tostring(why))) end
end)

Whip.command('pdlicence', {}, function(source, args)
    if source == 0 then print('in game only') return end
    local ok, dept = PWP.Depts.can(source, 'command')
    if not ok then return Whip.core:NotifyPlayer(source, dept, 'error') end
    local target, licence, mode = tonumber(args[1]), args[2], args[3]
    if not target or not licence then
        local names = {}
        for key in pairs(Config.Licences) do names[#names + 1] = key end
        table.sort(names)
        return Whip.core:NotifyPlayer(source, ('/pdlicence <id> <%s> [remove]'):format(table.concat(names, '|')), 'info')
    end
    local charId = Whip.core:GetCharId(target)
    if not charId then return Whip.core:NotifyPlayer(source, ('No player with id %d'):format(target), 'error') end
    if not Whip.core:GetPlayerRole(target, dept) then
        return Whip.core:NotifyPlayer(source, 'They do not work in your department', 'error')
    end
    local done, why = Licences.set(Whip.core:GetCharId(source), charId, dept, licence, mode ~= 'remove')
    if not done then return Whip.core:NotifyPlayer(source, why, 'error') end
    Whip.core:LogActivity(source, mode == 'remove' and 'licence_revoked' or 'licence_granted',
        { detail = ('%s %s to charId %d'):format(dept, licence, charId) })
    Whip.core:NotifyPlayer(source, ('%s %s'):format(Config.Licences[licence], mode == 'remove' and 'removed' or 'granted'), 'success')
end)

exports('HasLicence', function(charId, dept, licence) return Licences.has(charId, dept, licence) end)
exports('GetLicences', function(charId, dept)
    if not PWP.isDept(dept) then return false, 'No such department' end
    return Licences.list(charId, dept)
end)

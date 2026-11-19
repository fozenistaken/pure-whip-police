local TABLE = 'pure_whip_police_mail'
local KEEP_DAYS = 60
local Mail = {}
PWP.Mail = Mail

local function tell(src, title, text)
    if GetResourceState('whip_phone') == 'started' then
        exports.whip_phone:Notify(src, { app = 'pwcourt', title = title, text = text, kind = 'command' })
    else
        Whip.core:NotifyPlayer(src, title .. ': ' .. text, 'info', 8000)
    end
end

function Mail.send(charId, from, title, body)
    charId = tonumber(charId)
    if not charId then return false end
    MySQL.insert.await(('INSERT INTO `%s` (`charId`, `sender`, `title`, `body`, `at`) VALUES (?, ?, ?, ?, ?)'):format(TABLE),
        { charId, PWP.Text.clean(from, 60) or 'Police', PWP.Text.clean(title, 120) or 'Notice', PWP.Text.clean(body, 1500) or '', os.time() })
    local src = PWP.sourceOf(charId)
    if src then tell(src, from, title) end
    return true
end

function Mail.list(charId)
    return MySQL.query.await(('SELECT `id`, `sender`, `title`, `body`, `at`, `readAt` FROM `%s` WHERE `charId` = ? ORDER BY `id` DESC LIMIT 50'):format(TABLE),
        { tonumber(charId) }) or {}
end

function Mail.read(charId, id)
    MySQL.update.await(('UPDATE `%s` SET `readAt` = ? WHERE `id` = ? AND `charId` = ? AND `readAt` IS NULL'):format(TABLE),
        { os.time(), tonumber(id), tonumber(charId) })
    return true
end

function Mail.unread(charId)
    return MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `charId` = ? AND `readAt` IS NULL'):format(TABLE), { tonumber(charId) }) or 0
end

AddEventHandler('whip_core:player:loaded', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.source or e.phantom then return end
    local n = Mail.unread(e.charId)
    if n > 0 then tell(e.source, 'Mail', n == 1 and 'You have a letter from the city' or ('You have %d letters from the city'):format(n)) end
end)

Whip.register(function()
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `charId` INT UNSIGNED NOT NULL, `sender` VARCHAR(60) NOT NULL,
        `title` VARCHAR(120) NOT NULL, `body` VARCHAR(1500) NOT NULL, `at` INT UNSIGNED NOT NULL, `readAt` INT UNSIGNED NULL,
        INDEX (`charId`, `readAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end
    MySQL.update.await(('DELETE FROM `%s` WHERE `at` < ?'):format(TABLE), { os.time() - KEEP_DAYS * 86400 })
end)

exports('GetMail', function(charId) return Mail.list(charId) end)
exports('ReadMail', function(charId, id) return Mail.read(charId, id) end)
exports('SendMail', function(charId, from, title, body) return Mail.send(charId, from, title, body) end)

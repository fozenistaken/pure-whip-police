local TABLE = 'pure_whip_police_mugshots'
local PART = 48000
local MAX_BYTES = 400000
local PICTURE = '^data:image/[%a]+;base64,[%w%+/=]+$'
local Mugshots = { pending = {} }
PWP.Mugshots = Mugshots

function Mugshots.has(charId)
    return (MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `charId` = ?'):format(TABLE), { tonumber(charId) }) or 0) > 0
end

function Mugshots.image(charId)
    return MySQL.scalar.await(('SELECT `image` FROM `%s` WHERE `charId` = ?'):format(TABLE), { tonumber(charId) })
end

function Mugshots.ask(src, charId)
    local target = PWP.sourceOf(tonumber(charId))
    if not target then return false, 'They are not in town' end
    if not PWP.Contact.isCuffed(target) then return false, 'Cuff them first' end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 3.0 then return false, 'Stand in front of them' end
    local token = ('%d:%d:%d'):format(src, target, math.random(100000, 999999))
    Mugshots.pending[src] = { token = token, charId = tonumber(charId), parts = {}, at = os.time() }
    TriggerClientEvent(PWP.event('mugshotTake'), src, target, token, PART)
    return { pending = true }
end

local function part(src, token, i, n, data)
    local p = Mugshots.pending[src]
    if not p or p.token ~= token or os.time() - p.at > 60 then return end
    if type(data) ~= 'string' or #data > PART or i < 1 or n < 1 or n > math.ceil(MAX_BYTES / PART) or i > n then return end
    p.parts[i], p.n = data, n
    for k = 1, n do if not p.parts[k] then return end end
    Mugshots.pending[src] = nil
    local image = table.concat(p.parts, '', 1, n)
    if #image > MAX_BYTES or not image:find(PICTURE) then return Whip.core:NotifyPlayer(src, 'The mugshot did not come through', 'error') end
    MySQL.query.await(('INSERT INTO `%s` (`charId`, `image`, `byCharId`, `at`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `image` = VALUES(`image`), `byCharId` = VALUES(`byCharId`), `at` = VALUES(`at`)'):format(TABLE),
        { p.charId, image, Whip.core:GetCharId(src), os.time() })
    Whip.core:LogActivity(src, 'mugshot_taken', { detail = ('charId %d'):format(p.charId) })
    Whip.core:NotifyPlayer(src, 'Mugshot on file', 'success')
    if GetResourceState('whip_phone') == 'started' then exports.whip_phone:Push(src, 'pwpmdt', 'mugshot', { charId = p.charId }) end
end

AddEventHandler('playerDropped', function() Mugshots.pending[source] = nil end)

Whip.register(function()
    local ok = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `charId` INT NOT NULL PRIMARY KEY, `image` MEDIUMTEXT NOT NULL, `byCharId` INT NULL, `at` INT UNSIGNED NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, TABLE)) end
    Whip.core:SecureEvent(PWP.event('mugshotPart'), {
        rateLimit = 40,
        params = { { 'token', 'string', 40 }, { 'i', 'int', 1, 64 }, { 'n', 'int', 1, 64 }, { 'data', 'any' } },
    }, function(source, _, token, i, n, data) part(source, token, i, n, data) end)
end)

exports('GetMugshot', function(charId) return Mugshots.image(charId) end)

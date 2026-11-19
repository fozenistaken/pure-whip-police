local T = { weapons = 'pure_whip_police_weapons', history = 'pure_whip_police_weapon_history' }
local STATUS = { registered = true, stolen = true, seized = true, destroyed = true }
local Weapons = {}
PWP.Weapons = Weapons

local function now() return os.time() end
local function norm(serial)
    local s = type(serial) == 'string' and serial:upper():match('^%s*([%w%-]+)%s*$')
    return s and #s <= 32 and s or nil
end

local function log(serial, event, charId, by, note)
    MySQL.insert.await(('INSERT INTO `%s` (`serial`, `event`, `charId`, `byCharId`, `note`, `at`) VALUES (?, ?, ?, ?, ?, ?)'):format(T.history),
        { serial, event, charId, by, PWP.Text.clean(note, 200), now() })
end

local function itemName(item)
    local def = item and Whip.core:GetItemDef(item)
    return def and def.name or item
end

function Weapons.get(serial)
    serial = norm(serial)
    if not serial then return nil end
    local w = MySQL.single.await(('SELECT * FROM `%s` WHERE `serial` = ?'):format(T.weapons), { serial })
    if not w then return nil end
    w.name = itemName(w.item)
    w.history = MySQL.query.await(('SELECT `event`, `charId`, `byCharId`, `note`, `at` FROM `%s` WHERE `serial` = ? ORDER BY `id` DESC LIMIT 20'):format(T.history), { serial }) or {}
    local ids = { w.ownerCharId }
    for _, h in ipairs(w.history) do ids[#ids + 1] = h.charId; ids[#ids + 1] = h.byCharId end
    local list = {}
    for _, id in ipairs(ids) do if id then list[#list + 1] = id end end
    local names = #list > 0 and Whip.core:GetCharacterNames(list) or {}
    w.owner = w.ownerCharId and names[w.ownerCharId] or nil
    for _, h in ipairs(w.history) do h.who, h.by = h.charId and names[h.charId] or nil, h.byCharId and names[h.byCharId] or nil end
    return w
end

function Weapons.ofOwner(charId)
    local rows = MySQL.query.await(('SELECT `serial`, `item`, `status`, `registeredAt` FROM `%s` WHERE `ownerCharId` = ? ORDER BY `registeredAt` DESC LIMIT 50'):format(T.weapons),
        { tonumber(charId) }) or {}
    for _, r in ipairs(rows) do r.name = itemName(r.item) end
    return rows
end

function Weapons.register(serial, item, charId, byCharId, note)
    serial = norm(serial)
    charId = tonumber(charId)
    if not serial or not charId then return false, 'A gun needs a serial and an owner' end
    local old = MySQL.single.await(('SELECT `ownerCharId` FROM `%s` WHERE `serial` = ?'):format(T.weapons), { serial })
    MySQL.query.await(('INSERT INTO `%s` (`serial`, `item`, `ownerCharId`, `status`, `registeredAt`) VALUES (?, ?, ?, \'registered\', ?) ON DUPLICATE KEY UPDATE `ownerCharId` = VALUES(`ownerCharId`), `item` = COALESCE(VALUES(`item`), `item`), `status` = \'registered\', `registeredAt` = VALUES(`registeredAt`)'):format(T.weapons),
        { serial, item, charId, now() })
    log(serial, old and old.ownerCharId ~= charId and 'transferred' or 'registered', charId, byCharId, note)
    return true
end

function Weapons.setStatus(serial, status, byCharId, note)
    serial = norm(serial)
    if not serial or not STATUS[status] then return false, 'Registered, stolen, seized or destroyed' end
    local cur = MySQL.scalar.await(('SELECT `status` FROM `%s` WHERE `serial` = ?'):format(T.weapons), { serial })
    if not cur then return false, 'That serial is not registered' end
    if cur == status then return true end
    MySQL.update.await(('UPDATE `%s` SET `status` = ? WHERE `serial` = ?'):format(T.weapons), { status, serial })
    log(serial, status, nil, byCharId, note)
    return true
end

local function isGun(meta) return type(meta) == 'table' and type(meta.serial) == 'string' and type(meta.attachments) == 'table' end

AddEventHandler('whip_core:shop:purchased', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.source or not e.charId or not Config.Weapons.autoRegister then return end
    for _, line in ipairs(e.items or {}) do
        local def = line.itemKey and Whip.core:GetItemDef(line.itemKey)
        if def and def.type == 'weapon' and not def.stack then
            for _, found in ipairs(Whip.core:FindAllItems(e.source, line.itemKey) or {}) do
                local m = found.metadata
                if isGun(m) and not MySQL.scalar.await(('SELECT 1 FROM `%s` WHERE `serial` = ?'):format(T.weapons), { norm(m.serial) }) then
                    Weapons.register(m.serial, line.itemKey, e.charId, nil, 'Bought')
                end
            end
        end
    end
end)

Whip.register(function()
    for _, def in ipairs({
        { T.weapons, [[CREATE TABLE IF NOT EXISTS `%s` (`serial` VARCHAR(32) NOT NULL PRIMARY KEY, `item` VARCHAR(64) NULL,
            `ownerCharId` INT NULL, `status` ENUM('registered','stolen','seized','destroyed') NOT NULL DEFAULT 'registered',
            `registeredAt` INT UNSIGNED NOT NULL, INDEX (`ownerCharId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
        { T.history, [[CREATE TABLE IF NOT EXISTS `%s` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `serial` VARCHAR(32) NOT NULL,
            `event` VARCHAR(12) NOT NULL, `charId` INT NULL, `byCharId` INT NULL, `note` VARCHAR(200) NULL, `at` INT UNSIGNED NOT NULL,
            INDEX (`serial`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    }) do
        local ok = Whip.core:EnsureTable(def[1], def[2]:format(def[1]))
        if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, def[1])) end
    end
end)

exports('RegisterWeapon', function(serial, item, charId, note) return Weapons.register(serial, item, charId, nil, note) end)
exports('GetWeapon', function(serial) return Weapons.get(serial) end)
exports('SetWeaponStatus', function(serial, status, note) return Weapons.setStatus(serial, status, nil, note) end)

local TABLE = 'pure_whip_police_fines'
local Fines = {}
PWP.Fines = Fines

local function q(sql) return (sql:gsub('{t}', '`' .. TABLE .. '`')) end

function Fines.issue(charId, amount, opts)
    opts = opts or {}
    charId = tonumber(charId)
    if not charId or not PWP.Records.person(charId) then return false, 'No such character' end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > 10000000 then return false, 'A fine is $1 to $10,000,000' end
    local reason = PWP.Text.clean(opts.reason, 200) or 'Fine'
    local id = MySQL.insert.await(q([[INSERT INTO {t} (`charId`, `amount`, `reason`, `dept`, `issuedBy`, `reportId`)
        VALUES (?, ?, ?, ?, ?, ?)]]), { charId, amount, reason, opts.dept, PWP.Records.charOf(opts.by), tonumber(opts.reportId) })
    if not id then return false, 'Could not save the fine' end
    TriggerEvent(PWP.event('fined'), { id = id, charId = charId, amount = amount, by = opts.by, dept = opts.dept })
    return id
end

function Fines.list(charId, unpaidOnly)
    local sql = 'SELECT * FROM {t} WHERE `charId` = ?'
    if unpaidOnly then sql = sql .. " AND `status` = 'unpaid'" end
    return MySQL.query.await(q(sql .. ' ORDER BY `id` DESC LIMIT 100'), { tonumber(charId) }) or {}
end

local function account()
    local number = Config.Fines.account
    if type(number) ~= 'string' or number == '' then return nil end
    local acc = Whip.core:GetBankAccount({ number = number })
    return acc and acc.accountId or nil
end

local paying = {}

local function settle(src, session, charId)
    local unpaid = Fines.list(charId, true)
    if #unpaid == 0 then return false, 'You have no fines to pay' end
    local total, ids = 0, {}
    for _, f in ipairs(unpaid) do total = total + f.amount; ids[#ids + 1] = f.id end
    local receipt, why = Whip.core:ChargePlayer(src, total, { reason = ('Fines (%d)'):format(#ids) })
    if not receipt then return false, why end
    if not Whip.core:IsSessionCurrent(src, session) then
        Whip.core:RefundPlayer(receipt)
        return false
    end
    local placeholders = ('?,'):rep(#ids):sub(1, -2)
    local values = { charId }
    for _, id in ipairs(ids) do values[#values + 1] = id end
    local saved = Whip.core:CommitWithAction({ {
        query = q(("UPDATE {t} SET `status` = 'paid', `paidAt` = NOW() WHERE `charId` = ? AND `status` = 'unpaid' AND `id` IN (%s)"):format(placeholders)),
        values = values,
    } }, { source = src })
    if not saved then
        Whip.core:RefundPlayer(receipt)
        return false, 'Could not save that: your money is back'
    end
    return true, total, ids
end

function Fines.payAll(src, session)
    local charId = Whip.core:GetCharId(src)
    if not charId then return false, 'Not loaded' end
    if paying[charId] then return false, 'Already paying' end
    paying[charId] = true
    local ok, done, total, ids = pcall(settle, src, session, charId)
    paying[charId] = nil
    if not ok then print(('[%s] paying fines failed: %s'):format(PWP.RES, tostring(done))) return false, 'Could not pay' end
    if not done then return false, total end
    local acc = account()
    if acc then Whip.core:BankSystemDeposit(acc, total, { reason = 'Fines paid' }) end
    Whip.core:LogActivity(src, 'fines_paid', { detail = ('$%d for %d fines'):format(total, #ids) })
    return total, #ids
end

PWP.Points.kind('kiosk', {
    icon = 'dollar',
    public = true,
    options = {
        { id = 'check', label = 'Check my fines' },
        { id = 'pay', label = 'Pay all fines' },
    },
    onUse = function(source, _, _, use)
        CreateThread(function()
            local player = Whip.core:GetPlayer(source)
            if not player then return end
            if use.option == 'check' then
                local unpaid, total = Fines.list(player.charId, true), 0
                for _, f in ipairs(unpaid) do total = total + f.amount end
                Whip.core:NotifyPlayer(source, #unpaid == 0 and 'You have no fines' or
                    ('%d unpaid fines, $%d in all'):format(#unpaid, total), 'info')
                return
            end
            local paid, count = Fines.payAll(source, player.session)
            if not paid then
                if count then Whip.core:NotifyPlayer(source, count, 'error') end
                return
            end
            Whip.core:NotifyPlayer(source, ('Paid $%d (%d fines)'):format(paid, count), 'success')
        end)
        return true
    end,
})

Whip.register(function()
    local ok, why = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `charId` INT NOT NULL, `amount` INT UNSIGNED NOT NULL,
        `reason` VARCHAR(200) NOT NULL, `dept` VARCHAR(50) NULL, `issuedBy` INT NULL, `reportId` INT UNSIGNED NULL,
        `status` ENUM('unpaid','paid','void') NOT NULL DEFAULT 'unpaid', `paidAt` DATETIME NULL,
        `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`), KEY `charId` (`charId`, `status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] fines table: %s'):format(PWP.RES, tostring(why))) end
end)

exports('Fine', function(charId, amount, opts) return Fines.issue(charId, amount, opts) end)
exports('GetFines', function(charId) return Fines.list(charId, false) end)
exports('VoidFine', function(id)
    local changed = MySQL.update.await(q("UPDATE {t} SET `status` = 'void' WHERE `id` = ? AND `status` = 'unpaid'"), { tonumber(id) })
    if changed ~= 1 then return false, 'No unpaid fine with that id' end
    return true
end)

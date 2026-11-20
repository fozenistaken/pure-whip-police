local minutes = {}
local warned = {}
local WARN_EVERY = 600

local function phone(src, n)
    if GetResourceState('whip_phone') == 'started' then exports.whip_phone:Notify(src, n) end
end

local function tellLeaders(dept, amount)
    if os.time() - (warned[dept] or 0) < WARN_EVERY then return end
    warned[dept] = os.time()
    local text = ('The %s account could not pay a shift (%s). Fund the account to keep paying officers.'):format(PWP.dept(dept).short, PWP.money(amount))
    for _, o in ipairs(PWP.onDutyOfficers() or {}) do
        if o.dept == dept and Whip.core:HasJobPermission(o.source, dept, 'command') then
            phone(o.source, { app = 'pwpmdt', title = 'Missed paycheck', text = text, kind = 'command' })
        end
    end
end

local function fromDepartment(src, dept, amount, reason)
    local from = PWP.Fines.account(dept)
    if not from then return nil end
    local to = Whip.core:GetDefaultBankAccount(src)
    if not to then return false, 'They have no bank account' end
    return Whip.core:BankSystemTransfer(from, to.accountId, amount, { reason = reason, actorCharId = Whip.core:GetCharId(src) })
end

local function payOne(src, dept, session)
    if not Whip.core:IsSessionCurrent(src, session) or not Whip.core:IsPlayerClockedOn(src, dept) then return end
    local role = Whip.core:GetPlayerRole(src, dept)
    local amount = PWP.Catalogue.rate(Config.Pay.rates, role and role.level or 0)
    if amount <= 0 then return end
    local reason = ('Shift pay: %s'):format(PWP.dept(dept).short)
    if Config.Pay.from == 'department' then
        local paid, why = fromDepartment(src, dept, amount, reason)
        if paid then return end
        if paid == false then
            Whip.core:LogActivity(src, 'paycheck_missed', { detail = ('%s %d: %s'):format(dept, amount, tostring(why)) })
            phone(src, { app = 'pwpmdt', title = 'Missed paycheck', text = ('Your department could not pay this shift (%s).'):format(tostring(why)), kind = 'command' })
            if why == 'Insufficient funds' then tellLeaders(dept, amount) end
            return
        end
    end
    local paid, why = Whip.core:PayPlayer(src, amount, { method = 'bank', reason = reason })
    if not paid then print(('[%s] shift pay for %d failed: %s'):format(PWP.RES, src, tostring(why))) end
end

CreateThread(function()
    while true do
        Wait(60000)
        local every = math.max(1, math.floor(tonumber(Config.Pay.every) or 15))
        local seen = {}
        for _, o in ipairs(PWP.onDutyOfficers() or {}) do
            seen[o.source] = true
            minutes[o.source] = (minutes[o.source] or 0) + 1
            if minutes[o.source] >= every then
                minutes[o.source] = 0
                local player = Whip.core:GetPlayer(o.source)
                if player then CreateThread(function() payOne(o.source, o.dept, player.session) end) end
            end
        end
        for src in pairs(minutes) do
            if not seen[src] then minutes[src] = nil end
        end
    end
end)

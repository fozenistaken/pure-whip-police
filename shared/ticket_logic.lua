local Tickets = {}
PWP.TicketLogic = Tickets

local DAY = 86400
local PREFIX = { citation = 'CIT', parking = 'PRK', warning = 'WRN', fine = 'FIN' }
Tickets.KINDS = { citation = true, parking = true, warning = true }

function Tickets.number(kind, id)
    return ('%s-%06d'):format(PREFIX[kind] or 'FIN', tonumber(id) or 0)
end

function Tickets.parseNumber(text)
    local prefix, digits = tostring(text or ''):upper():match('^%s*(%a%a%a)%-?(%d+)%s*$')
    if not prefix then return nil end
    for kind, p in pairs(PREFIX) do
        if p == prefix then return tonumber(digits), kind end
    end
    return nil
end

function Tickets.allowed(kind, charge)
    if type(charge) ~= 'table' then return false end
    if kind == 'parking' then return charge.parking == 1 or charge.parking == true end
    return charge.citation == 1 or charge.citation == true
end

function Tickets.total(kind, codes, penal, cap)
    if kind == 'warning' then return 0 end
    local sum = 0
    for _, code in ipairs(codes) do sum = sum + ((penal[code] or {}).fine or 0) end
    return math.min(sum, cap or sum)
end

function Tickets.canContest(t, now)
    if type(t) ~= 'table' then return false, 'No such ticket' end
    if t.kind == 'warning' then return false, 'A warning has nothing to contest' end
    if t.status ~= 'unpaid' then return false, 'Only an unpaid ticket can be contested' end
    if t.signedAt then return false, 'You signed this ticket' end
    if (t.contest or 'none') ~= 'none' then return false, 'This ticket was contested already' end
    if not t.dueAt or now >= t.dueAt then return false, 'The deadline to contest has passed' end
    return true
end

function Tickets.overdue(t, now)
    return t.status == 'unpaid' and t.dueAt ~= nil and now >= t.dueAt and t.contest ~= 'open' and not t.warrantId
end

function Tickets.lapsed(t, now)
    return t.contest == 'open' and t.contestDue ~= nil and now >= t.contestDue
end

function Tickets.warrantMonths(amount, cfg)
    local months = math.ceil((tonumber(amount) or 0) / math.max(1, cfg.dollarsPerMonth))
    return math.max(cfg.minMonths, math.min(cfg.maxMonths, months))
end

function Tickets.ruling(t, verdict, amount)
    if verdict == 'dismiss' then return { status = 'void', contest = 'dismissed' } end
    if verdict == 'uphold' then return { contest = 'upheld', restart = true } end
    if verdict == 'reduce' then
        amount = math.floor(tonumber(amount) or -1)
        if amount < 0 or amount >= (t.amount or 0) then return nil, 'A reduced fine is lower than the ticket' end
        if amount == 0 then return { status = 'void', contest = 'reduced', amount = 0 } end
        return { contest = 'reduced', amount = amount, restart = true }
    end
    return nil, 'Dismiss, reduce or uphold'
end

function Tickets.storageDays(at, now, maxDays)
    return math.max(0, math.min(maxDays, math.floor((now - at) / DAY)))
end

function Tickets.bill(row, now, storage)
    local days = Tickets.storageDays(row.at, row.paidAt or now, storage.maxDays)
    return { fee = row.fee, days = days, storage = days * storage.perDay, total = row.fee + days * storage.perDay,
        most = row.fee + storage.maxDays * storage.perDay }
end

function Tickets.held(row, now)
    if row.holdOpen == 1 or row.holdOpen == true then return true, nil end
    if row.holdUntil and now < row.holdUntil then return true, row.holdUntil end
    return false
end

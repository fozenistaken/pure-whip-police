local T = PWP.TicketLogic
local DAY = 86400

Test('ticket numbers', function()
    Eq(T.number('citation', 42), 'CIT-000042')
    Eq(T.number('parking', 7), 'PRK-000007')
    local id, kind = T.parseNumber(' prk-000007 ')
    Eq(id, 7); Eq(kind, 'parking')
    Eq(T.parseNumber('XYZ-1'), nil)
    Eq(T.parseNumber('CIT'), nil)
end)

Test('charges allowed per kind', function()
    Eq(T.allowed('citation', { citation = 1, parking = 0 }), true)
    Eq(T.allowed('parking', { citation = 1, parking = 0 }), false)
    Eq(T.allowed('parking', { parking = 1 }), true)
    Eq(T.allowed('warning', { citation = 1 }), true)
    Eq(T.allowed('citation', nil), false)
end)

Test('totals and cap', function()
    local penal = { A = { fine = 300 }, B = { fine = 900 } }
    Eq(T.total('citation', { 'A', 'B' }, penal, 1000), 1000)
    Eq(T.total('citation', { 'A' }, penal, 1000), 300)
    Eq(T.total('warning', { 'A', 'B' }, penal, 1000), 0)
end)

Test('contest rules', function()
    local t = { kind = 'citation', status = 'unpaid', dueAt = 1000, contest = 'none' }
    Eq(T.canContest(t, 500), true)
    Eq(select(1, T.canContest(t, 1000)), false)
    t.signedAt = 10
    Eq(select(1, T.canContest(t, 500)), false)
    Eq(select(1, T.canContest({ kind = 'warning', status = 'warning' }, 0)), false)
    Eq(select(1, T.canContest({ kind = 'citation', status = 'paid', dueAt = 1000 }, 0)), false)
    Eq(select(1, T.canContest({ kind = 'citation', status = 'unpaid', dueAt = 1000, contest = 'open' }, 0)), false)
end)

Test('overdue and lapse', function()
    Eq(T.overdue({ status = 'unpaid', dueAt = 100, contest = 'none' }, 100), true)
    Eq(T.overdue({ status = 'unpaid', dueAt = 100, contest = 'open' }, 200), false)
    Eq(T.overdue({ status = 'unpaid', dueAt = 100, contest = 'none', warrantId = 4 }, 200), false)
    Eq(T.overdue({ status = 'unpaid', dueAt = nil }, 200), false)
    Eq(T.lapsed({ contest = 'open', contestDue = 50 }, 50), true)
    Eq(T.lapsed({ contest = 'open', contestDue = 50 }, 49), false)
end)

Test('warrant months from dollars', function()
    local cfg = { dollarsPerMonth = 500, minMonths = 1, maxMonths = 10 }
    Eq(T.warrantMonths(200, cfg), 1)
    Eq(T.warrantMonths(1250, cfg), 3)
    Eq(T.warrantMonths(999999, cfg), 10)
end)

Test('court rulings never raise a fine', function()
    local t = { amount = 500 }
    Eq(T.ruling(t, 'dismiss').status, 'void')
    Eq(T.ruling(t, 'uphold').restart, true)
    Eq(T.ruling(t, 'reduce', 200).amount, 200)
    Eq(T.ruling(t, 'reduce', 0).status, 'void')
    Eq(T.ruling(t, 'reduce', 500), nil)
    Eq(T.ruling(t, 'reduce', 900), nil)
    Eq(T.ruling(t, 'pardon'), nil)
end)

Test('impound bill with capped storage', function()
    local storage = { perDay = 100, maxDays = 5 }
    local b = T.bill({ fee = 500, at = 0 }, 2 * DAY + 10, storage)
    Eq(b.days, 2); Eq(b.total, 700); Eq(b.most, 1000)
    Eq(T.bill({ fee = 500, at = 0 }, 30 * DAY, storage).total, 1000)
    Eq(T.bill({ fee = 500, at = 0, paidAt = DAY }, 30 * DAY, storage).total, 600)
end)

Test('holds', function()
    Eq(T.held({ holdOpen = 1 }, 0), true)
    Eq(T.held({ holdUntil = 100 }, 50), true)
    Eq(T.held({ holdUntil = 100 }, 100), false)
    Eq(T.held({}, 0), false)
end)

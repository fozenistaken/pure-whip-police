local Ev = PWP.Evidence

Test('codes are stable per character and salt', function()
    Eq(Ev.code('DNA', 12, 'salt'), Ev.code('DNA', 12, 'salt'), 'same input')
    Eq(Ev.code('DNA', 12, 'salt') ~= Ev.code('DNA', 13, 'salt'), true, 'other character')
    Eq(Ev.code('DNA', 12, 'salt') ~= Ev.code('DNA', 12, 'other'), true, 'other salt')
    Eq(Ev.code('FP', 12, 'salt'):match('^FP%-%x%x%x%x%-%x%x%x%x$') ~= nil, true, 'format')
end)

Test('pushPrint puts the newest first, unique, capped', function()
    local l = Ev.pushPrint({ 'A', 'B', 'C' }, 'B', 3)
    Eq(table.concat(l, ','), 'B,A,C', 'moved to front')
    l = Ev.pushPrint({ 'A', 'B', 'C' }, 'D', 3)
    Eq(table.concat(l, ','), 'D,A,B', 'capped')
    l = Ev.pushPrint(nil, 'A', 3)
    Eq(table.concat(l, ','), 'A', 'from nothing')
end)

Test('sameBurst needs both time and place', function()
    local last = { at = 1000, coords = { x = 0, y = 0, z = 0 } }
    Eq(Ev.sameBurst(last, { x = 3, y = 0, z = 0 }, 2000, 10, 30000), true, 'near and soon')
    Eq(Ev.sameBurst(last, { x = 11, y = 0, z = 0 }, 2000, 10, 30000), false, 'too far')
    Eq(Ev.sameBurst(last, { x = 1, y = 0, z = 0 }, 40000, 10, 30000), false, 'too late')
    Eq(Ev.sameBurst(nil, { x = 1, y = 0, z = 0 }, 1, 10, 30000), false, 'no last')
end)

Test('near finds a match inside the radius only', function()
    local list = { { coords = { x = 0, y = 0, z = 0 }, who = 1 }, { coords = { x = 5, y = 0, z = 0 }, who = 2 } }
    local e = Ev.near(list, { x = 4.5, y = 0, z = 0 }, 1)
    Eq(e and e.who, 2, 'nearest inside')
    Eq(Ev.near(list, { x = 2.5, y = 0, z = 0 }, 1), nil, 'none inside')
    Eq(Ev.near(list, { x = 0.5, y = 0, z = 0 }, 1, function(x) return x.who == 2 end), nil, 'match filter')
end)

Test('result texts', function()
    Eq(Ev.result({ kind = 'casing', serial = 'AB12' }, 'Pistol'), 'Fired from a Pistol, serial AB12', 'casing')
    Eq(Ev.result({ kind = 'blood', dna = 'DNA-1' }), 'DNA DNA-1', 'blood')
    Eq(Ev.result({ kind = 'prints', prints = {} }), 'No usable prints', 'no prints')
    Eq(Ev.result({ kind = 'gun', serial = 'X', prints = { 'FP-1' } }), 'Serial X; prints FP-1', 'gun')
end)

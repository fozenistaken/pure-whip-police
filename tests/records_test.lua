local catalogue = {
    P101 = { fine = 500, months = 5 },
    P202 = { fine = 1500, months = 0 },
}

Test('penal totals add fines and months per count', function()
    local t = PWP.Penal.totals({ { code = 'P101', count = 2 } }, catalogue)
    Eq(t.fine, 1000, 'fine'); Eq(t.months, 10, 'months')
end)

Test('penal totals skip unknown codes and floor bad counts to 1', function()
    local t = PWP.Penal.totals({ { code = 'NOPE', count = 3 }, { code = 'P202', count = 0 } }, catalogue)
    Eq(t.fine, 1500, 'fine'); Eq(t.months, 0, 'months')
end)

Test('plates are trimmed, uppercased and single spaced', function()
    Eq(PWP.Plates.norm('  ab  12 '), 'AB 12', 'plate')
end)

Test('empty, long or odd plates are nil', function()
    Eq(PWP.Plates.norm(''), nil, 'empty')
    Eq(PWP.Plates.norm('ABCDEFGHI'), nil, 'long')
    Eq(PWP.Plates.norm('AB-12'), nil, 'dash')
end)

Test('revision: same passes, older is stale', function()
    Eq(PWP.Revision.check(3, 3), true, 'same')
    local ok, why = PWP.Revision.check(3, 2)
    Eq(ok, false, 'stale ok'); Eq(why, 'stale', 'stale why')
end)

Test('text clean strips control chars and caps length', function()
    Eq(PWP.Text.clean('  hi\1 there  ', 50), 'hi there', 'clean')
    Eq(PWP.Text.clean('abcdef', 3), 'abc', 'cap')
    Eq(PWP.Text.clean('   ', 10), nil, 'blank')
end)

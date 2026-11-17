local C = PWP.Catalogue
local function licences(list)
    return function(key) return list[key] == true end
end

Test('rank too low is refused', function()
    local ok, why = C.allowed({ minLevel = 20, licence = 'swat' }, 10, licences({ swat = true }))
    Eq(ok, false, 'ok'); Eq(why, 'Your rank is too low for that', 'why')
end)

Test('rank met but licence missing is refused', function()
    local ok, why = C.allowed({ minLevel = 20, licence = 'swat', licenceLabel = 'SWAT' }, 20, licences({}))
    Eq(ok, false, 'ok'); Eq(why, 'You need the SWAT licence', 'why')
end)

Test('rank and licence met is allowed', function()
    Eq(C.allowed({ minLevel = 20, licence = 'swat' }, 20, licences({ swat = true })), true, 'ok')
end)

Test('no minLevel means level 1', function()
    Eq(C.allowed({}, 1, licences({})), true, 'ok')
end)

Test('pay rate picks the highest level at or below', function()
    local rates = { { level = 1, amount = 60 }, { level = 10, amount = 80 }, { level = 40, amount = 115 } }
    Eq(C.rate(rates, 25), 80, 'level 25')
    Eq(C.rate(rates, 40), 115, 'level 40')
    Eq(C.rate(rates, 0), 0, 'level 0')
end)

local S = PWP.Sentence
local function v(x, y, z) return { x = x, y = y, z = z } end

Test('months to minutes at 1 per month', function() Eq(S.minutes(10, 1), 10, 'minutes') end)
Test('fractional rate rounds up, never below 1', function()
    Eq(S.minutes(3, 0.5), 2, 'half'); Eq(S.minutes(1, 0.1), 1, 'min one')
end)
Test('zero or bad months is no sentence', function() Eq(S.minutes(0, 1), 0, 'zero'); Eq(S.minutes('x', 1), 0, 'bad') end)
Test('cut never goes below zero', function() Eq(S.cut(3, 2), 1, 'cut'); Eq(S.cut(1, 5), 0, 'floor') end)

local box = { pos = v(1677.5, 2570.0, 45.0), size = v(305.0, 260.0, 60.0), heading = 0.0 }
Test('a cell spawn is inside the prison box', function() Eq(S.inBox(v(1661.05, 2524.68, 45.56), box), true, 'inside') end)
Test('the release gate is outside the prison box', function() Eq(S.inBox(v(1848.13, 2586.05, 45.67), box), false, 'gate') end)
Test('every inmate job spot is inside', function()
    for _, p in ipairs({ v(1761.46, 2540.41, 45.56), v(1621.62, 2509.30, 45.56), v(1625.10, 2575.99, 45.56) }) do
        Eq(S.inBox(p, box), true, 'job')
    end
end)
Test('a rotated box turns with its heading', function()
    local r = { pos = v(0, 0, 0), size = v(10, 2, 10), heading = 90.0 }
    Eq(S.inBox(v(0, 4, 0), r), true, 'along y'); Eq(S.inBox(v(4, 0, 0), r), false, 'across x')
end)

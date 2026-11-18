local A = PWP.Academy
local seed = 7
local function rand(a, b) seed = (seed * 1103515245 + 12345) % 2147483648 return a + seed % (b - a + 1) end

local PENAL = {
    { code = 'T101', title = 'Speeding', category = 'infraction', fine = 250, months = 0 },
    { code = 'P105', title = 'Resisting arrest', category = 'misdemeanor', fine = 1000, months = 5 },
    { code = 'R104', title = 'Robbery', category = 'felony', fine = 4000, months = 15 },
    { code = 'V102', title = 'Assault with a deadly weapon', category = 'felony', fine = 3500, months = 12 },
}
local EXTRA = { { q = 'What does 10-71 mean?', a = 'Shots fired', wrong = { 'Officer needs help', 'Traffic stop', 'Lunch' } } }

Test('exam has the asked count and every key points at the right option', function()
    local exam, key = A.build(PENAL, EXTRA, 6, rand)
    Eq(#exam, 6, 'six questions')
    for i, q in ipairs(exam) do
        Eq(q.options[key[i]] ~= nil, true, 'key in range ' .. i)
        Eq(q.answer, nil, 'no answer sent with question ' .. i)
        local seen = {}
        for _, o in ipairs(q.options) do Eq(seen[o], nil, 'no duplicate option'); seen[o] = true end
    end
end)

Test('fine questions name the real fine as the right answer', function()
    local exam, key = A.build({ PENAL[1], PENAL[3] }, {}, 10, rand)
    for i, q in ipairs(exam) do
        if q.text == 'What is the fine for Robbery?' then Eq(q.options[key[i]], '$4000', 'robbery fine') end
        if q.text == 'What kind of charge is Speeding?' then Eq(q.options[key[i]], 'Infraction', 'speeding kind') end
    end
end)

Test('scoring counts right answers only', function()
    local key = { 2, 1, 4 }
    local right, total = A.score(key, { 2, 3, 4 })
    Eq(right, 2, 'two right'); Eq(total, 3, 'of three')
    right = A.score(key, { ['1'] = 2 })
    Eq(right, 1, 'string keys from JSON')
end)

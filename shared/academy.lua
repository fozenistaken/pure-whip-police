local Academy = {}
PWP.Academy = Academy

local CAT = { infraction = 'Infraction', misdemeanor = 'Misdemeanor', felony = 'Felony' }

local function shuffle(list, rand)
    for i = #list, 2, -1 do
        local j = rand(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local function choices(right, pool, rand)
    local seen, out = { [right] = true }, { right }
    for _, v in ipairs(shuffle(pool, rand)) do
        if #out >= 4 then break end
        if not seen[v] then seen[v] = true; out[#out + 1] = v end
    end
    if #out < 2 then return nil end
    shuffle(out, rand)
    for i, v in ipairs(out) do if v == right then return out, i end end
end

local function money(n) return '$' .. tostring(math.floor(n)) end

function Academy.build(penal, extra, count, rand)
    local made = {}
    local fines, months = {}, {}
    for _, c in ipairs(penal) do
        fines[#fines + 1] = money(c.fine)
        if c.months > 0 then months[#months + 1] = c.months .. ' months' end
    end
    for _, c in ipairs(penal) do
        local opts, at = choices(money(c.fine), { table.unpack(fines) }, rand)
        if opts then made[#made + 1] = { text = ('What is the fine for %s?'):format(c.title), options = opts, answer = at } end
        if c.months > 0 then
            opts, at = choices(c.months .. ' months', { table.unpack(months) }, rand)
            if opts then made[#made + 1] = { text = ('How long in prison for %s?'):format(c.title), options = opts, answer = at } end
        end
        if CAT[c.category] then
            opts, at = choices(CAT[c.category], { 'Infraction', 'Misdemeanor', 'Felony' }, rand)
            if opts then made[#made + 1] = { text = ('What kind of charge is %s?'):format(c.title), options = opts, answer = at } end
        end
    end
    for _, q in ipairs(extra or {}) do
        local opts, at = choices(q.a, { table.unpack(q.wrong or {}) }, rand)
        if opts then made[#made + 1] = { text = q.q, options = opts, answer = at } end
    end
    shuffle(made, rand)
    local exam, key = {}, {}
    for i = 1, math.min(count, #made) do
        exam[i] = { id = i, text = made[i].text, options = made[i].options }
        key[i] = made[i].answer
    end
    return exam, key
end

function Academy.score(key, answers)
    local right = 0
    for id, answer in pairs(key) do
        if tonumber(answers[id] or answers[tostring(id)]) == answer then right = right + 1 end
    end
    return right, #key
end

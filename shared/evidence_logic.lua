local Ev = {}
PWP.Evidence = Ev

local function fnv(text, seed)
    local h = seed
    for i = 1, #text do
        h = (h ~ text:byte(i)) * 16777619 & 0xFFFFFFFF
    end
    return h
end

function Ev.code(prefix, charId, salt)
    local text = ('%s:%s:%s'):format(prefix, tostring(charId), tostring(salt))
    local a = fnv(text, 2166136261) & 0xFFFF
    local b = fnv(text, 3735928559) & 0xFFFF
    return ('%s-%04X-%04X'):format(prefix, a, b)
end

function Ev.pushPrint(list, code, max)
    local out = { code }
    for _, c in ipairs(type(list) == 'table' and list or {}) do
        if c ~= code and #out < max then out[#out + 1] = c end
    end
    return out
end

function Ev.sameBurst(last, coords, now, radius, windowMs)
    if not last then return false end
    if now - last.at > windowMs then return false end
    local dx, dy, dz = coords.x - last.coords.x, coords.y - last.coords.y, coords.z - last.coords.z
    return dx * dx + dy * dy + dz * dz <= radius * radius
end

function Ev.near(list, coords, radius, match)
    for i, e in ipairs(list) do
        local dx, dy, dz = coords.x - e.coords.x, coords.y - e.coords.y, coords.z - e.coords.z
        if dx * dx + dy * dy + dz * dz <= radius * radius and (not match or match(e)) then return e, i end
    end
    return nil
end

function Ev.result(meta, gunName)
    local kind = meta.kind
    if kind == 'casing' or kind == 'fragment' then
        return ('Fired from a %s, serial %s'):format(gunName or 'gun', meta.serial or 'unknown')
    elseif kind == 'blood' then
        return ('DNA %s'):format(meta.dna or 'unreadable')
    elseif kind == 'prints' then
        local list = type(meta.prints) == 'table' and meta.prints or {}
        return #list > 0 and ('Prints ' .. table.concat(list, ', ')) or 'No usable prints'
    elseif kind == 'gun' then
        local list = type(meta.prints) == 'table' and meta.prints or {}
        return ('Serial %s; %s'):format(meta.serial or 'none',
            #list > 0 and ('prints ' .. table.concat(list, ', ')) or 'no prints')
    end
    return 'Nothing to analyse'
end

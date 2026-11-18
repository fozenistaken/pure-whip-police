local json = {}

local escapes = { ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

local function isArray(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= 'number' or k < 1 or k % 1 ~= 0 then return false end
        n = n + 1
    end
    for i = 1, n do if t[i] == nil then return false end end
    return true, n
end

local function enc(v)
    local t = type(v)
    if t == 'nil' then return 'null' end
    if t == 'boolean' then return tostring(v) end
    if t == 'number' then
        if v ~= v or v == math.huge or v == -math.huge then return 'null' end
        if math.type(v) == 'integer' or v % 1 == 0 and math.abs(v) < 1e15 then return string.format('%d', v) end
        return string.format('%.14g', v)
    end
    if t == 'string' then
        return '"' .. v:gsub('[%c"\\]', function(c) return escapes[c] or string.format('\\u%04x', c:byte()) end) .. '"'
    end
    if t == 'table' then
        local arr, n = isArray(v)
        if arr and n > 0 then
            local out = {}
            for i = 1, n do out[i] = enc(v[i]) end
            return '[' .. table.concat(out, ',') .. ']'
        end
        local out = {}
        for k, val in pairs(v) do out[#out + 1] = enc(tostring(k)) .. ':' .. enc(val) end
        return '{' .. table.concat(out, ',') .. '}'
    end
    error('json: cannot encode ' .. t)
end

function json.encode(v) return enc(v) end

local function skip(s, i)
    local _, e = s:find('^[ \n\r\t]*', i)
    return e + 1
end

local dec

local function decString(s, i)
    local out, j = {}, i + 1
    while true do
        local c = s:sub(j, j)
        if c == '' then error('json: unterminated string') end
        if c == '"' then return table.concat(out), j + 1 end
        if c == '\\' then
            local n = s:sub(j + 1, j + 1)
            local map = { b = '\b', f = '\f', n = '\n', r = '\r', t = '\t', ['"'] = '"', ['\\'] = '\\', ['/'] = '/' }
            if n == 'u' then
                out[#out + 1] = utf8.char(tonumber(s:sub(j + 2, j + 5), 16))
                j = j + 6
            else
                out[#out + 1] = map[n] or n
                j = j + 2
            end
        else
            out[#out + 1] = c
            j = j + 1
        end
    end
end

dec = function(s, i)
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == '{' then
        local t = {}
        i = skip(s, i + 1)
        if s:sub(i, i) == '}' then return t, i + 1 end
        while true do
            local k
            k, i = decString(s, skip(s, i))
            i = skip(s, i)
            i = i + 1
            t[k], i = dec(s, i)
            i = skip(s, i)
            local d = s:sub(i, i)
            i = i + 1
            if d == '}' then return t, i end
        end
    elseif c == '[' then
        local t = {}
        i = skip(s, i + 1)
        if s:sub(i, i) == ']' then return t, i + 1 end
        while true do
            t[#t + 1], i = dec(s, i)
            i = skip(s, i)
            local d = s:sub(i, i)
            i = i + 1
            if d == ']' then return t, i end
        end
    elseif c == '"' then
        return decString(s, i)
    elseif s:sub(i, i + 3) == 'true' then return true, i + 4
    elseif s:sub(i, i + 4) == 'false' then return false, i + 5
    elseif s:sub(i, i + 3) == 'null' then return nil, i + 4
    end
    local num = s:match('^-?%d+%.?%d*[eE]?[-+]?%d*', i)
    if not num or num == '' then error('json: bad value at ' .. i) end
    return tonumber(num), i + #num
end

function json.decode(s)
    if type(s) ~= 'string' then return nil end
    local v = dec(s, 1)
    return v
end

return json

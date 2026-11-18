PWP = PWP or {}

local Sentence = {}
PWP.Sentence = Sentence

function Sentence.minutes(months, perMonth)
    months = math.floor(tonumber(months) or 0)
    perMonth = tonumber(perMonth) or 1
    if months < 1 then return 0 end
    return math.max(1, math.ceil(months * perMonth))
end

function Sentence.cut(left, by)
    return math.max(0, (tonumber(left) or 0) - math.max(0, tonumber(by) or 0))
end

function Sentence.edge(pos, box)
    local h = math.rad(-(box.heading or 0.0))
    local dx, dy = pos.x - box.pos.x, pos.y - box.pos.y
    local lx = dx * math.cos(h) - dy * math.sin(h)
    local ly = dx * math.sin(h) + dy * math.cos(h)
    return math.min(box.size.x / 2 - math.abs(lx), box.size.y / 2 - math.abs(ly))
end

function Sentence.inBox(pos, box)
    local h = math.rad(-(box.heading or 0.0))
    local dx, dy = pos.x - box.pos.x, pos.y - box.pos.y
    local lx = dx * math.cos(h) - dy * math.sin(h)
    local ly = dx * math.sin(h) + dy * math.cos(h)
    return math.abs(lx) <= box.size.x / 2 and math.abs(ly) <= box.size.y / 2
        and math.abs(pos.z - box.pos.z) <= box.size.z / 2
end

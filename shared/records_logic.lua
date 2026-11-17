PWP = PWP or {}

local Penal = {}
PWP.Penal = Penal

function Penal.totals(charges, catalogue)
    local fine, months = 0, 0
    for _, c in ipairs(charges or {}) do
        local def = catalogue[c.code]
        local count = math.max(1, math.floor(tonumber(c.count) or 1))
        if def then
            fine = fine + (def.fine or 0) * count
            months = months + (def.months or 0) * count
        end
    end
    return { fine = fine, months = months }
end

local Plates = {}
PWP.Plates = Plates

function Plates.norm(s)
    if type(s) ~= 'string' then return nil end
    s = s:upper():gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
    if #s < 1 or #s > 8 or s:find('[^%w ]') then return nil end
    return s
end

local Revision = {}
PWP.Revision = Revision

function Revision.check(stored, incoming)
    stored, incoming = tonumber(stored), tonumber(incoming)
    if not stored or not incoming then return false, 'missing revision' end
    if incoming ~= stored then return false, 'stale' end
    return true
end

local Text = {}
PWP.Text = Text

function Text.clean(s, maxLen)
    if type(s) ~= 'string' then return nil end
    s = s:gsub('[%z\1-\8\11\12\14-\31]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    if #s == 0 then return nil end
    if #s > maxLen then s = s:sub(1, maxLen) end
    return s
end

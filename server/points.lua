local Points = { kinds = {}, ids = {} }
PWP.Points = Points

function Points.kind(kind, def)
    Points.kinds[kind] = def
end

local function mergeRequire(dept, extra)
    local req = { job = dept }
    for k, v in pairs(extra or {}) do req[k] = v end
    return req
end

local function addPoint(row, def)
    local dept = row.dept
    local options = def.options
    if type(options) == 'function' then options = options(dept, row) end
    return Whip.core:AddPoint({
        at = { coords = row.coords },
        label = row.label,
        icon = def.icon,
        audience = { job = dept },
        require = mergeRequire(dept, def.require),
        reach = Config.PointReach,
        options = options,
        onUse = function(source, use) return def.onUse(source, dept, row, use) end,
    })
end

function Points.build()
    for _, id in ipairs(Points.ids) do Whip.core:RemovePoint(id) end
    Points.ids = {}
    for i, row in ipairs(Config.Points) do
        local def = Points.kinds[row.kind]
        if not def then
            print(('[%s] point %d: no kind "%s"'):format(PWP.RES, i, tostring(row.kind)))
        elseif not PWP.isDept(row.dept) then
            print(('[%s] point %d: no department "%s"'):format(PWP.RES, i, tostring(row.dept)))
        elseif def.build then
            local ok, why = def.build(row, i)
            if not ok then print(('[%s] point %d (%s): %s'):format(PWP.RES, i, row.kind, tostring(why))) end
        else
            local id, why = addPoint(row, def)
            if id then
                Points.ids[#Points.ids + 1] = id
            else
                print(('[%s] point %d (%s) refused: %s'):format(PWP.RES, i, row.kind, tostring(why)))
            end
        end
    end
end

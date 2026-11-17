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

function Points.build()
    for _, id in ipairs(Points.ids) do Whip.core:RemovePoint(id) end
    Points.ids = {}
    for i, row in ipairs(Config.Points) do
        local def = Points.kinds[row.kind]
        if not def then
            print(('[%s] point %d: no kind "%s"'):format(PWP.RES, i, tostring(row.kind)))
        elseif not PWP.isDept(row.dept) then
            print(('[%s] point %d: no department "%s"'):format(PWP.RES, i, tostring(row.dept)))
        else
            local dept = row.dept
            local id, why = Whip.core:AddPoint({
                at = { coords = row.coords },
                label = row.label,
                icon = def.icon,
                audience = { job = dept },
                require = mergeRequire(dept, def.require),
                reach = Config.PointReach,
                options = def.options,
                onUse = function(source, use) return def.onUse(source, dept, row, use) end,
            })
            if id then
                Points.ids[#Points.ids + 1] = id
            else
                print(('[%s] point %d (%s) refused: %s'):format(PWP.RES, i, row.kind, tostring(why)))
            end
        end
    end
end

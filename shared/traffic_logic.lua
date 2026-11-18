local Radar = {}
PWP.Radar = Radar

function Radar.factor(unit) return unit == 'mph' and 2.236936 or 3.6 end
function Radar.unitName(unit) return unit == 'mph' and 'mph' or 'km/h' end

function Radar.pick(offsets, range, lane)
    local best = {}
    for _, o in ipairs(offsets) do
        local d = math.abs(o.y)
        if math.abs(o.x) <= lane and math.abs(o.z) <= 5.0 and d > 2.0 and d <= range then
            local side = o.y > 0 and 'front' or 'rear'
            if not best[side] or d < best[side].d then best[side] = { item = o.item, d = d } end
        end
    end
    return best
end

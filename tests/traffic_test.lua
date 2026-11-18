local Radar = PWP.Radar

local function o(x, y, z, item) return { x = x, y = y, z = z or 0, item = item } end

Test('radar picks the nearest car in the lane ahead and behind', function()
    local best = Radar.pick({ o(0, 30, 0, 'far'), o(1, 12, 0, 'near'), o(0, -20, 0, 'back'), o(0, -8, 0, 'backnear') }, 80, 6)
    Eq(best.front.item, 'near', 'front nearest')
    Eq(best.rear.item, 'backnear', 'rear nearest')
end)

Test('radar ignores other lanes, other heights, too close and too far', function()
    local best = Radar.pick({ o(7, 10), o(0, 10, 6), o(0, 1.5), o(0, 90) }, 80, 6)
    Eq(best.front, nil, 'nothing ahead counts')
    Eq(best.rear, nil, 'nothing behind')
end)

Test('units', function()
    Eq(math.floor(30 * Radar.factor('kmh') + 0.5), 108, '30 m/s in km/h')
    Eq(math.floor(30 * Radar.factor('mph') + 0.5), 67, '30 m/s in mph')
    Eq(Radar.unitName('mph'), 'mph', 'mph name')
    Eq(Radar.unitName('kmh'), 'km/h', 'kmh name')
end)

local MAX = 32
local Radio = { lines = {}, member = {} }
PWP.Radio = Radio

local function provider()
    local res = Config.Providers.radio
    if res and res ~= 'builtin' then
        if GetResourceState(res) == 'started' then return res end
        print(('[%s] radio provider %s is not started: using the built-in radio'):format(PWP.RES, res))
    end
    return nil
end

local function channel(dept) return PWP.RES .. ':' .. dept end

local function openLine(dept, first)
    local id, why = Whip.voice('OpenLine', {
        members = { first }, track = 'radio', minMembers = 1, sameWorld = true,
        recipe = { { 'band', low = 300, high = 3400 }, { 'compress', threshold = -24, ratio = 4 } },
        onEnd = function(lineId)
            local list = Radio.lines[dept] or {}
            for i, l in ipairs(list) do if l.id == lineId then table.remove(list, i) break end end
        end,
    })
    if not id then return false, why end
    local list = Radio.lines[dept] or {}
    list[#list + 1] = { id = id, count = 1 }
    Radio.lines[dept] = list
    return id
end

function Radio.join(src, dept)
    local res = provider()
    if res then return exports[res]:JoinChannel(src, channel(dept)) end
    if Radio.member[src] then Radio.leave(src) end
    for _, l in ipairs(Radio.lines[dept] or {}) do
        if l.count < MAX then
            local ok = Whip.voice('AddLineMember', l.id, src)
            if ok then
                l.count = l.count + 1
                Radio.member[src] = { dept = dept, line = l.id }
                return true
            end
        end
    end
    local id, why = openLine(dept, src)
    if not id then return false, why end
    Radio.member[src] = { dept = dept, line = id }
    return true
end

function Radio.leave(src)
    local res = provider()
    local m = Radio.member[src]
    Radio.member[src] = nil
    if res then
        if m then return exports[res]:LeaveChannel(src, channel(m.dept)) end
        return true
    end
    if not m then return true end
    for _, l in ipairs(Radio.lines[m.dept] or {}) do
        if l.id == m.line then l.count = math.max(0, l.count - 1) end
    end
    Whip.voice('RemoveLineMember', m.line, src)
    return true
end

local function rejoinAll()
    Radio.lines, Radio.member = {}, {}
    for _, o in ipairs(PWP.onDutyOfficers() or {}) do Radio.join(o.source, o.dept) end
end

AddEventHandler(PWP.event('dutyChanged'), function(e)
    if not e.source then return end
    if e.onDuty then
        local ok, why = Radio.join(e.source, e.dept)
        if not ok and why then print(('[%s] radio for %d: %s'):format(PWP.RES, e.source, tostring(why))) end
    else
        Radio.leave(e.source)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'whip_voice' then SetTimeout(3000, rejoinAll) end
end)
AddEventHandler('onResourceStop', function(res)
    if res == 'whip_voice' then Radio.lines, Radio.member = {}, {} end
end)
AddEventHandler('playerDropped', function() Radio.member[source] = nil end)

Whip.register(function() SetTimeout(2000, rejoinAll) end)

exports('GetRadioChannel', function(dept)
    if not PWP.isDept(dept) then return false, 'No such department' end
    return channel(dept)
end)

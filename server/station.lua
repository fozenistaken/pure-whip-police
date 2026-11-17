local NS = PWP.RES .. ':station'
local Station = { sessions = {}, handlers = {} }
PWP.Station = Station

local function near(src, row)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(row.coords.x, row.coords.y, row.coords.z)) <= Config.PointReach + 3.0
end

--- kind: 'wardrobe' | 'garage' | 'armory' | 'locker' | 'stash'. build(src, session) returns the panel's data or false, why.
function Station.kind(kind, def)
    Station.handlers[kind] = def
end

function Station.open(src, kind, dept, row)
    local def = Station.handlers[kind]
    if not def then return false, 'Not available' end
    CreateThread(function()
        local session = { kind = kind, dept = dept, row = row }
        local data, why = def.build(src, session)
        if not data then return Whip.core:NotifyPlayer(src, why or 'Not available', 'error') end
        Station.sessions[src] = session
        data.kind, data.dept, data.short, data.title = kind, dept, PWP.dept(dept).short, row.label
        TriggerClientEvent(PWP.event('station'), src, data, { x = row.coords.x, y = row.coords.y, z = row.coords.z })
    end)
    return true
end

function Station.current(src, kind)
    local s = Station.sessions[src]
    if not s or (kind and s.kind ~= kind) then return nil, 'That is closed' end
    if not near(src, s.row) then Station.sessions[src] = nil return nil, 'Too far away' end
    return s
end

Whip.register(function()
    Whip.core:SecureCallback(NS .. ':act', { rateLimit = 150, params = { { 'action', 'string' }, { 'args', 'any' } } },
        function(source, _, action, args)
            if action == 'close' then Station.sessions[source] = nil return true end
            local s, why = Station.current(source)
            if not s then return false, why end
            local def = Station.handlers[s.kind]
            local fn = def and def.actions and def.actions[action]
            if not fn then return false, 'Not available' end
            local ok, result, reason = pcall(fn, source, s, type(args) == 'table' and args or {})
            if not ok then
                print(('[%s] station %s/%s failed: %s'):format(PWP.RES, s.kind, action, tostring(result)))
                return false, 'Something went wrong'
            end
            if result == false then return false, reason end
            if result == nil then return true end
            return result
        end)
end)

AddEventHandler('playerDropped', function() Station.sessions[source] = nil end)

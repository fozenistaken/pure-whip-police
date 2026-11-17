local function deptList(dept)
    if dept == nil then return PWP.deptKeys() end
    if PWP.isDept(dept) then return { dept } end
    return nil
end

exports('IsOfficer', function(src, dept)
    local list = deptList(dept)
    if not list then return false, 'No such department' end
    for _, key in ipairs(list) do
        if Whip.core:GetPlayerRole(src, key) then return true, key end
    end
    return false
end)

exports('IsOnDuty', function(src, dept)
    local list = deptList(dept)
    if not list then return false, 'No such department' end
    for _, key in ipairs(list) do
        if Whip.core:IsPlayerClockedOn(src, key) then return true, key end
    end
    return false
end)

local function onDutyOfficers(dept)
    local list = deptList(dept)
    if not list then return false, 'No such department' end
    local out = {}
    for _, key in ipairs(list) do
        for _, e in ipairs(Whip.core:GetClockedOnEmployees(key) or {}) do
            if e.source then out[#out + 1] = { source = e.source, charId = e.charId, dept = key } end
        end
    end
    return out
end
PWP.onDutyOfficers = onDutyOfficers

exports('GetOnDutyOfficers', onDutyOfficers)

exports('GetOnDutyCount', function(dept)
    local list, why = onDutyOfficers(dept)
    if not list then return false, why end
    return #list
end)

Whip.sayStarted()

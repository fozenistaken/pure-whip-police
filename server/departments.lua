local PERMISSIONS = {
    cuff = 'Cuff and uncuff',
    search = 'Search people',
    jail = 'Send to prison',
    fine = 'Write fines from the penal code',
    fine_custom = 'Write fines of any amount',
    armory = 'Use the armory',
    fleet = 'Take fleet vehicles',
    records = 'Read and write records',
    warrants = 'Issue and close warrants',
    command = 'Command: licences, roster, department money',
    prison_staff = 'Run the prison',
    dispatch = 'Dispatch: alerts and units',
    impound_override = 'Lift an impound hold early',
}

local Depts = { permissions = PERMISSIONS }
PWP.Depts = Depts

function PWP.sourceOf(charId)
    charId = tonumber(charId)
    if not charId then return nil end
    for src, p in pairs(Whip.core:GetPlayers({ light = true }) or {}) do
        if p.charId == charId then return tonumber(src) end
    end
    return nil
end

function Depts.ofSource(src)
    for _, key in ipairs(PWP.deptKeys()) do
        if Whip.core:IsPlayerClockedOn(src, key) then return key end
    end
    return nil
end

function Depts.memberOf(src)
    for _, key in ipairs(PWP.deptKeys()) do
        if Whip.core:GetPlayerRole(src, key) then return key end
    end
    return nil
end

function Depts.can(src, permission)
    local dept = Depts.ofSource(src)
    if not dept then return false, 'You are not on duty' end
    local ok, why = Whip.core:HasJobPermission(src, dept, permission)
    if not ok then return false, why or 'Your rank cannot do that' end
    return true, dept
end

Whip.register(function()
    for _, key in ipairs(PWP.deptKeys()) do
        local d = PWP.dept(key)
        local job, why = Whip.core:EnsureJob(key, {
            name = d.label,
            icon = 'shield',
            selfClockOn = false,
            roles = Config.Ranks,
            permissions = PERMISSIONS,
        })
        if not job then print(('[%s] department %s: %s'):format(PWP.RES, key, tostring(why))) end
    end

    for i, s in ipairs(Config.Stations) do
        local d = PWP.dept(s.dept)
        local ok, why = Whip.core:ShowBlip('everyone', 'station_' .. i, {
            coords = s.coords, label = s.label, sprite = Config.StationSprite,
            color = d and d.color or 3, shortRange = true,
        })
        if not ok then print(('[%s] station %d blip: %s'):format(PWP.RES, i, tostring(why))) end
    end

    PWP.Points.build()
end)

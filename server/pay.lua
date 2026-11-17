local minutes = {}

local function payOne(src, dept, session)
    if not Whip.core:IsSessionCurrent(src, session) or not Whip.core:IsPlayerClockedOn(src, dept) then return end
    local role = Whip.core:GetPlayerRole(src, dept)
    local amount = PWP.Catalogue.rate(Config.Pay.rates, role and role.level or 0)
    if amount <= 0 then return end
    local paid, why = Whip.core:PayPlayer(src, amount, {
        method = 'bank', reason = ('Shift pay: %s'):format(PWP.dept(dept).short),
    })
    if not paid then print(('[%s] shift pay for %d failed: %s'):format(PWP.RES, src, tostring(why))) end
end

CreateThread(function()
    while true do
        Wait(60000)
        local every = math.max(1, math.floor(tonumber(Config.Pay.every) or 15))
        local seen = {}
        for _, o in ipairs(PWP.onDutyOfficers() or {}) do
            seen[o.source] = true
            minutes[o.source] = (minutes[o.source] or 0) + 1
            if minutes[o.source] >= every then
                minutes[o.source] = 0
                local player = Whip.core:GetPlayer(o.source)
                if player then CreateThread(function() payOne(o.source, o.dept, player.session) end) end
            end
        end
        for src in pairs(minutes) do
            if not seen[src] then minutes[src] = nil end
        end
    end
end)

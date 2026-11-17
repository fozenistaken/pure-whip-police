local Front = { desks = {} }
PWP.Front = Front

local function unpaidOf(charId)
    local list, total = PWP.Fines.list(charId, true), 0
    for _, f in ipairs(list) do total = total + f.amount end
    return #list, total
end

local function money(n)
    local s = tostring(math.floor(n))
    while true do
        local done
        s, done = s:gsub('^(%d+)(%d%d%d)', '%1,%2')
        if done == 0 then break end
    end
    return '$' .. s
end

local function opening(src, dept)
    local player = Whip.core:GetPlayer(src)
    if not player then return nil end
    local role = Whip.core:GetPlayerRole(src, dept)
    local answers, line = {}, nil
    if role then
        local on = Whip.core:IsPlayerClockedOn(src, dept) == true
        answers[#answers + 1] = on and { id = 'off', label = 'Clock out' } or { id = 'on', label = 'Clock in' }
        line = ('%s %s. %s'):format(role.name or 'Officer', player.lastName or '', on and 'Heading out?' or 'Clocking in?')
    else
        line = ('%s. How can I help?'):format(PWP.dept(dept).label)
    end
    local count, total = unpaidOf(player.charId)
    if count > 0 then
        line = line .. (' You have %d unpaid %s, %s in all.'):format(count, count == 1 and 'fine' or 'fines', money(total))
        answers[#answers + 1] = { id = 'pay', label = 'Pay them' }
    end
    answers[#answers + 1] = { id = 'bye', label = 'Leave', ends = true }
    return line, answers, player
end

local function reply(convId, line)
    Whip.core:UpdateConversation(convId, { line = line, options = { { id = 'bye', label = 'Thanks', ends = true } } })
end

local function choose(dept)
    return function(src, answer, convId)
        CreateThread(function()
            if answer == 'on' then
                local ok, why = PWP.Duty.on(src, dept)
                reply(convId, ok and 'You are on. Stay safe out there.' or tostring(why))
            elseif answer == 'off' then
                local ok, why = PWP.Duty.off(src, dept)
                reply(convId, ok and 'Signed out. Good shift.' or tostring(why))
            elseif answer == 'pay' then
                local player = Whip.core:GetPlayer(src)
                if not player then return end
                local paid, countOrWhy = PWP.Fines.payAll(src, player.session)
                reply(convId, paid and ('Paid %s. You are clear.'):format(money(paid)) or tostring(countOrWhy or 'That did not go through.'))
            end
        end)
    end
end

local function talk(row, desk)
    return function(source, use)
        local line, answers = opening(source, row.dept)
        if not line then return false, 'Not loaded' end
        local conv, why = Whip.core:StartConversation(source, {
            fromUse = use.useId, npcId = desk.npcId, speaker = row.label, line = line,
            options = answers, layout = 'stack', onChoose = choose(row.dept),
        })
        if not conv then return false, why end
        return true
    end
end

local function promptOnly(row)
    local dept = row.dept
    return Whip.core:AddPoint({
        at = { coords = row.coords }, label = row.label, icon = 'id', reach = Config.FrontDesk.reach,
        options = {
            { id = 'on', label = 'Clock in', require = { job = dept } },
            { id = 'off', label = 'Clock out', require = { job = dept, onDuty = true } },
            { id = 'pay', label = 'Pay my fines' },
        },
        onUse = function(source, use)
            CreateThread(function()
                local player = Whip.core:GetPlayer(source)
                if not player then return end
                if use.option == 'on' or use.option == 'off' then
                    local ok, why = (use.option == 'on' and PWP.Duty.on or PWP.Duty.off)(source, dept)
                    Whip.core:NotifyPlayer(source, ok and (use.option == 'on' and 'Clocked in' or 'Clocked out') or tostring(why), ok and 'success' or 'error')
                    return
                end
                local paid, countOrWhy = PWP.Fines.payAll(source, player.session)
                Whip.core:NotifyPlayer(source, paid and ('Paid %s'):format(money(paid)) or tostring(countOrWhy), paid and 'success' or 'error')
            end)
            return true
        end,
    })
end

local function clear(index)
    local desk = Front.desks[index]
    if not desk then return end
    if desk.pointId then Whip.core:RemovePoint(desk.pointId) end
    if desk.npcId then Whip.core:DespawnNpc(desk.npcId) end
    Front.desks[index] = nil
end

PWP.Points.kind('front', {
    build = function(row, index)
        clear(index)
        local desk = {}
        Front.desks[index] = desk
        if not row.clerk then
            local id, why = promptOnly(row)
            if not id then return false, why end
            desk.pointId = id
            return true
        end
        local npcId, netId = Whip.core:SpawnNpc({
            model = row.model or Config.FrontDesk.model,
            coords = row.clerk,
            conditions = { invincible = true, canMove = false },
            interior = row.interior ~= false,
        })
        if not npcId then return false, netId end
        desk.npcId = npcId
        if Config.FrontDesk.scenario then Whip.core:SetNpcState(npcId, { anim = { scenario = Config.FrontDesk.scenario } }) end
        local id, why = Whip.core:AddPoint({
            at = { netId = netId }, label = row.label, talk = true, reach = Config.FrontDesk.reach,
            onUse = talk(row, desk),
        })
        if not id then return false, why end
        desk.pointId = id
        return true
    end,
})

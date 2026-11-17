local Duty = {}
PWP.Duty = Duty

function Duty.on(src, dept)
    if not PWP.isDept(dept) then return false, 'No such department' end
    if not Whip.core:GetPlayerRole(src, dept) then return false, 'You do not work there' end
    return Whip.core:ClockOn(src, dept)
end

function Duty.off(src, dept)
    if dept and not PWP.isDept(dept) then return false, 'No such department' end
    return Whip.core:ClockOff(src, dept)
end

PWP.Points.kind('duty', {
    icon = 'id',
    options = {
        { id = 'on', label = 'Go on duty' },
        { id = 'off', label = 'Go off duty' },
    },
    onUse = function(source, dept, _, use)
        local short = PWP.dept(dept).short
        if use.option == 'on' then
            local ok, why = Duty.on(source, dept)
            if not ok then return false, why end
            Whip.core:NotifyPlayer(source, ('On duty: %s'):format(short), 'success')
        else
            local ok, why = Duty.off(source, dept)
            if not ok then return false, why end
            Whip.core:NotifyPlayer(source, ('Off duty: %s'):format(short), 'info')
        end
        return true
    end,
})

local function relay(onDuty)
    return function(e)
        if not PWP.isDept(e.key) then return end
        TriggerEvent(PWP.event('dutyChanged'), { source = e.source, charId = e.charId, dept = e.key, onDuty = onDuty })
    end
end
AddEventHandler('whip_core:job:clockedOn', relay(true))
AddEventHandler('whip_core:job:clockedOff', relay(false))

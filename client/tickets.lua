local APP = 'pwpticket'
local WHEEL = PWP.name('ticket_wheel')

local function nearby()
    local me = GetEntityCoords(PlayerPedId())
    local people, cars = {}, {}
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= PlayerPedId() and #(GetEntityCoords(ped) - me) <= Config.Tickets.personMetres + 1.0 then
            people[#people + 1] = GetPlayerServerId(pid)
        end
    end
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(veh) - me) <= Config.Tickets.vehicleMetres + 1.0 then
            local id = Whip.core:GetVehicleId(veh)
            if id then cars[#cars + 1] = id end
        end
    end
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(me.x, me.y, me.z))
    return { people = people, cars = cars, place = street ~= '' and street or nil }
end

RegisterCommand('ticket', function()
    CreateThread(function()
        local _, why = exports.whip_phone:RunApp(APP, nearby())
        if why and why ~= 'busy' then Whip.core:Notify('Ticket book: ' .. tostring(why), 'error') end
    end)
end, false)
RegisterKeyMapping('ticket', 'Police: write a ticket', 'keyboard', '')

RegisterNetEvent(PWP.event('ticketSign'), function(t)
    if type(t) ~= 'table' or not t.id then return end
    CreateThread(function()
        local text = ('%s %s, $%d for %s. Officer: %s. Pay by %s. Signing accepts it; refuse and you may contest it in the Courts app.')
            :format(t.label or 'Ticket', t.number or '', t.amount or 0, t.charges or '', t.officer or 'police', t.dueAt and os.date('%d %b', t.dueAt) or '-')
        local yes = Whip.core:Confirm('Sign the ticket?', text, 'Sign', 'Refuse')
        TriggerServerEvent(PWP.event('ticketSigned'), t.id, yes == true)
    end)
end)

Whip.register(function()
    Whip.core:AddAction({
        id = WHEEL, at = { radial = true }, label = 'Ticket book', icon = 'objective',
        require = { job = PWP.deptKeys(), onDuty = true },
        onSelect = function() ExecuteCommand('ticket') end,
    })
end)

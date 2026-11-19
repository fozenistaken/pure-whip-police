local APP = 'pwpticket'
local WHEEL = PWP.name('ticket_wheel')
local RADAR_KEEP_MS = 600000

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
    local lock = PWP.RadarLock
    local radar = lock and GetGameTimer() - lock.at <= RADAR_KEEP_MS and { plate = lock.plate, speed = lock.speed, unit = lock.unit } or nil
    return { people = people, cars = cars, place = street ~= '' and street or nil, radar = radar }
end

local function writeAndHand(target)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
    Wait(Config.Tickets.writeSeconds * 1000)
    ClearPedTasks(ped)
    local other = target and GetPlayerFromServerId(target)
    local tped = other and other ~= -1 and GetPlayerPed(other)
    if not tped or tped == 0 then return end
    TaskTurnPedToFaceEntity(ped, tped, 800)
    Wait(800)
    if Whip.core:LoadAnimDict('mp_common') then
        TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 48, 0.0, false, false, false)
    end
end

RegisterCommand('ticket', function()
    CreateThread(function()
        local result, why = exports.whip_phone:RunApp(APP, nearby())
        if why and why ~= 'busy' then return Whip.core:Notify('Ticket book: ' .. tostring(why), 'error') end
        if type(result) == 'table' and result.number and Config.Tickets.writeSeconds > 0 then writeAndHand(result.target) end
    end)
end, false)
RegisterKeyMapping('ticket', 'Police: write a ticket', 'keyboard', '')

RegisterNetEvent(PWP.event('ticketSign'), function(t)
    if type(t) ~= 'table' or not t.id then return end
    CreateThread(function()
        if Config.Tickets.writeSeconds > 0 then
            Wait(Config.Tickets.writeSeconds * 1000 + 800)
            if Whip.core:LoadAnimDict('mp_common') then
                TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake1_b', 8.0, -8.0, 2000, 48, 0.0, false, false, false)
            end
        end
        local text = ('%s %s, $%d for %s. Officer: %s. Pay by %s. Signing accepts it; refuse and you may contest it in the Courts app.')
            :format(t.label or 'Ticket', t.number or '', t.amount or 0, t.charges or '', t.officer or 'police', t.due or '-')
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

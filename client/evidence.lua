local C = Config.Evidence
local BAGS, CLOTH = PWP.name('evidence_bags'), PWP.name('cloth')
local HIT_GAP_MS = 300
local drawn = false
local hurtAt = 0

local function watchHits()
    local last, sentAt = nil, 0
    while drawn do
        local hit, c = GetPedLastWeaponImpactCoord(PlayerPedId())
        local now = GetGameTimer()
        if hit and (not last or #(c - last) > 0.5) and now - sentAt >= HIT_GAP_MS then
            last, sentAt = c, now
            TriggerServerEvent(PWP.event('hit'), c.x, c.y, c.z)
        end
        Wait(100)
    end
end

AddEventHandler('whip_gunny:weapon:drawn', function()
    if drawn or not C.enabled then return end
    drawn = true
    watchHits()
end)

AddEventHandler('whip_gunny:weapon:holstered', function() drawn = false end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' or not C.enabled then return end
    local ped = PlayerPedId()
    if args[1] ~= ped or IsEntityDead(ped) then return end
    local now = GetGameTimer()
    if now - hurtAt < (C.hurtSeconds + 1) * 1000 then return end
    if GetEntityHealth(ped) >= GetEntityMaxHealth(ped) then return end
    hurtAt = now
    TriggerServerEvent(PWP.event('hurt'))
end)

Whip.register(function()
    if not C.enabled then return end
    Whip.core:AddAction({
        id = PWP.name('cardoor'),
        at = { vehiclePart = 'door_dside_f' },
        label = 'Prints',
        options = {
            { id = 'dust', label = 'Dust for prints', require = { job = PWP.deptKeys(), onDuty = true, item = BAGS } },
            { id = 'wipe', label = 'Wipe down', require = { item = CLOTH } },
        },
        onSelect = function(ctx)
            local id = ctx.entity and Whip.core:GetVehicleId(ctx.entity)
            if not id then return Whip.core:Notify('No prints on this car', 'error') end
            TriggerServerEvent(PWP.event('door'), id, ctx.option)
        end,
    })
end)

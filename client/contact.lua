local ACTION = PWP.name('contact')
local BLOCK = PWP.name('cuffed')
local cuffedKind = false
local animThread = 0

local function isPoliceKey(key)
    return PWP.isDept(key)
end

local function addAction()
    Whip.core:AddAction({
        id = ACTION,
        at = { aimBox = 'ped' },
        label = 'Police',
        reach = Config.Contact.reach,
        require = { job = PWP.deptKeys(), onDuty = true },
        canInteract = function(ctx) return ctx.player ~= nil end,
        options = {
            { id = 'cuff', label = 'Cuff', options = {
                { id = 'soft', label = 'Cuff in front' },
                { id = 'hard', label = 'Cuff behind' },
                { id = 'zip', label = 'Zip ties' },
            } },
            { id = 'uncuff', label = 'Uncuff' },
            { id = 'search', label = 'Search' },
        },
        onSelect = function(ctx)
            local target = ctx.player and ctx.player.serverId
            if not target then return end
            if ctx.option == 'uncuff' then
                TriggerServerEvent(PWP.event('uncuff'), target)
            elseif ctx.option == 'search' then
                TriggerServerEvent(PWP.event('search'), target)
            else
                TriggerServerEvent(PWP.event('cuff'), target, ctx.option)
            end
        end,
    })
end

local function refresh()
    local job = LocalPlayer.state.whipJob
    Whip.core:RemoveAction(ACTION)
    if job and isPoliceKey(job) then addAction() end
end

AddEventHandler('whip_core:job:clockedOn', refresh)
AddEventHandler('whip_core:job:clockedOff', refresh)
AddEventHandler('whip_core:player:loaded', refresh)
CreateThread(refresh)

local function loadDict(dict)
    RequestAnimDict(dict)
    local tries = 0
    while not HasAnimDictLoaded(dict) and tries < 100 do Wait(10); tries = tries + 1 end
    return HasAnimDictLoaded(dict)
end

local function holdAnim(token)
    if not loadDict('mp_arresting') then return end
    while animThread == token and cuffedKind do
        local ped = PlayerPedId()
        if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) and not IsPedInAnyVehicle(ped, false) then
            TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false)
        end
        Wait(500)
    end
    ClearPedSecondaryTask(PlayerPedId())
end

RegisterNetEvent(PWP.event('cuffState'), function(kind)
    cuffedKind = kind
    animThread = animThread + 1
    if not kind then
        Whip.core:UnblockControls(BLOCK)
        ClearPedSecondaryTask(PlayerPedId())
        return
    end
    local spec = { groups = { 'combat', 'vehicleCombat' }, mode = true }
    if kind == 'hard' then
        spec.groups = { 'combat', 'vehicleCombat', 'move' }
    else
        spec.walk = true
        spec.controls = { 22 }
    end
    Whip.core:BlockControls(BLOCK, spec)
    local token = animThread
    CreateThread(function() holdAnim(token) end)
end)

RegisterNetEvent(PWP.event('playCuff'), function()
    if not loadDict('mp_arresting') then return end
    TaskPlayAnim(PlayerPedId(), 'mp_arresting', 'a_uncuff', 8.0, -8.0, 3000, 49, 0.0, false, false, false)
end)

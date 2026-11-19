local APP = 'pwptow'
local ACTION = PWP.name('tow')
local registered = false

local function isDriver()
    if type(Config.Tow.job) ~= 'string' then return false end
    for _, job in pairs(Whip.core:GetPlayerJobs() or {}) do
        if job.key == Config.Tow.job then return true end
    end
    return false
end

local function sync()
    local want = isDriver() and GetResourceState('whip_phone') == 'started'
    if want and not registered then
        local ok, why = exports.whip_phone:RegisterModule({ id = APP, script = 'html/mdt/tow.js', ns = PWP.RES .. ':tow' })
        registered = ok == true
        if not ok then print('[pure-whip-police] Tow app: ' .. tostring(why)) end
    elseif not want and registered then
        exports.whip_phone:UnregisterModule(APP)
        registered = false
    end
end

AddEventHandler('whip_core:job:clockedOn', sync)
AddEventHandler('whip_core:job:clockedOff', sync)
AddEventHandler('whip_core:player:loaded', sync)
AddEventHandler('whip_core:job:listChanged', sync)
AddEventHandler('onClientResourceStart', function(res) if res == 'whip_phone' then registered = false; sync() end end)
AddEventHandler('onClientResourceStop', function(res) if res == 'whip_phone' then registered = false end end)
CreateThread(sync)

Whip.register(function()
    if type(Config.Tow.job) ~= 'string' then return end
    Whip.core:AddAction({
        id = ACTION,
        at = { vehiclePart = 'door_dside_f' },
        label = 'Tow',
        options = { { id = 'tow', label = 'Tow to the impound lot', require = { job = Config.Tow.job, onDuty = true } } },
        canInteract = function(ctx) return ctx.entity and Entity(ctx.entity).state.pwpTow == true end,
        onSelect = function(ctx)
            local id = ctx.entity and Whip.core:GetVehicleId(ctx.entity)
            if id then TriggerServerEvent(PWP.event('policecar'), id, 'tow') end
        end,
    })
end)

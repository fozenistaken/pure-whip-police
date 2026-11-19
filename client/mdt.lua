local APP = 'pwpmdt'
local WHEEL = PWP.name('mdt_wheel')
local registered = false

local function isMember()
    for _, job in pairs(Whip.core:GetPlayerJobs() or {}) do
        if PWP.isDept(job.key) then return true end
    end
    return false
end

local function sync()
    local want = Config.Providers.mdt == 'builtin' and isMember() and GetResourceState('whip_phone') == 'started'
    if want and not registered then
        local ok, why = exports.whip_phone:RegisterModule({ id = APP, script = 'html/mdt/module.js', ns = PWP.RES .. ':mdt' })
        registered = ok == true
        if not ok then print('[pure-whip-police] MDT app: ' .. tostring(why)) end
        local tok, twhy = exports.whip_phone:RegisterModule({ id = 'pwpticket', script = 'html/mdt/ticket.js', ns = PWP.RES .. ':ticket' })
        if not tok then print('[pure-whip-police] Ticket book: ' .. tostring(twhy)) end
    elseif not want and registered then
        exports.whip_phone:UnregisterModule(APP)
        exports.whip_phone:UnregisterModule('pwpticket')
        registered = false
    end
    Whip.core:RemoveAction(WHEEL)
    if want then
        Whip.core:AddAction({
            id = WHEEL, at = { radial = true }, label = 'MDT', icon = 'id',
            require = { job = PWP.deptKeys(), onDuty = true },
            onSelect = function() ExecuteCommand('mdt') end,
        })
    end
end

RegisterCommand('mdt', function()
    if not registered then return Whip.core:Notify('The MDT is for police officers', 'error') end
    CreateThread(function()
        local _, why = exports.whip_phone:RunApp(APP, {})
        if why and why ~= 'busy' then Whip.core:Notify('MDT: ' .. tostring(why), 'error') end
    end)
end, false)
RegisterKeyMapping('mdt', 'Police: open the MDT', 'keyboard', '')

AddEventHandler('whip_core:job:clockedOn', sync)
AddEventHandler('whip_core:job:clockedOff', sync)
AddEventHandler('whip_core:player:loaded', sync)
AddEventHandler('whip_core:job:listChanged', sync)
AddEventHandler('onClientResourceStart', function(res) if res == 'whip_phone' then registered = false; sync() end end)
AddEventHandler('onClientResourceStop', function(res) if res == 'whip_phone' then registered = false end end)
CreateThread(sync)

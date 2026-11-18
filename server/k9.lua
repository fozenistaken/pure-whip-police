local K9 = { down = {} }
PWP.K9 = K9

local function handler(src)
    local dept = PWP.Depts.ofSource(src)
    if not dept then return false, 'Go on duty first' end
    if not PWP.Licences.has(Whip.core:GetCharId(src), dept, 'k9') then return false, 'You need the K9 handler licence' end
    if K9.down[src] and K9.down[src] > os.time() then
        return false, ('Your dog is resting for %d more min'):format(math.ceil((K9.down[src] - os.time()) / 60))
    end
    return true, dept
end

local function smells(item)
    for _, pattern in ipairs(Config.K9.smells) do
        if item:find(pattern) then return true end
    end
    return false
end

local function anyIn(addr)
    local store = Whip.core:StoreRead(addr)
    for _, it in pairs(store and store.items or {}) do
        if type(it) == 'table' and it.item and smells(it.item) then return true end
    end
    return false
end

local function sniffPerson(target)
    for _, sub in ipairs({ 'player', 'accessory' }) do
        if anyIn({ kind = 'player', id = target, sub = sub }) then return 'pockets' end
    end
    return nil
end

local function sniffCar(vehicleId)
    for _, sub in ipairs({ 'trunk', 'glovebox' }) do
        if anyIn({ kind = 'vehicle', id = vehicleId, sub = sub }) then return sub == 'trunk' and 'boot' or 'glovebox' end
    end
    return nil
end

Whip.register(function()
    Whip.core:SecureCallback(PWP.event('k9'), { rateLimit = 2000 }, function(source)
        return handler(source)
    end)

    Whip.core:SecureCallback(PWP.event('k9person'), {
        rateLimit = 6000, params = { { 'target', 'player', { range = 8.0 } } },
    }, function(source, _, target)
        local ok, why = handler(source)
        if not ok then return false, why end
        local where = sniffPerson(target)
        Whip.core:LogActivity(source, 'k9_search', { detail = where and 'alert on a person' or 'no alert' })
        return { hit = where ~= nil, where = where }
    end)

    Whip.core:SecureCallback(PWP.event('k9car'), {
        rateLimit = 6000, params = { { 'veh', 'vehicle', { anyOwner = true, session = true } } },
        near = { at = 'vehicle', range = 10.0 },
    }, function(source, _, veh)
        local ok, why = handler(source)
        if not ok then return false, why end
        local where = sniffCar(veh.id or veh.vehicleId)
        Whip.core:LogActivity(source, 'k9_search', { detail = where and ('alert on ' .. (veh.plate or 'a car')) or 'no alert' })
        return { hit = where ~= nil, where = where }
    end)

    Whip.core:SecureCallback(PWP.event('k9attack'), {
        rateLimit = 5000, params = { { 'target', 'player', { range = 40.0, notSelf = true } } },
    }, function(source, _, target)
        local ok, why = handler(source)
        if not ok then return false, why end
        Whip.core:LogActivity(source, 'k9_attack', { detail = ('sent the dog at %d'):format(target) })
        PWP.Feeds.log('unit:' .. Whip.core:GetCharId(source), 'k9', 'Sent the K9 after someone', GetEntityCoords(GetPlayerPed(source)))
        return true
    end)

    Whip.core:SecureEvent(PWP.event('k9down'), { rateLimit = 5000 }, function(source)
        K9.down[source] = os.time() + Config.K9.cooldownMinutes * 60
    end)
end)

AddEventHandler('playerDropped', function() K9.down[source] = nil end)

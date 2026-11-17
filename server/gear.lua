local HIDDEN = vector3(-1.0, -1.0, -60.0)
local Gear = { lockers = {}, fleet = {} }
PWP.Gear = Gear

local function level(src, dept)
    local role = Whip.core:GetPlayerRole(src, dept)
    return role and role.level or 0
end

local function onDutyAt(src, dept)
    if not Whip.core:IsPlayerClockedOn(src, dept) then return false, 'Go on duty first' end
    return true
end

local function check(src, dept, entry, permission)
    local ok, why = onDutyAt(src, dept)
    if not ok then return false, why end
    if permission then
        local can, reason = Whip.core:HasJobPermission(src, dept, permission)
        if not can then return false, reason or 'Your rank cannot do that' end
    end
    local copy = { minLevel = entry.minLevel, licence = entry.licence,
        licenceLabel = entry.licence and Config.Licences[entry.licence] }
    return PWP.Catalogue.allowed(copy, level(src, dept), PWP.Licences.forSource(src, dept))
end

local function background(fn)
    CreateThread(fn)
    return true
end

local function lockerOf(charId)
    if Gear.lockers[charId] then return Gear.lockers[charId] end
    local def, why = Whip.core:EnsureContainer(('%s:locker:%d'):format(PWP.RES, charId), {
        name = 'Locker', slots = Config.Locker.slots, maxWeight = Config.Locker.weight,
        x = HIDDEN.x, y = HIDDEN.y, z = HIDDEN.z,
        requirements = { charIds = { charId } },
    })
    if not def then return false, why end
    Gear.lockers[charId] = def.containerId
    return def.containerId
end

PWP.Points.kind('locker', {
    icon = 'bag',
    onUse = function(source, dept)
        return background(function()
            local charId = Whip.core:GetCharId(source)
            local id, why = lockerOf(charId)
            if not id then return Whip.core:NotifyPlayer(source, why or 'Your locker could not be opened', 'error') end
            local ok, reason = Whip.core:OpenStore(source, { kind = 'container', id = id },
                { skipDistance = true, skipAccess = true })
            if not ok then Whip.core:NotifyPlayer(source, reason, 'error') end
        end)
    end,
})

PWP.Points.kind('stash', {
    build = function(row, index)
        local def, why = Whip.core:EnsureContainer(('%s:stash:%d'):format(PWP.RES, index), {
            name = row.label, slots = Config.Stash.slots, maxWeight = Config.Stash.weight,
            x = row.coords.x, y = row.coords.y, z = row.coords.z,
            requirements = { jobs = row.dept, onDuty = true },
        })
        if not def then return false, why end
        return true
    end,
})

local function armoryKey(dept, tier)
    return ('%s_armory_%s_%s'):format(PWP.RES, dept, tier.id)
end

local function ensureArmory(dept, tier, at)
    local key = armoryKey(dept, tier)
    local shop, why = Whip.core:EnsureShop(key, {
        name = ('%s %s'):format(PWP.dept(dept).short, tier.label), mode = 'npc',
        x = at.x, y = at.y, z = at.z, catalog = tier.catalog,
    })
    if not shop then return false, why end
    if not (shop.settings and shop.settings.virtual) then
        local s = {}
        for k, v in pairs(shop.settings or {}) do s[k] = v end
        s.virtual = true
        local ok, err = Whip.core:UpdateShop(shop.shopId, { settings = s })
        if not ok then return false, err end
    end
    return true
end

local function armoryOptions()
    local options = {}
    for i, tier in ipairs(Config.Armory) do
        if i > 6 then break end
        options[#options + 1] = { id = tier.id, label = tier.label }
    end
    return options
end

PWP.Points.kind('armory', {
    icon = 'store',
    require = { onDuty = true, jobPermission = 'armory' },
    options = armoryOptions(),
    onUse = function(source, dept, _, use)
        local tier
        for _, t in ipairs(Config.Armory) do if t.id == use.option then tier = t end end
        if not tier then return false, 'Not available' end
        local ok, why = check(source, dept, tier, 'armory')
        if not ok then return false, why end
        return background(function()
            local opened, reason = Whip.core:OpenShop(source, { key = armoryKey(dept, tier) }, {
                range = 3,
                authorize = function(src) return Whip.core:IsPlayerClockedOn(src, dept) == true end,
            })
            if not opened then Whip.core:NotifyPlayer(source, reason, 'error') end
        end)
    end,
})

local function uniformOptions(dept)
    local options = {}
    for i, u in ipairs(Config.Uniforms[dept] or {}) do
        if i > 5 then break end
        options[#options + 1] = { id = 'u' .. i, label = u.label }
    end
    options[#options + 1] = { id = 'own', label = 'Own clothes' }
    return options
end

PWP.Points.kind('wardrobe', {
    icon = 'theme',
    require = { onDuty = true },
    options = function(dept) return uniformOptions(dept) end,
    onUse = function(source, dept, _, use)
        if use.option == 'own' then
            TriggerClientEvent(PWP.event('uniform'), source, nil)
            return true
        end
        local index = tonumber(use.option:match('^u(%d+)$'))
        local uniform = index and (Config.Uniforms[dept] or {})[index]
        if not uniform then return false, 'Not available' end
        local ok, why = check(source, dept, uniform)
        if not ok then return false, why end
        TriggerClientEvent(PWP.event('uniform'), source, dept, index)
        return true
    end,
})

local function fleetOptions(dept)
    local options = {}
    for i, car in ipairs(Config.Fleet[dept] or {}) do
        if i > 5 then break end
        options[#options + 1] = { id = 'c' .. i, label = car.label }
    end
    options[#options + 1] = { id = 'return', label = 'Return your car' }
    return options
end

local function removeFleetCar(src)
    local id = Gear.fleet[src]
    Gear.fleet[src] = nil
    if id then Whip.core:DeleteVehicle(id) end
end

PWP.Points.kind('garage', {
    icon = 'garage',
    require = { onDuty = true, jobPermission = 'fleet' },
    options = function(dept) return fleetOptions(dept) end,
    onUse = function(source, dept, row, use)
        if use.option == 'return' then
            if not Gear.fleet[source] then return false, 'You have no fleet car out' end
            removeFleetCar(source)
            Whip.core:NotifyPlayer(source, 'Car returned', 'success')
            return true
        end
        local index = tonumber(use.option:match('^c(%d+)$'))
        local car = index and (Config.Fleet[dept] or {})[index]
        if not car then return false, 'Not available' end
        local ok, why = check(source, dept, car, 'fleet')
        if not ok then return false, why end
        if Gear.fleet[source] then return false, 'Return your other car first' end
        return background(function()
            local spot = row.spawn or vector4(row.coords.x, row.coords.y, row.coords.z, 0.0)
            local id, err = Whip.core:SpawnTempVehicle(car.model, spot, { forSource = source, secure = true })
            if not id then return Whip.core:NotifyPlayer(source, err, 'error') end
            Gear.fleet[source] = id
            Whip.core:LogActivity(source, 'fleet_out', { detail = ('%s %s'):format(dept, car.model) })
        end)
    end,
})

AddEventHandler('playerDropped', function() removeFleetCar(source) end)

Whip.register(function()
    for _, dept in ipairs(PWP.deptKeys()) do
        local at = nil
        for _, row in ipairs(Config.Points) do
            if row.dept == dept and row.kind == 'armory' then at = row.coords break end
        end
        at = at or (Config.Stations[1] and Config.Stations[1].coords) or vector3(0.0, 0.0, 0.0)
        for _, tier in ipairs(Config.Armory) do
            local ok, why = ensureArmory(dept, tier, at)
            if not ok then print(('[%s] armory %s/%s: %s'):format(PWP.RES, dept, tier.id, tostring(why))) end
        end
    end
end)

AddEventHandler(PWP.event('dutyChanged'), function(e)
    if not e.onDuty and e.source then TriggerClientEvent(PWP.event('uniform'), e.source, nil) end
end)

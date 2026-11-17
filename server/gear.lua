local HIDDEN = vector3(-1.0, -1.0, -60.0)
local Gear = { lockers = {}, stashes = {}, fleet = {} }
PWP.Gear = Gear
local Station = PWP.Station

local function level(src, dept)
    local role = Whip.core:GetPlayerRole(src, dept)
    return role and role.level or 0
end

local function onDutyAt(src, dept)
    if not Whip.core:IsPlayerClockedOn(src, dept) then return false, 'Go on duty first' end
    return true
end

local function allowed(src, dept, entry)
    local copy = { minLevel = entry.minLevel, licence = entry.licence,
        licenceLabel = entry.licence and Config.Licences[entry.licence] }
    return PWP.Catalogue.allowed(copy, level(src, dept), PWP.Licences.forSource(src, dept))
end

local function check(src, dept, entry, permission)
    local ok, why = onDutyAt(src, dept)
    if not ok then return false, why end
    if permission then
        local can, reason = Whip.core:HasJobPermission(src, dept, permission)
        if not can then return false, reason or 'Your rank cannot do that' end
    end
    return allowed(src, dept, entry)
end

local function lockText(src, dept, entry)
    local ok, why = allowed(src, dept, entry)
    if ok then return nil end
    return why
end

-- storage: a personal locker or a station stash, shown beside the pockets

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

local function slotsOf(contents)
    local list = {}
    for slot, it in pairs(contents.items or {}) do
        list[#list + 1] = { slot = tonumber(slot), item = it.item, amount = it.amount }
    end
    return { slots = contents.slots, weight = contents.weight, maxWeight = contents.maxWeight ~= math.huge and contents.maxWeight or nil, items = list }
end

local function bothSides(src, session)
    local pockets, why = Whip.core:StoreRead({ kind = 'player', id = src, sub = 'player' })
    if not pockets then return false, why end
    local store, err = Whip.core:StoreRead(session.addr)
    if not store then return false, err end
    return { pockets = slotsOf(pockets), store = slotsOf(store) }
end

local storage = {
    build = function(src, session) return bothSides(src, session) end,
    actions = {
        move = function(src, session, a)
            local slot = tonumber(a.slot)
            if not slot or slot < 1 or slot % 1 ~= 0 then return false, 'Pick an item' end
            local pockets = { kind = 'player', id = src, sub = 'player' }
            local from, to
            if a.from == 'pockets' then from, to = pockets, session.addr else from, to = session.addr, pockets end
            from = { kind = from.kind, id = from.id, sub = from.sub, slot = slot }
            local ok, why = Whip.core:StoreMove(from, to, a.one and { amount = 1 } or nil)
            if not ok then return false, why end
            return bothSides(src, session)
        end,
    },
}

Station.kind('locker', {
    build = function(src, session)
        local id, why = lockerOf(Whip.core:GetCharId(src))
        if not id then return false, why or 'Your locker could not be opened' end
        session.addr = { kind = 'container', id = id }
        local data, err = storage.build(src, session)
        if data then data.storeLabel = 'Locker' end
        return data, err
    end,
    actions = storage.actions,
})

Station.kind('stash', {
    build = function(src, session)
        local ok, why = onDutyAt(src, session.dept)
        if not ok then return false, why end
        local id = Gear.stashes[session.row]
        if not id then return false, 'The stash is not ready' end
        session.addr = { kind = 'container', id = id }
        local data, err = storage.build(src, session)
        if data then data.storeLabel = session.row.label end
        return data, err
    end,
    actions = storage.actions,
})

PWP.Points.kind('locker', {
    icon = 'bag',
    onUse = function(source, dept, row) return Station.open(source, 'locker', dept, row) end,
})

PWP.Points.kind('stash', {
    icon = 'box',
    require = { onDuty = true },
    onUse = function(source, dept, row) return Station.open(source, 'stash', dept, row) end,
})

-- armory: sign out kit from the tiers your rank and licences open

local function tierItems(tier)
    local list = {}
    for key, price in pairs(tier.catalog or {}) do list[#list + 1] = { key = key, price = price } end
    table.sort(list, function(a, b) return a.key < b.key end)
    return list
end

Station.kind('armory', {
    build = function(src, session)
        local ok, why = check(src, session.dept, { minLevel = 1 }, 'armory')
        if not ok then return false, why end
        local tiers = {}
        for _, tier in ipairs(Config.Armory) do
            tiers[#tiers + 1] = { id = tier.id, label = tier.label, locked = lockText(src, session.dept, tier), items = tierItems(tier) }
        end
        return { tiers = tiers, maxEach = Config.ArmoryMaxEach }
    end,
    actions = {
        take = function(src, session, a)
            local tier
            for _, t in ipairs(Config.Armory) do if t.id == a.tier then tier = t end end
            if not tier then return false, 'Not available' end
            local ok, why = check(src, session.dept, tier, 'armory')
            if not ok then return false, why end
            local want, total = {}, 0
            for key, n in pairs(type(a.items) == 'table' and a.items or {}) do
                local count = math.floor(tonumber(n) or 0)
                local price = tier.catalog[key]
                if count > 0 then
                    if not price then return false, 'That is not in this armory' end
                    if count > Config.ArmoryMaxEach then return false, ('At most %d of each'):format(Config.ArmoryMaxEach) end
                    want[#want + 1] = { key = key, count = count }
                    total = total + price * count
                end
            end
            if #want == 0 then return false, 'Pick something first' end
            for _, w in ipairs(want) do
                local fits, reason = Whip.core:CanFitItem(src, w.key, w.count)
                if not fits then return false, reason or 'No room' end
            end
            local receipt
            if total > 0 then
                local paid, err = Whip.core:ChargePlayer(src, total, { reason = 'Armory' })
                if not paid then return false, err end
                receipt = paid
            end
            local given = {}
            for _, w in ipairs(want) do
                local where, err = Whip.core:AddItem(src, w.key, w.count, nil, { reason = 'Police armory', noDrop = true })
                if not where then
                    for _, g in ipairs(given) do Whip.core:RemoveItem(src, g.key, g.count, nil, { reason = 'Armory undone' }) end
                    if receipt then Whip.core:RefundPlayer(receipt) end
                    return false, err or 'No room'
                end
                given[#given + 1] = w
            end
            Whip.core:LogActivity(src, 'armory', { detail = ('%s %s: %d kinds'):format(session.dept, tier.id, #given) })
            return { taken = #given }
        end,
    },
})

PWP.Points.kind('armory', {
    icon = 'store',
    require = { onDuty = true, jobPermission = 'armory' },
    onUse = function(source, dept, row) return Station.open(source, 'armory', dept, row) end,
})

-- wardrobe: duty uniforms, worn until you change or go off duty

Station.kind('wardrobe', {
    build = function(src, session)
        local ok, why = onDutyAt(src, session.dept)
        if not ok then return false, why end
        local list = {}
        for i, u in ipairs(Config.Uniforms[session.dept] or {}) do
            list[#list + 1] = { i = i, label = u.label, locked = lockText(src, session.dept, u) }
        end
        return { uniforms = list }
    end,
    actions = {
        wear = function(src, session, a)
            if a.i == 'own' then
                TriggerClientEvent(PWP.event('uniform'), src, nil)
                return true
            end
            local index = tonumber(a.i)
            local uniform = index and (Config.Uniforms[session.dept] or {})[index]
            if not uniform then return false, 'Not available' end
            local ok, why = check(src, session.dept, uniform)
            if not ok then return false, why end
            TriggerClientEvent(PWP.event('uniform'), src, session.dept, index)
            return true
        end,
    },
})

PWP.Points.kind('wardrobe', {
    icon = 'theme',
    require = { onDuty = true },
    onUse = function(source, dept, row) return Station.open(source, 'wardrobe', dept, row) end,
})

-- fleet: one car per officer, taken here and returned here

local function removeFleetCar(src)
    local out = Gear.fleet[src]
    Gear.fleet[src] = nil
    if out then Whip.core:DeleteVehicle(out.id) end
end

local function fleetState(src, dept)
    local list = {}
    for i, car in ipairs(Config.Fleet[dept] or {}) do
        list[#list + 1] = { i = i, label = car.label, model = car.model, locked = lockText(src, dept, car) }
    end
    local out = Gear.fleet[src]
    return { cars = list, out = out and { label = out.label, model = out.model } or false }
end

Station.kind('garage', {
    build = function(src, session)
        local ok, why = check(src, session.dept, { minLevel = 1 }, 'fleet')
        if not ok then return false, why end
        return fleetState(src, session.dept)
    end,
    actions = {
        take = function(src, session, a)
            local index = tonumber(a.i)
            local car = index and (Config.Fleet[session.dept] or {})[index]
            if not car then return false, 'Not available' end
            local ok, why = check(src, session.dept, car, 'fleet')
            if not ok then return false, why end
            if Gear.fleet[src] then return false, 'Return your other car first' end
            local row = session.row
            local spot = row.spawn or vector4(row.coords.x, row.coords.y, row.coords.z, 0.0)
            local id, err = Whip.core:SpawnTempVehicle(car.model, spot, { forSource = src, secure = true })
            if not id then return false, err end
            Gear.fleet[src] = { id = id, label = car.label, model = car.model }
            Whip.core:LogActivity(src, 'fleet_out', { detail = ('%s %s'):format(session.dept, car.model) })
            return fleetState(src, session.dept)
        end,
        ['return'] = function(src, session)
            if not Gear.fleet[src] then return false, 'You have no fleet car out' end
            removeFleetCar(src)
            return fleetState(src, session.dept)
        end,
    },
})

PWP.Points.kind('garage', {
    icon = 'garage',
    require = { onDuty = true, jobPermission = 'fleet' },
    onUse = function(source, dept, row) return Station.open(source, 'garage', dept, row) end,
})

AddEventHandler('playerDropped', function() removeFleetCar(source) end)

Whip.register(function()
    for index, row in ipairs(Config.Points) do
        if row.kind == 'stash' and PWP.isDept(row.dept) then
            local def, why = Whip.core:EnsureContainer(('%s:stash:%d'):format(PWP.RES, index), {
                name = row.label, slots = Config.Stash.slots, maxWeight = Config.Stash.weight,
                x = HIDDEN.x, y = HIDDEN.y, z = HIDDEN.z,
                requirements = { jobs = row.dept, onDuty = true },
            })
            if def then Gear.stashes[row] = def.containerId
            else print(('[%s] stash %d: %s'):format(PWP.RES, index, tostring(why))) end
        end
    end
    for _, dept in ipairs(PWP.deptKeys()) do
        for _, tier in ipairs(Config.Armory) do
            local shop = Whip.core:GetShop({ key = ('%s_armory_%s_%s'):format(PWP.RES, dept, tier.id) })
            if shop then Whip.core:DeleteShop(shop.shopId) end
        end
    end
end)

AddEventHandler(PWP.event('dutyChanged'), function(e)
    if not e.onDuty and e.source then TriggerClientEvent(PWP.event('uniform'), e.source, nil) end
end)

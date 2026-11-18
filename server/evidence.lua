local Ev = PWP.Evidence
local Gear, Station = PWP.Gear, PWP.Station
local C = Config.Evidence

local ITEM = {
    casing = PWP.name('casing'), bag = PWP.name('evidence'), bags = PWP.name('evidence_bags'),
    cloth = PWP.name('cloth'),
}
local T = { evidence = 'pure_whip_police_evidence', samples = 'pure_whip_police_samples' }
local PRINTS_KEY = 'pwp_prints'
local FLUSH_MS = 2500
local FIRE_KEEP_MS = 3000

local S = { marks = {}, casings = {}, bursts = {}, lastFire = {}, drawn = {}, lockers = {}, salt = nil }

local function charOf(src) return Whip.core:GetCharId(src) end

local function salt()
    if S.salt then return S.salt end
    local saved = GetResourceKvpString('evidence_salt')
    if not saved or saved == '' then
        saved = ('%08x%08x'):format(math.random(0, 0x7FFFFFFF), math.random(0, 0x7FFFFFFF))
        SetResourceKvp('evidence_salt', saved)
    end
    S.salt = saved
    return saved
end

local function dnaOf(charId) return Ev.code('DNA', charId, salt()) end
local function printOf(charId) return Ev.code('FP', charId, salt()) end

local function v3(c) return vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0) end

local function gunName(item)
    local def = item and Whip.core:GetItemDef(item)
    return def and def.name or item
end

local function isGun(meta)
    return type(meta) == 'table' and meta.serial ~= nil and type(meta.attachments) == 'table'
end

local function emit(name, data) TriggerEvent(PWP.event(name), data) end

local function newBag(src, data)
    local meta = data
    meta.baggedBy, meta.baggedAt = charOf(src), os.time()
    local where, why = Whip.core:AddItem(src, ITEM.bag, 1, meta, { reason = 'evidence bagged' })
    if not where then return false, why end
    emit('evidenceCollected', { source = src, kind = meta.kind, metadata = meta })
    return true
end

local function spendBag(src)
    if not Whip.core:HasItem(src, ITEM.bags) then return false, 'You have no evidence bags' end
    local ok, why = Whip.core:RemoveItem(src, ITEM.bags, 1)
    if not ok then return false, why end
    return true
end


local function dropMark(mark)
    mark.gone = true
    for i, m in ipairs(S.marks) do
        if m == mark then table.remove(S.marks, i) break end
    end
    if mark.point then Whip.core:RemovePoint(mark.point) end
end

local function capArea(list, coords, kind, drop)
    local inArea, oldest = 0, nil
    for _, e in ipairs(list) do
        if e.kind == kind and #(e.coords - coords) <= C.areaMetres then
            inArea = inArea + 1
            if not oldest or e.at < oldest.at then oldest = e end
        end
    end
    if inArea >= C.perArea and oldest then drop(oldest) end
end

local MARKS = {
    blood = { label = 'Blood', collect = 'Swab', clean = 'Clean up', merge = 1.5, keyOf = function(d) return d.dna end },
    hole = { label = 'Bullet hole', collect = 'Dig out the round', merge = 0.5, keyOf = function(d) return d.serial end },
}

local useMark

local function addMark(kind, coords, data)
    local def = MARKS[kind]
    if not def or not C.enabled then return false, 'Evidence is off' end
    coords = v3(coords)
    local key = def.keyOf(data)
    if Ev.near(S.marks, coords, def.merge, function(m) return m.kind == kind and m.key == key end) then return true end
    capArea(S.marks, coords, kind, dropMark)
    local mark = { kind = kind, coords = coords, data = data, key = key, at = os.time() }
    local options = {
        { id = 'collect', label = def.collect, require = { job = PWP.deptKeys(), onDuty = true, item = ITEM.bags } },
    }
    if def.clean then options[2] = { id = 'clean', label = def.clean, require = { item = ITEM.cloth } } end
    local id, why = Whip.core:AddPoint({
        at = { coords = coords }, label = def.label, icon = 'target', audience = 'everyone',
        reach = 1.5, seeFrom = 6.0, options = options,
        onUse = function(source, use) return useMark(source, mark, use.option) end,
    })
    if not id then return false, why end
    mark.point = id
    S.marks[#S.marks + 1] = mark
    emit('evidenceCreated', { kind = kind, coords = coords, data = data })
    return id
end

useMark = function(source, mark, option)
    local cleaning = option == 'clean'
    local player = Whip.core:GetPlayer(source)
    if not player then return false, 'Not loaded' end
    CreateThread(function()
        local done = Whip.core:Progress(source, {
            label = cleaning and 'Cleaning up...' or 'Collecting...', duration = cleaning and 5000 or 3000,
            near = { coords = mark.coords, range = 3.0 },
        })
        if not done or not Whip.core:IsSessionCurrent(source, player.session) then return end
        if mark.gone then return Whip.core:NotifyPlayer(source, 'It is gone', 'error') end
        if cleaning then
            dropMark(mark)
            Whip.core:LogActivity(source, 'evidence_cleaned', { detail = mark.kind })
            return Whip.core:NotifyPlayer(source, 'Cleaned up', 'success')
        end
        local ok, err = spendBag(source)
        if not ok then return Whip.core:NotifyPlayer(source, err, 'error') end
        dropMark(mark)
        local d = mark.data
        local meta = mark.kind == 'blood' and { kind = 'blood', dna = d.dna }
            or { kind = 'fragment', serial = d.serial, gun = d.gun }
        meta.foundAt, meta.x, meta.y, meta.z = mark.at, mark.coords.x, mark.coords.y, mark.coords.z
        local given, gerr = newBag(source, meta)
        if not given then Whip.core:NotifyPlayer(source, gerr or 'No room for the bag', 'error') end
    end)
    return true
end


local function casingMeta(b)
    return { serial = b.serial, gun = b.item, at = b.started, exp = b.started + C.casingMinutes * 60 }
end

local function dropCasing(c)
    for i, e in ipairs(S.casings) do
        if e == c then table.remove(S.casings, i) break end
    end
    Whip.core:DeleteGroundItem(c.id)
end

local function landCasings(b)
    local coords = v3(b.coords)
    capArea(S.casings, coords, 'casing', dropCasing)
    local row, why = Whip.core:CreateGroundItem({
        item = ITEM.casing, amount = math.max(1, math.min(500, b.shots)), coords = coords,
        metadata = casingMeta(b), reason = 'shots fired', createdBy = b.charId,
    })
    if not row then return print(('[%s] casings: %s'):format(PWP.RES, tostring(why))) end
    S.casings[#S.casings + 1] = { id = row.id, coords = coords, kind = 'casing', at = b.started,
        exp = b.started + C.casingMinutes * 60 }
    emit('evidenceCreated', { kind = 'casing', coords = coords, data = casingMeta(b) })
end

AddEventHandler('whip_gunny:weapon:fired', function(e)
    if GetInvokingResource() ~= 'whip_gunny' or not C.enabled then return end
    if type(e) ~= 'table' or not e.source or not e.serial or not e.coords then return end
    local now = GetGameTimer()
    local coords = v3(e.coords)
    S.lastFire[e.source] = { at = now, coords = coords, serial = e.serial, item = e.item }
    local b = S.bursts[e.serial]
    if b and Ev.sameBurst(b, coords, now, C.burstMetres, C.burstSeconds * 1000) then
        b.shots, b.at = b.shots + (tonumber(e.shots) or 1), now
        return
    end
    if b then landCasings(b) end
    S.bursts[e.serial] = { serial = e.serial, item = e.item, coords = coords, shots = tonumber(e.shots) or 1,
        at = now, started = os.time(), charId = charOf(e.source) }
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now = GetGameTimer()
        for serial, b in pairs(S.bursts) do
            if now - b.at >= FLUSH_MS then
                S.bursts[serial] = nil
                landCasings(b)
            end
        end
        for src, f in pairs(S.lastFire) do
            if now - f.at > FIRE_KEEP_MS then S.lastFire[src] = nil end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for i = #S.marks, 1, -1 do
            local m = S.marks[i]
            if now - m.at >= C.markMinutes * 60 then dropMark(m) end
        end
        for i = #S.casings, 1, -1 do
            local c = S.casings[i]
            if now >= c.exp then dropCasing(c) end
        end
    end
end)

local function sweepOldCasings()
    local rows = MySQL.query.await('SELECT `id`, `metadata`, `x`, `y`, `z` FROM `ground_items` WHERE `item` = ?',
        { ITEM.casing }) or {}
    local now = os.time()
    for _, r in ipairs(rows) do
        local meta = type(r.metadata) == 'string' and json.decode(r.metadata) or {}
        local exp = tonumber(meta and meta.exp) or 0
        if exp <= now then
            Whip.core:DeleteGroundItem(r.id)
        else
            S.casings[#S.casings + 1] = { id = r.id, coords = vector3(r.x, r.y, r.z), kind = 'casing',
                at = tonumber(meta.at) or now, exp = exp }
        end
    end
end


AddEventHandler('whip_core:player:died', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or not e.source or not e.charId then return end
    local ped = GetPlayerPed(e.source)
    if not ped or ped == 0 then return end
    local c = GetEntityCoords(ped)
    addMark('blood', vector3(c.x, c.y, c.z - 0.95), { dna = dnaOf(e.charId) })
end)


AddEventHandler('whip_gunny:weapon:drawn', function(e)
    if GetInvokingResource() ~= 'whip_gunny' or type(e) ~= 'table' or not e.source or not e.serial then return end
    S.drawn[e.source] = { slot = e.slot, pocket = e.pocket, item = e.item }
end)

AddEventHandler('whip_gunny:weapon:holstered', function(e)
    if GetInvokingResource() ~= 'whip_gunny' or type(e) ~= 'table' or not e.source then return end
    S.drawn[e.source] = nil
    if not C.enabled or e.reason ~= 'holstered' or not e.slot then return end
    local charId = charOf(e.source)
    if not charId then return end
    local addr = { kind = 'player', id = e.source, sub = e.pocket or 'player', slot = e.slot }
    local it = Whip.core:GetItemAt(addr)
    if not it or not isGun(it.metadata) then return end
    local prints = Ev.pushPrint(it.metadata.prints, printOf(charId), C.printsKept)
    Whip.core:SetItemMetadata(addr, { prints = prints })
end)

local function printCar(src, vehicleId)
    local charId = src and charOf(src)
    if not charId or not vehicleId or not C.enabled then return end
    local prints = Ev.pushPrint(Whip.core:GetVehicleData(vehicleId, PRINTS_KEY), printOf(charId), C.printsKept)
    Whip.core:SetVehicleData(vehicleId, PRINTS_KEY, prints)
end

AddEventHandler('whip_core:vehicle:registered', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' then return end
    printCar(e.source, e.vehicleId)
end)

AddEventHandler('whip_core:vehicle:lockpicked', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' then return end
    printCar(e.source, e.vehicleId)
end)

AddEventHandler('playerDropped', function()
    S.drawn[source], S.lastFire[source] = nil, nil
end)


local function examine(src, dept)
    local ok, why = Gear.onDutyAt(src, dept)
    if not ok then return false, why end
    local can, reason = Whip.core:HasJobPermission(src, dept, 'records')
    if not can then return false, reason or 'Your rank cannot do that' end
    local pockets, err = Whip.core:StoreRead({ kind = 'player', id = src, sub = 'player' })
    if not pockets then return false, err end
    local todo = {}
    for slot, it in pairs(pockets.items or {}) do
        if it.item == ITEM.bag and not (it.metadata or {}).result then todo[#todo + 1] = tonumber(slot) end
    end
    if #todo == 0 then return false, 'Bring evidence bags the lab has not read yet' end
    return todo
end

local function record(src, dept, kind, row)
    MySQL.insert.await(('INSERT INTO `%s` (`kind`, `serial`, `gun`, `code`, `x`, `y`, `z`, `foundAt`, `dept`, `analysedBy`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
        :format(T.evidence), { kind, row.serial, row.gun, row.code, row.x, row.y, row.z, row.foundAt, dept, charOf(src) })
end

local function codesOf(meta)
    local list = meta.kind == 'blood' and { meta.dna } or ((meta.kind == 'prints' or meta.kind == 'gun') and meta.prints)
    if type(list) ~= 'table' or #list == 0 then return { false } end
    return list
end

local function analyse(src, dept)
    local todo, why = examine(src, dept)
    if not todo then return Whip.core:NotifyPlayer(src, why, 'error') end
    local player = Whip.core:GetPlayer(src)
    if not player then return end
    local done, err = Whip.core:Progress(src, { label = 'Analysing evidence...', duration = C.labSeconds * 1000 })
    if not done then return Whip.core:NotifyPlayer(src, err == 'cancelled' and 'Stopped' or 'The lab run failed', 'error') end
    if not Whip.core:IsSessionCurrent(src, player.session) then return end
    local lines = {}
    for _, slot in ipairs(todo) do
        local addr = { kind = 'player', id = src, sub = 'player', slot = slot }
        local it = Whip.core:GetItemAt(addr)
        local meta = it and it.item == ITEM.bag and it.metadata
        if meta and not meta.result then
            local text = Ev.result(meta, gunName(meta.gun))
            for _, code in ipairs(codesOf(meta)) do
                record(src, dept, meta.kind or 'unknown', { serial = meta.serial, gun = meta.gun, code = code or nil,
                    x = meta.x, y = meta.y, z = meta.z, foundAt = meta.foundAt })
            end
            Whip.core:SetItemMetadata(addr, { result = text, analysedAt = os.time() })
            lines[#lines + 1] = text
            emit('evidenceAnalysed', { source = src, kind = meta.kind, result = text, metadata = meta })
        end
    end
    Whip.core:NotifyPlayer(src, table.concat(lines, '; '), 'success')
end

local function lockerOf(row, index)
    if S.lockers[row] then return S.lockers[row] end
    local def, why = Whip.core:EnsureContainer(('%s:evidence:%d'):format(PWP.RES, index), {
        name = row.label, slots = C.locker.slots, maxWeight = C.locker.weight,
        x = Gear.HIDDEN.x, y = Gear.HIDDEN.y, z = Gear.HIDDEN.z,
        requirements = { jobs = row.dept, onDuty = true },
    })
    if not def then return false, why end
    S.lockers[row] = def.containerId
    return def.containerId
end

local custody = {
    read = Gear.storage.actions.read,
    move = function(src, session, a)
        local slot = tonumber(a.slot)
        local from = a.from == 'pockets' and { kind = 'player', id = src, sub = 'player', slot = slot }
            or { kind = session.addr.kind, id = session.addr.id, slot = slot }
        local it = slot and Whip.core:GetItemAt(from)
        local result, why = Gear.storage.actions.move(src, session, a)
        if result and it then
            Whip.core:LogActivity(src, a.from == 'pockets' and 'evidence_in' or 'evidence_out',
                { detail = ('%s %s x%d'):format(session.row.label, it.item, it.amount or 1) })
        end
        return result, why
    end,
}

Station.kind('evidence', {
    build = function(src, session)
        local ok, why = Gear.onDutyAt(src, session.dept)
        if not ok then return false, why end
        local id = S.lockers[session.row]
        if not id then return false, 'The evidence locker is not ready' end
        session.addr = { kind = 'container', id = id }
        local data, err = Gear.storage.build(src, session)
        if data then data.storeLabel = 'Evidence locker' end
        return data, err
    end,
    actions = custody,
})

PWP.Points.kind('evidence', {
    icon = 'box',
    require = { onDuty = true },
    options = { { id = 'locker', label = 'Evidence locker' }, { id = 'lab', label = 'Analyse evidence' } },
    onUse = function(source, dept, row, use)
        if use and use.option == 'lab' then
            CreateThread(function() analyse(source, dept) end)
            return true
        end
        return Station.open(source, 'evidence', dept, row)
    end,
})


local function wipe(src, addr)
    local it = Whip.core:GetItemAt(addr)
    if not it or not isGun(it.metadata) then return false, 'Hold a gun to wipe it' end
    local ok, why = Whip.core:SetItemMetadata(addr, {}, { remove = { 'prints' } })
    if not ok then return false, why end
    Whip.core:NotifyPlayer(src, 'Wiped clean', 'success')
    return true
end

local function gunOptions()
    for key, def in pairs(Whip.core:GetItemDefs() or {}) do
        if def.type == 'weapon' and not def.stack and not def.fuelCapacity then
            Whip.core:AddItemOption(key, { action = PWP.name('baggun'), label = 'Bag as evidence',
                require = { job = PWP.deptKeys(), onDuty = true, item = ITEM.bags } })
        end
    end
end

AddEventHandler('whip_gunny:packs:ready', function()
    if C.enabled and Whip.isReady() then gunOptions() end
end)

Whip.register(function()
    S.marks, S.casings, S.lockers = {}, {}, {}
    if not C.enabled then return end
    Whip.core:RegisterItem(ITEM.casing, {
        name = 'Bullet Casing', desc = 'A spent casing.', weight = 0.01, type = 'misc',
        stack = true, maxStack = 500, prop = 'gr_prop_gr_single_bullet',
    })
    Whip.core:RegisterItem(ITEM.bag, {
        name = 'Evidence Bag', desc = 'Sealed evidence. The lab reads it.', weight = 0.05, type = 'misc',
        stack = false, prop = 'hei_heist_evidence01',
        metaFields = {
            { key = 'kind', label = 'Holds', format = 'uppercase' },
            { key = 'serial', label = 'Serial', format = 'uppercase' },
            { key = 'plate', label = 'Plate', format = 'uppercase' },
            { key = 'result', label = 'Lab', value = 'Not analysed' },
        },
    })
    Whip.core:RegisterItem(ITEM.bags, {
        name = 'Evidence Bags', desc = 'Empty bags for collecting evidence.', weight = 0.02, type = 'tool',
        stack = true, maxStack = 50, prop = 'hei_heist_evidence01',
    })
    Whip.core:RegisterItem(ITEM.cloth, {
        name = 'Cleaning Cloth', desc = 'Wipes prints off a gun or a car, and cleans up blood.', weight = 0.05,
        type = 'tool', stack = true, maxStack = 10, usable = true,
    })

    Whip.core:RegisterUseHandler(ITEM.cloth, function(source)
        local d = S.drawn[source]
        if not d then
            Whip.core:NotifyPlayer(source, 'Draw a gun to wipe it, or use the cloth at a car door or on blood', 'error')
            return false
        end
        local ok, why = wipe(source, { kind = 'player', id = source, sub = d.pocket or 'player', slot = d.slot })
        if not ok then Whip.core:NotifyPlayer(source, why, 'error') end
        return false
    end)

    Whip.core:AddItemOption(ITEM.casing, { action = PWP.name('bag'), label = 'Bag as evidence',
        require = { job = PWP.deptKeys(), onDuty = true, item = ITEM.bags } })
    Whip.core:RegisterContextAction(PWP.name('bag'), function(source, _, slotData, addr)
        if not slotData or slotData.item ~= ITEM.casing then return false, 'That is not a casing' end
        local ok, why = spendBag(source)
        if not ok then return false, why end
        local taken, err = Whip.core:StoreTake(addr)
        if not taken then
            Whip.core:AddItem(source, ITEM.bags, 1)
            return false, err
        end
        local m = taken.metadata or {}
        local given, gerr = newBag(source, { kind = 'casing', serial = m.serial, gun = m.gun, count = taken.amount,
            foundAt = m.at })
        if not given then
            Whip.core:StoreGive(addr, taken.item, taken.amount, taken.metadata)
            Whip.core:AddItem(source, ITEM.bags, 1)
            return false, gerr
        end
        return true
    end)

    Whip.core:AddItemOption(ITEM.bag, { action = PWP.name('unbag'), label = 'Take out the gun', when = { kind = 'gun' },
        require = { job = PWP.deptKeys(), onDuty = true } })
    Whip.core:RegisterContextAction(PWP.name('unbag'), function(source, _, slotData, addr)
        local m = slotData and slotData.metadata or {}
        if not slotData or slotData.item ~= ITEM.bag or m.kind ~= 'gun' or not m.gunItem then return false, 'There is no gun in it' end
        local taken, err = Whip.core:StoreTake(addr)
        if not taken then return false, err end
        local where, why = Whip.core:AddItem(source, m.gunItem, 1, m.gunMeta, { reason = 'evidence released' })
        if not where then
            Whip.core:StoreGive(addr, taken.item, taken.amount, taken.metadata)
            return false, why
        end
        Whip.core:LogActivity(source, 'evidence_out', { detail = ('gun %s'):format(tostring(m.serial)) })
        return true
    end)
    Whip.core:RegisterContextAction(PWP.name('baggun'), function(source, _, slotData, addr)
        local m = slotData and slotData.metadata
        if not isGun(m) then return false, 'Only a gun goes in an evidence bag this way' end
        local ok, why = spendBag(source)
        if not ok then return false, why end
        local taken, err = Whip.core:StoreTake(addr)
        if not taken then
            Whip.core:AddItem(source, ITEM.bags, 1)
            return false, err
        end
        local given, gerr = newBag(source, { kind = 'gun', serial = m.serial, gun = taken.item, gunItem = taken.item,
            gunMeta = taken.metadata, prints = m.prints or {}, foundAt = os.time() })
        if not given then
            Whip.core:StoreGive(addr, taken.item, taken.amount, taken.metadata)
            Whip.core:AddItem(source, ITEM.bags, 1)
            return false, gerr
        end
        return true
    end)
    gunOptions()

    Whip.core:SecureEvent(PWP.event('hurt'), { rateLimit = C.hurtSeconds * 1000 }, function(source)
        local charId = charOf(source)
        local ped = GetPlayerPed(source)
        if not charId or not ped or ped == 0 then return end
        if GetEntityHealth(ped) >= GetEntityMaxHealth(ped) then return end
        local c = GetEntityCoords(ped)
        addMark('blood', vector3(c.x, c.y, c.z - 0.95), { dna = dnaOf(charId) })
    end)

    Whip.core:SecureEvent(PWP.event('hit'), {
        rateLimit = 250,
        params = { { 'x', 'number', -10000, 10000 }, { 'y', 'number', -10000, 10000 }, { 'z', 'number', -500, 3000 } },
    }, function(source, _, x, y, z)
        local f = S.lastFire[source]
        if not f or GetGameTimer() - f.at > FIRE_KEEP_MS then return end
        local hit = vector3(x, y, z)
        if #(hit - f.coords) > C.hitMetres then return end
        addMark('hole', hit, { serial = f.serial, gun = f.item })
    end)

    Whip.core:SecureEvent(PWP.event('door'), {
        rateLimit = 2000,
        params = { { 'veh', 'vehicle', { anyOwner = true, session = true } }, { 'how', 'enum', { 'dust', 'wipe' } } },
        near = { at = 'vehicle', range = 4.0 },
    }, function(source, _, veh, how)
        if how == 'wipe' then
            if not Whip.core:HasItem(source, ITEM.cloth) then return false, 'You need a cleaning cloth' end
            Whip.core:SetVehicleData(veh, PRINTS_KEY, nil)
            Whip.core:LogActivity(source, 'evidence_cleaned', { detail = 'car prints' })
            Whip.core:NotifyPlayer(source, 'Wiped down', 'success')
            return
        end
        local ok, why = PWP.Depts.can(source, 'records')
        if not ok then return false, why end
        local spent, err = spendBag(source)
        if not spent then return false, err end
        local c = GetEntityCoords(GetPlayerPed(source))
        newBag(source, { kind = 'prints', prints = Whip.core:GetVehicleData(veh, PRINTS_KEY) or {},
            plate = veh.plate, foundAt = os.time(), x = c.x, y = c.y, z = c.z })
    end)

    for index, row in ipairs(Config.Points) do
        if row.kind == 'evidence' and PWP.isDept(row.dept) then
            local id, why = lockerOf(row, index)
            if not id then print(('[%s] evidence locker %d: %s'):format(PWP.RES, index, tostring(why))) end
        end
    end

    local ok = Whip.core:EnsureTable(T.evidence, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `kind` VARCHAR(16) NOT NULL,
        `serial` VARCHAR(32) NULL, `gun` VARCHAR(64) NULL, `code` VARCHAR(24) NULL,
        `x` FLOAT NULL, `y` FLOAT NULL, `z` FLOAT NULL, `foundAt` INT UNSIGNED NULL, `dept` VARCHAR(50) NOT NULL,
        `analysedBy` INT UNSIGNED NULL, `analysedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX (`serial`), INDEX (`code`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.evidence))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T.evidence)) end
    ok = Whip.core:EnsureTable(T.samples, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `charId` INT UNSIGNED NOT NULL PRIMARY KEY, `dna` VARCHAR(24) NOT NULL, `print` VARCHAR(24) NOT NULL,
        `takenBy` INT UNSIGNED NULL, `takenAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX (`dna`), INDEX (`print`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(T.samples))
    if not ok then print(('[%s] table %s could not be made'):format(PWP.RES, T.samples)) end

    sweepOldCasings()
end)


local E = { T = T, ITEM = ITEM, dnaOf = dnaOf, printOf = printOf, addMark = addMark }
PWP.EvidenceServer = E

function E.takeSamples(src, target)
    local charId = charOf(target)
    if not charId then return false, 'They are not here' end
    if not PWP.Contact.isCuffed(target) then return false, 'Cuff them first' end
    local a, b = GetEntityCoords(GetPlayerPed(src)), GetEntityCoords(GetPlayerPed(target))
    if #(a - b) > C.reach then return false, 'Stand next to them' end
    local dna, fp = dnaOf(charId), printOf(charId)
    MySQL.query.await(('INSERT INTO `%s` (`charId`, `dna`, `print`, `takenBy`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `takenBy` = VALUES(`takenBy`), `takenAt` = CURRENT_TIMESTAMP')
        :format(T.samples), { charId, dna, fp, charOf(src) })
    return { charId = charId, dna = dna, print = fp }
end

function E.samplesOf(charId)
    if not C.enabled then return nil end
    return MySQL.single.await(('SELECT `dna`, `print`, `takenAt` FROM `%s` WHERE `charId` = ?'):format(T.samples),
        { charId })
end

function E.ownerOf(code)
    if not C.enabled then return nil end
    local row = MySQL.single.await(('SELECT `charId` FROM `%s` WHERE `dna` = ? OR `print` = ?'):format(T.samples),
        { code, code })
    return row and row.charId or nil
end

function E.search(q)
    q = PWP.Text.clean(q, 32)
    if not q or not C.enabled then return {} end
    return MySQL.query.await(('SELECT `id`, `kind`, `serial`, `gun`, `code`, `x`, `y`, `z`, `foundAt`, `dept`, UNIX_TIMESTAMP(`analysedAt`) AS `analysedAt` FROM `%s` WHERE `serial` = ? OR `code` = ? ORDER BY `id` DESC LIMIT 50')
        :format(T.evidence), { q, q }) or {}
end

exports('CreateEvidence', function(kind, coords, data)
    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return false, 'coords must be a vector3' end
    data = type(data) == 'table' and data or {}
    if kind == 'blood' then
        local charId = tonumber(data.charId)
        if not charId then return false, 'blood needs data.charId' end
        return addMark('blood', coords, { dna = dnaOf(charId) })
    elseif kind == 'hole' then
        if not data.serial then return false, 'a bullet hole needs data.serial' end
        return addMark('hole', coords, { serial = tostring(data.serial), gun = data.gun })
    elseif kind == 'casing' then
        if not data.serial then return false, 'casings need data.serial' end
        landCasings({ serial = tostring(data.serial), item = data.gun, coords = coords,
            shots = math.floor(tonumber(data.amount) or 1), started = os.time(), charId = data.charId })
        return true
    end
    return false, "kind is 'blood', 'hole' or 'casing'"
end)

exports('GetEvidenceNear', function(coords, radius)
    if type(coords) ~= 'vector3' then return false, 'coords must be a vector3' end
    radius = math.min(tonumber(radius) or 10.0, 200.0)
    local out = {}
    for _, m in ipairs(S.marks) do
        if #(m.coords - coords) <= radius then out[#out + 1] = { kind = m.kind, coords = m.coords, at = m.at } end
    end
    for _, c in ipairs(S.casings) do
        if #(c.coords - coords) <= radius then out[#out + 1] = { kind = 'casing', coords = c.coords, at = c.at, id = c.id } end
    end
    return out
end)

exports('GetForensicCodes', function(charId)
    charId = tonumber(charId)
    if not charId then return false, 'charId must be a number' end
    return { dna = dnaOf(charId), print = printOf(charId) }
end)

exports('FindCodeOwner', function(code)
    if type(code) ~= 'string' then return false, 'code must be text' end
    local charId = E.ownerOf(code)
    if not charId then return false, 'No sample on file matches' end
    return charId
end)

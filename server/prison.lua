local TABLE = 'pure_whip_police_sentences'
local FLAG = PWP.name('jail')
local BLOCK = PWP.name('jail')
local HIDDEN = vector3(-2.0, -2.0, -60.0)
local S = PWP.Sentence

local Prison = { jailed = {}, belongings = {}, cooldown = {} }
PWP.Prison = Prison

local function q(sql) return (sql:gsub('{t}', '`' .. TABLE .. '`')) end

local function keep(item)
    for _, k in ipairs(Config.Prison.keepItems or {}) do if k == item then return true end end
    return false
end

local function belongingsOf(charId)
    if Prison.belongings[charId] then return Prison.belongings[charId] end
    local def, why = Whip.core:EnsureContainer(('%s:belongings:%d'):format(PWP.RES, charId), {
        name = 'Belongings', slots = 80, maxWeight = 1000.0,
        x = HIDDEN.x, y = HIDDEN.y, z = HIDDEN.z,
        requirements = { charIds = { charId } },
    })
    if not def then return false, why end
    Prison.belongings[charId] = def.containerId
    return def.containerId
end

local function teleport(src, spot)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    SetEntityCoords(ped, spot.x, spot.y, spot.z, false, false, false, false)
    if spot.w then SetEntityHeading(ped, spot.w) end
end

local function cellSpot()
    local list = Config.Prison.spawns
    return list[math.random(1, #list)]
end

function Prison.sentenceOf(charId)
    for s, j in pairs(Prison.jailed) do
        if j.charId == tonumber(charId) then return { minutesLeft = j.left, months = j.months, reason = j.reason, online = true, source = s } end
    end
    local row = MySQL.single.await(q("SELECT * FROM {t} WHERE `charId` = ? AND `status` = 'active' ORDER BY `id` DESC LIMIT 1"),
        { tonumber(charId) })
    if not row then return nil end
    return { minutesLeft = row.minutesLeft, months = row.months, reason = row.reason, online = false }
end

local function storeBelongings(src, charId)
    local cid, why = belongingsOf(charId)
    if not cid then return false, why end
    local inv = Whip.core:GetInventory(src) or {}
    local moved = 0
    for _, sub in ipairs({ 'player', 'accessory' }) do
        for slot, stack in pairs(inv[sub] or {}) do
            if stack and stack.item and not keep(stack.item) then
                local ok = Whip.core:StoreMove({ kind = 'player', id = src, sub = sub, slot = slot },
                    { kind = 'container', id = cid }, { reason = 'prison: belongings kept' })
                if ok then moved = moved + 1 end
            end
        end
    end
    return true, moved
end

local function returnBelongings(src, charId)
    local cid = belongingsOf(charId)
    if not cid then return 0, 0 end
    local contents = Whip.core:StoreRead({ kind = 'container', id = cid }) or {}
    local back, left = 0, 0
    for slot, stack in pairs(contents.items or {}) do
        if type(stack) == 'table' and stack.item then
            local ok = Whip.core:StoreMove({ kind = 'container', id = cid, slot = slot },
                { kind = 'player', id = src, sub = 'player' }, { reason = 'prison: belongings returned' })
            if ok then back = back + 1 else left = left + 1 end
        end
    end
    return back, left
end

local function save(charId, left)
    MySQL.update.await(q("UPDATE {t} SET `minutesLeft` = ? WHERE `charId` = ? AND `status` = 'active'"), { left, charId })
end

local function admit(src, charId, row)
    Prison.jailed[src] = { charId = charId, left = row.minutesLeft, months = row.months, reason = row.reason }
    Whip.core:SetPlayerFlag(src, FLAG, row.minutesLeft)
    Whip.core:BlockHands(src, BLOCK, { only = 'weapons', label = 'No weapons in here' })
end

function Prison.jail(target, months, opts)
    opts = opts or {}
    local charId = Whip.core:GetCharId(target)
    if not charId then return false, 'They are not here' end
    if Prison.jailed[target] then return false, 'They are already in prison' end
    months = math.floor(tonumber(months) or 0)
    if months < 1 or months > Config.Prison.maxMonths then
        return false, ('A sentence is 1 to %d months'):format(Config.Prison.maxMonths)
    end
    local minutes = S.minutes(months, Config.Prison.minutesPerMonth)
    local reason = PWP.Text.clean(opts.reason, 200) or 'Sentenced'
    local stored, why = storeBelongings(target, charId)
    if not stored then return false, why or 'Their belongings could not be stored' end
    local id = MySQL.insert.await(q([[INSERT INTO {t} (`charId`, `months`, `minutesLeft`, `reason`, `dept`, `sentencedBy`, `reportId`)
        VALUES (?, ?, ?, ?, ?, ?, ?)]]), { charId, months, minutes, reason, opts.dept, PWP.Records.charOf(opts.by), tonumber(opts.reportId) })
    if not id then return false, 'Could not save the sentence (their things are in prison storage)' end
    if PWP.Contact.isCuffed(target) then PWP.Contact.uncuff(opts.by, target) end
    admit(target, charId, { minutesLeft = minutes, months = months, reason = reason })
    teleport(target, cellSpot())
    Whip.core:NotifyPlayer(target, ('Sentenced to %d months: %d minutes inside. Your things are kept at the gate.'):format(months, minutes), 'warning', 10000)
    TriggerEvent(PWP.event('jailed'), { source = target, charId = charId, months = months, minutes = minutes, by = opts.by })
    return true, minutes
end

function Prison.release(target, opts)
    opts = opts or {}
    local j = Prison.jailed[target]
    if not j then return false, 'They are not in prison' end
    Prison.jailed[target] = nil
    MySQL.update.await(q("UPDATE {t} SET `status` = ?, `minutesLeft` = 0, `releasedAt` = NOW() WHERE `charId` = ? AND `status` = 'active'"),
        { opts.early and 'released' or 'served', j.charId })
    Whip.core:SetPlayerFlag(target, FLAG, nil)
    Whip.core:UnblockHands(target, BLOCK)
    teleport(target, Config.Prison.release)
    local back, left = returnBelongings(target, j.charId)
    Whip.core:NotifyPlayer(target, left > 0
        and ('You are free. %d of your things did not fit: collect them at the gate.'):format(left)
        or 'You are free. Your things are back in your pockets.', 'success', 10000)
    TriggerEvent(PWP.event('released'), { source = target, charId = j.charId, early = opts.early == true, by = opts.by })
    return true, back
end

local function tick()
    for src, j in pairs(Prison.jailed) do
        if not Whip.core:GetCharId(src) then
            Prison.jailed[src] = nil
        else
            j.left = S.cut(j.left, 1)
            Whip.core:SetPlayerFlag(src, FLAG, j.left)
            save(j.charId, j.left)
            if j.left <= 0 then
                Prison.release(src)
            elseif j.left % 5 == 0 then
                Whip.core:NotifyPlayer(src, ('%d minutes left'):format(j.left), 'info')
            end
        end
    end
end

local function guard()
    local zone = Config.Prison.zone
    for src in pairs(Prison.jailed) do
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 and not S.inBox(GetEntityCoords(ped), zone) then
            teleport(src, cellSpot())
            Whip.core:NotifyPlayer(src, 'You cannot leave the prison', 'error')
        end
    end
end

CreateThread(function()
    local seconds = 0
    while true do
        Wait(5000)
        seconds = seconds + 5
        guard()
        if seconds >= 60 then seconds = 0; tick() end
    end
end)

AddEventHandler('whip_core:player:loaded', function(e)
    local row = MySQL.single.await(q("SELECT * FROM {t} WHERE `charId` = ? AND `status` = 'active' ORDER BY `id` DESC LIMIT 1"),
        { e.charId })
    if not row or row.minutesLeft <= 0 then return end
    admit(e.source, e.charId, row)
    teleport(e.source, cellSpot())
    Whip.core:NotifyPlayer(e.source, ('Back inside: %d minutes left'):format(row.minutesLeft), 'warning')
end)

AddEventHandler('playerDropped', function() Prison.jailed[source] = nil end)

local function addPrisonPoints()
    for i, job in ipairs(Config.Prison.jobs) do
        Whip.core:AddPoint({
            at = { coords = job.coords }, label = job.label, icon = 'timer', reach = 1.5,
            onUse = function(source)
                local j = Prison.jailed[source]
                if not j then return false, 'Only for inmates' end
                local key = source .. ':' .. i
                if (Prison.cooldown[key] or 0) > os.time() then return false, 'Done here for now: try another spot' end
                Prison.cooldown[key] = os.time() + Config.Prison.jobCooldown
                CreateThread(function()
                    local done = Whip.core:Progress(source, { label = job.label, duration = 10000,
                        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                        near = { coords = job.coords, range = 3.0 } })
                    if done ~= true or not Prison.jailed[source] then return end
                    j.left = S.cut(j.left, Config.Prison.cutPerJob)
                    Whip.core:NotifyPlayer(source, ('Good work: %d minutes left'):format(j.left), 'success')
                end)
                return true
            end,
        })
    end
    Whip.core:AddPoint({
        at = { coords = Config.Prison.booking }, label = 'Prison belongings', icon = 'bag', reach = 2.0,
        onUse = function(source)
            if Prison.jailed[source] then return false, 'Not while you are inside' end
            CreateThread(function()
                local cid = belongingsOf(Whip.core:GetCharId(source))
                if not cid then return end
                local ok, why = Whip.core:OpenStore(source, { kind = 'container', id = cid }, { skipDistance = true, skipAccess = true })
                if not ok then Whip.core:NotifyPlayer(source, why, 'error') end
            end)
            return true
        end,
    })
end

Whip.register(function()
    local ok, why = Whip.core:EnsureTable(TABLE, ([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `charId` INT NOT NULL, `months` SMALLINT UNSIGNED NOT NULL,
        `minutesLeft` INT UNSIGNED NOT NULL, `reason` VARCHAR(200) NOT NULL, `dept` VARCHAR(50) NULL,
        `sentencedBy` INT NULL, `reportId` INT UNSIGNED NULL,
        `status` ENUM('active','served','released') NOT NULL DEFAULT 'active',
        `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `releasedAt` DATETIME NULL,
        PRIMARY KEY (`id`), KEY `charId` (`charId`, `status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]):format(TABLE))
    if not ok then print(('[%s] sentences table: %s'):format(PWP.RES, tostring(why))) end
    local z = Config.Prison.zone
    Whip.core:EnsureZone(PWP.RES .. ':bolingbroke', { type = 'box', pos = z.pos, size = z.size, heading = z.heading,
        label = 'Bolingbroke Penitentiary', trackPlayers = true })
    Whip.core:ShowBlip('everyone', 'prison', { coords = Config.Prison.booking, label = 'Bolingbroke Penitentiary',
        sprite = 188, color = 0, shortRange = true })
    addPrisonPoints()
end)

Whip.command('jail', {}, function(source, args)
    if source == 0 then return print('in game only') end
    local ok, dept = PWP.Depts.can(source, 'jail')
    if not ok then return Whip.core:NotifyPlayer(source, dept, 'error') end
    local target, months = tonumber(args[1]), tonumber(args[2])
    if not target or not months then return Whip.core:NotifyPlayer(source, '/jail <id> <months> [reason]', 'info') end
    local tped = target and GetPlayerPed(target)
    if not tped or tped == 0 or #(GetEntityCoords(tped) - GetEntityCoords(GetPlayerPed(source))) > 5.0 then
        return Whip.core:NotifyPlayer(source, 'They must be with you', 'error')
    end
    if not PWP.Contact.isCuffed(target) then return Whip.core:NotifyPlayer(source, 'Cuff them first', 'error') end
    local done, minutes = Prison.jail(target, months, { by = source, dept = dept, reason = table.concat(args, ' ', 3) })
    if not done then return Whip.core:NotifyPlayer(source, minutes, 'error') end
    Whip.core:LogActivity(source, 'jailed', { detail = ('%s jailed charId %d for %d months'):format(dept, Whip.core:GetCharId(target), months) })
    Whip.core:NotifyPlayer(source, ('Sent to prison: %d minutes'):format(minutes), 'success')
end)

Whip.command('unjail', {}, function(source, args)
    if source == 0 then return print('in game only') end
    local ok, dept = PWP.Depts.can(source, 'prison_staff')
    if not ok then return Whip.core:NotifyPlayer(source, dept, 'error') end
    local target = tonumber(args[1])
    if not target then return Whip.core:NotifyPlayer(source, '/unjail <id>', 'info') end
    local done, why = Prison.release(target, { early = true, by = source })
    if not done then return Whip.core:NotifyPlayer(source, why, 'error') end
    Whip.core:LogActivity(source, 'released', { detail = ('%s released charId %s early'):format(dept, tostring(Whip.core:GetCharId(target))) })
end)

exports('Jail', function(target, months, opts) return Prison.jail(tonumber(target), months, opts) end)
exports('Release', function(target, opts) return Prison.release(tonumber(target), opts) end)
exports('IsJailed', function(target) return Prison.jailed[tonumber(target)] ~= nil end)
exports('GetSentence', function(charId) return Prison.sentenceOf(charId) end)

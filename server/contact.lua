local HANDCUFFS = PWP.name('handcuffs')
local ZIPTIES = PWP.name('zipties')
local FLAG = PWP.name('cuffed')
local BLOCK = PWP.name('cuffed')
local KINDS = { 'soft', 'hard', 'zip' }

local Contact = { cuffed = {} }
PWP.Contact = Contact

function Contact.isCuffed(src)
    local s = Contact.cuffed[src]
    return s and s.kind or false
end

local function apply(src, kind)
    Contact.cuffed[src] = { kind = kind, at = os.time() }
    Whip.core:BlockHands(src, BLOCK, { label = 'Your hands are cuffed' })
    TriggerClientEvent(PWP.event('cuffState'), src, kind)
end

local function release(src)
    Contact.cuffed[src] = nil
    Whip.core:UnblockHands(src, BLOCK)
    TriggerClientEvent(PWP.event('cuffState'), src, false)
end

function Contact.cuff(by, target, kind)
    if Contact.isCuffed(target) then return false, 'They are already cuffed' end
    if Whip.core:IsPlayerDead(target) then return false, 'They are down: help them first' end
    local ok, why = Whip.core:SetPlayerFlag(target, FLAG, kind)
    if not ok then return false, why end
    apply(target, kind)
    if kind == 'zip' then
        local charId = Whip.core:GetCharId(target)
        SetTimeout(math.max(1, Config.Contact.zipMinutes) * 60000, function()
            local s = Contact.cuffed[target]
            if s and s.kind == 'zip' and Whip.core:GetCharId(target) == charId then Contact.uncuff(nil, target) end
        end)
    end
    TriggerEvent(PWP.event('cuffed'), { source = target, by = by, kind = kind })
    return true
end

function Contact.uncuff(by, target)
    if not Contact.isCuffed(target) then return false, 'They are not cuffed' end
    Whip.core:SetPlayerFlag(target, FLAG, nil)
    release(target)
    TriggerEvent(PWP.event('uncuffed'), { source = target, by = by })
    return true
end

local function officerOnly(source, permission)
    if Contact.isCuffed(source) then return false, 'Your hands are cuffed' end
    return PWP.Depts.can(source, permission)
end

Whip.register(function()
    Whip.core:RegisterItem(HANDCUFFS, {
        name = 'Handcuffs', desc = 'Police issue. Cuff a suspect in front or behind.',
        weight = 0.4, type = 'tool', stack = false, usable = false,
    })
    Whip.core:RegisterItem(ZIPTIES, {
        name = 'Zip Ties', desc = 'Plastic restraints. Fall off after a while.',
        weight = 0.05, type = 'tool', stack = true, maxStack = 20, usable = false,
    })

    Whip.core:SecureEvent(PWP.event('cuff'), {
        rateLimit = 1500,
        params = { { 'target', 'player', { range = Config.Contact.reach } }, { 'kind', 'enum', KINDS } },
    }, function(source, _, target, kind)
        local ok, dept = officerOnly(source, 'cuff')
        if not ok then return false, dept end
        local tool = kind == 'zip' and ZIPTIES or HANDCUFFS
        if not Whip.core:HasItem(source, tool) then
            return false, kind == 'zip' and 'You have no zip ties' or 'You have no handcuffs'
        end
        local done, why = Contact.cuff(source, target.source, kind)
        if not done then return false, why end
        if kind == 'zip' then
            local took = Whip.core:RemoveItem(source, ZIPTIES, 1, nil, { reason = 'zip ties used' })
            if not took then
                Contact.uncuff(nil, target.source)
                return false, 'You have no zip ties'
            end
        end
        TriggerClientEvent(PWP.event('playCuff'), source)
        Whip.core:NotifyPlayer(target.source, 'You have been cuffed', 'warning')
        Whip.core:LogActivity(source, 'cuffed', { detail = ('%s cuffed charId %s (%s)'):format(dept, tostring(target.charId), kind) })
    end)

    Whip.core:SecureEvent(PWP.event('uncuff'), {
        rateLimit = 1500,
        params = { { 'target', 'player', { range = Config.Contact.reach } } },
    }, function(source, _, target)
        local ok, dept = officerOnly(source, 'cuff')
        if not ok then return false, dept end
        local done, why = Contact.uncuff(source, target.source)
        if not done then return false, why end
        TriggerClientEvent(PWP.event('playCuff'), source)
        Whip.core:NotifyPlayer(target.source, 'Your cuffs are off', 'success')
        Whip.core:LogActivity(source, 'uncuffed', { detail = ('%s uncuffed charId %s'):format(dept, tostring(target.charId)) })
    end)

    Whip.core:SecureEvent(PWP.event('search'), {
        rateLimit = 2000,
        params = { { 'target', 'player', { range = Config.Contact.reach } } },
    }, function(source, player, target)
        local ok, dept = officerOnly(source, 'search')
        if not ok then return false, dept end
        if not Contact.isCuffed(target.source) and not Whip.core:IsPlayerDead(target.source) then
            return false, 'Cuff them first'
        end
        local done = Whip.core:Progress(source, {
            label = 'Searching', duration = math.max(1, Config.Contact.searchSeconds) * 1000,
            anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
            near = { coords = GetEntityCoords(GetPlayerPed(target.source)), range = Config.Contact.reach + 1.0 },
        })
        if done ~= true then return false end
        if not Whip.core:IsSessionCurrent(source, player.session) or not Whip.core:IsSessionCurrent(target.source, target.session) then
            return false
        end
        local opened, why = Whip.core:OpenPlayerInventory(source, target.source, { range = Config.Contact.reach + 1.0 })
        if not opened then return false, why end
        Whip.core:LogActivity(source, 'searched', { detail = ('%s searched charId %s'):format(dept, tostring(target.charId)) })
    end)
end)

AddEventHandler('whip_core:player:loaded', function(e)
    local kind = Whip.core:GetPlayerFlag(e.source, FLAG)
    if kind then apply(e.source, kind) end
end)

AddEventHandler('playerDropped', function() Contact.cuffed[source] = nil end)

exports('IsCuffed', function(src) return Contact.isCuffed(tonumber(src)) end)
exports('IsEscorted', function(src) return Player(tonumber(src)).state.whipEscorted == true end)
exports('Cuff', function(target, opts)
    opts = opts or {}
    local kind = opts.kind or 'soft'
    if kind ~= 'soft' and kind ~= 'hard' and kind ~= 'zip' then return false, "kind is 'soft', 'hard' or 'zip'" end
    if not Whip.core:GetCharId(tonumber(target)) then return false, 'No such player' end
    return Contact.cuff(opts.by, tonumber(target), kind)
end)
exports('Uncuff', function(target, opts)
    if not Whip.core:GetCharId(tonumber(target)) then return false, 'No such player' end
    return Contact.uncuff((opts or {}).by, tonumber(target))
end)

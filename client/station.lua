local ACT = PWP.RES .. ':station:act'
local SCREEN = 'station'
local open = nil

local function bodyOf(ped)
    local model = GetEntityModel(ped)
    if model == GetHashKey('mp_m_freemode_01') then return 'male' end
    if model == GetHashKey('mp_f_freemode_01') then return 'female' end
    return nil
end

local function topPicture(ped, body, top)
    if not body or not top or GetPedCollectionNameFromDrawable == nil then return nil end
    local drawable, texture = top[1], top[2] or 0
    local name = GetPedCollectionNameFromDrawable(ped, 11, drawable)
    local idx = GetPedCollectionLocalIndexFromDrawable(ped, 11, drawable)
    if type(name) ~= 'string' or type(idx) ~= 'number' or idx < 0 then return nil end
    if name == '' or name == GetPedCollectionName(ped, 0) then name = 'base' end
    return ('https://cfx-nui-whip_media_clothing_%s/img/clothing/%s/11_tops/%s_11_%s_%03d_%02d.webp'):format(body, body, body, name, idx, texture)
end

local function itemInfo(key)
    local def = Whip.core:GetItemDef(key) or {}
    return {
        label = def.name or key,
        weight = def.weight,
        img = def.img or ('https://cfx-nui-whip_core/html/img/items/%s.png'):format(key),
    }
end

local function decorateItems(list)
    for _, it in ipairs(list or {}) do
        local info = itemInfo(it.item or it.key)
        it.label, it.weight, it.img = info.label, info.weight, info.img
    end
end

local function decorate(data)
    if type(data) ~= 'table' then return data end
    if data.pockets then decorateItems(data.pockets.items) end
    if data.store then decorateItems(data.store.items) end
    for _, tier in ipairs(data.tiers or {}) do decorateItems(tier.items) end
    if data.uniforms then
        local ped = PlayerPedId()
        local body = bodyOf(ped)
        for _, u in ipairs(data.uniforms) do
            local cfg = (Config.Uniforms[data.dept] or {})[u.i]
            local look = cfg and (body == 'female' and cfg.female or cfg.male)
            u.img = look and look.components and topPicture(ped, body, look.components[11])
        end
        data.ownImg = topPicture(ped, body, PWP.Wardrobe.ownTop())
        data.worn = PWP.Wardrobe.worn() or 'own'
    end
    for _, car in ipairs(data.cars or {}) do
        car.img = ('https://cfx-nui-whip_media_previews/img/vehicles/%s.webp'):format(car.model:lower())
    end
    if data.out then data.out.img = ('https://cfx-nui-whip_media_previews/img/vehicles/%s.webp'):format(data.out.model:lower()) end
    return data
end

local function close(tellServer)
    if not open then return end
    open = nil
    SetNuiFocus(false, false)
    Whip.core:SetScreenOpen(false, SCREEN)
    SendNUIMessage({ action = 'close' })
    if tellServer then CreateThread(function() Whip.core:Callback(ACT, 'close', {}) end) end
end

RegisterNetEvent(PWP.event('station'), function(data, at)
    if type(data) ~= 'table' or type(at) ~= 'table' then return end
    if not Whip.core:IsGameInputFree() and not open then return end
    open = { at = vector3(at.x, at.y, at.z), token = GetGameTimer() }
    SendNUIMessage({ action = 'open', data = decorate(data) })
    SetNuiFocus(true, true)
    Whip.core:SetScreenOpen(true, SCREEN)
    local token = open.token
    CreateThread(function()
        while open and open.token == token do
            local ped = PlayerPedId()
            if IsEntityDead(ped) or #(GetEntityCoords(ped) - open.at) > Config.PointReach + 3.0 then close(true) break end
            Wait(500)
        end
    end)
end)

RegisterNUICallback('act', function(body, cb)
    if not open or type(body) ~= 'table' or type(body.action) ~= 'string' then return cb({ ok = false, why = 'That is closed' }) end
    CreateThread(function()
        local result, why = Whip.core:Callback(ACT, body.action, type(body.args) == 'table' and body.args or {})
        if result == false or result == nil then return cb({ ok = false, why = why or 'Something went wrong' }) end
        cb({ ok = true, data = decorate(type(result) == 'table' and result or nil) })
    end)
end)

RegisterNUICallback('close', function(_, cb)
    close(true)
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and open then
        SetNuiFocus(false, false)
        Whip.core:SetScreenOpen(false, SCREEN)
    end
end)

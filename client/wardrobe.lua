local saved = nil

local function snapshot(ped)
    local s = { components = {}, props = {} }
    for slot = 0, 11 do
        s.components[slot] = { GetPedDrawableVariation(ped, slot), GetPedTextureVariation(ped, slot) }
    end
    for _, slot in ipairs({ 0, 1, 2, 6, 7 }) do
        s.props[slot] = { GetPedPropIndex(ped, slot), GetPedPropTextureIndex(ped, slot) }
    end
    return s
end

local function apply(ped, look)
    for slot, v in pairs(look.components or {}) do
        SetPedComponentVariation(ped, tonumber(slot), v[1], v[2] or 0, 0)
    end
    for slot, v in pairs(look.props or {}) do
        if v[1] == nil or v[1] < 0 then
            ClearPedProp(ped, tonumber(slot))
        else
            SetPedPropIndex(ped, tonumber(slot), v[1], v[2] or 0, true)
        end
    end
end

local worn = nil

RegisterNetEvent(PWP.event('uniform'), function(dept, index)
    local ped = PlayerPedId()
    if not dept then
        if saved then apply(ped, saved) end
        saved, worn = nil, nil
        return
    end
    local uniform = (Config.Uniforms[dept] or {})[index]
    if not uniform then return end
    local look = GetEntityModel(ped) == GetHashKey('mp_f_freemode_01') and uniform.female or uniform.male
    if not look then return end
    saved = saved or snapshot(ped)
    worn = index
    apply(ped, look)
end)

PWP.Wardrobe = {
    worn = function() return worn end,
    ownTop = function()
        if saved then return saved.components[11] end
        local ped = PlayerPedId()
        return { GetPedDrawableVariation(ped, 11), GetPedTextureVariation(ped, 11) }
    end,
}

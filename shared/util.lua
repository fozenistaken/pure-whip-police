PWP = {
    RES = GetCurrentResourceName(),
}

function PWP.name(suffix)
    return PWP.RES .. '_' .. suffix
end

function PWP.event(suffix)
    return PWP.RES .. ':' .. suffix
end

function PWP.isDept(key)
    return type(key) == 'string' and Config.Departments[key] ~= nil
end

function PWP.deptKeys()
    local keys = {}
    for key in pairs(Config.Departments) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

function PWP.courts()
    local res = Config.Providers.courts
    if type(res) ~= 'string' or res == 'none' or GetResourceState(res) ~= 'started' then return nil end
    return res
end

function PWP.dept(key)
    return Config.Departments[key]
end

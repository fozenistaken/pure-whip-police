PWP = PWP or {}

local Catalogue = {}
PWP.Catalogue = Catalogue

function Catalogue.allowed(entry, level, hasLicence)
    if type(entry) ~= 'table' then return false, 'Not available' end
    if (tonumber(level) or 0) < (entry.minLevel or 1) then return false, 'Your rank is too low for that' end
    if entry.licence and not hasLicence(entry.licence) then
        return false, ('You need the %s licence'):format(entry.licenceLabel or entry.licence)
    end
    return true
end

function Catalogue.rate(rates, level)
    local best = nil
    for _, r in ipairs(rates or {}) do
        if (tonumber(level) or 0) >= r.level and (not best or r.level > best.level) then best = r end
    end
    return best and best.amount or 0
end

return Catalogue

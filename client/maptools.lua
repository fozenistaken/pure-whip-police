RegisterCommand('pwp_interior', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local interior = GetInteriorAtCoords(pos.x, pos.y, pos.z)
    if interior == 0 then
        print('[pure-whip-police] not inside an interior here')
        return
    end
    local ix, iy, iz = GetInteriorPosition(interior)
    local rx, ry, rz, rw = GetInteriorRotation(interior)
    local line = ('interior %d at %.4f, %.4f, %.4f rotation %.4f, %.4f, %.4f, %.4f; you at %.2f, %.2f, %.2f heading %.1f')
        :format(interior, ix, iy, iz, rx, ry, rz, rw, pos.x, pos.y, pos.z, GetEntityHeading(ped))
    print('[pure-whip-police] ' .. line)
    Whip.core:Notify(line, 'info', 15000)
end, false)

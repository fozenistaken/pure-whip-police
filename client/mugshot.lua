local HEAD = 31086

RegisterNetEvent(PWP.event('mugshotTake'), function(target, token, partSize)
    local player = GetPlayerFromServerId(tonumber(target) or -1)
    local ped = player ~= -1 and GetPlayerPed(player) or 0
    if ped == 0 or type(token) ~= 'string' then return end
    CreateThread(function()
        local head = GetPedBoneCoords(ped, HEAD, 0.0, 0.0, 0.0)
        local fwd = GetEntityForwardVector(ped)
        local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', head.x + fwd.x * 0.85, head.y + fwd.y * 0.85, head.z + 0.03, 0.0, 0.0, 0.0, 38.0, false, 2)
        PointCamAtCoord(cam, head.x, head.y, head.z + 0.02)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
        Wait(350)
        local image = Whip.core:TakeScreenshot({ format = 'webp', quality = 0.82, width = 480 })
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        if type(image) ~= 'string' then return Whip.core:Notify('The camera failed: try again', 'error') end
        PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
        local n = math.ceil(#image / partSize)
        for i = 1, n do
            TriggerServerEvent(PWP.event('mugshotPart'), token, i, n, image:sub((i - 1) * partSize + 1, i * partSize))
            Wait(60)
        end
    end)
end)

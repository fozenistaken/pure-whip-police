RegisterCommand('+pwp_panic', function()
    if PWP.isDept(LocalPlayer.state.whipJob) then TriggerServerEvent(PWP.event('panic')) end
end, false)
RegisterCommand('-pwp_panic', function() end, false)
RegisterKeyMapping('+pwp_panic', 'Police: panic button', 'keyboard', '')

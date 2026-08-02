-- zenith-nui client message router and focus manager

RegisterNUICallback('pingBridge', function(data, cb)
    print("^3[zenith-nui] Received ping from NUI bridge. Replying...^7")
    
    -- Send back standard JSON response
    cb({ status = "ok" })
    
    -- Trigger client event or direct NUI send message to simulate core bridge behavior
    SendNUIMessage({
        type = "zenith:core:pong",
        payload = { success = true }
    })
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2[zenith-nui] NUI bridge client loaded. Callbacks registered.^7")
    end
end)

-- zenith-core Client-side entry
Zenith = {}

function Zenith.GetCoreObject()
    return Zenith
end

exports('GetCoreObject', function()
    return Zenith.GetCoreObject()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2[zenith-core] Core client bootstrap completed.^7")
    end
end)

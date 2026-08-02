-- zenith-core Server-side entry
Zenith = {}
Zenith.DB = {}
Zenith.Players = {}

function Zenith.GetCoreObject()
    return Zenith
end

exports('GetCoreObject', function()
    return Zenith.GetCoreObject()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2[zenith-core] Core bootstrap completed.^7")
    end
end)

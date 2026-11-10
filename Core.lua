
local addonName, FJ = ...

FJ.Name = addonName
FJ.Version = "0.8.0-rc.1"

function FJ.Initialize()
    FJ.Storage.Initialize()
    FJ.Launcher.Initialize()
end

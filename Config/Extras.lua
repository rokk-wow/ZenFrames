local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:GetDefaultConfig_Extras()
    return {
        waypoints = {
            enabled = true,
        },
    }
end

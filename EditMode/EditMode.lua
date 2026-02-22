local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.editMode = false

addon:RegisterSlashCommand("zf", function(self)
    self:EditModeCommand()
end)

function addon:EnableEditMode()
    self:CombatSafe(function()
        if addon.editMode then return end
        addon.editMode = true
        addon:ShowEditModeFrames()
        addon:Info("Entering Edit Mode")
    end)
end

function addon:DisableEditMode()
    if not self.editMode then return end
    if InCombatLockdown() then return end
    self.editMode = false
    self:HideEditModeFrames()
    self:Info("Leaving Edit Mode")
end

function addon:EditModeCommand()
    if self.editMode then
        self:DisableEditMode()
    else
        self:EnableEditMode()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    addon:DisableEditMode()
end)

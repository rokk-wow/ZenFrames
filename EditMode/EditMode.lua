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
        addon:ShowEditModeDialog()
        addon:Info("Entering Edit Mode")
    end)
end

function addon:DisableEditMode()
    if not self.editMode then return end
    if InCombatLockdown() then return end
    self.editMode = false
    self:HideEditModeDialog()
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
    local shouldResumeEditMode = false
    if addon.savedVars and addon.savedVars.data then
        shouldResumeEditMode = addon.savedVars.data.resumeEditModeAfterReload == true
        addon.savedVars.data.resumeEditModeAfterReload = nil
    end

    if shouldResumeEditMode then
        addon:EnableEditMode()
    else
        addon:DisableEditMode()
    end
end)

local escapeFrame = CreateFrame("Frame", "ZenFramesEditModeEscape", UIParent)
escapeFrame:EnableKeyboard(false)
escapeFrame:SetPropagateKeyboardInput(true)
escapeFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" and addon.editMode then
        self:SetPropagateKeyboardInput(false)
        addon:DisableEditMode()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

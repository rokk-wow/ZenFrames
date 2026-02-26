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
        addon:Info(addon:L("emEnteringEditMode"))
        
        -- Check for pending sub-dialog first (takes priority)
        if self.savedVars and self.savedVars.data and self.savedVars.data.reopenSubDialog then
            addon:CheckAndReopenSubDialog()
        else
            addon:CheckAndReopenSettingsDialog()
        end
    end)
end

function addon:DisableEditMode()
    if not self.editMode then return end
    if InCombatLockdown() then return end
    self.editMode = false
    self:HideEditModeDialog()
    self:HideEditModeFrames()
    self:Info(addon:L("emLeavingEditMode"))
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
        C_Timer.After(.5, function()
            addon:EnableEditMode()
        end)
    else
        addon:DisableEditMode()
    end
end)

local escapeFrame = CreateFrame("Frame", "ZenFramesEditModeEscape", UIParent)
escapeFrame:EnableKeyboard(false)
if not escapeFrame:IsProtected() then
    escapeFrame:SetPropagateKeyboardInput(true)
end
escapeFrame:SetScript("OnKeyDown", function(self, key)
    if InCombatLockdown() then
        return
    end
    
    if key == "ESCAPE" and addon.editMode then
        if not self:IsProtected() then
            self:SetPropagateKeyboardInput(false)
        end
        if addon:IsEditModeSettingsDialogShown() then
            addon:ReturnFromEditModeSettingsDialog()
            return
        end
        local closedSubDialog = addon:HideAllEditModeSubDialogs()
        if closedSubDialog then
            addon:ShowEditModeDialog()
            return
        end
        if not closedSubDialog then
            addon:DisableEditMode()
        end
    else
        if not self:IsProtected() then
            self:SetPropagateKeyboardInput(true)
        end
    end
end)

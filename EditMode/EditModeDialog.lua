local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Frame definitions: config key, localization key, default enabled
-- ---------------------------------------------------------------------------

local ENABLED_FRAMES = {
    { configKey = "party",  locKey = "partyEnabled" },
    { configKey = "arena",  locKey = "arenaEnabled" },
}

local DISABLED_FRAMES = {
    { configKey = "player",       locKey = "playerEnabled" },
    { configKey = "target",       locKey = "targetEnabled" },
    { configKey = "targetTarget", locKey = "targetTargetEnabled" },
    { configKey = "focus",        locKey = "focusEnabled" },
    { configKey = "focusTarget",  locKey = "focusTargetEnabled" },
    { configKey = "pet",          locKey = "petEnabled" },
}

-- ---------------------------------------------------------------------------
-- Visibility state (edit-mode only, not persisted)
-- ---------------------------------------------------------------------------

local visibilityState = {}
local initialEnabledState = {}
local dialog
local subDialog
local SUB_DIALOG_TITLE_FONT_SIZE = 16

local function ToPascalCase(value)
    if not value then return "" end

    local parts = {}
    for part in tostring(value):gmatch("[^_%-%s%.]+") do
        part = part:gsub("^%l", string.upper)
        parts[#parts + 1] = part
    end

    local merged = table.concat(parts)
    if merged == "" then
        return ""
    end

    return merged:gsub("^%l", string.upper)
end

local function GetConfigDisplayName(configKey)
    return ToPascalCase(configKey)
end

local function GetModuleDisplayName(moduleKey)
    return ToPascalCase(moduleKey)
end

local function BuildSubDialog()
    if subDialog then return subDialog end

    local width = dialog and dialog:GetWidth() or 320
    subDialog = addon:CreateDialog("ZenFramesEditModeSubDialog", "", width)
    subDialog:SetFrameStrata("TOOLTIP")
    subDialog:SetFrameLevel(300)
    subDialog.title:SetFont(subDialog._fontPath, SUB_DIALOG_TITLE_FONT_SIZE, "OUTLINE")

    if dialog then
        subDialog:SetSize(dialog:GetWidth(), dialog:GetHeight())
    end

    return subDialog
end

function addon:HideAllEditModeSubDialogs()
    if subDialog then
        local wasShown = subDialog:IsShown()
        subDialog:Hide()
        return wasShown
    end

    return false
end

function addon:ShowEditModeSubDialog(configKey, moduleKey)
    if not configKey then return end

    self:HideAllEditModeSubDialogs()

    local sub = BuildSubDialog()
    if dialog then
        sub:SetSize(dialog:GetWidth(), dialog:GetHeight())
    end

    local title = GetConfigDisplayName(configKey)
    if moduleKey then
        title = title .. "." .. GetModuleDisplayName(moduleKey)
    end
    sub.title:SetText(title)

    local cursorX = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local uiX = cursorX / scale
    local screenWidth = UIParent:GetWidth()
    local dialogX = (uiX <= screenWidth * 0.5) and (screenWidth * 0.75) or (screenWidth * 0.25)
    local dialogY = UIParent:GetHeight() * 0.5

    sub:ClearAllPoints()
    sub:SetPoint("CENTER", UIParent, "BOTTOMLEFT", dialogX, dialogY)
    sub:Show()
end

local function ResetVisibilityState()
    for k in pairs(visibilityState) do
        visibilityState[k] = nil
    end
end

local function CheckForChanges()
    if not dialog or not dialog._reloadButton then return end
    local changed = false
    for configKey, row in pairs(dialog._rows) do
        local current = row.checkbox:GetChecked()
        if current ~= initialEnabledState[configKey] then
            changed = true
            break
        end
    end
    if changed then
        dialog._reloadButton:Enable()
    else
        dialog._reloadButton:Disable()
    end
end

-- ---------------------------------------------------------------------------
-- Build dialog
-- ---------------------------------------------------------------------------

local function BuildDialog()
    if dialog then return dialog end

    local config = addon:GetConfig()
    dialog = addon:CreateDialog("ZenFramesEditModeDialog", addon:L("editModeDialogTitle"), 320)

    local y = dialog._contentTop

    local rows = {}

    local function AddRow(def)
        local isEnabled = config[def.configKey] and config[def.configKey].enabled
        local isVisible = true
        visibilityState[def.configKey] = isVisible

        local row
        row, y = addon:DialogAddToggleRow(
            dialog, y,
            addon:L(def.locKey),
            isEnabled,
            isVisible,
            function(checked)
                addon:SetOverride({ def.configKey, "enabled" }, checked)
                addon:SetOverride({ def.configKey, "hideBlizzard" }, checked)

                visibilityState[def.configKey] = checked
                addon:EditModeToggleFrameVisibility(def.configKey, checked)

                local r = rows[def.configKey]
                if r then
                    r.eye._visible = checked
                    r.eye.icon:SetAtlas(checked and "GM-icon-visible" or "GM-icon-visibleDis")
                end

                CheckForChanges()
            end,
            function(visible)
                visibilityState[def.configKey] = visible
                addon:EditModeToggleFrameVisibility(def.configKey, visible)
            end
        )
        rows[def.configKey] = row
    end

    local divider
    divider, y = addon:DialogAddDivider(dialog, y - 6)
    y = y - 6

    for _, def in ipairs(ENABLED_FRAMES) do
        AddRow(def)
    end

    local divider
    divider, y = addon:DialogAddDivider(dialog, y - 6)
    y = y - 6

    for _, def in ipairs(DISABLED_FRAMES) do
        AddRow(def)
    end

    dialog._rows = rows

    local reloadBtn
    reloadBtn, y = addon:DialogAddButton(dialog, y - 10, addon:L("reloadUI"), function()
        if addon.savedVars then
            addon.savedVars.data = addon.savedVars.data or {}
            addon.savedVars.data.resumeEditModeAfterReload = true
        end
        ReloadUI()
    end)
    reloadBtn:Disable()
    dialog._reloadButton = reloadBtn

    local credit = dialog:CreateFontString(nil, "OVERLAY")
    credit:SetFont(dialog._fontPath, 11, "OUTLINE")
    credit:SetPoint("TOP", dialog, "TOP", 0, y - 25)
    credit:SetTextColor(0.8, 0.8, 0.8)
    credit:SetText(addon:L("editModeAuthorCredit"))
    y = y - 34

    addon:DialogFinalize(dialog, y)

    return dialog
end

-- ---------------------------------------------------------------------------
-- Show / Hide
-- ---------------------------------------------------------------------------

function addon:ShowEditModeDialog()
    local dlg = BuildDialog()
    ResetVisibilityState()

    local config = self:GetConfig()
    for configKey, row in pairs(dlg._rows) do
        local isEnabled = config[configKey] and config[configKey].enabled
        row.checkbox:SetChecked(isEnabled)
        row.eye._visible = true
        row.eye.icon:SetAtlas("GM-icon-visible")
        visibilityState[configKey] = true
        initialEnabledState[configKey] = isEnabled
    end

    dlg._reloadButton:Disable()
    dlg:Show()
end

function addon:HideEditModeDialog()
    self:HideAllEditModeSubDialogs()

    if dialog then
        dialog:Hide()
    end
    ResetVisibilityState()
end

-- ---------------------------------------------------------------------------
-- Toggle frame visibility in edit mode
-- ---------------------------------------------------------------------------

function addon:EditModeToggleFrameVisibility(configKey, visible)
    if self.unitFrames then
        for unit, frame in pairs(self.unitFrames) do
            local unitConfig = ({
                player = "player",
                target = "target",
                targettarget = "targetTarget",
                focus = "focus",
                focustarget = "focusTarget",
                pet = "pet",
            })[unit]
            if unitConfig == configKey then
                if visible then
                    frame:SetAlpha(1)
                else
                    frame:SetAlpha(0)
                end
            end
        end
    end

    if self.groupContainers then
        local container = self.groupContainers[configKey]
        if container then
            if visible then
                container:SetAlpha(1)
            else
                container:SetAlpha(0)
            end
        end
    end
end

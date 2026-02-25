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

    addon:RefreshConfig()
    dialog = addon:CreateEditModeSubDialog("ZenFramesEditModeDialog", addon:L("editModeDialogTitle"), {
        width = 320,
        showBackButton = false,
    })
    addon._editModeDialog = dialog

    local titleIcon = dialog:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(24, 24)
    titleIcon:SetAtlas("mechagon-projects")
    titleIcon:SetPoint("CENTER", dialog, "TOPLEFT", dialog._borderWidth + dialog._padding + 14, -(dialog._borderWidth + dialog._padding + 11))
    titleIcon:SetDesaturated(true)
    dialog._titleIcon = titleIcon

    local titleHover = CreateFrame("Frame", nil, dialog)
    titleHover:SetPoint("TOPLEFT", titleIcon, "TOPLEFT", 0, 0)
    titleHover:SetPoint("BOTTOMRIGHT", titleIcon, "BOTTOMRIGHT", 0, 0)
    titleHover:EnableMouse(true)
    titleHover:SetScript("OnEnter", function()
        titleIcon:SetDesaturated(false)
    end)
    titleHover:SetScript("OnLeave", function()
        titleIcon:SetDesaturated(true)
    end)
    titleHover:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        addon:ShowEditModeSettingsDialog()
    end)
    dialog._titleHover = titleHover

    local y = dialog._contentAreaTopOffset

    local rows = {}

    local function AddRow(def)
        local isEnabled = addon.config[def.configKey] and addon.config[def.configKey].enabled
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
    if InCombatLockdown() then return end

    -- Get position of any currently open dialog BEFORE building main dialog
    -- (BuildDialog returns singleton, so we need position before we get the frame)
    local centerX, centerY = self:GetOpenConfigDialogCenter(nil)

    local dlg = BuildDialog()
    self:HideOpenConfigDialogs(dlg)
    ResetVisibilityState()

    self:RefreshConfig()
    for configKey, row in pairs(dlg._rows) do
        local isEnabled = self.config[configKey] and self.config[configKey].enabled
        row.checkbox:SetChecked(isEnabled)
        row.eye._visible = true
        row.eye.icon:SetAtlas("GM-icon-visible")
        visibilityState[configKey] = true
        initialEnabledState[configKey] = isEnabled
    end

    dlg._reloadButton:Disable()

    if centerX and centerY then
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    else
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    dlg:Show()
end

function addon:HideEditModeDialog()
    if InCombatLockdown() then return end

    self:HideEditModeSettingsDialog()
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
    if InCombatLockdown() then return end
    
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

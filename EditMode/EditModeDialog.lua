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
local confirmDialog
local SUB_DIALOG_TITLE_FONT_SIZE = 16
local CONFIRM_DIALOG_TITLE_FONT_SIZE = 18

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

    local resetY = -(subDialog:GetHeight() - subDialog._borderWidth - subDialog._padding)
    local resetBtn = addon:DialogAddButton(subDialog, resetY, addon:L("resetButton"), function()
        if subDialog._configKey then
            addon:ShowResetConfirmDialog(subDialog._configKey, subDialog._moduleKey)
        end
    end)
    subDialog._resetButton = resetBtn

    return subDialog
end

local function BuildConfirmDialog()
    if confirmDialog then return confirmDialog end

    local width = 350
    confirmDialog = addon:CreateDialog("ZenFramesResetConfirmDialog", "", width)
    confirmDialog:SetFrameStrata("FULLSCREEN")
    confirmDialog:SetFrameLevel(500)
    confirmDialog.title:SetFont(confirmDialog._fontPath, CONFIRM_DIALOG_TITLE_FONT_SIZE, "OUTLINE")
    confirmDialog.title:SetText(addon:L("resetButton"))

    -- Message text
    local msgY = confirmDialog._contentTop
    local message = confirmDialog:CreateFontString(nil, "OVERLAY")
    message:SetFont(confirmDialog._fontPath, 14, "OUTLINE")
    message:SetTextColor(1, 1, 1)
    message:SetPoint("TOP", confirmDialog, "TOP", 0, msgY)
    message:SetWidth(width - 2 * (confirmDialog._borderWidth + confirmDialog._padding))
    message:SetJustifyH("LEFT")
    message:SetWordWrap(true)
    message:SetText(addon:L("resetConfirmText"))
    confirmDialog.message = message

    local msgHeight = message:GetStringHeight()
    local buttonY = msgY - msgHeight - 15

    -- Two buttons side by side
    local buttonWidth = (width - 2 * (confirmDialog._borderWidth + confirmDialog._padding) - 10) / 2
    local buttonHeight = 28

    -- Reset button (left side)
    local resetBtn = CreateFrame("Button", nil, confirmDialog, "UIPanelButtonTemplate")
    resetBtn:SetSize(buttonWidth, buttonHeight)
    resetBtn:SetPoint("TOPLEFT", confirmDialog, "TOPLEFT", confirmDialog._borderWidth + confirmDialog._padding, buttonY)
    resetBtn:SetText(addon:L("resetButton"))
    resetBtn:GetFontString():SetFont(confirmDialog._fontPath, 13, "OUTLINE")
    resetBtn:SetScript("OnClick", function()
        if confirmDialog.onConfirm then
            confirmDialog.onConfirm()
        end
        confirmDialog:Hide()
    end)
    confirmDialog.resetButton = resetBtn

    -- Cancel button (right side)
    local cancelBtn = CreateFrame("Button", nil, confirmDialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(buttonWidth, buttonHeight)
    cancelBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:GetFontString():SetFont(confirmDialog._fontPath, 13, "OUTLINE")
    cancelBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
    end)
    confirmDialog.cancelButton = cancelBtn

    -- Size the dialog to fit
    local totalHeight = math.abs(buttonY - buttonHeight) + confirmDialog._borderWidth + confirmDialog._padding
    confirmDialog:SetHeight(totalHeight)

    -- Handle Escape key
    confirmDialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    confirmDialog:EnableKeyboard(true)

    confirmDialog:SetScript("OnShow", function(self)
        self:SetPropagateKeyboardInput(false)
    end)

    confirmDialog:SetScript("OnHide", function(self)
        self:SetPropagateKeyboardInput(true)
        self.onConfirm = nil
    end)

    return confirmDialog
end

function addon:ShowResetConfirmDialog(configKey, moduleKey)
    local confirm = BuildConfirmDialog()
    
    confirm.onConfirm = function()
        local cfg = self.config[configKey]
        local targetCfg = cfg
        
        -- Handle auraFilters (stored as arrays)
        local isAuraFilter = false
        local auraFilterIndex = nil
        if moduleKey and cfg.modules and cfg.modules.auraFilters then
            for i, filter in ipairs(cfg.modules.auraFilters) do
                if filter.name == moduleKey then
                    targetCfg = filter
                    isAuraFilter = true
                    auraFilterIndex = i
                    break
                end
            end
        end
        
        -- If not an auraFilter, check regular modules
        if not isAuraFilter and moduleKey and cfg.modules and cfg.modules[moduleKey] then
            targetCfg = cfg.modules[moduleKey]
        end
        
        local preserveEnabled = targetCfg.enabled
        local preserveHideBlizzard = targetCfg.hideBlizzard
        
        if isAuraFilter then
            self:ClearOverrides({configKey, "modules", "auraFilters", auraFilterIndex})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "modules", "auraFilters", auraFilterIndex, "enabled"}, preserveEnabled)
            end
            if preserveHideBlizzard ~= nil then
                self:SetOverride({configKey, "modules", "auraFilters", auraFilterIndex, "hideBlizzard"}, preserveHideBlizzard)
            end
        elseif moduleKey then
            self:ClearOverrides({configKey, "modules", moduleKey})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "modules", moduleKey, "enabled"}, preserveEnabled)
            end
            if preserveHideBlizzard ~= nil then
                self:SetOverride({configKey, "modules", moduleKey, "hideBlizzard"}, preserveHideBlizzard)
            end
        else
            self:ClearOverrides({configKey})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "enabled"}, preserveEnabled)
            end
            if preserveHideBlizzard ~= nil then
                self:SetOverride({configKey, "hideBlizzard"}, preserveHideBlizzard)
            end
        end
        
        self.config = self:GetConfig()
        
        if moduleKey then
            self:RefreshModule(configKey, moduleKey)
            
            -- For group frame modules (party/arena), also reposition all instances
            if configKey == "party" or configKey == "arena" then
                local containerName = configKey == "party" and "zfPartyContainer" or "zfArenaContainer"
                local container = _G[containerName]
                
                if container and container.frames then
                    -- Get the DEFAULT module config (without any overrides)
                    local defaultConfig = self:GetDefaultConfig()
                    local defaultFrameCfg = defaultConfig[configKey]
                    
                    local moduleCfg = defaultFrameCfg.modules[moduleKey]
                    if not moduleCfg then
                        -- Check if it's an auraFilter
                        if isAuraFilter and auraFilterIndex then
                            moduleCfg = defaultFrameCfg.modules.auraFilters[auraFilterIndex]
                        end
                    end
                    
                    if moduleCfg then
                        local anchorPoint = moduleCfg.anchor
                        local relativePoint = moduleCfg.relativePoint
                        local offsetX = moduleCfg.offsetX or 0
                        local offsetY = moduleCfg.offsetY or 0
                        
                        -- Convert module key to PascalCase to access frame property
                        local moduleName = moduleKey:sub(1, 1):upper() .. moduleKey:sub(2)
                        
                        for i, unitFrame in ipairs(container.frames) do
                            local module = unitFrame[moduleName]
                            
                            if module and anchorPoint and relativePoint then
                                -- Determine the anchor frame for this module instance
                                local moduleAnchorFrame = unitFrame
                                
                                -- DEPRECATED: relativeToModule is deprecated but supported for backwards compatibility
                                if moduleCfg.relativeToModule then
                                    local ref = moduleCfg.relativeToModule
                                    if type(ref) == "table" then
                                        for _, key in ipairs(ref) do
                                            if unitFrame[key] then
                                                moduleAnchorFrame = unitFrame[key]
                                                break
                                            end
                                        end
                                    else
                                        moduleAnchorFrame = unitFrame[ref] or unitFrame
                                    end
                                end
                                
                                local moduleRelativeFrame = moduleCfg.relativeTo and _G[moduleCfg.relativeTo] or moduleAnchorFrame
                                
                                if moduleRelativeFrame then
                                    module:ClearAllPoints()
                                    module:SetPoint(anchorPoint, moduleRelativeFrame, relativePoint, offsetX, offsetY)
                                end
                            end
                        end
                    end
                end
            end
        else
            self:RefreshFrame(configKey)
        end
    end
    
    confirm:Show()
end

function addon:HideAllEditModeSubDialogs()
    if confirmDialog then
        confirmDialog:Hide()
    end
    
    if subDialog then
        local wasShown = subDialog:IsShown()
        subDialog:Hide()
        return wasShown
    end

    return false
end

function addon:ShowEditModeSubDialog(configKey, moduleKey)
    if not configKey then return end

    local existingX, existingY
    if subDialog and subDialog:IsShown() then
        local left = subDialog:GetLeft()
        local bottom = subDialog:GetBottom()
        local width = subDialog:GetWidth()
        local height = subDialog:GetHeight()
        
        if left and bottom and width and height then
            existingX = left + (width / 2)
            existingY = bottom + (height / 2)
        end
    end

    self:HideAllEditModeSubDialogs()

    local sub = BuildSubDialog()
    if dialog then
        sub:SetSize(dialog:GetWidth(), dialog:GetHeight())
    end

    sub._configKey = configKey
    sub._moduleKey = moduleKey

    local title = GetConfigDisplayName(configKey)
    if moduleKey then
        title = title .. " > " .. GetModuleDisplayName(moduleKey)
    end
    sub.title:SetText(title)

    local dialogX, dialogY
    if existingX and existingY then
        dialogX = existingX
        dialogY = existingY
    else
        local cursorX = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local uiX = cursorX / scale
        local screenWidth = UIParent:GetWidth()
        dialogX = (uiX <= screenWidth * 0.5) and (screenWidth * 0.75) or (screenWidth * 0.25)
        dialogY = UIParent:GetHeight() * 0.5
    end

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

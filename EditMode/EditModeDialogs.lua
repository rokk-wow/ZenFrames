local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local ZDS = addon.DialogStyle
addon.EDIT_MODE_DIALOG_HEIGHT = addon.EDIT_MODE_DIALOG_HEIGHT or 525
local EDIT_MODE_DIALOG_HEIGHT = addon.EDIT_MODE_DIALOG_HEIGHT

-- ---------------------------------------------------------------------------
-- Edit mode sub-dialog width resolver
-- ---------------------------------------------------------------------------

local function ResolveEditModeSubDialogWidth(sizeMode, explicitWidth)
    if type(explicitWidth) == "number" and explicitWidth > 0 then
        return explicitWidth
    end

    local baseWidth = (ZDS and ZDS.DIALOG_WIDTH_1_COL) or 300

    if sizeMode == "large" then
        return (ZDS and ZDS.DIALOG_WIDTH_2_COL) or 600
    end

    return baseWidth
end

function addon:CreateEditModeSubDialog(name, titleText, options)
    options = options or {}

    local width = ResolveEditModeSubDialogWidth(options.sizeMode, options.width)

    local leftIcon = nil
    if options.showBackButton ~= false then
        leftIcon = {
            atlas = "CreditsScreen-Assets-Buttons-Play",
            size = 20,
            rotation = math.pi,
            desaturated = true,
            onClick = options.onBackClick,
        }
    end

    local dialog = self:CreateDialog({
        name = name,
        title = titleText or "",
        titleFontSize = options.titleFontSize,
        width = width,
        height = options.height or EDIT_MODE_DIALOG_HEIGHT,
        frameStrata = options.frameStrata or "TOOLTIP",
        frameLevel = options.frameLevel or 300,
        showCloseButton = true,
        onCloseClick = options.onCloseClick,
        leftIcon = leftIcon,
    })

    return dialog
end

-- ---------------------------------------------------------------------------
-- Edit mode sub-dialog infrastructure
-- ---------------------------------------------------------------------------

local subDialog
local SUB_DIALOG_TITLE_FONT_SIZE = 16

local MODULE_SUB_DIALOG_METHODS = {
    arenaTargets = "PopulateArenaTargetsSubDialog",
    castbar = "PopulateCastbarSubDialog",
    combatIndicator = "PopulateCombatIndicatorSubDialog",
    dispelIcon = "PopulateDispelIconSubDialog",
    drTracker = "PopulateDRTrackerSubDialog",
    restingIndicator = "PopulateRestingIndicatorSubDialog",
    roleIcon = "PopulateRoleIconSubDialog",
    trinket = "PopulateTrinketSubDialog",
}

local MODULE_RESET_REFRESH_METHODS = {
    arenaTargets = "RefreshArenaTargetsEditModeVisuals",
    castbar = "RefreshCastbarEditModeVisuals",
    dispelIcon = "RefreshDispelIconEditModeVisuals",
    drTracker = "RefreshDRTrackerEditModeVisuals",
    roleIcon = "RefreshRoleIconEditModeVisuals",
    trinket = "RefreshTrinketEditModeVisuals",
}

local UNIT_FRAME_SUB_DIALOG_METHODS = {
    party = "PopulatePartySubDialog",
    arena = "PopulatePartySubDialog",
}

local function IsAuraFilterModule(configKey, moduleKey)
    if not configKey or not moduleKey then
        return false
    end

    local cfg = addon.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.auraFilters then
        return false
    end

    for _, filterCfg in ipairs(cfg.modules.auraFilters) do
        if filterCfg.name == moduleKey then
            return true
        end
    end

    return false
end

local function IsTextModule(configKey, moduleKey)
    if not configKey or not moduleKey then
        return false
    end

    local cfg = addon.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.text then
        return false
    end

    for _, textCfg in ipairs(cfg.modules.text) do
        if textCfg.name == moduleKey then
            return true
        end
    end

    return false
end

local LARGE_SUB_DIALOG_MODULES = {
    castbar = true,
}

local LARGE_SUB_DIALOG_CONFIGS = {
    party = true,
    arena = true,
    player = true,
    target = true,
    targetTarget = true,
    focus = true,
    focusTarget = true,
    pet = true,
}

local function ShouldUseLargeSubDialog(configKey, moduleKey)
    if not moduleKey then
        return LARGE_SUB_DIALOG_CONFIGS[configKey] == true
    end

    if LARGE_SUB_DIALOG_MODULES[moduleKey] == true then
        return true
    end

    return IsAuraFilterModule(configKey, moduleKey)
end

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

local function GetModuleFrameName(moduleKey)
    if not moduleKey then return nil end

    if moduleKey == "drTracker" then
        return "DRTracker"
    end

    return moduleKey:sub(1, 1):upper() .. moduleKey:sub(2)
end

local function RefreshTextureBorders(frame, cfg)
    if not frame or not cfg or not cfg.modules then return end

    local trinketCfg = cfg.modules.trinket
    if trinketCfg and frame.Trinket then
        addon:AddTextureBorder(frame.Trinket, trinketCfg.borderWidth, trinketCfg.borderColor)
    end

    local arenaTargetsCfg = cfg.modules.arenaTargets
    if arenaTargetsCfg and frame.ArenaTargets and frame.ArenaTargets.widget and frame.ArenaTargets.widget.indicators then
        local borderWidth = arenaTargetsCfg.borderWidth
        local borderColor = arenaTargetsCfg.borderColor
        for _, indicator in ipairs(frame.ArenaTargets.widget.indicators) do
            if indicator.Inner then
                indicator.Inner:ClearAllPoints()
                indicator.Inner:SetPoint("TOPLEFT", borderWidth, -borderWidth)
                indicator.Inner:SetPoint("BOTTOMRIGHT", -borderWidth, borderWidth)
            end
            addon:AddTextureBorder(indicator, borderWidth, borderColor)
        end
    end

    local drCfg = cfg.modules.drTracker
    if drCfg and frame.DRTracker then
        addon:AddTextureBorder(frame.DRTracker, drCfg.containerBorderWidth, drCfg.containerBorderColor)
    end

    if cfg.modules.auraFilters then
        for _, filterCfg in ipairs(cfg.modules.auraFilters) do
            if filterCfg.enabled and filterCfg.name then
                local filter = frame[filterCfg.name]
                if filter and filter.icons then
                    for _, icon in pairs(filter.icons) do
                        addon:AddTextureBorder(icon, filterCfg.borderWidth, filterCfg.borderColor)
                    end
                end
            end
        end
    end
end

local function ClearSubDialogControls()
    if not subDialog then return end

    if subDialog._controls then
        for _, control in ipairs(subDialog._controls) do
            control:Hide()
            control:SetParent(nil)
        end
    end
    
    subDialog._controls = {}
end

local function BuildSubDialog()
    if subDialog then return subDialog end

    local mainDialog = addon._editModeDialog
    subDialog = addon:CreateEditModeSubDialog("ZenFramesEditModeSubDialog", "", {
        sizeMode = "normal",
        onBackClick = function()
            addon:ReturnFromEditModeSubDialog()
        end,
        onCloseClick = function()
            addon:ReturnFromEditModeSubDialog()
        end,
    })
    addon._editModeSubDialog = subDialog

    if mainDialog then
        subDialog:SetSize(mainDialog:GetWidth(), mainDialog:GetHeight())
    end

    local resetIconSize = 32
    local resetPadding = 10
    local resetY = -(subDialog:GetHeight() - subDialog._borderWidth - resetPadding - resetIconSize)
    local resetBtn = addon:DialogAddTextureButton(subDialog, 0, {
        atlas = "UI-RefreshButton",
        width = resetIconSize,
        height = resetIconSize,
        desaturate = true,
        parent = subDialog,
        anchor = "TOP",
        attachTo = "TOP",
        offsetX = 0,
        offsetY = resetY,
        onClick = function()
            if subDialog._configKey then
                addon:ShowResetConfirmDialog(subDialog._configKey, subDialog._moduleKey)
            end
        end,
    })
    subDialog._resetButton = resetBtn

    return subDialog
end

function addon:HideAllEditModeSubDialogs()
    if InCombatLockdown() then return false end

    if subDialog then
        local wasShown = subDialog:IsShown()
        ClearSubDialogControls()
        subDialog:Hide()
        return wasShown
    end

    return false
end

local function GetDialogCenter(frame)
    if not frame then return nil, nil end

    local centerX, centerY = frame:GetCenter()
    if centerX and centerY then
        return centerX, centerY
    end

    local left = frame:GetLeft()
    local bottom = frame:GetBottom()
    local width = frame:GetWidth()
    local height = frame:GetHeight()

    if not left or not bottom or not width or not height then
        return nil, nil
    end

    return left + (width / 2), bottom + (height / 2)
end

function addon:GetOpenEditModeDialogCenter(excludedDialog)
    return self:GetOpenConfigDialogCenter(excludedDialog)
end

function addon:GetOpenConfigDialogCenter(excludedDialog)
    local candidates = {
        { name = "settings", frame = self._editModeSettingsDialog },
        { name = "sub", frame = self._editModeSubDialog },
        { name = "main", frame = self._editModeDialog },
    }

    for _, candidate in ipairs(candidates) do
        local dialog = candidate.frame

        if dialog and dialog ~= excludedDialog and dialog:IsShown() then
            local centerX, centerY = GetDialogCenter(dialog)
            if centerX and centerY then
                return centerX, centerY
            end
        end
    end

    -- Fallback for transient handoff states where source dialog may already report shown=false
    -- but still has valid geometry for position continuity.
    for _, candidate in ipairs(candidates) do
        local dialog = candidate.frame
        if dialog and dialog ~= excludedDialog then
            local centerX, centerY = GetDialogCenter(dialog)
            if centerX and centerY then
                return centerX, centerY
            end
        end
    end

    return nil, nil
end

function addon:HideOpenConfigDialogs(excludedDialog)
    if InCombatLockdown() then return false end

    local hiddenAny = false

    local settingsDialog = self._editModeSettingsDialog
    if settingsDialog and settingsDialog ~= excludedDialog and settingsDialog:IsShown() then
        settingsDialog:Hide()
        hiddenAny = true
    end

    if subDialog and subDialog ~= excludedDialog and subDialog:IsShown() then
        ClearSubDialogControls()
        subDialog:Hide()
        hiddenAny = true
    end

    local mainDialog = self._editModeDialog
    if mainDialog and mainDialog ~= excludedDialog and mainDialog:IsShown() then
        mainDialog:Hide()
        hiddenAny = true
    end

    return hiddenAny
end

function addon:ReturnFromEditModeSubDialog()
    if InCombatLockdown() then return end

    local centerX, centerY = GetDialogCenter(subDialog)
    self:HideAllEditModeSubDialogs()
    self:ShowEditModeDialog()

    local mainDialog = self._editModeDialog
    if mainDialog and centerX and centerY then
        mainDialog:ClearAllPoints()
        mainDialog:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    end
end

function addon:ShowEditModeSubDialog(configKey, moduleKey)
    if InCombatLockdown() then return end
    if not configKey then return end

    if self._textTagHelpDialog and self._textTagHelpDialog:IsShown() then
        self._textTagHelpDialog:Hide()
    end

    -- Get position of any currently open dialog BEFORE building sub-dialog
    -- (BuildSubDialog returns singleton, so we need position before we get the frame)
    local centerX, centerY = self:GetOpenConfigDialogCenter(nil)

    local sub = BuildSubDialog()
    self:HideOpenConfigDialogs(sub)
    local mainDialog = addon._editModeDialog
    local height = (mainDialog and mainDialog:GetHeight()) or sub:GetHeight()
    if height < EDIT_MODE_DIALOG_HEIGHT then
        height = EDIT_MODE_DIALOG_HEIGHT
    end
    local sizeMode = ShouldUseLargeSubDialog(configKey, moduleKey) and "large" or "normal"
    local width = ResolveEditModeSubDialogWidth(sizeMode)
    sub:SetSize(width, height)

    -- Create or remove columns based on sizeMode
    if sizeMode == "large" then
        -- Create columns if they don't exist
        if not sub._leftColumn then
            local columnGap = ZDS.COLUMN_GAP
            local columnWidth = (width - 2 * (sub._borderWidth + sub._padding) - columnGap) / 2

            local leftColumn = CreateFrame("Frame", nil, sub)
            leftColumn:SetPoint("TOPLEFT", sub, "TOPLEFT", sub._borderWidth + sub._padding, sub._contentTop)
            leftColumn:SetSize(columnWidth, 1)
            leftColumn._fontPath = sub._fontPath
            leftColumn._isDialogColumn = true
            sub._leftColumn = leftColumn

            local rightColumn = CreateFrame("Frame", nil, sub)
            rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", columnGap, 0)
            rightColumn:SetSize(columnWidth, 1)
            rightColumn._fontPath = sub._fontPath
            rightColumn._isDialogColumn = true
            sub._rightColumn = rightColumn
        else
            -- Update column widths if they exist
            local columnGap = ZDS.COLUMN_GAP
            local columnWidth = (width - 2 * (sub._borderWidth + sub._padding) - columnGap) / 2
            sub._leftColumn:SetWidth(columnWidth)
            sub._rightColumn:SetWidth(columnWidth)
        end
    else
        -- Remove columns for normal sizeMode
        if sub._leftColumn then
            sub._leftColumn:Hide()
            sub._leftColumn = nil
        end
        if sub._rightColumn then
            sub._rightColumn:Hide()
            sub._rightColumn = nil
        end
    end

    sub.title:SetWidth(width - 2 * (sub._borderWidth + sub._padding) - 60)

    if sub._resetButton then
        local resetIconSize = 32
        local resetPadding = 10
        local resetY = -(height - sub._borderWidth - resetPadding - resetIconSize)
        sub._resetButton:ClearAllPoints()
        sub._resetButton:SetPoint("TOP", sub, "TOP", 0, resetY)
    end

    sub._configKey = configKey
    sub._moduleKey = moduleKey

    -- Title is just the frame name
    local title = GetConfigDisplayName(configKey)
    sub.title:SetText(title)

    sub:ClearAllPoints()
    if centerX and centerY then
        sub:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    else
        sub:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    ClearSubDialogControls()
    
    local contentY = sub._contentTop
    
    -- Add section title (module name) if present, otherwise add spacer for consistent positioning
    if moduleKey then
        local sectionTitle
        sectionTitle, contentY = self:DialogAddSectionTitle(sub, contentY, GetModuleDisplayName(moduleKey))
        table.insert(sub._controls, sectionTitle)
    else
        local spacer
        spacer, contentY = self:DialogAddSpacer(sub, contentY)
        table.insert(sub._controls, spacer)
    end

    -- For large dialogs with columns, convert contentY from dialog-relative to column-relative.
    -- Column frames are already positioned at _contentTop from the dialog TOP,
    -- so controls inside them need yOffset relative to the column's TOP, not the dialog's TOP.
    if sizeMode == "large" and sub._leftColumn and sub._contentTop then
        contentY = contentY - sub._contentTop
    end
    
    if not moduleKey then
        local unitFrameMethod = UNIT_FRAME_SUB_DIALOG_METHODS[configKey]
        if unitFrameMethod and self[unitFrameMethod] then
            self[unitFrameMethod](self, subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        elseif self.PopulateUnitFrameSubDialog then
            self:PopulateUnitFrameSubDialog(subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        end
    elseif IsAuraFilterModule(configKey, moduleKey) then
        if self.PopulateAuraFilterSubDialog then
            self:PopulateAuraFilterSubDialog(subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        end
    elseif IsTextModule(configKey, moduleKey) then
        if self.PopulateTextSubDialog then
            self:PopulateTextSubDialog(sub, configKey, moduleKey, contentY)
        end
    else
        local methodName = MODULE_SUB_DIALOG_METHODS[moduleKey]
        if methodName and self[methodName] then
            self[methodName](self, subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        end
    end

    sub:Show()
end

function addon:ShowResetConfirmDialog(configKey, moduleKey)
    if InCombatLockdown() then return end

    self:ShowDialogConfirm({
        title = "resetButton",
        body = "resetConfirmText",
        confirmText = "resetButton",
        height = 250,
        onConfirm = function()
        local cfg = self.config[configKey]
        local targetCfg = cfg

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

        local isTextModule = false
        local textIndex = nil
        if not isAuraFilter and moduleKey and cfg.modules and cfg.modules.text then
            for i, textCfg in ipairs(cfg.modules.text) do
                if textCfg.name == moduleKey then
                    targetCfg = textCfg
                    isTextModule = true
                    textIndex = i
                    break
                end
            end
        end

        if not isAuraFilter and not isTextModule and moduleKey and cfg.modules and cfg.modules[moduleKey] then
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
        elseif isTextModule then
            self:ClearOverrides({configKey, "modules", "text", textIndex})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "modules", "text", textIndex, "enabled"}, preserveEnabled)
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

        self:RefreshConfig()

        if moduleKey then
            self:RefreshModule(configKey, moduleKey)

            if configKey == "party" or configKey == "arena" then
                local containerName = configKey == "party" and "zfPartyContainer" or "zfArenaContainer"
                local container = _G[containerName]

                if container and container.frames then
                    local frameCfg = self.config[configKey]
                    local defaultFrameCfg = self:GetDefaultConfig()[configKey]

                    local moduleCfg = frameCfg.modules[moduleKey]
                    if not moduleCfg then
                        if isAuraFilter and auraFilterIndex then
                            moduleCfg = defaultFrameCfg.modules.auraFilters[auraFilterIndex]
                        end
                    end

                    if moduleCfg then
                        local anchorPoint = moduleCfg.anchor
                        local relativePoint = moduleCfg.relativePoint
                        local offsetX = moduleCfg.offsetX or 0
                        local offsetY = moduleCfg.offsetY or 0
                        local moduleName = GetModuleFrameName(moduleKey)

                        for _, unitFrame in ipairs(container.frames) do
                            local module = unitFrame[moduleName]

                            if module and anchorPoint and relativePoint then
                                local moduleAnchorFrame = unitFrame

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

            if isAuraFilter then
                if self.RefreshAuraFilterEditModeVisuals then
                    self:RefreshAuraFilterEditModeVisuals(configKey, moduleKey)
                end
            elseif isTextModule then
                if self.RefreshTextEditModeVisuals then
                    self:RefreshTextEditModeVisuals(configKey, moduleKey)
                end
            else
                local refreshMethod = MODULE_RESET_REFRESH_METHODS[moduleKey]
                if refreshMethod and self[refreshMethod] then
                    self[refreshMethod](self, configKey, moduleKey)
                end
            end
        else
            self:RefreshFrame(configKey)

            if (configKey == "party" or configKey == "arena") and self.RefreshGroupContainerVisuals then
                self:RefreshGroupContainerVisuals(configKey)
            end
        end

        if self.editMode then
            local frameCfg = self.config and self.config[configKey]
            if frameCfg then
                if configKey == "party" or configKey == "arena" then
                    local container = self.groupContainers and self.groupContainers[configKey]
                    if container and container.frames then
                        for _, unitFrame in ipairs(container.frames) do
                            RefreshTextureBorders(unitFrame, frameCfg)
                        end
                    end
                else
                    local frame = frameCfg.frameName and _G[frameCfg.frameName]
                    if frame then
                        RefreshTextureBorders(frame, frameCfg)
                    end
                end
            end
        end

        if subDialog and subDialog:IsShown() then
            self:ShowEditModeSubDialog(configKey, moduleKey)
        end
        end,
    })
end

-- ---------------------------------------------------------------------------
-- Sub-dialog state persistence for reload workflow
-- ---------------------------------------------------------------------------

function addon:SetPendingSubDialogReopen(configKey, moduleKey)
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.reopenSubDialog = {
        configKey = configKey,
        moduleKey = moduleKey
    }
end

function addon:CheckAndReopenSubDialog()
    if not self.savedVars or not self.savedVars.data then return end
    
    local reopenData = self.savedVars.data.reopenSubDialog
    if reopenData and reopenData.configKey then
        local configKey = reopenData.configKey
        local moduleKey = reopenData.moduleKey
        
        -- Clear the flag
        self.savedVars.data.reopenSubDialog = nil
        
        -- Reopen the sub-dialog
        self:ShowEditModeSubDialog(configKey, moduleKey)
    end
end

-- ---------------------------------------------------------------------------
-- Edit mode reload helpers for enable controls
-- ---------------------------------------------------------------------------

function addon:EditModeReloadForPendingChange(configKey, moduleKey)
    self:SetPendingSubDialogReopen(configKey, moduleKey)
    if self.savedVars and self.savedVars.data then
        self.savedVars.data.resumeEditModeAfterReload = true
    end
    ReloadUI()
end

function addon:EditModeEnableButtonClick(configKey, moduleKey, onChange)
    return function(currentChecked, originalChecked, row)
        if originalChecked and not currentChecked then
            addon:ShowDialogConfirm({
                title = "reloadUI",
                body = "disableModuleConfirmText",
                confirmText = "reloadUI",
                height = 250,
                onConfirm = function()
                    addon:EditModeReloadForPendingChange(configKey, moduleKey)
                end,
                onCancel = function()
                    row.checkbox:SetChecked(originalChecked)
                    if onChange then
                        onChange(originalChecked)
                    end
                    row.actionButton:Disable()
                    row.actionButton:SetAlpha(0.5)
                end,
            })
            return
        end
        addon:EditModeReloadForPendingChange(configKey, moduleKey)
    end
end

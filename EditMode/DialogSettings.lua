local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local settingsDialog
local COLUMN_GAP = 28
local checkedCount = 0

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

local function ToCamelCase(value)
    if not value then return "" end
    
    -- Convert first character to lowercase
    return value:gsub("^%u", string.lower)
end

local function ParseModuleLabel(label)
    -- Label format: "Arena.DispelHighlight" or "Arena.FilterName"
    local configPascal, modulePascal = label:match("^([^%.]+)%.(.+)$")
    if not configPascal or not modulePascal then
        return nil, nil
    end
    
    local configKey = ToCamelCase(configPascal)
    local moduleKey = ToCamelCase(modulePascal)
    
    return configKey, moduleKey
end

local function SetModuleEnabled(moduleLabel, enabled)
    local configKey, moduleKey = ParseModuleLabel(moduleLabel)
    if not configKey or not moduleKey then
        return
    end
    
    -- Check if it's an aura filter by looking up the actual config
    local config = addon:GetConfig()
    local frameCfg = config[configKey]
    if not frameCfg or not frameCfg.modules then
        return
    end
    
    -- Check for auraFilters
    if frameCfg.modules.auraFilters and type(frameCfg.modules.auraFilters) == "table" then
        -- Compare PascalCase versions since filter names are stored in PascalCase
        local moduleKeyPascal = ToPascalCase(moduleKey)
        for i, filterCfg in ipairs(frameCfg.modules.auraFilters) do
            if type(filterCfg) == "table" and filterCfg.name then
                if filterCfg.name == moduleKeyPascal then
                    if enabled then
                        addon:SetOverride({configKey, "modules", "auraFilters", i, "enabled"}, true)
                    else
                        addon:ClearOverrides({configKey, "modules", "auraFilters", i, "enabled"})
                    end
                    return
                end
            end
        end
    end
    
    -- Otherwise it's a regular module
    if frameCfg.modules[moduleKey] then
        if enabled then
            addon:SetOverride({configKey, "modules", moduleKey, "enabled"}, true)
        else
            addon:ClearOverrides({configKey, "modules", moduleKey, "enabled"})
        end
    end
end

local function GetDisabledModuleDisplayNames(config)
    local disabled = {}

    for configKey, frameCfg in pairs(config or {}) do
        -- Skip if this is the global config or if the frame itself is disabled
        if configKey ~= "global" and type(frameCfg) == "table" and frameCfg.enabled ~= false and type(frameCfg.modules) == "table" then
            for moduleKey, moduleCfg in pairs(frameCfg.modules) do
                if moduleKey == "auraFilters" and type(moduleCfg) == "table" then
                    for _, filterCfg in ipairs(moduleCfg) do
                        if type(filterCfg) == "table" and filterCfg.enabled == false and filterCfg.name then
                            disabled[#disabled + 1] = ToPascalCase(configKey) .. "." .. ToPascalCase(filterCfg.name)
                        end
                    end
                elseif type(moduleCfg) == "table" and moduleCfg.enabled == false then
                    disabled[#disabled + 1] = ToPascalCase(configKey) .. "." .. ToPascalCase(moduleKey)
                end
            end
        end
    end

    table.sort(disabled)
    return disabled
end

local function ClearSettingsControls()
    if not settingsDialog or not settingsDialog._controls then return end

    for _, control in ipairs(settingsDialog._controls) do
        control:Hide()
        control:SetParent(nil)
    end

    settingsDialog._controls = {}
end

local function PopulateSettingsContent(dialog)
    -- Reset checked count when dialog opens
    checkedCount = 0
    
    local config = addon:GetConfig()
    local fonts = addon:ListMedia("font")
    local textures = addon:ListMedia("statusbar")

    if #fonts == 0 then
        fonts = { "DorisPP" }
    end
    if #textures == 0 then
        textures = { "Smooth" }
    end

    ClearSettingsControls()
    dialog._controls = dialog._controls or {}

    local leftColumn = dialog._leftColumn
    local rightColumn = dialog._rightColumn
    if not leftColumn or not rightColumn then return end

    local leftY = -4
    local rightY = -4

    local globalHeader, globalDivider
    globalHeader, globalDivider, leftY = addon:DialogAddHeader(leftColumn, leftY, "Global Options")
    table.insert(dialog._controls, globalHeader)
    table.insert(dialog._controls, globalDivider)

    local borderColorRow
    borderColorRow, leftY = addon:DialogAddColorPicker(leftColumn, leftY, "Border Color", "000000FF", function() end)
    table.insert(dialog._controls, borderColorRow)

    local borderSizeRow
    borderSizeRow, leftY = addon:DialogAddSlider(leftColumn, leftY, "Border Size", 1, 10, 2, 1, function() end)
    table.insert(dialog._controls, borderSizeRow)

    local fontRow
    fontRow, leftY = addon:DialogAddDropdown(leftColumn, leftY, "Font", fonts, config.global and config.global.font or fonts[1], function() end)
    table.insert(dialog._controls, fontRow)
    
    local healthTextureRow
    healthTextureRow, leftY = addon:DialogAddDropdown(leftColumn, leftY, "Health Texture", textures, textures[1], function() end)
    table.insert(dialog._controls, healthTextureRow)

    local powerTextureRow
    powerTextureRow, leftY = addon:DialogAddDropdown(leftColumn, leftY, "Power Texture", textures, textures[1], function() end)
    table.insert(dialog._controls, powerTextureRow)

    local absorbTextureRow
    absorbTextureRow, leftY = addon:DialogAddDropdown(leftColumn, leftY, "Absorb Texture", textures, textures[1], function() end)
    table.insert(dialog._controls, absorbTextureRow)

    local castbarTextureRow
    castbarTextureRow, leftY = addon:DialogAddDropdown(leftColumn, leftY, "Castbar Texture", textures, textures[1], function() end)
    table.insert(dialog._controls, castbarTextureRow)

    local disabledHeader, disabledDivider
    disabledHeader, disabledDivider, rightY = addon:DialogAddHeader(rightColumn, rightY, "Disabled Modules")
    table.insert(dialog._controls, disabledHeader)
    table.insert(dialog._controls, disabledDivider)

    local disabledModules = GetDisabledModuleDisplayNames(config)
    if #disabledModules == 0 then
        local emptyText = rightColumn:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(rightColumn._fontPath, 14, "OUTLINE")
        emptyText:SetTextColor(1, 1, 1)
        emptyText:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 38, rightY)
        emptyText:SetText("No disabled modules")
        table.insert(dialog._controls, emptyText)
        rightY = rightY - 24
    else
        for _, moduleLabel in ipairs(disabledModules) do
            local row
            row, rightY = addon:DialogAddCheckbox(rightColumn, rightY, moduleLabel, false, function(checked)
                SetModuleEnabled(moduleLabel, checked)
                
                -- Update checked count
                if checked then
                    checkedCount = checkedCount + 1
                else
                    checkedCount = checkedCount - 1
                end
                
                -- Update reload button state
                if dialog._reloadButton then
                    if checkedCount > 0 then
                        dialog._reloadButton:Enable()
                        dialog._reloadButton:SetAlpha(1.0)
                    else
                        dialog._reloadButton:Disable()
                        dialog._reloadButton:SetAlpha(0.5)
                    end
                end
            end)
            table.insert(dialog._controls, row)
        end
        
        -- Add reload button below disabled modules
        rightY = rightY - 10
        local reloadButton
        reloadButton, rightY = addon:DialogAddButton(rightColumn, rightY, "Reload UI", function()
            -- Save state to reopen settings after reload and resume edit mode
            addon:SetPendingSettingsDialogReopen(true)
            if addon.savedVars and addon.savedVars.data then
                addon.savedVars.data.resumeEditModeAfterReload = true
            end
            ReloadUI()
        end)
        dialog._reloadButton = reloadButton
        reloadButton:SetAlpha(checkedCount > 0 and 1.0 or 0.5)
        if checkedCount == 0 then
            reloadButton:Disable()
        end
        table.insert(dialog._controls, reloadButton)
    end

    local leftDepth = math.abs(leftY) + 8
    local rightDepth = math.abs(rightY) + 8
    local contentDepth = math.max(leftDepth, rightDepth)

    leftColumn:SetHeight(leftDepth)
    rightColumn:SetHeight(rightDepth)

    -- Set content frame height for scrolling
    if dialog._contentFrame then
        dialog._contentFrame:SetHeight(contentDepth)
    end

    -- Set dialog to a fixed maximum height for scrollability
    local maxDialogHeight = math.min(600, UIParent:GetHeight() * 0.7)
    local titleAreaHeight = math.abs(dialog._contentAreaTopOffset)
    local desiredHeight = titleAreaHeight + contentDepth + dialog._borderWidth + dialog._padding
    local finalHeight = math.min(desiredHeight, maxDialogHeight)
    dialog:SetHeight(finalHeight)

    -- Hide scrollbar if content fits without scrolling
    if dialog._scrollFrame then
        local scrollHeight = dialog._scrollFrame:GetHeight()
        local needsScrolling = contentDepth > scrollHeight
        
        if dialog._scrollFrame.ScrollBar then
            if needsScrolling then
                dialog._scrollFrame.ScrollBar:Show()
            else
                dialog._scrollFrame.ScrollBar:Hide()
                dialog._scrollFrame:SetVerticalScroll(0)
            end
        end
    end
end

local function GetDialogCenter(frame)
    if not frame then return nil, nil end

    local left = frame:GetLeft()
    local bottom = frame:GetBottom()
    local width = frame:GetWidth()
    local height = frame:GetHeight()

    if not left or not bottom or not width or not height then
        return nil, nil
    end

    return left + (width / 2), bottom + (height / 2)
end

local function BuildSettingsDialog()
    if settingsDialog then return settingsDialog end

    local baseDialog = addon._editModeDialog
    local baseWidth = baseDialog and baseDialog:GetWidth() or 320
    -- Add padding for column insets (BORDER_WIDTH + PADDING = 38px on each side)
    local width = (baseWidth * 2) + 40 + 76

    settingsDialog = addon:CreateDialog("ZenFramesEditModeSettingsDialog", addon:L("settingsTitle"), width)

    local titleIcon = settingsDialog:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(20, 20)
    titleIcon:SetAtlas("CreditsScreen-Assets-Buttons-Play")
    titleIcon:SetRotation(math.pi)
    titleIcon:SetPoint("CENTER", settingsDialog, "TOPLEFT", settingsDialog._borderWidth + settingsDialog._padding + 14, -(settingsDialog._borderWidth + settingsDialog._padding + 11))
    titleIcon:SetDesaturated(true)
    settingsDialog._titleIcon = titleIcon

    local titleHover = CreateFrame("Frame", nil, settingsDialog)
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
        if InCombatLockdown() then return end
        addon:ReturnFromEditModeSettingsDialog()
    end)
    settingsDialog._titleHover = titleHover

    local y = settingsDialog._contentTop
    local titleDivider
    titleDivider, y = addon:DialogAddDivider(settingsDialog, y - 6)
    settingsDialog._titleDivider = titleDivider

    settingsDialog._contentAreaTopOffset = y - 8

    local innerInset = settingsDialog._borderWidth + settingsDialog._padding
    -- Columns will apply their own insets to controls, so don't subtract from available width
    local columnWidth = math.floor((width - COLUMN_GAP) / 2)

    -- Create scroll frame for scrollable content
    local scrollFrame = CreateFrame("ScrollFrame", nil, settingsDialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", settingsDialog, "TOPLEFT", innerInset, settingsDialog._contentAreaTopOffset)
    scrollFrame:SetPoint("BOTTOMRIGHT", settingsDialog, "BOTTOMRIGHT", -innerInset, innerInset)
    settingsDialog._scrollFrame = scrollFrame

    -- Create content frame to hold columns
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetWidth(width - (innerInset * 2))
    contentFrame:SetHeight(1) -- Will be adjusted in PopulateSettingsContent
    scrollFrame:SetScrollChild(contentFrame)
    settingsDialog._contentFrame = contentFrame

    local leftColumn = CreateFrame("Frame", nil, contentFrame)
    -- Position left column with negative offset since controls add BORDER_WIDTH + PADDING themselves
    leftColumn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", -(settingsDialog._borderWidth + settingsDialog._padding), 0)
    leftColumn:SetWidth(columnWidth)
    leftColumn:SetHeight(1)
    leftColumn._fontPath = settingsDialog._fontPath

    local rightColumn = CreateFrame("Frame", nil, contentFrame)
    rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", COLUMN_GAP, 0)
    rightColumn:SetWidth(columnWidth)
    rightColumn:SetHeight(1)
    rightColumn._fontPath = settingsDialog._fontPath

    settingsDialog._leftColumn = leftColumn
    settingsDialog._rightColumn = rightColumn

    settingsDialog:SetScript("OnShow", function(self)
        PopulateSettingsContent(self)
    end)

    return settingsDialog
end

function addon:ShowEditModeSettingsDialog()
    if InCombatLockdown() then return end

    local mainDialog = addon._editModeDialog
    local centerX, centerY = GetDialogCenter(mainDialog)

    if mainDialog then
        mainDialog:Hide()
    end

    self:HideAllEditModeSubDialogs()

    local dlg = BuildSettingsDialog()

    if centerX and centerY then
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    end

    dlg:Show()
end

function addon:HideEditModeSettingsDialog()
    if InCombatLockdown() then return end

    if settingsDialog then
        settingsDialog:Hide()
    end
end

function addon:IsEditModeSettingsDialogShown()
    if not settingsDialog then
        return false
    end

    return settingsDialog:IsShown()
end

function addon:ReturnFromEditModeSettingsDialog()
    if InCombatLockdown() then return end

    local centerX, centerY = GetDialogCenter(settingsDialog)
    self:HideEditModeSettingsDialog()
    self:ShowEditModeDialog()

    local mainDialog = self._editModeDialog
    if mainDialog and centerX and centerY then
        mainDialog:ClearAllPoints()
        mainDialog:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    end
end

function addon:SetPendingSettingsDialogReopen(value)
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.reopenSettings = value
end

function addon:CheckAndReopenSettingsDialog()
    if not self.savedVars or not self.savedVars.data then return end
    
    if self.savedVars.data.reopenSettings then
        self.savedVars.data.reopenSettings = nil
        
        -- Open settings dialog (edit mode is already active at this point)
        self:ShowEditModeSettingsDialog()
    end
end

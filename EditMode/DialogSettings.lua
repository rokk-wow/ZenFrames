local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local settingsDialog
local COLUMN_GAP = 28
local checkedCount = 0
local globalSettingsRefreshTimer
local lastGlobalSettingsRefreshTime = 0
local GLOBAL_SETTINGS_REFRESH_THROTTLE_SECONDS = 0.03

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
    addon:RefreshConfig()
    local frameCfg = addon.config[configKey]
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

local function GetDisabledModuleDisplayNames()
    local disabled = {}

    for configKey, frameCfg in pairs(addon.config or {}) do
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
    
    addon:RefreshConfig()
    local fonts = addon:ListMedia("font")
    local textures = addon:ListMedia("statusbar")

    if #fonts == 0 then
        fonts = { "DorisPP" }
    end
    if #textures == 0 then
        textures = { "Smooth" }
    end

    local function BuildDropdownOptions(values)
        local dropdownOptions = {}

        for _, value in ipairs(values) do
            local label = tostring(value or "")
            label = label:gsub("_", " ")
            label = label:gsub("-", " ")
            label = label:gsub("(%l)(%u)", "%1 %2")
            label = label:gsub("%s+", " ")
            label = label:gsub("^%s+", "")
            label = label:gsub("%s+$", "")
            label = label:gsub("(%a)([%w']*)", function(first, rest)
                return string.upper(first) .. rest
            end)

            table.insert(dropdownOptions, {
                label = label,
                value = value,
            })
        end

        return dropdownOptions
    end

    local fontOptions = BuildDropdownOptions(fonts)
    local textureOptions = BuildDropdownOptions(textures)

    ClearSettingsControls()
    dialog._controls = dialog._controls or {}

    local leftColumn = dialog._leftColumn
    local rightColumn = dialog._rightColumn
    if not leftColumn or not rightColumn then return end

    local leftY = -4
    local rightY = -4

    local function RefreshTextFonts(frame, cfg)
        -- Get global font from already-refreshed config
        if not addon.config or not addon.config.global or not addon.config.global.font then return end
        
        local globalFont = addon.config.global.font
        
        -- Refresh frame.Texts (created by AddText)
        if frame.Texts then
            local textConfigs = cfg.modules and cfg.modules.text
            if textConfigs then
                for i, fs in pairs(frame.Texts) do
                    local textCfg = textConfigs[i]
                    if fs and textCfg then
                        local fontName = textCfg.font or globalFont
                        local fontPath = addon:FetchFont(fontName)
                        local fontSize = addon:ResolveFontSize(textCfg.size)
                        if fontPath and fontSize and fontSize > 0 then
                            fs:SetFont(fontPath, fontSize, textCfg.outline)
                        end
                    end
                end
            end
        end

        -- Refresh Castbar.Text and Castbar.Time
        if frame.Castbar then
            local castbarCfg = cfg.modules and cfg.modules.castbar
            if castbarCfg then
                local fontPath = addon:FetchFont(globalFont)
                if fontPath then
                    if frame.Castbar.Text and castbarCfg.textSize then
                        frame.Castbar.Text:SetFont(fontPath, castbarCfg.textSize, "OUTLINE")
                    end
                    if frame.Castbar.Time then
                        frame.Castbar.Time:SetFont(fontPath, 10, "OUTLINE")
                    end
                end
            end
        end

        -- Refresh aura filter button fonts
        if cfg.modules and cfg.modules.auraFilters then
            for _, filterCfg in ipairs(cfg.modules.auraFilters) do
                if filterCfg.enabled and filterCfg.name then
                    local filter = frame[filterCfg.name]
                    if filter and filter.icons then
                        local fontPath = addon:FetchFont(globalFont)
                        if fontPath then
                            for _, icon in pairs(filter.icons) do
                                if icon.Count then
                                    icon.Count:SetFont(fontPath, 10, "OUTLINE")
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function RefreshTextures(frame, cfg)
        -- Get global textures from already-refreshed config
        if not addon.config or not addon.config.global then return end
        
        local globalConfig = addon.config.global
        
        -- Refresh Health texture
        if frame.Health then
            local healthCfg = cfg.modules and cfg.modules.health
            if healthCfg and healthCfg.healthTexture then
                local texturePath = addon:FetchStatusbar(healthCfg.healthTexture, "health")
                if texturePath then
                    -- Preserve current color
                    local tex = frame.Health:GetStatusBarTexture()
                    local r, g, b, a
                    if tex then
                        r, g, b, a = tex:GetVertexColor()
                    end
                    
                    frame.Health:SetStatusBarTexture(texturePath)
                    
                    -- Restore color
                    if r and g and b then
                        local newTex = frame.Health:GetStatusBarTexture()
                        if newTex then
                            newTex:SetVertexColor(r, g, b, a or 1)
                        end
                    end
                end
            end
        end
        
        -- Refresh Power texture
        if frame.Power then
            local powerCfg = cfg.modules and cfg.modules.power
            if powerCfg and powerCfg.powerTexture then
                local texturePath = addon:FetchStatusbar(powerCfg.powerTexture, "power")
                if texturePath then
                    -- Preserve current color
                    local tex = frame.Power:GetStatusBarTexture()
                    local r, g, b, a
                    if tex then
                        r, g, b, a = tex:GetVertexColor()
                    end
                    
                    frame.Power:SetStatusBarTexture(texturePath)
                    
                    -- Restore color
                    if r and g and b then
                        local newTex = frame.Power:GetStatusBarTexture()
                        if newTex then
                            newTex:SetVertexColor(r, g, b, a or 1)
                        end
                    end
                end
            end
        end
        
        -- Refresh Castbar texture
        if frame.Castbar then
            local castbarCfg = cfg.modules and cfg.modules.castbar
            if castbarCfg and castbarCfg.castbarTexture then
                local texturePath = addon:FetchStatusbar(castbarCfg.castbarTexture, "castbar")
                if texturePath then
                    -- Preserve current color
                    local tex = frame.Castbar:GetStatusBarTexture()
                    local r, g, b, a
                    if tex then
                        r, g, b, a = tex:GetVertexColor()
                    end
                    
                    frame.Castbar:SetStatusBarTexture(texturePath)
                    
                    -- Restore color
                    if r and g and b then
                        local newTex = frame.Castbar:GetStatusBarTexture()
                        if newTex then
                            newTex:SetVertexColor(r, g, b, a or 1)
                        end
                    end
                end
            end
        end
        
        -- Refresh Absorbs texture (HealthPrediction)
        if frame.HealthPrediction and frame.HealthPrediction.damageAbsorb then
            local absorbsCfg = cfg.modules and cfg.modules.absorbs
            if absorbsCfg and absorbsCfg.absorbTexture then
                local texturePath = addon:FetchStatusbar(absorbsCfg.absorbTexture, "absorb")
                if texturePath then
                    frame.HealthPrediction.damageAbsorb:SetStatusBarTexture(texturePath)
                end
            end
        end
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

    local function RefreshVisibleFramesFromConfig()
        addon._cachedConfig = nil
        addon:RefreshConfig()

        local unitFrameConfigKeys = {
            "player",
            "target",
            "targetTarget",
            "focus",
            "focusTarget",
            "pet",
        }

        -- Map config keys to unit IDs (unitFrames is keyed by unit ID)
        local configKeyToUnit = {
            player = "player",
            target = "target",
            targetTarget = "targettarget",
            focus = "focus",
            focusTarget = "focustarget",
            pet = "pet",
        }

        for _, configKey in ipairs(unitFrameConfigKeys) do
            addon:RefreshFrame(configKey, addon.editMode)
            
            if addon.editMode then
                local unitId = configKeyToUnit[configKey]
                local frame = addon.unitFrames[unitId]
                local cfg = addon.config and addon.config[configKey]
                if frame and cfg then
                    RefreshTextFonts(frame, cfg)
                    RefreshTextures(frame, cfg)
                    RefreshTextureBorders(frame, cfg)
                end
            end
        end

        if addon.groupContainers then
            for configKey, container in pairs(addon.groupContainers) do
                local cfg = addon.config and addon.config[configKey]
                if type(cfg) == "table" then
                    local unitBorderWidth = cfg.borderWidth
                    local unitBorderColor = cfg.borderColor

                    addon:AddBorder(container, {
                        borderWidth = cfg.containerBorderWidth,
                        borderColor = cfg.containerBorderColor,
                    })

                    if container.frames then
                        for _, child in ipairs(container.frames) do
                            addon:AddBorder(child, {
                                borderWidth = unitBorderWidth,
                                borderColor = unitBorderColor,
                            })

                            if cfg.modules and cfg.modules.castbar and child.Castbar then
                                addon:AddBorder(child.Castbar, cfg.modules.castbar)
                            end

                            if addon.editMode then
                                RefreshTextFonts(child, cfg)
                                RefreshTextures(child, cfg)
                                RefreshTextureBorders(child, cfg)
                            elseif child.UpdateAllElements then
                                child:UpdateAllElements("RefreshConfig")
                            end
                        end
                    end
                end
            end
        end
    end

    local function ApplyGlobalSetting(settingKey, value)
        addon:SetOverride({"global", settingKey}, value)
        addon._configDirty = true
        addon._cachedConfig = nil

        if not addon.editMode then
            if globalSettingsRefreshTimer then
                globalSettingsRefreshTimer:Cancel()
                globalSettingsRefreshTimer = nil
            end
            RefreshVisibleFramesFromConfig()
            return
        end

        local now = (GetTimePreciseSec and GetTimePreciseSec()) or (GetTime and GetTime()) or 0
        local elapsed = now - lastGlobalSettingsRefreshTime

        if elapsed >= GLOBAL_SETTINGS_REFRESH_THROTTLE_SECONDS then
            lastGlobalSettingsRefreshTime = now
            RefreshVisibleFramesFromConfig()
            return
        end

        if globalSettingsRefreshTimer then
            globalSettingsRefreshTimer:Cancel()
        end

        local delay = GLOBAL_SETTINGS_REFRESH_THROTTLE_SECONDS - elapsed
        if delay < 0 then
            delay = 0
        end

        globalSettingsRefreshTimer = C_Timer.NewTimer(delay, function()
            globalSettingsRefreshTimer = nil
            lastGlobalSettingsRefreshTime = (GetTimePreciseSec and GetTimePreciseSec()) or (GetTime and GetTime()) or 0
            RefreshVisibleFramesFromConfig()
        end)
    end

    local globalHeader, globalDivider
    globalHeader, globalDivider, leftY = addon:DialogAddHeader(leftColumn, leftY, "Global Options")
    table.insert(dialog._controls, globalHeader)
    table.insert(dialog._controls, globalDivider)

    local borderColorRow
    borderColorRow, leftY = addon:DialogAddColorPicker(
        leftColumn,
        leftY,
        "Border Color",
        addon.config.global and addon.config.global.borderColor or "000000FF",
        function(value)
            ApplyGlobalSetting("borderColor", value)
        end
    )
    table.insert(dialog._controls, borderColorRow)

    local borderSizeRow
    borderSizeRow, leftY = addon:DialogAddSlider(
        leftColumn,
        leftY,
        "Border Size",
        1,
        10,
        addon.config.global and addon.config.global.borderWidth or 2,
        1,
        function(value)
            ApplyGlobalSetting("borderWidth", value)
        end
    )
    table.insert(dialog._controls, borderSizeRow)

    local fontRow
    fontRow, leftY = addon:DialogAddDropdown(
        leftColumn,
        leftY,
        "Font",
        fontOptions,
        addon.config.global and addon.config.global.font or fonts[1],
        function(value)
            ApplyGlobalSetting("font", value)
        end
    )
    table.insert(dialog._controls, fontRow)
    
    local healthTextureRow
    healthTextureRow, leftY = addon:DialogAddDropdown(
        leftColumn,
        leftY,
        "Health Texture",
        textureOptions,
        addon.config.global and addon.config.global.healthTexture or textures[1],
        function(value)
            ApplyGlobalSetting("healthTexture", value)
        end
    )
    table.insert(dialog._controls, healthTextureRow)

    local powerTextureRow
    powerTextureRow, leftY = addon:DialogAddDropdown(
        leftColumn,
        leftY,
        "Power Texture",
        textureOptions,
        addon.config.global and addon.config.global.powerTexture or textures[1],
        function(value)
            ApplyGlobalSetting("powerTexture", value)
        end
    )
    table.insert(dialog._controls, powerTextureRow)

    local absorbTextureRow
    absorbTextureRow, leftY = addon:DialogAddDropdown(
        leftColumn,
        leftY,
        "Absorb Texture",
        textureOptions,
        addon.config.global and addon.config.global.absorbTexture or textures[1],
        function(value)
            ApplyGlobalSetting("absorbTexture", value)
        end
    )
    table.insert(dialog._controls, absorbTextureRow)

    local castbarTextureRow
    castbarTextureRow, leftY = addon:DialogAddDropdown(
        leftColumn,
        leftY,
        "Castbar Texture",
        textureOptions,
        addon.config.global and addon.config.global.castbarTexture or textures[1],
        function(value)
            ApplyGlobalSetting("castbarTexture", value)
        end
    )
    table.insert(dialog._controls, castbarTextureRow)

    local disabledHeader, disabledDivider
    disabledHeader, disabledDivider, rightY = addon:DialogAddHeader(rightColumn, rightY, "Disabled Modules")
    table.insert(dialog._controls, disabledHeader)
    table.insert(dialog._controls, disabledDivider)

    local disabledModules = GetDisabledModuleDisplayNames()
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

local function BuildSettingsDialog()
    if settingsDialog then return settingsDialog end

    settingsDialog = addon:CreateEditModeSubDialog("ZenFramesEditModeSettingsDialog", addon:L("settingsTitle"), {
        sizeMode = "large",
        onBackClick = function()
            addon:ReturnFromEditModeSettingsDialog()
        end,
    })
    addon._editModeSettingsDialog = settingsDialog

    local width = settingsDialog:GetWidth()

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

    -- Get position of any currently open dialog BEFORE building settings dialog
    -- (BuildSettingsDialog returns singleton, so we need position before we get the frame)
    local centerX, centerY = self:GetOpenConfigDialogCenter(nil)

    local dlg = BuildSettingsDialog()
    self:HideOpenConfigDialogs(dlg)

    if centerX and centerY then
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    else
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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

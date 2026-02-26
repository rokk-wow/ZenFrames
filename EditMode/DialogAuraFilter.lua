local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetAuraFilterConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.auraFilters then return nil, nil, nil end

    for i, entry in ipairs(cfg.modules.auraFilters) do
        if entry.name == moduleKey then
            return cfg, entry, i
        end
    end

    return nil, nil, nil
end

local function UpdateFilterFrameIconSize(filterFrame, iconSize)
    if not filterFrame or not filterFrame.icons then return end

    filterFrame.iconSize = iconSize

    local cellW = iconSize + 2 * filterFrame.iconBorderWidth
    local cellH = iconSize + 2 * filterFrame.iconBorderWidth
    local cols = math.min(filterFrame.perRow, filterFrame.maxIcons)
    local rows = math.ceil(filterFrame.maxIcons / cols)

    filterFrame:SetSize(
        cols * cellW + math.max(0, cols - 1) * filterFrame.spacingX + 2 * filterFrame.spacingX,
        rows * cellH + math.max(0, rows - 1) * filterFrame.spacingY + 2 * filterFrame.spacingY
    )

    local vertAnchor = (filterFrame.growthY == "DOWN") and "TOP" or "BOTTOM"
    local horizAnchor = (filterFrame.growthX == "LEFT") and "RIGHT" or "LEFT"
    local initialAnchor = vertAnchor .. horizAnchor
    local xMult = (filterFrame.growthX == "LEFT") and -1 or 1
    local yMult = (filterFrame.growthY == "UP") and 1 or -1

    for i, icon in ipairs(filterFrame.icons) do
        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        local col = (i - 1) % filterFrame.perRow
        local row = math.floor((i - 1) / filterFrame.perRow)
        icon:SetPoint(initialAnchor, filterFrame, initialAnchor,
            (col * (cellW + filterFrame.spacingX) + filterFrame.spacingX + filterFrame.iconBorderWidth) * xMult,
            (row * (cellH + filterFrame.spacingY) + filterFrame.spacingY + filterFrame.iconBorderWidth) * yMult)
    end
end

local function UpdateFilterFrameBorders(self, filterFrame, borderWidth, borderColor)
    if not filterFrame or not filterFrame.icons then return end

    for _, icon in ipairs(filterFrame.icons) do
        self:AddTextureBorder(icon, borderWidth, borderColor)
    end
end

local function UpdateFilterFramePlaceholders(filterFrame, show)
    if not filterFrame or not filterFrame.icons then return end

    filterFrame.showPlaceholderIcon = show

    if show and filterFrame.placeholderIcon then
        for _, icon in ipairs(filterFrame.icons) do
            if not icon.Placeholder then
                icon.Placeholder = icon:CreateTexture(nil, "BACKGROUND")
                icon.Placeholder:SetAllPoints()
                icon.Placeholder:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            icon.Placeholder:SetTexture(filterFrame.placeholderIcon)
            icon.Placeholder:SetDesaturated(filterFrame.placeholderDesaturate)
            if filterFrame.placeholderColor then
                icon.Placeholder:SetVertexColor(unpack(filterFrame.placeholderColor))
            end
            icon.Placeholder:Show()
            if icon.EditBackground then
                icon.EditBackground:Hide()
            end
            icon:Show()
        end
    else
        for _, icon in ipairs(filterFrame.icons) do
            if icon.Placeholder then
                icon.Placeholder:Hide()
            end
            if not icon.EditBackground then
                icon.EditBackground = icon:CreateTexture(nil, "BACKGROUND")
                icon.EditBackground:SetAllPoints()
                icon.EditBackground:SetColorTexture(0, 0, 0, 0.7)
            end
            icon.EditBackground:Show()
            icon:Show()
        end
    end
end

local function ForEachFilterFrame(self, configKey, moduleKey, filterCfg, callback)
    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            local filterFrame = unitFrame[moduleKey]
            if filterFrame then
                callback(filterFrame)
            end
        end
        return
    end

    if filterCfg.frameName then
        local filterFrame = _G[filterCfg.frameName]
        if filterFrame then
            callback(filterFrame)
        end
    end
end

local function RefreshAuraFilterVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, filterCfg = GetAuraFilterConfig(self, configKey, moduleKey)
    if not cfg or not filterCfg then return end

    local iconSize = filterCfg.iconSize or 30
    local borderWidth = filterCfg.borderWidth or 1
    local borderColor = filterCfg.borderColor or "000000FF"
    local showPlaceholder = filterCfg.showPlaceholderIcon == true

    ForEachFilterFrame(self, configKey, moduleKey, filterCfg, function(filterFrame)
        UpdateFilterFrameIconSize(filterFrame, iconSize)
        UpdateFilterFrameBorders(self, filterFrame, borderWidth, borderColor)
        UpdateFilterFramePlaceholders(filterFrame, showPlaceholder)
    end)
end

function addon:RefreshAuraFilterEditModeVisuals(configKey, moduleKey)
    RefreshAuraFilterVisuals(self, configKey, moduleKey)
end

function addon:PopulateAuraFilterSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.auraFilters then return end

    local _, filterCfg, filterIndex = GetAuraFilterConfig(self, configKey, moduleKey)
    if not filterIndex or not filterCfg then return end

    subDialog._controls = subDialog._controls or {}

    local function ApplyFilterSetting(propertyName, value, shouldRefresh)
        self:SetOverride({configKey, "modules", "auraFilters", filterIndex, propertyName}, value)

        if shouldRefresh then
            RefreshAuraFilterVisuals(self, configKey, moduleKey)
        end
    end

    local useColumns = subDialog._leftColumn and subDialog._rightColumn
    local leftY = yOffset
    local rightY = yOffset

    -- LEFT COLUMN: Core settings
    local enabledRow
    enabledRow, leftY = self:DialogAddEnableControl(subDialog._leftColumn or subDialog, leftY, self:L("emEnabled"), filterCfg.enabled, configKey, moduleKey, function(value)
        ApplyFilterSetting("enabled", value)
    end)
    table.insert(subDialog._controls, enabledRow)

    local sizeRow
    sizeRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emSize"), 1, 100, filterCfg.iconSize, 1, function(value)
        ApplyFilterSetting("iconSize", value, true)
    end)
    table.insert(subDialog._controls, sizeRow)

    local showSwipeRow
    showSwipeRow, leftY = self:DialogAddCheckbox(subDialog._leftColumn or subDialog, leftY, self:L("emShowSwipe"), filterCfg.showSwipe ~= false, function(value)
        ApplyFilterSetting("showSwipe", value)
    end)
    table.insert(subDialog._controls, showSwipeRow)

    local showCooldownRow
    showCooldownRow, leftY = self:DialogAddCheckbox(subDialog._leftColumn or subDialog, leftY, self:L("emShowCooldownNumbers"), filterCfg.showCooldownNumbers ~= false, function(value)
        ApplyFilterSetting("showCooldownNumbers", value)
    end)
    table.insert(subDialog._controls, showCooldownRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 1
    local borderSizeRow
    borderSizeRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emBorderSize"), 1, 10, filterCfg.borderWidth, 1, function(value)
        ApplyFilterSetting("borderWidth", value, true)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, leftY = self:DialogAddColorPicker(subDialog._leftColumn or subDialog, leftY, self:L("emBorderColor"), filterCfg.borderColor, function(value)
        ApplyFilterSetting("borderColor", value, true)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)

    -- RIGHT COLUMN: Glow & placeholder
    local showPlaceholderRow
    showPlaceholderRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, self:L("emShowPlaceholder"), filterCfg.showPlaceholderIcon == true, function(value)
        ApplyFilterSetting("showPlaceholderIcon", value, true)
    end)
    table.insert(subDialog._controls, showPlaceholderRow)

    local showGlowRow
    showGlowRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, self:L("emShowGlow"), filterCfg.showGlow == true, function(value)
        ApplyFilterSetting("showGlow", value)
    end)
    table.insert(subDialog._controls, showGlowRow)

    local glowColorRow
    glowColorRow, rightY = self:DialogAddColorPicker(subDialog._rightColumn or subDialog, rightY, self:L("emGlowColor"), filterCfg.glowColor, function(value)
        ApplyFilterSetting("glowColor", value)
    end)
    table.insert(subDialog._controls, glowColorRow)
end

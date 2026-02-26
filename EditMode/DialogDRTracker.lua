local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetDRTrackerConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function RefreshDRTrackerVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local _, moduleCfg = GetDRTrackerConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if not container or not container.frames then return end

    local iconSize = moduleCfg.iconSize or 36
    local borderWidth = moduleCfg.borderWidth or 1
    local maxIcons = moduleCfg.maxIcons or 4
    local perRow = moduleCfg.perRow or 4
    local spacingX = moduleCfg.spacingX or 2
    local spacingY = moduleCfg.spacingY or 2
    local growthX = moduleCfg.growthX or "LEFT"
    local growthY = moduleCfg.growthY or "DOWN"
    local cols = math.min(perRow, maxIcons)
    local rows = math.ceil(maxIcons / cols)
    local cellW = iconSize + 2 * borderWidth
    local cellH = iconSize + 2 * borderWidth
    local containerW = cols * cellW + math.max(0, cols - 1) * spacingX
    local containerH = rows * cellH + math.max(0, rows - 1) * spacingY

    for _, unitFrame in ipairs(container.frames) do
        local drTracker = unitFrame.DRTracker
        if drTracker then
            drTracker:SetSize(containerW, containerH)
            self:AddTextureBorder(drTracker, moduleCfg.containerBorderWidth or 0, moduleCfg.containerBorderColor or "00000000")

            if drTracker._drPlaceholderIcons then
                for i, icon in ipairs(drTracker._drPlaceholderIcons) do
                    if i > maxIcons then
                        icon:Hide()
                    else
                        icon:SetSize(iconSize, iconSize)
                        icon:ClearAllPoints()

                        local col = (i - 1) % cols
                        local row = math.floor((i - 1) / cols)

                        local xOff = col * (cellW + spacingX) + borderWidth
                        local yOff = row * (cellH + spacingY) + borderWidth

                        if growthX == "LEFT" then
                            xOff = -xOff
                        end
                        if growthY ~= "UP" then
                            yOff = -yOff
                        end

                        local hAnchor = (growthX == "LEFT") and "TOPRIGHT" or "TOPLEFT"
                        if growthY == "UP" then
                            hAnchor = (growthX == "LEFT") and "BOTTOMRIGHT" or "BOTTOMLEFT"
                        end

                        icon:SetPoint(hAnchor, drTracker, hAnchor, xOff, yOff)
                        self:AddTextureBorder(icon, borderWidth, moduleCfg.borderColor or "000000FF")
                        icon:Show()
                    end
                end
            end
        end
    end
end

function addon:RefreshDRTrackerEditModeVisuals(configKey, moduleKey)
    moduleKey = moduleKey or "drTracker"
    RefreshDRTrackerVisuals(self, configKey, moduleKey)
end

function addon:PopulateDRTrackerSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetDRTrackerConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    subDialog._controls = subDialog._controls or {}

    local currentY = yOffset

    local enabledRow
    enabledRow, currentY = self:DialogAddEnableControl(subDialog, currentY, self:L("emEnabled"), moduleCfg.enabled, configKey, moduleKey, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "enabled"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)

    local sizeRow
    sizeRow, currentY = self:DialogAddSlider(subDialog, currentY, self:L("emSize"), 1, 100, moduleCfg.iconSize, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "iconSize"}, value)
        RefreshDRTrackerVisuals(self, configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)

    local showSwipeRow
    showSwipeRow, currentY = self:DialogAddCheckbox(subDialog, currentY, self:L("emShowSwipe"), moduleCfg.showSwipe ~= false, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "showSwipe"}, value)
    end)
    table.insert(subDialog._controls, showSwipeRow)

    local showCooldownRow
    showCooldownRow, currentY = self:DialogAddCheckbox(subDialog, currentY, self:L("emShowCooldownNumbers"), moduleCfg.showCooldownNumbers ~= false, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "showCooldownNumbers"}, value)
    end)
    table.insert(subDialog._controls, showCooldownRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 1
    local borderSizeRow
    borderSizeRow, currentY = self:DialogAddSlider(subDialog, currentY, self:L("emBorderSize"), 1, 10, moduleCfg.borderWidth, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "borderWidth"}, value)
        RefreshDRTrackerVisuals(self, configKey, moduleKey)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, currentY = self:DialogAddColorPicker(subDialog, currentY, self:L("emBorderColor"), moduleCfg.borderColor, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "borderColor"}, value)
        RefreshDRTrackerVisuals(self, configKey, moduleKey)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)
end

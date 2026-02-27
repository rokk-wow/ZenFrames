local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetArenaTargetsConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function ApplyArenaTargetsVisual(self, unitFrame, frameCfg, moduleCfg)
    if not unitFrame or not frameCfg or not moduleCfg then return end

    local arenaTargets = unitFrame.ArenaTargets
    if not arenaTargets then return end

    local indicatorWidth = moduleCfg.indicatorWidth or 10
    local indicatorHeight = moduleCfg.indicatorHeight or 16
    local spacing = moduleCfg.spacing or 0
    local growDirection = moduleCfg.growDirection or "DOWN"
    local borderWidth = moduleCfg.borderWidth or 1
    local borderColor = moduleCfg.borderColor or "000000FF"
    local maxIndicators = moduleCfg.maxIndicators or 3

    local containerWidth, containerHeight
    if growDirection == "DOWN" or growDirection == "UP" then
        containerWidth = indicatorWidth + (2 * borderWidth)
        containerHeight = (indicatorHeight * maxIndicators)
            + (spacing * (maxIndicators - 1))
            + (2 * borderWidth)
    else
        containerWidth = (indicatorWidth * maxIndicators)
            + (spacing * (maxIndicators - 1))
            + (2 * borderWidth)
        containerHeight = indicatorHeight + (2 * borderWidth)
    end

    arenaTargets:SetSize(containerWidth, containerHeight)

    local widget = arenaTargets.widget
    if not widget or not widget.indicators then
        return
    end

    for index, indicator in ipairs(widget.indicators) do
        indicator:SetSize(indicatorWidth, indicatorHeight)
        indicator:ClearAllPoints()

        if index == 1 then
            local xInset = borderWidth
            local yInset = borderWidth

            if growDirection == "UP" then
                indicator:SetPoint("BOTTOMLEFT", arenaTargets, "BOTTOMLEFT", xInset, yInset)
            elseif growDirection == "LEFT" then
                indicator:SetPoint("TOPRIGHT", arenaTargets, "TOPRIGHT", -xInset, -yInset)
            else
                indicator:SetPoint("TOPLEFT", arenaTargets, "TOPLEFT", xInset, -yInset)
            end
        else
            local previous = widget.indicators[index - 1]
            if growDirection == "RIGHT" then
                indicator:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
            elseif growDirection == "LEFT" then
                indicator:SetPoint("RIGHT", previous, "LEFT", -spacing, 0)
            elseif growDirection == "UP" then
                indicator:SetPoint("BOTTOM", previous, "TOP", 0, spacing)
            else
                indicator:SetPoint("TOP", previous, "BOTTOM", 0, -spacing)
            end
        end

        if indicator.Inner then
            indicator.Inner:ClearAllPoints()
            indicator.Inner:SetPoint("TOPLEFT", borderWidth, -borderWidth)
            indicator.Inner:SetPoint("BOTTOMRIGHT", -borderWidth, borderWidth)
        end

        self:AddTextureBorder(indicator, borderWidth, borderColor)
    end
end

local function RefreshArenaTargetsVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetArenaTargetsConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            ApplyArenaTargetsVisual(self, unitFrame, cfg, moduleCfg)
        end
    else
        local frameName = cfg.frameName
        if frameName then
            local unitFrame = _G[frameName]
            if not unitFrame and self.unitFrames then
                for _, candidate in pairs(self.unitFrames) do
                    if candidate and candidate:GetName() == frameName then
                        unitFrame = candidate
                        break
                    end
                end
            end

            if unitFrame then
                ApplyArenaTargetsVisual(self, unitFrame, cfg, moduleCfg)
            end
        end
    end

    if self.RefreshArenaTargetsPlaceholderPreviews then
        self:RefreshArenaTargetsPlaceholderPreviews(configKey, moduleKey)
    end
end

function addon:RefreshArenaTargetsEditModeVisuals(configKey, moduleKey)
    if not configKey then return end
    RefreshArenaTargetsVisuals(self, configKey, moduleKey or "arenaTargets")
end

function addon:PopulateArenaTargetsSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetArenaTargetsConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    subDialog._controls = subDialog._controls or {}

    local currentY = yOffset

    local onChange = function(value)
        self:SetOverride({configKey, "modules", moduleKey, "enabled"}, value)
    end
    local enabledRow
    enabledRow, currentY = self:DialogAddEnableControl(subDialog, currentY, "emEnabled", moduleCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)

    local modeRow
    modeRow, currentY = self:DialogAddDropdown(subDialog, currentY, "emMode", {
        { label = "emShowFriendlyUnits", value = "friendly" },
        { label = "emShowEnemyUnits", value = "enemy" },
    }, moduleCfg.mode, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "mode"}, value)
    end)
    table.insert(subDialog._controls, modeRow)

    local indicatorWidthRow
    indicatorWidthRow, currentY = self:DialogAddSlider(subDialog, currentY, "emIndicatorWidth", 2, 100, moduleCfg.indicatorWidth, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "indicatorWidth"}, value)
        self:RefreshArenaTargetsEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, indicatorWidthRow)

    local indicatorHeightRow
    indicatorHeightRow, currentY = self:DialogAddSlider(subDialog, currentY, "emIndicatorHeight", 2, 100, moduleCfg.indicatorHeight, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "indicatorHeight"}, value)
        self:RefreshArenaTargetsEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, indicatorHeightRow)

    local indicatorSpacingRow
    indicatorSpacingRow, currentY = self:DialogAddSlider(subDialog, currentY, "emIndicatorSpacing", 0, 100, moduleCfg.spacing, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "spacing"}, value)
        self:RefreshArenaTargetsEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, indicatorSpacingRow)

end

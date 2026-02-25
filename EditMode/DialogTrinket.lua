local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetTrinketConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function UpdateTrinketFrameVisual(self, unitFrame, trinketCfg)
    if not unitFrame or not trinketCfg then return end

    local trinket = unitFrame.Trinket
    if not trinket then return end

    local size = trinketCfg.iconSize or trinket:GetWidth() or 1
    local borderWidth = trinketCfg.borderWidth or 1
    local borderColor = trinketCfg.borderColor or "000000FF"
    local offsetX = trinketCfg.offsetX or 0
    local offsetY = (trinketCfg.offsetY or 0) + borderWidth

    trinket:SetSize(size, size)

    local anchorFrame = unitFrame
    if trinketCfg.relativeToModule then
        local ref = trinketCfg.relativeToModule
        if type(ref) == "table" then
            for _, key in ipairs(ref) do
                if unitFrame[key] then
                    anchorFrame = unitFrame[key]
                    break
                end
            end
        else
            anchorFrame = unitFrame[ref] or unitFrame
        end
    end

    local relativeFrame = trinketCfg.relativeTo and _G[trinketCfg.relativeTo] or anchorFrame
    if relativeFrame and trinketCfg.anchor and trinketCfg.relativePoint then
        trinket:ClearAllPoints()
        trinket:SetPoint(trinketCfg.anchor, relativeFrame, trinketCfg.relativePoint, offsetX, offsetY)
    end

    if trinket.Cooldown then
        local showSwipe = trinketCfg.showSwipe ~= false
        local showNumbers = trinketCfg.showCooldownNumbers ~= false
        trinket.Cooldown:SetDrawSwipe(showSwipe)
        trinket.Cooldown.noCooldownCount = not showNumbers
        trinket.Cooldown:SetHideCountdownNumbers(not showNumbers)
    end

    self:AddTextureBorder(trinket, borderWidth, borderColor)
end

local function RefreshTrinketVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetTrinketConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            UpdateTrinketFrameVisual(self, unitFrame, moduleCfg)
        end
        return
    end

    local frameName = cfg.frameName
    if not frameName then return end

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
        UpdateTrinketFrameVisual(self, unitFrame, moduleCfg)
    end
end

function addon:RefreshTrinketEditModeVisuals(configKey, moduleKey)
    moduleKey = moduleKey or "trinket"
    RefreshTrinketVisuals(self, configKey, moduleKey)
end

function addon:PopulateTrinketSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetTrinketConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    subDialog._controls = subDialog._controls or {}

    local currentY = yOffset

    local enabledRow
    enabledRow, currentY = self:DialogAddEnableControl(subDialog, currentY, "Enabled", moduleCfg.enabled, configKey, moduleKey, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "enabled"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)

    local sizeRow
    sizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "Size", 10, 100, moduleCfg.iconSize, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "iconSize"}, value)
        RefreshTrinketVisuals(self, configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 1
    local borderSizeRow
    borderSizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "Border Size", 1, 10, moduleCfg.borderWidth, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "borderWidth"}, value)
        RefreshTrinketVisuals(self, configKey, moduleKey)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, currentY = self:DialogAddColorPicker(subDialog, currentY, "Border Color", moduleCfg.borderColor, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "borderColor"}, value)
        RefreshTrinketVisuals(self, configKey, moduleKey)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)

    local showSwipeRow
    showSwipeRow, currentY = self:DialogAddCheckbox(subDialog, currentY, "Show Swipe", moduleCfg.showSwipe ~= false, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "showSwipe"}, value)
    end)
    table.insert(subDialog._controls, showSwipeRow)

    local showCooldownNumbersRow
    showCooldownNumbersRow, currentY = self:DialogAddCheckbox(subDialog, currentY, "Show Cooldown Numbers", moduleCfg.showCooldownNumbers ~= false, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "showCooldownNumbers"}, value)
    end)
    table.insert(subDialog._controls, showCooldownNumbersRow)
end

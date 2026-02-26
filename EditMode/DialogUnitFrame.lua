local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local CLICK_OPTIONS = {
    { label = addon:L("emSelectTarget"), value = "select" },
    { label = addon:L("emContextMenu"), value = "contextMenu" },
    { label = addon:L("emSetFocus"), value = "focus" },
    { label = addon:L("emClearFocus"), value = "clearFocus" },
    { label = addon:L("emInspect"), value = "inspect" },
    { label = addon:L("emNone"), value = "none" },
}

local INDIVIDUAL_UNIT_CONFIGS = {
    "player",
    "target",
    "targetTarget",
    "focus",
    "focusTarget",
    "pet",
}

local function IsIndividualUnitFrame(configKey)
    for _, key in ipairs(INDIVIDUAL_UNIT_CONFIGS) do
        if key == configKey then
            return true
        end
    end
    return false
end

local function RefreshUnitFrameVisuals(self, configKey)
    self:RefreshConfig()

    local cfg = self.config[configKey]
    if not cfg then return end

    local frameName = cfg.frameName
    if not frameName then return end

    local frame = _G[frameName]
    if not frame then return end

    local w = cfg.width or 150
    local h = cfg.height or 60
    frame:SetSize(w, h)

    if frame.Health then
        local powerCfg = cfg.modules and cfg.modules.power
        local powerHeight = powerCfg and powerCfg.enabled and powerCfg.height or 0
        local adjustHealth = powerCfg and powerCfg.adjustHealthbarHeight

        local healthHeight = h
        if adjustHealth and frame.Power and frame.Power:IsShown() then
            healthHeight = h - powerHeight
            frame.Power._healthOriginalHeight = h
        end
        frame.Health:SetWidth(w)
        frame.Health:SetHeight(healthHeight)
    end

    if frame.Power then
        local powerCfg = cfg.modules and cfg.modules.power
        if powerCfg and powerCfg.enabled then
            local renderWidth = math.max(1, w)
            frame.Power:SetWidth(renderWidth)
            if frame.Power._topBorder then
                frame.Power._topBorder:SetHeight(math.max(1, cfg.borderWidth or 1))
                local r, g, b, a = self:HexToRGB(cfg.borderColor or "000000FF")
                frame.Power._topBorder:SetColorTexture(r, g, b, a)
            end
        end
    end

    if frame.Background then
        local r, g, b, a = self:HexToRGB(cfg.backgroundColor or "00000088")
        frame.Background:SetColorTexture(r, g, b, a)
    end

    self:AddBorder(frame, { borderWidth = cfg.borderWidth, borderColor = cfg.borderColor })
end

function addon:PopulateUnitFrameSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog or not configKey then return end

    local cfg = self.config[configKey]
    if not cfg then return end

    if not IsIndividualUnitFrame(configKey) then return end

    subDialog._controls = subDialog._controls or {}

    local useColumns = subDialog._leftColumn and subDialog._rightColumn
    local leftY = yOffset
    local rightY = yOffset

    -- LEFT COLUMN: Sizing & appearance
    local enabledRow
    enabledRow, leftY = self:DialogAddEnableControl(subDialog._leftColumn or subDialog, leftY, self:L("emEnabled"), cfg.enabled, configKey, nil, function(value)
        self:SetOverride({configKey, "enabled"}, value)
        self:SetOverride({configKey, "hideBlizzard"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)

    local widthRow
    widthRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emWidth"), 1, 250, cfg.width, 1, function(value)
        self:SetOverride({configKey, "width"}, value)
        RefreshUnitFrameVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, widthRow)

    local heightRow
    heightRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emHeight"), 1, 250, cfg.height, 1, function(value)
        self:SetOverride({configKey, "height"}, value)
        RefreshUnitFrameVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, heightRow)

    local bgColorRow
    bgColorRow, leftY = self:DialogAddColorPicker(subDialog._leftColumn or subDialog, leftY, self:L("emBackgroundColor"), cfg.backgroundColor, function(value)
        self:SetOverride({configKey, "backgroundColor"}, value)
        RefreshUnitFrameVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, bgColorRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 2
    local borderSizeRow
    borderSizeRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emBorderSize"), 1, 10, cfg.borderWidth, 1, function(value)
        self:SetOverride({configKey, "borderWidth"}, value)
        RefreshUnitFrameVisuals(self, configKey)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, leftY = self:DialogAddColorPicker(subDialog._leftColumn or subDialog, leftY, self:L("emBorderColor"), cfg.borderColor, function(value)
        self:SetOverride({configKey, "borderColor"}, value)
        RefreshUnitFrameVisuals(self, configKey)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)

    -- RIGHT COLUMN: Click behavior & visibility
    local leftClickRow
    leftClickRow, rightY = self:DialogAddDropdown(subDialog._rightColumn or subDialog, rightY, self:L("emLeftClick"), CLICK_OPTIONS, cfg.leftClick, function(value)
        self:SetOverride({configKey, "leftClick"}, value)
    end)
    table.insert(subDialog._controls, leftClickRow)

    local rightClickRow
    rightClickRow, rightY = self:DialogAddDropdown(subDialog._rightColumn or subDialog, rightY, self:L("emRightClick"), CLICK_OPTIONS, cfg.rightClick, function(value)
        self:SetOverride({configKey, "rightClick"}, value)
    end)
    table.insert(subDialog._controls, rightClickRow)

    local hideInArenaRow
    hideInArenaRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, self:L("emHideInArena"), cfg.hideInArena, function(value)
        self:SetOverride({configKey, "hideInArena"}, value)
    end)
    table.insert(subDialog._controls, hideInArenaRow)
end

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

local function RefreshPartyVisuals(self, configKey)
    self:RefreshConfig()

    local cfg = self.config[configKey]
    if not cfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if not container then return end

    local unitW = cfg.unitWidth or 150
    local unitH = cfg.unitHeight or 60
    local spacingY = cfg.spacingY or 3
    local borderWidth = cfg.borderWidth
    local borderColor = cfg.borderColor

    if container.frames then
        local powerCfg = cfg.modules and cfg.modules.power
        local powerHeight = powerCfg and powerCfg.enabled and powerCfg.height or 0
        local adjustHealth = powerCfg and powerCfg.adjustHealthbarHeight

        for index, unitFrame in ipairs(container.frames) do
            unitFrame:SetSize(unitW, unitH)

            if unitFrame.Health then
                local healthHeight = unitH
                if adjustHealth and unitFrame.Power and unitFrame.Power:IsShown() then
                    healthHeight = unitH - powerHeight
                end
                unitFrame.Health:SetHeight(healthHeight)
            end

            if unitFrame.Power then
                if powerCfg and powerCfg.enabled then
                    local renderWidth = math.max(1, unitW)
                    unitFrame.Power:SetWidth(renderWidth)
                    if unitFrame.Power._topBorder then
                        unitFrame.Power._topBorder:SetHeight(math.max(1, borderWidth or 1))
                        local pr, pg, pb, pa = self:HexToRGB(borderColor or "000000FF")
                        unitFrame.Power._topBorder:SetColorTexture(pr, pg, pb, pa)
                    end
                end
            end

            if unitFrame.Background then
                local r, g, b, a = self:HexToRGB(cfg.unitBackgroundColor or "00000088")
                unitFrame.Background:SetColorTexture(r, g, b, a)
            end

            self:AddBorder(unitFrame, { borderWidth = borderWidth, borderColor = borderColor })

            if index > 1 then
                local previous = container.frames[index - 1]
                unitFrame:ClearAllPoints()
                unitFrame:SetPoint("TOP", previous, "BOTTOM", 0, -spacingY)
            end
        end
    end

    local maxUnits = cfg.maxUnits or 5
    local perRow = cfg.perRow or 1
    local spacingX = cfg.spacingX or 0
    local cols = math.min(perRow, maxUnits)
    local rows = math.ceil(maxUnits / cols)
    local containerW = cols * unitW + math.max(0, cols - 1) * spacingX + 2 * spacingX
    local containerH = rows * unitH + math.max(0, rows - 1) * spacingY + 2 * spacingY
    container:SetSize(containerW, containerH)
end

function addon:PopulatePartySubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog or not configKey then return end

    local cfg = self.config[configKey]
    if not cfg then return end

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
    widthRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emWidth"), 1, 250, cfg.unitWidth, 1, function(value)
        self:SetOverride({configKey, "unitWidth"}, value)
        RefreshPartyVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, widthRow)

    local heightRow
    heightRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emHeight"), 1, 250, cfg.unitHeight, 1, function(value)
        self:SetOverride({configKey, "unitHeight"}, value)
        RefreshPartyVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, heightRow)

    local spacingRow
    spacingRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, self:L("emSpacing"), 1, 100, cfg.spacingY, 1, function(value)
        self:SetOverride({configKey, "spacingY"}, value)
        RefreshPartyVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, spacingRow)

    -- RIGHT COLUMN: Click behavior & borders
    local bgColorRow
    bgColorRow, rightY = self:DialogAddColorPicker(subDialog._rightColumn or subDialog, rightY, self:L("emBackgroundColor"), cfg.unitBackgroundColor, function(value)
        self:SetOverride({configKey, "unitBackgroundColor"}, value)
        RefreshPartyVisuals(self, configKey)
    end)
    table.insert(subDialog._controls, bgColorRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 2
    local borderSizeRow
    borderSizeRow, rightY = self:DialogAddSlider(subDialog._rightColumn or subDialog, rightY, self:L("emBorderSize"), 1, 10, cfg.borderWidth, 1, function(value)
        self:SetOverride({configKey, "borderWidth"}, value)
        RefreshPartyVisuals(self, configKey)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, rightY = self:DialogAddColorPicker(subDialog._rightColumn or subDialog, rightY, self:L("emBorderColor"), cfg.borderColor, function(value)
        self:SetOverride({configKey, "borderColor"}, value)
        RefreshPartyVisuals(self, configKey)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)

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

end

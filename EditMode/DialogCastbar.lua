local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetCastbarConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function BuildDropdownOptions(values)
    local options = {}

    for _, value in ipairs(values) do
        local label = tostring(value or "")
        label = label:gsub("_", " ")
        label = label:gsub("-", " ")
        label = label:gsub("(%l)(%u)", "%1 %2")
        label = label:gsub("%s+", " ")
        label = label:gsub("^%s+", "")
        label = label:gsub("%s+$", "")
        label = label:gsub("(%a)([%w']*)", function(first, rest)
            return string.upper(first) .. string.lower(rest)
        end)

        table.insert(options, {
            label = label,
            value = value,
        })
    end

    return options
end

local function RefreshCastbarVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetCastbarConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    if moduleCfg.frameName then
        self:RefreshModule(configKey, moduleKey)
        return
    end

    local container = self.groupContainers and self.groupContainers[configKey]
    if not container or not container.frames then return end

    local moduleName = moduleKey:sub(1, 1):upper() .. moduleKey:sub(2)
    local fontPath = self:GetFontPath()

    for _, unitFrame in ipairs(container.frames) do
        local castbar = unitFrame[moduleName]
        if castbar then
            if moduleCfg.width and moduleCfg.height then
                castbar:SetSize(moduleCfg.width, moduleCfg.height)
            end

            self:AddBorder(castbar, moduleCfg)

            if castbar.Text then
                castbar.Text:SetShown(moduleCfg.showSpellName == true)
                if fontPath and moduleCfg.textSize then
                    castbar.Text:SetFont(fontPath, moduleCfg.textSize, "OUTLINE")
                end
                local align = moduleCfg.textAlignment or "LEFT"
                local padding = moduleCfg.textPadding or 4
                castbar.Text:ClearAllPoints()
                if align == "CENTER" then
                    castbar.Text:SetPoint("CENTER", castbar, "CENTER", 0, 0)
                elseif align == "RIGHT" then
                    castbar.Text:SetPoint("RIGHT", castbar, "RIGHT", -padding, 0)
                else
                    castbar.Text:SetPoint("LEFT", castbar, "LEFT", padding, 0)
                end
                castbar.Text:SetJustifyH(align)
            end

            if castbar.Time then
                castbar.Time:SetShown(moduleCfg.showCastTime == true)
                if fontPath and moduleCfg.textSize then
                    castbar.Time:SetFont(fontPath, moduleCfg.textSize, "OUTLINE")
                end
            end

            if castbar.IconFrame then
                castbar.IconFrame:SetShown(moduleCfg.showIcon == true)
                castbar.IconFrame:ClearAllPoints()
                local bw = moduleCfg.borderWidth or 1
                if moduleCfg.iconPosition == "RIGHT" then
                    castbar.IconFrame:SetPoint("LEFT", castbar, "RIGHT", 2 + bw, 0)
                else
                    castbar.IconFrame:SetPoint("RIGHT", castbar, "LEFT", -(2 + bw), 0)
                end
                self:AddBorder(castbar.IconFrame, moduleCfg)
            end
        end
    end
end

function addon:RefreshCastbarEditModeVisuals(configKey, moduleKey)
    moduleKey = moduleKey or "castbar"
    RefreshCastbarVisuals(self, configKey, moduleKey)
end

function addon:PopulateCastbarSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetCastbarConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    local function ApplyCastbarSetting(propertyName, value, shouldRefresh)
        self:SetOverride({configKey, "modules", moduleKey, propertyName}, value)

        if shouldRefresh then
            RefreshCastbarVisuals(self, configKey, moduleKey)
        end
    end

    subDialog._controls = subDialog._controls or {}

    -- Use two-column layout if available
    local useColumns = subDialog._leftColumn and subDialog._rightColumn
    local leftY = yOffset
    local rightY = yOffset

    -- LEFT COLUMN: Sizing & appearance
    local onChange = function(value)
        ApplyCastbarSetting("enabled", value, false)
    end
    local enabledRow
    enabledRow, leftY = self:DialogAddEnableControl(subDialog._leftColumn or subDialog, leftY, "emEnabled", moduleCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)

    local widthRow
    widthRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, "emWidth", 1, 500, moduleCfg.width, 1, function(value)
        ApplyCastbarSetting("width", value, true)
    end)
    table.insert(subDialog._controls, widthRow)

    local heightRow
    heightRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, "emHeight", 1, 100, moduleCfg.height, 1, function(value)
        ApplyCastbarSetting("height", value, true)
    end)
    table.insert(subDialog._controls, heightRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 1
    local borderSizeRow
    borderSizeRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, "emBorderSize", 1, 10, moduleCfg.borderWidth, 1, function(value)
        ApplyCastbarSetting("borderWidth", value, true)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, leftY = self:DialogAddColorPicker(subDialog._leftColumn or subDialog, leftY, "emBorderColor", moduleCfg.borderColor, function(value)
        ApplyCastbarSetting("borderColor", value, true)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)

    -- RIGHT COLUMN: Text & icon visibility
    local showSpellNameRow
    showSpellNameRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, "emShowSpellName", moduleCfg.showSpellName ~= false, function(value)
        ApplyCastbarSetting("showSpellName", value, true)
    end)
    table.insert(subDialog._controls, showSpellNameRow)

    local textSizeRow
    textSizeRow, rightY = self:DialogAddSlider(subDialog._rightColumn or subDialog, rightY, "emTextSize", 8, 32, moduleCfg.textSize, 1, function(value)
        ApplyCastbarSetting("textSize", value, true)
    end)
    table.insert(subDialog._controls, textSizeRow)

    local showCastTimeRow
    showCastTimeRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, "emShowCastTime", moduleCfg.showCastTime == true, function(value)
        ApplyCastbarSetting("showCastTime", value, true)
    end)
    table.insert(subDialog._controls, showCastTimeRow)

    local showIconRow
    showIconRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, "emShowIcon", moduleCfg.showIcon == true, function(value)
        ApplyCastbarSetting("showIcon", value, true)
    end)
    table.insert(subDialog._controls, showIconRow)

    local iconPositionRow
    iconPositionRow, rightY = self:DialogAddDropdown(subDialog._rightColumn or subDialog, rightY, "emIconPosition", {
        { label = "emLeft", value = "LEFT" },
        { label = "emRight", value = "RIGHT" },
    }, moduleCfg.iconPosition, function(value)
        ApplyCastbarSetting("iconPosition", value, true)
    end)
    table.insert(subDialog._controls, iconPositionRow)

    local textAlignmentRow
    textAlignmentRow, rightY = self:DialogAddDropdown(subDialog._rightColumn or subDialog, rightY, "emTextAlignment", {
        { label = "emLeft", value = "LEFT" },
        { label = "emRight", value = "RIGHT" },
        { label = "emCenter", value = "CENTER" },
    }, moduleCfg.textAlignment, function(value)
        ApplyCastbarSetting("textAlignment", value, true)
    end)
    table.insert(subDialog._controls, textAlignmentRow)
end

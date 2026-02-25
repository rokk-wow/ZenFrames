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
    self:RefreshModule(configKey, moduleKey)
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
    local enabledRow
    enabledRow, leftY = self:DialogAddEnableControl(subDialog._leftColumn or subDialog, leftY, "Enabled", moduleCfg.enabled, configKey, moduleKey, function(value)
        ApplyCastbarSetting("enabled", value, false)
    end)
    table.insert(subDialog._controls, enabledRow)

    local widthRow
    widthRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, "Width", 1, 500, moduleCfg.width, 1, function(value)
        ApplyCastbarSetting("width", value, true)
    end)
    table.insert(subDialog._controls, widthRow)

    local heightRow
    heightRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, "Height", 1, 100, moduleCfg.height, 1, function(value)
        ApplyCastbarSetting("height", value, true)
    end)
    table.insert(subDialog._controls, heightRow)

    local borderSizeGlobalValue = self.config.global and self.config.global.borderWidth or 1
    local borderSizeRow
    borderSizeRow, leftY = self:DialogAddSlider(subDialog._leftColumn or subDialog, leftY, "Border Size", 1, 10, moduleCfg.borderWidth, 1, function(value)
        ApplyCastbarSetting("borderWidth", value, true)
    end, {
        enabled = true,
        globalValue = borderSizeGlobalValue,
    })
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorGlobalValue = self.config.global and self.config.global.borderColor or "000000FF"
    local borderColorRow
    borderColorRow, leftY = self:DialogAddColorPicker(subDialog._leftColumn or subDialog, leftY, "Border Color", moduleCfg.borderColor, function(value)
        ApplyCastbarSetting("borderColor", value, true)
    end, {
        enabled = true,
        globalValue = borderColorGlobalValue,
    })
    table.insert(subDialog._controls, borderColorRow)

    -- RIGHT COLUMN: Text & icon visibility
    local showSpellNameRow
    showSpellNameRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, "Show Spell Name", moduleCfg.showSpellName ~= false, function(value)
        ApplyCastbarSetting("showSpellName", value, true)
    end)
    table.insert(subDialog._controls, showSpellNameRow)

    local textSizeRow
    textSizeRow, rightY = self:DialogAddSlider(subDialog._rightColumn or subDialog, rightY, "Text Size", 8, 32, moduleCfg.textSize, 1, function(value)
        ApplyCastbarSetting("textSize", value, true)
    end)
    table.insert(subDialog._controls, textSizeRow)

    local showCastTimeRow
    showCastTimeRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, "Show Cast Time", moduleCfg.showCastTime == true, function(value)
        ApplyCastbarSetting("showCastTime", value, true)
    end)
    table.insert(subDialog._controls, showCastTimeRow)

    local showIconRow
    showIconRow, rightY = self:DialogAddCheckbox(subDialog._rightColumn or subDialog, rightY, "Show Icon", moduleCfg.showIcon == true, function(value)
        ApplyCastbarSetting("showIcon", value, true)
    end)
    table.insert(subDialog._controls, showIconRow)

    local iconPositionRow
    iconPositionRow, rightY = self:DialogAddDropdown(subDialog._rightColumn or subDialog, rightY, "Icon Position", {
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }, moduleCfg.iconPosition, function(value)
        ApplyCastbarSetting("iconPosition", value, true)
    end)
    table.insert(subDialog._controls, iconPositionRow)

    local textAlignmentRow
    textAlignmentRow, rightY = self:DialogAddDropdown(subDialog._rightColumn or subDialog, rightY, "Text Alignment", {
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
        { label = "Center", value = "CENTER" },
    }, moduleCfg.textAlignment, function(value)
        ApplyCastbarSetting("textAlignment", value, true)
    end)
    table.insert(subDialog._controls, textAlignmentRow)
end

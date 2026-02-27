local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetRoleIconConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function UpdateRoleIconFrameVisual(self, unitFrame, moduleCfg)
    if not unitFrame or not moduleCfg then return end

    local roleIconFrame = unitFrame.RoleIcon
    if not roleIconFrame then return end

    local iconSize = moduleCfg.iconSize or moduleCfg.size or roleIconFrame:GetWidth() or 1
    roleIconFrame:SetSize(iconSize, iconSize)

    local iconTexture = unitFrame.GroupRoleIndicator
    if iconTexture and moduleCfg.color then
        local r, g, b, a = self:HexToRGB(moduleCfg.color)
        iconTexture:SetVertexColor(r, g, b, a)
    end
end

local function RefreshRoleIconVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetRoleIconConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            UpdateRoleIconFrameVisual(self, unitFrame, moduleCfg)
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
        UpdateRoleIconFrameVisual(self, unitFrame, moduleCfg)
    end
end

function addon:RefreshRoleIconEditModeVisuals(configKey, moduleKey)
    if not configKey then return end
    RefreshRoleIconVisuals(self, configKey, moduleKey or "roleIcon")
end

function addon:PopulateRoleIconSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetRoleIconConfig(self, configKey, moduleKey)
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

    local sizeValue = moduleCfg.iconSize or moduleCfg.size
    local sizeRow
    sizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "emSize", 10, 100, sizeValue, 1, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "iconSize"}, value)
        self:RefreshRoleIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)

    local colorRow
    colorRow, currentY = self:DialogAddColorPicker(subDialog, currentY, "emColor", moduleCfg.color, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "color"}, value)
        self:RefreshRoleIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, colorRow)
end

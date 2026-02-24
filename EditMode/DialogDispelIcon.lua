local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetDispelIconConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function UpdateDispelIconFrameVisual(unitFrame, moduleCfg)
    if not unitFrame or not moduleCfg then return end

    local dispelIconFrame = unitFrame.DispelIcon
    if not dispelIconFrame then return end

    local iconSize = moduleCfg.iconSize or dispelIconFrame:GetWidth() or 1
    dispelIconFrame:SetSize(iconSize, iconSize)
end

local function RefreshDispelIconVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetDispelIconConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            UpdateDispelIconFrameVisual(unitFrame, moduleCfg)
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
        UpdateDispelIconFrameVisual(unitFrame, moduleCfg)
    end
end

function addon:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    if not configKey then return end
    RefreshDispelIconVisuals(self, configKey, moduleKey or "dispelIcon")
end

function addon:PopulateDispelIconSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetDispelIconConfig(self, configKey, moduleKey)
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
        self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)
end

local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local resolveConfig = addon._resolveConfigForKey
local buildPath = addon._buildOverridePath

local function GetObjectiveCarrierConfig(self, configKey, moduleKey)
    local cfg = resolveConfig(configKey)
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function UpdateObjectiveCarrierFrameVisual(self, unitFrame, moduleCfg)
    if not unitFrame or not moduleCfg then return end

    local carrierFrame = unitFrame.ObjectiveCarrier
    if not carrierFrame then return end

    local iconSize = moduleCfg.size or carrierFrame:GetWidth() or 1
    carrierFrame:SetSize(iconSize, iconSize)
end

local function RefreshObjectiveCarrierVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetObjectiveCarrierConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            UpdateObjectiveCarrierFrameVisual(self, unitFrame, moduleCfg)
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
        UpdateObjectiveCarrierFrameVisual(self, unitFrame, moduleCfg)
    end
end

function addon:RefreshObjectiveCarrierEditModeVisuals(configKey, moduleKey)
    if not configKey then return end
    RefreshObjectiveCarrierVisuals(self, configKey, moduleKey or "objectiveCarrier")
end

function addon:PopulateObjectiveCarrierSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetObjectiveCarrierConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    subDialog._controls = subDialog._controls or {}

    local currentY = yOffset

    local onChange = function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "enabled"), value)
    end
    local enabledRow
    enabledRow, currentY = self:DialogAddEnableControl(subDialog, currentY, "emEnabled", moduleCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)

    local sizeRow
    sizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "emSize", 10, 60, moduleCfg.size or 20, 1, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "size"), value)
        self:RefreshObjectiveCarrierEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)
end

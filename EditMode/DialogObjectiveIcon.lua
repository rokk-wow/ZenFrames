local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local resolveConfig = addon._resolveConfigForKey
local buildPath = addon._buildOverridePath

local function GetObjectiveIconConfig(self, configKey, moduleKey)
    local cfg = resolveConfig(configKey)
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function UpdateObjectiveIconFrameVisual(self, unitFrame, moduleCfg)
    if not unitFrame or not moduleCfg then return end

    local iconFrame = unitFrame.ObjectiveIcon
    if not iconFrame then return end

    local iconSize = moduleCfg.iconSize or moduleCfg.size or iconFrame:GetWidth() or 1
    iconFrame:SetSize(iconSize, iconSize)
end

local function RefreshObjectiveIconVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetObjectiveIconConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            UpdateObjectiveIconFrameVisual(self, unitFrame, moduleCfg)
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
        UpdateObjectiveIconFrameVisual(self, unitFrame, moduleCfg)
    end
end

function addon:RefreshObjectiveIconEditModeVisuals(configKey, moduleKey)
    if not configKey then return end
    RefreshObjectiveIconVisuals(self, configKey, moduleKey or "objectiveIcon")
end

function addon:PopulateObjectiveIconSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetObjectiveIconConfig(self, configKey, moduleKey)
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

    local sizeValue = moduleCfg.iconSize or moduleCfg.size
    local sizeRow
    sizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "emSize", 8, 48, sizeValue, 1, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "iconSize"), value)
        self:RefreshObjectiveIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)
end

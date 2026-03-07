local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local resolveConfig = addon._resolveConfigForKey
local buildPath = addon._buildOverridePath

function addon:PopulateCombatIndicatorSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local cfg = resolveConfig(configKey)
    if not cfg or not cfg.modules or not cfg.modules[moduleKey] then return end

    local moduleCfg = cfg.modules[moduleKey]
    subDialog._controls = subDialog._controls or {}

    local onChange = function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "enabled"), value)
    end
    local enabledRow = self:DialogAddEnableControl(subDialog, yOffset, "emEnabled", moduleCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)
end

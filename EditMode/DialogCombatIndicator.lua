local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:PopulateCombatIndicatorSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules[moduleKey] then return end

    local moduleCfg = cfg.modules[moduleKey]
    subDialog._controls = subDialog._controls or {}

    local onChange = function(value)
        self:SetOverride({configKey, "modules", moduleKey, "enabled"}, value)
    end
    local enabledRow = self:DialogAddEnableControl(subDialog, yOffset, "emEnabled", moduleCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)
end

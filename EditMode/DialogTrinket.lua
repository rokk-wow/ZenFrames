local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:PopulateTrinketSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules[moduleKey] then return end

    local moduleCfg = cfg.modules[moduleKey]
    subDialog._controls = subDialog._controls or {}

    local enabledRow = self:DialogAddEnableControl(subDialog, yOffset, "Enabled", moduleCfg.enabled, configKey, moduleKey, function(value)
        self:SetOverride({configKey, "modules", moduleKey, "enabled"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)
end

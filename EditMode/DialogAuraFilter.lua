local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:PopulateAuraFilterSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.auraFilters then return end

    local filterIndex
    local filterCfg
    for i, entry in ipairs(cfg.modules.auraFilters) do
        if entry.name == moduleKey then
            filterIndex = i
            filterCfg = entry
            break
        end
    end

    if not filterIndex or not filterCfg then return end

    subDialog._controls = subDialog._controls or {}

    local enabledRow = self:DialogAddEnableControl(subDialog, yOffset, "Enabled", filterCfg.enabled, configKey, moduleKey, function(value)
        self:SetOverride({configKey, "modules", "auraFilters", filterIndex, "enabled"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)
end

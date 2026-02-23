local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:PopulateUnitFrameSubDialog(subDialog, configKey, moduleKey, titleFontSize)
    if not subDialog or not configKey then return end

    local cfg = self.config[configKey]
    if not cfg then return end

    subDialog._controls = subDialog._controls or {}

    local yOffset = -(subDialog._borderWidth + subDialog._padding + (titleFontSize or 16) + 40)

    local enabledRow = self:DialogAddEnableControl(subDialog, yOffset, "Enabled", cfg.enabled, configKey, nil, function(value)
        self:SetOverride({configKey, "enabled"}, value)
        self:SetOverride({configKey, "hideBlizzard"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)
end

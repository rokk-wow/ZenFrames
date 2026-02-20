local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:SetupModulesSettingsPanel()
    self:AddSettingsPanel("modules", {
        title = "modulesTitle",
        controls = {
            {
                type = "header",
                name = "modulesHeader",
            },
            {
                type = "checkbox",
                name = "partyEnabled",
                default = true,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "checkbox",
                name = "arenaEnabled",
                default = true,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "header",
                name = "experimentalHeader",
            },
            {
                type = "checkbox",
                name = "playerEnabled",
                default = false,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "checkbox",
                name = "targetEnabled",
                default = false,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "checkbox",
                name = "targetTargetEnabled",
                default = false,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "checkbox",
                name = "focusEnabled",
                default = false,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "checkbox",
                name = "focusTargetEnabled",
                default = false,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "checkbox",
                name = "petEnabled",
                default = false,
                onValueChange = function()
                    self.config = self:GetCustomConfig() or self:GetConfig()
                end,
            },
            {
                type = "description",
                name = "reloadRequiredLabel",
            },
            {
                type = "button",
                name = "reloadUI",
                onClick = function()
                    ReloadUI()
                end,
            },
        },
    })
end

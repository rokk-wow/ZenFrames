local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:SetupPartySettingsPanel()
    local function refreshConfig()
        self.config = self:GetCustomConfig() or self:GetConfig()
    end

    self:AddSettingsPanel("party", {
        title = "partyTitle",
        controls = {
            {
                type = "header",
                name = "partyTrinketHeader",
            },
            {
                type = "checkbox",
                name = "partyTrinketEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "partyArenaTargetsHeader",
            },
            {
                type = "checkbox",
                name = "partyArenaTargetsEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "partyCastbarHeader",
            },
            {
                type = "checkbox",
                name = "partyCastbarEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "partyCrowdControlHeader",
            },
            {
                type = "checkbox",
                name = "partyCrowdControlEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "partyCrowdControlGlow",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "colorPicker",
                name = "partyCrowdControlGlowColor",
                default = "#FF0000",
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "partyDefensivesHeader",
            },
            {
                type = "checkbox",
                name = "partyDefensivesEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "partyDefensivesGlow",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "colorPicker",
                name = "partyDefensivesGlowColor",
                default = "#00FF98",
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "partyImportantBuffsHeader",
            },
            {
                type = "checkbox",
                name = "partyImportantBuffsEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "partyImportantBuffsGlow",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "colorPicker",
                name = "partyImportantBuffsGlowColor",
                default = "#55BBFF",
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "partyDispelHeader",
            },
            {
                type = "checkbox",
                name = "partyDispelIconEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "partyDispelHighlightEnabled",
                default = false,
                onValueChange = refreshConfig,
            },
        }
    })
end

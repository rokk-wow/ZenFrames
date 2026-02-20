local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:SetupArenaSettingsPanel()
    local function refreshConfig()
        self.config = self:GetCustomConfig() or self:GetConfig()
    end

    self:AddSettingsPanel("arena", {
        title = "arenaTitle",
        controls = {
            {
                type = "header",
                name = "arenaTrinketHeader",
            },
            {
                type = "checkbox",
                name = "arenaTrinketEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "arenaArenaTargetsHeader",
            },
            {
                type = "checkbox",
                name = "arenaArenaTargetsEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "arenaCastbarHeader",
            },
            {
                type = "checkbox",
                name = "arenaCastbarEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "arenaCrowdControlHeader",
            },
            {
                type = "checkbox",
                name = "arenaCrowdControlEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "arenaCrowdControlGlow",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "colorPicker",
                name = "arenaCrowdControlGlowColor",
                default = "#FF0000",
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "arenaDefensivesHeader",
            },
            {
                type = "checkbox",
                name = "arenaDefensivesEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "arenaDefensivesGlow",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "colorPicker",
                name = "arenaDefensivesGlowColor",
                default = "#00FF98",
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "arenaImportantBuffsHeader",
            },
            {
                type = "checkbox",
                name = "arenaImportantBuffsEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "checkbox",
                name = "arenaImportantBuffsGlow",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "colorPicker",
                name = "arenaImportantBuffsGlowColor",
                default = "#55BBFF",
                onValueChange = refreshConfig,
            },
            {
                type = "header",
                name = "arenaDRTrackerHeader",
            },
            {
                type = "checkbox",
                name = "arenaDRTrackerEnabled",
                default = true,
                onValueChange = refreshConfig,
            },
            {
                type = "divider",
            },
            {
                type = "description",
                name = "arenaReloadDescription",
            },
            {
                type = "button",
                name = "reloadUI",
                onClick = function() ReloadUI() end,
            },
        }
    })
end

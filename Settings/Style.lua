local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:SetupStyleSettingsPanel()
    local fontOptions      = self:MediaDropdownOptions("font")
    local statusbarOptions = self:MediaDropdownOptions("statusbar")

    local function refreshStyle()
        self.config = self:GetCustomConfig() or self:GetConfig()
        self:RefreshStyle()
    end

    self:AddSettingsPanel("style", {
        title = "styleTitle",
        controls = {
            {
                type = "header",
                name = "frameMoverHeader",
            },
            {
                type = "button",
                name = "resetFramePositions",
                onClick = function()
                    self:ResetFramePositions()
                end,
            },
            {
                type = "header",
                name = "styleHeader",
            },
            {
                type = "dropdown",
                name = "font",
                default = "DorisPP",
                options = fontOptions,
                onValueChange = refreshStyle,
            },
            {
                type = "dropdown",
                name = "healthTexture",
                default = "Smooth",
                options = statusbarOptions,
                onValueChange = refreshStyle,
            },
            {
                type = "dropdown",
                name = "powerTexture",
                default = "Minimalist",
                options = statusbarOptions,
                onValueChange = refreshStyle,
            },
            {
                type = "dropdown",
                name = "castbarTexture",
                default = "Smooth",
                options = statusbarOptions,
                onValueChange = refreshStyle,
            },
            {
                type = "dropdown",
                name = "absorbTexture",
                default = "Diagonal",
                options = statusbarOptions,
                onValueChange = refreshStyle,
            },
            {
                type = "divider",
            },
            {
                type = "inputBox",
                name = "largeFrameLeftText",
                default = "[name:medium]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "largeFrameLeftText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "inputBox",
                name = "largeFrameRightText",
                default = "[perhp]% / [maxhp:short]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "largeFrameRightText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "inputBox",
                name = "smallFrameText",
                default = "[name:short]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "smallFrameText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "inputBox",
                name = "partyFrameLeftText",
                default = "[name:short]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "partyFrameLeftText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "inputBox",
                name = "partyFrameRightText",
                default = "[spec]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "partyFrameRightText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "inputBox",
                name = "arenaFrameLeftText",
                default = "[name:short]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "arenaFrameLeftText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "inputBox",
                name = "arenaFrameRightText",
                default = "[spec]",
                buttonText = "apply",
                onClick = function(_, inputText)
                    self:SetValue("style", "arenaFrameRightText", inputText)
                    refreshStyle()
                end,
            },
            {
                type = "button",
                name = "textTagHelp",
                onClick = function()
                    self:ShowTextTagHelp()
                end,
            },
        },
    })
end

function addon:ShowTextTagHelp()
    self:_ShowDialog({
        title = "textTagHelpTitle",
        controls = {{
            type = "inputBox",
            name = "textTagHelpURL",
            default = "https://example.com",
            highlightText = true,
            sessionOnly = true,
        }},
    })
end

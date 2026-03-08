local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Action Bar Definitions
-- ---------------------------------------------------------------------------

addon.actionBarDefs = {
    { name = "MainMenuBar", buttonPrefix = "ActionButton", fadeKey = "actionBar1", displayName = "Action Bar 1" },
    { name = "MultiBarBottomLeft", buttonPrefix = "MultiBarBottomLeftButton", fadeKey = "actionBar2", displayName = "Action Bar 2" },
    { name = "MultiBarBottomRight", buttonPrefix = "MultiBarBottomRightButton", fadeKey = "actionBar3", displayName = "Action Bar 3" },
    { name = "MultiBarRight", buttonPrefix = "MultiBarRightButton", fadeKey = "actionBar4", displayName = "Action Bar 4" },
    { name = "MultiBarLeft", buttonPrefix = "MultiBarLeftButton", fadeKey = "actionBar5", displayName = "Action Bar 5" },
    { name = "MultiBar5", buttonPrefix = "MultiBar5Button", fadeKey = "actionBar6", displayName = "Action Bar 6" },
    { name = "MultiBar6", buttonPrefix = "MultiBar6Button", fadeKey = "actionBar7", displayName = "Action Bar 7" },
    { name = "MultiBar7", buttonPrefix = "MultiBar7Button", fadeKey = "actionBar8", displayName = "Action Bar 8" },
    { name = "PetActionBar", buttonPrefix = "PetActionButton", fadeKey = "petBar", displayName = "Pet Bar" },
    { name = "StanceBar", buttonPrefix = "StanceButton", fadeKey = "stanceBar", displayName = "Stance Bar" },
}

-- ---------------------------------------------------------------------------
-- Iterator Helpers
-- ---------------------------------------------------------------------------

local function IterateActionButtons(callback)
    if type(callback) ~= "function" then return end

    for _, barInfo in ipairs(addon.actionBarDefs) do
        local prefix = barInfo.buttonPrefix
        for i = 1, 12 do
            local buttonName = prefix .. i
            local button = _G[buttonName]
            if button then
                callback(button, buttonName)
            end
        end
    end
end

local function IterateActionBars(callback)
    if type(callback) ~= "function" then return end

    for _, barInfo in ipairs(addon.actionBarDefs) do
        local frame = _G[barInfo.name]
        if frame then
            callback(frame, barInfo.name)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Add Borders to Action Buttons
-- ---------------------------------------------------------------------------

local function AddActionButtonBorders(cfg)
    local r, g, b, a = addon:HexToRGB(cfg.borderColor)
    local size = cfg.borderWidth

    IterateActionButtons(function(button, buttonName)
        local normalTexture = button:GetNormalTexture()
        if normalTexture then
            normalTexture:SetAlpha(0)
            normalTexture:Hide()
        end

        if button.NormalTexture then
            button.NormalTexture:SetAlpha(0)
            button.NormalTexture:Hide()
        end

        if not button.ZenFrames_Borders then
            local borders = {}

            borders.top = button:CreateTexture(nil, "OVERLAY")
            borders.top:SetColorTexture(r, g, b, a)
            borders.top:SetHeight(size)
            borders.top:ClearAllPoints()
            borders.top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            borders.top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

            borders.bottom = button:CreateTexture(nil, "OVERLAY")
            borders.bottom:SetColorTexture(r, g, b, a)
            borders.bottom:SetHeight(size)
            borders.bottom:ClearAllPoints()
            borders.bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
            borders.bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

            borders.left = button:CreateTexture(nil, "OVERLAY")
            borders.left:SetColorTexture(r, g, b, a)
            borders.left:SetWidth(size)
            borders.left:ClearAllPoints()
            borders.left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            borders.left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)

            borders.right = button:CreateTexture(nil, "OVERLAY")
            borders.right:SetColorTexture(r, g, b, a)
            borders.right:SetWidth(size)
            borders.right:ClearAllPoints()
            borders.right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
            borders.right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

            button.ZenFrames_Borders = borders
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Set Button Padding
-- ---------------------------------------------------------------------------

local function SetButtonPadding(padding)
    IterateActionBars(function(bar, name)
        if bar.SetAttribute then
            bar:SetAttribute("buttonSpacing", padding)
        end

        if bar.UpdateGridLayout then
            hooksecurefunc(bar, "UpdateGridLayout", function(self)
                if self.SetAttribute then
                    self:SetAttribute("buttonSpacing", padding)
                end
            end)
            bar:UpdateGridLayout()
        elseif bar.Layout then
            bar:Layout()
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Hide Proc Glow (SpellActivationAlert)
-- ---------------------------------------------------------------------------

local function HideProcGlow()
    IterateActionButtons(function(button, buttonName)
        if button.SpellActivationAlert then
            button.SpellActivationAlert:Hide()
            button.SpellActivationAlert:SetAlpha(0)

            if not button.SpellActivationAlert.__ZenFrames_HideHooked then
                button.SpellActivationAlert.__ZenFrames_HideHooked = true
                hooksecurefunc(button.SpellActivationAlert, "Show", function(self)
                    self:Hide()
                    self:SetAlpha(0)
                end)
            end
        end
    end)

    if ActionButtonSpellAlertManager and not ActionButtonSpellAlertManager.__ZenFrames_Hooked then
        ActionButtonSpellAlertManager.__ZenFrames_Hooked = true
        hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(self, actionButton)
            if type(actionButton) ~= "table" then
                actionButton = self
            end

            if actionButton and actionButton.SpellActivationAlert then
                actionButton.SpellActivationAlert:Hide()
                actionButton.SpellActivationAlert:SetAlpha(0)
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Hide Spell Activation Overlay
-- ---------------------------------------------------------------------------

local function HideSpellActivationOverlay()
    if SpellActivationOverlayFrame then
        SpellActivationOverlayFrame:Hide()
        SpellActivationOverlayFrame:SetAlpha(0)

        hooksecurefunc(SpellActivationOverlayFrame, "Show", function(self)
            self:Hide()
            self:SetAlpha(0)
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Hide Macro Text
-- ---------------------------------------------------------------------------

local function HideMacroText()
    IterateActionButtons(function(button, buttonName)
        if button.Name then
            button.Name:SetAlpha(0)
            button.Name:Hide()
            hooksecurefunc(button.Name, "Show", function(self)
                self:SetAlpha(0)
            end)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Hide Keybind Text
-- ---------------------------------------------------------------------------

local function HideKeybindText()
    IterateActionButtons(function(button, buttonName)
        if button.HotKey then
            button.HotKey:SetAlpha(0)
            button.HotKey:Hide()
            hooksecurefunc(button.HotKey, "Show", function(self)
                self:SetAlpha(0)
            end)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Hide Spell Cast Anim Frame
-- ---------------------------------------------------------------------------

local function HideSpellCastAnim()
    IterateActionButtons(function(button, buttonName)
        if button.SpellCastAnimFrame then
            button.SpellCastAnimFrame:SetAlpha(0)
            button.SpellCastAnimFrame:Hide()

            hooksecurefunc(button.SpellCastAnimFrame, "Show", function(self)
                self:SetAlpha(0)
            end)

            local subElements = { "Fill", "InnerGlow", "FillMask", "Ants", "Spark" }
            for _, key in ipairs(subElements) do
                if button.SpellCastAnimFrame[key] then
                    button.SpellCastAnimFrame[key]:SetAlpha(0)
                    button.SpellCastAnimFrame[key]:Hide()
                    hooksecurefunc(button.SpellCastAnimFrame[key], "Show", function(self)
                        self:SetAlpha(0)
                    end)
                end
            end
        end

        if button.InterruptDisplay then
            button.InterruptDisplay:SetAlpha(0)
            button.InterruptDisplay:Hide()
            hooksecurefunc(button.InterruptDisplay, "Show", function(self)
                self:SetAlpha(0)
            end)
            if button.InterruptDisplay.Base then
                button.InterruptDisplay.Base:SetAlpha(0)
                button.InterruptDisplay.Base:Hide()
            end
            if button.InterruptDisplay.Highlight then
                button.InterruptDisplay.Highlight:SetAlpha(0)
                button.InterruptDisplay.Highlight:Hide()
            end
        end

        local checkedTexture = button:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:SetAlpha(0)
            checkedTexture:Hide()
        end
        hooksecurefunc(button, "SetChecked", function(self)
            if self:GetChecked() then
                local tex = self:GetCheckedTexture()
                if tex then
                    tex:SetAlpha(0)
                    tex:Hide()
                end
            end
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- Add Action Bar Backgrounds
-- ---------------------------------------------------------------------------

local function AddActionBarBackgrounds(bgOpacity)
    IterateActionBars(function(bar, name)
        if bar.GetSettingValueBool then
            local alwaysShowButtons = bar:GetSettingValueBool(9)

            if alwaysShowButtons and not bar.ZenFrames_Background then
                local bg = bar:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(bar)
                bg:SetColorTexture(0, 0, 0, bgOpacity)
                bar.ZenFrames_Background = bg
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Customize Assisted Highlight Glow
-- ---------------------------------------------------------------------------

local function CustomizeAssistedHighlight(highlightColor)
    local r, g, b, a = addon:HexToRGB(highlightColor)

    IterateActionButtons(function(button, buttonName)
        if button.AssistedCombatHighlightFrame then
            local inCombat = UnitAffectingCombat("player")
            if not inCombat then
                button.AssistedCombatHighlightFrame:Hide()
            end
        end
    end)

    if AssistedCombatManager then
        hooksecurefunc(AssistedCombatManager, "SetAssistedHighlightFrameShown", function(self, actionButton, shown)
            local highlightFrame = actionButton.AssistedCombatHighlightFrame
            local inCombat = UnitAffectingCombat("player")

            if highlightFrame and highlightFrame:IsVisible() and shown and inCombat then
                local flipbook = highlightFrame.Flipbook
                if flipbook then
                    flipbook:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
                    flipbook:SetDesaturated(true)
                    flipbook:SetVertexColor(r, g, b, a)

                    local anim = flipbook.Anim:GetAnimations()
                    if anim then
                        flipbook:ClearAllPoints()
                        flipbook:SetSize(flipbook:GetSize())
                        flipbook:SetPoint("CENTER", highlightFrame, "CENTER", -1.5, 1)

                        flipbook.Anim:Stop()
                        flipbook.Anim:Play()
                    end
                end
            elseif highlightFrame and not inCombat then
                highlightFrame:Hide()
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Zoom Button Icons
-- ---------------------------------------------------------------------------

local function ZoomButtonIcons(iconZoom)
    local inset = iconZoom / 2

    IterateActionButtons(function(button, buttonName)
        if button.icon then
            button.icon:SetTexCoord(inset, 1 - inset, inset, 1 - inset)

            if button.cooldown then
                button.cooldown:ClearAllPoints()
                button.cooldown:SetAllPoints(button)
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Fade Bars on Mouseover
-- ---------------------------------------------------------------------------

local function UpdateFadeBars(fadeCfg)
    local fadeBars = {}

    for _, barInfo in ipairs(addon.actionBarDefs) do
        if fadeCfg[barInfo.fadeKey] then
            local frame = _G[barInfo.name]
            if frame then
                fadeBars[#fadeBars + 1] = { frame = frame, info = barInfo }
            end
        end
    end

    if #fadeBars == 0 then return end

    local function FadeAllIn()
        for _, entry in ipairs(fadeBars) do
            if InCombatLockdown() then
                entry.frame:SetAlpha(1)
            else
                UIFrameFadeIn(entry.frame, 0.2, entry.frame:GetAlpha(), 1)
            end
        end
    end

    local function FadeAllOut()
        for _, entry in ipairs(fadeBars) do
            if InCombatLockdown() then
                entry.frame:SetAlpha(0)
            else
                UIFrameFadeOut(entry.frame, 0.2, entry.frame:GetAlpha(), 0)
            end
        end
    end

    for _, entry in ipairs(fadeBars) do
        entry.frame:EnableMouse(true)
        entry.frame:SetScript("OnEnter", FadeAllIn)
        entry.frame:SetScript("OnLeave", FadeAllOut)

        local prefix = entry.info.buttonPrefix
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                button:HookScript("OnEnter", FadeAllIn)
                button:HookScript("OnLeave", FadeAllOut)
            end
        end

        entry.frame:SetAlpha(0)
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeActionBars()
    local cfg = self.config and self.config.extras and self.config.extras.actionBars
    if not cfg or not cfg.enabled then return end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function()
        self:CombatSafe(function()
            if cfg.hideProcGlow then
                HideProcGlow()
            end

            if cfg.hideSpellActivationOverlay then
                HideSpellActivationOverlay()
            end

            AddActionButtonBorders(cfg)
            SetButtonPadding(cfg.buttonPadding)

            if cfg.hideMacroText then
                HideMacroText()
            end

            if cfg.hideKeybindText then
                HideKeybindText()
            end

            if cfg.hideSpellCastAnim then
                HideSpellCastAnim()
            end

            if cfg.addBarBackgrounds then
                AddActionBarBackgrounds(cfg.barBackgroundOpacity)
            end

            if cfg.customizeAssistedHighlight then
                CustomizeAssistedHighlight(cfg.assistedHighlightColor)
            end

            ZoomButtonIcons(cfg.iconZoom)
            UpdateFadeBars(cfg.fadeBars)
        end)
    end)
end

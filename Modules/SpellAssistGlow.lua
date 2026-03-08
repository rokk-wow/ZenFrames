local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Proc Glow Creation
-- ---------------------------------------------------------------------------

local function CreateProcGlow(parent, glowScale, r, g, b, animationDuration)
    local procGlow = CreateFrame("Frame", nil, parent)
    procGlow:SetSize(parent:GetWidth() * glowScale, parent:GetHeight() * glowScale)
    procGlow:SetPoint("CENTER")

    local procLoop = procGlow:CreateTexture(nil, "ARTWORK")
    procLoop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    procLoop:SetAllPoints(procGlow)
    procLoop:SetAlpha(0)

    if r ~= nil and g ~= nil and b ~= nil then
        procLoop:SetDesaturated(true)
        procLoop:SetVertexColor(r, g, b)
    end

    procGlow.ProcLoopFlipbook = procLoop

    local procLoopAnim = procGlow:CreateAnimationGroup()
    procLoopAnim:SetLooping("REPEAT")

    local alpha = procLoopAnim:CreateAnimation("Alpha")
    alpha:SetChildKey("ProcLoopFlipbook")
    alpha:SetDuration(0.001)
    alpha:SetOrder(0)
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(1)

    local flip = procLoopAnim:CreateAnimation("FlipBook")
    flip:SetChildKey("ProcLoopFlipbook")
    flip:SetDuration(animationDuration)
    flip:SetOrder(0)
    flip:SetFlipBookRows(6)
    flip:SetFlipBookColumns(5)
    flip:SetFlipBookFrames(30)

    procGlow.ProcLoop = procLoopAnim

    return procGlow
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeSpellAssistGlow()
    local cfg = self.config and self.config.extras and self.config.extras.spellAssistGlow
    if not cfg or not cfg.enabled then return end

    local r, g, b = self:HexToRGB(cfg.glowColor)
    local glowScale = cfg.glowScale
    local animationDuration = cfg.animationDuration
    local viewerFrameName = cfg.viewerFrameName

    self:RegisterEvent("UNIT_AURA", function(event, unit)
        if unit ~= "player" then return end

        local viewer = _G[viewerFrameName]
        if not viewer then return end

        for _, child in pairs({viewer:GetChildren()}) do
            if child.Icon and not child.ZenFrames_ProcGlow then
                local procGlow = CreateProcGlow(child, glowScale, r, g, b, animationDuration)
                procGlow.ProcLoop:Play()
                child.ZenFrames_ProcGlow = procGlow
            end
        end
    end)
end

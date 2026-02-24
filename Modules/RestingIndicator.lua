local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddRestingIndicator(frame, cfg)
    local size = cfg.size

    local RestingFrame = CreateFrame("Frame", nil, frame)
    RestingFrame:SetFrameStrata(cfg.strata)
    RestingFrame:SetSize(size, size)
    RestingFrame:SetPoint(
        cfg.anchor,
        _G[cfg.relativeTo] or frame,
        cfg.relativePoint,
        cfg.offsetX,
        cfg.offsetY
    )

    local texture = RestingFrame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(RestingFrame)
    if cfg.atlasTexture then
        texture:SetAtlas(cfg.atlasTexture, false)
    end

    RestingFrame.PostUpdate = function(element, isResting)
        if isResting and not UnitAffectingCombat("player") then
            element:Show()
        else
            element:Hide()
        end
    end

    frame.RestingIndicator = RestingFrame
    addon:AttachPlaceholder(RestingFrame)
end

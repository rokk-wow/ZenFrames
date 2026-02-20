local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddRestingIndicator(frame, cfg)
    local size = cfg.size or 24

    local RestingFrame = CreateFrame("Frame", nil, frame)
    RestingFrame:SetFrameStrata(cfg.strata or "HIGH")
    RestingFrame:SetSize(size, size)
    RestingFrame:SetPoint(
        cfg.anchor or "CENTER",
        _G[cfg.relativeTo] or frame,
        cfg.relativePoint or "CENTER",
        cfg.offsetX or 0,
        cfg.offsetY or 0
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
end

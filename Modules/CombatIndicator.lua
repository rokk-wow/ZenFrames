local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddCombatIndicator(frame, cfg)
    local size = cfg.size or 24

    local CombatFrame = CreateFrame("Frame", nil, frame)
    CombatFrame:SetFrameStrata(cfg.strata or "HIGH")
    CombatFrame:SetSize(size, size)
    CombatFrame:SetPoint(
        cfg.anchor or "CENTER",
        _G[cfg.relativeTo] or frame,
        cfg.relativePoint or "CENTER",
        cfg.offsetX or 0,
        cfg.offsetY or 0
    )
    CombatFrame:Hide()

    local texture = CombatFrame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(CombatFrame)
    if cfg.atlasTexture then
        texture:SetAtlas(cfg.atlasTexture, false)
    end

    local RestingFrame = frame.RestingIndicator
    CombatFrame.PostUpdate = function(element, inCombat)
        if inCombat then
            element:Show()
            if RestingFrame then
                RestingFrame:Hide()
            end
        else
            element:Hide()
            if RestingFrame and IsResting() then
                RestingFrame:Show()
            end
        end
    end

    frame.CombatIndicator = CombatFrame
end

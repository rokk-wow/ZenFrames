local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddObjectiveCarrier(frame, cfg)
    local size = cfg.size or 20

    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(size, size)
    container:SetFrameLevel(frame:GetFrameLevel() + 10)
    container:SetPoint(
        cfg.anchor or "TOP",
        cfg.relativeTo and _G[cfg.relativeTo] or frame,
        cfg.relativePoint or "TOP",
        cfg.offsetX or 0,
        cfg.offsetY or -2
    )

    local icon = container:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(container)

    icon.Override = function(self, event, unit)
        if unit ~= self.unit then return end

        local element = self.PvPClassificationIndicator
        local classification = UnitPvpClassification(unit)
        local iconKey = classification and addon.ObjectiveCarrierClassificationMap[classification]
        local iconData = iconKey and addon.config.global and addon.config.global.objectiveCarrierIcons and addon.config.global.objectiveCarrierIcons[iconKey]

        print("[ZF-ObjCarrier]", "event=" .. tostring(event), "unit=" .. tostring(unit), "class=" .. tostring(classification), "iconKey=" .. tostring(iconKey), "hasData=" .. tostring(iconData ~= nil))

        if iconData then
            element:SetAtlas(iconData.atlas, false)
            element:SetDesaturated(iconData.desaturate or false)
            if iconData.color then
                local r, g, b = addon:HexToRGB(iconData.color)
                element:SetVertexColor(r, g, b)
            else
                element:SetVertexColor(1, 1, 1)
            end
            element:Show()
            element:GetParent():Show()
        else
            element:Hide()
            element:GetParent():Hide()
        end
    end

    container:Hide()
    frame.PvPClassificationIndicator = icon
    frame.ObjectiveCarrier = container
    addon:AttachPlaceholder(container)
end

addon.ObjectiveCarrierClassificationMap = {
    [Enum.PvPUnitClassification.FlagCarrierHorde or 0] = "flagHorde",
    [Enum.PvPUnitClassification.FlagCarrierAlliance or 1] = "flagAlliance",
    [Enum.PvPUnitClassification.FlagCarrierNeutral or 2] = "flagNeutral",
    [Enum.PvPUnitClassification.CartRunnerHorde or 3] = "cartHorde",
    [Enum.PvPUnitClassification.CartRunnerAlliance or 4] = "cartAlliance",
    [Enum.PvPUnitClassification.OrbCarrierBlue or 7] = "orbBlue",
    [Enum.PvPUnitClassification.OrbCarrierGreen or 8] = "orbGreen",
    [Enum.PvPUnitClassification.OrbCarrierOrange or 9] = "orbOrange",
    [Enum.PvPUnitClassification.OrbCarrierPurple or 10] = "orbPurple",
}

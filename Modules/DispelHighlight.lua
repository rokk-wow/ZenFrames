local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local TYPE_MAP = {
    Magic   = oUF.Enum.DispelType.Magic,
    Curse   = oUF.Enum.DispelType.Curse,
    Disease = oUF.Enum.DispelType.Disease,
    Poison  = oUF.Enum.DispelType.Poison,
    Bleed   = oUF.Enum.DispelType.Bleed,
    Enrage  = oUF.Enum.DispelType.Enrage,
}

local dispelColorCurve

local function EnsureDispelColorCurve()
    if dispelColorCurve then return end

    local globalDispel = addon.config.global.dispelColors or {}

    dispelColorCurve = C_CurveUtil.CreateColorCurve()
    dispelColorCurve:SetType(Enum.LuaCurveType.Step)

    for name, enumVal in pairs(TYPE_MAP) do
        local hex = globalDispel[name]
        if hex then
            local r, g, b, a = addon:HexToRGB(hex)
            dispelColorCurve:AddPoint(enumVal, CreateColor(r, g, b, a or 1))
        end
    end
end

function addon:AddDispelHighlight(frame, cfg)
    local borderWidth = cfg.borderWidth

    local inner = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    inner:SetAllPoints(frame)
    inner:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderWidth,
        insets = { left = borderWidth, right = borderWidth, top = borderWidth, bottom = borderWidth },
    })
    inner:SetFrameStrata("HIGH")
    inner:SetFrameLevel(frame:GetFrameLevel() + 20)
    inner:Hide()

    frame.DispelHighlight = inner
end

local function Update(self, event, unit)
    if unit and self.unit ~= unit then return end

    local element = self.DispelHighlight
    if not element then return end

    unit = self.unit
    if not unit or not UnitExists(unit) then
        element:Hide()
        return
    end

    EnsureDispelColorCurve()

    local foundColor = nil

    local slots = { C_UnitAuras.GetAuraSlots(unit, "HARMFUL") }
    for i = 2, #slots do
        local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if data and data.auraInstanceID then
            if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, "HARMFUL|RAID") then
                local ok, color = pcall(
                    C_UnitAuras.GetAuraDispelTypeColor,
                    unit, data.auraInstanceID, dispelColorCurve
                )

                if ok and color then
                    foundColor = color
                    break
                end
            end
        end
    end

    if foundColor then
        element:SetBackdropBorderColor(foundColor:GetRGBA())
        element:Show()
    else
        element:Hide()
    end
end

local function Enable(self)
    local element = self.DispelHighlight
    if not element then return end

    self:RegisterEvent("UNIT_AURA", Update)

    Update(self, "Enable")
    return true
end

local function Disable(self)
    local element = self.DispelHighlight
    if not element then return end

    element:Hide()
    self:UnregisterEvent("UNIT_AURA", Update)
end

oUF:AddElement("DispelHighlight", Update, Enable, Disable)

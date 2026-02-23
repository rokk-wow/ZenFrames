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

local typeCurves
local white = CreateColor(1, 1, 1, 1)

local function EnsureTypeCurves()
    if typeCurves then return end
    typeCurves = {}

    for name, enumVal in pairs(TYPE_MAP) do
        local curve = C_CurveUtil.CreateColorCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(enumVal, white)
        typeCurves[name] = curve
    end
end

local function GetDispelType(unit, auraInstanceID)
    for name, curve in pairs(typeCurves) do
        local ok, color = pcall(
            C_UnitAuras.GetAuraDispelTypeColor,
            unit, auraInstanceID, curve
        )
        if ok and color then
            return name
        end
    end
    return nil
end

function addon:AddDispelIcon(frame, cfg)
    local size = cfg.iconSize or 36
    local borderWidth = cfg.iconBorderWidth or 1

    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(size, size)

    local anchorFrame = frame
    -- DEPRECATED: relativeToModule is deprecated. Use direct frame anchoring with calculated offsets instead.
    -- This logic remains for backwards compatibility with existing custom configs.
    if cfg.relativeToModule then
        local ref = cfg.relativeToModule
        if type(ref) == "table" then
            for _, key in ipairs(ref) do
                if frame[key] then
                    anchorFrame = frame[key]
                    break
                end
            end
        else
            anchorFrame = frame[ref] or frame
        end
    end

    local frameBorderWidth = cfg.frameBorderWidth or 0
    container:SetPoint(
        cfg.anchor or "TOPLEFT",
        anchorFrame,
        cfg.relativePoint or "TOPRIGHT",
        cfg.offsetX or 0,
        (cfg.offsetY or 0) + frameBorderWidth - borderWidth
    )

    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(container)
    container.Icon = icon

    addon:AddTextureBorder(container, borderWidth, cfg.iconBorderColor or "000000FF")

    container:SetFrameLevel(frame:GetFrameLevel() + 10)
    container:Hide()

    frame.DispelIcon = container
    addon:AttachPlaceholder(container)
end

local function Update(self, event, unit)
    if unit and self.unit ~= unit then return end

    local element = self.DispelIcon
    if not element then return end

    unit = self.unit
    if not unit or not UnitExists(unit) then
        element:Hide()
        return
    end

    EnsureTypeCurves()

    local foundType = nil

    local slots = { C_UnitAuras.GetAuraSlots(unit, "HARMFUL") }
    for i = 2, #slots do
        local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if data and data.auraInstanceID then
            if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, "HARMFUL|RAID") then
                foundType = GetDispelType(unit, data.auraInstanceID)
                if foundType then break end
            end
        end
    end

    if foundType then
        local textures = addon.config.global.dispelTextures or {}
        local atlas = textures[foundType] or textures.default or "icons_64x64_deadly"
        element.Icon:SetAtlas(atlas)
        element:Show()
    else
        element:Hide()
    end
end

local function Enable(self)
    local element = self.DispelIcon
    if not element then return end

    self:RegisterEvent("UNIT_AURA", Update)

    Update(self, "Enable")
    return true
end

local function Disable(self)
    local element = self.DispelIcon
    if not element then return end

    element:Hide()
    self:UnregisterEvent("UNIT_AURA", Update)
end

oUF:AddElement("DispelIcon", Update, Enable, Disable)

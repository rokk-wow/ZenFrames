local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local ICON_SIZE = 30
local SPACING = 2
local MAX_ICONS = 10
local COLS = 10
local ROW_HEIGHT = ICON_SIZE + 16
local POC_FONT = "Fonts\\FRIZQT__.TTF"

local FILTERS = {
    "PLAYER",
    "CANCELABLE",
    "NOT_CANCELABLE",
    "RAID",
    "INCLUDE_NAME_PLATE_ONLY",
    "EXTERNAL_DEFENSIVE",
    "CROWD_CONTROL",
    "RAID_IN_COMBAT",
    "RAID_PLAYER_DISPELLABLE",
    "BIG_DEFENSIVE",
    "IMPORTANT",
    "MAW",
}

function addon:CreateAuraFilterDebug(cfg)
    local friendlyUnits = cfg.friendlyUnits or { "party1" }
    local hostileUnits  = cfg.hostileUnits or { "target" }
    local allRefreshFuncs = {}

    local function CreateFilterRow(baseFilter, filterName, anchor, rowIndex, rowUnits)
        local frameName = "frmdDebug_" .. baseFilter .. "_" .. filterName
        local testFilter = baseFilter .. "|" .. filterName
        local isHelpful = baseFilter == "HELPFUL"

        local container = CreateFrame("Frame", frameName, UIParent)
        container:SetSize(
            COLS * ICON_SIZE + (COLS - 1) * SPACING + 4,
            ICON_SIZE + 4
        )

        local xOff = anchor == "TOPLEFT" and 10 or -10
        local yOff = -(10 + rowIndex * ROW_HEIGHT)
        container:SetPoint(anchor, UIParent, anchor, xOff, yOff)

        local bg = container:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.4)

        local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 1)
        title:SetText(filterName)
        title:SetTextColor(isHelpful and 0.4 or 1, isHelpful and 1 or 0.4, 0.4)

        local countLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countLabel:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", 0, 1)
        countLabel:SetTextColor(0.7, 0.7, 0.7)

        local buttons = {}

        for i = 1, MAX_ICONS do
            local btn = CreateFrame("Button", frameName .. "_" .. i, container)
            btn:SetSize(ICON_SIZE, ICON_SIZE)

            local col = (i - 1) % COLS
            btn:SetPoint("TOPLEFT", container, "TOPLEFT",
                2 + col * (ICON_SIZE + SPACING), -2)

            btn.Icon = btn:CreateTexture(nil, "ARTWORK")
            btn.Icon:SetAllPoints()
            btn.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            btn.Cooldown = CreateFrame("Cooldown", "$parentCD", btn, "CooldownFrameTemplate")
            btn.Cooldown:SetAllPoints()
            btn.Cooldown:SetDrawEdge(false)
            btn.Cooldown:SetReverse(true)
            btn.Cooldown:SetDrawSwipe(true)
            btn.Cooldown:SetHideCountdownNumbers(false)

            btn.Count = btn:CreateFontString(nil, "OVERLAY")
            btn.Count:SetFont(POC_FONT, 9, "OUTLINE")
            btn.Count:SetPoint("BOTTOMRIGHT", 2, 0)

            btn:EnableMouse(true)
            btn:SetScript("OnEnter", function(self)
                if self.auraInstanceID and self.auraUnit then
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    if isHelpful then
                        GameTooltip:SetUnitBuffByAuraInstanceID(self.auraUnit, self.auraInstanceID, baseFilter)
                    else
                        GameTooltip:SetUnitDebuffByAuraInstanceID(self.auraUnit, self.auraInstanceID, baseFilter)
                    end
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            btn:Hide()
            buttons[i] = btn
        end

        local function Refresh()
            local matched = {}
            for _, unit in ipairs(rowUnits) do
                if UnitExists(unit) then
                    local slots = { C_UnitAuras.GetAuraSlots(unit, baseFilter) }
                    for si = 2, #slots do
                        local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[si])
                        if data then
                            local filtered = addon:SecureCall(
                                C_UnitAuras.IsAuraFilteredOutByInstanceID,
                                unit, data.auraInstanceID, testFilter)
                            if filtered == false then
                                matched[#matched + 1] = { unit = unit, aura = data }
                            end
                        end
                    end
                end
            end

            countLabel:SetText(#matched)

            for i = 1, MAX_ICONS do
                local btn = buttons[i]
                local match = matched[i]
                local aura = match and match.aura
                if aura then
                    btn.auraInstanceID = aura.auraInstanceID
                    btn.auraUnit = match.unit

                    local ok = addon:SecureCall(function()
                        btn.Icon:SetTexture(aura.icon)
                        return true
                    end)
                    if not ok then
                        btn.Icon:SetTexture(nil)
                    end
                    btn.Count:Hide()

                    addon:SecureCall(function()
                        btn.Cooldown:SetCooldownFromExpirationTime(aura.expirationTime, aura.duration)
                        return true
                    end)

                    btn:Show()
                else
                    btn.auraInstanceID = nil
                    btn.auraUnit = nil
                    btn:Hide()
                end
            end
        end

        allRefreshFuncs[#allRefreshFuncs + 1] = Refresh
    end

    for i, filterName in ipairs(FILTERS) do
        CreateFilterRow("HELPFUL", filterName, "TOPLEFT", i - 1, friendlyUnits)
    end

    for i, filterName in ipairs(FILTERS) do
        CreateFilterRow("HARMFUL", filterName, "TOPRIGHT", i - 1, hostileUnits)
    end

    local allUnits = {}
    local seen = {}
    for _, list in ipairs({ friendlyUnits, hostileUnits }) do
        for _, unit in ipairs(list) do
            if not seen[unit] then
                seen[unit] = true
                allUnits[#allUnits + 1] = unit
            end
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "GROUP_ROSTER_UPDATE" then
            self:UnregisterEvent("UNIT_AURA")
            for _, unit in ipairs(allUnits) do
                if UnitExists(unit) then
                    self:RegisterUnitEvent("UNIT_AURA", unit)
                end
            end
        end
        for _, fn in ipairs(allRefreshFuncs) do
            fn()
        end
    end)
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    C_Timer.After(2, function()
        local any = false
        for _, unit in ipairs(allUnits) do
            if UnitExists(unit) then
                eventFrame:RegisterUnitEvent("UNIT_AURA", unit)
                any = true
            end
        end
        if any then
            for _, fn in ipairs(allRefreshFuncs) do
                fn()
            end
        end
    end)
end

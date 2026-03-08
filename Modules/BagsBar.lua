local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Zone-based visibility for BagsBar
-- ---------------------------------------------------------------------------

local bagsBarHiddenParent = CreateFrame("Frame")
bagsBarHiddenParent:Hide()

local bagsBarOriginalParent
local bagsBarIsHidden = false

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

local function SetBagsBarVisibility(visible)
    local frame = BagsBar
    if not frame then return end

    if visible and bagsBarIsHidden then
        local parent = bagsBarOriginalParent or UIParent
        frame:SetParent(parent)
        bagsBarIsHidden = false
        frame:Show()
    elseif not visible and not bagsBarIsHidden then
        if not bagsBarOriginalParent then
            bagsBarOriginalParent = frame:GetParent()
        end
        frame:Hide()
        frame:SetParent(bagsBarHiddenParent)
        bagsBarIsHidden = true

        if not frame._zenFramesBagsBarShowHooked then
            hooksecurefunc(frame, "Show", function(self)
                if bagsBarIsHidden then
                    self:Hide()
                end
            end)
            frame._zenFramesBagsBarShowHooked = true
        end
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeBagsBar()
    local cfg = self.config and self.config.extras and self.config.extras.bagsBar

    addon.toggleableFrames["bagsbar"] = {
        isHidden = function() return bagsBarIsHidden end,
        setVisibility = function(visible)
            if not cfg or not cfg.enabled then return end
            SetBagsBarVisibility(visible)
        end,
    }

    if not cfg or not cfg.enabled then return end

    local hasZoneFilter = cfg.showInZones and #cfg.showInZones < 5
    local zoneLookup = hasZoneFilter and BuildZoneLookup(cfg.showInZones) or nil

    if not hasZoneFilter then return end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:SetScript("OnEvent", function()
        local currentZone = addon:GetCurrentZone()
        SetBagsBarVisibility(zoneLookup[currentZone] == true)
    end)
end

local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Zone-based visibility for MainStatusTrackingBarContainer / MainStatusTrackingBar
-- ---------------------------------------------------------------------------

local statusBarHiddenParent = CreateFrame("Frame")
statusBarHiddenParent:Hide()

local statusBarOriginalParents = {}
local statusBarIsHidden = false

local statusBarFrameNames = {
    "MainStatusTrackingBarContainer",
    "MainStatusTrackingBar",
}

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

local function SetStatusBarFrameVisibility(frameName, visible)
    local frame = _G[frameName]
    if not frame then return end

    if visible and statusBarIsHidden then
        local parent = statusBarOriginalParents[frameName] or UIParent
        frame:SetParent(parent)
        frame:Show()
    elseif not visible and not statusBarIsHidden then
        if not statusBarOriginalParents[frameName] then
            statusBarOriginalParents[frameName] = frame:GetParent()
        end
        frame:Hide()
        frame:SetParent(statusBarHiddenParent)

        if not frame._zenFramesStatusBarShowHooked then
            hooksecurefunc(frame, "Show", function(self)
                if statusBarIsHidden then
                    self:Hide()
                end
            end)
            frame._zenFramesStatusBarShowHooked = true
        end
    end
end

local function SetStatusBarVisibility(visible)
    statusBarIsHidden = not visible
    for _, frameName in ipairs(statusBarFrameNames) do
        SetStatusBarFrameVisibility(frameName, visible)
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeStatusBar()
    local cfg = self.config and self.config.extras and self.config.extras.statusBar

    addon.toggleableFrames["statusbar"] = {
        isHidden = function() return statusBarIsHidden end,
        setVisibility = function(visible)
            if not cfg or not cfg.enabled then return end
            SetStatusBarVisibility(visible)
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
        SetStatusBarVisibility(zoneLookup[currentZone] == true)
    end)
end

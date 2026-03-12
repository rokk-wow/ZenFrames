local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Clock Customization
-- ---------------------------------------------------------------------------

local function CustomizeClock(cfg)
    local clockButton = TimeManagerClockButton
    if not clockButton then return end

    clockButton:ClearAllPoints()
    clockButton:SetPoint("TOP", UIParent, "TOP", cfg.offsetX, cfg.offsetY)

    local ticker = TimeManagerClockTicker
    if ticker then
        ticker:SetFont(ticker:GetFont(), cfg.fontSize, "OUTLINE")
        ticker:SetJustifyH("CENTER")
    end

    if AddonCompartmentFrame then
        AddonCompartmentFrame:ClearAllPoints()
        AddonCompartmentFrame:SetPoint("LEFT", clockButton, "RIGHT", cfg.compartmentSpacing, 0)
    end
end

-- ---------------------------------------------------------------------------
-- Mail Icon
-- ---------------------------------------------------------------------------

function addon:CreateMailIcon()
    local clockButton = TimeManagerClockButton
    if not clockButton then return end

    local blizzMailFrame = MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame
    if not blizzMailFrame then return end

    blizzMailFrame:SetParent(clockButton)
    blizzMailFrame:ClearAllPoints()
    blizzMailFrame:SetPoint("TOP", clockButton, "BOTTOM", 0, -2)
    blizzMailFrame:SetIgnoreParentAlpha(true)
    blizzMailFrame:Show()

    hooksecurefunc(blizzMailFrame, "SetPoint", function(self)
        if self:GetParent() == clockButton then return end
        self:SetParent(clockButton)
        self:ClearAllPoints()
        self:SetPoint("TOP", clockButton, "BOTTOM", 0, -2)
    end)
end

-- ---------------------------------------------------------------------------
-- Zone-based visibility for Clock frames
-- ---------------------------------------------------------------------------

local clockHiddenParent = CreateFrame("Frame")
clockHiddenParent:Hide()

local clockOriginalParents = {}
local clockHiddenFrames = {}

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

local function SetClockFrameVisibility(frameName, visible)
    local frame = _G[frameName]
    if not frame then return end

    if visible and clockHiddenFrames[frameName] then
        local parent = clockOriginalParents[frameName] or UIParent
        frame:SetParent(parent)
        clockHiddenFrames[frameName] = false
        frame:Show()
    elseif not visible and not clockHiddenFrames[frameName] then
        if not clockOriginalParents[frameName] then
            clockOriginalParents[frameName] = frame:GetParent()
        end
        frame:Hide()
        frame:SetParent(clockHiddenParent)
        clockHiddenFrames[frameName] = true

        if not frame._zenFramesClockShowHooked then
            hooksecurefunc(frame, "Show", function(self)
                if clockHiddenFrames[frameName] then
                    self:Hide()
                end
            end)
            frame._zenFramesClockShowHooked = true
        end
    end
end

local function SetClockZoneVisibility(visible)
    SetClockFrameVisibility("TimeManagerClockButton", visible)
    SetClockFrameVisibility("AddonCompartmentFrame", visible)
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeClock()
    local cfg = self.config and self.config.extras and self.config.extras.clock
    if not cfg or not cfg.enabled then return end

    local hasZoneFilter = cfg.showInZones and #cfg.showInZones < 5
    local zoneLookup = hasZoneFilter and BuildZoneLookup(cfg.showInZones) or nil

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    if hasZoneFilter then
        eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    end
    eventFrame:SetScript("OnEvent", function(_, event)
        if hasZoneFilter then
            local currentZone = addon:GetCurrentZone()
            SetClockZoneVisibility(zoneLookup[currentZone] == true)
        end

        if event == "PLAYER_ENTERING_WORLD" then
            CustomizeClock(cfg)
        end
    end)

    if cfg.showMailIcon then
        self:CreateMailIcon()
    end

    addon.toggleableFrames["clock"] = {
        isHidden = function() return clockHiddenFrames["TimeManagerClockButton"] == true end,
        setVisibility = function(visible) SetClockZoneVisibility(visible) end,
    }
end

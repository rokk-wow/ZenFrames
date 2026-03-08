local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Zone-based visibility for ObjectiveTrackerFrame
-- ---------------------------------------------------------------------------

local questFrameHiddenParent = CreateFrame("Frame")
questFrameHiddenParent:Hide()

local questFrameOriginalParent
local questFrameIsHidden = false

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

local function SetQuestFrameVisibility(visible)
    local frame = ObjectiveTrackerFrame
    if not frame then return end

    if visible and questFrameIsHidden then
        local parent = questFrameOriginalParent or UIParent
        frame:SetParent(parent)
        questFrameIsHidden = false
        frame:Show()
    elseif not visible and not questFrameIsHidden then
        if not questFrameOriginalParent then
            questFrameOriginalParent = frame:GetParent()
        end
        frame:Hide()
        frame:SetParent(questFrameHiddenParent)
        questFrameIsHidden = true

        if not frame._zenFramesQuestFrameShowHooked then
            hooksecurefunc(frame, "Show", function(self)
                if questFrameIsHidden then
                    self:Hide()
                end
            end)
            frame._zenFramesQuestFrameShowHooked = true
        end
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeQuestFrame()
    local cfg = self.config and self.config.extras and self.config.extras.questFrame

    addon.toggleableFrames["questframe"] = {
        isHidden = function() return questFrameIsHidden end,
        setVisibility = function(visible)
            if not cfg or not cfg.enabled then return end
            SetQuestFrameVisibility(visible)
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
        SetQuestFrameVisibility(zoneLookup[currentZone] == true)
    end)
end

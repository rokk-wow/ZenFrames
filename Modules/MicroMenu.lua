local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Zone-based visibility for MicroMenuContainer
-- ---------------------------------------------------------------------------

local microMenuHiddenParent = CreateFrame("Frame")
microMenuHiddenParent:Hide()

local microMenuOriginalParent
local microMenuIsHidden = false

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

local function SetMicroMenuVisibility(visible)
    local frame = MicroMenuContainer
    if not frame then return end

    if visible and microMenuIsHidden then
        local parent = microMenuOriginalParent or UIParent
        frame:SetParent(parent)
        microMenuIsHidden = false
        frame:Show()
    elseif not visible and not microMenuIsHidden then
        if not microMenuOriginalParent then
            microMenuOriginalParent = frame:GetParent()
        end
        frame:Hide()
        frame:SetParent(microMenuHiddenParent)
        microMenuIsHidden = true

        if not frame._zenFramesMicroMenuShowHooked then
            hooksecurefunc(frame, "Show", function(self)
                if microMenuIsHidden then
                    self:Hide()
                end
            end)
            frame._zenFramesMicroMenuShowHooked = true
        end
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeMicroMenu()
    local cfg = self.config and self.config.extras and self.config.extras.microMenu

    addon.toggleableFrames["micromenu"] = {
        isHidden = function() return microMenuIsHidden end,
        setVisibility = function(visible)
            if not cfg or not cfg.enabled then return end
            SetMicroMenuVisibility(visible)
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
        SetMicroMenuVisibility(zoneLookup[currentZone] == true)
    end)
end

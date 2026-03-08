local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Customize Minimap
-- ---------------------------------------------------------------------------

local function CustomizeMinimap(cfg)
    if Minimap then
        if cfg.squareMask then
            Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
        end

        Minimap:SetSize(cfg.size, cfg.size)

        if cfg.unclamp then
            Minimap:SetClampedToScreen(false)
            if Minimap:GetParent() then
                Minimap:GetParent():SetClampedToScreen(false)
            end
        end

        if cfg.borderWidth > 0 then
            addon:AddBorder(Minimap, cfg)
        end

        C_Timer.After(0.2, function()
            if Minimap then
                local currentZoom = Minimap:GetZoom()
                if currentZoom > 0 then
                    Minimap:SetZoom(currentZoom - 1)
                end
            end
        end)
    end

    if cfg.unclamp and MinimapCluster then
        MinimapCluster:SetClampedToScreen(false)

        if MinimapCluster.Selection then
            MinimapCluster.Selection:SetClampedToScreen(false)
        end
        if MinimapCluster.EditModeHighlight then
            MinimapCluster.EditModeHighlight:SetClampedToScreen(false)
        end
    end

    if cfg.unclamp and EditModeManagerFrame then
        local selection = EditModeManagerFrame.selection
        if selection then
            selection:SetClampedToScreen(false)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Hide Minimap Elements
-- ---------------------------------------------------------------------------

local function HideMinimapElements(cfg)
    if cfg.hideBackdrop and MinimapBackdrop then
        MinimapBackdrop:Hide()
        MinimapBackdrop:SetAlpha(0)
    end

    if cfg.hideBorderTop and MinimapCluster and MinimapCluster.BorderTop then
        MinimapCluster.BorderTop:Hide()
        MinimapCluster.BorderTop:SetAlpha(0)
    end

    if cfg.hideTracking and MinimapCluster and MinimapCluster.Tracking then
        if MinimapCluster.Tracking.Button then
            MinimapCluster.Tracking.Button:Hide()
            MinimapCluster.Tracking.Button:SetAlpha(0)
        end
        if MinimapCluster.Tracking.Background then
            MinimapCluster.Tracking.Background:Hide()
            MinimapCluster.Tracking.Background:SetAlpha(0)
        end
    end

    if cfg.hideZoneText and MinimapCluster and MinimapCluster.ZoneTextButton then
        MinimapCluster.ZoneTextButton:Hide()
        MinimapCluster.ZoneTextButton:SetAlpha(0)

        for i = 1, MinimapCluster.ZoneTextButton:GetNumRegions() do
            local region = select(i, MinimapCluster.ZoneTextButton:GetRegions())
            if region then
                region:Hide()
                region:SetAlpha(0)
            end
        end
    end

    if cfg.hideGameTime and GameTimeFrame then
        GameTimeFrame:Hide()
        GameTimeFrame:SetAlpha(0)
    end

    if cfg.hideZoomButtons then
        if Minimap then
            if Minimap.ZoomIn then
                Minimap.ZoomIn:Hide()
                Minimap.ZoomIn:SetAlpha(0)
            end
            if Minimap.ZoomOut then
                Minimap.ZoomOut:Hide()
                Minimap.ZoomOut:SetAlpha(0)
            end
        end

        if MinimapZoomIn then
            MinimapZoomIn:Hide()
            MinimapZoomIn:SetAlpha(0)
        end
        if MinimapZoomOut then
            MinimapZoomOut:Hide()
            MinimapZoomOut:SetAlpha(0)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Refresh Minimap Zoom (fixes rendering after shape/size changes)
-- ---------------------------------------------------------------------------

local function RefreshMinimapZoom()
    if not Minimap then return end

    C_Timer.After(0.1, function()
        local currentZoom = Minimap:GetZoom()
        if currentZoom < Minimap:GetZoomLevels() then
            Minimap:SetZoom(currentZoom + 1)
        else
            Minimap:SetZoom(currentZoom - 1)
        end
        C_Timer.After(0.05, function()
            Minimap:SetZoom(currentZoom)
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- Restore Minimap After Cutscene
-- ---------------------------------------------------------------------------

local function RestoreMinimap(cfg)
    local function restoreNow()
        if MinimapCluster then
            MinimapCluster:Show()
            MinimapCluster:SetAlpha(1)
            MinimapCluster:SetClampedToScreen(false)
        end

        if Minimap then
            Minimap:Show()
            Minimap:SetAlpha(1)
            Minimap:SetClampedToScreen(false)
        end

        CustomizeMinimap(cfg)
        HideMinimapElements(cfg)
        RefreshMinimapZoom()
    end

    restoreNow()
    C_Timer.After(0.2, restoreNow)
    C_Timer.After(1.0, restoreNow)
end

-- ---------------------------------------------------------------------------
-- Zone-based visibility for MinimapCluster
-- ---------------------------------------------------------------------------

local minimapHiddenParent = CreateFrame("Frame")
minimapHiddenParent:Hide()

local minimapOriginalParent
local minimapIsHidden = false

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

local function SetMinimapZoneVisibility(visible)
    local frame = MinimapCluster
    if not frame then return end

    if visible and minimapIsHidden then
        local parent = minimapOriginalParent or UIParent
        frame:SetParent(parent)
        minimapIsHidden = false
        frame:Show()
    elseif not visible and not minimapIsHidden then
        if not minimapOriginalParent then
            minimapOriginalParent = frame:GetParent()
        end
        frame:Hide()
        frame:SetParent(minimapHiddenParent)
        minimapIsHidden = true

        if not frame._zenFramesMinimapShowHooked then
            hooksecurefunc(frame, "Show", function(self)
                if minimapIsHidden then
                    self:Hide()
                end
            end)
            frame._zenFramesMinimapShowHooked = true
        end
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeMinimap()
    local cfg = self.config and self.config.extras and self.config.extras.minimap
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
            SetMinimapZoneVisibility(zoneLookup[currentZone] == true)
        end

        if event == "PLAYER_ENTERING_WORLD" then
            CustomizeMinimap(cfg)
            HideMinimapElements(cfg)
            RefreshMinimapZoom()
        end
    end)

    addon.toggleableFrames["minimap"] = {
        isHidden = function() return minimapIsHidden end,
        setVisibility = function(visible) SetMinimapZoneVisibility(visible) end,
    }

    if cfg.restoreAfterCutscene then
        self:RegisterEvent("CINEMATIC_STOP", function()
            RestoreMinimap(cfg)
        end)

        if MovieFrame then
            MovieFrame:HookScript("OnHide", function()
                RestoreMinimap(cfg)
            end)
        end
    end
end

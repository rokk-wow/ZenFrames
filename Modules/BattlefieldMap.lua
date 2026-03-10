local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Customize Battlefield Map
-- ---------------------------------------------------------------------------

local function CustomizeBattlefieldMap(cfg)
    local mapFrame = BattlefieldMapFrame
    if not mapFrame then return end

    if BattlefieldMapOptions then
        BattlefieldMapOptions.opacity = 1.0 - cfg.opacity
        if mapFrame.RefreshAlpha then
            mapFrame:RefreshAlpha()
        end
    end

    if cfg.hideBorderFrame then
        hooksecurefunc(mapFrame, "Show", function()
            if mapFrame.BorderFrame then
                mapFrame.BorderFrame:Hide()
                mapFrame.BorderFrame:SetAlpha(0)
            end

            if mapFrame.ScrollContainer and cfg.borderWidth > 0 then
                if not mapFrame.ScrollContainer.ZenFrames_BorderFrame then
                    local borderFrame = CreateFrame("Frame", nil, mapFrame.ScrollContainer)
                    borderFrame:SetAllPoints(mapFrame.ScrollContainer)
                    mapFrame.ScrollContainer.ZenFrames_BorderFrame = borderFrame
                end
                addon:AddBorder(mapFrame.ScrollContainer.ZenFrames_BorderFrame, cfg)
            end
        end)

        if mapFrame:IsShown() then
            if mapFrame.BorderFrame then
                mapFrame.BorderFrame:Hide()
                mapFrame.BorderFrame:SetAlpha(0)
            end

            if mapFrame.ScrollContainer and cfg.borderWidth > 0 then
                if not mapFrame.ScrollContainer.ZenFrames_BorderFrame then
                    local borderFrame = CreateFrame("Frame", nil, mapFrame.ScrollContainer)
                    borderFrame:SetAllPoints(mapFrame.ScrollContainer)
                    mapFrame.ScrollContainer.ZenFrames_BorderFrame = borderFrame
                end
                addon:AddBorder(mapFrame.ScrollContainer.ZenFrames_BorderFrame, cfg)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Scale and Position Battlefield Map
-- ---------------------------------------------------------------------------

local function ScaleBattlefieldMap(cfg)
    local mapFrame = BattlefieldMapFrame
    if not mapFrame then return end

    local defaultHeight = mapFrame:GetHeight()
    if defaultHeight > 0 then
        local scale = cfg.height / defaultHeight
        mapFrame:SetScale(scale)
    end
end

-- ---------------------------------------------------------------------------
-- Zone-based Visibility (via CVar - protected frame)
-- ---------------------------------------------------------------------------

local function BuildZoneLookup(zoneList)
    local lookup = {}
    if type(zoneList) == "table" then
        for _, zone in ipairs(zoneList) do
            lookup[zone] = true
        end
    end
    return lookup
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeBattlefieldMap()
    local cfg = self.config and self.config.extras and self.config.extras.battlefieldMap
    if not cfg or not cfg.enabled then return end

    local hasZoneFilter = cfg.showInZones and #cfg.showInZones < 5
    local zoneLookup = hasZoneFilter and BuildZoneLookup(cfg.showInZones) or nil

    local customized = false
    local settingCVar = false

    local function ApplyCustomizations()
        if not BattlefieldMapFrame then return end
        CustomizeBattlefieldMap(cfg)
        ScaleBattlefieldMap(cfg)
        customized = true
    end

    local function ApplyZoneFilter()
        if not hasZoneFilter then return end
        local currentZone = addon:GetCurrentZone()
        local shouldShow = zoneLookup[currentZone] == true
        settingCVar = true
        SetCVar("showBattlefieldMinimap", shouldShow and "1" or "0")
        settingCVar = false
        if not shouldShow and BattlefieldMapFrame and BattlefieldMapFrame:IsShown() then
            BattlefieldMapFrame:Hide()
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("CVAR_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            ApplyZoneFilter()
            ApplyCustomizations()
        end

        if event == "CVAR_UPDATE" then
            local cvarName, cvarValue = ...
            if cvarName == "showBattlefieldMinimap" and cvarValue == "1" and not settingCVar and not customized then
                C_Timer.After(0, ApplyCustomizations)
            end
        end
    end)

    addon.toggleableFrames["battlefieldmap"] = {
        isHidden = function() return GetCVar("showBattlefieldMinimap") == "0" end,
        setVisibility = function(visible)
            addon:CombatSafe(function()
                SetCVar("showBattlefieldMinimap", visible and "1" or "0")
            end)
        end,
    }
end

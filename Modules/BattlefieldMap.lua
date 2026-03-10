local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Resolve Active Battleground Profile
-- ---------------------------------------------------------------------------

local activeBattlefieldMapCfg = nil

local function GetActiveProfileConfig()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "pvp" then return nil end

    local raidCfg = addon.config and addon.config.raid
    if not raidCfg then return nil end

    local routing = raidCfg.routing or {}
    local pvp = routing.pvp or {}
    local epic = pvp.epicBattleground or {}
    local bg = pvp.battleground or {}
    local blz = pvp.blitz or {}

    local instanceGroupSize = select(9, GetInstanceInfo()) or 0
    if instanceGroupSize == 0 then
        instanceGroupSize = select(5, GetInstanceInfo()) or 0
    end
    if instanceGroupSize == 0 then
        instanceGroupSize = GetNumGroupMembers() or 0
    end

    local profileName
    if instanceGroupSize >= (epic.minRaidSize or 26) then
        profileName = epic.profile or "epicBattleground"
    elseif instanceGroupSize >= (bg.minRaidSize or 9) then
        profileName = bg.profile or "battleground"
    else
        profileName = blz.profile or "blitz"
    end

    local profiles = raidCfg.profiles
    return profiles and profiles[profileName]
end

-- ---------------------------------------------------------------------------
-- Customize Battlefield Map
-- ---------------------------------------------------------------------------

local function ApplyBorderCustomization(mapFrame, cfg)
    if not cfg.hideBorderFrame then return end

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

local function CustomizeBattlefieldMap(cfg)
    local mapFrame = BattlefieldMapFrame
    if not mapFrame then return end

    if BattlefieldMapOptions then
        BattlefieldMapOptions.opacity = 1.0 - cfg.opacity
        if mapFrame.RefreshAlpha then
            mapFrame:RefreshAlpha()
        end
    end

    if mapFrame:IsShown() then
        ApplyBorderCustomization(mapFrame, cfg)
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
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeBattlefieldMap()
    local mapHooked = false
    local settingCVar = false

    local function ApplyCustomizations()
        if not BattlefieldMapFrame then return end

        local profileCfg = GetActiveProfileConfig()
        local cfg = profileCfg and profileCfg.battlefieldMap

        if not cfg or not cfg.enabled then
            activeBattlefieldMapCfg = nil
            return
        end

        activeBattlefieldMapCfg = cfg
        CustomizeBattlefieldMap(cfg)
        ScaleBattlefieldMap(cfg)

        if not mapHooked then
            mapHooked = true
            hooksecurefunc(BattlefieldMapFrame, "Show", function()
                if activeBattlefieldMapCfg then
                    ApplyBorderCustomization(BattlefieldMapFrame, activeBattlefieldMapCfg)
                end
            end)
        end
    end

    local function ApplyZoneFilter()
        local profileCfg = GetActiveProfileConfig()
        local cfg = profileCfg and profileCfg.battlefieldMap
        local shouldShow = cfg and cfg.enabled

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
            if cvarName == "showBattlefieldMinimap" and cvarValue == "1" and not settingCVar then
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

local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Battleground Callouts
-- ---------------------------------------------------------------------------

local calloutButtons = {}

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

local function GetChatSlashCommand()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "/i "
    elseif IsInGroup() then
        return "/p "
    end
    return nil
end

local function UpdateButtonMacros()
    if InCombatLockdown() then return end
    for _, button in ipairs(calloutButtons) do
        local msg = button.calloutMessage
        if not msg then return end

        local subZone = GetSubZoneText()
        if not subZone or subZone == "" then return end

        local slash = GetChatSlashCommand()
        if slash then
            button:SetAttribute("macrotext", slash .. subZone .. ": " .. msg)
        else
            button:SetAttribute("macrotext", "")
        end
    end
end

local function HideCalloutButtons()
    for _, button in ipairs(calloutButtons) do
        button:Hide()
    end
end

local function CreateCalloutButtons(cfg, parentFrame)
    if InCombatLockdown() then return end
    HideCalloutButtons()

    local buttonCount = #cfg.buttons
    local buttonSize = cfg.buttonSize
    local totalWidth = buttonSize * buttonCount
    local startOffset = -(totalWidth / 2) + (buttonSize / 2)

    for i, buttonCfg in ipairs(cfg.buttons) do
        local frameName = "ZenFramesBGCallout" .. i
        local button = _G[frameName] or CreateFrame("Button", frameName, parentFrame, "SecureActionButtonTemplate, UIPanelButtonTemplate")

        button:SetParent(parentFrame)
        button:ClearAllPoints()
        button:SetSize(buttonSize, buttonSize)
        button:SetPoint("CENTER", parentFrame, "TOP", startOffset + (buttonSize * (i - 1)), 0)
        button:RegisterForClicks("LeftButtonUp")
        button:SetFrameStrata("DIALOG")
        button:SetText(buttonCfg.label)

        button:SetAttribute("type", "macro")
        button.calloutMessage = buttonCfg.message
        button:Hide()

        calloutButtons[i] = button
    end

    for i = buttonCount + 1, #calloutButtons do
        calloutButtons[i] = nil
    end
end

local function UpdateCalloutVisibility()
    local mapFrame = BattlefieldMapFrame
    local mapVisible = mapFrame and mapFrame:IsVisible()
    local inBattleground = UnitInBattleground("player")
    local subZone = GetSubZoneText()
    local hasSubZone = subZone and subZone ~= ""

    local shouldShow = mapVisible and inBattleground and hasSubZone

    if shouldShow then
        UpdateButtonMacros()
    end

    for _, button in ipairs(calloutButtons) do
        if shouldShow then
            button:Show()
        else
            button:Hide()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeBattlegroundCallouts()
    local mapHooked = false
    local lastCalloutCfg = nil

    local function Setup()
        local mapFrame = BattlefieldMapFrame
        if not mapFrame then return end

        local profileCfg = GetActiveProfileConfig()
        local cfg = profileCfg and profileCfg.battlegroundCallouts

        if not cfg or not cfg.enabled then
            HideCalloutButtons()
            lastCalloutCfg = nil
            return
        end

        if cfg ~= lastCalloutCfg then
            lastCalloutCfg = cfg
            CreateCalloutButtons(cfg, mapFrame)
        end

        if not mapHooked then
            mapHooked = true
            hooksecurefunc(mapFrame, "Show", function()
                UpdateCalloutVisibility()
            end)
            hooksecurefunc(mapFrame, "Hide", function()
                UpdateCalloutVisibility()
            end)
        end

        UpdateCalloutVisibility()
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CVAR_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "CVAR_UPDATE" then
            local cvarName = ...
            if cvarName == "showBattlefieldMinimap" then
                C_Timer.After(0.1, function()
                    Setup()
                end)
            end
            return
        end

        Setup()
    end)
end

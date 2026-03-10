local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Call Incs
-- ---------------------------------------------------------------------------

local callIncButtons = {}

local function ResolveButtonText(template)
    local subZone = GetSubZoneText() or ""
    return template:gsub("%$zone", subZone)
end

local function SendCallInc(template)
    local message = ResolveButtonText(template)
    if not message or message == "" then return end

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        SendChatMessage(message, "INSTANCE_CHAT")
    elseif IsInGroup() then
        SendChatMessage(message, "PARTY")
    end
end

local function GetActiveCallIncsCfg()
    local raidCfg = addon.config and addon.config.raid
    if not raidCfg then return nil end

    local state = addon.GetRaidRoutingState and addon:GetRaidRoutingState()
    local activeProfile = state and (state.activeFriendlyProfile or state.activeEnemyProfile)

    if activeProfile then
        local profiles = raidCfg.profiles or {}
        local profileCfg = profiles[activeProfile]
        if profileCfg and profileCfg.callIncs and profileCfg.callIncs.enabled then
            return profileCfg.callIncs
        end
    end

    local extrasCfg = addon.config and addon.config.extras and addon.config.extras.callIncs
    if extrasCfg and extrasCfg.enabled then
        return extrasCfg
    end

    return nil
end

local function CreateCallIncButtons(cfg, parentFrame)
    local orderedKeys = {}
    for label in pairs(cfg.buttons) do
        orderedKeys[#orderedKeys + 1] = label
    end
    table.sort(orderedKeys)

    local buttonCount = #orderedKeys
    local buttonSize = cfg.buttonSize
    local totalWidth = buttonSize * buttonCount
    local startOffset = -(totalWidth / 2) + (buttonSize / 2)

    for i, label in ipairs(orderedKeys) do
        local template = cfg.buttons[label]
        local frameName = "ZenFramesCallInc" .. i
        local button = _G[frameName] or CreateFrame("Button", frameName, parentFrame, "UIPanelButtonTemplate")

        button:SetSize(buttonSize, buttonSize)
        button:SetPoint("CENTER", parentFrame, "TOP", startOffset + (buttonSize * (i - 1)), 0)
        button:RegisterForClicks("LeftButtonUp")
        button:SetFrameStrata("DIALOG")
        button:SetText(label)

        button:SetScript("OnClick", function() SendCallInc(template) end)
        button:Hide()

        callIncButtons[i] = button
    end
end

local function RebuildCallIncButtons()
    for _, button in ipairs(callIncButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(callIncButtons)

    local cfg = GetActiveCallIncsCfg()
    if not cfg or not cfg.buttons then return end

    local mapFrame = BattlefieldMapFrame
    if not mapFrame then return end

    CreateCallIncButtons(cfg, mapFrame)
end

local function UpdateCallIncVisibility()
    local mapFrame = BattlefieldMapFrame
    local mapVisible = mapFrame and mapFrame:IsVisible()
    local inBattleground = UnitInBattleground("player")
    local subZone = GetSubZoneText()
    local hasSubZone = subZone and subZone ~= ""

    local shouldShow = mapVisible and inBattleground and hasSubZone

    for _, button in ipairs(callIncButtons) do
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

function addon:InitializeCallIncs()
    local extrasCfg = self.config and self.config.extras and self.config.extras.callIncs
    if not extrasCfg or not extrasCfg.enabled then return end

    local initialized = false

    local function Setup()
        local mapFrame = BattlefieldMapFrame
        if not mapFrame or initialized then return end
        initialized = true

        RebuildCallIncButtons()

        hooksecurefunc(mapFrame, "Show", function()
            UpdateCallIncVisibility()
        end)

        hooksecurefunc(mapFrame, "Hide", function()
            UpdateCallIncVisibility()
        end)

        UpdateCallIncVisibility()
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
                    RebuildCallIncButtons()
                    UpdateCallIncVisibility()
                end)
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            RebuildCallIncButtons()
        end

        Setup()
        UpdateCallIncVisibility()
    end)
end

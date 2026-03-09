local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Battleground Callouts
-- ---------------------------------------------------------------------------

local calloutButtons = {}

local function SendCallout(message)
    local subZone = GetSubZoneText()
    if not message or not subZone or subZone == "" then return end

    local fullMessage = subZone .. ": " .. message

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        SendChatMessage(fullMessage, "INSTANCE_CHAT")
    elseif IsInGroup() then
        SendChatMessage(fullMessage, "PARTY")
    end
end

local function CreateCalloutButtons(cfg, parentFrame)
    local buttonCount = #cfg.buttons
    local buttonSize = cfg.buttonSize
    local totalWidth = buttonSize * buttonCount
    local startOffset = -(totalWidth / 2) + (buttonSize / 2)

    for i, buttonCfg in ipairs(cfg.buttons) do
        local frameName = "ZenFramesBGCallout" .. i
        local button = _G[frameName] or CreateFrame("Button", frameName, parentFrame, "UIPanelButtonTemplate")

        button:SetSize(buttonSize, buttonSize)
        button:SetPoint("CENTER", parentFrame, "TOP", startOffset + (buttonSize * (i - 1)), 0)
        button:RegisterForClicks("LeftButtonUp")
        button:SetFrameStrata("DIALOG")
        button:SetText(buttonCfg.label)

        local msg = buttonCfg.message
        button:SetScript("OnClick", function() SendCallout(msg) end)
        button:Hide()

        calloutButtons[i] = button
    end
end

local function UpdateCalloutVisibility()
    local mapFrame = BattlefieldMapFrame
    local mapVisible = mapFrame and mapFrame:IsVisible()
    local inBattleground = UnitInBattleground("player")
    local subZone = GetSubZoneText()
    local hasSubZone = subZone and subZone ~= ""

    local shouldShow = mapVisible and inBattleground and hasSubZone

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
    local cfg = self.config and self.config.extras and self.config.extras.battlegroundCallouts
    if not cfg or not cfg.enabled then return end

    local initialized = false

    local function Setup()
        local mapFrame = BattlefieldMapFrame
        if not mapFrame or initialized then return end
        initialized = true

        CreateCalloutButtons(cfg, mapFrame)

        hooksecurefunc(mapFrame, "Show", function()
            UpdateCalloutVisibility()
        end)

        hooksecurefunc(mapFrame, "Hide", function()
            UpdateCalloutVisibility()
        end)

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
                    UpdateCalloutVisibility()
                end)
            end
            return
        end

        Setup()
        UpdateCalloutVisibility()
    end)
end

local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Unclamp Chat Frames
-- ---------------------------------------------------------------------------

local function UnclampChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetClampedToScreen(false)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Reposition Chat Edit Box
-- ---------------------------------------------------------------------------

local function RepositionChatEditBox(backgroundOpacity)
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:ClearAllPoints()
            editBox:SetPoint("TOPLEFT", _G["ChatFrame" .. i], "BOTTOMLEFT", 0, 25)
            editBox:SetPoint("TOPRIGHT", _G["ChatFrame" .. i], "BOTTOMRIGHT", 0, 0)

            for j = 1, editBox:GetNumRegions() do
                local region = select(j, editBox:GetRegions())
                if region and region:GetObjectType() == "Texture" then
                    region:SetAlpha(0)
                    region:Hide()
                end
            end

            if not editBox.ZenFrames_Background then
                editBox.ZenFrames_Background = editBox:CreateTexture(nil, "BACKGROUND")
                editBox.ZenFrames_Background:SetAllPoints(editBox)
                editBox.ZenFrames_Background:SetColorTexture(0, 0, 0, backgroundOpacity)

                hooksecurefunc(editBox, "SetShown", function(self, shown)
                    if self.ZenFrames_Background then
                        self.ZenFrames_Background:SetShown(shown)
                    end
                end)

                hooksecurefunc(editBox, "SetAlpha", function(self, alpha)
                    if self.ZenFrames_Background then
                        self.ZenFrames_Background:SetAlpha(alpha)
                    end
                end)
            end

            if editBox.ZenFrames_Background then
                editBox.ZenFrames_Background:SetShown(editBox:IsShown())
                editBox.ZenFrames_Background:SetAlpha(editBox:GetAlpha())
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Hide Chat Frame Channel Button
-- ---------------------------------------------------------------------------

local function HideChatFrameChannelButton()
    if ChatFrameChannelButton then
        ChatFrameChannelButton:Hide()
        ChatFrameChannelButton:SetAlpha(0)

        hooksecurefunc(ChatFrameChannelButton, "Show", function(self)
            self:Hide()
            self:SetAlpha(0)
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Hide Quick Join Toast Button
-- ---------------------------------------------------------------------------

local function HideQuickJoinToastButton()
    if QuickJoinToastButton then
        QuickJoinToastButton:Hide()
        QuickJoinToastButton:SetAlpha(0)

        hooksecurefunc(QuickJoinToastButton, "Show", function(self)
            self:Hide()
            self:SetAlpha(0)
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Disable Chat in Arena
-- ---------------------------------------------------------------------------

addon.arenaChatFilters = {}
addon.originalBubbleSettings = {}

local function CreateArenaChatFilter()
    return function(self, event, message, sender, ...)
        return true
    end
end

local function SetArenaChatMessageFilter(chatEvent, block)
    if block then
        if not addon.arenaChatFilters[chatEvent] then
            local filterFunc = CreateArenaChatFilter()
            ChatFrame_AddMessageEventFilter(chatEvent, filterFunc)
            addon.arenaChatFilters[chatEvent] = filterFunc
        end
    else
        if addon.arenaChatFilters[chatEvent] then
            ChatFrame_RemoveMessageEventFilter(chatEvent, addon.arenaChatFilters[chatEvent])
            addon.arenaChatFilters[chatEvent] = nil
        end
    end
end

local function SetArenaChatBubbles(block)
    if block then
        addon.originalBubbleSettings.chatBubbles = GetCVar("chatBubbles")
        addon.originalBubbleSettings.chatBubblesParty = GetCVar("chatBubblesParty")
        addon.originalBubbleSettings.chatBubblesRaid = GetCVar("chatBubblesRaid")
        SetCVar("chatBubbles", "0")
        SetCVar("chatBubblesParty", "0")
        SetCVar("chatBubblesRaid", "0")
    else
        if addon.originalBubbleSettings.chatBubbles then
            SetCVar("chatBubbles", addon.originalBubbleSettings.chatBubbles)
            addon.originalBubbleSettings.chatBubbles = nil
        end
        if addon.originalBubbleSettings.chatBubblesParty then
            SetCVar("chatBubblesParty", addon.originalBubbleSettings.chatBubblesParty)
            addon.originalBubbleSettings.chatBubblesParty = nil
        end
        if addon.originalBubbleSettings.chatBubblesRaid then
            SetCVar("chatBubblesRaid", addon.originalBubbleSettings.chatBubblesRaid)
            addon.originalBubbleSettings.chatBubblesRaid = nil
        end
    end
end

local function ApplyArenaChatFilters(block)
    SetArenaChatMessageFilter("CHAT_MSG_WHISPER", block)
    SetArenaChatMessageFilter("CHAT_MSG_WHISPER_INFORM", block)
    SetArenaChatMessageFilter("CHAT_MSG_SAY", block)
    SetArenaChatMessageFilter("CHAT_MSG_YELL", block)
    SetArenaChatMessageFilter("CHAT_MSG_EMOTE", block)
    SetArenaChatMessageFilter("CHAT_MSG_TEXT_EMOTE", block)
    SetArenaChatMessageFilter("CHAT_MSG_PARTY", block)
    SetArenaChatMessageFilter("CHAT_MSG_PARTY_LEADER", block)
    SetArenaChatMessageFilter("CHAT_MSG_INSTANCE_CHAT", block)
    SetArenaChatMessageFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", block)
    SetArenaChatMessageFilter("CHAT_MSG_RAID", block)
    SetArenaChatMessageFilter("CHAT_MSG_RAID_LEADER", block)
    SetArenaChatMessageFilter("CHAT_MSG_RAID_WARNING", block)
    SetArenaChatBubbles(block)
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeChat()
    local cfg = self.config and self.config.extras and self.config.extras.chat
    if not cfg or not cfg.enabled then return end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function()
        if cfg.unclampFrames then
            UnclampChatFrames()
        end

        if cfg.repositionEditBox then
            RepositionChatEditBox(cfg.editBoxBackgroundOpacity)
        end

        if cfg.hideChannelButton then
            HideChatFrameChannelButton()
        end

        if cfg.hideQuickJoinToastButton then
            HideQuickJoinToastButton()
        end

        if cfg.disableChatInArena then
            ApplyArenaChatFilters(self:GetCurrentZone() == "arena")
        end
    end)

    if cfg.disableChatInArena then
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
            ApplyArenaChatFilters(self:GetCurrentZone() == "arena")
        end)
    end
end

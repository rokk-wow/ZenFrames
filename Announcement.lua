local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Announcement dialog - shown once per version after update
-- ---------------------------------------------------------------------------

local DIALOG_WIDTH = 400
local DIALOG_HEIGHT = 200
local BORDER_WIDTH = 8
local PADDING = 30
local TITLE_FONT_SIZE = 22
local BODY_FONT_SIZE = 13
local BULLET_FONT_SIZE = 13
local BUTTON_FONT_SIZE = 13
local BUTTON_HEIGHT = 28
local DIVIDER_HEIGHT = 2
local ICON_SIZE = 64
local TITLE_COLOR = { 0, 1, 0.596 }
local BODY_COLOR = { 0.9, 0.9, 0.9 }
local HIGHLIGHT_COLOR = { 1, 0.82, 0 }
local DIVIDER_COLOR = { 0, 0, 0, 1 }
local BG_COLOR = { 0, 0, 0, 0.8 }
local BORDER_COLOR = { 0, 0, 0, 1 }

local announcementDialog

local function BuildAnnouncementDialog()
    if announcementDialog then return announcementDialog end

    local fontPath = addon:FetchFont("DorisPP")

    local frame = CreateFrame("Frame", "ZenFramesAnnouncementDialog", UIParent, "BackdropTemplate")
    frame:SetSize(DIALOG_WIDTH, DIALOG_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = BORDER_WIDTH,
        insets = { left = BORDER_WIDTH, right = BORDER_WIDTH, top = BORDER_WIDTH, bottom = BORDER_WIDTH },
    })
    frame:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    frame:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, TITLE_FONT_SIZE, "OUTLINE")
    title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    title:SetPoint("TOP", frame, "TOP", 0, -(BORDER_WIDTH + PADDING))
    title:SetText(addon:L("announcementTitle"))
    frame._title = title

    -- Divider under title
    local dividerY = -(BORDER_WIDTH + PADDING + TITLE_FONT_SIZE + 10)
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(DIVIDER_HEIGHT)
    divider:SetColorTexture(DIVIDER_COLOR[1], DIVIDER_COLOR[2], DIVIDER_COLOR[3], DIVIDER_COLOR[4])
    divider:SetPoint("LEFT", frame, "LEFT", BORDER_WIDTH + PADDING, 0)
    divider:SetPoint("RIGHT", frame, "RIGHT", -(BORDER_WIDTH + PADDING), 0)
    divider:SetPoint("TOP", frame, "TOP", 0, dividerY)
    frame._divider = divider

    local contentLeft = BORDER_WIDTH + PADDING
    local contentWidth = DIALOG_WIDTH - 2 * (BORDER_WIDTH + PADDING)

    -- Icon (left-aligned, 5px below divider)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetAtlas("raceicon128-pandaren-male")
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, dividerY - 10)
    frame._icon = icon

    -- Greeting (speech bubble near icon mouth)
    local greeting = frame:CreateFontString(nil, "OVERLAY")
    greeting:SetFont(fontPath, BODY_FONT_SIZE + 1, "OUTLINE")
    greeting:SetTextColor(HIGHLIGHT_COLOR[1], HIGHLIGHT_COLOR[2], HIGHLIGHT_COLOR[3])
    greeting:SetPoint("LEFT", icon, "RIGHT", 10, -10)
    greeting:SetJustifyH("LEFT")
    greeting:SetText("\226\128\148" .. addon:L("announcementGreeting"))
    frame._greeting = greeting

    -- Content starts below icon
    local y = dividerY - 10 - ICON_SIZE - 30

    -- Bullet 1
    local bullet1 = frame:CreateFontString(nil, "OVERLAY")
    bullet1:SetFont(fontPath, BULLET_FONT_SIZE, "OUTLINE")
    bullet1:SetTextColor(BODY_COLOR[1], BODY_COLOR[2], BODY_COLOR[3])
    bullet1:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft + 10, y)
    bullet1:SetWidth(contentWidth - 10)
    bullet1:SetJustifyH("LEFT")
    bullet1:SetText("* " .. addon:L("announcementBullet1"))
    frame._bullet1 = bullet1

    y = y - 20

    -- Bullet 2
    local bullet2 = frame:CreateFontString(nil, "OVERLAY")
    bullet2:SetFont(fontPath, BULLET_FONT_SIZE, "OUTLINE")
    bullet2:SetTextColor(BODY_COLOR[1], BODY_COLOR[2], BODY_COLOR[3])
    bullet2:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft + 10, y)
    bullet2:SetWidth(contentWidth - 10)
    bullet2:SetJustifyH("LEFT")
    bullet2:SetText("* " .. addon:L("announcementBullet2"))
    frame._bullet2 = bullet2

    y = y - 50

    -- Apology
    local apology = frame:CreateFontString(nil, "OVERLAY")
    apology:SetFont(fontPath, BODY_FONT_SIZE, "OUTLINE")
    apology:SetTextColor(BODY_COLOR[1], BODY_COLOR[2], BODY_COLOR[3])
    apology:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, y)
    apology:SetWidth(contentWidth)
    apology:SetJustifyH("LEFT")
    apology:SetWordWrap(true)
    apology:SetText(addon:L("announcementApology"))
    frame._apology = apology

    y = y - 50

    -- Contact
    local contact = frame:CreateFontString(nil, "OVERLAY")
    contact:SetFont(fontPath, BODY_FONT_SIZE, "OUTLINE")
    contact:SetTextColor(BODY_COLOR[1], BODY_COLOR[2], BODY_COLOR[3])
    contact:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, y)
    contact:SetWidth(contentWidth)
    contact:SetJustifyH("LEFT")
    contact:SetWordWrap(true)
    contact:SetText(addon:L("announcementContact"))
    frame._contact = contact

    y = y - 60

    -- Launch Edit Mode button
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetSize(contentWidth, BUTTON_HEIGHT)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, y)
    btn:SetText(addon:L("announcementLaunchButton"))
    btn:GetFontString():SetFont(fontPath, BUTTON_FONT_SIZE, "OUTLINE")
    btn:SetScript("OnClick", function()
        addon:DismissAnnouncement()
        addon:EnableEditMode()
    end)
    frame._launchButton = btn

    y = y - BUTTON_HEIGHT - PADDING - BORDER_WIDTH

    frame:SetHeight(math.abs(y))

    frame:Hide()
    announcementDialog = frame
    return frame
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function addon:ShowAnnouncement(announcementId)
    if not self.savedVars then return false end

    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.dismissedAnnouncements = self.savedVars.data.dismissedAnnouncements or {}

    if self.savedVars.data.dismissedAnnouncements[announcementId] then
        return false
    end

    local dialog = BuildAnnouncementDialog()
    dialog._currentAnnouncementId = announcementId
    dialog:Show()

    return true
end

function addon:DismissAnnouncement()
    if announcementDialog then
        local announcementId = announcementDialog._currentAnnouncementId
        if announcementId and self.savedVars then
            self.savedVars.data = self.savedVars.data or {}
            self.savedVars.data.dismissedAnnouncements = self.savedVars.data.dismissedAnnouncements or {}
            self.savedVars.data.dismissedAnnouncements[announcementId] = true
        end
        announcementDialog:Hide()
    end

    return true
end

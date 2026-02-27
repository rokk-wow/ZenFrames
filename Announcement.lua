local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Announcement dialog - shown once per version after update
-- ---------------------------------------------------------------------------

local announcementDialog

local function BuildAnnouncementDialog()
    if announcementDialog then return announcementDialog end

    local dialog = addon:CreateDialog({
        name = "ZenFramesAnnouncementDialog",
        title = "announcementTitle",
        width = 450,
        showCloseButton = false,
        dismissOnEscape = true,
        showAvatar = true,
        avatarSpeech = "announcementGreeting",
        footerButtons = {
            {
                text = "announcementLaunchButton",
                onClick = function()
                    addon:DismissAnnouncement()
                    addon:EnableEditMode()
                end,
            },
        },
    })

    local y = dialog._contentTop
    local _, newY = addon:DialogAddDescription(dialog, y, {
        "announcementBullet1",
        "announcementBullet2",
        "announcementApology",
        "announcementContact",
    })
    addon:DialogFinalize(dialog, newY)

    announcementDialog = dialog
    return dialog
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

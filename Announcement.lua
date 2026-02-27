local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Announcement dialog - shown once per version after update
-- ---------------------------------------------------------------------------

local CURRENT_ANNOUNCEMENT_ID = "v2.1.0"

local ANNOUNCEMENT_LOCALIZATION = {
    enEN = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Greetings, gladiator.",
        announcementBullet1 = "- Blitz, Battleground, Epic Battleground and Raid frames added",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Launch Edit Mode",
    },
    esES = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Saludos, gladiador.",
	    announcementBullet1 = "- Se añadieron marcos de Blitz, Campos de Batalla, Campos de Batalla Épicos y Banda",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Abrir Modo de Edición",
    },
    esMX = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Saludos, gladiador.",
	    announcementBullet1 = "- Se añadieron marcos de Blitz, Campos de Batalla, Campos de Batalla Épicos y Banda",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Abrir Modo de Edición",
    },
    ptBR = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Saudações, gladiador.",
	    announcementBullet1 = "- Foram adicionados quadros de Blitz, Campo de Batalha, Campo de Batalha Épico e Raide",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Abrir Modo de Edição",
    },
    frFR = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Salutations, gladiateur.",
	    announcementBullet1 = "- Ajout des cadres Blitz, Champs de bataille, Champs de bataille épiques et Raid",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Ouvrir le Mode Édition",
    },
    deDE = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Seid gegrüßt, Gladiator.",
	    announcementBullet1 = "- Blitz-, Schlachtfeld-, epische Schlachtfeld- und Schlachtzugsfenster hinzugefügt",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Bearbeitungsmodus öffnen",
    },
    ruRU = {
        announcementTitle = "ZenFrames v2.1.0",
        announcementGreeting = "Приветствую, гладиатор.",
	    announcementBullet1 = "- Добавлены рамки для Blitz, полей боя, эпических полей боя и рейда",
        announcementContact = "|cffffd100https://discord.gg/JYKdcdMyQG|r",
        announcementLaunchButton = "Открыть режим редактирования",
    },
}

local function ApplyAnnouncementLocalization()
    if type(addon.locale) ~= "table" then return end

    for localeKey, localeValues in pairs(ANNOUNCEMENT_LOCALIZATION) do
        if type(addon.locale[localeKey]) ~= "table" then
            addon.locale[localeKey] = {}
        end

        local localeTable = addon.locale[localeKey]

        for index = 1, 50 do
            local bulletKey = "announcementBullet" .. index
            if localeValues[bulletKey] == nil then
                localeTable[bulletKey] = nil
            end
        end

        for key, value in pairs(localeValues) do
            localeTable[key] = value
        end
    end

    addon.localization = addon.locale[GetLocale()] or addon.locale.enEN
end

ApplyAnnouncementLocalization()

local announcementDialog

function addon:GetCurrentAnnouncementId()
    return CURRENT_ANNOUNCEMENT_ID
end

local function IsNonEmptyText(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

function addon:GetAnnouncementBodyKeys()
    local localeTable = self.localization or (self.locale and self.locale.enEN) or {}
    local keys = {}

    for index = 1, 50 do
        local bulletKey = "announcementBullet" .. index
        local bulletText = localeTable[bulletKey]

        if bulletText == nil then
            break
        end

        if IsNonEmptyText(bulletText) then
            keys[#keys + 1] = bulletKey
        end
    end

    if IsNonEmptyText(localeTable.announcementContact) then
        keys[#keys + 1] = "announcementContact"
    end

    return keys
end

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
    local bodyKeys = addon:GetAnnouncementBodyKeys()
    local newY = y
    if #bodyKeys > 0 then
        local _
        _, newY = addon:DialogAddDescription(dialog, y, bodyKeys)
    end
    addon:DialogFinalize(dialog, newY)

    announcementDialog = dialog
    return dialog
end

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

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Dialog style constants
-- ---------------------------------------------------------------------------

local BORDER_WIDTH = 8
local PADDING = 30
local TITLE_FONT_SIZE = 22
local TITLE_COLOR = { 0, 1, 0.596 }
local BG_COLOR = { 0, 0, 0, 0.8 }
local BORDER_COLOR = { 0, 0, 0, 1 }
local DIVIDER_HEIGHT = 2
local DIVIDER_COLOR = { 0, 0, 0, 1 }
local BODY_FONT_SIZE = 13
local BODY_COLOR = { 0.9, 0.9, 0.9 }
local AVATAR_SPEECH_COLOR = { 1, 0.82, 0 }
local AVATAR_SPEECH_FONT_SIZE = 14
local AVATAR_DEFAULT_SIZE = 64
local AVATAR_DEFAULT_ATLAS = "raceicon128-pandaren-male"
local BUTTON_FONT_SIZE = 13
local BUTTON_HEIGHT = 28
local BUTTON_SPACING = 10
local ICON_DEFAULT_SIZE = 24
local CLOSE_BUTTON_ATLAS = "BackupPet-DeadFrame"
local TITLE_ICON_OFFSET_X = 14
local TITLE_ICON_OFFSET_Y = 11
local DIALOG_WIDTH_1_COL = 300
local DIALOG_WIDTH_2_COL = 600
local COLUMN_GAP = 28

-- ---------------------------------------------------------------------------
-- Exported style constants for other modules
-- ---------------------------------------------------------------------------

addon.DialogStyle = {
    BORDER_WIDTH = BORDER_WIDTH,
    PADDING = PADDING,
    TITLE_FONT_SIZE = TITLE_FONT_SIZE,
    TITLE_COLOR = TITLE_COLOR,
    BG_COLOR = BG_COLOR,
    BORDER_COLOR = BORDER_COLOR,
    DIVIDER_HEIGHT = DIVIDER_HEIGHT,
    DIVIDER_COLOR = DIVIDER_COLOR,
    BODY_FONT_SIZE = BODY_FONT_SIZE,
    BODY_COLOR = BODY_COLOR,
    AVATAR_SPEECH_COLOR = AVATAR_SPEECH_COLOR,
    AVATAR_SPEECH_FONT_SIZE = AVATAR_SPEECH_FONT_SIZE,
    AVATAR_DEFAULT_SIZE = AVATAR_DEFAULT_SIZE,
    AVATAR_DEFAULT_ATLAS = AVATAR_DEFAULT_ATLAS,
    BUTTON_FONT_SIZE = BUTTON_FONT_SIZE,
    BUTTON_HEIGHT = BUTTON_HEIGHT,
    BUTTON_SPACING = BUTTON_SPACING,
    ICON_DEFAULT_SIZE = ICON_DEFAULT_SIZE,
    CLOSE_BUTTON_ATLAS = CLOSE_BUTTON_ATLAS,
    TITLE_ICON_OFFSET_X = TITLE_ICON_OFFSET_X,
    TITLE_ICON_OFFSET_Y = TITLE_ICON_OFFSET_Y,
    DIALOG_WIDTH_1_COL = DIALOG_WIDTH_1_COL,
    DIALOG_WIDTH_2_COL = DIALOG_WIDTH_2_COL,
    COLUMN_GAP = COLUMN_GAP,
}

-- ---------------------------------------------------------------------------
-- Active replace-mode dialog tracking
-- ---------------------------------------------------------------------------

local activeReplaceDialog

-- ---------------------------------------------------------------------------
-- ESC dismiss stack — tracks all visible Dialogs with dismissOnEscape
-- ---------------------------------------------------------------------------

local STRATA_ORDER = {
    BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4,
    DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8,
}

local DialogStack = {}

local function RegisterDialogForEscape(frame)
    DialogStack[frame] = true
end

local function UnregisterDialogForEscape(frame)
    DialogStack[frame] = nil
end

local function DismissTopDialog()
    local topDialog, topScore = nil, -1

    for dialog in pairs(DialogStack) do
        if dialog:IsShown() then
            local strataValue = STRATA_ORDER[dialog:GetFrameStrata()] or 0
            local level = dialog:GetFrameLevel() or 0
            local score = strataValue * 100000 + level
            if score > topScore then
                topScore = score
                topDialog = dialog
            end
        else
            DialogStack[dialog] = nil
        end
    end

    if topDialog then
        topDialog:Hide()
        return true
    end

    return false
end

local escFrame = CreateFrame("Frame", "DialogEscapeHandler", UIParent)
local function SetEscKeyPropagation(frame, propagate)
    if frame._propagateKeyboardInput == propagate then
        return
    end

    frame._propagateKeyboardInput = propagate
    if InCombatLockdown() then
        return
    end

    frame:SetPropagateKeyboardInput(propagate)
end

escFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
escFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:SetPropagateKeyboardInput(self._propagateKeyboardInput ~= false)
    end
end)

escFrame:EnableKeyboard(true)
SetEscKeyPropagation(escFrame, true)
escFrame:SetScript("OnKeyDown", function(self, key)
    if key ~= "ESCAPE" then
        SetEscKeyPropagation(self, true)
        return
    end

    if DismissTopDialog() then
        SetEscKeyPropagation(self, false)
    else
        SetEscKeyPropagation(self, true)
    end
end)

local function GetFrameCenter(frame)
    if not frame then return nil, nil end
    local left = frame:GetLeft()
    local right = frame:GetRight()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()
    if not left or not right or not top or not bottom then return nil, nil end
    return (left + right) / 2, (top + bottom) / 2
end

-- ---------------------------------------------------------------------------
-- Title bar icon builder (shared by left and right icon)
-- ---------------------------------------------------------------------------

local function CreateTitleBarIcon(frame, cfg, anchorPoint, anchorOffsetX, anchorOffsetY)
    local iconSize = cfg.size or ICON_DEFAULT_SIZE
    local startDesaturated = cfg.desaturated ~= false

    local iconBtn = CreateFrame("Button", nil, frame)
    iconBtn:SetSize(iconSize, iconSize)
    iconBtn:SetPoint("CENTER", frame, anchorPoint, anchorOffsetX, anchorOffsetY)

    local iconTex = iconBtn:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints()
    iconTex:SetAtlas(cfg.atlas)
    if cfg.rotation then
        iconTex:SetRotation(cfg.rotation)
    end
    iconTex:SetDesaturated(startDesaturated)

    iconBtn:SetScript("OnEnter", function()
        iconTex:SetDesaturated(not startDesaturated)
    end)
    iconBtn:SetScript("OnLeave", function()
        iconTex:SetDesaturated(startDesaturated)
    end)

    if cfg.onClick then
        iconBtn:SetScript("OnClick", function()
            cfg.onClick(frame)
        end)
    end

    iconBtn._texture = iconTex
    return iconBtn
end

-- ---------------------------------------------------------------------------
-- CreateDialog
--
-- options:
--   name              string    Global frame name
--   title             string    Localization key for title text
--   titleFontSize     number    Title font size (default 22)
--   columns           number    Number of content columns: 1 (default) or 2
--   width             number    Dialog width (overrides column default)
--   height            number    Dialog height (default 300)
--   frameStrata       string    Frame strata (default "DIALOG")
--   frameLevel        number    Frame level (default 200)
--   movable           boolean   Draggable (default true)
--   clampedToScreen   boolean   Clamped (default true)
--
--   leftIcon          table     { atlas, size, rotation, desaturated, onClick }
--   rightIcon         table     { atlas, size, rotation, desaturated, onClick }
--   showCloseButton   boolean   Show close icon in top-right corner (default true)
--   onCloseClick      function  Custom close-icon click handler; receives (dialog).
--                               If nil, defaults to dialog:Hide().
--
--   showAvatar        boolean   Show avatar icon below divider
--   avatarAtlas       string    Avatar atlas (default pandaren male)
--   avatarSize        number    Avatar icon size (default 64)
--   avatarSpeech      string    Localization key for avatar speech text
--
--   footerButtons     table     { { text, onClick }, ... } bottom buttons (text = loc key)
--
--   dismissOnEscape   boolean   Register with global ESC stack (default false).
--                               ESC closes the topmost visible Dialog by
--                               strata + frameLevel, so layered dialogs close
--                               in the correct order.
--   persistOnReload   boolean   If true, the dialog automatically reopens after
--                               ReloadUI() if it was visible at reload time.
--                               Requires a global frame name (options.name).
--
-- Showing dialogs (addon:ShowDialog(dialog, mode)):
--   "replace"      Hides the previous replace-mode dialog and opens the new
--                  one at the same position. If no previous dialog, centers.
--   "standalone"   Opens centered at a higher strata, independent of any
--                  existing dialogs. (default)
--   Both modes check InCombatLockdown() and return false if in combat.
--
-- Hiding dialogs:
--   addon:HideDialog(dialog) - hides with combat lockdown guard
--   addon:DismissTopDialog() - closes the topmost ESC-stack dialog
--
-- Confirmation popup helper:
--   addon:ShowDialogConfirm({ title, body, onConfirm, onCancel, width })
--   Builds and shows a confirmation dialog with OK/Cancel buttons.
--
-- Persist on reload:
--   Set persistOnReload = true in CreateDialog options. The dialog
--   automatically saves its visibility state to savedVars on show/hide.
--   Call addon:DialogRestorePersisted() once after login to reopen
--   any dialogs that were visible before the reload.
--
-- Returns the dialog frame with internal layout properties:
--   _fontPath              Font path string
--   _padding               Inner padding value
--   _borderWidth           Border edge size
--   _title                 Title FontString
--   _divider               Title divider texture
--   _leftIcon              Left icon button (if created)
--   _titleIcon             Alias for _leftIcon._texture (backward compat)
--   _titleHover            Alias for _leftIcon (backward compat)
--   _rightIcon             Right icon button (if created)
--   _closeButton           Close icon button (if showCloseButton)
--   _avatar                Avatar texture (if showAvatar)
--   _avatarSpeech          Avatar speech FontString (if avatarSpeech)
--   _footerButtons         Table of footer button frames (if footerButtons)
--   _contentTop            Y offset where content area begins (below avatar or divider)
--   _contentBottom         Y offset where content area ends (above footer or frame bottom)
--   _contentAreaTopOffset  Same as _contentTop (backward compat)
--   _contentLeft           Left edge of content area
--   _contentWidth          Usable content width
--   _columns               Number of columns (1 or 2)
--   _leftColumn            Left column frame (if columns == 2)
--   _rightColumn           Right column frame (if columns == 2)
--   title                  Alias for _title (backward compat)
--   _titleDivider          Alias for _divider (backward compat)
-- ---------------------------------------------------------------------------

function addon:CreateDialog(options)
    options = options or {}

    local name = options.name
    local columns = options.columns or 1
    local width = options.width
    if not width then
        width = columns == 2 and DIALOG_WIDTH_2_COL or DIALOG_WIDTH_1_COL
    end
    local height = options.height or 300
    local titleText = options.title or ""
    local titleFontSize = options.titleFontSize or TITLE_FONT_SIZE
    local frameStrata = options.frameStrata or "DIALOG"
    local frameLevel = options.frameLevel or 200
    local movable = options.movable ~= false
    local clampedToScreen = options.clampedToScreen ~= false

    local fontPath = self:FetchFont("DorisPP")

    -- -------------------------------------------------------------------
    -- Base frame
    -- -------------------------------------------------------------------

    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata(frameStrata)
    frame:SetFrameLevel(frameLevel)
    frame:SetClampedToScreen(clampedToScreen)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = BORDER_WIDTH,
        insets = { left = BORDER_WIDTH, right = BORDER_WIDTH, top = BORDER_WIDTH, bottom = BORDER_WIDTH },
    })
    frame:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    frame:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])

    frame:EnableMouse(true)
    if movable then
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    -- Internal properties for dialog control compatibility
    frame._fontPath = fontPath
    frame._padding = PADDING
    frame._borderWidth = BORDER_WIDTH

    local contentLeft = BORDER_WIDTH + PADDING
    local contentWidth = width - 2 * contentLeft

    -- -------------------------------------------------------------------
    -- Title
    -- -------------------------------------------------------------------

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, titleFontSize, "OUTLINE")
    title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    title:SetPoint("TOP", frame, "TOP", 0, -(BORDER_WIDTH + PADDING))
    title:SetText(self:L(titleText))

    local hasLeftIcon = options.leftIcon ~= nil
    local hasCloseButton = options.showCloseButton ~= false
    local hasRightIcon = options.rightIcon ~= nil
    local titlePadding = 0
    if hasLeftIcon then titlePadding = titlePadding + 30 end
    if hasCloseButton then titlePadding = titlePadding + 30 end
    if hasRightIcon then titlePadding = titlePadding + 30 end
    if titlePadding > 0 then
        title:SetWidth(contentWidth - titlePadding)
        title:SetWordWrap(false)
        title:SetMaxLines(1)
    end

    frame._title = title
    frame.title = title

    -- -------------------------------------------------------------------
    -- Left title bar icon
    -- -------------------------------------------------------------------

    if options.leftIcon then
        local iconOffsetX = BORDER_WIDTH + PADDING + TITLE_ICON_OFFSET_X - 8
        local iconOffsetY = -(BORDER_WIDTH + PADDING + TITLE_ICON_OFFSET_Y)

        frame._leftIcon = CreateTitleBarIcon(frame, options.leftIcon, "TOPLEFT", iconOffsetX, iconOffsetY)
        frame._titleIcon = frame._leftIcon._texture
        frame._titleHover = frame._leftIcon
    end

    -- -------------------------------------------------------------------
    -- Close icon (far right, shown by default)
    -- -------------------------------------------------------------------

    local closeIconWidth = 0
    if options.showCloseButton ~= false then
        local closeCfg = {
            atlas = CLOSE_BUTTON_ATLAS,
            size = ICON_DEFAULT_SIZE,
            desaturated = true,
            onClick = options.onCloseClick or function(dialog)
                dialog:Hide()
            end,
        }

        local iconOffsetX = -(BORDER_WIDTH + PADDING + TITLE_ICON_OFFSET_X - 4)
        local iconOffsetY = -(BORDER_WIDTH + PADDING + TITLE_ICON_OFFSET_Y)

        frame._closeButton = CreateTitleBarIcon(frame, closeCfg, "TOPRIGHT", iconOffsetX, iconOffsetY)
        closeIconWidth = ICON_DEFAULT_SIZE + 8
    end

    -- -------------------------------------------------------------------
    -- Right title bar icon (positioned left of close icon)
    -- -------------------------------------------------------------------

    if options.rightIcon then
        local iconOffsetX = -(BORDER_WIDTH + PADDING + TITLE_ICON_OFFSET_X + closeIconWidth)
        local iconOffsetY = -(BORDER_WIDTH + PADDING + TITLE_ICON_OFFSET_Y)

        if not options.rightIcon.onClick then
            options.rightIcon.onClick = function(dialog) dialog:Hide() end
        end

        frame._rightIcon = CreateTitleBarIcon(frame, options.rightIcon, "TOPRIGHT", iconOffsetX, iconOffsetY)
    end

    -- -------------------------------------------------------------------
    -- Title divider
    -- -------------------------------------------------------------------

    local dividerY = -(BORDER_WIDTH + PADDING + titleFontSize + 20)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(DIVIDER_HEIGHT)
    divider:SetColorTexture(DIVIDER_COLOR[1], DIVIDER_COLOR[2], DIVIDER_COLOR[3], DIVIDER_COLOR[4])
    divider:SetPoint("LEFT", frame, "LEFT", contentLeft, 0)
    divider:SetPoint("RIGHT", frame, "RIGHT", -contentLeft, 0)
    divider:SetPoint("TOP", frame, "TOP", 0, dividerY)

    frame._divider = divider
    frame._titleDivider = divider

    local contentY = dividerY - DIVIDER_HEIGHT - 8

    -- -------------------------------------------------------------------
    -- Avatar section
    -- -------------------------------------------------------------------

    if options.showAvatar then
        local avatarSize = options.avatarSize or AVATAR_DEFAULT_SIZE
        local avatarAtlas = options.avatarAtlas or AVATAR_DEFAULT_ATLAS
        local avatarSpacing = 10

        local icon = frame:CreateTexture(nil, "OVERLAY")
        icon:SetSize(avatarSize, avatarSize)
        icon:SetAtlas(avatarAtlas)
        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, contentY)
        frame._avatar = icon

        if options.avatarSpeech then
            local speech = frame:CreateFontString(nil, "OVERLAY")
            speech:SetFont(fontPath, AVATAR_SPEECH_FONT_SIZE, "OUTLINE")
            speech:SetTextColor(AVATAR_SPEECH_COLOR[1], AVATAR_SPEECH_COLOR[2], AVATAR_SPEECH_COLOR[3])
            speech:SetPoint("LEFT", icon, "RIGHT", avatarSpacing, -10)
            speech:SetJustifyH("LEFT")
            speech:SetText("\226\128\148" .. self:L(options.avatarSpeech))
            frame._avatarSpeech = speech
        end

        contentY = contentY - avatarSize - avatarSpacing
    end

    frame._contentTop = contentY
    frame._contentAreaTopOffset = contentY
    frame._contentLeft = contentLeft
    frame._contentWidth = contentWidth
    frame._columns = columns

    -- -------------------------------------------------------------------
    -- Column layout (optional)
    -- -------------------------------------------------------------------

    if columns == 2 then
        local innerWidth = width - 2 * contentLeft
        local columnWidth = math.floor((innerWidth - COLUMN_GAP) / 2)

        local leftCol = CreateFrame("Frame", nil, frame)
        leftCol:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, contentY)
        leftCol:SetWidth(columnWidth)
        leftCol:SetHeight(1)
        leftCol._fontPath = fontPath
        leftCol._isDialogColumn = true
        frame._leftColumn = leftCol

        local rightCol = CreateFrame("Frame", nil, frame)
        rightCol:SetPoint("TOPLEFT", leftCol, "TOPRIGHT", COLUMN_GAP, 0)
        rightCol:SetWidth(columnWidth)
        rightCol:SetHeight(1)
        rightCol._fontPath = fontPath
        rightCol._isDialogColumn = true
        frame._rightColumn = rightCol
    end

    -- -------------------------------------------------------------------
    -- Footer buttons (bottom-aligned, centered)
    -- -------------------------------------------------------------------

    if options.footerButtons and #options.footerButtons > 0 then
        local numButtons = #options.footerButtons
        local footerY = BORDER_WIDTH + PADDING

        frame._footerButtons = {}

        if numButtons == 1 then
            local btnCfg = options.footerButtons[1]
            local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            btn:SetSize(contentWidth, BUTTON_HEIGHT)
            btn:SetPoint("BOTTOM", frame, "BOTTOM", 0, footerY)
            btn:SetText(btnCfg.text and self:L(btnCfg.text) or "")
            btn:GetFontString():SetFont(fontPath, BUTTON_FONT_SIZE, "OUTLINE")
            btn:SetScript("OnClick", function()
                if btnCfg.onClick then btnCfg.onClick(frame) end
            end)
            frame._footerButtons[1] = btn
        else
            local totalSpacing = (numButtons - 1) * BUTTON_SPACING
            local buttonWidth = (contentWidth - totalSpacing) / numButtons

            for i, btnCfg in ipairs(options.footerButtons) do
                local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
                btn:SetSize(buttonWidth, BUTTON_HEIGHT)
                btn:SetText(btnCfg.text and self:L(btnCfg.text) or "")
                btn:GetFontString():SetFont(fontPath, BUTTON_FONT_SIZE, "OUTLINE")
                btn:SetScript("OnClick", function()
                    if btnCfg.onClick then btnCfg.onClick(frame) end
                end)

                if i == 1 then
                    btn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeft, footerY)
                else
                    btn:SetPoint("LEFT", frame._footerButtons[i - 1], "RIGHT", BUTTON_SPACING, 0)
                end

                frame._footerButtons[i] = btn
            end
        end

        frame._contentBottom = -(height - BORDER_WIDTH - PADDING - BUTTON_HEIGHT - BUTTON_SPACING)
    else
        frame._contentBottom = -(height - BORDER_WIDTH - PADDING)
    end

    -- -------------------------------------------------------------------
    -- ESC key dismissal — register with global stack
    -- -------------------------------------------------------------------

    if options.dismissOnEscape then
        frame:HookScript("OnShow", function(self)
            RegisterDialogForEscape(self)
        end)
        frame:HookScript("OnHide", function(self)
            UnregisterDialogForEscape(self)
        end)
    end

    -- -------------------------------------------------------------------
    -- Persist on reload — track visibility in savedVars
    -- -------------------------------------------------------------------

    if options.persistOnReload and name then
        frame:HookScript("OnShow", function()
            addon.savedVars.data = addon.savedVars.data or {}
            addon.savedVars.data.DialogPersist = addon.savedVars.data.DialogPersist or {}
            addon.savedVars.data.DialogPersist[name] = true
        end)
        frame:HookScript("OnHide", function()
            if addon.savedVars and addon.savedVars.data
                and addon.savedVars.data.DialogPersist then
                addon.savedVars.data.DialogPersist[name] = nil
            end
        end)
    end

    frame:Hide()
    return frame
end

-- ---------------------------------------------------------------------------
-- ShowDialog
--
-- mode:
--   "replace"     Finds the last shown replace-mode dialog, takes its
--                 position, hides it, and shows the new dialog there.
--                 If no previous replace dialog exists, opens centered.
--   "standalone"  Opens centered at a higher strata, independent of any
--                 existing dialogs.
-- ---------------------------------------------------------------------------

function addon:ShowDialog(dialog, mode)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeShowDialog", dialog, mode)

    if InCombatLockdown() then
        callHook(self, "AfterShowDialog", false)
        return false
    end

    mode = mode or "standalone"
    dialog._DialogMode = mode

    if mode == "replace" then
        local centerX, centerY

        if activeReplaceDialog
            and activeReplaceDialog ~= dialog
            and activeReplaceDialog:IsShown()
        then
            centerX, centerY = GetFrameCenter(activeReplaceDialog)
            activeReplaceDialog:Hide()
        end

        dialog:ClearAllPoints()
        if centerX and centerY then
            dialog:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
        else
            dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end

        activeReplaceDialog = dialog
        dialog:Show()
    else
        dialog:SetFrameStrata("TOOLTIP")
        dialog:ClearAllPoints()
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        dialog:Show()
    end

    callHook(self, "AfterShowDialog", dialog)
    return dialog
end

-- ---------------------------------------------------------------------------
-- GetActiveDialogReplace - returns the current replace-mode dialog (if any)
-- ---------------------------------------------------------------------------

function addon:GetActiveDialogReplace()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeGetActiveDialogReplace")

    local result = activeReplaceDialog or false

    callHook(self, "AfterGetActiveDialogReplace", result)
    return result
end

-- ---------------------------------------------------------------------------
-- HideDialog — hide with combat lockdown guard
-- ---------------------------------------------------------------------------

function addon:HideDialog(dialog)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeHideDialog", dialog)

    if InCombatLockdown() then
        callHook(self, "AfterHideDialog", false)
        return false
    end

    dialog:Hide()

    callHook(self, "AfterHideDialog", true)
    return true
end

-- ---------------------------------------------------------------------------
-- DismissTopDialog — public API for the ESC stack
-- ---------------------------------------------------------------------------

function addon:DismissTopDialog()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeDismissTopDialog")

    local result = DismissTopDialog()

    callHook(self, "AfterDismissTopDialog", result)
    return result
end

-- ---------------------------------------------------------------------------
-- Persist on reload — reopen dialogs that were visible before ReloadUI()
-- ---------------------------------------------------------------------------

function addon:DialogRestorePersisted()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeDialogRestorePersisted")

    if not self.savedVars or not self.savedVars.data
        or not self.savedVars.data.DialogPersist then
        callHook(self, "AfterDialogRestorePersisted", false)
        return false
    end

    local reopened = false
    for dialogName in pairs(self.savedVars.data.DialogPersist) do
        local frame = _G[dialogName]
        if frame and frame.Show then
            frame:Show()
            reopened = true
        end
    end

    callHook(self, "AfterDialogRestorePersisted", reopened)
    return reopened
end

-- ---------------------------------------------------------------------------
-- ShowDialogConfirm — confirmation popup helper
--
--   options:
--     title       string        Localization key for the title
--     body        string|table  Localization key(s) for body paragraphs
--     onConfirm   function      Called when the user clicks OK
--     onCancel    function      Called when the user clicks Cancel (optional)
--     width       number        Dialog width (default 350)
--     height      number        Minimum dialog height (optional)
-- ---------------------------------------------------------------------------

function addon:ShowDialogConfirm(options)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeShowDialogConfirm", options)

    if InCombatLockdown() then
        callHook(self, "AfterShowDialogConfirm", false)
        return false
    end

    options = options or {}
    local confirmWidth = options.width or 350

    local dialog = self:CreateDialog({
        title = options.title or "",
        width = confirmWidth,
        frameStrata = "TOOLTIP",
        frameLevel = 900,
        dismissOnEscape = true,
        footerButtons = {
            {
                text = options.confirmText or "DialogOk",
                onClick = function(dlg)
                    dlg:Hide()
                    if options.onConfirm then
                        options.onConfirm()
                    end
                end,
            },
            {
                text = options.cancelText or "emCancel",
                onClick = function(dlg)
                    dlg:Hide()
                    if options.onCancel then
                        options.onCancel()
                    end
                end,
            },
        },
    })

    local y = dialog._contentTop
    if options.body then
        local _, newY = self:DialogAddDescription(dialog, y, options.body)
        y = newY
    end
    self:DialogFinalize(dialog, y)
    if options.height and dialog.GetHeight and dialog.SetHeight then
        local currentHeight = dialog:GetHeight() or 0
        if currentHeight < options.height then
            dialog:SetHeight(options.height)
        end
    end
    self:ShowDialog(dialog, "standalone")

    callHook(self, "AfterShowDialogConfirm", dialog)
    return dialog
end

-- ---------------------------------------------------------------------------
-- DialogMarkPersistent — dynamically mark a dialog for reload persistence
-- ---------------------------------------------------------------------------

function addon:DialogMarkPersistent(dialog)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeDialogMarkPersistent", dialog)

    if not dialog then
        callHook(self, "AfterDialogMarkPersistent", false)
        return false
    end

    local name = dialog:GetName()
    if not name then
        callHook(self, "AfterDialogMarkPersistent", false)
        return false
    end

    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.DialogPersist = self.savedVars.data.DialogPersist or {}
    self.savedVars.data.DialogPersist[name] = true

    callHook(self, "AfterDialogMarkPersistent", true)
    return true
end

-- ---------------------------------------------------------------------------
-- DialogMarkNotPersistent — remove a dialog from reload persistence
-- ---------------------------------------------------------------------------

function addon:DialogMarkNotPersistent(dialog)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeDialogMarkNotPersistent", dialog)

    if not dialog then
        callHook(self, "AfterDialogMarkNotPersistent", false)
        return false
    end

    local name = dialog:GetName()
    if not name then
        callHook(self, "AfterDialogMarkNotPersistent", false)
        return false
    end

    if self.savedVars and self.savedVars.data
        and self.savedVars.data.DialogPersist then
        self.savedVars.data.DialogPersist[name] = nil
    end

    callHook(self, "AfterDialogMarkNotPersistent", true)
    return true
end

-- ---------------------------------------------------------------------------
-- DialogFinalize - resize dialog height to fit content
-- ---------------------------------------------------------------------------

function addon:DialogFinalize(dialog, yOffset)
    local bottomReserved = BORDER_WIDTH + PADDING
    if dialog._footerButtons and #dialog._footerButtons > 0 then
        bottomReserved = bottomReserved + BUTTON_HEIGHT + BUTTON_SPACING
    end

    local totalHeight = math.abs(yOffset) + bottomReserved
    dialog:SetHeight(totalHeight)

    if dialog._footerButtons and #dialog._footerButtons > 0 then
        dialog._contentBottom = -(totalHeight - BORDER_WIDTH - PADDING - BUTTON_HEIGHT - BUTTON_SPACING)
    else
        dialog._contentBottom = -(totalHeight - BORDER_WIDTH - PADDING)
    end
end

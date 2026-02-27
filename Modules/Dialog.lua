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

-- ===========================================================================
-- Dialog Controls
-- Standardized form controls for use with any Dialog frame.
-- All controls follow the yOffset accumulator pattern:
--   local row, yOffset = addon:DialogAdd*(dialog, yOffset, ...)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Control style constants
-- ---------------------------------------------------------------------------

local CONTROL_PADDING = 8
local CONTROL_SIZE = 28
local CONTROL_ROW_HEIGHT = 78
local CONTROL_ROW_HEIGHT_HALF = 40
local CONTROL_LABEL_FONT_SIZE = 14
local CONTROL_SMALL_LABEL_FONT_SIZE = 12
local CONTROL_BUTTON_FONT_SIZE = 13
local CONTROL_BUTTON_HEIGHT = 28

local GLOBAL_LOCK_ICON_SIZE = 28
local GLOBAL_LOCKED_ALPHA = 0.4

local HEADER_FONT_SIZE = 16
local HEADER_COLOR = { 0, 1, 0.596 }
local HEADER_SPACING_AFTER = 8
local SUBHEADER_FONT_SIZE = 14
local SUBHEADER_COLOR = { 1, 0.82, 0 }
local SUBHEADER_SPACING_AFTER = 6

local SECTION_TITLE_FONT_SIZE = 16
local SECTION_TITLE_TOP_PADDING = 12
local SECTION_TITLE_BOTTOM_PADDING = 12

local DROPDOWN_HEIGHT = 32
local DROPDOWN_ITEM_HEIGHT = 22
local DROPDOWN_MENU_MAX_VISIBLE = 10
local DROPDOWN_ARROW_ATLAS = "CreditsScreen-Assets-Buttons-Play"
local COLOR_SWATCH_SIZE = 20

-- ---------------------------------------------------------------------------
-- Export control style constants
-- ---------------------------------------------------------------------------

addon.DialogStyle.CONTROL_PADDING = CONTROL_PADDING
addon.DialogStyle.CONTROL_SIZE = CONTROL_SIZE
addon.DialogStyle.CONTROL_ROW_HEIGHT = CONTROL_ROW_HEIGHT
addon.DialogStyle.CONTROL_ROW_HEIGHT_HALF = CONTROL_ROW_HEIGHT_HALF
addon.DialogStyle.CONTROL_LABEL_FONT_SIZE = CONTROL_LABEL_FONT_SIZE
addon.DialogStyle.CONTROL_SMALL_LABEL_FONT_SIZE = CONTROL_SMALL_LABEL_FONT_SIZE
addon.DialogStyle.CONTROL_BUTTON_FONT_SIZE = CONTROL_BUTTON_FONT_SIZE
addon.DialogStyle.CONTROL_BUTTON_HEIGHT = CONTROL_BUTTON_HEIGHT
addon.DialogStyle.HEADER_FONT_SIZE = HEADER_FONT_SIZE
addon.DialogStyle.HEADER_COLOR = HEADER_COLOR
addon.DialogStyle.SUBHEADER_FONT_SIZE = SUBHEADER_FONT_SIZE
addon.DialogStyle.SUBHEADER_COLOR = SUBHEADER_COLOR
addon.DialogStyle.SECTION_TITLE_FONT_SIZE = SECTION_TITLE_FONT_SIZE

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function GetDialogPadding(parent)
    if parent and parent._isDialogColumn then
        return 0
    end
    return BORDER_WIDTH + PADDING
end

local function SetEllipsizedText(fontString, value, maxWidth)
    local fullText = tostring(value or "")
    fontString:SetText(fullText)

    if not maxWidth or maxWidth <= 0 then
        return
    end

    if fontString:GetStringWidth() <= maxWidth then
        return
    end

    local ellipsis = "..."
    local low = 0
    local high = #fullText

    while low < high do
        local mid = math.floor((low + high + 1) / 2)
        local candidate = string.sub(fullText, 1, mid) .. ellipsis
        fontString:SetText(candidate)

        if fontString:GetStringWidth() <= maxWidth then
            low = mid
        else
            high = mid - 1
        end
    end

    if low <= 0 then
        fontString:SetText(ellipsis)
    else
        fontString:SetText(string.sub(fullText, 1, low) .. ellipsis)
    end
end

local function ParseHexColor(hex)
    if not hex or hex == "" then return 1, 1, 1, 1 end
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    local a = tonumber(hex:sub(7, 8), 16) or 255
    return r / 255, g / 255, b / 255, a / 255
end

-- ---------------------------------------------------------------------------
-- Global lock button builder
-- ---------------------------------------------------------------------------

local function CreateGlobalLockButton(row, isLocked, onToggle)
    local lockButton = CreateFrame("Button", nil, row)
    lockButton:SetSize(GLOBAL_LOCK_ICON_SIZE, GLOBAL_LOCK_ICON_SIZE)
    lockButton:SetPoint("LEFT", row, "LEFT", 0, 0)

    local icon = lockButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetAtlas("GreatVault-32x32", true)
    lockButton.icon = icon

    function lockButton:SetLocked(locked)
        if locked then
            self.icon:SetDesaturated(true)
            self.icon:SetAlpha(GLOBAL_LOCKED_ALPHA)
        else
            self.icon:SetDesaturated(false)
            self.icon:SetAlpha(1)
        end
    end

    lockButton:SetLocked(isLocked)
    lockButton:SetScript("OnClick", function(self)
        local newLocked = not self._locked
        self._locked = newLocked
        self:SetLocked(newLocked)
        if onToggle then
            onToggle(newLocked)
        end
    end)
    lockButton._locked = isLocked

    return lockButton
end

-- ---------------------------------------------------------------------------
-- Active dropdown tracking
-- ---------------------------------------------------------------------------

local activeDropdown

local function HideactiveDropdown()
    if activeDropdown and activeDropdown.menu and activeDropdown.menu:IsShown() then
        activeDropdown.menu:Hide()
    end
end

function addon:DialogHasOpenDropdown()
    return activeDropdown and activeDropdown.menu and activeDropdown.menu:IsShown() or false
end

function addon:DialogScrollOpenDropdown(delta)
    if not self:DialogHasOpenDropdown() then
        return false
    end

    local dropdown = activeDropdown
    local range = dropdown.scroll:GetVerticalScrollRange()
    if range <= 0 then
        return true
    end

    local current = dropdown.scroll:GetVerticalScroll()
    local nextValue = current - (delta * DROPDOWN_ITEM_HEIGHT)
    if nextValue < 0 then
        nextValue = 0
    elseif nextValue > range then
        nextValue = range
    end

    dropdown.scroll:SetVerticalScroll(nextValue)
    return true
end

-- ---------------------------------------------------------------------------
-- DialogAddDivider
-- ---------------------------------------------------------------------------

function addon:DialogAddDivider(dialog, yOffset)
    local padLeft = GetDialogPadding(dialog)
    local divider = dialog:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(DIVIDER_HEIGHT)
    divider:SetColorTexture(DIVIDER_COLOR[1], DIVIDER_COLOR[2], DIVIDER_COLOR[3], DIVIDER_COLOR[4])
    divider:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    divider:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    divider:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    return divider, yOffset - DIVIDER_HEIGHT
end

-- ---------------------------------------------------------------------------
-- DialogAddToggleRow - checkbox + visibility eye + label
-- ---------------------------------------------------------------------------

function addon:DialogAddToggleRow(dialog, yOffset, label, checked, visible, onCheckChanged, onVisibilityChanged)
    label = addon:L(label)

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT_HALF)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    cb:SetScript("OnClick", function(self)
        if onCheckChanged then
            onCheckChanged(self:GetChecked())
        end
    end)
    row.checkbox = cb

    local eye = CreateFrame("Button", nil, row)
    eye:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    eye:SetPoint("LEFT", cb, "RIGHT", CONTROL_PADDING, 0)

    local eyeIcon = eye:CreateTexture(nil, "ARTWORK")
    eyeIcon:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    eyeIcon:SetPoint("CENTER", eye, "CENTER", 0, 0)
    eye.icon = eyeIcon

    local function UpdateEyeIcon(isVisible)
        if isVisible then
            eyeIcon:SetAtlas("GM-icon-visible")
            eyeIcon:SetVertexColor(1, 0.82, 0, 1)
            eyeIcon:SetSize(CONTROL_SIZE + 2, CONTROL_SIZE + 2)
        else
            eyeIcon:SetAtlas("GM-icon-visibleDis")
            eyeIcon:SetVertexColor(1, 1, 1, 1)
            eyeIcon:SetSize(CONTROL_SIZE, CONTROL_SIZE)
        end
    end

    eye._visible = visible
    UpdateEyeIcon(visible)

    eye:SetScript("OnClick", function(self)
        self._visible = not self._visible
        UpdateEyeIcon(self._visible)
        if onVisibilityChanged then
            onVisibilityChanged(self._visible)
        end
    end)
    row.eye = eye

    local fontPath = dialog._fontPath
    local text = row:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("LEFT", eye, "RIGHT", CONTROL_PADDING, 0)
    text:SetText(label)
    row.label = text

    return row, yOffset - CONTROL_ROW_HEIGHT_HALF
end

-- ---------------------------------------------------------------------------
-- DialogAddCheckbox - simple checkbox + label
-- ---------------------------------------------------------------------------

function addon:DialogAddCheckbox(dialog, yOffset, label, checked, onChange)
    label = addon:L(label)

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT_HALF)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    cb:SetScript("OnClick", function(self)
        if onChange then
            onChange(self:GetChecked())
        end
    end)
    row.checkbox = cb

    local text = row:CreateFontString(nil, "OVERLAY")
    text:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("LEFT", cb, "RIGHT", CONTROL_PADDING, 0)
    text:SetText(label)
    row.label = text

    return row, yOffset - CONTROL_ROW_HEIGHT_HALF
end

-- ---------------------------------------------------------------------------
-- DialogAddDropdown - dropdown selector with optional global lock
-- ---------------------------------------------------------------------------

function addon:DialogAddDropdown(dialog, yOffset, label, options, currentValue, onChange, globalOption)
    label = addon:L(label)

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local hasGlobalOption = type(globalOption) == "table" and globalOption.enabled == true
    local isLocked = hasGlobalOption and currentValue == "_GLOBAL_"
    if hasGlobalOption and not isLocked then
        local globalValue = globalOption and globalOption.globalValue
        if globalValue ~= nil and currentValue ~= nil and tostring(globalValue) == tostring(currentValue) then
            isLocked = true
        end
    end

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(1, 1, 1)
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -11)
    labelText:SetText(label)
    row.label = labelText

    local lockButton

    local button = CreateFrame("Button", nil, row, "BackdropTemplate")
    button:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -27)
    button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -27)
    button:SetHeight(DROPDOWN_HEIGHT)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    button:SetBackdropColor(0, 0, 0, 0.65)
    button:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local selectedText = button:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(dialog._fontPath, 12, "OUTLINE")
    selectedText:SetTextColor(1, 1, 1)
    selectedText:SetPoint("LEFT", button, "LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", button, "RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetWordWrap(false)
    selectedText:SetMaxLines(1)

    local arrowIcon = button:CreateTexture(nil, "OVERLAY")
    arrowIcon:SetSize(12, 12)
    arrowIcon:SetAtlas(DROPDOWN_ARROW_ATLAS)
    arrowIcon:SetRotation(-math.pi / 2)
    arrowIcon:SetPoint("RIGHT", button, "RIGHT", -8, 0)

    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(400)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    menu:SetBackdropColor(0, 0, 0, 0.95)
    menu:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    menu:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -22, 4)
    scroll:EnableMouseWheel(true)

    local menuContent = CreateFrame("Frame", nil, scroll)
    menuContent:SetFrameLevel(menu:GetFrameLevel() + 2)
    menuContent:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    menuContent:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    menuContent:SetHeight(1)
    scroll:SetScrollChild(menuContent)

    local optionButtons = {}
    local selectedValue = currentValue or (options[1] and options[1].value) or ""
    local unlockedValue = selectedValue

    if isLocked then
        unlockedValue = globalOption and globalOption.globalValue
    end
    if unlockedValue == nil or unlockedValue == "" or unlockedValue == "_GLOBAL_" then
        unlockedValue = (options[1] and options[1].value) or ""
    end
    if isLocked then
        selectedValue = unlockedValue
    end

    local function GetOptionLabelByValue(value)
        for _, optionData in ipairs(options) do
            if optionData.value == value then
                return optionData.label and addon:L(optionData.label) or tostring(optionData.value or "")
            end
        end
        return tostring(value or "")
    end

    local function SetSelectedValue(value)
        selectedValue = value or ""
        local maxWidth = math.max(10, button:GetWidth() - 28)
        local selectedLabel = GetOptionLabelByValue(selectedValue)
        SetEllipsizedText(selectedText, selectedLabel, maxWidth)
    end

    local function RebuildOptions()
        for _, optionButton in ipairs(optionButtons) do
            optionButton:Hide()
        end

        for index, optionData in ipairs(options) do
            local optionButton = optionButtons[index]
            if not optionButton then
                optionButton = CreateFrame("Button", nil, menuContent, "BackdropTemplate")
                optionButton:SetFrameLevel(menu:GetFrameLevel() + 3)
                optionButton:SetHeight(DROPDOWN_ITEM_HEIGHT)
                optionButton:SetPoint("LEFT", menuContent, "LEFT", 0, 0)
                optionButton:SetPoint("RIGHT", menuContent, "RIGHT", 0, 0)
                optionButton:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                })

                local text = optionButton:CreateFontString(nil, "OVERLAY")
                text:SetFont(dialog._fontPath, 12, "OUTLINE")
                text:SetTextColor(1, 1, 1)
                text:SetPoint("LEFT", optionButton, "LEFT", 8, 0)
                text:SetPoint("RIGHT", optionButton, "RIGHT", -8, 0)
                text:SetJustifyH("LEFT")
                text:SetWordWrap(false)
                text:SetMaxLines(1)
                optionButton._text = text

                optionButton:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.2, 0.45, 0.35, 0.55)
                end)
                optionButton:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)

                optionButton:EnableMouseWheel(true)
                optionButton:SetScript("OnMouseWheel", function(_, delta)
                    addon:DialogScrollOpenDropdown(delta)
                end)

                optionButtons[index] = optionButton
            end

            optionButton:ClearAllPoints()
            optionButton:SetPoint("TOPLEFT", menuContent, "TOPLEFT", 0, -((index - 1) * DROPDOWN_ITEM_HEIGHT))
            optionButton:SetPoint("TOPRIGHT", menuContent, "TOPRIGHT", 0, -((index - 1) * DROPDOWN_ITEM_HEIGHT))
            local optionValue = optionData.value
            local optionLabel = optionData.label and addon:L(optionData.label) or tostring(optionValue or "")

            optionButton._value = optionValue
            local optionMaxWidth = math.max(10, optionButton:GetWidth() - 16)
            SetEllipsizedText(optionButton._text, optionLabel, optionMaxWidth)
            optionButton._text:Show()
            optionButton:SetScript("OnClick", function(self)
                SetSelectedValue(self._value)
                unlockedValue = self._value
                if onChange then
                    onChange(self._value)
                end
                menu:Hide()
            end)

            if optionValue == selectedValue then
                optionButton:SetBackdropColor(0.2, 0.45, 0.35, 0.35)
            else
                optionButton:SetBackdropColor(0, 0, 0, 0)
            end

            optionButton:Show()
        end

        menuContent:SetHeight(math.max(1, #options * DROPDOWN_ITEM_HEIGHT))
    end

    scroll:SetScript("OnMouseWheel", function(_, delta)
        addon:DialogScrollOpenDropdown(delta)
    end)

    menu:SetScript("OnHide", function(self)
        if activeDropdown and activeDropdown.menu == self then
            activeDropdown = nil
        end
    end)

    local function UpdateDropdownState()
        if lockButton then
            lockButton:ClearAllPoints()
            lockButton:SetPoint("LEFT", row, "LEFT", 0, 0)
        end

        local leftOffset = lockButton and (GLOBAL_LOCK_ICON_SIZE + CONTROL_PADDING) or 0

        if isLocked then
            labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            labelText:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
            labelText:SetText(label .. ": " .. addon:L("emGlobal"))
            if menu:IsShown() then
                menu:Hide()
            end
            button:Hide()
        else
            labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            labelText:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, -11)
            labelText:SetText(label)
            button:Show()
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, -27)
            button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -27)
            SetSelectedValue(unlockedValue)
        end
    end

    button:SetScript("OnClick", function()
        if isLocked then
            return
        end

        if menu:IsShown() then
            menu:Hide()
            return
        end

        HideactiveDropdown()

        local menuWidth = math.max(120, button:GetWidth())
        local visibleCount = math.min(#options, DROPDOWN_MENU_MAX_VISIBLE)
        local menuHeight = math.max(DROPDOWN_ITEM_HEIGHT, (visibleCount * DROPDOWN_ITEM_HEIGHT) + 8)

        menu:SetSize(menuWidth + 18, menuHeight)
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)

        menuContent:SetWidth(menuWidth)
        RebuildOptions()
        menu:Show()
        scroll:SetVerticalScroll(0)
        C_Timer.After(0, function()
            if menu:IsShown() then
                scroll:SetVerticalScroll(0)
            end
        end)

        activeDropdown = {
            menu = menu,
            scroll = scroll,
        }
    end)

    button:HookScript("OnSizeChanged", function()
        SetSelectedValue(selectedValue)
    end)

    SetSelectedValue(selectedValue)

    if hasGlobalOption then
        lockButton = CreateGlobalLockButton(row, isLocked, function(newLocked)
            isLocked = newLocked
            if isLocked then
                unlockedValue = selectedValue
                if onChange then
                    onChange("_GLOBAL_")
                end
            else
                SetSelectedValue(unlockedValue)
                if onChange then
                    onChange(unlockedValue)
                end
            end
            UpdateDropdownState()
        end)
        row.lockButton = lockButton
    end

    UpdateDropdownState()

    row:SetScript("OnHide", function()
        if menu:IsShown() then
            menu:Hide()
        end
    end)

    row.dropdown = button
    row.dropdownMenu = menu
    return row, yOffset - CONTROL_ROW_HEIGHT
end

-- ---------------------------------------------------------------------------
-- DialogAddSlider - slider with value display and optional global lock
-- ---------------------------------------------------------------------------

function addon:DialogAddSlider(dialog, yOffset, label, minVal, maxVal, currentValue, step, onChange, globalOption)
    label = addon:L(label)
    local hasGlobalOption = type(globalOption) == "table" and globalOption.enabled == true
    local isInitiallyLocked = hasGlobalOption and currentValue == "_GLOBAL_"
    if hasGlobalOption and not isInitiallyLocked then
        local globalValue = globalOption and globalOption.globalValue
        local numericGlobal = type(globalValue) == "number" and globalValue or tonumber(globalValue)
        local numericCurrent = type(currentValue) == "number" and currentValue or tonumber(currentValue)
        if type(numericGlobal) == "number" and type(numericCurrent) == "number" and numericGlobal == numericCurrent then
            isInitiallyLocked = true
        end
    end

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(1, 1, 1)
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -11)
    row.label = labelText

    local isLocked = isInitiallyLocked

    local numericValue = currentValue
    if type(numericValue) ~= "number" then
        numericValue = tonumber(numericValue)
    end
    if type(numericValue) ~= "number" then
        numericValue = minVal
    end

    if isLocked then
        local globalValue = globalOption and globalOption.globalValue
        if type(globalValue) ~= "number" then
            globalValue = tonumber(globalValue)
        end
        if type(globalValue) == "number" then
            numericValue = globalValue
        end
    end

    if numericValue < minVal then
        numericValue = minVal
    elseif numericValue > maxVal then
        numericValue = maxVal
    end

    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -27)
    slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -3, -27)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(numericValue)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)

    slider.Low:SetText("")
    slider.High:SetText("")
    slider.Text:SetText("")

    local unlockedValue = numericValue
    local suppressSliderCallback = false

    local function UpdateSliderState()
        local leftOffset = row.lockButton and (GLOBAL_LOCK_ICON_SIZE + CONTROL_PADDING) or 0

        if isLocked then
            labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            labelText:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
            labelText:SetText(label .. ": " .. addon:L("emGlobal"))
            slider:Hide()
        else
            labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            labelText:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, -11)
            local displayValue = math.floor(unlockedValue + 0.5)
            labelText:SetText(label .. ": " .. displayValue)
            suppressSliderCallback = true
            slider:SetValue(unlockedValue)
            suppressSliderCallback = false
            slider:ClearAllPoints()
            slider:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset + 3, -27)
            slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -3, -27)
            slider:Show()
        end
    end

    slider:SetScript("OnValueChanged", function(self, value)
        if suppressSliderCallback or isLocked then
            return
        end
        value = math.floor(value + 0.5)
        unlockedValue = value
        labelText:SetText(label .. ": " .. value)
        if onChange then
            onChange(value)
        end
    end)

    if hasGlobalOption then
        local lockBtn = CreateGlobalLockButton(row, isLocked, function(newLocked)
            isLocked = newLocked
            if isLocked then
                local currentSliderValue = slider:GetValue()
                unlockedValue = math.floor(currentSliderValue + 0.5)
                if onChange then
                    onChange("_GLOBAL_")
                end
            else
                if onChange then
                    onChange(unlockedValue)
                end
            end
            UpdateSliderState()
        end)
        lockBtn:ClearAllPoints()
        lockBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.lockButton = lockBtn
    end

    UpdateSliderState()

    row.slider = slider
    return row, yOffset - CONTROL_ROW_HEIGHT
end

-- ---------------------------------------------------------------------------
-- DialogAddTextInput - single-line text input
-- ---------------------------------------------------------------------------

function addon:DialogAddTextInput(dialog, yOffset, label, currentValue, onChange)
    label = addon:L(label)

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(1, 1, 1)
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -11)
    labelText:SetText(label)
    row.label = labelText

    local box = CreateFrame("EditBox", nil, row, "BackdropTemplate")
    box:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -27)
    box:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -27)
    box:SetHeight(DROPDOWN_HEIGHT)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    box:SetBackdropColor(0, 0, 0, 0.65)
    box:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    box:SetFont(dialog._fontPath, 12, "OUTLINE")
    box:SetTextColor(1, 1, 1)
    box:SetTextInsets(8, 8, 0, 0)
    box:SetAutoFocus(false)
    box:SetText(currentValue or "")
    box:SetCursorPosition(0)

    box:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        if onChange then
            onChange(self:GetText())
        end
    end)

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    box:SetScript("OnEscapePressed", function(self)
        self:SetText(currentValue or "")
        self:ClearFocus()
        if onChange then
            onChange(currentValue or "")
        end
    end)

    row.editBox = box
    return row, yOffset - CONTROL_ROW_HEIGHT
end

-- ---------------------------------------------------------------------------
-- DialogAddEnableControl - checkbox + action button (e.g. Reload UI)
--
-- options:
--   buttonText       string    Localization key for button label (default: "reloadUI")
--   buttonWidth      number    Button width (default 80)
--   onChange         function  Called when the checkbox value changes; receives (newValue).
--   onButtonClick    function  Called when the button is clicked; receives
--                              (currentChecked, originalChecked, row).
--                              If nil, defaults to calling ReloadUI().
-- ---------------------------------------------------------------------------

function addon:DialogAddEnableControl(dialog, yOffset, label, checked, options)
    label = addon:L(label)
    options = options or {}
    local buttonWidth = options.buttonWidth or 80
    local buttonHeight = 24

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT_HALF)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    row.checkbox = cb

    local text = row:CreateFontString(nil, "OVERLAY")
    text:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("LEFT", cb, "RIGHT", CONTROL_PADDING, 0)
    text:SetText(label)
    row.label = text

    local btnText = addon:L(options.buttonText or "reloadUI")
    local actionBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    actionBtn:SetSize(buttonWidth, buttonHeight)
    actionBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    actionBtn:SetText(btnText)
    actionBtn:GetFontString():SetFont(dialog._fontPath, CONTROL_BUTTON_FONT_SIZE, "OUTLINE")
    actionBtn:Disable()
    actionBtn:SetAlpha(0.5)
    row.actionButton = actionBtn

    local originalValue = checked

    local function UpdateActionButton(currentValue)
        if currentValue ~= originalValue then
            actionBtn:Enable()
            actionBtn:SetAlpha(1.0)
        else
            actionBtn:Disable()
            actionBtn:SetAlpha(0.5)
        end
    end

    cb:SetScript("OnClick", function(self)
        local newValue = self:GetChecked()
        if options.onChange then
            options.onChange(newValue)
        end
        UpdateActionButton(newValue)
    end)

    actionBtn:SetScript("OnClick", function()
        local currentValue = cb:GetChecked()
        if options.onButtonClick then
            options.onButtonClick(currentValue, originalValue, row)
        else
            ReloadUI()
        end
    end)

    return row, yOffset - CONTROL_ROW_HEIGHT_HALF
end

-- ---------------------------------------------------------------------------
-- DialogAddColorPicker - color swatch with optional global lock
-- ---------------------------------------------------------------------------

function addon:DialogAddColorPicker(dialog, yOffset, label, currentColor, onChange, globalOption)
    label = addon:L(label)
    local hasGlobalOption = type(globalOption) == "table" and globalOption.enabled == true
    local isLocked = hasGlobalOption and currentColor == "_GLOBAL_"
    if hasGlobalOption and not isLocked then
        local globalValue = globalOption and globalOption.globalValue
        if type(globalValue) == "string" and type(currentColor) == "string" then
            if globalValue:upper() == currentColor:upper() then
                isLocked = true
            end
        end
    end

    local unlockedColor = currentColor
    if isLocked then
        unlockedColor = globalOption and globalOption.globalValue
    end
    if type(unlockedColor) ~= "string" or unlockedColor == "" or unlockedColor == "_GLOBAL_" then
        unlockedColor = "FFFFFFFF"
    end

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT_HALF)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local lockButton

    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(COLOR_SWATCH_SIZE, COLOR_SWATCH_SIZE)
    swatch:SetPoint("LEFT", row, "LEFT", 0, 0)

    local swatchBg = swatch:CreateTexture(nil, "BACKGROUND")
    swatchBg:SetColorTexture(0.333, 0.333, 0.333, 1)
    swatchBg:SetAllPoints()

    local swatchColor = swatch:CreateTexture(nil, "ARTWORK")
    swatchColor:SetPoint("TOPLEFT", 2, -2)
    swatchColor:SetPoint("BOTTOMRIGHT", -2, 2)

    local r, g, b, a = ParseHexColor(unlockedColor)
    swatchColor:SetColorTexture(r, g, b, a)

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(1, 1, 1)
    labelText:SetPoint("LEFT", swatch, "RIGHT", CONTROL_PADDING + 3, 0)
    row.label = labelText

    local function UpdateColorState()
        if lockButton then
            lockButton:ClearAllPoints()
            lockButton:SetPoint("LEFT", row, "LEFT", 0, 0)
        end

        local leftOffset = lockButton and (GLOBAL_LOCK_ICON_SIZE + CONTROL_PADDING) or 0

        if isLocked then
            swatch:Hide()
            labelText:ClearAllPoints()
            labelText:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
            labelText:SetText(label .. ": " .. addon:L("emGlobal"))
        else
            local cr, cg, cb, ca = ParseHexColor(unlockedColor)
            swatchColor:SetColorTexture(cr, cg, cb, ca)
            swatch:Show()
            swatch:ClearAllPoints()
            swatch:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
            labelText:ClearAllPoints()
            labelText:SetPoint("LEFT", swatch, "RIGHT", CONTROL_PADDING + 3, 0)
            labelText:SetText(label)
        end
    end

    swatch:SetScript("OnClick", function()
        local preOpenColor = unlockedColor
        local openR, openG, openB, openA = ParseHexColor(unlockedColor)

        local pickerLevel = (dialog and dialog:GetFrameLevel() or 300) + 100
        if ColorPickerFrame then
            ColorPickerFrame:SetFrameStrata("TOOLTIP")
            ColorPickerFrame:SetFrameLevel(pickerLevel)
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = openR,
            g = openG,
            b = openB,
            opacity = openA,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                swatchColor:SetColorTexture(nr, ng, nb, na)

                local hex = string.format("%02x%02x%02x%02x",
                    math.floor(nr * 255 + 0.5),
                    math.floor(ng * 255 + 0.5),
                    math.floor(nb * 255 + 0.5),
                    math.floor(na * 255 + 0.5))

                unlockedColor = hex
                if onChange then
                    onChange(hex)
                end
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                swatchColor:SetColorTexture(nr, ng, nb, na)

                local hex = string.format("%02x%02x%02x%02x",
                    math.floor(nr * 255 + 0.5),
                    math.floor(ng * 255 + 0.5),
                    math.floor(nb * 255 + 0.5),
                    math.floor(na * 255 + 0.5))

                unlockedColor = hex
                if onChange then
                    onChange(hex)
                end
            end,
            cancelFunc = function()
                local cr, cg, cb, ca = ParseHexColor(preOpenColor)
                unlockedColor = preOpenColor
                swatchColor:SetColorTexture(cr, cg, cb, ca)
            end,
        })
    end)

    if hasGlobalOption then
        lockButton = CreateGlobalLockButton(row, isLocked, function(newLocked)
            isLocked = newLocked
            if isLocked then
                if onChange then
                    onChange("_GLOBAL_")
                end
            else
                if onChange then
                    onChange(unlockedColor)
                end
            end
            UpdateColorState()
        end)
        row.lockButton = lockButton
    end

    UpdateColorState()

    row.swatch = swatch
    return row, yOffset - CONTROL_ROW_HEIGHT_HALF
end

-- ---------------------------------------------------------------------------
-- DialogAddDescription - one or more paragraphs of descriptive text
--
-- keys    string|table  A single localization key (string) or a table of
--                       localization keys. Each key renders as a separate
--                       paragraph separated by a blank line.
-- align   string        Optional text alignment: "LEFT" (default),
--                       "CENTER", or "RIGHT".
-- ---------------------------------------------------------------------------

function addon:DialogAddDescription(dialog, yOffset, keys, align)
    align = align or "LEFT"
    local padLeft = GetDialogPadding(dialog)
    local contentWidth = dialog:GetWidth() - 2 * padLeft

    local text
    if type(keys) == "table" then
        local paragraphs = {}
        for _, key in ipairs(keys) do
            paragraphs[#paragraphs + 1] = self:L(key)
        end
        text = table.concat(paragraphs, "\n\n")
    else
        text = self:L(keys)
    end

    local desc = dialog:CreateFontString(nil, "OVERLAY")
    desc:SetFont(dialog._fontPath, BODY_FONT_SIZE, "OUTLINE")
    desc:SetTextColor(BODY_COLOR[1], BODY_COLOR[2], BODY_COLOR[3])
    desc:SetWidth(contentWidth)
    desc:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, yOffset - 15)
    desc:SetJustifyH(align)
    desc:SetWordWrap(true)
    desc:SetSpacing(3)
    desc:SetText(text)

    local textHeight = desc:GetStringHeight() or (BODY_FONT_SIZE * 2)
    return desc, yOffset - 15 - textHeight - CONTROL_PADDING - 15
end

-- ---------------------------------------------------------------------------
-- DialogAddHeader - section header with divider
-- ---------------------------------------------------------------------------

function addon:DialogAddHeader(dialog, yOffset, text)
    text = addon:L(text)
    local padLeft = GetDialogPadding(dialog)
    local header = dialog:CreateFontString(nil, "OVERLAY")
    header:SetFont(dialog._fontPath, HEADER_FONT_SIZE, "OUTLINE")
    header:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    header:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, yOffset)
    header:SetText(text)

    local dividerY = yOffset - HEADER_FONT_SIZE - 6
    local divider
    divider, dividerY = self:DialogAddDivider(dialog, dividerY)

    return header, divider, dividerY - HEADER_SPACING_AFTER
end

-- ---------------------------------------------------------------------------
-- DialogAddSubHeader - smaller section header with divider
-- ---------------------------------------------------------------------------

function addon:DialogAddSubHeader(dialog, yOffset, text)
    text = addon:L(text)
    local padLeft = GetDialogPadding(dialog)
    local header = dialog:CreateFontString(nil, "OVERLAY")
    header:SetFont(dialog._fontPath, SUBHEADER_FONT_SIZE, "OUTLINE")
    header:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    header:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, yOffset)
    header:SetText(text)

    local dividerY = yOffset - SUBHEADER_FONT_SIZE - 4
    local divider
    divider, dividerY = self:DialogAddDivider(dialog, dividerY)

    return header, divider, dividerY - SUBHEADER_SPACING_AFTER
end

-- ---------------------------------------------------------------------------
-- DialogAddSectionTitle - centered section/module title
-- ---------------------------------------------------------------------------

function addon:DialogAddSectionTitle(dialog, yOffset, text)
    text = addon:L(text)
    yOffset = yOffset - SECTION_TITLE_TOP_PADDING

    local title = dialog:CreateFontString(nil, "OVERLAY")
    title:SetFont(dialog._fontPath, SECTION_TITLE_FONT_SIZE, "OUTLINE")
    title:SetTextColor(SUBHEADER_COLOR[1], SUBHEADER_COLOR[2], SUBHEADER_COLOR[3])
    title:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    title:SetText(text)

    return title, yOffset - SECTION_TITLE_FONT_SIZE - SECTION_TITLE_BOTTOM_PADDING
end

-- ---------------------------------------------------------------------------
-- DialogAddSpacer - invisible spacing (matches section title height)
-- ---------------------------------------------------------------------------

function addon:DialogAddSpacer(dialog, yOffset)
    local spacer = CreateFrame("Frame", nil, dialog)
    spacer:SetHeight(SECTION_TITLE_TOP_PADDING + SECTION_TITLE_FONT_SIZE + SECTION_TITLE_BOTTOM_PADDING)
    spacer:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    return spacer, yOffset - (SECTION_TITLE_TOP_PADDING + SECTION_TITLE_FONT_SIZE + SECTION_TITLE_BOTTOM_PADDING)
end

-- ---------------------------------------------------------------------------
-- DialogAddButton - full-width button row
-- ---------------------------------------------------------------------------

function addon:DialogAddButton(dialog, yOffset, label, onClick)
    label = addon:L(label)
    local padLeft = GetDialogPadding(dialog)

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_ROW_HEIGHT)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btn:SetSize(row:GetWidth() or (dialog:GetWidth() - 2 * padLeft), CONTROL_BUTTON_HEIGHT)
    btn:SetPoint("LEFT", row, "LEFT", 0, 0)
    btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    btn:SetText(label)
    btn:GetFontString():SetFont(dialog._fontPath, CONTROL_BUTTON_FONT_SIZE, "OUTLINE")
    btn:SetScript("OnClick", onClick)

    row.button = btn
    return row, yOffset - CONTROL_ROW_HEIGHT
end

-- ---------------------------------------------------------------------------
-- DialogAddTextureButton - atlas texture button
--
--   dialog       parent dialog or column frame
--   yOffset      current vertical offset
--   options      table:
--     atlas        string    Atlas name for the texture
--     width        number    Button width (default 32)
--     height       number    Button height (default 32)
--     desaturate   boolean   Desaturate when not hovered (default false)
--     onClick      function  Click callback, receives (dialog)
--     parent       frame     Optional parent to anchor to instead of row
--     anchor       string    Anchor point on the button (default "CENTER")
--     attachTo     string    Point on parent to attach to (default "CENTER")
--     offsetX      number    Horizontal offset (default 0)
--     offsetY      number    Vertical offset (default 0)
-- ---------------------------------------------------------------------------

function addon:DialogAddTextureButton(dialog, yOffset, options)
    options = options or {}

    local btnWidth = options.width or 32
    local btnHeight = options.height or 32
    local desaturate = options.desaturate == true
    local anchorParent = options.parent
    local anchorPoint = options.anchor or "CENTER"
    local attachToPoint = options.attachTo or "CENTER"
    local offsetX = options.offsetX or 0
    local offsetY = options.offsetY or 0

    local row
    if not anchorParent then
        local padLeft = GetDialogPadding(dialog)
        row = CreateFrame("Frame", nil, dialog)
        row:SetHeight(CONTROL_ROW_HEIGHT)
        row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
        row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
        row:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    end

    local btn = CreateFrame("Button", nil, anchorParent or row)
    btn:SetSize(btnWidth, btnHeight)

    if anchorParent then
        btn:SetPoint(anchorPoint, anchorParent, attachToPoint, offsetX, offsetY)
    else
        btn:SetPoint("CENTER", row, "CENTER", 0, 0)
    end

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetAtlas(options.atlas)
    tex:SetDesaturated(desaturate)

    if desaturate then
        btn:SetScript("OnEnter", function()
            tex:SetDesaturated(false)
        end)
        btn:SetScript("OnLeave", function()
            tex:SetDesaturated(true)
        end)
    end

    if options.onClick then
        local dialogFrame = dialog
        if dialog._isDialogColumn then
            dialogFrame = dialog:GetParent()
        end
        btn:SetScript("OnClick", function()
            options.onClick(dialogFrame)
        end)
    end

    btn._texture = tex

    if row then
        row.button = btn
        return row, yOffset - CONTROL_ROW_HEIGHT
    end

    return btn, yOffset
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

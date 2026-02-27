local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local style = addon.DialogStyle or {}
addon.DialogStyle = style

local BORDER_WIDTH = style.BORDER_WIDTH or 8
local PADDING = style.PADDING or 30
local DIVIDER_HEIGHT = style.DIVIDER_HEIGHT or 2
local DIVIDER_COLOR = style.DIVIDER_COLOR or { 0, 0, 0, 1 }
local BODY_FONT_SIZE = style.BODY_FONT_SIZE or 13
local BODY_COLOR = style.BODY_COLOR or { 0.9, 0.9, 0.9 }

-- ===========================================================================
-- Dialog Controls
-- Standardized form controls for use with any Dialog frame.
-- All controls follow the yOffset accumulator pattern:
--   local row, yOffset = addon:DialogAdd*(dialog, yOffset, ...)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Control style constants
-- ---------------------------------------------------------------------------

local CONTROL_LAYOUT = {
    globalLockButton = {
        iconSize = 28,
        atlas = "GreatVault-32x32",
        lockedAlpha = 0.4,
    },
    divider = {
        paddingTop = 0,
        paddingBottom = 10,
    },
    toggleRow = {
        labelFontSize = 14,
        labelColor = { 1, 1, 1 },
        eyeVisibleAtlas = "GM-icon-visible",
        eyeVisibleColor = { 1, 0.82, 0, 1 },
        eyeHiddenAtlas = "GM-icon-visibleDis",
        eyeHiddenColor = { 1, 1, 1, 1 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    checkbox = {
        labelFontSize = 14,
        labelColor = { 1, 1, 1 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    dropdown = {
        itemHeight = 22,
        menuMaxVisible = 10,
        labelFontSize = 12,
        inputFontSize = 12,
        itemFontSize = 12,
        arrowAtlas = "CreditsScreen-Assets-Buttons-Play",
        arrowSize = 12,
        labelColor = { 1, 1, 1 },
        inputTextColor = { 1, 1, 1 },
        inputBgColor = { 0, 0, 0, 0.65 },
        inputBorderColor = { 0.2, 0.2, 0.2, 1 },
        menuBgColor = { 0, 0, 0, 0.95 },
        menuBorderColor = { 0.2, 0.2, 0.2, 1 },
        itemHoverColor = { 0.2, 0.45, 0.35, 0.55 },
        itemSelectedColor = { 0.2, 0.45, 0.35, 0.35 },
        itemDefaultColor = { 0, 0, 0, 0 },
        paddingTop = 0,
        paddingBottom = 15,
    },
    slider = {
        labelFontSize = 12,
        labelColor = { 1, 1, 1 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    textInput = {
        labelFontSize = 12,
        inputFontSize = 12,
        labelColor = { 1, 1, 1 },
        textColor = { 1, 1, 1 },
        inputBgColor = { 0, 0, 0, 0.65 },
        inputBorderColor = { 0.2, 0.2, 0.2, 1 },
        paddingTop = 5,
        paddingBottom = 20,
    },
    enableControl = {
        labelFontSize = 14,
        buttonFontSize = 13,
        labelColor = { 1, 1, 1 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    colorPicker = {
        swatchSize = 20,
        labelFontSize = 14,
        labelColor = { 1, 1, 1 },
        swatchBgColor = { 0.333, 0.333, 0.333, 1 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    description = {
        fontSize = BODY_FONT_SIZE,
        color = BODY_COLOR,
        paddingTop = 0,
        paddingBottom = 10,
    },
    header = {
        fontSize = 16,
        color = { 0, 1, 0.596 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    subHeader = {
        fontSize = 14,
        color = { 1, 0.82, 0 },
        paddingTop = 0,
        paddingBottom = 10,
    },
    sectionTitle = {
        fontSize = 16,
        color = { 1, 0.82, 0 },
        paddingTop = 5,
        paddingBottom = 15,
    },
    spacer = {
        paddingTop = 0,
        paddingBottom = 10,
    },
    button = {
        fontSize = 13,
        paddingTop = 0,
        paddingBottom = 10,
    },
    textureButton = {
        paddingTop = 0,
        paddingBottom = 10,
    },
}

local CONTROL_LABEL_FONT_SIZE = CONTROL_LAYOUT.toggleRow.labelFontSize
local CONTROL_SMALL_LABEL_FONT_SIZE = CONTROL_LAYOUT.dropdown.labelFontSize
local CONTROL_BUTTON_FONT_SIZE = CONTROL_LAYOUT.button.fontSize

local GLOBAL_LOCKED_ALPHA = CONTROL_LAYOUT.globalLockButton.lockedAlpha

local HEADER_FONT_SIZE = CONTROL_LAYOUT.header.fontSize
local HEADER_COLOR = CONTROL_LAYOUT.header.color
local SUBHEADER_FONT_SIZE = CONTROL_LAYOUT.subHeader.fontSize
local SUBHEADER_COLOR = CONTROL_LAYOUT.subHeader.color

local SECTION_TITLE_FONT_SIZE = CONTROL_LAYOUT.sectionTitle.fontSize

local DROPDOWN_ARROW_ATLAS = CONTROL_LAYOUT.dropdown.arrowAtlas

-- ---------------------------------------------------------------------------
-- Export control style constants
-- ---------------------------------------------------------------------------

addon.DialogStyle.CONTROL_LABEL_FONT_SIZE = CONTROL_LABEL_FONT_SIZE
addon.DialogStyle.CONTROL_SMALL_LABEL_FONT_SIZE = CONTROL_SMALL_LABEL_FONT_SIZE
addon.DialogStyle.CONTROL_BUTTON_FONT_SIZE = CONTROL_BUTTON_FONT_SIZE
addon.DialogStyle.HEADER_FONT_SIZE = HEADER_FONT_SIZE
addon.DialogStyle.HEADER_COLOR = HEADER_COLOR
addon.DialogStyle.SUBHEADER_FONT_SIZE = SUBHEADER_FONT_SIZE
addon.DialogStyle.SUBHEADER_COLOR = SUBHEADER_COLOR
addon.DialogStyle.SECTION_TITLE_FONT_SIZE = SECTION_TITLE_FONT_SIZE
addon.DialogStyle.CONTROL_LAYOUT = CONTROL_LAYOUT

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function GetDialogPadding(parent)
    if parent and parent._isDialogColumn then
        return 0
    end
    return BORDER_WIDTH + PADDING
end

local function GetControlVerticalPadding(controlKey)
    local controlCfg = CONTROL_LAYOUT[controlKey]
    if not controlCfg then
        return 0, 0
    end

    local top = type(controlCfg.paddingTop) == "number" and controlCfg.paddingTop or 0
    local bottom = type(controlCfg.paddingBottom) == "number" and controlCfg.paddingBottom or 0
    return top, bottom
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

local CONTROL_HORIZONTAL_GAP = 8
local LABEL_TO_CONTROL_GAP = 4
local COLOR_PICKER_LABEL_GAP = 11
local COLOR_PICKER_LEFT_INSET = 4
local SLIDER_HORIZONTAL_INSET = 3
local DROPDOWN_INPUT_HEIGHT = 32
local TEXT_INPUT_HEIGHT = 32
local TOGGLE_ROW_CONTROL_SIZE = 28
local CHECKBOX_CONTROL_SIZE = 28
local ENABLE_CONTROL_SIZE = 28
local COLOR_PICKER_ROW_HEIGHT = 28

-- ---------------------------------------------------------------------------
-- Global lock button builder
-- ---------------------------------------------------------------------------

local function CreateGlobalLockButton(row, isLocked, onToggle)
    local lockIconSize = CONTROL_LAYOUT.globalLockButton.iconSize

    local lockButton = CreateFrame("Button", nil, row)
    lockButton:SetSize(lockIconSize, lockIconSize)
    lockButton:SetPoint("LEFT", row, "LEFT", 0, 0)

    local icon = lockButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetAtlas(CONTROL_LAYOUT.globalLockButton.atlas, true)
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
    local dropdownItemHeight = CONTROL_LAYOUT.dropdown.itemHeight
    local nextValue = current - (delta * dropdownItemHeight)
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
    local paddingTop, paddingBottom = GetControlVerticalPadding("divider")
    local topY = yOffset - paddingTop

    local padLeft = GetDialogPadding(dialog)
    local divider = dialog:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(DIVIDER_HEIGHT)
    divider:SetColorTexture(DIVIDER_COLOR[1], DIVIDER_COLOR[2], DIVIDER_COLOR[3], DIVIDER_COLOR[4])
    divider:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    divider:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    divider:SetPoint("TOP", dialog, "TOP", 0, topY)
    return divider, topY - DIVIDER_HEIGHT - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddToggleRow - checkbox + visibility eye + label
-- ---------------------------------------------------------------------------

function addon:DialogAddToggleRow(dialog, yOffset, label, checked, visible, onCheckChanged, onVisibilityChanged)
    label = addon:L(label)
    local cfg = CONTROL_LAYOUT.toggleRow
    local visualControlSize = TOGGLE_ROW_CONTROL_SIZE
    local paddingTop, paddingBottom = GetControlVerticalPadding("toggleRow")
    local topY = yOffset - paddingTop
    local rowHeight = visualControlSize

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(visualControlSize, visualControlSize)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    cb:SetScript("OnClick", function(self)
        if onCheckChanged then
            onCheckChanged(self:GetChecked())
        end
    end)
    row.checkbox = cb

    local eye = CreateFrame("Button", nil, row)
    eye:SetSize(visualControlSize, visualControlSize)
    eye:SetPoint("LEFT", cb, "RIGHT", CONTROL_HORIZONTAL_GAP, 0)

    local eyeIcon = eye:CreateTexture(nil, "ARTWORK")
    eyeIcon:SetSize(visualControlSize, visualControlSize)
    eyeIcon:SetPoint("CENTER", eye, "CENTER", 0, 0)
    eye.icon = eyeIcon

    local function UpdateEyeIcon(isVisible)
        if isVisible then
            eyeIcon:SetAtlas(cfg.eyeVisibleAtlas)
            eyeIcon:SetVertexColor(unpack(cfg.eyeVisibleColor))
            eyeIcon:SetSize(visualControlSize + 2, visualControlSize + 2)
        else
            eyeIcon:SetAtlas(cfg.eyeHiddenAtlas)
            eyeIcon:SetVertexColor(unpack(cfg.eyeHiddenColor))
            eyeIcon:SetSize(visualControlSize, visualControlSize)
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
    text:SetTextColor(unpack(cfg.labelColor))
    text:SetPoint("LEFT", eye, "RIGHT", CONTROL_HORIZONTAL_GAP, 0)
    text:SetText(label)
    row.label = text

    return row, topY - rowHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddCheckbox - simple checkbox + label
-- ---------------------------------------------------------------------------

function addon:DialogAddCheckbox(dialog, yOffset, label, checked, onChange)
    label = addon:L(label)
    local cfg = CONTROL_LAYOUT.checkbox
    local controlSize = CHECKBOX_CONTROL_SIZE
    local paddingTop, paddingBottom = GetControlVerticalPadding("checkbox")
    local topY = yOffset - paddingTop
    local rowHeight = controlSize

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(controlSize, controlSize)
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
    text:SetTextColor(unpack(cfg.labelColor))
    text:SetPoint("LEFT", cb, "RIGHT", CONTROL_HORIZONTAL_GAP, 0)
    text:SetText(label)
    row.label = text

    return row, topY - rowHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddDropdown - dropdown selector with optional global lock
-- ---------------------------------------------------------------------------

function addon:DialogAddDropdown(dialog, yOffset, label, options, currentValue, onChange, globalOption)
    label = addon:L(label)
    local cfg = CONTROL_LAYOUT.dropdown
    local globalLockIconSize = CONTROL_LAYOUT.globalLockButton.iconSize
    local dropdownItemHeight = cfg.itemHeight
    local dropdownMenuMaxVisible = cfg.menuMaxVisible
    local dropdownHeight = DROPDOWN_INPUT_HEIGHT
    local inputTopOffset = 0
    local paddingTop, paddingBottom = GetControlVerticalPadding("dropdown")
    local topY = yOffset - paddingTop
    local rowHeight = 1

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

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
    labelText:SetTextColor(unpack(cfg.labelColor))
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    row.label = labelText

    local labelHeight = math.max(1, math.ceil(labelText:GetStringHeight() or cfg.labelFontSize))
    inputTopOffset = labelHeight + LABEL_TO_CONTROL_GAP
    rowHeight = inputTopOffset + dropdownHeight
    row:SetHeight(rowHeight)

    local lockButton

    local button = CreateFrame("Button", nil, row, "BackdropTemplate")
    button:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -inputTopOffset)
    button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -inputTopOffset)
    button:SetHeight(dropdownHeight)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    button:SetBackdropColor(unpack(cfg.inputBgColor))
    button:SetBackdropBorderColor(unpack(cfg.inputBorderColor))

    local selectedText = button:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(dialog._fontPath, cfg.inputFontSize, "OUTLINE")
    selectedText:SetTextColor(unpack(cfg.inputTextColor))
    selectedText:SetPoint("LEFT", button, "LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", button, "RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetWordWrap(false)
    selectedText:SetMaxLines(1)

    local arrowIcon = button:CreateTexture(nil, "OVERLAY")
    arrowIcon:SetSize(cfg.arrowSize, cfg.arrowSize)
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
    menu:SetBackdropColor(unpack(cfg.menuBgColor))
    menu:SetBackdropBorderColor(unpack(cfg.menuBorderColor))
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
                optionButton:SetHeight(dropdownItemHeight)
                optionButton:SetPoint("LEFT", menuContent, "LEFT", 0, 0)
                optionButton:SetPoint("RIGHT", menuContent, "RIGHT", 0, 0)
                optionButton:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                })

                local text = optionButton:CreateFontString(nil, "OVERLAY")
                text:SetFont(dialog._fontPath, cfg.itemFontSize, "OUTLINE")
                text:SetTextColor(unpack(cfg.inputTextColor))
                text:SetPoint("LEFT", optionButton, "LEFT", 8, 0)
                text:SetPoint("RIGHT", optionButton, "RIGHT", -8, 0)
                text:SetJustifyH("LEFT")
                text:SetWordWrap(false)
                text:SetMaxLines(1)
                optionButton._text = text

                optionButton:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(unpack(cfg.itemHoverColor))
                end)
                optionButton:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(unpack(cfg.itemDefaultColor))
                end)

                optionButton:EnableMouseWheel(true)
                optionButton:SetScript("OnMouseWheel", function(_, delta)
                    addon:DialogScrollOpenDropdown(delta)
                end)

                optionButtons[index] = optionButton
            end

            optionButton:ClearAllPoints()
            optionButton:SetPoint("TOPLEFT", menuContent, "TOPLEFT", 0, -((index - 1) * dropdownItemHeight))
            optionButton:SetPoint("TOPRIGHT", menuContent, "TOPRIGHT", 0, -((index - 1) * dropdownItemHeight))
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
                optionButton:SetBackdropColor(unpack(cfg.itemSelectedColor))
            else
                optionButton:SetBackdropColor(unpack(cfg.itemDefaultColor))
            end

            optionButton:Show()
        end

        menuContent:SetHeight(math.max(1, #options * dropdownItemHeight))
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

        local leftOffset = lockButton and (globalLockIconSize + CONTROL_HORIZONTAL_GAP) or 0

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
            labelText:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, 0)
            labelText:SetText(label)
            button:Show()
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, -inputTopOffset)
            button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -inputTopOffset)
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
        local visibleCount = math.min(#options, dropdownMenuMaxVisible)
        local menuHeight = math.max(dropdownItemHeight, (visibleCount * dropdownItemHeight) + 8)

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
    return row, topY - rowHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddSlider - slider with value display and optional global lock
-- ---------------------------------------------------------------------------

function addon:DialogAddSlider(dialog, yOffset, label, minVal, maxVal, currentValue, step, onChange, globalOption)
    label = addon:L(label)
    local cfg = CONTROL_LAYOUT.slider
    local globalLockIconSize = CONTROL_LAYOUT.globalLockButton.iconSize
    local sliderHeight = 0
    local sliderTopOffset = 0
    local paddingTop, paddingBottom = GetControlVerticalPadding("slider")
    local topY = yOffset - paddingTop
    local rowHeight = 1

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
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(unpack(cfg.labelColor))
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    row.label = labelText

    local labelHeight = math.max(1, math.ceil(labelText:GetStringHeight() or cfg.labelFontSize))
    sliderTopOffset = labelHeight + LABEL_TO_CONTROL_GAP

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
    slider:SetPoint("TOPLEFT", row, "TOPLEFT", SLIDER_HORIZONTAL_INSET, -sliderTopOffset)
    slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -SLIDER_HORIZONTAL_INSET, -sliderTopOffset)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(numericValue)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)

    slider.Low:SetText("")
    slider.High:SetText("")
    slider.Text:SetText("")

    sliderHeight = math.max(1, math.ceil(slider:GetHeight() or 0))
    if sliderHeight <= 1 then
        sliderHeight = 16
    end
    rowHeight = sliderTopOffset + sliderHeight
    row:SetHeight(rowHeight)

    local unlockedValue = numericValue
    local suppressSliderCallback = false

    local function UpdateSliderState()
        local leftOffset = row.lockButton and (globalLockIconSize + CONTROL_HORIZONTAL_GAP) or 0

        if isLocked then
            labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            labelText:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
            labelText:SetText(label .. ": " .. addon:L("emGlobal"))
            slider:Hide()
        else
            labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            labelText:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, 0)
            local displayValue = math.floor(unlockedValue + 0.5)
            labelText:SetText(label .. ": " .. displayValue)
            suppressSliderCallback = true
            slider:SetValue(unlockedValue)
            suppressSliderCallback = false
            slider:ClearAllPoints()
            slider:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset + SLIDER_HORIZONTAL_INSET, -sliderTopOffset)
            slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -SLIDER_HORIZONTAL_INSET, -sliderTopOffset)
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
    return row, topY - rowHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddTextInput - single-line text input
-- ---------------------------------------------------------------------------

function addon:DialogAddTextInput(dialog, yOffset, label, currentValue, onChange)
    label = addon:L(label)
    local cfg = CONTROL_LAYOUT.textInput
    local dropdownHeight = TEXT_INPUT_HEIGHT
    local inputTopOffset = 0
    local paddingTop, paddingBottom = GetControlVerticalPadding("textInput")
    local topY = yOffset - paddingTop
    local rowHeight = 1

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(unpack(cfg.labelColor))
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    row.label = labelText

    local labelHeight = math.max(1, math.ceil(labelText:GetStringHeight() or cfg.labelFontSize))
    inputTopOffset = labelHeight + LABEL_TO_CONTROL_GAP
    rowHeight = inputTopOffset + dropdownHeight
    row:SetHeight(rowHeight)

    local box = CreateFrame("EditBox", nil, row, "BackdropTemplate")
    box:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -inputTopOffset)
    box:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -inputTopOffset)
    box:SetHeight(dropdownHeight)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    box:SetBackdropColor(unpack(cfg.inputBgColor))
    box:SetBackdropBorderColor(unpack(cfg.inputBorderColor))
    box:SetFont(dialog._fontPath, cfg.inputFontSize, "OUTLINE")
    box:SetTextColor(unpack(cfg.textColor))
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
    return row, topY - rowHeight - paddingBottom
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
    local cfg = CONTROL_LAYOUT.enableControl
    local controlSize = ENABLE_CONTROL_SIZE
    local paddingTop, paddingBottom = GetControlVerticalPadding("enableControl")
    local topY = yOffset - paddingTop
    local rowHeight = controlSize

    local buttonWidth = options.buttonWidth or 80
    local buttonHeight = 24

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(controlSize, controlSize)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    row.checkbox = cb

    local text = row:CreateFontString(nil, "OVERLAY")
    text:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    text:SetTextColor(unpack(cfg.labelColor))
    text:SetPoint("LEFT", cb, "RIGHT", CONTROL_HORIZONTAL_GAP, 0)
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

    return row, topY - rowHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddColorPicker - color swatch with optional global lock
-- ---------------------------------------------------------------------------

function addon:DialogAddColorPicker(dialog, yOffset, label, currentColor, onChange, globalOption)
    label = addon:L(label)
    local cfg = CONTROL_LAYOUT.colorPicker
    local controlSize = COLOR_PICKER_ROW_HEIGHT
    local globalLockIconSize = CONTROL_LAYOUT.globalLockButton.iconSize
    local colorSwatchSize = cfg.swatchSize
    local paddingTop, paddingBottom = GetControlVerticalPadding("colorPicker")
    local topY = yOffset - paddingTop
    local rowHeight = controlSize

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
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local lockButton

    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(colorSwatchSize, colorSwatchSize)
    swatch:SetPoint("LEFT", row, "LEFT", COLOR_PICKER_LEFT_INSET, 0)

    local swatchBg = swatch:CreateTexture(nil, "BACKGROUND")
    swatchBg:SetColorTexture(unpack(cfg.swatchBgColor))
    swatchBg:SetAllPoints()

    local swatchColor = swatch:CreateTexture(nil, "ARTWORK")
    swatchColor:SetPoint("TOPLEFT", 2, -2)
    swatchColor:SetPoint("BOTTOMRIGHT", -2, 2)

    local r, g, b, a = ParseHexColor(unlockedColor)
    swatchColor:SetColorTexture(r, g, b, a)

    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(unpack(cfg.labelColor))
    labelText:SetPoint("LEFT", swatch, "RIGHT", COLOR_PICKER_LABEL_GAP, 0)
    row.label = labelText

    local function UpdateColorState()
        if lockButton then
            lockButton:ClearAllPoints()
            lockButton:SetPoint("LEFT", row, "LEFT", 0, 0)
        end

        local leftOffset = lockButton and (globalLockIconSize + CONTROL_HORIZONTAL_GAP) or 0

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
            swatch:SetPoint("LEFT", row, "LEFT", leftOffset + COLOR_PICKER_LEFT_INSET, 0)
            labelText:ClearAllPoints()
            labelText:SetPoint("LEFT", swatch, "RIGHT", COLOR_PICKER_LABEL_GAP, 0)
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
    return row, topY - rowHeight - paddingBottom
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
    local paddingTop, paddingBottom = GetControlVerticalPadding("description")
    local topY = yOffset - paddingTop

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
    desc:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, topY)
    desc:SetJustifyH(align)
    desc:SetWordWrap(true)
    desc:SetSpacing(3)
    desc:SetText(text)

    local textHeight = desc:GetStringHeight() or (BODY_FONT_SIZE * 2)
    return desc, topY - textHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddHeader - section header with divider
-- ---------------------------------------------------------------------------

function addon:DialogAddHeader(dialog, yOffset, text)
    text = addon:L(text)
    local paddingTop, paddingBottom = GetControlVerticalPadding("header")
    local topY = yOffset - paddingTop

    local padLeft = GetDialogPadding(dialog)
    local header = dialog:CreateFontString(nil, "OVERLAY")
    header:SetFont(dialog._fontPath, HEADER_FONT_SIZE, "OUTLINE")
    header:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    header:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, topY)
    header:SetText(text)

    local dividerY = topY - HEADER_FONT_SIZE
    local divider
    divider, dividerY = self:DialogAddDivider(dialog, dividerY)

    return header, divider, dividerY - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddSubHeader - smaller section header with divider
-- ---------------------------------------------------------------------------

function addon:DialogAddSubHeader(dialog, yOffset, text)
    text = addon:L(text)
    local paddingTop, paddingBottom = GetControlVerticalPadding("subHeader")
    local topY = yOffset - paddingTop

    local padLeft = GetDialogPadding(dialog)
    local header = dialog:CreateFontString(nil, "OVERLAY")
    header:SetFont(dialog._fontPath, SUBHEADER_FONT_SIZE, "OUTLINE")
    header:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    header:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, topY)
    header:SetText(text)

    local dividerY = topY - SUBHEADER_FONT_SIZE
    local divider
    divider, dividerY = self:DialogAddDivider(dialog, dividerY)

    return header, divider, dividerY - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddSectionTitle - centered section/module title
-- ---------------------------------------------------------------------------

function addon:DialogAddSectionTitle(dialog, yOffset, text)
    text = addon:L(text)
    local paddingTop, paddingBottom = GetControlVerticalPadding("sectionTitle")
    local titleY = yOffset - paddingTop

    local title = dialog:CreateFontString(nil, "OVERLAY")
    title:SetFont(dialog._fontPath, SECTION_TITLE_FONT_SIZE, "OUTLINE")
    title:SetTextColor(SUBHEADER_COLOR[1], SUBHEADER_COLOR[2], SUBHEADER_COLOR[3])
    title:SetPoint("TOP", dialog, "TOP", 0, titleY)
    title:SetText(text)

    return title, titleY - SECTION_TITLE_FONT_SIZE - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddSpacer - invisible spacing (matches section title height)
-- ---------------------------------------------------------------------------

function addon:DialogAddSpacer(dialog, yOffset)
    local paddingTop, paddingBottom = GetControlVerticalPadding("spacer")
    local topY = yOffset - paddingTop
    local spacerHeight = 0

    local spacer = CreateFrame("Frame", nil, dialog)
    spacer:SetHeight(spacerHeight)
    spacer:SetPoint("TOP", dialog, "TOP", 0, topY)

    return spacer, topY - spacerHeight - paddingBottom
end

-- ---------------------------------------------------------------------------
-- DialogAddButton - full-width button row
-- ---------------------------------------------------------------------------

function addon:DialogAddButton(dialog, yOffset, label, onClick)
    label = addon:L(label)
    local buttonHeight = 28
    local paddingTop, paddingBottom = GetControlVerticalPadding("button")
    local topY = yOffset - paddingTop
    local rowHeight = buttonHeight

    local padLeft = GetDialogPadding(dialog)

    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, topY)

    local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btn:SetSize(row:GetWidth() or (dialog:GetWidth() - 2 * padLeft), buttonHeight)
    btn:SetPoint("LEFT", row, "LEFT", 0, 0)
    btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    btn:SetText(label)
    btn:GetFontString():SetFont(dialog._fontPath, CONTROL_BUTTON_FONT_SIZE, "OUTLINE")
    btn:SetScript("OnClick", onClick)

    row.button = btn
    return row, topY - rowHeight - paddingBottom
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
--     relativeTo   frame     Optional frame to anchor against (defaults to parent)
--     anchor       string    Anchor point on the button (default "CENTER")
--     attachTo     string    Point on parent to attach to (default "CENTER")
--     offsetX      number    Horizontal offset (default 0)
--     offsetY      number    Vertical offset (default 0)
-- ---------------------------------------------------------------------------

function addon:DialogAddTextureButton(dialog, yOffset, options)
    options = options or {}
    local paddingTop, paddingBottom = GetControlVerticalPadding("textureButton")
    local topY = yOffset - paddingTop

    local btnWidth = options.width or 32
    local btnHeight = options.height or 32
    local rowHeight = btnHeight
    local desaturate = options.desaturate == true
    local anchorParent = options.parent
    local relativeTo = options.relativeTo
    local anchorPoint = options.anchor or "CENTER"
    local attachToPoint = options.attachTo or "CENTER"
    local offsetX = options.offsetX or 0
    local offsetY = options.offsetY or 0

    local row
    if not anchorParent then
        local padLeft = GetDialogPadding(dialog)
        row = CreateFrame("Frame", nil, dialog)
        row:SetHeight(rowHeight)
        row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
        row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
        row:SetPoint("TOP", dialog, "TOP", 0, topY)
    end

    local btn = CreateFrame("Button", nil, anchorParent or row)
    btn:SetSize(btnWidth, btnHeight)

    if anchorParent then
        btn:SetPoint(anchorPoint, relativeTo or anchorParent, attachToPoint, offsetX, offsetY)
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
        return row, topY - rowHeight - paddingBottom
    end

    return btn, yOffset
end

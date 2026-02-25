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

-- ---------------------------------------------------------------------------
-- Control style constants - modify these to change all controls at once
-- ---------------------------------------------------------------------------

-- Common sizing
local CONTROL_PADDING = 8              -- Horizontal padding between control elements (checkbox to label, etc)
local CONTROL_SIZE = 28                -- Size for checkboxes and color swatches
local CONTROL_BASE_HEIGHT = 32         -- Base row height for single-line controls (checkbox, color picker)
local CONTROL_TALL_HEIGHT = 50         -- Row height for controls with labels above (dropdown, slider)
local CONTROL_TALL_SPACING_AFTER = 10   -- Extra spacing after tall controls (dropdown, slider)

-- Font sizes
local CONTROL_LABEL_FONT_SIZE = 14     -- Font size for control labels (checkboxes, visibility toggles)
local CONTROL_SMALL_LABEL_FONT_SIZE = 12  -- Smaller font for dropdown/slider labels
local BUTTON_FONT_SIZE = 13            -- Font size for buttons

local GLOBAL_LOCK_ICON_SIZE = 28
local GLOBAL_LOCKED_ALPHA = 0.4

-- Header styling
local HEADER_FONT_SIZE = 16            -- Main section headers
local HEADER_COLOR = { 0, 1, 0.596 }   -- Green header color
local HEADER_SPACING_AFTER = 8         -- Space after header divider
local SUBHEADER_FONT_SIZE = 14         -- Sub-section headers  
local SUBHEADER_SPACING_AFTER = 6      -- Space after sub-header divider

-- ---------------------------------------------------------------------------
-- CreateDialog - reusable draggable dialog builder
-- ---------------------------------------------------------------------------

function addon:CreateDialog(name, titleText, width)
    width = width or 300

    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, 100)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetClampedToScreen(false)

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

    local fontPath = addon:FetchFont("DorisPP")

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, TITLE_FONT_SIZE, "OUTLINE")
    title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    title:SetPoint("TOP", frame, "TOP", 0, -(BORDER_WIDTH + PADDING))
    title:SetText(titleText)
    frame.title = title

    frame._contentTop = -(BORDER_WIDTH + PADDING + TITLE_FONT_SIZE + 10)
    frame._padding = PADDING
    frame._borderWidth = BORDER_WIDTH
    frame._fontPath = fontPath

    frame:Hide()
    return frame
end

-- ---------------------------------------------------------------------------
-- Helper: Get correct horizontal padding for dialog parent
-- When control is added to a column frame, use 0 padding (column handles spacing)
-- When added to main dialog, use BORDER_WIDTH + PADDING
-- ---------------------------------------------------------------------------
local function GetDialogPadding(parent)
    if parent and parent._isDialogColumn then
        return 0
    end
    return BORDER_WIDTH + PADDING
end

-- ---------------------------------------------------------------------------
-- AddDivider - horizontal divider line
-- ---------------------------------------------------------------------------

function addon:DialogAddDivider(dialog, yOffset)
    local divider = dialog:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(DIVIDER_HEIGHT)
    divider:SetColorTexture(DIVIDER_COLOR[1], DIVIDER_COLOR[2], DIVIDER_COLOR[3], DIVIDER_COLOR[4])
    divider:SetPoint("LEFT", dialog, "LEFT", BORDER_WIDTH + PADDING, 0)
    divider:SetPoint("RIGHT", dialog, "RIGHT", -(BORDER_WIDTH + PADDING), 0)
    divider:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    return divider, yOffset - DIVIDER_HEIGHT
end

-- ---------------------------------------------------------------------------
-- AddToggleRow - checkbox + visibility eye + label (Visibility Control)
-- ---------------------------------------------------------------------------

function addon:DialogAddToggleRow(dialog, yOffset, label, checked, visible, onCheckChanged, onVisibilityChanged)
    local rowHeight = CONTROL_BASE_HEIGHT + 4  -- Slightly taller for better visual spacing
    
    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
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
    eyeIcon:SetAllPoints()
    eye.icon = eyeIcon

    local function UpdateEyeIcon(isVisible)
        if isVisible then
            eyeIcon:SetAtlas("GM-icon-visible")
        else
            eyeIcon:SetAtlas("GM-icon-visibleDis")
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

    return row, yOffset - rowHeight
end

-- ---------------------------------------------------------------------------
-- AddDropdown - dropdown selector (Dropdown Control)
-- ---------------------------------------------------------------------------

local DROPDOWN_HEIGHT = 32
local DROPDOWN_ITEM_HEIGHT = 22
local DROPDOWN_MENU_MAX_VISIBLE = 10
local DROPDOWN_ARROW_ATLAS = "CreditsScreen-Assets-Buttons-Play"
local DROPDOWN_EXTRA_BOTTOM_PADDING = 4

local CreateGlobalLockButton

local activeDialogDropdown

local function HideActiveDialogDropdown()
    if activeDialogDropdown and activeDialogDropdown.menu and activeDialogDropdown.menu:IsShown() then
        activeDialogDropdown.menu:Hide()
    end
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

function addon:DialogHasOpenDropdown()
    return activeDialogDropdown and activeDialogDropdown.menu and activeDialogDropdown.menu:IsShown() or false
end

function addon:DialogScrollOpenDropdown(delta)
    if not self:DialogHasOpenDropdown() then
        return false
    end

    local dropdown = activeDialogDropdown
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

function addon:DialogAddDropdown(dialog, yOffset, label, options, currentValue, onChange, globalOption)
    yOffset = yOffset - (CONTROL_TALL_SPACING_AFTER / 2)  -- Apply half spacing before control
    
    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_TALL_HEIGHT)
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

    -- Label
    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(1, 1, 1)
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    row.label = labelText

    local lockButton

    local button = CreateFrame("Button", nil, row, "BackdropTemplate")
    button:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
    button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -4)
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
                return optionData.label or tostring(optionData.value or "")
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
            local optionLabel = optionData.label or tostring(optionValue or "")

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
        if activeDialogDropdown and activeDialogDropdown.menu == self then
            activeDialogDropdown = nil
        end
    end)

    local function UpdateDropdownState()
        if lockButton then
            lockButton:ClearAllPoints()
            lockButton:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
        end

        if isLocked then
            labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            if lockButton then
                labelText:SetPoint("LEFT", lockButton, "RIGHT", CONTROL_PADDING + 1, 0)
            else
                labelText:SetPoint("LEFT", row, "LEFT", 0, 0)
            end
            labelText:SetText(label .. ": Global")
            if menu:IsShown() then
                menu:Hide()
            end
            button:Hide()
        else
            labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            if lockButton then
                labelText:SetPoint("TOPLEFT", lockButton, "TOPRIGHT", CONTROL_PADDING, 5)
            else
                labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            end
            labelText:SetText(label)
            button:Show()
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
            button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -4)
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

        HideActiveDialogDropdown()

        local width = math.max(120, button:GetWidth())
        local visibleCount = math.min(#options, DROPDOWN_MENU_MAX_VISIBLE)
        local menuHeight = math.max(DROPDOWN_ITEM_HEIGHT, (visibleCount * DROPDOWN_ITEM_HEIGHT) + 8)

        menu:SetSize(width + 18, menuHeight)
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)

        menuContent:SetWidth(width)
        RebuildOptions()
        menu:Show()
        scroll:SetVerticalScroll(0)
        C_Timer.After(0, function()
            if menu:IsShown() then
                scroll:SetVerticalScroll(0)
            end
        end)

        activeDialogDropdown = {
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
    return row, yOffset - CONTROL_TALL_HEIGHT - (CONTROL_TALL_SPACING_AFTER / 2) - DROPDOWN_EXTRA_BOTTOM_PADDING
end

-- ---------------------------------------------------------------------------
-- AddSlider - slider with value display (Slider Control)
-- ---------------------------------------------------------------------------

local SLIDER_HEIGHT = 16
local SLIDER_BOTTOM_PADDING_REDUCTION = 3

CreateGlobalLockButton = function(row, isLocked, onToggle)
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

function addon:DialogAddSlider(dialog, yOffset, label, minVal, maxVal, currentValue, step, onChange, globalOption)
    yOffset = yOffset - (CONTROL_TALL_SPACING_AFTER / 2)  -- Apply half spacing before control
    
    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(CONTROL_TALL_HEIGHT)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    -- Label with current value
    local labelText = row:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
    labelText:SetTextColor(1, 1, 1)
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.label = labelText

    local hasGlobalOption = type(globalOption) == "table" and globalOption.enabled == true
    local isLocked = hasGlobalOption and currentValue == "_GLOBAL_"
    if hasGlobalOption and not isLocked then
        local globalValue = globalOption and globalOption.globalValue
        local numericGlobal = type(globalValue) == "number" and globalValue or tonumber(globalValue)
        local numericCurrent = type(currentValue) == "number" and currentValue or tonumber(currentValue)
        if type(numericGlobal) == "number" and type(numericCurrent) == "number" and numericGlobal == numericCurrent then
            isLocked = true
        end
    end

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

    -- Slider
    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 3, -8)
    slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -3, -20)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(numericValue)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    
    -- Remove default labels
    slider.Low:SetText("")
    slider.High:SetText("")
    slider.Text:SetText("")

    local unlockedValue = numericValue
    local suppressSliderCallback = false

    local function UpdateSliderState()
        if isLocked then
            labelText:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
            if row.lockButton then
                labelText:ClearAllPoints()
                labelText:SetPoint("LEFT", row.lockButton, "RIGHT", CONTROL_PADDING + 1, 0)
            else
                labelText:ClearAllPoints()
                labelText:SetPoint("LEFT", row, "LEFT", 0, 0)
            end
            labelText:SetText(label .. ": Global")
            slider:Hide()
        else
            labelText:SetFont(dialog._fontPath, CONTROL_SMALL_LABEL_FONT_SIZE, "OUTLINE")
            labelText:ClearAllPoints()
            if row.lockButton then
                labelText:SetPoint("TOPLEFT", row.lockButton, "TOPRIGHT", CONTROL_PADDING, 0)
            else
                labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            end
            local displayValue = math.floor(unlockedValue + 0.5)
            labelText:SetText(label .. ": " .. displayValue)
            suppressSliderCallback = true
            slider:SetValue(unlockedValue)
            suppressSliderCallback = false
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
        local lockButton = CreateGlobalLockButton(row, isLocked, function(newLocked)
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
        lockButton:ClearAllPoints()
        lockButton:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
        labelText:ClearAllPoints()
        labelText:SetPoint("TOPLEFT", lockButton, "TOPRIGHT", CONTROL_PADDING, 0)
        slider:ClearAllPoints()
        slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 3, -8)
        slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -3, -20)
        row.lockButton = lockButton
    end

    UpdateSliderState()
    
    row.slider = slider
    return row, yOffset - CONTROL_TALL_HEIGHT - (CONTROL_TALL_SPACING_AFTER / 2) + SLIDER_BOTTOM_PADDING_REDUCTION
end

-- ---------------------------------------------------------------------------
-- AddCheckbox - simple checkbox (Checkbox Control)
-- ---------------------------------------------------------------------------

function addon:DialogAddCheckbox(dialog, yOffset, label, checked, onChange)
    local rowHeight = CONTROL_BASE_HEIGHT + 4  -- Match visibility control spacing
    local spacingAfter = CONTROL_TALL_SPACING_AFTER / 2  -- Match EnableControl spacing
    
    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
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

    return row, yOffset - rowHeight - spacingAfter
end

-- ---------------------------------------------------------------------------
-- AddEnableControl - checkbox + "Reload UI" button (Enable Control)
-- ---------------------------------------------------------------------------

local ShowEditModeConfirmDialog

function addon:DialogAddEnableControl(dialog, yOffset, label, checked, configKey, moduleKey, onChange)
    local rowHeight = CONTROL_BASE_HEIGHT + 4  -- Match visibility control spacing
    local buttonWidth = 80
    local buttonHeight = 24
    local spacingAfter = CONTROL_TALL_SPACING_AFTER / 2
    
    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(rowHeight)
    local padLeft = GetDialogPadding(dialog)
    row:SetPoint("LEFT", dialog, "LEFT", padLeft, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -padLeft, 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    -- Checkbox on the left
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(CONTROL_SIZE, CONTROL_SIZE)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    row.checkbox = cb

    -- Label text
    local text = row:CreateFontString(nil, "OVERLAY")
    text:SetFont(dialog._fontPath, CONTROL_LABEL_FONT_SIZE, "OUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("LEFT", cb, "RIGHT", CONTROL_PADDING, 0)
    text:SetText(label)
    row.label = text

    -- Reload UI button (right-aligned)
    local reloadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reloadBtn:SetSize(buttonWidth, buttonHeight)
    reloadBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    reloadBtn:SetText("Reload UI")
    reloadBtn:GetFontString():SetFont(dialog._fontPath, BUTTON_FONT_SIZE, "OUTLINE")
    reloadBtn:Disable()
    reloadBtn:SetAlpha(0.5)
    row.reloadButton = reloadBtn

    -- Track original value
    local originalValue = checked

    -- Update reload button state
    local function UpdateReloadButton(currentValue)
        if currentValue ~= originalValue then
            reloadBtn:Enable()
            reloadBtn:SetAlpha(1.0)
        else
            reloadBtn:Disable()
            reloadBtn:SetAlpha(0.5)
        end
    end

    -- Checkbox click handler
    cb:SetScript("OnClick", function(self)
        local newValue = self:GetChecked()
        if onChange then
            onChange(newValue)
        end
        UpdateReloadButton(newValue)
    end)

    -- Reload button click handler
    reloadBtn:SetScript("OnClick", function()
        local function ReloadForPendingChange()
            addon:SetPendingSubDialogReopen(configKey, moduleKey)
            if addon.savedVars and addon.savedVars.data then
                addon.savedVars.data.resumeEditModeAfterReload = true
            end
            ReloadUI()
        end

        local currentValue = cb:GetChecked()
        local isDisabling = originalValue == true and currentValue == false

        if isDisabling and ShowEditModeConfirmDialog then
            ShowEditModeConfirmDialog({
                title = addon:L("reloadUI"),
                message = addon:L("disableModuleConfirmText"),
                confirmText = addon:L("reloadUI"),
                onConfirm = ReloadForPendingChange,
                onCancel = function()
                    cb:SetChecked(originalValue)
                    if onChange then
                        onChange(originalValue)
                    end
                    UpdateReloadButton(originalValue)
                end,
            })
            return
        end

        ReloadForPendingChange()
    end)

    return row, yOffset - rowHeight - spacingAfter
end

-- ---------------------------------------------------------------------------
-- AddColorPicker - color picker button (Color Picker Control)
-- ---------------------------------------------------------------------------

local COLOR_SWATCH_SIZE = 20  -- Smaller than checkbox/control size

function addon:DialogAddColorPicker(dialog, yOffset, label, currentColor, onChange, globalOption)
    yOffset = yOffset - 5
    local rowHeight = CONTROL_BASE_HEIGHT + 4  -- Match visibility control spacing

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
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local lockButton

    -- Color swatch button (on left, like checkbox)
    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(COLOR_SWATCH_SIZE, COLOR_SWATCH_SIZE)
    swatch:SetPoint("LEFT", row, "LEFT", 0, 0)

    local swatchBg = swatch:CreateTexture(nil, "BACKGROUND")
    swatchBg:SetColorTexture(0.333, 0.333, 0.333, 1)  -- #555555 gray border
    swatchBg:SetAllPoints()

    local swatchColor = swatch:CreateTexture(nil, "ARTWORK")
    swatchColor:SetPoint("TOPLEFT", 2, -2)
    swatchColor:SetPoint("BOTTOMRIGHT", -2, 2)
    
    -- Parse hex color
    local function ParseHexColor(hex)
        if not hex or hex == "" then return 1, 1, 1, 1 end
        local r = tonumber(hex:sub(1, 2), 16) or 255
        local g = tonumber(hex:sub(3, 4), 16) or 255
        local b = tonumber(hex:sub(5, 6), 16) or 255
        local a = tonumber(hex:sub(7, 8), 16) or 255
        return r/255, g/255, b/255, a/255
    end
    
    local r, g, b, a = ParseHexColor(unlockedColor)
    swatchColor:SetColorTexture(r, g, b, a)

    -- Label (to the right of swatch, like checkbox layout)
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

        if isLocked then
            swatch:Hide()
            labelText:ClearAllPoints()
            if lockButton then
                labelText:SetPoint("LEFT", lockButton, "RIGHT", CONTROL_PADDING + 1, 0)
            else
                labelText:SetPoint("LEFT", row, "LEFT", 0, 0)
            end
            labelText:SetText(label .. ": Global")
        else
            local cr, cg, cb, ca = ParseHexColor(unlockedColor)
            swatchColor:SetColorTexture(cr, cg, cb, ca)
            swatch:Show()
            swatch:ClearAllPoints()
            if lockButton then
                swatch:SetPoint("LEFT", lockButton, "RIGHT", CONTROL_PADDING, 0)
            else
                swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
            end
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
                
                -- Convert to hex
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
                
                -- Convert to hex
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
    return row, yOffset - rowHeight - 10  -- Extra 5px spacing below color picker
end

-- ---------------------------------------------------------------------------
-- AddHeader - section header with divider (Header Control)
-- ---------------------------------------------------------------------------

function addon:DialogAddHeader(dialog, yOffset, text)
    local header = dialog:CreateFontString(nil, "OVERLAY")
    header:SetFont(dialog._fontPath, HEADER_FONT_SIZE, "OUTLINE")
    header:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    header:SetPoint("TOPLEFT", dialog, "TOPLEFT", BORDER_WIDTH + PADDING, yOffset)
    header:SetText(text)

    local dividerY = yOffset - HEADER_FONT_SIZE - 6
    local divider
    divider, dividerY = addon:DialogAddDivider(dialog, dividerY)

    return header, divider, dividerY - HEADER_SPACING_AFTER
end

-- ---------------------------------------------------------------------------
-- AddSubHeader - smaller section header with divider (SubHeader Control)
-- ---------------------------------------------------------------------------

function addon:DialogAddSubHeader(dialog, yOffset, text)
    local header = dialog:CreateFontString(nil, "OVERLAY")
    header:SetFont(dialog._fontPath, SUBHEADER_FONT_SIZE, "OUTLINE")
    header:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    header:SetPoint("TOPLEFT", dialog, "TOPLEFT", BORDER_WIDTH + PADDING, yOffset)
    header:SetText(text)

    local dividerY = yOffset - SUBHEADER_FONT_SIZE - 4
    local divider
    divider, dividerY = addon:DialogAddDivider(dialog, dividerY)

    return header, divider, dividerY - SUBHEADER_SPACING_AFTER
end

-- ---------------------------------------------------------------------------
-- AddSectionTitle - centered module/section title (Section Title Control)
-- ---------------------------------------------------------------------------

local SECTION_TITLE_FONT_SIZE = 16
local SECTION_TITLE_TOP_PADDING = 12
local SECTION_TITLE_BOTTOM_PADDING = 12

function addon:DialogAddSectionTitle(dialog, yOffset, text)
    yOffset = yOffset - SECTION_TITLE_TOP_PADDING
    
    local title = dialog:CreateFontString(nil, "OVERLAY")
    title:SetFont(dialog._fontPath, SECTION_TITLE_FONT_SIZE, "OUTLINE")
    title:SetTextColor(1, 1, 1)
    title:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    title:SetText(text)
    
    return title, yOffset - SECTION_TITLE_FONT_SIZE - SECTION_TITLE_BOTTOM_PADDING
end

-- ---------------------------------------------------------------------------
-- AddSpacer - invisible spacing (matches section title height)
-- ---------------------------------------------------------------------------

function addon:DialogAddSpacer(dialog, yOffset)
    -- Create invisible frame with same height as section title for consistent spacing
    local spacer = CreateFrame("Frame", nil, dialog)
    spacer:SetHeight(SECTION_TITLE_TOP_PADDING + SECTION_TITLE_FONT_SIZE + SECTION_TITLE_BOTTOM_PADDING)
    spacer:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    
    return spacer, yOffset - (SECTION_TITLE_TOP_PADDING + SECTION_TITLE_FONT_SIZE + SECTION_TITLE_BOTTOM_PADDING)
end

-- ---------------------------------------------------------------------------
-- FinalizeDialog - resize height to fit content
-- ---------------------------------------------------------------------------

function addon:DialogFinalize(dialog, yOffset)
    local totalHeight = math.abs(yOffset) + BORDER_WIDTH + PADDING
    dialog:SetHeight(totalHeight)
end

-- ---------------------------------------------------------------------------
-- AddButton - generic button row (Button Control)
-- ---------------------------------------------------------------------------

local BUTTON_HEIGHT = 28

function addon:DialogAddButton(dialog, yOffset, label, onClick)
    local btn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    btn:SetSize(dialog:GetWidth() - 2 * (BORDER_WIDTH + PADDING), BUTTON_HEIGHT)
    btn:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    btn:SetText(label)
    btn:GetFontString():SetFont(dialog._fontPath, BUTTON_FONT_SIZE, "OUTLINE")
    btn:SetScript("OnClick", onClick)
    return btn, yOffset - BUTTON_HEIGHT
end

local function ResolveEditModeSubDialogWidth(sizeMode, explicitWidth)
    if type(explicitWidth) == "number" and explicitWidth > 0 then
        return explicitWidth
    end

    local mainDialog = addon._editModeDialog
    local baseWidth = mainDialog and mainDialog:GetWidth() or 320

    if sizeMode == "large" then
        return (baseWidth * 2) + 116
    end

    return baseWidth
end

function addon:CreateEditModeSubDialog(name, titleText, options)
    options = options or {}

    local width = ResolveEditModeSubDialogWidth(options.sizeMode, options.width)
    local dialog = self:CreateDialog(name, titleText or "", width)

    dialog:SetFrameStrata(options.frameStrata or "TOOLTIP")
    dialog:SetFrameLevel(options.frameLevel or 300)

    dialog.title:SetFont(dialog._fontPath, options.titleFontSize or TITLE_FONT_SIZE, "OUTLINE")
    dialog.title:SetWidth(width - 2 * (BORDER_WIDTH + PADDING) - (options.titleRightPadding or 60))
    dialog.title:SetWordWrap(false)
    dialog.title:SetMaxLines(1)

    if options.showBackButton ~= false then
        local titleIcon = dialog:CreateTexture(nil, "OVERLAY")
        titleIcon:SetSize(20, 20)
        titleIcon:SetAtlas("CreditsScreen-Assets-Buttons-Play")
        titleIcon:SetRotation(math.pi)
        titleIcon:SetPoint("CENTER", dialog, "TOPLEFT", dialog._borderWidth + dialog._padding + 14, -(dialog._borderWidth + dialog._padding + 11))
        titleIcon:SetDesaturated(true)
        dialog._titleIcon = titleIcon

        local titleHover = CreateFrame("Frame", nil, dialog)
        titleHover:SetPoint("TOPLEFT", titleIcon, "TOPLEFT", 0, 0)
        titleHover:SetPoint("BOTTOMRIGHT", titleIcon, "BOTTOMRIGHT", 0, 0)
        titleHover:EnableMouse(true)
        titleHover:SetScript("OnEnter", function()
            titleIcon:SetDesaturated(false)
        end)
        titleHover:SetScript("OnLeave", function()
            titleIcon:SetDesaturated(true)
        end)
        titleHover:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" then return end
            if InCombatLockdown() then return end
            if options.onBackClick then
                options.onBackClick()
            end
        end)
        dialog._titleHover = titleHover
    end

    local dividerY = -(dialog._borderWidth + dialog._padding + TITLE_FONT_SIZE + 20)
    local titleDivider, y = self:DialogAddDivider(dialog, dividerY)
    dialog._titleDivider = titleDivider
    dialog._contentAreaTopOffset = y - 8

    return dialog
end

-- ---------------------------------------------------------------------------
-- Edit mode sub-dialog infrastructure
-- ---------------------------------------------------------------------------

local subDialog
local confirmDialog
local SUB_DIALOG_TITLE_FONT_SIZE = 16
local CONFIRM_DIALOG_TITLE_FONT_SIZE = 18

local MODULE_SUB_DIALOG_METHODS = {
    arenaTargets = "PopulateArenaTargetsSubDialog",
    castbar = "PopulateCastbarSubDialog",
    combatIndicator = "PopulateCombatIndicatorSubDialog",
    dispelIcon = "PopulateDispelIconSubDialog",
    drTracker = "PopulateDRTrackerSubDialog",
    restingIndicator = "PopulateRestingIndicatorSubDialog",
    roleIcon = "PopulateRoleIconSubDialog",
    trinket = "PopulateTrinketSubDialog",
}

local function IsAuraFilterModule(configKey, moduleKey)
    if not configKey or not moduleKey then
        return false
    end

    local cfg = addon.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.auraFilters then
        return false
    end

    for _, filterCfg in ipairs(cfg.modules.auraFilters) do
        if filterCfg.name == moduleKey then
            return true
        end
    end

    return false
end

local LARGE_SUB_DIALOG_MODULES = {
    castbar = true,
}

local function ShouldUseLargeSubDialog(configKey, moduleKey)
    if not moduleKey then
        return false
    end

    if LARGE_SUB_DIALOG_MODULES[moduleKey] == true then
        return true
    end

    return IsAuraFilterModule(configKey, moduleKey)
end

local function ToPascalCase(value)
    if not value then return "" end

    local parts = {}
    for part in tostring(value):gmatch("[^_%-%s%.]+") do
        part = part:gsub("^%l", string.upper)
        parts[#parts + 1] = part
    end

    local merged = table.concat(parts)
    if merged == "" then
        return ""
    end

    return merged:gsub("^%l", string.upper)
end

local function GetConfigDisplayName(configKey)
    return ToPascalCase(configKey)
end

local function GetModuleDisplayName(moduleKey)
    return ToPascalCase(moduleKey)
end

local function GetModuleFrameName(moduleKey)
    if not moduleKey then return nil end

    if moduleKey == "drTracker" then
        return "DRTracker"
    end

    return moduleKey:sub(1, 1):upper() .. moduleKey:sub(2)
end

local function RefreshTextureBorders(frame, cfg)
    if not frame or not cfg or not cfg.modules then return end

    local trinketCfg = cfg.modules.trinket
    if trinketCfg and frame.Trinket then
        addon:AddTextureBorder(frame.Trinket, trinketCfg.borderWidth, trinketCfg.borderColor)
    end

    local arenaTargetsCfg = cfg.modules.arenaTargets
    if arenaTargetsCfg and frame.ArenaTargets and frame.ArenaTargets.widget and frame.ArenaTargets.widget.indicators then
        local borderWidth = arenaTargetsCfg.borderWidth
        local borderColor = arenaTargetsCfg.borderColor
        for _, indicator in ipairs(frame.ArenaTargets.widget.indicators) do
            if indicator.Inner then
                indicator.Inner:ClearAllPoints()
                indicator.Inner:SetPoint("TOPLEFT", borderWidth, -borderWidth)
                indicator.Inner:SetPoint("BOTTOMRIGHT", -borderWidth, borderWidth)
            end
            addon:AddTextureBorder(indicator, borderWidth, borderColor)
        end
    end

    local drCfg = cfg.modules.drTracker
    if drCfg and frame.DRTracker then
        addon:AddTextureBorder(frame.DRTracker, drCfg.containerBorderWidth, drCfg.containerBorderColor)
    end

    if cfg.modules.auraFilters then
        for _, filterCfg in ipairs(cfg.modules.auraFilters) do
            if filterCfg.enabled and filterCfg.name then
                local filter = frame[filterCfg.name]
                if filter and filter.icons then
                    for _, icon in pairs(filter.icons) do
                        addon:AddTextureBorder(icon, filterCfg.borderWidth, filterCfg.borderColor)
                    end
                end
            end
        end
    end
end

local function ClearSubDialogControls()
    if not subDialog then return end

    if subDialog._controls then
        for _, control in ipairs(subDialog._controls) do
            control:Hide()
            control:SetParent(nil)
        end
    end
    
    subDialog._controls = {}
end

local function BuildSubDialog()
    if subDialog then return subDialog end

    local mainDialog = addon._editModeDialog
    subDialog = addon:CreateEditModeSubDialog("ZenFramesEditModeSubDialog", "", {
        sizeMode = "normal",
        onBackClick = function()
            addon:ReturnFromEditModeSubDialog()
        end,
    })
    addon._editModeSubDialog = subDialog

    if mainDialog then
        subDialog:SetSize(mainDialog:GetWidth(), mainDialog:GetHeight())
    end

    local resetY = -(subDialog:GetHeight() - subDialog._borderWidth - subDialog._padding)
    local resetBtn = addon:DialogAddButton(subDialog, resetY, addon:L("resetButton"), function()
        if subDialog._configKey then
            addon:ShowResetConfirmDialog(subDialog._configKey, subDialog._moduleKey)
        end
    end)
    subDialog._resetButton = resetBtn

    return subDialog
end

local function BuildConfirmDialog()
    if confirmDialog then return confirmDialog end

    local width = 350
    confirmDialog = addon:CreateDialog("ZenFramesResetConfirmDialog", "", width)
    addon._editModeConfirmDialog = confirmDialog
    confirmDialog:SetFrameStrata("TOOLTIP")
    confirmDialog:SetFrameLevel(1000)
    confirmDialog.title:SetFont(confirmDialog._fontPath, CONFIRM_DIALOG_TITLE_FONT_SIZE, "OUTLINE")
    confirmDialog.title:SetText(addon:L("resetButton"))

    local dividerY = -(confirmDialog._borderWidth + confirmDialog._padding + CONFIRM_DIALOG_TITLE_FONT_SIZE + 20)
    addon:DialogAddDivider(confirmDialog, dividerY)

    local msgY = confirmDialog._contentTop
    local message = confirmDialog:CreateFontString(nil, "OVERLAY")
    message:SetFont(confirmDialog._fontPath, 14, "OUTLINE")
    message:SetTextColor(1, 1, 1)
    message:SetPoint("TOP", confirmDialog, "TOP", 0, msgY)
    message:SetWidth(width - 2 * (confirmDialog._borderWidth + confirmDialog._padding))
    message:SetJustifyH("LEFT")
    message:SetWordWrap(true)
    message:SetText(addon:L("resetConfirmText"))
    confirmDialog.message = message

    local msgHeight = message:GetStringHeight()
    local buttonY = msgY - msgHeight - 15

    local buttonWidth = (width - 2 * (confirmDialog._borderWidth + confirmDialog._padding) - 10) / 2
    local buttonHeight = 28

    local resetBtn = CreateFrame("Button", nil, confirmDialog, "UIPanelButtonTemplate")
    resetBtn:SetSize(buttonWidth, buttonHeight)
    resetBtn:SetPoint("TOPLEFT", confirmDialog, "TOPLEFT", confirmDialog._borderWidth + confirmDialog._padding, buttonY)
    resetBtn:SetText(addon:L("resetButton"))
    resetBtn:GetFontString():SetFont(confirmDialog._fontPath, 13, "OUTLINE")
    resetBtn:SetScript("OnClick", function()
        if confirmDialog.onConfirm then
            confirmDialog.onConfirm()
        end
        confirmDialog:Hide()
    end)
    confirmDialog.confirmButton = resetBtn

    local cancelBtn = CreateFrame("Button", nil, confirmDialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(buttonWidth, buttonHeight)
    cancelBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:GetFontString():SetFont(confirmDialog._fontPath, 13, "OUTLINE")
    cancelBtn:SetScript("OnClick", function()
        if confirmDialog.onCancel then
            confirmDialog.onCancel()
        end
        confirmDialog:Hide()
    end)
    confirmDialog.cancelButton = cancelBtn

    local totalHeight = math.abs(buttonY - buttonHeight) + confirmDialog._borderWidth + confirmDialog._padding
    confirmDialog:SetHeight(totalHeight)

    confirmDialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    confirmDialog:EnableKeyboard(true)

    confirmDialog:SetScript("OnShow", function(self)
        self:SetPropagateKeyboardInput(false)
    end)

    confirmDialog:SetScript("OnHide", function(self)
        self:SetPropagateKeyboardInput(true)
        self.onConfirm = nil
        self.onCancel = nil
    end)

    return confirmDialog
end

ShowEditModeConfirmDialog = function(options)
    if InCombatLockdown() then return end

    local confirm = BuildConfirmDialog()
    if not confirm then return end

    local titleText = options and options.title or addon:L("resetButton")
    local messageText = options and options.message or addon:L("resetConfirmText")
    local confirmText = options and options.confirmText or addon:L("resetButton")

    confirm.title:SetText(titleText)
    confirm.message:SetText(messageText)

    if confirm.confirmButton then
        confirm.confirmButton:SetText(confirmText)
    end

    confirm.onConfirm = options and options.onConfirm
    confirm.onCancel = options and options.onCancel

    local msgHeight = confirm.message:GetStringHeight()
    local buttonY = confirm._contentTop - msgHeight - 15

    if confirm.confirmButton then
        confirm.confirmButton:ClearAllPoints()
        confirm.confirmButton:SetPoint("TOPLEFT", confirm, "TOPLEFT", confirm._borderWidth + confirm._padding, buttonY)
    end

    if confirm.cancelButton and confirm.confirmButton then
        confirm.cancelButton:ClearAllPoints()
        confirm.cancelButton:SetPoint("LEFT", confirm.confirmButton, "RIGHT", 10, 0)
    end

    local buttonHeight = confirm.confirmButton and confirm.confirmButton:GetHeight() or 28
    local totalHeight = math.abs(buttonY - buttonHeight) + confirm._borderWidth + confirm._padding
    confirm:SetHeight(totalHeight)

    local parentDialog = addon._editModeSubDialog
    if not (parentDialog and parentDialog:IsShown()) then
        parentDialog = addon._editModeSettingsDialog
    end
    if not (parentDialog and parentDialog:IsShown()) then
        parentDialog = addon._editModeDialog
    end

    if parentDialog and parentDialog:IsShown() then
        confirm:ClearAllPoints()
        confirm:SetPoint("CENTER", parentDialog, "CENTER", 0, 0)
    end

    confirm:Show()
end

function addon:HideAllEditModeSubDialogs()
    if InCombatLockdown() then return false end

    if confirmDialog then
        confirmDialog:Hide()
    end

    if subDialog then
        local wasShown = subDialog:IsShown()
        ClearSubDialogControls()
        subDialog:Hide()
        return wasShown
    end

    return false
end

local function GetDialogCenter(frame)
    if not frame then return nil, nil end

    local centerX, centerY = frame:GetCenter()
    if centerX and centerY then
        return centerX, centerY
    end

    local left = frame:GetLeft()
    local bottom = frame:GetBottom()
    local width = frame:GetWidth()
    local height = frame:GetHeight()

    if not left or not bottom or not width or not height then
        return nil, nil
    end

    return left + (width / 2), bottom + (height / 2)
end

function addon:GetOpenEditModeDialogCenter(excludedDialog)
    return self:GetOpenConfigDialogCenter(excludedDialog)
end

function addon:GetOpenConfigDialogCenter(excludedDialog)
    local candidates = {
        { name = "settings", frame = self._editModeSettingsDialog },
        { name = "sub", frame = self._editModeSubDialog },
        { name = "main", frame = self._editModeDialog },
    }

    for _, candidate in ipairs(candidates) do
        local dialog = candidate.frame

        if dialog and dialog ~= excludedDialog and dialog:IsShown() then
            local centerX, centerY = GetDialogCenter(dialog)
            if centerX and centerY then
                return centerX, centerY
            end
        end
    end

    -- Fallback for transient handoff states where source dialog may already report shown=false
    -- but still has valid geometry for position continuity.
    for _, candidate in ipairs(candidates) do
        local dialog = candidate.frame
        if dialog and dialog ~= excludedDialog then
            local centerX, centerY = GetDialogCenter(dialog)
            if centerX and centerY then
                return centerX, centerY
            end
        end
    end

    return nil, nil
end

function addon:HideOpenConfigDialogs(excludedDialog)
    if InCombatLockdown() then return false end

    local hiddenAny = false

    local settingsDialog = self._editModeSettingsDialog
    if settingsDialog and settingsDialog ~= excludedDialog and settingsDialog:IsShown() then
        settingsDialog:Hide()
        hiddenAny = true
    end

    if subDialog and subDialog ~= excludedDialog and subDialog:IsShown() then
        ClearSubDialogControls()
        subDialog:Hide()
        hiddenAny = true
    end

    local mainDialog = self._editModeDialog
    if mainDialog and mainDialog ~= excludedDialog and mainDialog:IsShown() then
        mainDialog:Hide()
        hiddenAny = true
    end

    return hiddenAny
end

function addon:ReturnFromEditModeSubDialog()
    if InCombatLockdown() then return end

    local centerX, centerY = GetDialogCenter(subDialog)
    self:HideAllEditModeSubDialogs()
    self:ShowEditModeDialog()

    local mainDialog = self._editModeDialog
    if mainDialog and centerX and centerY then
        mainDialog:ClearAllPoints()
        mainDialog:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    end
end

function addon:ShowEditModeSubDialog(configKey, moduleKey)
    if InCombatLockdown() then return end
    if not configKey then return end

    -- Get position of any currently open dialog BEFORE building sub-dialog
    -- (BuildSubDialog returns singleton, so we need position before we get the frame)
    local centerX, centerY = self:GetOpenConfigDialogCenter(nil)

    local sub = BuildSubDialog()
    self:HideOpenConfigDialogs(sub)
    local mainDialog = addon._editModeDialog
    local height = (mainDialog and mainDialog:GetHeight()) or sub:GetHeight()
    local sizeMode = ShouldUseLargeSubDialog(configKey, moduleKey) and "large" or "normal"
    local width = ResolveEditModeSubDialogWidth(sizeMode)
    sub:SetSize(width, height)

    -- Create or remove columns based on sizeMode
    if sizeMode == "large" then
        -- Create columns if they don't exist
        if not sub._leftColumn then
            local columnGap = 28
            local columnWidth = (width - 2 * (BORDER_WIDTH + PADDING) - columnGap) / 2

            local leftColumn = CreateFrame("Frame", nil, sub)
            leftColumn:SetPoint("TOPLEFT", sub, "TOPLEFT", BORDER_WIDTH + PADDING, sub._contentAreaTopOffset)
            leftColumn:SetSize(columnWidth, 1)
            leftColumn._fontPath = sub._fontPath
            leftColumn._isDialogColumn = true
            sub._leftColumn = leftColumn

            local rightColumn = CreateFrame("Frame", nil, sub)
            rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", columnGap, 0)
            rightColumn:SetSize(columnWidth, 1)
            rightColumn._fontPath = sub._fontPath
            rightColumn._isDialogColumn = true
            sub._rightColumn = rightColumn
        else
            -- Update column widths if they exist
            local columnGap = 28
            local columnWidth = (width - 2 * (BORDER_WIDTH + PADDING) - columnGap) / 2
            sub._leftColumn:SetWidth(columnWidth)
            sub._rightColumn:SetWidth(columnWidth)
        end
    else
        -- Remove columns for normal sizeMode
        if sub._leftColumn then
            sub._leftColumn:Hide()
            sub._leftColumn = nil
        end
        if sub._rightColumn then
            sub._rightColumn:Hide()
            sub._rightColumn = nil
        end
    end

    sub.title:SetWidth(width - 2 * (BORDER_WIDTH + PADDING) - 60)

    if sub._resetButton then
        local resetY = -(height - sub._borderWidth - sub._padding)
        local normalWidth = ResolveEditModeSubDialogWidth("normal")
        local resetButtonWidth = normalWidth - 2 * (BORDER_WIDTH + PADDING)
        sub._resetButton:SetWidth(resetButtonWidth)
        sub._resetButton:ClearAllPoints()
        sub._resetButton:SetPoint("TOP", sub, "TOP", 0, resetY)
    end

    sub._configKey = configKey
    sub._moduleKey = moduleKey

    -- Title is just the frame name
    local title = GetConfigDisplayName(configKey)
    sub.title:SetText(title)

    sub:ClearAllPoints()
    if centerX and centerY then
        sub:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    else
        sub:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    ClearSubDialogControls()
    
    -- Start content below the divider (divider is at -(borderWidth + padding + titleSize + 20), 2px tall)
    local contentY = -(sub._borderWidth + sub._padding + TITLE_FONT_SIZE + 20 + DIVIDER_HEIGHT)
    
    -- Add section title (module name) if present, otherwise add spacer for consistent positioning
    if moduleKey then
        local sectionTitle
        sectionTitle, contentY = self:DialogAddSectionTitle(sub, contentY, GetModuleDisplayName(moduleKey))
        table.insert(sub._controls, sectionTitle)
    else
        local spacer
        spacer, contentY = self:DialogAddSpacer(sub, contentY)
        table.insert(sub._controls, spacer)
    end

    -- For large dialogs with columns, convert contentY from dialog-relative to column-relative.
    -- Column frames are already positioned at _contentAreaTopOffset from the dialog TOP,
    -- so controls inside them need yOffset relative to the column's TOP, not the dialog's TOP.
    if sizeMode == "large" and sub._leftColumn and sub._contentAreaTopOffset then
        contentY = contentY - sub._contentAreaTopOffset
    end
    
    if not moduleKey then
        if self.PopulateUnitFrameSubDialog then
            self:PopulateUnitFrameSubDialog(subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        end
    elseif IsAuraFilterModule(configKey, moduleKey) then
        if self.PopulateAuraFilterSubDialog then
            self:PopulateAuraFilterSubDialog(subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        end
    else
        local methodName = MODULE_SUB_DIALOG_METHODS[moduleKey]
        if methodName and self[methodName] then
            self[methodName](self, subDialog, configKey, moduleKey, contentY, GetModuleFrameName)
        end
    end

    sub:Show()
end

function addon:ShowResetConfirmDialog(configKey, moduleKey)
    if InCombatLockdown() then return end

    ShowEditModeConfirmDialog({
        title = self:L("resetButton"),
        message = self:L("resetConfirmText"),
        confirmText = self:L("resetButton"),
        onConfirm = function()
        local cfg = self.config[configKey]
        local targetCfg = cfg

        local isAuraFilter = false
        local auraFilterIndex = nil
        if moduleKey and cfg.modules and cfg.modules.auraFilters then
            for i, filter in ipairs(cfg.modules.auraFilters) do
                if filter.name == moduleKey then
                    targetCfg = filter
                    isAuraFilter = true
                    auraFilterIndex = i
                    break
                end
            end
        end

        if not isAuraFilter and moduleKey and cfg.modules and cfg.modules[moduleKey] then
            targetCfg = cfg.modules[moduleKey]
        end

        local preserveEnabled = targetCfg.enabled
        local preserveHideBlizzard = targetCfg.hideBlizzard

        if isAuraFilter then
            self:ClearOverrides({configKey, "modules", "auraFilters", auraFilterIndex})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "modules", "auraFilters", auraFilterIndex, "enabled"}, preserveEnabled)
            end
            if preserveHideBlizzard ~= nil then
                self:SetOverride({configKey, "modules", "auraFilters", auraFilterIndex, "hideBlizzard"}, preserveHideBlizzard)
            end
        elseif moduleKey then
            self:ClearOverrides({configKey, "modules", moduleKey})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "modules", moduleKey, "enabled"}, preserveEnabled)
            end
            if preserveHideBlizzard ~= nil then
                self:SetOverride({configKey, "modules", moduleKey, "hideBlizzard"}, preserveHideBlizzard)
            end
        else
            self:ClearOverrides({configKey})
            if preserveEnabled ~= nil then
                self:SetOverride({configKey, "enabled"}, preserveEnabled)
            end
            if preserveHideBlizzard ~= nil then
                self:SetOverride({configKey, "hideBlizzard"}, preserveHideBlizzard)
            end
        end

        self:RefreshConfig()

        if moduleKey then
            self:RefreshModule(configKey, moduleKey)

            if configKey == "party" or configKey == "arena" then
                local containerName = configKey == "party" and "zfPartyContainer" or "zfArenaContainer"
                local container = _G[containerName]

                if container and container.frames then
                    local frameCfg = self.config[configKey]
                    local defaultFrameCfg = self:GetDefaultConfig()[configKey]

                    local moduleCfg = frameCfg.modules[moduleKey]
                    if not moduleCfg then
                        if isAuraFilter and auraFilterIndex then
                            moduleCfg = defaultFrameCfg.modules.auraFilters[auraFilterIndex]
                        end
                    end

                    if moduleCfg then
                        local anchorPoint = moduleCfg.anchor
                        local relativePoint = moduleCfg.relativePoint
                        local offsetX = moduleCfg.offsetX or 0
                        local offsetY = moduleCfg.offsetY or 0
                        local moduleName = GetModuleFrameName(moduleKey)

                        for _, unitFrame in ipairs(container.frames) do
                            local module = unitFrame[moduleName]

                            if module and anchorPoint and relativePoint then
                                local moduleAnchorFrame = unitFrame

                                if moduleCfg.relativeToModule then
                                    local ref = moduleCfg.relativeToModule
                                    if type(ref) == "table" then
                                        for _, key in ipairs(ref) do
                                            if unitFrame[key] then
                                                moduleAnchorFrame = unitFrame[key]
                                                break
                                            end
                                        end
                                    else
                                        moduleAnchorFrame = unitFrame[ref] or unitFrame
                                    end
                                end

                                local moduleRelativeFrame = moduleCfg.relativeTo and _G[moduleCfg.relativeTo] or moduleAnchorFrame

                                if moduleRelativeFrame then
                                    module:ClearAllPoints()
                                    module:SetPoint(anchorPoint, moduleRelativeFrame, relativePoint, offsetX, offsetY)
                                end
                            end
                        end
                    end
                end
            end

            if moduleKey == "roleIcon" and self.RefreshRoleIconEditModeVisuals then
                self:RefreshRoleIconEditModeVisuals(configKey, moduleKey)
            end

            if moduleKey == "dispelIcon" and self.RefreshDispelIconEditModeVisuals then
                self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
            end

            if moduleKey == "arenaTargets" and self.RefreshArenaTargetsEditModeVisuals then
                self:RefreshArenaTargetsEditModeVisuals(configKey, moduleKey)
            end
        else
            self:RefreshFrame(configKey)
        end

        if self.editMode then
            local frameCfg = self.config and self.config[configKey]
            if frameCfg then
                if configKey == "party" or configKey == "arena" then
                    local container = self.groupContainers and self.groupContainers[configKey]
                    if container and container.frames then
                        for _, unitFrame in ipairs(container.frames) do
                            RefreshTextureBorders(unitFrame, frameCfg)
                        end
                    end
                else
                    local frame = frameCfg.frameName and _G[frameCfg.frameName]
                    if frame then
                        RefreshTextureBorders(frame, frameCfg)
                    end
                end
            end
        end

        if subDialog and subDialog:IsShown() then
            self:ShowEditModeSubDialog(configKey, moduleKey)
        end
        end,
    })
end

-- ---------------------------------------------------------------------------
-- Sub-dialog state persistence for reload workflow
-- ---------------------------------------------------------------------------

function addon:SetPendingSubDialogReopen(configKey, moduleKey)
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.reopenSubDialog = {
        configKey = configKey,
        moduleKey = moduleKey
    }
end

function addon:CheckAndReopenSubDialog()
    if not self.savedVars or not self.savedVars.data then return end
    
    local reopenData = self.savedVars.data.reopenSubDialog
    if reopenData and reopenData.configKey then
        local configKey = reopenData.configKey
        local moduleKey = reopenData.moduleKey
        
        -- Clear the flag
        self.savedVars.data.reopenSubDialog = nil
        
        -- Reopen the sub-dialog
        self:ShowEditModeSubDialog(configKey, moduleKey)
    end
end

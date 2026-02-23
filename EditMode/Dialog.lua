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
local BG_COLOR = { 0, 0, 0, 0.65 }
local BORDER_COLOR = { 0, 0, 0, 1 }
local DIVIDER_HEIGHT = 2
local DIVIDER_COLOR = { 0, 0, 0, 1 }

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
-- AddToggleRow - checkbox + visibility eye + label
-- ---------------------------------------------------------------------------

local ROW_HEIGHT = 36
local CHECKBOX_SIZE = 28
local EYE_SIZE = 28
local EYE_PADDING = 8
local LABEL_FONT_SIZE = 14

function addon:DialogAddToggleRow(dialog, yOffset, label, checked, visible, onCheckChanged, onVisibilityChanged)
    local row = CreateFrame("Frame", nil, dialog)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("LEFT", dialog, "LEFT", BORDER_WIDTH + PADDING, 0)
    row:SetPoint("RIGHT", dialog, "RIGHT", -(BORDER_WIDTH + PADDING), 0)
    row:SetPoint("TOP", dialog, "TOP", 0, yOffset)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetChecked(checked)
    cb:SetScript("OnClick", function(self)
        if onCheckChanged then
            onCheckChanged(self:GetChecked())
        end
    end)
    row.checkbox = cb

    local eye = CreateFrame("Button", nil, row)
    eye:SetSize(EYE_SIZE, EYE_SIZE)
    eye:SetPoint("LEFT", cb, "RIGHT", EYE_PADDING, 0)

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
    text:SetFont(fontPath, LABEL_FONT_SIZE, "OUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("LEFT", eye, "RIGHT", EYE_PADDING, 0)
    text:SetText(label)
    row.label = text

    return row, yOffset - ROW_HEIGHT
end

-- ---------------------------------------------------------------------------
-- FinalizeDialog - resize height to fit content
-- ---------------------------------------------------------------------------

function addon:DialogFinalize(dialog, yOffset)
    local totalHeight = math.abs(yOffset) + BORDER_WIDTH + PADDING
    dialog:SetHeight(totalHeight)
end

-- ---------------------------------------------------------------------------
-- AddButton - generic button row
-- ---------------------------------------------------------------------------

local BUTTON_HEIGHT = 28
local BUTTON_FONT_SIZE = 13

function addon:DialogAddButton(dialog, yOffset, label, onClick)
    local btn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    btn:SetSize(dialog:GetWidth() - 2 * (BORDER_WIDTH + PADDING), BUTTON_HEIGHT)
    btn:SetPoint("TOP", dialog, "TOP", 0, yOffset)
    btn:SetText(label)
    btn:GetFontString():SetFont(dialog._fontPath, BUTTON_FONT_SIZE, "OUTLINE")
    btn:SetScript("OnClick", onClick)
    return btn, yOffset - BUTTON_HEIGHT
end

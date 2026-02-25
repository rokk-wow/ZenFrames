local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Text tag reference content (displayed in help dialog)
-- ---------------------------------------------------------------------------

local HELP_HEADER_COLOR = "|cff00ff98"
local HELP_TAG_COLOR = "|cffffd100"
local HELP_TEXT_COLOR = "|cffffffff"
local HELP_EXAMPLE_COLOR = "|cffaaaaaa"

local HELP_TEXT = table.concat({
    HELP_HEADER_COLOR .. "Text Tag Reference|r",
    "",
    HELP_TEXT_COLOR .. "Tags are enclosed in square brackets and combined with literal text.|r",
    "",
    HELP_HEADER_COLOR .. "Syntax Examples|r",
    HELP_TAG_COLOR .. "  [name]|r " .. HELP_EXAMPLE_COLOR .. "-> Full unit name|r",
    HELP_TAG_COLOR .. "  [perhp]%|r " .. HELP_EXAMPLE_COLOR .. "-> 85%|r",
    HELP_TAG_COLOR .. "  [curhp:short] / [maxhp:short]|r " .. HELP_EXAMPLE_COLOR .. "-> 245K / 300K|r",
    HELP_TAG_COLOR .. "  [raidcolor][name:medium]\\|r|r " .. HELP_EXAMPLE_COLOR .. "-> Class-colored name|r",
    "",
    HELP_TEXT_COLOR .. "Optional prefix/suffix (shown only if the tag returns a value):|r",
    HELP_TAG_COLOR .. "  [==$>name<$==]|r " .. HELP_EXAMPLE_COLOR .. "-> ==Thrall==|r",
    HELP_TAG_COLOR .. "  [perhp<$%]|r " .. HELP_EXAMPLE_COLOR .. "-> 85%|r",
    "",
    HELP_HEADER_COLOR .. "Name Tags|r",
    HELP_TAG_COLOR .. "  [name]|r " .. HELP_TEXT_COLOR .. "Full name|r",
    HELP_TAG_COLOR .. "  [name:short]|r " .. HELP_TEXT_COLOR .. "Short name|r",
    HELP_TAG_COLOR .. "  [name:medium]|r " .. HELP_TEXT_COLOR .. "Medium name|r",
    HELP_TAG_COLOR .. "  [name:long]|r " .. HELP_TEXT_COLOR .. "Long name|r",
    HELP_TAG_COLOR .. "  [name:abbrev]|r " .. HELP_TEXT_COLOR .. "Abbreviated name|r",
    HELP_TAG_COLOR .. "  [name:trunc(12)]|r " .. HELP_TEXT_COLOR .. "Truncated to 12 characters|r",
    "",
    HELP_HEADER_COLOR .. "Health Tags|r",
    HELP_TAG_COLOR .. "  [curhp]|r " .. HELP_TEXT_COLOR .. "Current HP (raw number)|r",
    HELP_TAG_COLOR .. "  [maxhp]|r " .. HELP_TEXT_COLOR .. "Max HP (raw number)|r",
    HELP_TAG_COLOR .. "  [perhp]|r " .. HELP_TEXT_COLOR .. "Health percent (e.g. 85)|r",
    HELP_TAG_COLOR .. "  [missinghp]|r " .. HELP_TEXT_COLOR .. "Missing HP|r",
    HELP_TAG_COLOR .. "  [curhp:short]|r " .. HELP_TEXT_COLOR .. "Current HP abbreviated (245K)|r",
    HELP_TAG_COLOR .. "  [maxhp:short]|r " .. HELP_TEXT_COLOR .. "Max HP abbreviated (300K)|r",
    HELP_TAG_COLOR .. "  [hp:percent]|r " .. HELP_TEXT_COLOR .. "Health percent with % (85%)|r",
    HELP_TAG_COLOR .. "  [hp:cur-percent]|r " .. HELP_TEXT_COLOR .. "245K - 85%|r",
    HELP_TAG_COLOR .. "  [hp:cur-max]|r " .. HELP_TEXT_COLOR .. "245K / 300K|r",
    HELP_TAG_COLOR .. "  [hp:deficit]|r " .. HELP_TEXT_COLOR .. "Missing HP as -245K|r",
    "",
    HELP_HEADER_COLOR .. "Power Tags|r",
    HELP_TAG_COLOR .. "  [curpp]|r " .. HELP_TEXT_COLOR .. "Current power (raw)|r",
    HELP_TAG_COLOR .. "  [maxpp]|r " .. HELP_TEXT_COLOR .. "Max power (raw)|r",
    HELP_TAG_COLOR .. "  [perpp]|r " .. HELP_TEXT_COLOR .. "Power percent|r",
    HELP_TAG_COLOR .. "  [curpp:short]|r " .. HELP_TEXT_COLOR .. "Current power abbreviated|r",
    HELP_TAG_COLOR .. "  [maxpp:short]|r " .. HELP_TEXT_COLOR .. "Max power abbreviated|r",
    HELP_TAG_COLOR .. "  [pp:percent]|r " .. HELP_TEXT_COLOR .. "Power percent with %|r",
    HELP_TAG_COLOR .. "  [pp:cur-percent]|r " .. HELP_TEXT_COLOR .. "Current - percent%|r",
    HELP_TAG_COLOR .. "  [pp:cur-max]|r " .. HELP_TEXT_COLOR .. "Current / Max|r",
    "",
    HELP_HEADER_COLOR .. "Info Tags|r",
    HELP_TAG_COLOR .. "  [level]|r " .. HELP_TEXT_COLOR .. "Unit level|r",
    HELP_TAG_COLOR .. "  [smartlevel]|r " .. HELP_TEXT_COLOR .. "Level with elite/boss indicator|r",
    HELP_TAG_COLOR .. "  [class]|r " .. HELP_TEXT_COLOR .. "Class name|r",
    HELP_TAG_COLOR .. "  [smartclass]|r " .. HELP_TEXT_COLOR .. "Class (players) or creature type (NPCs)|r",
    HELP_TAG_COLOR .. "  [spec]|r " .. HELP_TEXT_COLOR .. "Spec abbreviation (e.g. ARMS, RESTO)|r",
    HELP_TAG_COLOR .. "  [race]|r " .. HELP_TEXT_COLOR .. "Race name|r",
    HELP_TAG_COLOR .. "  [creature]|r " .. HELP_TEXT_COLOR .. "Creature family or type|r",
    HELP_TAG_COLOR .. "  [faction]|r " .. HELP_TEXT_COLOR .. "Faction name|r",
    HELP_TAG_COLOR .. "  [group]|r " .. HELP_TEXT_COLOR .. "Raid group number|r",
    "",
    HELP_HEADER_COLOR .. "Status Tags|r",
    HELP_TAG_COLOR .. "  [dead]|r " .. HELP_TEXT_COLOR .. "Dead or Ghost|r",
    HELP_TAG_COLOR .. "  [offline]|r " .. HELP_TEXT_COLOR .. "Offline if disconnected|r",
    HELP_TAG_COLOR .. "  [status]|r " .. HELP_TEXT_COLOR .. "Dead / Ghost / Offline / zzz|r",
    HELP_TAG_COLOR .. "  [resting]|r " .. HELP_TEXT_COLOR .. "zzz if resting|r",
    HELP_TAG_COLOR .. "  [pvp]|r " .. HELP_TEXT_COLOR .. "PvP if flagged|r",
    HELP_TAG_COLOR .. "  [leader]|r " .. HELP_TEXT_COLOR .. "L if group leader|r",
    HELP_TAG_COLOR .. "  [sex]|r " .. HELP_TEXT_COLOR .. "Male / Female|r",
    "",
    HELP_HEADER_COLOR .. "Color Tags|r",
    HELP_TAG_COLOR .. "  [raidcolor]|r " .. HELP_TEXT_COLOR .. "Class color hex (use before name, \\|r after)|r",
    HELP_TAG_COLOR .. "  [powercolor]|r " .. HELP_TEXT_COLOR .. "Power type color hex|r",
    HELP_TAG_COLOR .. "  [threatcolor]|r " .. HELP_TEXT_COLOR .. "Threat level color hex|r",
    "",
    HELP_HEADER_COLOR .. "Classification Tags|r",
    HELP_TAG_COLOR .. "  [classification]|r " .. HELP_TEXT_COLOR .. "Rare / Rare Elite / Elite / Boss|r",
    HELP_TAG_COLOR .. "  [shortclassification]|r " .. HELP_TEXT_COLOR .. "R / R+ / + / B / -|r",
    HELP_TAG_COLOR .. "  [threat]|r " .. HELP_TEXT_COLOR .. "Aggro / ++ / --|r",
}, "\n")

-- ---------------------------------------------------------------------------
-- Help dialog (scrollable text tag reference)
-- ---------------------------------------------------------------------------

local HELP_DIALOG_WIDTH = 420
local HELP_DIALOG_HEIGHT = 500
local HELP_PADDING = 16
local HELP_BORDER = 8

local helpDialog

local function GetOrCreateHelpDialog()
    if helpDialog then return helpDialog end

    local fontPath = addon:FetchFont("DorisPP")

    local frame = CreateFrame("Frame", "ZenFramesTextTagHelpDialog", UIParent, "BackdropTemplate")
    frame:SetSize(HELP_DIALOG_WIDTH, HELP_DIALOG_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 520, 0)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(500)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = HELP_BORDER,
        insets = { left = HELP_BORDER, right = HELP_BORDER, top = HELP_BORDER, bottom = HELP_BORDER },
    })
    frame:SetBackdropColor(0, 0, 0, 0.92)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 18, "OUTLINE")
    title:SetTextColor(0, 1, 0.596)
    title:SetPoint("TOP", frame, "TOP", 0, -(HELP_BORDER + HELP_PADDING))
    title:SetText("Text Tag Reference")

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(HELP_BORDER + 8), -(HELP_BORDER + 8))
    closeBtn:SetNormalAtlas("EventToastCloseButton")
    closeBtn:SetHighlightAtlas("EventToastCloseButton")
    closeBtn:GetHighlightTexture():SetAlpha(0.3)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local dividerY = -(HELP_BORDER + HELP_PADDING + 18 + 10)
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(2)
    divider:SetColorTexture(0, 0, 0, 1)
    divider:SetPoint("LEFT", frame, "LEFT", HELP_BORDER + HELP_PADDING, 0)
    divider:SetPoint("RIGHT", frame, "RIGHT", -(HELP_BORDER + HELP_PADDING), 0)
    divider:SetPoint("TOP", frame, "TOP", 0, dividerY)

    local scrollTop = dividerY - 8
    local scrollBottom = HELP_BORDER + HELP_PADDING

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", HELP_BORDER + HELP_PADDING, scrollTop)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(HELP_BORDER + HELP_PADDING + 22), scrollBottom)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(HELP_DIALOG_WIDTH - 2 * (HELP_BORDER + HELP_PADDING) - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local body = content:CreateFontString(nil, "OVERLAY")
    body:SetFont(fontPath, 12, "OUTLINE")
    body:SetTextColor(1, 1, 1)
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    body:SetWidth(content:GetWidth())
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetSpacing(3)
    body:SetText(HELP_TEXT)

    content:SetScript("OnShow", function(self)
        local textHeight = body:GetStringHeight()
        self:SetHeight(math.max(textHeight + 10, 1))
    end)

    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    frame:SetScript("OnShow", function(self)
        local textHeight = body:GetStringHeight()
        content:SetHeight(math.max(textHeight + 10, 1))
    end)

    frame:Hide()
    helpDialog = frame
    addon._textTagHelpDialog = frame
    return frame
end

-- ---------------------------------------------------------------------------
-- GetTextConfig - find text config entry by name
-- ---------------------------------------------------------------------------

local configKeyToUnit = {
    player = "player",
    target = "target",
    targetTarget = "targettarget",
    focus = "focus",
    focusTarget = "focustarget",
    pet = "pet",
}

local function ForEachFrameByConfig(configKey, callback)
    local unitId = configKeyToUnit[configKey]
    if unitId and addon.unitFrames then
        local frame = addon.unitFrames[unitId]
        if frame then
            callback(frame)
        end
        return
    end

    if addon.groupContainers and addon.groupContainers[configKey] then
        local container = addon.groupContainers[configKey]
        if container.frames then
            for _, child in ipairs(container.frames) do
                callback(child)
            end
        end
    end
end

local function RefreshTextSize(configKey, textIndex, newSize)
    local cfg = addon.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.text then return end

    ForEachFrameByConfig(configKey, function(frame)
        if frame.Texts and frame.Texts[textIndex] then
            local fs = frame.Texts[textIndex]
            local textCfg = cfg.modules.text[textIndex]
            if textCfg then
                local fontPath = addon:GetFontPath(textCfg.font)
                local fontSize = addon:ResolveFontSize(newSize)
                fs:SetFont(fontPath, fontSize, textCfg.outline)
            end
        end

        if frame._textPins and frame._textPins[textIndex] then
            local pin = frame._textPins[textIndex]
            local pinSize = newSize + 6
            pin:SetSize(pinSize * 3, pinSize)
        end
    end)
end

local function RefreshTextColor(configKey, textIndex, newColor)
    ForEachFrameByConfig(configKey, function(frame)
        if frame.Texts and frame.Texts[textIndex] then
            local fs = frame.Texts[textIndex]
            local r, g, b, a = addon:HexToRGB(newColor)
            fs:SetTextColor(r, g, b, a or 1)
        end
    end)
end

local function RefreshTextOutline(configKey, textIndex, newOutline)
    local cfg = addon.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.text then return end

    ForEachFrameByConfig(configKey, function(frame)
        if frame.Texts and frame.Texts[textIndex] then
            local fs = frame.Texts[textIndex]
            local textCfg = cfg.modules.text[textIndex]
            if textCfg then
                local fontPath = addon:GetFontPath(textCfg.font)
                local fontSize = addon:ResolveFontSize(textCfg.size)
                fs:SetFont(fontPath, fontSize, newOutline)
            end
        end
    end)
end

local function RefreshTextShadow(configKey, textIndex, newShadow)
    ForEachFrameByConfig(configKey, function(frame)
        if frame.Texts and frame.Texts[textIndex] then
            local fs = frame.Texts[textIndex]
            if newShadow then
                fs:SetShadowOffset(1, -1)
                fs:SetShadowColor(0, 0, 0, 1)
            else
                fs:SetShadowOffset(0, 0)
                fs:SetShadowColor(0, 0, 0, 0)
            end
        end
    end)
end

local function RefreshTextFormat(configKey, textIndex, newFormat)
    ForEachFrameByConfig(configKey, function(frame)
        if frame.Texts and frame.Texts[textIndex] then
            local fs = frame.Texts[textIndex]
            if fs._savedUpdateTag then
                fs.UpdateTag = fs._savedUpdateTag
                fs._savedUpdateTag = nil
            end
            frame:Tag(fs, newFormat)
            if fs.UpdateTag then
                fs:UpdateTag()
            end
        end
    end)
end

local function GetTextConfig(self, configKey, moduleKey)
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.text then return nil, nil, nil end

    for i, entry in ipairs(cfg.modules.text) do
        if entry.name == moduleKey then
            return cfg, entry, i
        end
    end

    return nil, nil, nil
end

function addon:RefreshTextEditModeVisuals(configKey, moduleKey)
    self:RefreshConfig()

    local _, textCfg, textIndex = GetTextConfig(self, configKey, moduleKey)
    if not textCfg or not textIndex then return end

    ForEachFrameByConfig(configKey, function(frame)
        if not frame.Texts or not frame.Texts[textIndex] then return end
        local fs = frame.Texts[textIndex]

        local parent = textCfg.relativeTo and _G[textCfg.relativeTo] or frame
        fs:ClearAllPoints()
        fs:SetPoint(textCfg.anchor, parent, textCfg.relativePoint, textCfg.offsetX or 0, textCfg.offsetY or 0)

        local fontPath = addon:GetFontPath(textCfg.font)
        local fontSize = addon:ResolveFontSize(textCfg.size)
        fs:SetFont(fontPath, fontSize, textCfg.outline)

        if textCfg.color then
            local r, g, b, a = addon:HexToRGB(textCfg.color)
            fs:SetTextColor(r, g, b, a or 1)
        end

        if textCfg.shadow then
            fs:SetShadowOffset(1, -1)
            fs:SetShadowColor(0, 0, 0, 1)
        else
            fs:SetShadowOffset(0, 0)
            fs:SetShadowColor(0, 0, 0, 0)
        end

        if fs._savedUpdateTag then
            fs.UpdateTag = fs._savedUpdateTag
            fs._savedUpdateTag = nil
        end
        if textCfg.format then
            frame:Tag(fs, textCfg.format)
            if fs.UpdateTag then
                fs:UpdateTag()
            end
        end

        if frame._textPins and frame._textPins[textIndex] then
            local pin = frame._textPins[textIndex]
            local pinSize = (textCfg.size or 14) + 6
            pin:SetSize(pinSize * 3, pinSize)
        end
    end)
end

function addon:PopulateTextSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local cfg, textCfg, textIndex = GetTextConfig(self, configKey, moduleKey)
    if not textCfg then return end

    subDialog._controls = subDialog._controls or {}

    local enabledRow
    enabledRow, yOffset = self:DialogAddEnableControl(subDialog, yOffset, "Enabled", textCfg.enabled, configKey, moduleKey, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "enabled"}, value)
    end)
    table.insert(subDialog._controls, enabledRow)

    local textRow
    textRow, yOffset = self:DialogAddTextInput(subDialog, yOffset, "Format", textCfg.format, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "format"}, value)
        RefreshTextFormat(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, textRow)

    local helpBtn = CreateFrame("Button", nil, textRow)
    helpBtn:SetSize(18, 18)
    helpBtn:SetPoint("RIGHT", textRow.label, "LEFT", -5, 0)

    local helpIcon = helpBtn:CreateTexture(nil, "ARTWORK")
    helpIcon:SetAllPoints()
    helpIcon:SetAtlas("Crosshair_Questturnin_32")
    helpIcon:SetDesaturated(true)
    helpBtn.icon = helpIcon

    helpBtn:SetScript("OnEnter", function() helpIcon:SetDesaturated(false) end)
    helpBtn:SetScript("OnLeave", function() helpIcon:SetDesaturated(true) end)
    helpBtn:SetScript("OnClick", function()
        local dialog = GetOrCreateHelpDialog()
        if dialog:IsShown() then
            dialog:Hide()
        else
            dialog:Show()
        end
    end)
    table.insert(subDialog._controls, helpBtn)

    local sizeRow
    sizeRow, yOffset = self:DialogAddSlider(subDialog, yOffset, "Size", 8, 32, textCfg.size, 1, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "size"}, value)
        RefreshTextSize(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, sizeRow)

    local colorRow
    colorRow, yOffset = self:DialogAddColorPicker(subDialog, yOffset, "Color", textCfg.color, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "color"}, value)
        RefreshTextColor(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, colorRow)

    local shadowRow
    shadowRow, yOffset = self:DialogAddCheckbox(subDialog, yOffset, "Shadow", textCfg.shadow, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "shadow"}, value)
        RefreshTextShadow(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, shadowRow)

    local outlineOptions = {
        { label = "None", value = "" },
        { label = "Outline", value = "OUTLINE" },
        { label = "Thick Outline", value = "THICKOUTLINE" },
        { label = "Monochrome", value = "MONOCHROME" },
    }
    local outlineRow
    outlineRow, yOffset = self:DialogAddDropdown(subDialog, yOffset, "Outline", outlineOptions, textCfg.outline, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "outline"}, value)
        RefreshTextOutline(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, outlineRow)
end

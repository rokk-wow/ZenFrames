local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Help dialog (scrollable text tag reference)
-- ---------------------------------------------------------------------------

local helpDialog

local function GetOrCreateHelpDialog()
    if helpDialog then return helpDialog end

    local style = addon.DialogStyle

    local dialog = addon:CreateDialog({
        name = "ZenFramesTextTagHelpDialog",
        title = "emTextTagReference",
        width = 420,
        height = 500,
        frameStrata = "TOOLTIP",
        frameLevel = 500,
        dismissOnEscape = true,
    })

    -- Scrollable body for the long help content
    local contentTop = dialog._contentTop
    local padLeft = style.BORDER_WIDTH + style.PADDING
    local scrollBottom = style.BORDER_WIDTH + style.PADDING

    local scroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, contentTop)
    scroll:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -(padLeft + 22), scrollBottom)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(420 - 2 * padLeft - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local body = content:CreateFontString(nil, "OVERLAY")
    body:SetFont(dialog._fontPath, 12, "OUTLINE")
    body:SetTextColor(1, 1, 1)
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    body:SetWidth(content:GetWidth())
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetSpacing(3)
    body:SetText(addon:L("emTextTagHelpContent"))

    dialog:HookScript("OnShow", function()
        local textHeight = body:GetStringHeight()
        content:SetHeight(math.max(textHeight + 10, 1))
    end)

    helpDialog = dialog
    addon._textTagHelpDialog = dialog
    return dialog
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

    local onChange = function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "enabled"}, value)
    end
    local enabledRow
    enabledRow, yOffset = self:DialogAddEnableControl(subDialog, yOffset, "emEnabled", textCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)

    local textRow
    textRow, yOffset = self:DialogAddTextInput(subDialog, yOffset, "emFormat", textCfg.format, function(value)
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
            addon:ShowDialog(dialog, "standalone")
        end
    end)
    table.insert(subDialog._controls, helpBtn)

    local sizeRow
    sizeRow, yOffset = self:DialogAddSlider(subDialog, yOffset, "emSize", 8, 32, textCfg.size, 1, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "size"}, value)
        RefreshTextSize(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, sizeRow)

    local colorRow
    colorRow, yOffset = self:DialogAddColorPicker(subDialog, yOffset, "emColor", textCfg.color, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "color"}, value)
        RefreshTextColor(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, colorRow)

    local shadowRow
    shadowRow, yOffset = self:DialogAddCheckbox(subDialog, yOffset, "emShadow", textCfg.shadow, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "shadow"}, value)
        RefreshTextShadow(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, shadowRow)

    local outlineOptions = {
        { label = "emNone", value = "" },
        { label = "emOutline", value = "OUTLINE" },
        { label = "emThickOutline", value = "THICKOUTLINE" },
        { label = "emMonochrome", value = "MONOCHROME" },
    }
    local outlineRow
    outlineRow, yOffset = self:DialogAddDropdown(subDialog, yOffset, "emOutline", outlineOptions, textCfg.outline, function(value)
        self:SetOverride({configKey, "modules", "text", textIndex, "outline"}, value)
        RefreshTextOutline(configKey, textIndex, value)
    end)
    table.insert(subDialog._controls, outlineRow)
end

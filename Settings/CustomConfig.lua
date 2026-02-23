local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local LibSerialize = LibStub("LibSerialize")

-- ---------------------------------------------------------------------------
-- Pretty-print serializer for human-readable Lua table output
-- ---------------------------------------------------------------------------
local serializeValue, serializeTable

serializeValue = function(v, indent)
    local tv = type(v)
    if tv == "string" then
        return string.format("%q", v)
    elseif tv == "number" or tv == "boolean" then
        return tostring(v)
    elseif tv == "table" then
        return serializeTable(v, indent)
    else
        return "nil"
    end
end

serializeTable = function(tbl, indent)
    indent = indent or ""
    local nextIndent = indent .. "    "

    local numericKeys = {}
    local stringKeys = {}
    for k in pairs(tbl) do
        if type(k) == "number" then
            table.insert(numericKeys, k)
        elseif type(k) == "string" then
            table.insert(stringKeys, k)
        end
    end
    table.sort(numericKeys)
    table.sort(stringKeys)

    local entries = {}
    for _, k in ipairs(numericKeys) do
        table.insert(entries, nextIndent .. serializeValue(tbl[k], nextIndent))
    end
    for _, k in ipairs(stringKeys) do
        local keyStr
        if k:match("^[%a_][%w_]*$") then
            keyStr = k
        else
            keyStr = '["' .. k .. '"]'
        end
        table.insert(entries, nextIndent .. keyStr .. " = " .. serializeValue(tbl[k], nextIndent))
    end

    if #entries == 0 then
        return "{}"
    end

    return "{\n" .. table.concat(entries, ",\n") .. "\n" .. indent .. "}"
end

-- ---------------------------------------------------------------------------
-- Settings panel
-- ---------------------------------------------------------------------------
function addon:SetupCustomConfigSettingsPanel()
    self:AddSettingsPanel("customConfig", {
        title = "customConfigTitle",
        controls = {
            {
                type = "header",
                name = "customConfigNoticeHeader",
            },
            {
                type = "description",
                name = "customConfigTemporaryNotice",
            },
        },
    })
end

-- ---------------------------------------------------------------------------
-- Hook: build entire custom config panel layout
-- ---------------------------------------------------------------------------
function addon:AfterBuildSettingsPanelHelper(panel)
    if not panel or panel.panelKey ~= "customConfig" then return end

    local content = panel.ScrollFrame.Content
    local ui = self.sadCore.ui
    local yOffset = -(content:GetHeight() - ui.spacing.panelBottom) - 10

    -- Scroll container for multiline editbox
    local boxHeight = 300
    local scrollBg = CreateFrame("Frame", nil, content, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", ui.spacing.controlLeft, yOffset)
    scrollBg:SetPoint("RIGHT", content, "RIGHT", ui.spacing.contentRight, 0)
    scrollBg:SetHeight(boxHeight)
    scrollBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    scrollBg:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    scrollBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    scrollBg:SetFrameLevel(content:GetFrameLevel() + 10)
    scrollBg:EnableMouse(true)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6)
    scrollFrame:SetFrameLevel(scrollBg:GetFrameLevel() + 1)
    scrollFrame:EnableMouseWheel(true)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(500)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
    scrollFrame:SetScrollChild(editBox)

    scrollBg:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    scrollFrame:SetScript("OnSizeChanged", function(self, width)
        editBox:SetWidth(width)
    end)

    local existing = self.savedVars and self.savedVars.data and self.savedVars.data.customConfig
    if existing then
        editBox:SetText(serializeTable(existing))
        editBox:SetCursorPosition(0)
    end

    self.customConfigEditBox = editBox
    yOffset = yOffset - boxHeight - 10

    -- Button row: [Get Current Config] [Remove Custom Config]          [Apply]
    local btnHeight = 26
    local getBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    getBtn:SetSize(140, btnHeight)
    getBtn:SetPoint("TOPLEFT", ui.spacing.controlLeft, yOffset)
    getBtn:SetText(self:L("customConfigGetCurrent"))
    getBtn:SetScript("OnClick", function()
        self:ShowCurrentConfigDialog()
    end)

    local removeBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    removeBtn:SetSize(160, btnHeight)
    removeBtn:SetPoint("LEFT", getBtn, "RIGHT", 6, 0)
    removeBtn:SetText(self:L("customConfigRemove"))
    removeBtn:SetScript("OnClick", function()
        self:RemoveCustomConfig()
    end)

    local applyBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    applyBtn:SetSize(100, btnHeight)
    applyBtn:SetPoint("RIGHT", content, "RIGHT", ui.spacing.contentRight, 0)
    applyBtn:SetPoint("TOP", getBtn, "TOP")
    applyBtn:SetText(self:L("customConfigApply"))
    applyBtn:SetScript("OnClick", function()
        self:ApplyCustomConfig()
    end)
    yOffset = yOffset - btnHeight - 10

    -- Docs button
    local docsBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    docsBtn:SetSize(80, btnHeight)
    docsBtn:SetPoint("TOPLEFT", ui.spacing.controlLeft, yOffset)
    docsBtn:SetText(self:L("customConfigDocs"))
    docsBtn:SetScript("OnClick", function()
        self:ShowCustomConfigDocs()
    end)
    yOffset = yOffset - btnHeight - 10

    content:SetHeight(math.abs(yOffset) + ui.spacing.panelBottom)
end

-- ---------------------------------------------------------------------------
-- Docs dialog
-- ---------------------------------------------------------------------------
local CUSTOM_CONFIG_DOCS_URL = "https://github.com/rokk-wow/ZenFrames/blob/main/CustomConfig.md"

function addon:ShowCustomConfigDocs()
    self:_ShowDialog({
        title = "customConfigDocsTitle",
        controls = {{
            type = "inputBox",
            name = "customConfigDocsURL",
            default = CUSTOM_CONFIG_DOCS_URL,
            highlightText = true,
            sessionOnly = true,
        }},
    })
end

-- ---------------------------------------------------------------------------
-- Get Current Config dialog
-- ---------------------------------------------------------------------------
function addon:ShowCurrentConfigDialog()
    local cfg = self:GetConfig()
    local serialized = serializeTable(cfg)

    self:_ShowDialog({
        title = "customConfigGetCurrentTitle",
        controls = {{
            type = "inputBox",
            name = "customConfigCopyHint",
            default = serialized,
            highlightText = true,
            sessionOnly = true,
        }},
    })
end

-- ---------------------------------------------------------------------------
-- Apply Custom Config
-- ---------------------------------------------------------------------------
function addon:ApplyCustomConfig()
    local inputText = self.customConfigEditBox and self.customConfigEditBox:GetText()
    if not inputText or inputText == "" then
        self:Error(self:L("customConfigEmpty"))
        return
    end

    local tbl, err = LibSerialize:Deserialize(inputText)
    if not tbl then
        self:Error(self:L("customConfigParseError") .. ": " .. tostring(err))
        return
    end

    if type(tbl) ~= "table" then
        self:Error(self:L("customConfigInvalid"))
        return
    end

    self.savedVars.data.customConfig = tbl
    ReloadUI()
end

-- ---------------------------------------------------------------------------
-- Remove Custom Config
-- ---------------------------------------------------------------------------
function addon:RemoveCustomConfig()
    if not self.savedVars.data.customConfig then
        self:Info(self:L("customConfigNoneActive"))
        return
    end

    self.savedVars.data.customConfig = nil
    ReloadUI()
end

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local BORDER_R, BORDER_G, BORDER_B, BORDER_A = 0, 1, 0.596, 0.6
local BG_R, BG_G, BG_B, BG_A = 0, 1, 0.596, 0.1
local HOVER_BORDER_A = 1.0
local HOVER_BG_A = 0.6
local BORDER_WIDTH = 1
local PADDING = 4
local LEVEL_OFFSET = 50

local placeholderGroups = {}

local function GetConfigPath(overlay)
    local path = overlay._configKey or ""
    if overlay._moduleKey then
        path = path .. "." .. overlay._moduleKey
    end
    return path
end

local function HighlightOverlay(overlay)
    overlay._bg:SetColorTexture(BG_R, BG_G, BG_B, HOVER_BG_A)
    for _, b in ipairs(overlay._borders) do
        b:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, HOVER_BORDER_A)
    end
end

local function UnhighlightOverlay(overlay)
    overlay._bg:SetColorTexture(BG_R, BG_G, BG_B, BG_A)
    for _, b in ipairs(overlay._borders) do
        b:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
    end
end

local function RegisterPlaceholder(overlay)
    local path = GetConfigPath(overlay)
    if not placeholderGroups[path] then
        placeholderGroups[path] = {}
    end
    placeholderGroups[path][overlay] = true
end

local function UnregisterPlaceholder(overlay)
    local path = GetConfigPath(overlay)
    if placeholderGroups[path] then
        placeholderGroups[path][overlay] = nil
    end
end

function addon:AttachPlaceholder(element)
    if not element or element._placeholder then return end

    function element:ShowPlaceholder(configKey, moduleKey)
        if not self._placeholder then
            local overlay = CreateFrame("Frame", nil, self)
            overlay:SetPoint("TOPLEFT", self, "TOPLEFT", -PADDING, PADDING)
            overlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", PADDING, -PADDING)
            overlay:SetFrameLevel(self:GetFrameLevel() + LEVEL_OFFSET)

            local bg = overlay:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(overlay)
            bg:SetColorTexture(BG_R, BG_G, BG_B, BG_A)

            local border = overlay:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
            border:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
            border:SetHeight(BORDER_WIDTH)
            border:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            local borderBottom = overlay:CreateTexture(nil, "BORDER")
            borderBottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
            borderBottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
            borderBottom:SetHeight(BORDER_WIDTH)
            borderBottom:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            local borderLeft = overlay:CreateTexture(nil, "BORDER")
            borderLeft:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
            borderLeft:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
            borderLeft:SetWidth(BORDER_WIDTH)
            borderLeft:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            local borderRight = overlay:CreateTexture(nil, "BORDER")
            borderRight:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
            borderRight:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
            borderRight:SetWidth(BORDER_WIDTH)
            borderRight:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            overlay:EnableMouse(false)
            overlay:SetFrameStrata("BACKGROUND")

            overlay._bg = bg
            overlay._borders = { border, borderBottom, borderLeft, borderRight }

            overlay:SetScript("OnEnter", function(self)
                local path = GetConfigPath(self)
                local group = placeholderGroups[path]
                if group then
                    for o in pairs(group) do
                        HighlightOverlay(o)
                    end
                else
                    HighlightOverlay(self)
                end
            end)

            overlay:SetScript("OnLeave", function(self)
                local path = GetConfigPath(self)
                local group = placeholderGroups[path]
                if group then
                    for o in pairs(group) do
                        UnhighlightOverlay(o)
                    end
                else
                    UnhighlightOverlay(self)
                end
            end)

            overlay:SetScript("OnMouseDown", function()
                if overlay._configKey then
                    addon:ShowEditModeSubDialog(overlay._configKey, overlay._moduleKey)
                end
            end)

            self._placeholder = overlay
        end

        local overlay = self._placeholder
        overlay._configKey = configKey
        overlay._moduleKey = moduleKey
        overlay:SetFrameStrata("DIALOG")
        overlay:EnableMouse(true)

        RegisterPlaceholder(overlay)

        if not self._savedHide then
            self._savedHide = self.Hide
            self.Hide = function() end
        end

        self:Show()
        overlay:Show()
    end

    function element:HidePlaceholder()
        if self._placeholder then
            UnregisterPlaceholder(self._placeholder)
            self._placeholder:SetFrameStrata("BACKGROUND")
            self._placeholder:EnableMouse(false)
            self._placeholder:Hide()
        end

        if self._savedHide then
            self.Hide = self._savedHide
            self._savedHide = nil
        end
    end
end

local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local resolveConfig = addon._resolveConfigForKey
local buildPath = addon._buildOverridePath

local function GetDispelIconConfig(self, configKey, moduleKey)
    local cfg = resolveConfig(configKey)
    if not cfg or not cfg.modules then return nil, nil end

    local moduleCfg = cfg.modules[moduleKey]
    if type(moduleCfg) ~= "table" then return nil, nil end

    return cfg, moduleCfg
end

local function UpdateDispelIconFrameVisual(self, unitFrame, moduleCfg)
    if not unitFrame or not moduleCfg then return end

    local dispelIconFrame = unitFrame.DispelIcon
    if not dispelIconFrame then return end

    local iconSize = moduleCfg.iconSize or dispelIconFrame:GetWidth() or 1
    local borderWidth = tonumber(moduleCfg.borderWidth) or 1
    local borderColor = moduleCfg.borderColor or "00000000"
    local backgroundColor = moduleCfg.backgroundColor or "00000000"

    dispelIconFrame:SetSize(iconSize, iconSize)

    if not dispelIconFrame.Background then
        local bg = dispelIconFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(dispelIconFrame)
        dispelIconFrame.Background = bg
    end

    local br, bg, bb, ba = self:HexToRGB(backgroundColor)
    dispelIconFrame.Background:SetColorTexture(br, bg, bb, ba or 1)

    if dispelIconFrame.Icon then
        dispelIconFrame.Icon:ClearAllPoints()
        dispelIconFrame.Icon:SetPoint("TOPLEFT", dispelIconFrame, "TOPLEFT", borderWidth, -borderWidth)
        dispelIconFrame.Icon:SetPoint("BOTTOMRIGHT", dispelIconFrame, "BOTTOMRIGHT", -borderWidth, borderWidth)
    end

    self:AddTextureBorder(dispelIconFrame, borderWidth, borderColor)

    if moduleCfg.showGlow then
        if not dispelIconFrame.ProcGlow then
            local procGlow = CreateFrame("Frame", nil, dispelIconFrame)
            procGlow:SetSize(dispelIconFrame:GetWidth() * 1.4, dispelIconFrame:GetHeight() * 1.4)
            procGlow:SetPoint("CENTER")

            local procLoop = procGlow:CreateTexture(nil, "ARTWORK")
            procLoop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
            procLoop:SetAllPoints(procGlow)
            procLoop:SetAlpha(0)

            procGlow.ProcLoopFlipbook = procLoop

            local procLoopAnim = procGlow:CreateAnimationGroup()
            procLoopAnim:SetLooping("REPEAT")

            local alpha = procLoopAnim:CreateAnimation("Alpha")
            alpha:SetChildKey("ProcLoopFlipbook")
            alpha:SetDuration(0.001)
            alpha:SetOrder(0)
            alpha:SetFromAlpha(1)
            alpha:SetToAlpha(1)

            local flip = procLoopAnim:CreateAnimation("FlipBook")
            flip:SetChildKey("ProcLoopFlipbook")
            flip:SetDuration(1)
            flip:SetOrder(0)
            flip:SetFlipBookRows(6)
            flip:SetFlipBookColumns(5)
            flip:SetFlipBookFrames(30)

            procGlow.ProcLoop = procLoopAnim
            procGlow:Hide()
            dispelIconFrame.ProcGlow = procGlow
        end

        local globalDispelColors = self.config and self.config.global and self.config.global.dispelColors or {}
        local previewGlowHex = globalDispelColors.Magic or globalDispelColors.default or "FFFFFFFF"
        local gr, gg, gb = self:HexToRGB(previewGlowHex)
        dispelIconFrame.ProcGlow.ProcLoopFlipbook:SetDesaturated(true)
        dispelIconFrame.ProcGlow.ProcLoopFlipbook:SetVertexColor(gr, gg, gb)
        dispelIconFrame.ProcGlow:SetSize(dispelIconFrame:GetWidth() * 1.4, dispelIconFrame:GetHeight() * 1.4)
        dispelIconFrame.ProcGlow:Show()
        dispelIconFrame.ProcGlow.ProcLoop:Play()
    elseif dispelIconFrame.ProcGlow then
        dispelIconFrame.ProcGlow.ProcLoop:Stop()
        dispelIconFrame.ProcGlow:Hide()
    end
end

local function RefreshDispelIconVisuals(self, configKey, moduleKey)
    self:RefreshConfig()

    local cfg, moduleCfg = GetDispelIconConfig(self, configKey, moduleKey)
    if not cfg or not moduleCfg then return end

    local container = self.groupContainers and self.groupContainers[configKey]
    if container and container.frames then
        for _, unitFrame in ipairs(container.frames) do
            UpdateDispelIconFrameVisual(self, unitFrame, moduleCfg)
        end
        return
    end

    local frameName = cfg.frameName
    if not frameName then return end

    local unitFrame = _G[frameName]
    if not unitFrame and self.unitFrames then
        for _, candidate in pairs(self.unitFrames) do
            if candidate and candidate:GetName() == frameName then
                unitFrame = candidate
                break
            end
        end
    end

    if unitFrame then
        UpdateDispelIconFrameVisual(self, unitFrame, moduleCfg)
    end
end

function addon:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    if not configKey then return end
    RefreshDispelIconVisuals(self, configKey, moduleKey or "dispelIcon")
end

function addon:PopulateDispelIconSubDialog(subDialog, configKey, moduleKey, yOffset)
    if not subDialog then return end

    local _, moduleCfg = GetDispelIconConfig(self, configKey, moduleKey)
    if not moduleCfg then return end

    subDialog._controls = subDialog._controls or {}

    local currentY = yOffset

    local onChange = function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "enabled"), value)
    end
    local enabledRow
    enabledRow, currentY = self:DialogAddEnableControl(subDialog, currentY, "emEnabled", moduleCfg.enabled, {
        onChange = onChange,
        onButtonClick = self:EditModeEnableButtonClick(configKey, moduleKey, onChange),
    })
    table.insert(subDialog._controls, enabledRow)

    local sizeRow
    sizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "emSize", 10, 100, moduleCfg.iconSize, 1, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "iconSize"), value)
        self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, sizeRow)

    local showGlowRow
    showGlowRow, currentY = self:DialogAddCheckbox(subDialog, currentY, "emShowGlow", moduleCfg.showGlow == true, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "showGlow"), value)
        self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, showGlowRow)

    local bgColorRow
    bgColorRow, currentY = self:DialogAddColorPicker(subDialog, currentY, "emBackgroundColor", moduleCfg.backgroundColor, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "backgroundColor"), value)
        self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, bgColorRow)

    local borderSizeRow
    borderSizeRow, currentY = self:DialogAddSlider(subDialog, currentY, "emBorderSize", 0, 10, moduleCfg.borderWidth, 1, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "borderWidth"), value)
        self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, borderSizeRow)

    local borderColorRow
    borderColorRow, currentY = self:DialogAddColorPicker(subDialog, currentY, "emBorderColor", moduleCfg.borderColor, function(value)
        self:SetOverride(buildPath(configKey, "modules", moduleKey, "borderColor"), value)
        self:RefreshDispelIconEditModeVisuals(configKey, moduleKey)
    end)
    table.insert(subDialog._controls, borderColorRow)
end

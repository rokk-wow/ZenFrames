local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

addon.sadCore.savedVarsGlobalName = "ZenFramesSettings_Global"
addon.sadCore.savedVarsPerCharName = "ZenFramesSettings_Char"
addon.sadCore.compartmentFuncName = "ZenFramesCompartment_Func"
addon.sadCore.releaseNotes = {
    version = "1.1.0",
    notes = {
        "release_v1_1_0_desc_1",
    }
}

local unitConfigMap = {
    player = "player",
    target = "target",
    targettarget = "targetTarget",
    focus = "focus",
    focustarget = "focusTarget",
    pet = "pet",
}

local groupConfigMap = {
    party = { "player", "party1", "party2", "party3", "party4" },
    arena = { "arena1", "arena2", "arena3" },
}

function addon:Initialize()
    self.author = "Rôkk-Wyrmrest Accord"

    self:SetupModulesSettingsPanel()
    self:SetupStyleSettingsPanel()
    self:SetupPartySettingsPanel()
    self:SetupArenaSettingsPanel()
    self:SetupCustomConfigSettingsPanel()

    self.config = self:GetCustomConfig() or self:GetConfig()
    self.unitFrames = {}

    self:OverridePowerColors()
    self:OverrideReactionColors()
    self:HookDisableBlizzard()

    self:SpawnFrames()
    self:SpawnAuraFilters()

    if self.config.auraFilterDebug and self.config.auraFilterDebug.enabled then
        self:CreateAuraFilterDebug(self.config.auraFilterDebug)
    end
end

function addon:OverridePowerColors()
    local cfg = self.config.global
    local colors = oUF.colors.power

    local powerMap = {
        { token = "MANA",        enum = Enum.PowerType.Mana,       hex = cfg.manaColor },
        { token = "RAGE",        enum = Enum.PowerType.Rage,       hex = cfg.rageColor },
        { token = "FOCUS",       enum = Enum.PowerType.Focus,      hex = cfg.focusColor },
        { token = "ENERGY",      enum = Enum.PowerType.Energy,     hex = cfg.energyColor },
        { token = "RUNIC_POWER", enum = Enum.PowerType.RunicPower, hex = cfg.runicPowerColor },
        { token = "LUNAR_POWER", enum = Enum.PowerType.LunarPower, hex = cfg.lunarPowerColor },
    }

    for _, entry in ipairs(powerMap) do
        local r, g, b = self:HexToRGB(entry.hex)
        local color = oUF:CreateColor(r, g, b)
        colors[entry.token] = color
        colors[entry.enum] = color
    end
end

function addon:OverrideReactionColors()
    local cfg = self.config.global
    local colors = oUF.colors.reaction

    for i = 1, 3 do
        local r, g, b = self:HexToRGB(cfg.hostileColor)
        colors[i] = oUF:CreateColor(r, g, b)
    end

    do
        local r, g, b = self:HexToRGB(cfg.neutralColor)
        colors[4] = oUF:CreateColor(r, g, b)
    end

    for i = 5, 8 do
        local r, g, b = self:HexToRGB(cfg.friendlyColor)
        colors[i] = oUF:CreateColor(r, g, b)
    end
end

function addon:HookDisableBlizzard()
    local originalDisableBlizzard = oUF.DisableBlizzard

    oUF.DisableBlizzard = function(oufSelf, unit)
        local configKey = unitConfigMap[unit]
        if configKey then
            local unitCfg = addon.config[configKey]
            if unitCfg and not unitCfg.hideBlizzard then
                return
            end
        end

        local groupKey = unit:match("^(%a+)%d*$")
        if groupKey and groupConfigMap[groupKey] then
            local groupCfg = addon.config[groupKey]
            if groupCfg and not groupCfg.hideBlizzard then
                return
            end
        end

        originalDisableBlizzard(oufSelf, unit)
    end
end

function addon:AddTextureBorder(frame, borderWidth, hexColor)
    borderWidth = borderWidth or 1
    local r, g, b, a = self:HexToRGB(hexColor or "000000FF")

    frame.borderTop = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.borderTop:SetColorTexture(r, g, b, a)
    frame.borderTop:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
    frame.borderTop:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.borderTop:SetHeight(borderWidth)

    frame.borderBottom = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.borderBottom:SetColorTexture(r, g, b, a)
    frame.borderBottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.borderBottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.borderBottom:SetHeight(borderWidth)

    frame.borderLeft = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.borderLeft:SetColorTexture(r, g, b, a)
    frame.borderLeft:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
    frame.borderLeft:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
    frame.borderLeft:SetWidth(borderWidth)

    frame.borderRight = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.borderRight:SetColorTexture(r, g, b, a)
    frame.borderRight:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
    frame.borderRight:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
    frame.borderRight:SetWidth(borderWidth)
end

function addon:SpawnFrames()
    oUF:Factory(function()
        for unit, configKey in pairs(unitConfigMap) do
            if addon.config[configKey].enabled then
                addon:SpawnUnitFrame(unit, configKey)
            end
        end

        if not addon.config.player.enabled then
            if PlayerFrame then PlayerFrame:Show() end
            if BuffFrame then BuffFrame:Show() end
            if DebuffFrame then DebuffFrame:Show() end
        end

        for configKey, units in pairs(groupConfigMap) do
            if addon.config[configKey] and addon.config[configKey].enabled then
                if addon.config[configKey].hideBlizzard then
                    oUF:DisableBlizzard(configKey)
                end
                addon:SpawnGroupFrames(configKey, units)
            end
        end

        addon:RegisterHighlightEvent()
    end)
end

function addon:SpawnAuraFilters()
    local filters = self.config.auraFilters
    if not filters then return end

    for _, cfg in ipairs(filters) do
        if cfg.enabled then
            self:CreateAuraFilter(cfg)
        end
    end
end

local function ApplyFontToFontString(addonInstance, fs, fontPath)
    if not fs or not fs.GetFont or not fs.SetFont then return end

    local _, size, flags = fs:GetFont()
    local resolvedSize = size or (addonInstance.config and addonInstance.config.global and addonInstance.config.global.normalFont) or 14
    local resolvedFlags = flags or "OUTLINE"

    fs:SetFont(fontPath, resolvedSize, resolvedFlags)
    fs:SetText(fs:GetText() or "")
end

local function RefreshFontsRecursively(addonInstance, rootFrame, fontPath)
    if not rootFrame then return end

    local regions = { rootFrame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            ApplyFontToFontString(addonInstance, region, fontPath)
        end
    end

    local children = { rootFrame:GetChildren() }
    for _, child in ipairs(children) do
        RefreshFontsRecursively(addonInstance, child, fontPath)
    end
end

function addon:RefreshFrameStyle(frame, fontPath, healthTex, powerTex, castbarTex, absorbTex)
    if not frame then return end

    if frame.Health and healthTex then
        frame.Health:SetStatusBarTexture(healthTex)
    end

    if frame.Power and powerTex then
        frame.Power:SetStatusBarTexture(powerTex)
    end

    if frame.Castbar then
        if castbarTex then
            frame.Castbar:SetStatusBarTexture(castbarTex)
        end
        if frame.Castbar.Text then
            local _, size, flags = frame.Castbar.Text:GetFont()
            frame.Castbar.Text:SetFont(fontPath, size, flags)
            frame.Castbar.Text:SetText(frame.Castbar.Text:GetText() or "")
        end
        if frame.Castbar.Time then
            local _, size, flags = frame.Castbar.Time:GetFont()
            frame.Castbar.Time:SetFont(fontPath, size, flags)
            frame.Castbar.Time:SetText(frame.Castbar.Time:GetText() or "")
        end
    end

    if frame.HealthPrediction and frame.HealthPrediction.damageAbsorb and absorbTex then
        frame.HealthPrediction.damageAbsorb:SetStatusBarTexture(absorbTex)
    end

    if frame.Texts then
        for _, fs in pairs(frame.Texts) do
            if fs and fs.GetFont then
                ApplyFontToFontString(self, fs, fontPath)
            end
        end
    end

    RefreshFontsRecursively(self, frame, fontPath)

    if frame.UpdateTags then
        frame:UpdateTags()
    end

    if frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshStyle")
    end
end

function addon:RefreshTextFormats(frame, textConfigs)
    if not frame or not frame.Texts or not textConfigs then return end

    for i, fs in pairs(frame.Texts) do
        local cfg = textConfigs[i]
        if fs and cfg and cfg.format then
            frame:Untag(fs)
            frame:Tag(fs, cfg.format)
        end
    end

    if frame.UpdateTags then
        frame:UpdateTags()
    end
end

function addon:RefreshStyle()
    local cfg = self.config
    local fontPath   = self:FetchFont(cfg.global.font)
    local healthTex  = self:FetchStatusbar(self:GetValue("style", "healthTexture"))
    local powerTex   = self:FetchStatusbar(self:GetValue("style", "powerTexture"))
    local castbarTex = self:FetchStatusbar(self:GetValue("style", "castbarTexture"))
    local absorbTex  = self:FetchStatusbar(self:GetValue("style", "absorbTexture"))

    if self.unitFrames then
        for unit, frame in pairs(self.unitFrames) do
            local configKey = unitConfigMap[unit]
            if configKey and cfg[configKey] and cfg[configKey].modules then
                self:RefreshTextFormats(frame, cfg[configKey].modules.text)
            end

            self:RefreshFrameStyle(frame, fontPath, healthTex, powerTex, castbarTex, absorbTex)
        end
    end

    if self.groupContainers then
        for configKey, container in pairs(self.groupContainers) do
            if container.frames then
                for _, child in ipairs(container.frames) do
                    if cfg[configKey] and cfg[configKey].modules then
                        self:RefreshTextFormats(child, cfg[configKey].modules.text)
                    end

                    self:RefreshFrameStyle(child, fontPath, healthTex, powerTex, castbarTex, absorbTex)
                end
            end
        end
    end
end



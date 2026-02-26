local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF
local CONFIG_REQUEST_DEBOUNCE_SECONDS = 0.1

addon.sadCore.savedVarsGlobalName = "ZenFramesSettings_Global"
addon.sadCore.savedVarsPerCharName = "ZenFramesSettings_Char"
addon.sadCore.compartmentFuncName = "ZenFramesCompartment_Func"

local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function deepMerge(defaults, overrides)
    local result = deepCopy(defaults)
    if type(overrides) ~= "table" then return result end
    for k, v in pairs(overrides) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = deepMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function replaceGlobalTokens(config)
    if type(config) ~= "table" then return config end

    local globals = config.global
    if type(globals) ~= "table" then return config end

    local function walk(tbl, path)
        for key, value in pairs(tbl) do
            if type(value) == "table" then
                walk(value, path .. "." .. tostring(key))
            elseif value == "_GLOBAL_" and globals[key] ~= nil then
                tbl[key] = deepCopy(globals[key])
            end
        end
    end

    for sectionKey, sectionValue in pairs(config) do
        if sectionKey ~= "global" and type(sectionValue) == "table" then
            walk(sectionValue, tostring(sectionKey))
        end
    end

    return config
end

local function setNested(tbl, keys, value)
    local current = tbl
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    current[keys[#keys]] = value
end

function addon:GetOverrides()
    if not self.savedVars then return {} end
    self.savedVars.data = self.savedVars.data or {}
    return self.savedVars.data.overrides or {}
end

function addon:SetOverride(pathSegments, value)
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.overrides = self.savedVars.data.overrides or {}
    setNested(self.savedVars.data.overrides, pathSegments, value)

    if self.editMode then
        self._editModeChangesMade = true
    end

    if pathSegments[1] == "global" then
        self._configDirty = true
        return
    end

    if self._cachedConfig then
        local resolvedValue = value
        if value == "_GLOBAL_" then
            local key = pathSegments[#pathSegments]
            if self._cachedConfig.global and self._cachedConfig.global[key] ~= nil then
                resolvedValue = deepCopy(self._cachedConfig.global[key])
            end
        end
        setNested(self._cachedConfig, pathSegments, resolvedValue)
    else
        self._configDirty = true
    end
end

function addon:ClearOverrides(pathSegments)
    if not self.savedVars or not self.savedVars.data or not self.savedVars.data.overrides then return end

    if self.editMode then
        self._editModeChangesMade = true
    end
    
    local current = self.savedVars.data.overrides
    for i = 1, #pathSegments - 1 do
        local key = pathSegments[i]
        if type(current[key]) ~= "table" then
            return
        end
        current = current[key]
    end
    
    current[pathSegments[#pathSegments]] = nil
    self._configDirty = true
end

function addon:ResetAllSettings()
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.overrides = {}
    self.savedVars.data.dismissedAnnouncements = {}
    self._configDirty = true
    ReloadUI()
end

function addon:RefreshFrame(configKey, skipElementUpdate)
    if not configKey then return end
    
    local cfg = self.config[configKey]
    if not cfg or not cfg.frameName then return end
    
    local frame = _G[cfg.frameName]
    if not frame then return end
    if InCombatLockdown() then return end

    if self.ApplyUnitFrameClickBehavior then
        if frame.frames then
            for _, child in ipairs(frame.frames) do
                self:ApplyUnitFrameClickBehavior(child, cfg)
            end
        else
            self:ApplyUnitFrameClickBehavior(frame, cfg)
        end
    end
    
    if cfg.width and cfg.height then
        frame:SetSize(cfg.width, cfg.height)

        if frame.Health then
            local powerCfg = cfg.modules and cfg.modules.power
            local powerHeight = powerCfg and powerCfg.enabled and powerCfg.height or 0
            local adjustHealth = powerCfg and powerCfg.adjustHealthbarHeight

            local healthHeight = cfg.height
            if adjustHealth and frame.Power and frame.Power:IsShown() then
                healthHeight = cfg.height - powerHeight
                frame.Power._healthOriginalHeight = cfg.height
            end
            frame.Health:SetWidth(cfg.width)
            frame.Health:SetHeight(healthHeight)
        end

        if frame.Power then
            local powerCfg = cfg.modules and cfg.modules.power
            if powerCfg and powerCfg.enabled then
                local renderWidth = math.max(1, cfg.width)
                frame.Power:SetWidth(renderWidth)
                if frame.Power._topBorder then
                    frame.Power._topBorder:SetHeight(math.max(1, borderWidth))
                    local r, g, b, a = self:HexToRGB(cfg.borderColor or "000000FF")
                    frame.Power._topBorder:SetColorTexture(r, g, b, a)
                end
            end
        end
    end

    self:AddBorder(frame, cfg)

    if cfg.modules then
        for _, moduleCfg in pairs(cfg.modules) do
            if type(moduleCfg) == "table" then
                if moduleCfg.frameName then
                    local moduleFrame = _G[moduleCfg.frameName]
                    if moduleFrame then
                        self:AddBorder(moduleFrame, moduleCfg)
                    end
                elseif moduleCfg[1] then
                    for _, filterCfg in ipairs(moduleCfg) do
                        if type(filterCfg) == "table" and filterCfg.frameName then
                            local filterFrame = _G[filterCfg.frameName]
                            if filterFrame then
                                self:AddBorder(filterFrame, {
                                    borderWidth = filterCfg.containerBorderWidth,
                                    borderColor = filterCfg.containerBorderColor,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    if frame.HighlightBorder and cfg.highlightSelected and cfg.borderWidth and cfg.borderWidth > 0 then
        local hr, hg, hb = self:HexToRGB(self.config.global.highlightColor)
        local highlightW = cfg.borderWidth + 2
        local highlightOffset = highlightW

        frame.HighlightBorder:ClearAllPoints()
        frame.HighlightBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -highlightOffset, highlightOffset)
        frame.HighlightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", highlightOffset, -highlightOffset)
        frame.HighlightBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = highlightW,
        })
        frame.HighlightBorder:SetBackdropBorderColor(hr, hg, hb, 1)
    end
    
    frame:ClearAllPoints()
    frame:SetPoint(cfg.anchor, _G[cfg.relativeTo], cfg.relativePoint, cfg.offsetX, cfg.offsetY)

    if self.UpdateArenaFrameVisibility then
        self:UpdateArenaFrameVisibility()
    end
    
    if not skipElementUpdate and frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshConfig")
    end
end

function addon:RefreshModule(configKey, moduleKey)
    if not configKey or not moduleKey then return end
    
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules[moduleKey] then return end
    
    local moduleCfg = cfg.modules[moduleKey]
    local frame
    
    -- Some modules don't have frameName (they're child elements of the unit frame)
    if moduleCfg.frameName then
        frame = _G[moduleCfg.frameName]
    else
        -- For modules without frameName, access them through the parent unit frame
        local parentFrame = self.unitFrames[configKey] or _G[cfg.frameName]
        if parentFrame then
            -- Convert moduleKey to frame property name (e.g., "combatIndicator" -> "CombatIndicator")
            local framePropertyName = moduleKey:sub(1, 1):upper() .. moduleKey:sub(2)
            frame = parentFrame[framePropertyName]
        end
    end
    
    if not frame then return end
    if InCombatLockdown() then return end
    
    if moduleCfg.width and moduleCfg.height then
        frame:SetSize(moduleCfg.width, moduleCfg.height)
    end

    if moduleCfg.frameName then
        self:AddBorder(frame, moduleCfg)
    end
    
    frame:ClearAllPoints()
    frame:SetPoint(moduleCfg.anchor, _G[moduleCfg.relativeTo], moduleCfg.relativePoint, moduleCfg.offsetX, moduleCfg.offsetY)
    
    -- Castbar-specific: update text visibility, size, and alignment
    local fontPath = moduleCfg.textSize and self:GetFontPath()
    if frame.Text then
        frame.Text:SetShown(moduleCfg.showSpellName == true)
        if fontPath then
            frame.Text:SetFont(fontPath, moduleCfg.textSize, "OUTLINE")
        end
        local align = moduleCfg.textAlignment or "LEFT"
        local padding = moduleCfg.textPadding or 4
        frame.Text:ClearAllPoints()
        if align == "CENTER" then
            frame.Text:SetPoint("CENTER", frame, "CENTER", 0, 0)
        elseif align == "RIGHT" then
            frame.Text:SetPoint("RIGHT", frame, "RIGHT", -padding, 0)
        else
            frame.Text:SetPoint("LEFT", frame, "LEFT", padding, 0)
        end
        frame.Text:SetJustifyH(align)
    end
    if frame.Time then
        frame.Time:SetShown(moduleCfg.showCastTime == true)
        if fontPath then
            frame.Time:SetFont(fontPath, moduleCfg.textSize, "OUTLINE")
        end
        local align = moduleCfg.textAlignment or "LEFT"
        frame.Time:ClearAllPoints()
        if align == "RIGHT" then
            frame.Time:SetPoint("LEFT", frame, "LEFT", 8, 0)
        else
            frame.Time:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
        end
    end
    if frame.IconFrame then
        frame.IconFrame:SetShown(moduleCfg.showIcon == true)
        frame.IconFrame:ClearAllPoints()
        local bw = moduleCfg.borderWidth or 1
        if moduleCfg.iconPosition == "RIGHT" then
            frame.IconFrame:SetPoint("LEFT", frame, "RIGHT", 2 + bw, 0)
        else
            frame.IconFrame:SetPoint("RIGHT", frame, "LEFT", -(2 + bw), 0)
        end
        self:AddBorder(frame.IconFrame, moduleCfg)
    end
    
    if frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshConfig")
    end
end

function addon:GetConfig()
    local now = GetTime and GetTime() or 0
    if not self._cachedConfig or self._configDirty then
        local mergedConfig = deepMerge(self:GetDefaultConfig(), self:GetOverrides())
        self._cachedConfig = replaceGlobalTokens(mergedConfig)
        self._configDirty = false
        self._lastConfigBuildTime = now
        return self._cachedConfig
    end

    if self._lastConfigBuildTime and (now - self._lastConfigBuildTime) < CONFIG_REQUEST_DEBOUNCE_SECONDS then
        return self._cachedConfig
    end

    return self._cachedConfig
end

function addon:RefreshConfig()
    self.config = self:GetConfig()
end

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

    self:AddSettingsPanel("main", {
        controls = {
            {
                type = "header",
                name = "editModeHeader",
            },
            {
                type = "description",
                name = "editModeDescription",
            },
            {
                type = "button",
                name = "editModeButton",
                onClick = function()
                    C_Timer.After(0, function()
                        if SettingsPanel and SettingsPanel:IsShown() then
                            HideUIPanel(SettingsPanel)
                        end
                        self:EnableEditMode()
                    end)
                end,
            },
            {
                type = "button",
                name = "resetAllButton",
                onClick = function()
                    StaticPopup_Show("ZENFRAMES_RESET_ALL_CONFIRM")
                end,
            },
        },
    })

    StaticPopupDialogs["ZENFRAMES_RESET_ALL_CONFIRM"] = {
        text = self:L("resetAllConfirmText"),
        button1 = self:L("resetAllButton"),
        button2 = "Cancel",
        OnAccept = function()
            self:ResetAllSettings()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    if self.savedVars and self.savedVars.version ~= "2.0.0" then
        wipe(self.savedVars)
        self.savedVars.version = "2.0.0"
        self.savedVars.data = { overrides = {}, dismissedAnnouncements = {} }
        self._configDirty = true
    end

    self:RefreshConfig()
    self.unitFrames = {}

    self:OverridePowerColors()
    self:OverrideReactionColors()
    self:HookDisableBlizzard()

    self:SpawnFrames()
    self:SpawnAuraFilters()

    if self.config.auraFilterDebug and self.config.auraFilterDebug.enabled then
        self:CreateAuraFilterDebug(self.config.auraFilterDebug)
    end

    C_Timer.After(1, function()
        self:ShowAnnouncement("v2.0.0")
    end)
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

    if not frame.borderTop then
        frame.borderTop = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    end
    frame.borderTop:SetColorTexture(r, g, b, a)
    frame.borderTop:ClearAllPoints()
    frame.borderTop:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
    frame.borderTop:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.borderTop:SetHeight(borderWidth)

    if not frame.borderBottom then
        frame.borderBottom = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    end
    frame.borderBottom:SetColorTexture(r, g, b, a)
    frame.borderBottom:ClearAllPoints()
    frame.borderBottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.borderBottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.borderBottom:SetHeight(borderWidth)

    if not frame.borderLeft then
        frame.borderLeft = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    end
    frame.borderLeft:SetColorTexture(r, g, b, a)
    frame.borderLeft:ClearAllPoints()
    frame.borderLeft:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, borderWidth)
    frame.borderLeft:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, -borderWidth)
    frame.borderLeft:SetWidth(borderWidth)

    if not frame.borderRight then
        frame.borderRight = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    end
    frame.borderRight:SetColorTexture(r, g, b, a)
    frame.borderRight:ClearAllPoints()
    frame.borderRight:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, borderWidth)
    frame.borderRight:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, -borderWidth)
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



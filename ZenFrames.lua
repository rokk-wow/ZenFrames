local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

addon.sadCore.savedVarsGlobalName = "ZenFramesSettings_Global"
addon.sadCore.savedVarsPerCharName = "ZenFramesSettings_Char"
addon.sadCore.compartmentFuncName = "ZenFramesCompartment_Func"
addon.sadCore.releaseNotes = {
    version = "1.2.0",
    notes = {
        "release_v1_2_0_desc_1",
    }
}

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
end

function addon:ClearOverrides(pathSegments)
    if not self.savedVars or not self.savedVars.data or not self.savedVars.data.overrides then return end
    
    local current = self.savedVars.data.overrides
    for i = 1, #pathSegments - 1 do
        local key = pathSegments[i]
        if type(current[key]) ~= "table" then
            return
        end
        current = current[key]
    end
    
    current[pathSegments[#pathSegments]] = nil
end

function addon:ResetAllSettings()
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    self.savedVars.data.overrides = {}
    ReloadUI()
end

function addon:RefreshFrame(configKey)
    if not configKey then return end
    
    local cfg = self.config[configKey]
    if not cfg or not cfg.frameName then return end
    
    local frame = _G[cfg.frameName]
    if not frame then return end
    if InCombatLockdown() then return end
    
    if cfg.width and cfg.height then
        frame:SetSize(cfg.width, cfg.height)
    end
    
    frame:ClearAllPoints()
    frame:SetPoint(cfg.anchor, _G[cfg.relativeTo], cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    
    if frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshConfig")
    end
end

function addon:RefreshModule(configKey, moduleKey)
    if not configKey or not moduleKey then return end
    
    local cfg = self.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules[moduleKey] then return end
    
    local moduleCfg = cfg.modules[moduleKey]
    if not moduleCfg.frameName then return end
    
    local frame = _G[moduleCfg.frameName]
    if not frame then return end
    if InCombatLockdown() then return end
    
    if moduleCfg.width and moduleCfg.height then
        frame:SetSize(moduleCfg.width, moduleCfg.height)
    end
    
    frame:ClearAllPoints()
    frame:SetPoint(moduleCfg.anchor, _G[moduleCfg.relativeTo], moduleCfg.relativePoint, moduleCfg.offsetX, moduleCfg.offsetY)
    
    if frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshConfig")
    end
end

function addon:GetConfig()
    return deepMerge(self:GetDefaultConfig(), self:GetOverrides())
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

    self:RunMigrations()

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



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

function addon:GetCustomConfig()
    local customConfig = self.savedVars and self.savedVars.data and self.savedVars.data.customConfig
    if customConfig then
        return deepCopy(customConfig)
    end
    return nil
end

function addon:GetConfig()
    return deepMerge(self:GetDefaultConfig(), self:GetOverrides())
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

    self:SetupCustomConfigSettingsPanel()

    -- ---------------------------------------------------------------------------
    -- Migration from legacy flat saved variables
    --
    -- Remove later - once all users with legacy settings have played at least
    -- once this is dead code.
    -- Implemented 2/22/2026 - can remove any time after 3/22/2026.
    -- ---------------------------------------------------------------------------
    self:MigrateConfig()
    -- End Migration Segment

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

-- ---------------------------------------------------------------------------
-- Migration from legacy flat saved variables
--
-- Remove later - once all users with legacy settings have played at least
-- once this is dead code.
-- Implemented 2/22/2026 - can remove any time after 3/22/2026.
-- ---------------------------------------------------------------------------
function addon:MigrateConfig()
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    if self.savedVars.data.configMigrated then return end

    local overrides = self.savedVars.data.overrides or {}
    local migrated = false

    local modules = self.savedVars.modules
    if type(modules) == "table" then
        local moduleMap = {
            playerEnabled       = "player",
            targetEnabled       = "target",
            targetTargetEnabled = "targetTarget",
            focusEnabled        = "focus",
            focusTargetEnabled  = "focusTarget",
            petEnabled          = "pet",
            partyEnabled        = "party",
            arenaEnabled        = "arena",
        }
        for setting, configKey in pairs(moduleMap) do
            if type(modules[setting]) == "boolean" then
                setNested(overrides, {configKey, "enabled"}, modules[setting])
                setNested(overrides, {configKey, "hideBlizzard"}, modules[setting])
                migrated = true
            end
        end
    end

    local style = self.savedVars.style
    if type(style) == "table" then
        if type(style.font) == "string" then
            setNested(overrides, {"global", "font"}, style.font)
            migrated = true
        end

        local allUnits = {"player", "target", "targetTarget", "focus", "focusTarget", "pet"}
        local largeUnits = {"player", "target"}
        local smallUnits = {"targetTarget", "focus", "focusTarget", "pet"}

        if type(style.healthTexture) == "string" then
            for _, key in ipairs(allUnits) do
                setNested(overrides, {key, "modules", "health", "texture"}, style.healthTexture)
            end
            migrated = true
        end

        if type(style.powerTexture) == "string" then
            for _, key in ipairs(allUnits) do
                setNested(overrides, {key, "modules", "power", "texture"}, style.powerTexture)
            end
            migrated = true
        end

        if type(style.castbarTexture) == "string" then
            for _, key in ipairs(largeUnits) do
                setNested(overrides, {key, "modules", "castbar", "texture"}, style.castbarTexture)
            end
            migrated = true
        end

        if type(style.absorbTexture) == "string" then
            for _, key in ipairs(largeUnits) do
                setNested(overrides, {key, "modules", "absorbs", "texture"}, style.absorbTexture)
            end
            migrated = true
        end

        if type(style.largeFrameLeftText) == "string" then
            for _, key in ipairs(largeUnits) do
                setNested(overrides, {key, "modules", "text", 1, "format"}, style.largeFrameLeftText)
            end
            migrated = true
        end

        if type(style.largeFrameRightText) == "string" then
            for _, key in ipairs(largeUnits) do
                setNested(overrides, {key, "modules", "text", 2, "format"}, style.largeFrameRightText)
            end
            migrated = true
        end

        if type(style.smallFrameText) == "string" then
            for _, key in ipairs(smallUnits) do
                setNested(overrides, {key, "modules", "text", 1, "format"}, style.smallFrameText)
            end
            migrated = true
        end

        if type(style.partyFrameLeftText) == "string" then
            setNested(overrides, {"party", "modules", "text", 1, "format"}, style.partyFrameLeftText)
            migrated = true
        end
        if type(style.partyFrameRightText) == "string" then
            setNested(overrides, {"party", "modules", "text", 2, "format"}, style.partyFrameRightText)
            migrated = true
        end
        if type(style.arenaFrameLeftText) == "string" then
            setNested(overrides, {"arena", "modules", "text", 1, "format"}, style.arenaFrameLeftText)
            migrated = true
        end
        if type(style.arenaFrameRightText) == "string" then
            setNested(overrides, {"arena", "modules", "text", 2, "format"}, style.arenaFrameRightText)
            migrated = true
        end
    end

    local party = self.savedVars.party
    if type(party) == "table" then
        local partyModuleMap = {
            partyTrinketEnabled         = {"party", "modules", "trinket", "enabled"},
            partyArenaTargetsEnabled    = {"party", "modules", "arenaTargets", "enabled"},
            partyCastbarEnabled         = {"party", "modules", "castbar", "enabled"},
            partyDispelIconEnabled      = {"party", "modules", "dispelIcon", "enabled"},
            partyDispelHighlightEnabled = {"party", "modules", "dispelHighlight", "enabled"},
        }
        for setting, path in pairs(partyModuleMap) do
            if type(party[setting]) == "boolean" then
                setNested(overrides, path, party[setting])
                migrated = true
            end
        end

        local partyFilterMap = {
            { enable = "partyCrowdControlEnabled",    glow = "partyCrowdControlGlow",    color = "partyCrowdControlGlowColor",    index = 3 },
            { enable = "partyDefensivesEnabled",      glow = "partyDefensivesGlow",      color = "partyDefensivesGlowColor",      index = 4 },
            { enable = "partyImportantBuffsEnabled",  glow = "partyImportantBuffsGlow",  color = "partyImportantBuffsGlowColor",  index = 5 },
        }
        for _, f in ipairs(partyFilterMap) do
            if type(party[f.enable]) == "boolean" then
                setNested(overrides, {"party", "modules", "auraFilters", f.index, "enabled"}, party[f.enable])
                migrated = true
            end
            if type(party[f.glow]) == "boolean" then
                setNested(overrides, {"party", "modules", "auraFilters", f.index, "showGlow"}, party[f.glow])
                migrated = true
            end
            if type(party[f.color]) == "string" then
                setNested(overrides, {"party", "modules", "auraFilters", f.index, "glowColor"}, party[f.color]:gsub("^#", ""))
                migrated = true
            end
        end
    end

    local arena = self.savedVars.arena
    if type(arena) == "table" then
        local arenaModuleMap = {
            arenaTrinketEnabled         = {"arena", "modules", "trinket", "enabled"},
            arenaArenaTargetsEnabled    = {"arena", "modules", "arenaTargets", "enabled"},
            arenaCastbarEnabled         = {"arena", "modules", "castbar", "enabled"},
            arenaDRTrackerEnabled       = {"arena", "modules", "drTracker", "enabled"},
            arenaDispelIconEnabled      = {"arena", "modules", "dispelIcon", "enabled"},
            arenaDispelHighlightEnabled = {"arena", "modules", "dispelHighlight", "enabled"},
        }
        for setting, path in pairs(arenaModuleMap) do
            if type(arena[setting]) == "boolean" then
                setNested(overrides, path, arena[setting])
                migrated = true
            end
        end

        local arenaFilterMap = {
            { enable = "arenaCrowdControlEnabled",    glow = "arenaCrowdControlGlow",    color = "arenaCrowdControlGlowColor",    index = 3 },
            { enable = "arenaDefensivesEnabled",      glow = "arenaDefensivesGlow",      color = "arenaDefensivesGlowColor",      index = 4 },
            { enable = "arenaImportantBuffsEnabled",  glow = "arenaImportantBuffsGlow",  color = "arenaImportantBuffsGlowColor",  index = 5 },
        }
        for _, f in ipairs(arenaFilterMap) do
            if type(arena[f.enable]) == "boolean" then
                setNested(overrides, {"arena", "modules", "auraFilters", f.index, "enabled"}, arena[f.enable])
                migrated = true
            end
            if type(arena[f.glow]) == "boolean" then
                setNested(overrides, {"arena", "modules", "auraFilters", f.index, "showGlow"}, arena[f.glow])
                migrated = true
            end
            if type(arena[f.color]) == "string" then
                setNested(overrides, {"arena", "modules", "auraFilters", f.index, "glowColor"}, arena[f.color]:gsub("^#", ""))
                migrated = true
            end
        end
    end

    if migrated then
        self.savedVars.data.overrides = overrides
    end
    self.savedVars.data.configMigrated = true
end
-- End Migration Segment

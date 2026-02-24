local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Migration code
--
-- This entire file is one-time migration logic. Remove once all users have
-- logged in at least once.
-- Latest addition: 2/23/2026 - can remove everything after 3/23/2026.
-- ---------------------------------------------------------------------------

function addon:RunMigrations()
    self:MigrateConfig()
    self:MigrateFrameNamePrefix()
    self:MigrateRemoveCustomConfig()
    self:MigrateConfigKeyRenames()
end

-- ---------------------------------------------------------------------------
-- MigratePrefixInFrameReferences
-- ---------------------------------------------------------------------------

function addon:MigratePrefixInFrameReferences(tbl)
    if type(tbl) ~= "table" then return false end

    local migrated = false
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            if self:MigratePrefixInFrameReferences(value) then
                migrated = true
            end
        elseif (key == "frameName" or key == "relativeTo") and type(value) == "string" then
            local updatedValue = value:gsub("^frmd", "zf")
            if updatedValue ~= value then
                tbl[key] = updatedValue
                migrated = true
            end
        end
    end

    return migrated
end

-- ---------------------------------------------------------------------------
-- MigrateRenameKey
-- ---------------------------------------------------------------------------

function addon:MigrateRenameKey(tbl, oldKey, newKey)
    if tbl[oldKey] ~= nil and tbl[newKey] == nil then
        tbl[newKey] = tbl[oldKey]
        tbl[oldKey] = nil
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- MigrateFrameNamePrefix - rename frmd → zf in saved overrides
-- ---------------------------------------------------------------------------

function addon:MigrateFrameNamePrefix()
    if not self.savedVars then return false end
    self.savedVars.data = self.savedVars.data or {}
    if self.savedVars.data.frameNamePrefixMigrated then return false end

    local migrated = false

    if self:MigratePrefixInFrameReferences(self.savedVars.data.overrides) then
        migrated = true
    end

    self.savedVars.data.frameNamePrefixMigrated = true
    return migrated
end

-- ---------------------------------------------------------------------------
-- MigrateRemoveCustomConfig - clear legacy custom config from saved vars
-- ---------------------------------------------------------------------------

function addon:MigrateRemoveCustomConfig()
    if not self.savedVars or not self.savedVars.data then return end
    if not self.savedVars.data.customConfig then return end

    self.savedVars.data.customConfig = nil
    self:Info(self:L("customConfigRemoved"))
end

-- ---------------------------------------------------------------------------
-- MigrateConfigKeyRenames - rename config keys in saved overrides
-- ---------------------------------------------------------------------------

local KEY_RENAMES = {
    { parent = "health",  old = "texture",         new = "healthTexture" },
    { parent = "power",   old = "texture",         new = "powerTexture" },
    { parent = "castbar", old = "texture",         new = "castbarTexture" },
    { parent = "absorbs", old = "texture",         new = "absorbTexture" },
}

local ICON_BORDER_RENAMES = {
    { old = "iconBorderWidth", new = "borderWidth" },
    { old = "iconBorderColor", new = "borderColor" },
}

local ICON_BORDER_MODULES = { "auraFilters", "dispelIcon", "trinket", "drTracker" }
local GROUP_BORDER_RENAMES = {
    { old = "unitBorderWidth", new = "borderWidth" },
    { old = "unitBorderColor", new = "borderColor" },
}

function addon:MigrateConfigKeyRenames()
    if not self.savedVars or not self.savedVars.data then return end
    if self.savedVars.data.configKeyRenamesMigrated then return end

    local overrides = self.savedVars.data.overrides
    if not overrides then
        self.savedVars.data.configKeyRenamesMigrated = true
        return
    end

    local unitKeys = {"player", "target", "targetTarget", "focus", "focusTarget", "pet", "party", "arena"}

    for _, unitKey in ipairs(unitKeys) do
        local unitOvr = overrides[unitKey]
        if type(unitOvr) == "table" and type(unitOvr.modules) == "table" then
            local mods = unitOvr.modules

            for _, rename in ipairs(KEY_RENAMES) do
                local parentTbl = mods[rename.parent]
                if type(parentTbl) == "table" then
                    self:MigrateRenameKey(parentTbl, rename.old, rename.new)
                end
            end

            for _, modKey in ipairs(ICON_BORDER_MODULES) do
                local modTbl = mods[modKey]
                if type(modTbl) == "table" then
                    if modTbl[1] then
                        for _, entry in ipairs(modTbl) do
                            if type(entry) == "table" then
                                for _, rename in ipairs(ICON_BORDER_RENAMES) do
                                    self:MigrateRenameKey(entry, rename.old, rename.new)
                                end
                            end
                        end
                    else
                        for _, rename in ipairs(ICON_BORDER_RENAMES) do
                            self:MigrateRenameKey(modTbl, rename.old, rename.new)
                        end
                    end
                end
            end
        end

        if (unitKey == "party" or unitKey == "arena") and type(unitOvr) == "table" then
            for _, rename in ipairs(GROUP_BORDER_RENAMES) do
                self:MigrateRenameKey(unitOvr, rename.old, rename.new)
            end
        end
    end

    self.savedVars.data.configKeyRenamesMigrated = true
end

-- ---------------------------------------------------------------------------
-- MigrateConfig - migrate legacy flat saved variables to overrides
-- ---------------------------------------------------------------------------

function addon:MigrateConfig()
    if not self.savedVars then return end
    self.savedVars.data = self.savedVars.data or {}
    if self.savedVars.data.configMigrated then return end

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
                self:SetOverride({configKey, "enabled"}, modules[setting])
                self:SetOverride({configKey, "hideBlizzard"}, modules[setting])
                migrated = true
            end
        end
    end

    local style = self.savedVars.style
    if type(style) == "table" then
        if type(style.font) == "string" then
            self:SetOverride({"global", "font"}, style.font)
            migrated = true
        end

        local allUnits = {"player", "target", "targetTarget", "focus", "focusTarget", "pet"}
        local largeUnits = {"player", "target"}
        local smallUnits = {"targetTarget", "focus", "focusTarget", "pet"}

        if type(style.healthTexture) == "string" then
            for _, key in ipairs(allUnits) do
                self:SetOverride({key, "modules", "health", "healthTexture"}, style.healthTexture)
            end
            migrated = true
        end

        if type(style.powerTexture) == "string" then
            for _, key in ipairs(allUnits) do
                self:SetOverride({key, "modules", "power", "powerTexture"}, style.powerTexture)
            end
            migrated = true
        end

        if type(style.castbarTexture) == "string" then
            for _, key in ipairs(largeUnits) do
                self:SetOverride({key, "modules", "castbar", "castbarTexture"}, style.castbarTexture)
            end
            migrated = true
        end

        if type(style.absorbTexture) == "string" then
            for _, key in ipairs(largeUnits) do
                self:SetOverride({key, "modules", "absorbs", "absorbTexture"}, style.absorbTexture)
            end
            migrated = true
        end

        if type(style.largeFrameLeftText) == "string" then
            for _, key in ipairs(largeUnits) do
                self:SetOverride({key, "modules", "text", 1, "format"}, style.largeFrameLeftText)
            end
            migrated = true
        end

        if type(style.largeFrameRightText) == "string" then
            for _, key in ipairs(largeUnits) do
                self:SetOverride({key, "modules", "text", 2, "format"}, style.largeFrameRightText)
            end
            migrated = true
        end

        if type(style.smallFrameText) == "string" then
            for _, key in ipairs(smallUnits) do
                self:SetOverride({key, "modules", "text", 1, "format"}, style.smallFrameText)
            end
            migrated = true
        end

        if type(style.partyFrameLeftText) == "string" then
            self:SetOverride({"party", "modules", "text", 1, "format"}, style.partyFrameLeftText)
            migrated = true
        end
        if type(style.partyFrameRightText) == "string" then
            self:SetOverride({"party", "modules", "text", 2, "format"}, style.partyFrameRightText)
            migrated = true
        end
        if type(style.arenaFrameLeftText) == "string" then
            self:SetOverride({"arena", "modules", "text", 1, "format"}, style.arenaFrameLeftText)
            migrated = true
        end
        if type(style.arenaFrameRightText) == "string" then
            self:SetOverride({"arena", "modules", "text", 2, "format"}, style.arenaFrameRightText)
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
                self:SetOverride(path, party[setting])
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
                self:SetOverride({"party", "modules", "auraFilters", f.index, "enabled"}, party[f.enable])
                migrated = true
            end
            if type(party[f.glow]) == "boolean" then
                self:SetOverride({"party", "modules", "auraFilters", f.index, "showGlow"}, party[f.glow])
                migrated = true
            end
            if type(party[f.color]) == "string" then
                self:SetOverride({"party", "modules", "auraFilters", f.index, "glowColor"}, party[f.color]:gsub("^#", ""))
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
                self:SetOverride(path, arena[setting])
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
                self:SetOverride({"arena", "modules", "auraFilters", f.index, "enabled"}, arena[f.enable])
                migrated = true
            end
            if type(arena[f.glow]) == "boolean" then
                self:SetOverride({"arena", "modules", "auraFilters", f.index, "showGlow"}, arena[f.glow])
                migrated = true
            end
            if type(arena[f.color]) == "string" then
                self:SetOverride({"arena", "modules", "auraFilters", f.index, "glowColor"}, arena[f.color]:gsub("^#", ""))
                migrated = true
            end
        end
    end

    self.savedVars.data.configMigrated = true
end

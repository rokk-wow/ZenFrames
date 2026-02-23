local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local CLASS_TOKENS = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local savedUnits = {}

local unitConfigMap = {
    player = "player",
    target = "target",
    targettarget = "targetTarget",
    focus = "focus",
    focustarget = "focusTarget",
    pet = "pet",
}

local DISPLAY_NAMES = {
    player = "Player",
    target = "Target",
    targettarget = "Target of Target",
    focus = "Focus",
    focustarget = "Focus Target",
    pet = "Pet",
    party1 = "Party 1",
    party2 = "Party 2",
    party3 = "Party 3",
    party4 = "Party 4",
    arena1 = "Arena 1",
    arena2 = "Arena 2",
    arena3 = "Arena 3",
}

local function RandomClassToken()
    return CLASS_TOKENS[math.random(#CLASS_TOKENS)]
end

local function ApplyClassColor(frame, classToken)
    if not frame.Health then return end
    local color = oUF.colors.class[classToken]
    if color then
        frame.Health:SetStatusBarColor(color:GetRGB())
    end
end

local function OverrideNameText(frame, displayName, configKey)
    if not frame.Texts or not displayName then return end
    local cfg = addon.config[configKey]
    local textConfigs = cfg and cfg.modules and cfg.modules.text
    if not textConfigs then return end

    for i, fs in pairs(frame.Texts) do
        local textCfg = textConfigs[i]
        if fs and textCfg and textCfg.format and textCfg.format:find("name") then
            fs:SetText(displayName)

            if fs.UpdateTag then
                fs._savedUpdateTag = fs.UpdateTag
                fs.UpdateTag = function() end
            end
        end
    end
end

local function RestoreNameText(frame, configKey)
    if not frame.Texts then return end
    local cfg = addon.config[configKey]
    local textConfigs = cfg and cfg.modules and cfg.modules.text
    if not textConfigs then return end

    for i, fs in pairs(frame.Texts) do
        local textCfg = textConfigs[i]
        if fs and textCfg and textCfg.format and textCfg.format:find("name") then
            if fs._savedUpdateTag then
                fs.UpdateTag = fs._savedUpdateTag
                fs._savedUpdateTag = nil
            end
        end
    end
end

local function AssignPlayerUnit(frame)
    savedUnits[frame] = frame.unit

    if not InCombatLockdown() then
        pcall(frame.SetAttribute, frame, "unit", "player")
    end
    frame.unit = "player"
end

local function RestoreOriginalUnit(frame)
    local originalUnit = savedUnits[frame]
    if not originalUnit then return end

    if not InCombatLockdown() then
        pcall(frame.SetAttribute, frame, "unit", originalUnit)
    end
    frame.unit = originalUnit
    savedUnits[frame] = nil
end

local PLACEHOLDER_ELEMENTS = {
    "Castbar",
    "Trinket",
    "CombatIndicator",
    "RestingIndicator",
    "RoleIcon",
    "DispelIcon",
    "DRTracker",
    "ArenaTargets",
}

local ELEMENT_TO_MODULE_KEY = {
    Castbar = "castbar",
    Trinket = "trinket",
    CombatIndicator = "combatIndicator",
    RestingIndicator = "restingIndicator",
    RoleIcon = "roleIcon",
    DispelIcon = "dispelIcon",
    DRTracker = "drTracker",
    ArenaTargets = "arenaTargets",
}

local function GetAuraFilterNames(configKey)
    local cfg = addon.config[configKey]
    if not cfg or not cfg.modules or not cfg.modules.auraFilters then return end
    local names = {}
    for _, filter in ipairs(cfg.modules.auraFilters) do
        if filter.name then
            names[#names + 1] = filter.name
        end
    end
    return names
end

local function ShowPlaceholders(frame, configKey)
    for _, key in ipairs(PLACEHOLDER_ELEMENTS) do
        local element = frame[key]
        if element and element.ShowPlaceholder then
            element:ShowPlaceholder(configKey, ELEMENT_TO_MODULE_KEY[key])
        end
    end

    local auraNames = GetAuraFilterNames(configKey)
    if auraNames then
        for _, name in ipairs(auraNames) do
            local filter = frame[name]
            if filter and filter.ShowPlaceholder then
                filter:ShowPlaceholder(configKey, name)
            end
        end
    end
end

local function HidePlaceholders(frame, configKey)
    for _, key in ipairs(PLACEHOLDER_ELEMENTS) do
        local element = frame[key]
        if element and element.HidePlaceholder then
            element:HidePlaceholder()
        end
    end

    local auraNames = GetAuraFilterNames(configKey)
    if auraNames then
        for _, name in ipairs(auraNames) do
            local filter = frame[name]
            if filter and filter.HidePlaceholder then
                filter:HidePlaceholder()
            end
        end
    end
end

function addon:ShowEditModeFrames()
    if InCombatLockdown() then return end
    
    for unit, frame in pairs(self.unitFrames) do
        AssignPlayerUnit(frame)
        frame:Show()

        if frame.UpdateAllElements then
            frame:UpdateAllElements("EditMode")
        end

        ApplyClassColor(frame, RandomClassToken())
        OverrideNameText(frame, DISPLAY_NAMES[unit], unitConfigMap[unit])
        ShowPlaceholders(frame, unitConfigMap[unit])

        addon:AttachPlaceholder(frame)
        frame:ShowPlaceholder(unitConfigMap[unit], nil)
    end

    if self.groupContainers then
        for configKey, container in pairs(self.groupContainers) do
            if container._visibilityFrame then
                container._visibilityFrame:UnregisterAllEvents()
            end
            container:Show()

            if container.frames then
                for _, child in ipairs(container.frames) do
                    local originalUnit = child.unit
                    child:Disable()
                    AssignPlayerUnit(child)
                    child:Show()

                    if child.UpdateAllElements then
                        child:UpdateAllElements("EditMode")
                    end

                    ApplyClassColor(child, RandomClassToken())
                    OverrideNameText(child, DISPLAY_NAMES[originalUnit] or originalUnit, configKey)
                    ShowPlaceholders(child, configKey)
                end
            end

            addon:AttachPlaceholder(container)
            container:ShowPlaceholder(configKey, nil)
        end
    end
end

function addon:HideEditModeFrames()
    if InCombatLockdown() then return end
    
    for unit, frame in pairs(self.unitFrames) do
        if frame.HidePlaceholder then
            frame:HidePlaceholder()
        end
        HidePlaceholders(frame, unitConfigMap[unit])
        RestoreNameText(frame, unitConfigMap[unit])
        RestoreOriginalUnit(frame)

        if frame.UpdateAllElements then
            frame:UpdateAllElements("EditMode")
        end
    end

    if self.groupContainers then
        for configKey, container in pairs(self.groupContainers) do
            if container.HidePlaceholder then
                container:HidePlaceholder()
            end

            if container.frames then
                for _, child in ipairs(container.frames) do
                    HidePlaceholders(child, configKey)
                    RestoreNameText(child, configKey)
                    RestoreOriginalUnit(child)
                    child:Enable()

                    if child.UpdateAllElements then
                        child:UpdateAllElements("EditMode")
                    end
                end
            end

            if container._visibilityFrame and container._visibilityEvents then
                for _, event in ipairs(container._visibilityEvents) do
                    container._visibilityFrame:RegisterEvent(event)
                end
                container._visibilityFrame:GetScript("OnEvent")(container._visibilityFrame, "PLAYER_ENTERING_WORLD")
            end
        end
    end
end

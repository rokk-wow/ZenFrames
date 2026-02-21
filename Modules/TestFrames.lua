local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local stateDrivers = {
    party = "[group] show; hide",
    arena = "[@arena1,exists] show; hide",
}

local function isModuleEnabled(addonInstance, configKey, moduleKey)
    local cfg = addonInstance.config or addonInstance:GetCustomConfig() or addonInstance:GetConfig()
    local moduleCfg = cfg and cfg[configKey] and cfg[configKey].modules and cfg[configKey].modules[moduleKey]
    if moduleCfg == nil then
        return false
    end
    return moduleCfg.enabled ~= false
end

local function getGroupConfig(addonInstance, configKey)
    local cfg = addonInstance.config or addonInstance:GetCustomConfig() or addonInstance:GetConfig()
    return cfg and cfg[configKey]
end

local function setTestUnit(frame, enable)
    if enable then
        if not frame._testOriginalUnit then
            frame._testOriginalUnit = frame.unit
        end

        if not InCombatLockdown() then
            pcall(frame.SetAttribute, frame, "unit", "player")
        end
        frame.unit = "player"
    else
        local originalUnit = frame._testOriginalUnit
        if originalUnit then
            if not InCombatLockdown() then
                pcall(frame.SetAttribute, frame, "unit", originalUnit)
            end
            frame.unit = originalUnit
        end
    end
end

local function ensureGroupModule(addonInstance, child, configKey, moduleKey)
    local groupCfg = getGroupConfig(addonInstance, configKey)
    local modules = groupCfg and groupCfg.modules
    if not modules or not modules[moduleKey] then
        return nil
    end

    if moduleKey == "trinket" and not child.Trinket then
        addonInstance:AddTrinket(child, modules.trinket)
    elseif moduleKey == "arenaTargets" and not child.ArenaTargets then
        local frameBorderW = groupCfg.unitBorderWidth or 0
        addonInstance:AddArenaTargets(child, modules.arenaTargets, frameBorderW)
    elseif moduleKey == "castbar" and not child.Castbar then
        addonInstance:AddCastbar(child, modules.castbar)
    elseif moduleKey == "drTracker" and not child.DRTracker then
        addonInstance:AddDRTracker(child, modules.drTracker)
    end

    if moduleKey == "trinket" then return child.Trinket end
    if moduleKey == "arenaTargets" then return child.ArenaTargets end
    if moduleKey == "castbar" then return child.Castbar end
    if moduleKey == "drTracker" then return child.DRTracker end
end

local function setModuleVisibility(child, moduleKey, enabled)
    if moduleKey == "trinket" and child.Trinket then
        child.Trinket._testMode = enabled or nil
        if enabled then
            child.Trinket:Show()
        else
            child.Trinket:Hide()
        end
        return
    end

    if moduleKey == "castbar" and child.Castbar then
        child.Castbar._testMode = enabled or nil
        if enabled then
            child.Castbar:Show()
        else
            child.Castbar:Hide()
        end
        return
    end

    if moduleKey == "arenaTargets" and child.ArenaTargets then
        child.ArenaTargets._testMode = enabled or nil
        if child.ArenaTargets.widget then
            if enabled then
                child.ArenaTargets.widget:Activate()
            else
                child.ArenaTargets.widget:Deactivate()
            end
        end
        if enabled then
            child.ArenaTargets:Show()
        else
            child.ArenaTargets:Hide()
        end
        return
    end

    if moduleKey == "drTracker" and child.DRTracker then
        child.DRTracker._testMode = enabled or nil
        if enabled then
            child.DRTracker:Show()
        else
            child.DRTracker:Hide()
        end
    end
end

local function resolveAnchorFrame(child, relativeToModule)
    if not relativeToModule then
        return child
    end

    if type(relativeToModule) == "table" then
        for _, key in ipairs(relativeToModule) do
            if child[key] then
                return child[key]
            end
        end
        return child
    end

    return child[relativeToModule] or child
end

local function refreshFilterAnchor(filterFrame, child, filterCfg)
    if not filterFrame or not filterCfg then return end

    local anchorFrame = child
    if filterCfg.relativeToModule then
        anchorFrame = resolveAnchorFrame(child, filterCfg.relativeToModule)
    elseif filterCfg.relativeTo and _G[filterCfg.relativeTo] then
        anchorFrame = _G[filterCfg.relativeTo]
    end

    filterFrame:ClearAllPoints()
    filterFrame:SetPoint(
        filterCfg.anchor or "CENTER",
        anchorFrame,
        filterCfg.relativePoint or "CENTER",
        filterCfg.offsetX or 0,
        filterCfg.offsetY or 0
    )
end

local function refreshAuraFilters(addonInstance, child, configKey)
    local groupCfg = getGroupConfig(addonInstance, configKey)
    local filters = groupCfg and groupCfg.modules and groupCfg.modules.auraFilters
    if not filters then return end

    for _, filterCfg in ipairs(filters) do
        local filterName = filterCfg.name
        if filterName and filterCfg.enabled == false then
            local existing = child[filterName]
            if existing and existing.Destroy then
                existing:Destroy()
            elseif existing then
                existing:Hide()
            end
            child[filterName] = nil
        elseif filterName then
            local existing = child[filterName]
            if not existing then
                existing = addonInstance:AddAuraFilter(child, filterCfg)
            end

            if existing then
                refreshFilterAnchor(existing, child, filterCfg)
                existing:Show()
                if existing.UpdateUnits then
                    existing:UpdateUnits()
                elseif existing.Refresh then
                    existing:Refresh()
                end
            end
        end
    end
end

function addon:IsTestModeEnabled(configKey)
    self.groupContainers = self.groupContainers or {}
    local container = self.groupContainers[configKey]
    return container and container._testMode == true
end

function addon:ToggleTestMode(configKey)
    if self:IsTestModeEnabled(configKey) then
        self:HideTestFrames(configKey)
        return false
    end

    self:ShowTestFrames(configKey)
    return true
end

function addon:ToggleGroupTestModes()
    local partyEnabled = self:IsTestModeEnabled("party")
    local arenaEnabled = self:IsTestModeEnabled("arena")

    if partyEnabled or arenaEnabled then
        self:HideTestFrames("party")
        self:HideTestFrames("arena")
        return false
    end

    self:ShowTestFrames("party")
    self:ShowTestFrames("arena")
    return true
end

function addon:RefreshTestFrames(configKey)
    self.groupContainers = self.groupContainers or {}
    local container = self.groupContainers[configKey]
    if not container or not container.frames or not container._testMode then return end

    local moduleStates = {
        trinket = isModuleEnabled(self, configKey, "trinket"),
        arenaTargets = isModuleEnabled(self, configKey, "arenaTargets"),
        castbar = isModuleEnabled(self, configKey, "castbar"),
        drTracker = (configKey == "arena") and isModuleEnabled(self, configKey, "drTracker"),
    }

    for _, child in ipairs(container.frames) do
        setTestUnit(child, true)
        refreshAuraFilters(self, child, configKey)

        for moduleKey, enabled in pairs(moduleStates) do
            if enabled then
                ensureGroupModule(self, child, configKey, moduleKey)
            end
            setModuleVisibility(child, moduleKey, enabled)
        end

        if child.UpdateAllElements then
            child:UpdateAllElements("RefreshTestFrames")
        end
    end
end

function addon:ShowTestFrames(configKey)
    self.groupContainers = self.groupContainers or {}
    local container = self.groupContainers[configKey]
    if not container or not container.frames then return end

    UnregisterStateDriver(container, "visibility")
    container:Show()

    for _, child in ipairs(container.frames) do
        child:Disable()
        child:Show()
        setTestUnit(child, true)
    end

    container._testMode = true
    self:RefreshTestFrames(configKey)
end

function addon:HideTestFrames(configKey)
    self.groupContainers = self.groupContainers or {}
    local container = self.groupContainers[configKey]
    if not container or not container.frames then return end

    for _, child in ipairs(container.frames) do
        setModuleVisibility(child, "trinket", false)
        setModuleVisibility(child, "arenaTargets", false)
        setModuleVisibility(child, "castbar", false)
        setModuleVisibility(child, "drTracker", false)

        local groupCfg = getGroupConfig(self, configKey)
        local filters = groupCfg and groupCfg.modules and groupCfg.modules.auraFilters
        if filters then
            for _, filterCfg in ipairs(filters) do
                local filterName = filterCfg.name
                if filterName and child[filterName] then
                    child[filterName]:Hide()
                end
            end
        end

        setTestUnit(child, false)
        if child.UpdateAllElements then
            child:UpdateAllElements("RefreshTestFrames")
        end

        child:Enable()
    end

    local driver = stateDrivers[configKey]
    if driver then
        RegisterStateDriver(container, "visibility", driver)
    end

    container._testMode = false
end

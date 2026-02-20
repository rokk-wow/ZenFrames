local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local stateDrivers = {
    party = "[group] show; hide",
    arena = "[@arena1,exists] show; hide",
}

function addon:ShowTestFrames(configKey)
    self.groupContainers = self.groupContainers or {}
    local container = self.groupContainers[configKey]
    if not container or not container.frames then return end

    UnregisterStateDriver(container, "visibility")
    container:Show()

    for _, child in ipairs(container.frames) do
        child:Disable()
        child:Show()

        if child.Health then
            child.Health:SetMinMaxValues(0, 1)
            child.Health:SetValue(1)
        end

        if child.Power then
            child.Power:SetMinMaxValues(0, 1)
            child.Power:SetValue(1)
            child.Power:Show()
        end

        if child.Trinket then
            child.Trinket:Show()
            child.Trinket._testMode = true
            if not child.Trinket._testBackground then
                child.Trinket._testBackground = child.Trinket:CreateTexture(nil, "BACKGROUND", nil, -8)
                child.Trinket._testBackground:SetAllPoints(child.Trinket)
            end
            child.Trinket._testBackground:SetColorTexture(0.5, 0.2, 0.5, 0.4)
            child.Trinket._testBackground:Show()
        end

        if child.DRTracker then
            child.DRTracker:Show()
            child.DRTracker._testMode = true
        end

        if child.ArenaTargets then
            if child.ArenaTargets.widget then
                child.ArenaTargets.widget:Activate()
                
                if child.ArenaTargets.widget.indicators then
                    for i, indicator in ipairs(child.ArenaTargets.widget.indicators) do
                        indicator:Show()
                        if indicator.Inner then
                            indicator.Inner:SetColorTexture(1, 1, 1, 0.5)
                        end
                    end
                end
            end
            child.ArenaTargets:Show()
            child.ArenaTargets._testMode = true
        end

        if child.Castbar then
            child.Castbar:Show()
            child.Castbar._testMode = true
            if not child.Castbar._testBackground then
                child.Castbar._testBackground = child.Castbar:CreateTexture(nil, "BACKGROUND", nil, -8)
                child.Castbar._testBackground:SetAllPoints(child.Castbar)
            end
            child.Castbar._testBackground:SetColorTexture(0.2, 0.2, 0.4, 0.4)
            child.Castbar._testBackground:Show()
        end
    end

    container._testMode = true
end

function addon:HideTestFrames(configKey)
    self.groupContainers = self.groupContainers or {}
    local container = self.groupContainers[configKey]
    if not container or not container.frames then return end

    for _, child in ipairs(container.frames) do
        if child.Trinket and child.Trinket._testMode then
            child.Trinket._testMode = nil
            if child.Trinket._testBackground then
                child.Trinket._testBackground:Hide()
            end
            child.Trinket:Hide()
        end

        if child.DRTracker and child.DRTracker._testMode then
            child.DRTracker._testMode = nil
            child.DRTracker:Hide()
        end

        if child.ArenaTargets and child.ArenaTargets._testMode then
            child.ArenaTargets._testMode = nil
            if child.ArenaTargets.widget then
                if child.ArenaTargets.widget.indicators then
                    for _, indicator in ipairs(child.ArenaTargets.widget.indicators) do
                        indicator:Hide()
                    end
                end
                child.ArenaTargets.widget:Deactivate()
            end
        end

        if child.Castbar and child.Castbar._testMode then
            child.Castbar._testMode = nil
            if child.Castbar._testBackground then
                child.Castbar._testBackground:Hide()
            end
            child.Castbar:Hide()
        end
        child:Enable()
    end

    local driver = stateDrivers[configKey]
    if driver then
        RegisterStateDriver(container, "visibility", driver)
    end

    container._testMode = false
end

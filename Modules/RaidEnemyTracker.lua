local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local trackerFrame

local function RaidDebugPrint(...)
    print("ZenFrames:", ...)
end

local function IsRelevantPvpRaid()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "pvp" then
        return false
    end

    if not IsInRaid() then
        return false
    end

    local groupSize = GetNumGroupMembers() or 0
    return groupSize > 5
end

local function IsPveRaid()
    if not IsInRaid() then
        return false
    end

    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return true
    end

    return instanceType ~= "pvp"
end

function addon:ResetRaidEnemyTrackerState()
    self._raidEnemyTracker = {
        sourceUnits = {
            target = nil,
            focus = nil,
            mouseover = nil,
        },
        nameplateUnits = {},
        orderedUnits = {},
    }
end

local function EnsureTrackerState(self)
    if not self._raidEnemyTracker then
        self:ResetRaidEnemyTrackerState()
    end
    return self._raidEnemyTracker
end

function addon:RefreshRaidEnemyOrdering()
    local state = EnsureTrackerState(self)
    local ordered = {}
    local seen = {}

    local function IsTrackableEnemyUnit(unit)
        if not unit then
            return false
        end
        if not UnitExists(unit) then
            return false
        end
        if not UnitCanAttack("player", unit) then
            return false
        end
        if not UnitIsPlayer(unit) then
            return false
        end
        return true
    end

    local function PushUnit(unit)
        if not unit or seen[unit] then
            return
        end
        if not IsTrackableEnemyUnit(unit) then
            return
        end
        seen[unit] = true
        ordered[#ordered + 1] = unit
    end

    PushUnit(state.sourceUnits.target)
    PushUnit(state.sourceUnits.focus)
    PushUnit(state.sourceUnits.mouseover)

    local nameplates = {}
    for unit in pairs(state.nameplateUnits) do
        nameplates[#nameplates + 1] = unit
    end
    table.sort(nameplates)
    for _, unit in ipairs(nameplates) do
        PushUnit(unit)
    end

    state.orderedUnits = ordered

    if state._lastOrderedCount ~= #ordered then
        state._lastOrderedCount = #ordered
        local first = ordered[1] or "none"
        local second = ordered[2] or "none"
        RaidDebugPrint("enemy units", #ordered, first, second)
    end

    if self.UpdateRaidFrameVisibility then
        self:UpdateRaidFrameVisibility()
    elseif self.UpdateRaidEnemyProfileUnits then
        local stateSnapshot = self.GetRaidRoutingState and self:GetRaidRoutingState() or nil
        self:UpdateRaidEnemyProfileUnits(stateSnapshot and stateSnapshot.activeEnemyProfile)
    end
end

function addon:RefreshRaidEnemyScoreboard()
    if IsPveRaid() then
        self:ResetRaidEnemyTrackerState()
        if self.UpdateRaidFrameVisibility then
            self:UpdateRaidFrameVisibility()
        end
        return
    end

    if not IsRelevantPvpRaid() then
        self:ResetRaidEnemyTrackerState()
        if self.UpdateRaidFrameVisibility then
            self:UpdateRaidFrameVisibility()
        end
        return
    end
    self:RefreshRaidEnemyOrdering()
end

function addon:UpdateRaidEnemyUnitSource(unit, source)
    if not unit or not source then
        return
    end

    local state = EnsureTrackerState(self)
    if not IsRelevantPvpRaid() then
        return
    end

    if not UnitExists(unit) then
        return
    end

    if not UnitCanAttack("player", unit) or not UnitIsPlayer(unit) then
        return
    end

    if source == "nameplate" then
        state.nameplateUnits[unit] = true
    elseif state.sourceUnits[source] ~= nil then
        state.sourceUnits[source] = unit
    end

    self:RefreshRaidEnemyOrdering()
end

function addon:ClearRaidEnemyUnitSource(unit, source)
    if not unit then
        return
    end

    if not IsRelevantPvpRaid() then
        return
    end

    local state = EnsureTrackerState(self)

    if source then
        if source == "nameplate" then
            state.nameplateUnits[unit] = nil
        elseif state.sourceUnits[source] == unit then
            state.sourceUnits[source] = nil
        end
    else
        state.nameplateUnits[unit] = nil
        for key, value in pairs(state.sourceUnits) do
            if value == unit then
                state.sourceUnits[key] = nil
            end
        end
    end

    self:RefreshRaidEnemyOrdering()
end

function addon:GetRaidEnemyUnits(maxUnits)
    local state = EnsureTrackerState(self)
    local units = {}
    local limit = maxUnits or #state.orderedUnits

    for i = 1, math.min(limit, #state.orderedUnits) do
        units[#units + 1] = state.orderedUnits[i]
    end

    return units
end

function addon:GetRaidEnemyUnitAt(index)
    local state = EnsureTrackerState(self)
    if not index or index < 1 then
        return nil
    end
    return state.orderedUnits[index]
end

function addon:GetRaidEnemyRosterCount()
    local state = EnsureTrackerState(self)
    return #state.orderedUnits
end

function addon:InitializeRaidEnemyTracker()
    if trackerFrame then
        return
    end

    self:ResetRaidEnemyTrackerState()

    trackerFrame = CreateFrame("Frame")
    trackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    trackerFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    trackerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    trackerFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
    trackerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    trackerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    trackerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    trackerFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    trackerFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

    trackerFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "ZONE_CHANGED_NEW_AREA"
            or event == "GROUP_ROSTER_UPDATE"
            or event == "UPDATE_BATTLEFIELD_SCORE" then
            addon:RefreshRaidEnemyScoreboard()
            return
        end

        if event == "NAME_PLATE_UNIT_ADDED" then
            local unit = ...
            addon:UpdateRaidEnemyUnitSource(unit, "nameplate")
            return
        end

        if event == "NAME_PLATE_UNIT_REMOVED" then
            local unit = ...
            addon:ClearRaidEnemyUnitSource(unit, "nameplate")
            return
        end

        if event == "PLAYER_TARGET_CHANGED" then
            addon:ClearRaidEnemyUnitSource("target", "target")
            addon:UpdateRaidEnemyUnitSource("target", "target")
            return
        end

        if event == "PLAYER_FOCUS_CHANGED" then
            addon:ClearRaidEnemyUnitSource("focus", "focus")
            addon:UpdateRaidEnemyUnitSource("focus", "focus")
            return
        end

        if event == "UPDATE_MOUSEOVER_UNIT" then
            addon:ClearRaidEnemyUnitSource("mouseover", "mouseover")
            addon:UpdateRaidEnemyUnitSource("mouseover", "mouseover")
        end
    end)

    self._raidEnemyTrackerFrame = trackerFrame
end

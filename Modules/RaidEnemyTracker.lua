local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local trackerFrame
local scoreboardRetryTicker

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
        slotAssignments = {},
        unitToSlot = {},
        liveUnits = {},
        slotMeta = {},
        _maxSlot = 0,
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

    state.slotAssignments = state.slotAssignments or {}
    state.unitToSlot = state.unitToSlot or {}
    state._maxSlot = state._maxSlot or 0

    state.liveUnits = {}
    for _, unit in ipairs(ordered) do
        state.liveUnits[unit] = true
    end

    state.slotMeta = state.slotMeta or {}
    for _, unit in ipairs(ordered) do
        if not state.unitToSlot[unit] then
            local assignedSlot = nil
            local _, _, classToken = UnitClass(unit)
            if classToken then
                for slot = 1, state._maxSlot do
                    local meta = state.slotMeta[slot]
                    if meta and meta.source == "scoreboard" and meta.classToken == classToken then
                        local currentUnit = state.slotAssignments[slot]
                        if not currentUnit or not state.liveUnits[currentUnit] then
                            local prevKey = state.slotAssignments[slot]
                            if prevKey then
                                state.unitToSlot[prevKey] = nil
                            end
                            state.slotAssignments[slot] = unit
                            state.unitToSlot[unit] = slot
                            meta.source = "nameplate"
                            assignedSlot = slot
                            break
                        end
                    end
                end
            end

            if not assignedSlot then
                state._maxSlot = state._maxSlot + 1
                state.slotAssignments[state._maxSlot] = unit
                state.unitToSlot[unit] = state._maxSlot
                assignedSlot = state._maxSlot
            end

            if classToken and assignedSlot then
                state.slotMeta[assignedSlot] = state.slotMeta[assignedSlot] or {}
                state.slotMeta[assignedSlot].classToken = classToken
                if state.slotMeta[assignedSlot].source == nil then
                    state.slotMeta[assignedSlot].source = "nameplate"
                end
            end
        else
            local slot = state.unitToSlot[unit]
            if slot and not state.slotMeta[slot] then
                local _, _, classToken = UnitClass(unit)
                if classToken then
                    state.slotMeta[slot] = { classToken = classToken, source = "nameplate" }
                end
            end
        end
    end

    if state._lastOrderedCount ~= #ordered then
        state._lastOrderedCount = #ordered
        local first = ordered[1] or "none"
        local second = ordered[2] or "none"
    end

    if self.UpdateRaidFrameVisibility then
        self:UpdateRaidFrameVisibility()
    elseif self.UpdateRaidEnemyProfileUnits then
        local stateSnapshot = self.GetRaidRoutingState and self:GetRaidRoutingState() or nil
        self:UpdateRaidEnemyProfileUnits(stateSnapshot and stateSnapshot.activeEnemyProfile)
    end
end

function addon:RefreshRaidEnemyScoreboard()
    self:ResetRaidEnemyTrackerState()

    if IsPveRaid() then
        if self.UpdateRaidFrameVisibility then
            self:UpdateRaidFrameVisibility()
        end
        return
    end

    if not IsRelevantPvpRaid() then
        if self.UpdateRaidFrameVisibility then
            self:UpdateRaidFrameVisibility()
        end
        return
    end

    local state = EnsureTrackerState(self)
    for i = 1, 40 do
        local np = "nameplate" .. i
        if UnitExists(np) and UnitCanAttack("player", np) and UnitIsPlayer(np) then
            state.nameplateUnits[np] = true
        end
    end

    self:ScanScoreboardEnemies()
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
    local unit = state.slotAssignments and state.slotAssignments[index]
    if unit and state.liveUnits and state.liveUnits[unit] then
        return unit
    end
    return nil
end

function addon:IsRaidEnemySlotOccupied(index)
    local state = EnsureTrackerState(self)
    if not index or index < 1 then
        return false
    end
    return state.slotAssignments ~= nil and state.slotAssignments[index] ~= nil
end

function addon:GetRaidEnemyRosterCount()
    local state = EnsureTrackerState(self)
    return state._maxSlot or 0
end

function addon:GetRaidEnemySlotMeta(index)
    local state = EnsureTrackerState(self)
    if not index or index < 1 then
        return nil
    end
    return state.slotMeta and state.slotMeta[index]
end

function addon:ScanScoreboardEnemies()
    local state = EnsureTrackerState(self)
    if not IsRelevantPvpRaid() then
        return
    end

    if InCombatLockdown() then
        return
    end

    local numScores = GetNumBattlefieldScores and GetNumBattlefieldScores() or 0
    if numScores == 0 then
        return
    end

    local playerFaction = GetBattlefieldArenaFaction and GetBattlefieldArenaFaction() or UnitFactionGroup("player")
    local scoreboardEnemies = {}

    for i = 1, numScores do
        local info = C_PvP and C_PvP.GetScoreInfo and C_PvP.GetScoreInfo(i)
        if info and info.faction ~= nil and info.classToken then
            local isEnemy = false
            if type(playerFaction) == "number" then
                isEnemy = info.faction ~= playerFaction
            else
                local factionTag = (info.faction == 0) and "Horde" or "Alliance"
                isEnemy = factionTag ~= playerFaction
            end
            if isEnemy then
                scoreboardEnemies[#scoreboardEnemies + 1] = info.classToken
            end
        end
    end

    table.sort(scoreboardEnemies)

    state.slotMeta = state.slotMeta or {}
    local existingClasses = {}
    for slot = 1, state._maxSlot do
        local meta = state.slotMeta[slot]
        if meta and meta.classToken then
            existingClasses[meta.classToken] = (existingClasses[meta.classToken] or 0) + 1
        end
    end

    for _, classToken in ipairs(scoreboardEnemies) do
        existingClasses[classToken] = (existingClasses[classToken] or 0) - 1
        if existingClasses[classToken] < 0 then
            existingClasses[classToken] = 0
            state._maxSlot = state._maxSlot + 1
            local placeholderKey = "scoreboard_" .. state._maxSlot
            state.slotAssignments[state._maxSlot] = placeholderKey
            state.unitToSlot[placeholderKey] = state._maxSlot
            state.slotMeta[state._maxSlot] = { classToken = classToken, source = "scoreboard" }
        end
    end
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
    trackerFrame:RegisterEvent("PVP_MATCH_ACTIVE")
    trackerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    trackerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    trackerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    trackerFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    trackerFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

    trackerFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "ZONE_CHANGED_NEW_AREA"
            or event == "GROUP_ROSTER_UPDATE"
            or event == "UPDATE_BATTLEFIELD_SCORE"
            or event == "PVP_MATCH_ACTIVE" then
            if event ~= "UPDATE_BATTLEFIELD_SCORE" and IsRelevantPvpRaid() and RequestBattlefieldScoreData then
                RequestBattlefieldScoreData()
            end
            addon:RefreshRaidEnemyScoreboard()
            addon:StartScoreboardRetryIfNeeded()
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

function addon:StartScoreboardRetryIfNeeded()
    if scoreboardRetryTicker then return end
    if not IsRelevantPvpRaid() then return end

    local rosterCount = self:GetRaidEnemyRosterCount()
    if rosterCount > 0 then return end

    scoreboardRetryTicker = C_Timer.NewTicker(3, function()
        if not IsRelevantPvpRaid() then
            scoreboardRetryTicker:Cancel()
            scoreboardRetryTicker = nil
            return
        end

        if RequestBattlefieldScoreData then
            RequestBattlefieldScoreData()
        end

        local count = addon:GetRaidEnemyRosterCount()
        if count > 0 then
            scoreboardRetryTicker:Cancel()
            scoreboardRetryTicker = nil
        end
    end)
end

function addon:StopScoreboardRetry()
    if scoreboardRetryTicker then
        scoreboardRetryTicker:Cancel()
        scoreboardRetryTicker = nil
    end
end

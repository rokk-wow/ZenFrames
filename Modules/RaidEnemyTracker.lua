-- ---------------------------------------------------------------------------
-- RaidEnemyTracker — enemy detection for battleground/blitz/epic BG frames
-- ---------------------------------------------------------------------------
local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local trackerFrame
local scanTicker
local scoreboardRetryTicker

-- ---------------------------------------------------------------------------
-- Guard functions
-- ---------------------------------------------------------------------------

local function IsRelevantPvpGroup()
    local inInstance, instanceType = IsInInstance()
    if instanceType ~= "pvp" then return false end
    if not IsInGroup() then return false end
    return GetNumGroupMembers() > 5
end

local function GetPlayerFaction()
    local faction = GetBattlefieldArenaFaction()
    if faction == nil then return nil, nil end
    local enemyFaction = (faction == 0) and 1 or 0
    return faction, enemyFaction
end

-- ---------------------------------------------------------------------------
-- PID Calculation Engine
-- ---------------------------------------------------------------------------

local PID_ClassTokenToID = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    MONK = 10,
    DRUID = 11,
    DEMONHUNTER = 12,
    EVOKER = 13,
}

local PID_RaceTokenToID = {}
local PID_RaceMapBuilt = false

local function EnsureRaceMap()
    if PID_RaceMapBuilt then return end
    local playableRaces = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
        22, 25, 27, 28, 29, 30, 31, 32, 34, 35, 36, 37, 52, 84, 85, 86,
    }
    for i = 1, #playableRaces do
        local raceInfo = C_CreatureInfo.GetRaceInfo(playableRaces[i])
        if raceInfo then
            if raceInfo.clientFileString then
                PID_RaceTokenToID[raceInfo.clientFileString] = raceInfo.raceID
            end
            if raceInfo.raceName then
                PID_RaceTokenToID[raceInfo.raceName] = raceInfo.raceID
            end
        end
    end
    PID_RaceTokenToID["Undead"] = PID_RaceTokenToID["Scourge"] or 5
    PID_RaceTokenToID["Earthen"] = PID_RaceTokenToID["EarthenDwarf"] or 85
    PID_RaceMapBuilt = true
end

local PID_CollapseMap = {
    [24] = 25,
    [26] = 25,
    [70] = 52,
    [84] = 85,
    [91] = 86,
}

local guidInfoCache = {}

local function GetCachedPlayerInfo(guid)
    local cached = guidInfoCache[guid]
    if cached then
        return cached[1], cached[2]
    end
    local _, _, _, englishRaceName, gender = GetPlayerInfoByGUID(guid)
    if gender then
        guidInfoCache[guid] = { englishRaceName, gender }
    end
    return englishRaceName, gender
end

local function CalculatePID(raceID, classID, gender, honorLevel)
    if not classID then
        return 0, 0, 0, 0, 0
    end
    local classPID = classID * 65536
    local genderComponent = (gender or 0) * 4294967296
    local classGenderPID = genderComponent + classPID
    if not raceID then
        return 0, 0, 0, classGenderPID, classPID
    end
    local collapsedRaceID = PID_CollapseMap[raceID] or raceID
    if not collapsedRaceID then
        return 0, 0, 0, classGenderPID, classPID
    end
    local corePID = (collapsedRaceID * 16777216) + classPID
    local basePID = genderComponent + corePID
    local honor = (honorLevel and honorLevel > 0) and honorLevel or 0
    return basePID + honor, basePID, corePID, classGenderPID, classPID
end

local function UnitPID(unitID)
    if not UnitExists(unitID) then
        return 0, 0, 0, 0, 0
    end
    local _, _, raceID = UnitRace(unitID)
    local _, _, classID = UnitClass(unitID)
    local gender = UnitSex(unitID)
    if not classID then
        return 0, 0, 0, 0, 0
    end
    if classID == 1 and (not raceID or raceID == 0) then
        return 0, 0, 0, 0, 0
    end
    local unitHonor = UnitHonorLevel(unitID)
    return CalculatePID(raceID, classID, gender, unitHonor)
end

local function RosterPID(rosterEntry)
    EnsureRaceMap()
    local raceID = PID_RaceTokenToID[rosterEntry.raceName or ""]
        or PID_RaceTokenToID[rosterEntry.englishRace or ""]
        or 0
    local classID = PID_ClassTokenToID[rosterEntry.classToken or ""] or 0
    if raceID == 0 then raceID = nil end
    if classID == 0 then classID = nil end
    local gender = rosterEntry.gender
    if not gender and rosterEntry.guid then
        local _, cachedGender = GetCachedPlayerInfo(rosterEntry.guid)
        gender = cachedGender
    end
    return CalculatePID(raceID, classID, gender, rosterEntry.honorLevel)
end

-- ---------------------------------------------------------------------------
-- Roster persistence across /reload
-- ---------------------------------------------------------------------------

local function SaveRosterToSavedVars()
    if not addon.savedVarsChar then return end

    local state = addon._raidEnemyTracker
    if not state or state.rosterCount == 0 then
        addon.savedVarsChar.raidEnemyRoster = nil
        return
    end

    local saved = {
        roster = {},
        slotMeta = {},
        rosterCount = state.rosterCount,
        allyFaction = state.allyFaction,
        enemyFaction = state.enemyFaction,
    }

    for i, entry in ipairs(state.roster) do
        saved.roster[i] = {
            name = entry.name,
            classToken = entry.classToken,
            raceName = entry.raceName,
            englishRace = entry.englishRace,
            faction = entry.faction,
            honorLevel = entry.honorLevel,
            guid = entry.guid,
            talentSpec = entry.talentSpec,
            role = entry.role,
            gender = entry.gender,
            realmName = entry.realmName,
        }
    end

    for i, meta in pairs(state.slotMeta) do
        saved.slotMeta[i] = {
            classToken = meta.classToken,
            raceName = meta.raceName,
            gender = meta.gender,
            honorLevel = meta.honorLevel,
            name = meta.name,
            talentSpec = meta.talentSpec,
        }
    end

    addon.savedVarsChar.raidEnemyRoster = saved
end

local function RestoreRosterFromSavedVars()
    if not addon.savedVarsChar then return false end

    local saved = addon.savedVarsChar.raidEnemyRoster
    if not saved or not saved.rosterCount or saved.rosterCount == 0 then return false end

    local state = addon._raidEnemyTracker
    if not state then return false end

    state.rosterCount = saved.rosterCount
    state.allyFaction = saved.allyFaction
    state.enemyFaction = saved.enemyFaction

    for i, entry in ipairs(saved.roster) do
        state.roster[i] = entry
        if entry.name then
            state.rosterByName[entry.name] = i
        end
    end

    for i, meta in pairs(saved.slotMeta) do
        state.slotMeta[i] = meta
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Roster state management
-- ---------------------------------------------------------------------------

function addon:ResetRaidEnemyTrackerState()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeResetRaidEnemyTrackerState")

    wipe(guidInfoCache)

    if scanCycleCache then wipe(scanCycleCache) end

    self._raidEnemyTracker = {
        roster = {},
        rosterByName = {},
        unitAssignments = {},
        unitPriority = {},
        slotMeta = {},
        rosterCount = 0,
        scoreboardFrozen = false,
        lobbyRosterCaptured = false,
        allyFaction = nil,
        enemyFaction = nil,
    }

    callHook(self, "AfterResetRaidEnemyTrackerState", true)
    return true
end

-- ---------------------------------------------------------------------------
-- API functions consumed by UnitFrame.lua
-- ---------------------------------------------------------------------------

function addon:GetRaidEnemyUnitAt(index)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeGetRaidEnemyUnitAt", index)

    local state = self._raidEnemyTracker
    if not state then
        callHook(self, "AfterGetRaidEnemyUnitAt", nil)
        return nil
    end

    local unit = state.unitAssignments[index]
    if unit and UnitExists(unit) then
        callHook(self, "AfterGetRaidEnemyUnitAt", unit)
        return unit
    end

    callHook(self, "AfterGetRaidEnemyUnitAt", nil)
    return nil
end

function addon:GetRaidEnemyRosterCount()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeGetRaidEnemyRosterCount")

    local state = self._raidEnemyTracker
    if not state then
        callHook(self, "AfterGetRaidEnemyRosterCount", 0)
        return 0
    end

    local count = state.rosterCount
    callHook(self, "AfterGetRaidEnemyRosterCount", count)
    return count
end

function addon:IsRaidEnemySlotOccupied(index)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeIsRaidEnemySlotOccupied", index)

    local state = self._raidEnemyTracker
    if not state then
        callHook(self, "AfterIsRaidEnemySlotOccupied", false)
        return false
    end

    local occupied = state.roster[index] ~= nil
    callHook(self, "AfterIsRaidEnemySlotOccupied", occupied)
    return occupied
end

function addon:GetRaidEnemySlotMeta(index)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeGetRaidEnemySlotMeta", index)

    local state = self._raidEnemyTracker
    if not state then
        callHook(self, "AfterGetRaidEnemySlotMeta", nil)
        return nil
    end

    local meta = state.slotMeta[index]
    callHook(self, "AfterGetRaidEnemySlotMeta", meta)
    return meta
end

-- ---------------------------------------------------------------------------
-- Scoreboard Parsing (Step 3)
-- ---------------------------------------------------------------------------

local function ParseScoreboardEntry(index)
    local scoreInfo = C_PvP.GetScoreInfo(index)
    if not scoreInfo then return nil end

    local name = scoreInfo.name
    if name ~= nil and issecretvalue and issecretvalue(name) then
        return nil
    end

    local entry = {
        name = name,
        faction = scoreInfo.faction,
        classToken = scoreInfo.classToken,
        raceName = scoreInfo.raceName,
        honorLevel = scoreInfo.honorLevel,
        guid = scoreInfo.guid,
        talentSpec = scoreInfo.talentSpec,
        role = scoreInfo.roleAssigned,
    }

    if scoreInfo.guid then
        local ok, _, _, _, englishRace, sex, _, realmName = pcall(GetPlayerInfoByGUID, scoreInfo.guid)
        if ok then
            entry.englishRace = englishRace
            entry.gender = sex
            entry.realmName = realmName
        end
    end

    return entry
end

local function GetExpectedEnemyCount()
    local _, _, _, _, maxPlayers = GetInstanceInfo()
    if not maxPlayers or maxPlayers == 0 then return 0 end
    return math.floor(maxPlayers / 2)
end

function addon:RefreshEnemyFrames()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeRefreshEnemyFrames")

    if self.UpdateRaidFrameVisibility then
        self:UpdateRaidFrameVisibility()
    end

    callHook(self, "AfterRefreshEnemyFrames", true)
    return true
end

function addon:ScanScoreboardEnemies()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeScanScoreboardEnemies")

    local state = self._raidEnemyTracker
    if not state then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    if state.scoreboardFrozen then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    if not IsRelevantPvpGroup() then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    local numScores = GetNumBattlefieldScores()
    if not numScores or numScores == 0 then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    local testInfo = C_PvP.GetScoreInfo(1)
    if testInfo and testInfo.name ~= nil and issecretvalue and issecretvalue(testInfo.name) then
        state.scoreboardFrozen = true
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    if state.lobbyRosterCaptured then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    local allyFaction, enemyFaction = GetPlayerFaction()
    if not allyFaction then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end
    state.allyFaction = allyFaction
    state.enemyFaction = enemyFaction

    local playerName = UnitName("player")

    local newEnemies = {}
    for i = 1, numScores do
        local entry = ParseScoreboardEntry(i)
        if entry and entry.faction and entry.classToken then
            if entry.name and entry.name == playerName and entry.faction == enemyFaction then
                allyFaction = enemyFaction
                enemyFaction = (allyFaction == 0) and 1 or 0
                state.allyFaction = allyFaction
                state.enemyFaction = enemyFaction
            end
        end
    end

    for i = 1, numScores do
        local entry = ParseScoreboardEntry(i)
        if entry and entry.faction == state.enemyFaction and entry.classToken then
            newEnemies[#newEnemies + 1] = entry
        end
    end

    if #newEnemies < state.rosterCount then
        callHook(self, "AfterScanScoreboardEnemies", false)
        return false
    end

    local existingByGUID = {}
    for slotIndex, rosterEntry in ipairs(state.roster) do
        if rosterEntry.guid then
            existingByGUID[rosterEntry.guid] = slotIndex
        end
    end

    local nextSlot = state.rosterCount + 1
    for _, entry in ipairs(newEnemies) do
        local existingSlot = entry.guid and existingByGUID[entry.guid] or nil
        if existingSlot then
            state.roster[existingSlot] = entry
            state.slotMeta[existingSlot] = {
                classToken = entry.classToken,
                raceName = entry.raceName or entry.englishRace,
                gender = entry.gender,
                honorLevel = entry.honorLevel,
                name = entry.name,
                talentSpec = entry.talentSpec,
            }
            if entry.name then
                state.rosterByName[entry.name] = existingSlot
            end
        else
            local alreadySlotted = false
            if entry.name then
                local nameSlot = state.rosterByName[entry.name]
                if nameSlot then
                    state.roster[nameSlot] = entry
                    state.slotMeta[nameSlot] = {
                        classToken = entry.classToken,
                        raceName = entry.raceName or entry.englishRace,
                        gender = entry.gender,
                        honorLevel = entry.honorLevel,
                        name = entry.name,
                        talentSpec = entry.talentSpec,
                    }
                    alreadySlotted = true
                end
            end
            if not alreadySlotted then
                state.roster[nextSlot] = entry
                state.slotMeta[nextSlot] = {
                    classToken = entry.classToken,
                    raceName = entry.raceName or entry.englishRace,
                    gender = entry.gender,
                    honorLevel = entry.honorLevel,
                    name = entry.name,
                    talentSpec = entry.talentSpec,
                }
                if entry.name then
                    state.rosterByName[entry.name] = nextSlot
                end
                if entry.guid then
                    existingByGUID[entry.guid] = nextSlot
                end
                nextSlot = nextSlot + 1
            end
        end
    end

    state.rosterCount = nextSlot - 1

    local expectedCount = GetExpectedEnemyCount()
    if expectedCount > 0 and state.rosterCount >= expectedCount then
        state.lobbyRosterCaptured = true
    end

    self:RefreshEnemyFrames()

    callHook(self, "AfterScanScoreboardEnemies", true)
    return true
end

function addon:StartScoreboardRetryIfNeeded()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeStartScoreboardRetryIfNeeded")

    if scoreboardRetryTicker then
        scoreboardRetryTicker:Cancel()
        scoreboardRetryTicker = nil
    end

    scoreboardRetryTicker = C_Timer.NewTicker(3, function()
        if not IsRelevantPvpGroup() then
            if scoreboardRetryTicker then
                scoreboardRetryTicker:Cancel()
                scoreboardRetryTicker = nil
            end
            return
        end

        local state = addon._raidEnemyTracker
        if state and state.lobbyRosterCaptured then
            if scoreboardRetryTicker then
                scoreboardRetryTicker:Cancel()
                scoreboardRetryTicker = nil
            end
            return
        end

        RequestBattlefieldScoreData()
    end)

    callHook(self, "AfterStartScoreboardRetryIfNeeded", true)
    return true
end

function addon:StopScoreboardRetry()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeStopScoreboardRetry")

    if scoreboardRetryTicker then
        scoreboardRetryTicker:Cancel()
        scoreboardRetryTicker = nil
    end

    callHook(self, "AfterStopScoreboardRetry", true)
    return true
end

-- ---------------------------------------------------------------------------
-- PID Matching + Unit Assignment (Step 4)
-- ---------------------------------------------------------------------------

local UNIT_PRIORITY = {
    target = 1,
    focus = 2,
    mouseover = 3,
    nameplate = 4,
    other = 5,
}

local scanCycleCache = {}

local function ClearScanCycleCache()
    wipe(scanCycleCache)
end

local function AssignUnitToSlot(state, slotIndex, unitID, priorityKey)
    local currentPriority = state.unitPriority[slotIndex]
    local newPriority = UNIT_PRIORITY[priorityKey] or UNIT_PRIORITY.other

    if currentPriority and currentPriority < newPriority then
        return false
    end

    local currentUnit = state.unitAssignments[slotIndex]
    if currentUnit == unitID and currentPriority == newPriority then
        return false
    end

    state.unitAssignments[slotIndex] = unitID
    state.unitPriority[slotIndex] = newPriority
    return true
end

local function GetRosterSlotByUnitID(state, unitID)
    if not state or state.rosterCount == 0 then return nil end
    if not unitID or not UnitExists(unitID) then return nil end

    EnsureRaceMap()

    local cached = scanCycleCache[unitID]
    if cached ~= nil then
        return cached or nil
    end

    local okGUID, unitGUID = pcall(UnitGUID, unitID)
    if okGUID and unitGUID and not (issecretvalue and issecretvalue(unitGUID)) then
        for slotIndex, rosterEntry in ipairs(state.roster) do
            if rosterEntry.guid and rosterEntry.guid == unitGUID then
                scanCycleCache[unitID] = slotIndex
                return slotIndex
            end
        end
    end

    local targetPID, targetBasePID, targetCorePID, targetClassGenderPID, targetClassPID = UnitPID(unitID)

    if targetClassPID == 0 then
        scanCycleCache[unitID] = false
        return nil
    end

    local candidates = {}
    local baseCandidates = {}
    local coreCandidates = {}
    local classGenderCandidates = {}
    local classCandidates = {}

    for slotIndex, rosterEntry in ipairs(state.roster) do
        local candidatePID, candidateBasePID, candidateCorePID, candidateClassGenderPID, candidateClassPID =
            RosterPID(rosterEntry)

        if candidatePID > 0 and candidatePID == targetPID then
            candidates[#candidates + 1] = slotIndex
        elseif candidateBasePID > 0 and candidateBasePID == targetBasePID and targetBasePID > 0 then
            baseCandidates[#baseCandidates + 1] = slotIndex
        elseif candidateCorePID > 0 and candidateCorePID == targetCorePID and targetCorePID > 0 then
            coreCandidates[#coreCandidates + 1] = slotIndex
        elseif candidateClassGenderPID > 0 and candidateClassGenderPID == targetClassGenderPID and targetClassGenderPID > 0 then
            classGenderCandidates[#classGenderCandidates + 1] = slotIndex
        elseif candidateClassPID > 0 and candidateClassPID == targetClassPID then
            classCandidates[#classCandidates + 1] = slotIndex
        end
    end

    if #candidates == 0 and #baseCandidates > 0 then
        candidates = baseCandidates
    end
    if #candidates == 0 and #coreCandidates > 0 then
        candidates = coreCandidates
    end
    if #candidates == 0 and #classGenderCandidates > 0 then
        candidates = classGenderCandidates
    end
    if #candidates == 0 and #classCandidates > 0 then
        candidates = classCandidates
    end

    local result = nil

    if #candidates == 1 then
        result = candidates[1]
    elseif #candidates > 1 then
        local okName, targetServer = pcall(function()
            local _, s = UnitName(unitID)
            return s
        end)
        if okName and targetServer and not (issecretvalue and issecretvalue(targetServer)) and targetServer ~= "" then
            for _, slotIndex in ipairs(candidates) do
                local entry = state.roster[slotIndex]
                if entry.realmName and entry.realmName ~= "" and entry.realmName == targetServer then
                    result = slotIndex
                    break
                end
            end
        end

        if not result then
            local unitRole = UnitGroupRolesAssigned(unitID)
            if unitRole and unitRole ~= "NONE" then
                local roleMatches = {}
                for _, slotIndex in ipairs(candidates) do
                    local entry = state.roster[slotIndex]
                    if entry.role and entry.role == unitRole then
                        roleMatches[#roleMatches + 1] = slotIndex
                    end
                end
                if #roleMatches == 1 then
                    result = roleMatches[1]
                end
            end
        end

        if not result then
            local unitHonor = UnitHonorLevel(unitID)
            if unitHonor and unitHonor > 0 then
                for _, slotIndex in ipairs(candidates) do
                    local entry = state.roster[slotIndex]
                    if entry.honorLevel and entry.honorLevel == unitHonor then
                        result = slotIndex
                        break
                    end
                end
            end
        end

        if not result then
            result = candidates[1]
        end
    end

    scanCycleCache[unitID] = result or false
    return result
end

-- ---------------------------------------------------------------------------
-- Pre-built unit token tables
-- ---------------------------------------------------------------------------

local raidTargetUnits = {}
for i = 1, 40 do raidTargetUnits[i] = "raid" .. i .. "target" end

local partyTargetUnits = {}
for i = 1, 4 do partyTargetUnits[i] = "party" .. i .. "target" end

local nameplateUnits = {}
for i = 1, 40 do nameplateUnits[i] = "nameplate" .. i end

-- ---------------------------------------------------------------------------
-- Unit Scanning (Step 5)
-- ---------------------------------------------------------------------------

local function IsEnemyPlayer(unitID)
    return UnitExists(unitID) and UnitCanAttack("player", unitID) and UnitIsPlayer(unitID)
end

local function ClearVolatileAssignments(state)
    wipe(state.unitAssignments)
    wipe(state.unitPriority)
end

local function ClearUnitFromSlots(state, unitID)
    for slotIndex, assignedUnit in pairs(state.unitAssignments) do
        if assignedUnit == unitID then
            state.unitAssignments[slotIndex] = nil
            state.unitPriority[slotIndex] = nil
            return slotIndex
        end
    end
    return nil
end

local function ClearPriorityFromSlots(state, priorityKey)
    local priorityValue = UNIT_PRIORITY[priorityKey]
    if not priorityValue then return end
    for slotIndex, currentPriority in pairs(state.unitPriority) do
        if currentPriority == priorityValue then
            state.unitAssignments[slotIndex] = nil
            state.unitPriority[slotIndex] = nil
        end
    end
end

local function ScanEnemyUnits()
    local state = addon._raidEnemyTracker
    if not state or state.rosterCount == 0 then return end
    if not IsRelevantPvpGroup() then return end

    ClearScanCycleCache()
    ClearVolatileAssignments(state)

    local changed = false

    if IsEnemyPlayer("target") then
        local slotIndex = GetRosterSlotByUnitID(state, "target")
        if slotIndex then
            if AssignUnitToSlot(state, slotIndex, "target", "target") then
                changed = true
            end
        end
    end

    if IsEnemyPlayer("focus") then
        local slotIndex = GetRosterSlotByUnitID(state, "focus")
        if slotIndex then
            if AssignUnitToSlot(state, slotIndex, "focus", "focus") then
                changed = true
            end
        end
    end

    local numMembers = GetNumGroupMembers()
    if IsInRaid() then
        for i = 1, numMembers do
            local unit = raidTargetUnits[i]
            if unit and IsEnemyPlayer(unit) then
                local slotIndex = GetRosterSlotByUnitID(state, unit)
                if slotIndex and not state.unitAssignments[slotIndex] then
                    state.slotSeen = state.slotSeen or {}
                    state.slotSeen[slotIndex] = true
                    changed = true
                end
            end
        end
    else
        for i = 1, 4 do
            local unit = partyTargetUnits[i]
            if unit and IsEnemyPlayer(unit) then
                local slotIndex = GetRosterSlotByUnitID(state, unit)
                if slotIndex and not state.unitAssignments[slotIndex] then
                    state.slotSeen = state.slotSeen or {}
                    state.slotSeen[slotIndex] = true
                    changed = true
                end
            end
        end
    end

    for i = 1, 40 do
        local unit = nameplateUnits[i]
        if UnitExists(unit) and IsEnemyPlayer(unit) then
            local slotIndex = GetRosterSlotByUnitID(state, unit)
            if slotIndex then
                if AssignUnitToSlot(state, slotIndex, unit, "nameplate") then
                    changed = true
                end
            end
        end
    end

    if changed then
        addon:RefreshEnemyFrames()
    end
end

function addon:StartEnemyUnitScan()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeStartEnemyUnitScan")

    if scanTicker then
        scanTicker:Cancel()
        scanTicker = nil
    end

    scanTicker = C_Timer.NewTicker(0.25, ScanEnemyUnits)

    callHook(self, "AfterStartEnemyUnitScan", true)
    return true
end

function addon:StopEnemyUnitScan()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeStopEnemyUnitScan")

    if scanTicker then
        scanTicker:Cancel()
        scanTicker = nil
    end

    callHook(self, "AfterStopEnemyUnitScan", true)
    return true
end

-- ---------------------------------------------------------------------------
-- Event Handlers (Step 5)
-- ---------------------------------------------------------------------------

local function HandleZoneEnter()
    addon:ResetRaidEnemyTrackerState()

    if IsRelevantPvpGroup() then
        local restored = RestoreRosterFromSavedVars()

        local allyFaction, enemyFaction = GetPlayerFaction()
        local state = addon._raidEnemyTracker
        if state and allyFaction then
            state.allyFaction = allyFaction
            state.enemyFaction = enemyFaction
        end
        RequestBattlefieldScoreData()
        addon:StartScoreboardRetryIfNeeded()
        addon:StartEnemyUnitScan()

        if restored then
            addon:RefreshEnemyFrames()
        end
    else
        addon:StopEnemyUnitScan()
        addon:StopScoreboardRetry()
        addon:RefreshEnemyFrames()
        if addon.savedVarsChar then
            addon.savedVarsChar.raidEnemyRoster = nil
        end
    end
end

local function HandleNameplateAdded(unitID)
    if not IsEnemyPlayer(unitID) then return end

    local state = addon._raidEnemyTracker
    if not state or state.rosterCount == 0 then return end

    ClearScanCycleCache()
    local slotIndex = GetRosterSlotByUnitID(state, unitID)
    if slotIndex and AssignUnitToSlot(state, slotIndex, unitID, "nameplate") then
        addon:RefreshEnemyFrames()
    end
end

local function HandleNameplateRemoved(unitID)
    local state = addon._raidEnemyTracker
    if not state then return end

    local cleared = ClearUnitFromSlots(state, unitID)
    if cleared then
        addon:RefreshEnemyFrames()
    end
end

local function HandleDirectUnitChanged(priorityKey, unitID)
    local state = addon._raidEnemyTracker
    if not state or state.rosterCount == 0 then return end

    ClearScanCycleCache()
    ClearPriorityFromSlots(state, priorityKey)

    if unitID and IsEnemyPlayer(unitID) then
        local slotIndex = GetRosterSlotByUnitID(state, unitID)
        if slotIndex then
            AssignUnitToSlot(state, slotIndex, unitID, priorityKey)
        end
    end

    addon:RefreshEnemyFrames()
end

local function HandlePvpMatchStateChanged()
    local state = addon._raidEnemyTracker
    if not state then return end

    local matchState = C_PvP.GetActiveMatchState()

    if matchState == Enum.PvPMatchState.Engaged then
        if state.lobbyRosterCaptured then
            state.scoreboardFrozen = true
        end
    elseif matchState == Enum.PvPMatchState.Complete or matchState == Enum.PvPMatchState.PostRound then
        state.scoreboardFrozen = false
        state.lobbyRosterCaptured = false
        addon:ScanScoreboardEnemies()
    elseif matchState == Enum.PvPMatchState.Inactive then
        state.scoreboardFrozen = false
        state.lobbyRosterCaptured = false
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeRaidEnemyTracker()
    local callHook = self.callHook or function() end
    callHook(self, "BeforeInitializeRaidEnemyTracker")

    self:ResetRaidEnemyTrackerState()

    trackerFrame = CreateFrame("Frame")
    trackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    trackerFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    trackerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    trackerFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
    trackerFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
    trackerFrame:RegisterEvent("PVP_MATCH_ACTIVE")
    trackerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    trackerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    trackerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    trackerFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    trackerFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    trackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    trackerFrame:RegisterEvent("PLAYER_LOGOUT")

    trackerFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            HandleZoneEnter()

        elseif event == "GROUP_ROSTER_UPDATE" then
            if IsRelevantPvpGroup() then
                RequestBattlefieldScoreData()
                addon:StartScoreboardRetryIfNeeded()
                addon:StartEnemyUnitScan()
            end

        elseif event == "UPDATE_BATTLEFIELD_SCORE" then
            addon:ScanScoreboardEnemies()

        elseif event == "PVP_MATCH_STATE_CHANGED" or event == "PVP_MATCH_ACTIVE" then
            HandlePvpMatchStateChanged()

        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitID = ...
            HandleNameplateAdded(unitID)

        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            local unitID = ...
            HandleNameplateRemoved(unitID)

        elseif event == "PLAYER_TARGET_CHANGED" then
            HandleDirectUnitChanged("target", "target")

        elseif event == "PLAYER_FOCUS_CHANGED" then
            HandleDirectUnitChanged("focus", "focus")

        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            HandleDirectUnitChanged("mouseover", "mouseover")

        elseif event == "PLAYER_REGEN_ENABLED" then
            addon:RefreshEnemyFrames()

        elseif event == "PLAYER_LOGOUT" then
            SaveRosterToSavedVars()
        end
    end)

    callHook(self, "AfterInitializeRaidEnemyTracker", true)
    return true
end

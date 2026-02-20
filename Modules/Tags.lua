local addonName, ns = ...
local oUF = ns.oUF
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function GetName(unit)
    local ok, name = pcall(UnitName, unit)
    if not ok then return nil end
    local safe, _ = pcall(tostring, name)
    if not safe then return nil end
    return name
end

oUF.Tags.Methods['name:short'] = function(unit, realUnit)
    return GetName(realUnit or unit)
end
oUF.Tags.Events['name:short'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['name:medium'] = function(unit, realUnit)
    return GetName(realUnit or unit)
end
oUF.Tags.Events['name:medium'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['name:long'] = function(unit, realUnit)
    return GetName(realUnit or unit)
end
oUF.Tags.Events['name:long'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['name:abbrev'] = function(unit, realUnit)
    return GetName(realUnit or unit)
end
oUF.Tags.Events['name:abbrev'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['name:trunc'] = function(unit, realUnit, ...)
    return GetName(realUnit or unit)
end
oUF.Tags.Events['name:trunc'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['curhp:short'] = function(unit)
    return AbbreviateNumbers(UnitHealth(unit))
end
oUF.Tags.Events['curhp:short'] = 'UNIT_HEALTH UNIT_MAXHEALTH'

oUF.Tags.Methods['maxhp:short'] = function(unit)
    return AbbreviateNumbers(UnitHealthMax(unit))
end
oUF.Tags.Events['maxhp:short'] = 'UNIT_MAXHEALTH'

oUF.Tags.Methods['hp:percent'] = function(unit)
    return string.format('%d%%', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
end
oUF.Tags.Events['hp:percent'] = 'UNIT_HEALTH UNIT_MAXHEALTH'

oUF.Tags.Methods['hp:cur-percent'] = function(unit)
    local cur = AbbreviateNumbers(UnitHealth(unit))
    local pct = string.format('%d', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
    return cur .. ' - ' .. pct .. '%'
end
oUF.Tags.Events['hp:cur-percent'] = 'UNIT_HEALTH UNIT_MAXHEALTH'

oUF.Tags.Methods['hp:cur-max'] = function(unit)
    local cur = AbbreviateNumbers(UnitHealth(unit))
    local max = AbbreviateNumbers(UnitHealthMax(unit))
    return cur .. ' / ' .. max
end
oUF.Tags.Events['hp:cur-max'] = 'UNIT_HEALTH UNIT_MAXHEALTH'

oUF.Tags.Methods['hp:deficit'] = function(unit)
    local deficit = UnitHealthMissing(unit)
    if deficit and deficit > 0 then
        return '-' .. AbbreviateNumbers(deficit)
    end
end
oUF.Tags.Events['hp:deficit'] = 'UNIT_HEALTH UNIT_MAXHEALTH'

oUF.Tags.Methods['curpp:short'] = function(unit)
    local cur = UnitPower(unit)
    if cur and cur > 0 then
        return AbbreviateNumbers(cur)
    end
end
oUF.Tags.Events['curpp:short'] = 'UNIT_POWER_UPDATE UNIT_MAXPOWER'

oUF.Tags.Methods['maxpp:short'] = function(unit)
    return AbbreviateNumbers(UnitPowerMax(unit))
end
oUF.Tags.Events['maxpp:short'] = 'UNIT_MAXPOWER'

oUF.Tags.Methods['pp:percent'] = function(unit)
    return string.format('%d%%', UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100))
end
oUF.Tags.Events['pp:percent'] = 'UNIT_POWER_UPDATE UNIT_MAXPOWER'

oUF.Tags.Methods['pp:cur-percent'] = function(unit)
    local cur = AbbreviateNumbers(UnitPower(unit))
    local pct = string.format('%d', UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100))
    return cur .. ' - ' .. pct .. '%'
end
oUF.Tags.Events['pp:cur-percent'] = 'UNIT_POWER_UPDATE UNIT_MAXPOWER'

oUF.Tags.Methods['pp:cur-max'] = function(unit)
    local cur = AbbreviateNumbers(UnitPower(unit))
    local max = AbbreviateNumbers(UnitPowerMax(unit))
    return cur .. ' / ' .. max
end
oUF.Tags.Events['pp:cur-max'] = 'UNIT_POWER_UPDATE UNIT_MAXPOWER'

oUF.Tags.SharedEvents.INSPECT_READY = true

local inspectQueue = {}
local inspectPending = false
local specCache = {}
local inspectFrame = CreateFrame("Frame")

local function ProcessInspectQueue()
    if inspectPending then return end
    while #inspectQueue > 0 do
        local unit = table.remove(inspectQueue, 1)
        if UnitExists(unit) and UnitIsConnected(unit)
           and not UnitIsUnit(unit, 'player')
           and not InCombatLockdown() then
            local guid = UnitGUID(unit)
            if guid and specCache[guid] then
            else
                inspectPending = true
                NotifyInspect(unit)
                return
            end
        end
    end
end

local function PruneCache()
    local activeGUIDs = {}
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then activeGUIDs[guid] = true end
        end
    end
    for guid in pairs(specCache) do
        if not activeGUIDs[guid] then
            specCache[guid] = nil
        end
    end
end

inspectFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
inspectFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "INSPECT_READY" then
        local guid = ...
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and UnitGUID(unit) == guid then
                local specId = GetInspectSpecialization(unit)
                if specId and specId > 0 then
                    specCache[guid] = specId
                end
                break
            end
        end
        inspectPending = false
        ProcessInspectQueue()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        PruneCache()
        table.wipe(inspectQueue)
        inspectPending = false
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                local guid = UnitGUID(unit)
                if not guid or not specCache[guid] then
                    table.insert(inspectQueue, unit)
                end
            end
        end
        if #inspectQueue > 0 then
            ProcessInspectQueue()
        end
    end
end)

oUF.Tags.Methods['spec'] = function(unit)
    local specId

    if UnitIsUnit(unit, 'player') then
        local specIndex = C_SpecializationInfo.GetSpecialization()
        if specIndex then
            specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        end
    else
        local arenaIndex = unit:match('arena(%d)$')
        if arenaIndex then
            specId = GetArenaOpponentSpec(tonumber(arenaIndex))
        else
            local guid = UnitGUID(unit)
            if guid and specCache[guid] then
                specId = specCache[guid]
            elseif GetInspectSpecialization then
                specId = GetInspectSpecialization(unit)
            end
        end
    end

    if specId and specId > 0 then
        local abbrev = addon.config.global.specAbbrevById[specId]
        if abbrev then return abbrev end
    end
    return ''
end
oUF.Tags.Events['spec'] = 'ARENA_PREP_OPPONENT_SPECIALIZATIONS ARENA_OPPONENT_UPDATE GROUP_ROSTER_UPDATE PLAYER_SPECIALIZATION_CHANGED INSPECT_READY'

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:BuildRaidUnitTokens(maxUnits)
    local units = {}
    for i = 1, maxUnits do
        units[i] = "raid" .. i
    end
    return units
end

function addon:BuildNameplateUnitTokens(maxUnits)
    local units = {}
    for i = 1, maxUnits do
        units[i] = "nameplate" .. i
    end
    return units
end

-- Raid profile routing: instance-based for PVP, group-size-based for PVE.
-- PVP: uses instance max group size (fixed at entry) to select profile immediately.
-- PVE: raid profile when in a raid group, party frames for small groups.
function addon:GetRaidRoutingState()
    local raidCfg = self.config and self.config.raid

    if not raidCfg then
        return { showParty = false, activeFriendlyProfile = nil }
    end

    if not IsInGroup() then
        return { showParty = false, activeFriendlyProfile = nil }
    end

    local inInstance, instanceType = IsInInstance()

    -- PVP instances: profile determined by instance max group size (known at entry)
    if inInstance and instanceType == "pvp" then
        local routing = raidCfg.routing or {}
        local pvp  = routing.pvp or {}
        local epic = pvp.epicBattleground or {}
        local bg   = pvp.battleground or {}
        local blz  = pvp.blitz or {}

        local instanceGroupSize = select(9, GetInstanceInfo()) or 0
        if instanceGroupSize == 0 then
            instanceGroupSize = select(5, GetInstanceInfo()) or 0
        end
        if instanceGroupSize == 0 then
            instanceGroupSize = GetNumGroupMembers() or 0
        end

        local profile
        if instanceGroupSize >= (epic.minRaidSize or 26) then
            profile = epic.profile or "epicBattleground"
        elseif instanceGroupSize >= (bg.minRaidSize or 9) then
            profile = bg.profile or "battleground"
        else
            profile = blz.profile or "blitz"
        end

        local profiles = raidCfg.profiles or {}
        local profileCfg = profiles[profile]
        local friendlyEnabled = profileCfg and profileCfg.friendly and profileCfg.friendly.enabled
        local enemyEnabled = profileCfg and profileCfg.enemy and profileCfg.enemy.enabled

        if not friendlyEnabled and not enemyEnabled then
            return { showParty = false, activeFriendlyProfile = nil, activeEnemyProfile = nil }
        end

        return {
            showParty = false,
            activeFriendlyProfile = friendlyEnabled and profile or nil,
            activeEnemyProfile = enemyEnabled and profile or nil,
        }
    end

    local routing   = raidCfg.routing or {}
    local threshold = routing.usePartyWhenGroupSizeAtOrBelow or 5
    local groupSize = GetNumGroupMembers() or 0

    -- Below threshold → party frames
    if groupSize <= threshold then
        return { showParty = true, activeFriendlyProfile = nil }
    end

    -- PVE: raid profile when in a raid group
    if IsInRaid() then
        local raidRoute = routing.raid or {}
        local profile   = raidRoute.profile or "raid"
        local profiles = raidCfg.profiles or {}
        local profileCfg = profiles[profile]
        local friendlyEnabled = profileCfg and profileCfg.friendly and profileCfg.friendly.enabled

        if not friendlyEnabled then
            return { showParty = true, activeFriendlyProfile = nil }
        end

        return { showParty = false, activeFriendlyProfile = profile }
    end

    -- Non-raid group above threshold (e.g. dungeon party) → party frames
    return { showParty = true, activeFriendlyProfile = nil }
end

function addon:GetBattlegroundTeamSize()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "pvp" then
        return 0
    end

    local bgTeamSizes = self.config and self.config.global and self.config.global.bgTeamSizes
    local bgName = select(1, GetInstanceInfo())
    if bgName and bgTeamSizes and bgTeamSizes[bgName] then
        return bgTeamSizes[bgName]
    end

    print("[ZenFrames] No battleground team size defined for: " .. tostring(bgName))
    return 0
end

function addon:CreateRaidSlotPlaceholders(container)
    if not container or not container.frames then
        return false
    end

    container._zfSlotPlaceholders = container._zfSlotPlaceholders or {}

    for i, child in ipairs(container.frames) do
        if child and not container._zfSlotPlaceholders[i] then
            local placeholder = CreateFrame("Frame", nil, container)
            placeholder:SetSize(child:GetWidth(), child:GetHeight())
            placeholder:SetFrameLevel(math.max(0, child:GetFrameLevel() - 2))
            placeholder:SetAllPoints(child)

            local bg = placeholder:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0, 0, 0, 0.5)

            placeholder:Hide()
            container._zfSlotPlaceholders[i] = placeholder
        end
    end

    return true
end

function addon:UpdateRaidSlotPlaceholders()
    if not self.groupContainers then
        return false
    end

    local state = self:GetRaidRoutingState()
    local activeProfile = state.activeFriendlyProfile
    local activeEnemyProfile = state.activeEnemyProfile
    local teamSize = 0

    if activeProfile and self.pvpFriendlyProfiles[activeProfile] then
        teamSize = self:GetBattlegroundTeamSize()
    end

    for containerKey, container in pairs(self.groupContainers) do
        if container._zfSlotPlaceholders then
            local profile, side
            if type(containerKey) == "string" then
                profile, side = containerKey:match("^raid_([%w]+)_(%w+)$")
            end

            if profile and side then
                local isActive
                if side == "friendly" then
                    isActive = (profile == activeProfile) and self.pvpFriendlyProfiles[profile] and teamSize > 0
                elseif side == "enemy" then
                    isActive = (profile == activeEnemyProfile) and self.pvpFriendlyProfiles[profile] and teamSize > 0
                end

                for i, ph in pairs(container._zfSlotPlaceholders) do
                    if isActive and i <= teamSize then
                        ph:Show()
                    else
                        ph:Hide()
                    end
                end
            end
        end
    end

    return true
end

function addon:UpdateRaidEnemyProfileUnits(activeEnemyProfile)
    if not self.groupContainers then
        return
    end

    local activeContainerKey = activeEnemyProfile and ("raid_" .. activeEnemyProfile .. "_enemy") or nil
    local container = activeContainerKey and self.groupContainers[activeContainerKey]
    if not container or not container.frames then
        return
    end

    local raidCfg = self.config and self.config.raid
    local profileCfg = raidCfg and raidCfg.profiles and raidCfg.profiles[activeEnemyProfile]
    local enemyCfg = profileCfg and profileCfg.enemy
    if not enemyCfg then
        return
    end

    local fallbackUnits = self:BuildNameplateUnitTokens(enemyCfg.maxUnits or #container.frames)
    local rosterCount = self.GetRaidEnemyRosterCount and self:GetRaidEnemyRosterCount() or 0
    local outOfRangeAlpha = enemyCfg.outOfRangeOpacity or 0.5
    local inCombat = InCombatLockdown()

    self._zfEnemyNameOverrides = self._zfEnemyNameOverrides or {}
    wipe(self._zfEnemyNameOverrides)

    if inCombat then
        self._zfPendingRaidEnemyUnitSync = true
        self._zfRaidEnemyPendingProfile = activeEnemyProfile
    else
        self._zfPendingRaidEnemyUnitSync = false
        self._zfRaidEnemyPendingProfile = nil
    end

    for i, child in ipairs(container.frames) do
        local unit = self.GetRaidEnemyUnitAt and self:GetRaidEnemyUnitAt(i) or nil
        local currentUnit = child and child:GetAttribute("unit")

        local slotOccupied = self.IsRaidEnemySlotOccupied and self:IsRaidEnemySlotOccupied(i) or (unit ~= nil)

        if slotOccupied then
            if unit then
                local meta = self.GetRaidEnemySlotMeta and self:GetRaidEnemySlotMeta(i)
                if meta and meta.name then
                    self._zfEnemyNameOverrides[unit] = meta.name
                end

                if not inCombat and child and currentUnit ~= unit then
                    child:SetAttribute("unit", unit)
                    child.unit = unit
                    child:SetAttribute("*type1", child._zfOrigType1 or "target")
                    child:SetAttribute("*macrotext1", child._zfOrigMacro1)
                    if child.UpdateAllElements then
                        child:UpdateAllElements("RefreshUnit")
                    end
                end
                child:SetAlpha(1)
            else
                local meta = self.GetRaidEnemySlotMeta and self:GetRaidEnemySlotMeta(i)
                if meta then
                    if meta.classToken and child.Health then
                        local color = child.colors and child.colors.class and child.colors.class[meta.classToken]
                        if color then
                            child.Health:SetStatusBarColor(color:GetRGB())
                            child.Health:SetValue(child.Health:GetMinMaxValues() and select(2, child.Health:GetMinMaxValues()) or 1)
                        end
                    end

                    if meta.name and child.Texts then
                        for _, fs in ipairs(child.Texts) do
                            if fs and fs.SetText and fs._zfTagFormat and fs._zfTagFormat:find("name") then
                                fs:SetText(meta.name)
                            end
                        end
                    end

                    if not inCombat and meta.name then
                        if not child._zfOrigType1 then
                            child._zfOrigType1 = child:GetAttribute("*type1")
                            child._zfOrigMacro1 = child:GetAttribute("*macrotext1")
                        end
                        child:SetAttribute("*type1", "macro")
                        child:SetAttribute("*macrotext1", "/target " .. meta.name)
                    end
                end
                if child.HighlightBorder then
                    child.HighlightBorder:Hide()
                end
                child:SetAlpha(outOfRangeAlpha)
            end
            if not inCombat then
                child:Show()
            end
        else
            child:SetAlpha(0)
            if not inCombat then
                local resetUnit = fallbackUnits[i]
                if child and resetUnit and currentUnit ~= resetUnit then
                    child:SetAttribute("unit", resetUnit)
                    child.unit = resetUnit
                    if child.UpdateAllElements then
                        child:UpdateAllElements("RefreshUnit")
                    end
                end
                child:Hide()
            end
        end
    end

    local resolved = 0
    for i = 1, rosterCount do
        if self.GetRaidEnemyUnitAt and self:GetRaidEnemyUnitAt(i) then
            resolved = resolved + 1
        end
    end
    local first = self.GetRaidEnemyUnitAt and (self:GetRaidEnemyUnitAt(1) or "none") or "none"
    local second = self.GetRaidEnemyUnitAt and (self:GetRaidEnemyUnitAt(2) or "none") or "none"
    local signature = table.concat({
        tostring(activeEnemyProfile or "none"),
        tostring(rosterCount),
        tostring(resolved),
        tostring(first),
        tostring(second),
    }, "|")

    if self._zfRaidEnemyLastLogSignature ~= signature then
        self._zfRaidEnemyLastLogSignature = signature
    end
end

function addon:UpdateRaidFrameVisibility()
    local raidCfg = self.config and self.config.raid
    if not raidCfg then
        return
    end

    local state = self:GetRaidRoutingState()
    local activeProfile = state.activeFriendlyProfile
    local activeEnemyProfile = state.activeEnemyProfile

    if self._zfRaidLastFriendlyProfile ~= activeProfile
        or self._zfRaidLastEnemyProfile ~= activeEnemyProfile
        or self._zfRaidLastShowParty ~= state.showParty then
        self._zfRaidLastFriendlyProfile = activeProfile
        self._zfRaidLastEnemyProfile = activeEnemyProfile
        self._zfRaidLastShowParty = state.showParty
    end

    if InCombatLockdown() then
        self._zfPendingRaidVisibilityUpdate = true
        self._zfRaidPendingActiveProfile = activeProfile
        self._zfRaidPendingEnemyProfile = activeEnemyProfile
        return
    end

    self._zfPendingRaidVisibilityUpdate = false
    self._zfRaidPendingActiveProfile = nil
    self._zfRaidPendingEnemyProfile = nil

    for containerKey, container in pairs(self.groupContainers or {}) do
        if type(containerKey) == "string" and containerKey:match("^raid_[%w]+_friendly$") then
            local profile = containerKey:match("^raid_([%w]+)_friendly$")
            if profile and container then
                if profile == activeProfile then
                    if container.RefreshGroupLabels then
                        container:RefreshGroupLabels()
                    end
                    container:Show()
                else
                    container:Hide()
                end
            end
        end

        if type(containerKey) == "string" and containerKey:match("^raid_[%w]+_enemy$") then
            local profile = containerKey:match("^raid_([%w]+)_enemy$")
            if profile and container then
                if profile == activeEnemyProfile then
                    if container.RefreshGroupLabels then
                        container:RefreshGroupLabels()
                    end
                    container:Show()
                else
                    container:Hide()
                end
            end
        end
    end

    self:UpdateRaidEnemyProfileUnits(activeEnemyProfile)
    self:UpdateRaidSlotPlaceholders()
end

function addon:EnsureRaidVisibilityEventFrame()
    if self._zfRaidVisibilityEventFrame then return end

    local raidVisibilityEventFrame = CreateFrame("Frame")
    raidVisibilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    raidVisibilityEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    raidVisibilityEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    raidVisibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    raidVisibilityEventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if addon._zfPendingRaidVisibilityUpdate then
                addon:UpdateRaidFrameVisibility()
            elseif addon._zfPendingRaidEnemyUnitSync then
                addon:UpdateRaidEnemyProfileUnits(addon._zfRaidEnemyPendingProfile)
            end
            return
        end

        addon:UpdateRaidFrameVisibility()
    end)

    self._zfRaidVisibilityEventFrame = raidVisibilityEventFrame
end

function addon:SpawnRaidFrames()
    local raidCfg = self.config and self.config.raid
    if not raidCfg then
        return
    end

    local profiles = raidCfg.profiles or {}
    self.groupContainers = self.groupContainers or {}

    for profileName, profileCfg in pairs(profiles) do
        local friendlyCfg = profileCfg and profileCfg.friendly
        if friendlyCfg and friendlyCfg.enabled and friendlyCfg.maxUnits and friendlyCfg.maxUnits > 0 then
            local containerKey = "raid_" .. profileName .. "_friendly"
            if not self.groupContainers[containerKey] then
                local units = self:BuildRaidUnitTokens(friendlyCfg.maxUnits)
                local container = self:SpawnGroupFrames(containerKey, units, friendlyCfg)
                if container then
                    if self.pvpFriendlyProfiles[profileName] then
                        self:CreateRaidSlotPlaceholders(container)
                    end
                    container:Hide()
                end
            end
        end

        local enemyCfg = profileCfg and profileCfg.enemy
        if enemyCfg and enemyCfg.enabled and enemyCfg.maxUnits and enemyCfg.maxUnits > 0 then
            local containerKey = "raid_" .. profileName .. "_enemy"
            if not self.groupContainers[containerKey] then
                local units = self:BuildNameplateUnitTokens(enemyCfg.maxUnits)
                local container = self:SpawnGroupFrames(containerKey, units, enemyCfg)
                if container then
                    if self.pvpFriendlyProfiles[profileName] then
                        self:CreateRaidSlotPlaceholders(container)
                    end
                    container:Hide()
                end
            end
        end
    end

    self:EnsureRaidVisibilityEventFrame()
    self:UpdateRaidFrameVisibility()
end

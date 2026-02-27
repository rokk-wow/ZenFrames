local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local highlightUpdaters = {}
local arenaVisibilityEventFrame
local raidVisibilityEventFrame

local unitToConfigKeyMap = {
    player = "player",
    target = "target",
    targettarget = "targetTarget",
    focus = "focus",
    focustarget = "focusTarget",
    pet = "pet",
}

local function IsArenaInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "arena"
end

local CLICK_ACTION_DEFAULT_LEFT = "select"
local CLICK_ACTION_DEFAULT_RIGHT = "contextMenu"

local function NormalizeClickAction(action, fallback)
    if action == "none" or action == "select" or action == "contextMenu" or action == "focus" or action == "inspect" or action == "clearFocus" then
        return action
    end
    return fallback
end

local function GetActionAttributes(action)
    if action == "select" then
        return "target", nil
    end
    if action == "contextMenu" then
        return "togglemenu", nil
    end
    if action == "focus" then
        return "focus", nil
    end
    if action == "clearFocus" then
        return "macro", "/clearfocus"
    end
    return nil, nil
end

function addon:ApplyUnitFrameClickBehavior(frame, cfg)
    if not frame then return end

    local leftAction = NormalizeClickAction(cfg and cfg.leftClick, CLICK_ACTION_DEFAULT_LEFT)
    local rightAction = NormalizeClickAction(cfg and cfg.rightClick, CLICK_ACTION_DEFAULT_RIGHT)

    frame:RegisterForClicks("AnyUp")

    local leftType, leftMacro = GetActionAttributes(leftAction)
    local rightType, rightMacro = GetActionAttributes(rightAction)

    frame:SetAttribute("*type1", leftType)
    frame:SetAttribute("*type2", rightType)
    frame:SetAttribute("*macrotext1", leftMacro)
    frame:SetAttribute("*macrotext2", rightMacro)

    frame._zfLeftClickAction = leftAction
    frame._zfRightClickAction = rightAction

    if not frame._zfInspectClickHooked then
        frame:HookScript("OnMouseUp", function(self, button)
            local action = nil
            if button == "LeftButton" then
                action = self._zfLeftClickAction
            elseif button == "RightButton" then
                action = self._zfRightClickAction
            end

            if action ~= "inspect" then
                return
            end

            local unit = self.unit or self:GetAttribute("unit")
            if not unit or not UnitExists(unit) then
                return
            end

            if not UnitIsPlayer(unit) then
                return
            end

            if CanInspect and CanInspect(unit) then
                InspectUnit(unit)
            end
        end)
        frame._zfInspectClickHooked = true
    end
end

function addon:SpawnUnitFrame(unit, configKey)
    local styleName = "ZenFrames" .. configKey

    oUF:RegisterStyle(styleName, function(frame)
        local cfg = addon.config[configKey]

        frame:SetSize(cfg.width, cfg.height)
        addon:ApplyUnitFrameClickBehavior(frame, cfg)
        frame:SetPoint(cfg.anchor, _G[cfg.relativeTo], cfg.relativePoint, cfg.offsetX, cfg.offsetY)

        addon:AddBackground(frame, cfg)

        if cfg.hideBlizzard and BuffFrame then
            BuffFrame:UnregisterAllEvents()
            BuffFrame:Hide()
            BuffFrame:SetScript("OnShow", BuffFrame.Hide)
        end
        if cfg.hideBlizzard and DebuffFrame then
            DebuffFrame:UnregisterAllEvents()
            DebuffFrame:Hide()
            DebuffFrame:SetScript("OnShow", DebuffFrame.Hide)
        end

        if cfg.modules then
            if cfg.modules.health and cfg.modules.health.enabled then
                addon:AddHealth(frame, cfg.modules.health)
            end

            if cfg.modules.absorbs and cfg.modules.absorbs.enabled then
                addon:AddAbsorbs(frame, cfg.modules.absorbs)
            end

            if cfg.modules.power and cfg.modules.power.enabled then
                addon:AddPower(frame, cfg.modules.power, cfg)
            end

            if cfg.modules.text then
                addon:AddText(frame, cfg.modules.text)
            end

            if cfg.modules.castbar and cfg.modules.castbar.enabled then
                addon:AddCastbar(frame, cfg.modules.castbar)
            end

            if cfg.modules.restingIndicator and cfg.modules.restingIndicator.enabled then
                addon:AddRestingIndicator(frame, cfg.modules.restingIndicator)
            end

            if cfg.modules.combatIndicator and cfg.modules.combatIndicator.enabled then
                addon:AddCombatIndicator(frame, cfg.modules.combatIndicator)
            end

            if cfg.modules.roleIcon and cfg.modules.roleIcon.enabled then
                addon:AddRoleIcon(frame, cfg.modules.roleIcon)
            end

            if cfg.modules.trinket and cfg.modules.trinket.enabled then
                addon:AddTrinket(frame, cfg.modules.trinket)
            end

            if cfg.modules.arenaTargets and cfg.modules.arenaTargets.enabled then
                addon:AddArenaTargets(frame, cfg.modules.arenaTargets, cfg.borderWidth)
            end

            if cfg.modules.auraFilters then
                for _, filterCfg in ipairs(cfg.modules.auraFilters) do
                    if filterCfg.enabled then
                        addon:AddAuraFilter(frame, filterCfg)
                    end
                end
            end

            if cfg.modules.drTracker and cfg.modules.drTracker.enabled then
                addon:AddDRTracker(frame, cfg.modules.drTracker)
            end

            if frame.Health then
                local powerCfg = cfg.modules.power
                local powerHeight = powerCfg and powerCfg.enabled and powerCfg.height or 0
                local adjustHealth = powerCfg and powerCfg.adjustHealthbarHeight

                local healthHeight = cfg.height
                if adjustHealth and frame.Power then
                    healthHeight = cfg.height - powerHeight
                    frame.Power._healthOriginalHeight = cfg.height
                end
                frame.Health:SetWidth(cfg.width)
                frame.Health:SetHeight(healthHeight)
            end
        end

        addon:AddBorder(frame, cfg)

        if cfg.modules and cfg.modules.dispelHighlight and cfg.modules.dispelHighlight.enabled then
            addon:AddDispelHighlight(frame, cfg.modules.dispelHighlight)
        end

        if cfg.modules and cfg.modules.dispelIcon and cfg.modules.dispelIcon.enabled then
            addon:AddDispelIcon(frame, cfg.modules.dispelIcon)
        end

        if cfg.highlightSelected then
            local hr, hg, hb = addon:HexToRGB(addon.config.global.highlightColor)
            local borderW = cfg.borderWidth
            local highlightW = borderW + 2
            local highlightOffset = highlightW

            local highlight = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -highlightOffset, highlightOffset)
            highlight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", highlightOffset, -highlightOffset)
            highlight:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = highlightW,
            })
            highlight:SetBackdropBorderColor(hr, hg, hb, 1)
            highlight:SetFrameLevel((frame.Border and frame.Border:GetFrameLevel() or frame:GetFrameLevel()) + 20)
            highlight:Hide()
            frame.HighlightBorder = highlight

            local function UpdateHighlight()
                if UnitExists(frame.unit) and UnitIsUnit(frame.unit, "target") then
                    highlight:Show()
                else
                    highlight:Hide()
                end
            end

            table.insert(highlightUpdaters, UpdateHighlight)
            hooksecurefunc(frame, "UpdateAllElements", function() UpdateHighlight() end)
        end
    end)

    oUF:SetActiveStyle(styleName)
    self.unitFrames[unit] = oUF:Spawn(unit, self.config[configKey].frameName)

    local frame = self.unitFrames[unit]
    if frame then
        frame._zfConfigKey = configKey

        if not frame._zfArenaVisibilityHooked then
            frame:HookScript("OnShow", function(self)
                if self._zfHideInArenaActive and not InCombatLockdown() then
                    self:Hide()
                end
            end)
            frame._zfArenaVisibilityHooked = true
        end

        C_Timer.After(addon.config.global.refreshDelay, function()
            if frame then
                frame:UpdateAllElements("RefreshUnit")
            end
        end)
    end

    self:EnsureArenaVisibilityEventFrame()
    self:UpdateArenaFrameVisibility()
end

function addon:UpdateArenaFrameVisibility()
    local inArena = IsArenaInstance()

    if InCombatLockdown() then
        self._zfPendingArenaVisibilityUpdate = true
        return
    end

    self._zfPendingArenaVisibilityUpdate = false

    for unit, frame in pairs(self.unitFrames or {}) do
        local configKey = unitToConfigKeyMap[unit]
        local cfg = configKey and self.config and self.config[configKey]

        if frame and cfg and cfg.enabled then
            local shouldHide = cfg.hideInArena == true and inArena
            frame._zfHideInArenaActive = shouldHide

            if shouldHide then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end
end

function addon:EnsureArenaVisibilityEventFrame()
    if arenaVisibilityEventFrame then return end

    arenaVisibilityEventFrame = CreateFrame("Frame")
    arenaVisibilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    arenaVisibilityEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    arenaVisibilityEventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    arenaVisibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    arenaVisibilityEventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if addon._zfPendingArenaVisibilityUpdate then
                addon:UpdateArenaFrameVisibility()
            end
            return
        end

        addon:UpdateArenaFrameVisibility()
    end)

    addon._zfArenaVisibilityEventFrame = arenaVisibilityEventFrame
end

local function BuildRaidUnitTokens(maxUnits)
    local units = {}
    for i = 1, maxUnits do
        units[i] = "raid" .. i
    end
    return units
end

local function BuildNameplateUnitTokens(maxUnits)
    local units = {}
    for i = 1, maxUnits do
        units[i] = "nameplate" .. i
    end
    return units
end

local function RaidDebugPrint(...)
    print("ZenFrames:", ...)
end

local function IsRaidLikeGroupForBypass(raidCfg)
    local inGroup = IsInGroup()
    local inRaid = IsInRaid()
    local groupSize = GetNumGroupMembers() or 0
    local threshold = raidCfg and raidCfg.routing and raidCfg.routing.usePartyWhenGroupSizeAtOrBelow or 5

    local inInstance, instanceType = IsInInstance()
    local isScenarioInstance = inInstance and instanceType == "scenario"
    local isScenarioGroup = IsInScenarioGroup and IsInScenarioGroup() or false
    local hasRaidUnits = UnitExists("raid1") == true
    local thresholdRaidUnitExists = UnitExists("raid" .. tostring(threshold + 1)) == true

    if inRaid then
        return true
    end

    if thresholdRaidUnitExists then
        return true
    end

    if not isScenarioInstance and not isScenarioGroup then
        return false
    end

    if inRaid or hasRaidUnits then
        return true
    end

    if inGroup and groupSize > threshold then
        return true
    end

    return false
end

local function RaidDebugPrintOnce(self, key, ...)
    self._zfRaidDebugSignatures = self._zfRaidDebugSignatures or {}

    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local signature = table.concat(parts, "|")

    if self._zfRaidDebugSignatures[key] ~= signature then
        self._zfRaidDebugSignatures[key] = signature
        RaidDebugPrint(...)
    end
end

function addon:GetRaidRoutingState()
    local raidCfg = self.config and self.config.raid
    local raidLikeBypass = raidCfg and IsRaidLikeGroupForBypass(raidCfg)
    local raidEnabled = raidCfg and (raidCfg.enabled == true or raidLikeBypass)

    if not raidCfg or not raidEnabled then
        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "disabled", "raidCfgEnabled", tostring(raidCfg and raidCfg.enabled))
        return {
            showParty = false,
            activeFriendlyProfile = nil,
            activeEnemyProfile = nil,
        }
    end

    local routing = raidCfg.routing or {}
    local threshold = routing.usePartyWhenGroupSizeAtOrBelow or 5
    local inGroup = IsInGroup()
    local inRaid = IsInRaid()
    local groupSize = inGroup and GetNumGroupMembers() or 0
    local inInstance, instanceType = IsInInstance()
    local isScenarioRaidLike = inInstance and instanceType == "scenario" and groupSize > threshold

    RaidDebugPrintOnce(
        self,
        "raidRoutingContext",
        "raid context",
        "inGroup", inGroup and "1" or "0",
        "inRaid", inRaid and "1" or "0",
        "groupSize", groupSize,
        "instanceType", instanceType or "none",
        "threshold", threshold,
        "scenarioRaidLike", isScenarioRaidLike and "1" or "0"
    )

    if not inGroup then
        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "no-group")
        return {
            showParty = false,
            activeFriendlyProfile = nil,
            activeEnemyProfile = nil,
        }
    end

    if groupSize <= threshold then
        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "party", "groupSize", groupSize)
        return {
            showParty = true,
            activeFriendlyProfile = nil,
            activeEnemyProfile = nil,
        }
    end

    if not inRaid and not isScenarioRaidLike then
        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "group-not-raid", "groupSize", groupSize)
        return {
            showParty = false,
            activeFriendlyProfile = nil,
            activeEnemyProfile = nil,
        }
    end

    if not inRaid and isScenarioRaidLike then
        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "scenario-raid-like", "groupSize", groupSize)
    end

    local isPvpRaid = inInstance and instanceType == "pvp"

    if isPvpRaid then
        local pvp = routing.pvp or {}
        local blitz = pvp.blitz
        if blitz and groupSize >= (blitz.minRaidSize or 6) and groupSize <= (blitz.maxRaidSize or 8) then
            local profile = blitz.profile
            RaidDebugPrintOnce(self, "raidRouting", "raid routing", "pvp", "blitz", "profile", profile or "nil")
            return {
                showParty = false,
                activeFriendlyProfile = profile,
                activeEnemyProfile = profile,
            }
        end

        local battleground = pvp.battleground
        if battleground and groupSize >= (battleground.minRaidSize or 9) and groupSize <= (battleground.maxRaidSize or 25) then
            local profile = battleground.profile
            RaidDebugPrintOnce(self, "raidRouting", "raid routing", "pvp", "battleground", "profile", profile or "nil")
            return {
                showParty = false,
                activeFriendlyProfile = profile,
                activeEnemyProfile = profile,
            }
        end

        local epicBattleground = pvp.epicBattleground
        if epicBattleground and groupSize >= (epicBattleground.minRaidSize or 26) then
            local profile = epicBattleground.profile
            RaidDebugPrintOnce(self, "raidRouting", "raid routing", "pvp", "epic", "profile", profile or "nil")
            return {
                showParty = false,
                activeFriendlyProfile = profile,
                activeEnemyProfile = profile,
            }
        end

        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "pvp", "no-matching-profile", "groupSize", groupSize)
        return {
            showParty = false,
            activeFriendlyProfile = nil,
            activeEnemyProfile = nil,
        }
    end

    local pve = routing.pve or {}
    if groupSize >= (pve.minRaidSize or 6) then
        RaidDebugPrintOnce(self, "raidRouting", "raid routing", "pve", "profile", pve.profile or "pve")
        return {
            showParty = false,
            activeFriendlyProfile = pve.profile or "pve",
            activeEnemyProfile = nil,
        }
    end

    RaidDebugPrintOnce(self, "raidRouting", "raid routing", "pve", "below-min-raid-size", "groupSize", groupSize)
    return {
        showParty = false,
        activeFriendlyProfile = nil,
        activeEnemyProfile = nil,
    }
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

    local fallbackUnits = BuildNameplateUnitTokens(enemyCfg.maxUnits or #container.frames)
    local rosterCount = self.GetRaidEnemyRosterCount and self:GetRaidEnemyRosterCount() or 0

    if InCombatLockdown() then
        self._zfPendingRaidEnemyUnitSync = true
        self._zfRaidEnemyPendingProfile = activeEnemyProfile
        return
    end

    self._zfPendingRaidEnemyUnitSync = false
    self._zfRaidEnemyPendingProfile = nil

    for i, child in ipairs(container.frames) do
        local unit = self.GetRaidEnemyUnitAt and self:GetRaidEnemyUnitAt(i) or nil
        local currentUnit = child and child:GetAttribute("unit")

        if i <= rosterCount then
            if unit and child and currentUnit ~= unit then
                child:SetAttribute("unit", unit)
                child.unit = unit
                if child.UpdateAllElements then
                    child:UpdateAllElements("RefreshUnit")
                end
            end
        else
            local resetUnit = fallbackUnits[i]
            if child and resetUnit and currentUnit ~= resetUnit then
                child:SetAttribute("unit", resetUnit)
                child.unit = resetUnit
                if child.UpdateAllElements then
                    child:UpdateAllElements("RefreshUnit")
                end
            end
        end
    end

    local resolvedUnits = self.GetRaidEnemyUnits and self:GetRaidEnemyUnits(enemyCfg.maxUnits or #container.frames) or {}
    local resolved = #resolvedUnits
    local first = self.GetRaidEnemyUnitAt and (self:GetRaidEnemyUnitAt(1) or "none") or "none"
    local second = self.GetRaidEnemyUnitAt and (self:GetRaidEnemyUnitAt(2) or "none") or "none"
    local signature = table.concat({
        tostring(activeEnemyProfile or "none"),
        tostring(resolved),
        tostring(first),
        tostring(second),
    }, "|")

    if self._zfRaidEnemyLastLogSignature ~= signature then
        self._zfRaidEnemyLastLogSignature = signature
        RaidDebugPrint("raid enemy bind", activeEnemyProfile or "none", resolved, first, second)
    end
end

function addon:UpdateRaidFrameVisibility()
    local raidCfg = self.config and self.config.raid
    local raidLikeBypass = raidCfg and IsRaidLikeGroupForBypass(raidCfg)
    local raidEnabled = raidCfg and (raidCfg.enabled == true or raidLikeBypass)
    if not raidCfg or not raidEnabled then
        local inInstance, instanceType = IsInInstance()
        local scenarioGroup = IsInScenarioGroup and IsInScenarioGroup() or false
        local hasRaid1 = UnitExists("raid1") and "1" or "0"
        local hasRaid6 = UnitExists("raid6") and "1" or "0"
        RaidDebugPrintOnce(
            self,
            "raidVisibility",
            "raid visibility",
            "skipped",
            "raidCfgEnabled", tostring(raidCfg and raidCfg.enabled),
            "raidLikeBypass", raidLikeBypass and "1" or "0",
            "instanceType", instanceType or "none",
            "scenarioGroup", scenarioGroup and "1" or "0",
            "hasRaid1", hasRaid1,
            "hasRaid6", hasRaid6
        )
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
        RaidDebugPrint(
            "raid route",
            state.showParty and "party" or (activeProfile or "none"),
            activeEnemyProfile or "none"
        )
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
end

function addon:EnsureRaidVisibilityEventFrame()
    if raidVisibilityEventFrame then return end

    raidVisibilityEventFrame = CreateFrame("Frame")
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

    addon._zfRaidVisibilityEventFrame = raidVisibilityEventFrame
end

function addon:SpawnRaidFrames()
    local raidCfg = self.config and self.config.raid
    local raidLikeBypass = raidCfg and IsRaidLikeGroupForBypass(raidCfg)
    local raidEnabled = raidCfg and (raidCfg.enabled == true or raidLikeBypass)
    if not raidCfg or not raidEnabled then
        local inInstance, instanceType = IsInInstance()
        local scenarioGroup = IsInScenarioGroup and IsInScenarioGroup() or false
        local hasRaid1 = UnitExists("raid1") and "1" or "0"
        local hasRaid6 = UnitExists("raid6") and "1" or "0"
        RaidDebugPrintOnce(
            self,
            "raidSpawn",
            "raid spawn",
            "skipped",
            "raidCfgEnabled", tostring(raidCfg and raidCfg.enabled),
            "raidLikeBypass", raidLikeBypass and "1" or "0",
            "instanceType", instanceType or "none",
            "scenarioGroup", scenarioGroup and "1" or "0",
            "hasRaid1", hasRaid1,
            "hasRaid6", hasRaid6
        )
        return
    end

    if raidLikeBypass and raidCfg and raidCfg.enabled ~= true then
        RaidDebugPrintOnce(self, "raidScenarioBypass", "raid spawn", "raid-like-bypass", "raidCfgEnabled", tostring(raidCfg.enabled))
    end

    local profiles = raidCfg.profiles or {}
    self.groupContainers = self.groupContainers or {}

    RaidDebugPrintOnce(self, "raidSpawn", "raid spawn", "begin", "profiles", next(profiles) and "1" or "0")

    if raidCfg.hideBlizzard then
        oUF:DisableBlizzard("raid")
    end

    for profileName, profileCfg in pairs(profiles) do
        local friendlyCfg = profileCfg and profileCfg.friendly
        if friendlyCfg and friendlyCfg.enabled and friendlyCfg.maxUnits and friendlyCfg.maxUnits > 0 then
            local containerKey = "raid_" .. profileName .. "_friendly"
            if not self.groupContainers[containerKey] then
                local units = BuildRaidUnitTokens(friendlyCfg.maxUnits)
                local container = self:SpawnGroupFrames(containerKey, units, friendlyCfg)
                if container then
                    container:Hide()
                    RaidDebugPrint("raid spawn", containerKey, "friendly", "created", friendlyCfg.maxUnits)
                end
            end
        else
            RaidDebugPrint("raid spawn", "friendly", profileName, "disabled-or-invalid")
        end

        local enemyCfg = profileCfg and profileCfg.enemy
        if enemyCfg and enemyCfg.enabled and enemyCfg.maxUnits and enemyCfg.maxUnits > 0 then
            local containerKey = "raid_" .. profileName .. "_enemy"
            if not self.groupContainers[containerKey] then
                local units = BuildNameplateUnitTokens(enemyCfg.maxUnits)
                local container = self:SpawnGroupFrames(containerKey, units, enemyCfg)
                if container then
                    container:Hide()
                    RaidDebugPrint("raid spawn", containerKey, "enemy", "created", enemyCfg.maxUnits)
                end
            end
        else
            RaidDebugPrint("raid spawn", "enemy", profileName, "disabled-or-invalid")
        end
    end

    self:EnsureRaidVisibilityEventFrame()
    self:UpdateRaidFrameVisibility()
end

function addon:SpawnGroupFrames(configKey, units, explicitCfg)
    local cfg = explicitCfg or self.config[configKey]
    local unitBorderWidth = cfg.borderWidth
    local unitBorderColor = cfg.borderColor

    local maxUnits = math.min(cfg.maxUnits, #units)
    local perRow = cfg.perRow
    local spacingX = cfg.spacingX
    local spacingY = cfg.spacingY
    local growthX = cfg.growthX
    local growthY = cfg.growthY
    local unitW = cfg.unitWidth
    local unitH = cfg.unitHeight

    local cols = math.min(perRow, maxUnits)
    local rows = math.ceil(maxUnits / cols)
    local cellW = unitW
    local cellH = unitH
    local containerW = cols * cellW + math.max(0, cols - 1) * spacingX + 2 * spacingX
    local containerH = rows * cellH + math.max(0, rows - 1) * spacingY + 2 * spacingY

    local container = CreateFrame("Frame", cfg.frameName, UIParent)
    container:SetSize(containerW, containerH)
    container:SetPoint(
        cfg.anchor,
        _G[cfg.relativeTo] or UIParent,
        cfg.relativePoint,
        cfg.offsetX,
        cfg.offsetY)

    if cfg.containerBackgroundColor then
        self:AddBackground(container, { backgroundColor = cfg.containerBackgroundColor })
    end

    if cfg.containerBorderWidth and cfg.containerBorderColor then
        self:AddBorder(container, {
            borderWidth = cfg.containerBorderWidth,
            borderColor = cfg.containerBorderColor,
        })
    end

    local xMult = (growthX == "LEFT") and -1 or 1
    local yMult = (growthY == "UP") and 1 or -1

    local vertAnchor = (growthY == "DOWN") and "TOP" or "BOTTOM"
    local horizAnchor = (growthX == "LEFT") and "RIGHT" or "LEFT"
    local initialAnchor = vertAnchor .. horizAnchor

    local styleName = "ZenFrames" .. configKey

    oUF:RegisterStyle(styleName, function(frame)
        frame:SetSize(unitW, unitH)
        self:ApplyUnitFrameClickBehavior(frame, cfg)
        frame.isChild = true

        self:AddBackground(frame, { backgroundColor = cfg.unitBackgroundColor })

        if cfg.modules then
            if cfg.modules.health and cfg.modules.health.enabled then
                self:AddHealth(frame, cfg.modules.health)
            end

            if cfg.modules.absorbs and cfg.modules.absorbs.enabled then
                self:AddAbsorbs(frame, cfg.modules.absorbs)
            end

            if cfg.modules.power and cfg.modules.power.enabled then
                self:AddPower(frame, cfg.modules.power, cfg)
            end

            if cfg.modules.text then
                self:AddText(frame, cfg.modules.text)
            end

            if cfg.modules.castbar and cfg.modules.castbar.enabled then
                self:AddCastbar(frame, cfg.modules.castbar)
            end

            if cfg.modules.restingIndicator and cfg.modules.restingIndicator.enabled then
                self:AddRestingIndicator(frame, cfg.modules.restingIndicator)
            end

            if cfg.modules.combatIndicator and cfg.modules.combatIndicator.enabled then
                self:AddCombatIndicator(frame, cfg.modules.combatIndicator)
            end

            if cfg.modules.roleIcon and cfg.modules.roleIcon.enabled then
                self:AddRoleIcon(frame, cfg.modules.roleIcon)
            end

            if cfg.modules.trinket and cfg.modules.trinket.enabled then
                self:AddTrinket(frame, cfg.modules.trinket)
            end

            if cfg.modules.arenaTargets and cfg.modules.arenaTargets.enabled then
                self:AddArenaTargets(frame, cfg.modules.arenaTargets, unitBorderWidth)
            end

            if cfg.modules.auraFilters then
                for _, filterCfg in ipairs(cfg.modules.auraFilters) do
                    if filterCfg.enabled then
                        self:AddAuraFilter(frame, filterCfg)
                    end
                end
            end

            if cfg.modules.drTracker and cfg.modules.drTracker.enabled then
                self:AddDRTracker(frame, cfg.modules.drTracker)
            end
        end

        if cfg.outOfRangeOpacity and cfg.outOfRangeOpacity < 1 then
            frame.Range = {
                insideAlpha = 1,
                outsideAlpha = cfg.outOfRangeOpacity,
            }
        end

        self:AddBorder(frame, {
            borderWidth = unitBorderWidth,
            borderColor = unitBorderColor,
        })

        if cfg.modules and cfg.modules.dispelHighlight and cfg.modules.dispelHighlight.enabled then
            self:AddDispelHighlight(frame, cfg.modules.dispelHighlight)
        end

        if cfg.modules and cfg.modules.dispelIcon and cfg.modules.dispelIcon.enabled then
            self:AddDispelIcon(frame, cfg.modules.dispelIcon)
        end

        if cfg.highlightSelected then
            local hr, hg, hb = self:HexToRGB(self.config.global.highlightColor)
            local borderW = unitBorderWidth
            local highlightW = borderW + 2
            local highlightOffset = highlightW

            local highlight = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -highlightOffset, highlightOffset)
            highlight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", highlightOffset, -highlightOffset)
            highlight:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = highlightW,
            })
            highlight:SetBackdropBorderColor(hr, hg, hb, 1)
            highlight:SetFrameLevel((frame.Border and frame.Border:GetFrameLevel() or frame:GetFrameLevel()) + 20)
            highlight:Hide()
            frame.HighlightBorder = highlight

            local function UpdateHighlight()
                if UnitExists(frame.unit) and UnitIsUnit(frame.unit, "target") then
                    highlight:Show()
                else
                    highlight:Hide()
                end
            end

            table.insert(highlightUpdaters, UpdateHighlight)
            hooksecurefunc(frame, "UpdateAllElements", function() UpdateHighlight() end)
        end
    end)

    oUF:SetActiveStyle(styleName)

    container.frames = {}
    for i = 1, maxUnits do
        local unit = units[i]
        local col = (i - 1) % perRow
        local row = math.floor((i - 1) / perRow)

        local childName = cfg.frameName .. "_" .. i
        local child = oUF:Spawn(unit, childName)

        child:SetParent(container)

        if configKey == "arena" then
            UnregisterUnitWatch(child)
            child:SetAttribute("state-unitexists", true)
            child:Show()

            local arenaEnabled = true
            child.Enable = function(self)
                arenaEnabled = true
                if not InCombatLockdown() then
                    self:Show()
                end
            end
            child.Disable = function(self)
                arenaEnabled = false
            end
            child.IsEnabled = function()
                return arenaEnabled
            end

            local originalUAE = child.UpdateAllElements
            child.UpdateAllElements = function(self, event)
                local unit = self.unit
                if not unit then return end

                if type(event) ~= "string" then
                    event = "RefreshUnit"
                end

                if self.PreUpdate then
                    self:PreUpdate(event)
                end

                for _, func in next, self.__elements do
                    func(self, event, unit)
                end

                if self.PostUpdate then
                    self:PostUpdate(event)
                end
            end
        end

        child:SetPoint(initialAnchor, container, initialAnchor,
            (col * (cellW + spacingX) + spacingX) * xMult,
            (row * (cellH + spacingY) + spacingY) * yMult)

        container.frames[i] = child
    end

    local function RefreshGroupLabels()
        local layout = cfg.groupLayout
        local shouldShow = layout and layout.showGroupLabels == true

        container._groupLabels = container._groupLabels or {}

        if not shouldShow then
            for _, labelFrame in ipairs(container._groupLabels) do
                labelFrame:Hide()
            end
            return
        end

        local unitsPerGroup = layout.unitsPerGroup or 5
        if unitsPerGroup < 1 then
            unitsPerGroup = 5
        end

        local groupCount = math.ceil(maxUnits / unitsPerGroup)
        local labelSize = layout.groupLabelSize or 10
        local fontPath = self:GetFontPath()
        local labelBorderWidth = cfg.borderWidth or 1
        local labelBorderColor = cfg.borderColor or "000000FF"
        local labelBackgroundColor = cfg.unitBackgroundColor or cfg.backgroundColor or "00000088"

        for groupIndex = 1, groupCount do
            local startUnitIndex = ((groupIndex - 1) * unitsPerGroup) + 1
            local anchorFrame = container.frames[startUnitIndex]
            if anchorFrame then
                local labelFrame = container._groupLabels[groupIndex]
                if not labelFrame then
                    labelFrame = CreateFrame("Frame", nil, container)
                    labelFrame:SetFrameLevel(container:GetFrameLevel() + 20)

                    local bg = labelFrame:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints(labelFrame)
                    bg:SetColorTexture(0, 0, 0, 0.85)
                    labelFrame._bg = bg

                    local text = labelFrame:CreateFontString(nil, "OVERLAY")
                    text:SetPoint("CENTER", labelFrame, "CENTER", 0, 0)
                    text:SetTextColor(1, 1, 1, 1)
                    labelFrame._text = text

                    container._groupLabels[groupIndex] = labelFrame
                end

                local hasGroupMembers = false
                local endUnitIndex = math.min(maxUnits, startUnitIndex + unitsPerGroup - 1)
                for unitIndex = startUnitIndex, endUnitIndex do
                    local unitFrame = container.frames[unitIndex]
                    local unitToken = unitFrame and (unitFrame:GetAttribute("unit") or unitFrame.unit)
                    if unitToken and UnitExists(unitToken) then
                        hasGroupMembers = true
                        break
                    end
                end

                if not hasGroupMembers then
                    labelFrame:Hide()
                else
                    local labelText = tostring(groupIndex)

                    local tabWidth = math.max(22, labelSize + 12)
                    local tabHeight = math.max(22, labelSize + 12)
                    labelFrame:SetSize(tabWidth, tabHeight)
                    labelFrame:ClearAllPoints()
                    if growthX == "LEFT" then
                        labelFrame:SetPoint("LEFT", anchorFrame, "RIGHT", labelBorderWidth, 0)
                    else
                        labelFrame:SetPoint("RIGHT", anchorFrame, "LEFT", -labelBorderWidth, 0)
                    end

                    local br, bg, bb, ba = self:HexToRGB(labelBackgroundColor)
                    labelFrame._bg:SetColorTexture(br, bg, bb, ba or 1)

                    self:AddBorder(labelFrame, {
                        borderWidth = labelBorderWidth,
                        borderColor = labelBorderColor,
                    })

                    labelFrame._text:SetFont(fontPath, labelSize, "OUTLINE")
                    labelFrame._text:SetText(labelText)
                    labelFrame:Show()
                end
            end
        end

        for i = groupCount + 1, #container._groupLabels do
            container._groupLabels[i]:Hide()
        end
    end

    container.RefreshGroupLabels = RefreshGroupLabels
    RefreshGroupLabels()

    C_Timer.After(self.config.global.refreshDelay, function()
        for _, child in ipairs(container.frames) do
            if child then
                child:UpdateAllElements("RefreshUnit")
            end
        end
    end)

    if configKey == "party" and not explicitCfg then
        container:Hide()

        local partyPendingShow = false
        local partyPendingHide = false

        local function ShouldShowParty()
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "arena" then
                return cfg.hideInArena ~= true
            end

            if not IsInGroup() then
                return false
            end

            local threshold = 5
            if addon.config and addon.config.raid and addon.config.raid.routing then
                threshold = addon.config.raid.routing.usePartyWhenGroupSizeAtOrBelow or threshold
            end

            local groupSize = GetNumGroupMembers()
            if groupSize <= threshold then
                return true
            end

            return IsInGroup() and not IsInRaid()
        end

        local function ShowPartyContainer()
            if InCombatLockdown() then
                partyPendingShow = true
                partyPendingHide = false
                return
            end
            partyPendingShow = false
            partyPendingHide = false
            container:Show()
        end

        local function HidePartyContainer()
            if InCombatLockdown() then
                partyPendingHide = true
                partyPendingShow = false
                return
            end
            partyPendingShow = false
            partyPendingHide = false
            container:Hide()
        end

        local function UpdatePartyVisibility()
            if ShouldShowParty() then
                ShowPartyContainer()
            else
                HidePartyContainer()
            end
        end

        local visFrame = CreateFrame("Frame")
        visFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        visFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        visFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        visFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        visFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_ENABLED" then
                if partyPendingShow then
                    ShowPartyContainer()
                elseif partyPendingHide then
                    HidePartyContainer()
                end
            else
                UpdatePartyVisibility()
            end
        end)

        container._visibilityFrame = visFrame
        container._visibilityEvents = {
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
            "GROUP_ROSTER_UPDATE",
            "PLAYER_REGEN_ENABLED",
        }

        C_Timer.After(0.5, function()
            UpdatePartyVisibility()
        end)
    end

    if configKey == "arena" and not explicitCfg then
        container:Hide()

        local arenaPendingShow  = false
        local arenaPendingHide  = false

        local function ShowArenaContainer()
            if InCombatLockdown() then
                arenaPendingShow = true
                arenaPendingHide = false
                return
            end
            arenaPendingShow = false
            arenaPendingHide = false
            container:Show()
        end

        local function HideArenaContainer()
            if InCombatLockdown() then
                arenaPendingHide = true
                arenaPendingShow = false
                return
            end
            arenaPendingShow = false
            arenaPendingHide = false

            for _, child in ipairs(container.frames) do
                child:SetAlpha(1)
            end

            container:Hide()
        end

        local arenaUnitFrames = {}
        for i, child in ipairs(container.frames) do
            arenaUnitFrames["arena" .. i] = child
        end

        local visFrame = CreateFrame("Frame")
        visFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        visFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        visFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        visFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
        visFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        visFrame:SetScript("OnEvent", function(_, event, ...)
            if event == "ARENA_OPPONENT_UPDATE" then
                local unitToken, updateReason = ...
                local frame = arenaUnitFrames[unitToken]
                if frame then
                    if updateReason == "seen" then
                        frame:SetAlpha(1)
                    elseif updateReason == "unseen" or updateReason == "destroyed" then
                        frame:SetAlpha(0.5)
                    end
                end
            elseif event == "PLAYER_REGEN_ENABLED" then
                if arenaPendingShow then
                    ShowArenaContainer()
                elseif arenaPendingHide then
                    HideArenaContainer()
                end
            elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
                if cfg.hideInArena then
                    HideArenaContainer()
                else
                    ShowArenaContainer()
                end
            elseif event == "PLAYER_ENTERING_WORLD" then
                local inInstance, instanceType = IsInInstance()
                if inInstance and instanceType == "arena" then
                    if cfg.hideInArena then
                        HideArenaContainer()
                    else
                        ShowArenaContainer()
                    end
                else
                    HideArenaContainer()
                end
            end
        end)

        container._visibilityFrame = visFrame
        container._visibilityEvents = {
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
            "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
            "ARENA_OPPONENT_UPDATE",
            "PLAYER_REGEN_ENABLED",
        }

        C_Timer.After(0.5, function()
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "arena" and not cfg.hideInArena then
                ShowArenaContainer()
            end
        end)
    end

    self.groupContainers = self.groupContainers or {}
    self.groupContainers[configKey] = container

    self:EnsureArenaVisibilityEventFrame()
    self:UpdateArenaFrameVisibility()

    return container
end

function addon:AddBackground(frame, cfg)
    if not cfg.backgroundColor then return end
    local r, g, b, a = self:HexToRGB(cfg.backgroundColor)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(r, g, b, a)
    frame.Background = bg
end

function addon:AddBorder(frame, cfg)
    if not frame then return end

    local borderWidth = cfg and cfg.borderWidth
    local borderColor = cfg and cfg.borderColor
    if not borderColor or not borderWidth or borderWidth <= 0 then
        if frame.Border then
            frame.Border:Hide()
        end
        return
    end

    local r, g, b, a = self:HexToRGB(borderColor)
    local offset = borderWidth

    if not frame.Border then
        frame.Border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    end

    frame.Border:ClearAllPoints()
    frame.Border:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    frame.Border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)
    frame.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderWidth,
    })
    frame.Border:SetBackdropBorderColor(r, g, b, a)
    frame.Border:Show()
end

function addon:RegisterHighlightEvent()
    if #highlightUpdaters == 0 then return end

    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        for _, fn in ipairs(highlightUpdaters) do
            fn()
        end
    end)
end

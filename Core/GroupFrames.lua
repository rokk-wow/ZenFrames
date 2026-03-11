local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:SpawnGroupFrames(configKey, units, explicitCfg)
    local cfg = explicitCfg or self.config[configKey]
    local unitBorderWidth = cfg.borderWidth
    local unitBorderColor = cfg.borderColor

    if configKey == "boss" and cfg.hideBlizzard then
        oUF:DisableBlizzard("boss")
    end

    local maxUnits = math.min(cfg.maxUnits, #units)
    local perRow = cfg.perRow
    local spacingX = cfg.spacingX
    local spacingY = cfg.spacingY
    local growthX = cfg.growthX
    local growthY = cfg.growthY
    local unitW = cfg.unitWidth
    local unitH = cfg.unitHeight

    local layout = cfg.groupLayout
    local useGroupLayout = layout and layout.enabled
    local groupCount, unitsPerGroup, enforcePerRow, groupCols, groupRows
    local groupWidth, groupHeight, groupSpacingXVal, groupSpacingYVal, layoutOrientation

    if useGroupLayout then
        unitsPerGroup = layout.unitsPerGroup or 5
        enforcePerRow = layout.enforcePerRow or 5
        layoutOrientation = layout.orientation or "HORIZONTAL"
        groupSpacingXVal = layout.groupSpacingX or 4
        groupSpacingYVal = layout.groupSpacingY or 4
        if layout.overrideGrowthX then growthX = layout.overrideGrowthX end
        if layout.overrideGrowthY then growthY = layout.overrideGrowthY end
    end

    local cellW = unitW
    local cellH = unitH
    local cols, rows, containerW, containerH

    if useGroupLayout then
        groupCols = math.min(enforcePerRow, unitsPerGroup)
        groupRows = math.ceil(unitsPerGroup / enforcePerRow)
        groupWidth = groupCols * cellW + math.max(0, groupCols - 1) * spacingX
        groupHeight = groupRows * cellH + math.max(0, groupRows - 1) * spacingY
        groupCount = math.ceil(maxUnits / unitsPerGroup)
        if layoutOrientation == "HORIZONTAL" then
            containerW = groupWidth + 2 * spacingX
            containerH = groupCount * groupHeight + math.max(0, groupCount - 1) * groupSpacingYVal + 2 * spacingY
        else
            containerW = groupCount * groupWidth + math.max(0, groupCount - 1) * groupSpacingXVal + 2 * spacingX
            containerH = groupHeight + 2 * spacingY
        end
    else
        cols = math.min(perRow, maxUnits)
        rows = math.ceil(maxUnits / cols)
        containerW = cols * cellW + math.max(0, cols - 1) * spacingX + 2 * spacingX
        containerH = rows * cellH + math.max(0, rows - 1) * spacingY + 2 * spacingY
    end

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

            if cfg.modules.readyCheck and cfg.modules.readyCheck.enabled then
                self:AddReadyCheck(frame, cfg.modules.readyCheck)
            end

            if cfg.modules.trinket and cfg.modules.trinket.enabled then
                self:AddTrinket(frame, cfg.modules.trinket)
            end

            if cfg.modules.arenaTargets and cfg.modules.arenaTargets.enabled then
                self:AddArenaTargets(frame, cfg.modules.arenaTargets, unitBorderWidth)
            end

            if cfg.modules.objectiveIcon and cfg.modules.objectiveIcon.enabled then
                self:AddObjectiveIcon(frame, cfg.modules.objectiveIcon)
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

        -- oUF Range uses UnitInParty which doesn't work for enemies.
        -- Enemy frame alpha is managed by UpdateRaidEnemyProfileUnits instead.
        local isEnemyContainer = type(configKey) == "string" and configKey:match("_enemy$")
        if not isEnemyContainer and cfg.outOfRangeOpacity and cfg.outOfRangeOpacity < 1 then
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
                if addon:SecureCall(UnitExists, frame.unit) and addon:SecureCall(UnitIsUnit, frame.unit, "target") then
                    highlight:Show()
                else
                    highlight:Hide()
                end
            end

            table.insert(addon.highlightUpdaters, UpdateHighlight)
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

        local isEnemyContainer = type(configKey) == "string" and configKey:match("_enemy$")
        if configKey ~= "arena" and not isEnemyContainer then
            child:RegisterEvent("GROUP_ROSTER_UPDATE", function(self, event)
                local unitGUID = UnitGUID(self.unit)
                if unitGUID and not issecretvalue(unitGUID) and unitGUID ~= self.unitGUID then
                    self.unitGUID = unitGUID
                    self:UpdateAllElements(event)
                end
            end, true)
        end

        if isEnemyContainer then
            UnregisterUnitWatch(child)
            child:SetAttribute("state-unitexists", true)
            child:Show()

            child._zfEnemyFrameIndex = i
            child:HookScript("PreClick", function(self, button)
                if InCombatLockdown() then return end
                local index = self._zfEnemyFrameIndex
                if not index then return end
                local unit = addon:GetRaidEnemyUnitAt(index)
                if unit and UnitExists(unit) then
                    self:SetAttribute("unit", unit)
                    self.unit = unit
                end
            end)
        end

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

        if useGroupLayout then
            local groupIndex = math.floor((i - 1) / unitsPerGroup)
            local indexInGroup = (i - 1) % unitsPerGroup
            local colInGroup = indexInGroup % enforcePerRow
            local rowInGroup = math.floor(indexInGroup / enforcePerRow)
            local offsetX, offsetY
            if layoutOrientation == "HORIZONTAL" then
                offsetX = spacingX + colInGroup * (cellW + spacingX)
                offsetY = spacingY + groupIndex * (groupHeight + groupSpacingYVal) + rowInGroup * (cellH + spacingY)
            else
                offsetX = spacingX + groupIndex * (groupWidth + groupSpacingXVal) + colInGroup * (cellW + spacingX)
                offsetY = spacingY + rowInGroup * (cellH + spacingY)
            end
            child:SetPoint(initialAnchor, container, initialAnchor, offsetX * xMult, offsetY * yMult)
        else
            child:SetPoint(initialAnchor, container, initialAnchor,
                (col * (cellW + spacingX) + spacingX) * xMult,
                (row * (cellH + spacingY) + spacingY) * yMult)
        end

        container.frames[i] = child
    end

    if useGroupLayout then
        container._groupBackgrounds = container._groupBackgrounds or {}
        local grpBgColor = layout.containerBackgroundColor
        local grpBorderWidth = layout.containerBorderWidth
        local grpBorderColor = layout.containerBorderColor

        if grpBgColor or (grpBorderWidth and grpBorderColor) then
            for g = 0, groupCount - 1 do
                local groupBg = container._groupBackgrounds[g + 1]
                if not groupBg then
                    groupBg = CreateFrame("Frame", nil, container)
                    groupBg:SetFrameLevel(container:GetFrameLevel())
                    container._groupBackgrounds[g + 1] = groupBg
                end

                local gOffsetX, gOffsetY
                if layoutOrientation == "HORIZONTAL" then
                    gOffsetX = spacingX
                    gOffsetY = spacingY + g * (groupHeight + groupSpacingYVal)
                else
                    gOffsetX = spacingX + g * (groupWidth + groupSpacingXVal)
                    gOffsetY = spacingY
                end

                groupBg:ClearAllPoints()
                groupBg:SetPoint(initialAnchor, container, initialAnchor, gOffsetX * xMult, gOffsetY * yMult)
                groupBg:SetSize(groupWidth, groupHeight)

                if grpBgColor then
                    self:AddBackground(groupBg, { backgroundColor = grpBgColor })
                end
                if grpBorderWidth and grpBorderColor then
                    self:AddBorder(groupBg, { borderWidth = grpBorderWidth, borderColor = grpBorderColor })
                end

                groupBg:Show()
            end
        end

        for i = (groupCount or 0) + 1, #(container._groupBackgrounds or {}) do
            if container._groupBackgrounds[i] then
                container._groupBackgrounds[i]:Hide()
            end
        end
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

            -- Delegate to centralized routing for all non-arena decisions
            local state = addon:GetRaidRoutingState()
            return state.showParty
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

        local arenaOutOfRangeAlpha = cfg.outOfRangeOpacity or 0.5

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
                        frame:SetAlpha(arenaOutOfRangeAlpha)
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

    if configKey == "boss" and not explicitCfg then
        local bossIsVisible = false

        local function HideBossContainer()
            if bossIsVisible == false then return end
            bossIsVisible = false
            if not InCombatLockdown() then
                container:Hide()
            else
                container:SetAlpha(0)
            end
        end

        local function ShowBossContainer()
            if bossIsVisible == true then return end
            bossIsVisible = true
            if not InCombatLockdown() then
                container:SetAlpha(1)
                container:Show()
            else
                container:SetAlpha(1)
            end
        end

        HideBossContainer()

        local function ShouldShowBossContainer()
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "arena" and cfg.hideInArena then
                return false
            end

            for i = 1, maxUnits do
                if UnitExists("boss" .. i) then
                    return true
                end
            end

            return false
        end

        local function UpdateBossVisibility()
            if ShouldShowBossContainer() then
                ShowBossContainer()
            else
                HideBossContainer()
            end
        end

        local function SyncBossContainerState()
            if bossIsVisible then
                container:SetAlpha(1)
                container:Show()
            else
                container:Hide()
            end
        end

        local visFrame = CreateFrame("Frame")
        visFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        visFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        visFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        visFrame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
        visFrame:RegisterEvent("ENCOUNTER_END")
        visFrame:RegisterEvent("BOSS_KILL")
        visFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        visFrame:SetScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                SyncBossContainerState()
                return
            end

            if event == "UNIT_TARGETABLE_CHANGED" then
                local unitToken = ...
                if type(unitToken) == "string" and not unitToken:match("^boss%d+$") then
                    return
                end
            end

            UpdateBossVisibility()
        end)

        container._visibilityFrame = visFrame
        container._visibilityEvents = {
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
            "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
            "UNIT_TARGETABLE_CHANGED",
            "ENCOUNTER_END",
            "BOSS_KILL",
            "PLAYER_REGEN_ENABLED",
        }

        C_Timer.After(0.5, function()
            UpdateBossVisibility()
        end)
    end

    self.groupContainers = self.groupContainers or {}
    self.groupContainers[configKey] = container

    self:EnsureArenaVisibilityEventFrame()
    self:UpdateArenaFrameVisibility()

    return container
end

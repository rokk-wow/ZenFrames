local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local highlightUpdaters = {}
local arenaVisibilityEventFrame

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
                addon:AddPower(frame, cfg.modules.power)
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

function addon:SpawnGroupFrames(configKey, units)
    local cfg = self.config[configKey]
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
                self:AddPower(frame, cfg.modules.power)
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

    C_Timer.After(self.config.global.refreshDelay, function()
        for _, child in ipairs(container.frames) do
            if child then
                child:UpdateAllElements("RefreshUnit")
            end
        end
    end)

    if configKey == "party" then
        container:Hide()

        local partyPendingShow = false
        local partyPendingHide = false

        local function ShouldShowParty()
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "arena" then
                return cfg.hideInArena ~= true
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

    if configKey == "arena" then
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

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local highlightUpdaters = {}

function addon:SpawnUnitFrame(unit, configKey)
    local styleName = "ZenFrames" .. configKey

    oUF:RegisterStyle(styleName, function(frame)
        local cfg = addon.config[configKey]

        frame:SetSize(cfg.width, cfg.height)
        frame:RegisterForClicks("AnyUp")
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
                addon:AddArenaTargets(frame, cfg.modules.arenaTargets)
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
            local borderW = cfg.borderWidth or 2
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
        C_Timer.After(addon.config.global.refreshDelay, function()
            if frame then
                frame:UpdateAllElements("RefreshUnit")
            end
        end)
    end
end

function addon:SpawnGroupFrames(configKey, units)
    local cfg = self.config[configKey]

    local maxUnits = math.min(cfg.maxUnits or #units, #units)
    local perRow = cfg.perRow or maxUnits
    local spacingX = cfg.spacingX or 0
    local spacingY = cfg.spacingY or 0
    local growthX = cfg.growthX or "RIGHT"
    local growthY = cfg.growthY or "DOWN"
    local unitW = cfg.unitWidth
    local unitH = cfg.unitHeight
    local unitBorderW = cfg.unitBorderWidth or 0

    local cols = math.min(perRow, maxUnits)
    local rows = math.ceil(maxUnits / cols)
    local cellW = unitW + 2 * unitBorderW
    local cellH = unitH + 2 * unitBorderW
    local containerW = cols * cellW + math.max(0, cols - 1) * spacingX + 2 * spacingX
    local containerH = rows * cellH + math.max(0, rows - 1) * spacingY + 2 * spacingY

    local container = CreateFrame("Frame", cfg.frameName, UIParent)
    container:SetSize(containerW, containerH)
    container:SetPoint(
        cfg.anchor or "CENTER",
        _G[cfg.relativeTo] or UIParent,
        cfg.relativePoint or "CENTER",
        cfg.offsetX or 0,
        cfg.offsetY or 0)

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
        frame:RegisterForClicks("AnyUp")

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
                self:AddArenaTargets(frame, cfg.modules.arenaTargets, cfg.unitBorderWidth or 0)
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
            borderWidth = cfg.unitBorderWidth,
            borderColor = cfg.unitBorderColor,
        })

        if cfg.modules and cfg.modules.dispelHighlight and cfg.modules.dispelHighlight.enabled then
            self:AddDispelHighlight(frame, cfg.modules.dispelHighlight)
        end

        if cfg.modules and cfg.modules.dispelIcon and cfg.modules.dispelIcon.enabled then
            self:AddDispelIcon(frame, cfg.modules.dispelIcon)
        end

        if cfg.highlightSelected then
            local hr, hg, hb = self:HexToRGB(self.config.global.highlightColor)
            local borderW = cfg.unitBorderWidth or 2
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

        local childName = (cfg.frameName or "frmdGroup") .. "_" .. i
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
            (col * (cellW + spacingX) + spacingX + unitBorderW) * xMult,
            (row * (cellH + spacingY) + spacingY + unitBorderW) * yMult)

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
        RegisterStateDriver(container, "visibility", "[group] show; hide")
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
                ShowArenaContainer()
            elseif event == "PLAYER_ENTERING_WORLD" then
                local inInstance, instanceType = IsInInstance()
                if inInstance and instanceType == "arena" then
                    ShowArenaContainer()
                else
                    HideArenaContainer()
                end
            end
        end)

        C_Timer.After(0.5, function()
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "arena" then
                ShowArenaContainer()
            end
        end)
    end

    self.groupContainers = self.groupContainers or {}
    self.groupContainers[configKey] = container

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
    if not cfg.borderColor or not cfg.borderWidth then return end
    local r, g, b, a = self:HexToRGB(cfg.borderColor)
    local offset = cfg.borderWidth
    frame.Border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.Border:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    frame.Border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)
    frame.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = cfg.borderWidth,
    })
    frame.Border:SetBackdropBorderColor(r, g, b, a)
end

function addon:RegisterHighlightEvent()
    if #highlightUpdaters == 0 then return end

    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        for _, fn in ipairs(highlightUpdaters) do
            fn()
        end
    end)
end

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

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

            if cfg.modules.objectiveIcon and cfg.modules.objectiveIcon.enabled then
                addon:AddObjectiveIcon(frame, cfg.modules.objectiveIcon)
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

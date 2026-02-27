local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:StyleAuraButton(button, borderWidth, borderColor, options)
    options = options or {}

    button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if button.Overlay then
        button.Overlay:SetTexture(nil)
    end

    self:AddTextureBorder(button, borderWidth, borderColor)

    local fontPath = self:GetFontPath()
    button.Count:ClearAllPoints()
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, 0)
    button.Count:SetFont(fontPath, 10, "OUTLINE")
    button.Count:SetDrawLayer("OVERLAY", 7)

    if button.Cooldown then
        button.Cooldown:SetDrawEdge(false)
        button.Cooldown:SetReverse(true)

        local showSwipe = options.showSwipe ~= false
        button.Cooldown:SetDrawSwipe(showSwipe)

        local showNumbers = options.showCooldownNumbers ~= false
        button.Cooldown.noCooldownCount = not showNumbers
        button.Cooldown:SetHideCountdownNumbers(not showNumbers)
    end

    if options.showGlow then
        local procGlow = CreateFrame("Frame", nil, button)
        procGlow:SetSize(button:GetWidth() * 1.4, button:GetHeight() * 1.4)
        procGlow:SetPoint("CENTER")

        local procLoop = procGlow:CreateTexture(nil, "ARTWORK")
        procLoop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
        procLoop:SetAllPoints(procGlow)
        procLoop:SetAlpha(0)

        if options.glowColor then
            local gr, gg, gb = self:HexToRGB(options.glowColor)
            procLoop:SetDesaturated(true)
            procLoop:SetVertexColor(gr, gg, gb)
        end

        procGlow.ProcLoopFlipbook = procLoop

        local procLoopAnim = procGlow:CreateAnimationGroup()
        procLoopAnim:SetLooping("REPEAT")

        local alpha = procLoopAnim:CreateAnimation("Alpha")
        alpha:SetChildKey("ProcLoopFlipbook")
        alpha:SetDuration(0.001)
        alpha:SetOrder(0)
        alpha:SetFromAlpha(1)
        alpha:SetToAlpha(1)

        local flip = procLoopAnim:CreateAnimation("FlipBook")
        flip:SetChildKey("ProcLoopFlipbook")
        flip:SetDuration(1)
        flip:SetOrder(0)
        flip:SetFlipBookRows(6)
        flip:SetFlipBookColumns(5)
        flip:SetFlipBookFrames(30)

        procGlow.ProcLoop = procLoopAnim
        procGlow:Hide()
        button.ProcGlow = procGlow
    end
end

local AuraFilterMixin = {}

local UNIT_EXPANDERS = {
    party = function()
        local units = {}
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                units[#units + 1] = "raid" .. i
            end
        elseif IsInGroup() then
            units[#units + 1] = "player"
            for i = 1, 4 do
                units[#units + 1] = "party" .. i
            end
        else
            units[#units + 1] = "player"
        end
        return units
    end,
    raid = function()
        local units = {}
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
        return units
    end,
    arena = function()
        local units = {}
        for i = 1, 5 do
            units[#units + 1] = "arena" .. i
        end
        return units
    end,
}

local UNIT_CHANGE_EVENTS = {
    target = "PLAYER_TARGET_CHANGED",
    focus = "PLAYER_FOCUS_CHANGED",
}

function AuraFilterMixin:Init(cfg)
    self.baseFilter = cfg.baseFilter or "HELPFUL"
    self.units = cfg.units or {}
    self.isHelpful = (self.baseFilter == "HELPFUL")
    self.hasDynamicUnits = false
    for _, token in ipairs(self.units) do
        if UNIT_EXPANDERS[token] then
            self.hasDynamicUnits = true
            break
        end
    end

    self.iconSize = cfg.iconSize or 30
    self.iconBorderWidth = cfg.borderWidth or 1
    self.spacingX = cfg.spacingX or 2
    self.spacingY = cfg.spacingY or 2
    self.maxIcons = cfg.maxIcons or 10
    self.perRow = cfg.perRow or self.maxIcons
    self.growthX = cfg.growthX or "RIGHT"
    self.growthY = cfg.growthY or "DOWN"

    self.showPlaceholderIcon = cfg.showPlaceholderIcon or false
    local ph = cfg.placeholderIcon
    if ph and ph ~= "" then
        if tonumber(ph) then
            self.placeholderIcon = tonumber(ph)
        elseif not ph:find("[/\\]") then
            self.placeholderIcon = "Interface\\Icons\\" .. ph
        else
            self.placeholderIcon = ph
        end
    end
    self.placeholderDesaturate = cfg.placeholderDesaturate or false
    if cfg.placeholderColor then
        local r, g, b, a = addon:HexToRGB(cfg.placeholderColor)
        self.placeholderColor = { r, g, b, a }
    end

    local subFilters = cfg.subFilters or {}
    self.testFilters = {}
    for _, sub in ipairs(subFilters) do
        self.testFilters[#self.testFilters + 1] = self.baseFilter .. "|" .. sub
    end
    if #self.testFilters == 0 then
        self.useBaseOnly = true
    end

    local excludeSubFilters = cfg.excludeSubFilters or {}
    self.excludeFilters = {}
    for _, sub in ipairs(excludeSubFilters) do
        self.excludeFilters[#self.excludeFilters + 1] = self.baseFilter .. "|" .. sub
    end

    self.priorityFilter = self.baseFilter .. "|IMPORTANT"

    local cols = math.min(self.perRow, self.maxIcons)
    local rows = math.ceil(self.maxIcons / cols)
    local cellW = self.iconSize + 2 * self.iconBorderWidth
    local cellH = self.iconSize + 2 * self.iconBorderWidth
    self:SetSize(
        cols * cellW + math.max(0, cols - 1) * self.spacingX + 2 * self.spacingX,
        rows * cellH + math.max(0, rows - 1) * self.spacingY + 2 * self.spacingY
    )

    self.icons = {}
    self:CreateIcons(cfg)

    self.currentUnits = {}
    self.unitLookup = {}

    self:SetScript("OnEvent", self.OnEvent)
    self:RegisterEvent("PLAYER_REGEN_ENABLED")

    if self.hasDynamicUnits then
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
    end

    for _, unit in ipairs(self.units) do
        if unit:match("^arena%d+$") then
            self:RegisterEvent("ARENA_OPPONENT_UPDATE")
        end
        local changeEvent = UNIT_CHANGE_EVENTS[unit]
        if changeEvent then
            self:RegisterEvent(changeEvent)
        end
    end

    C_Timer.After(0.5, function()
        if self then
            self:UpdateUnits()
        end
    end)

    self:SetScript("OnShow", function(s)
        s:UpdateUnits()
    end)
end

function AuraFilterMixin:CreateIcons(cfg)
    local isHelpful = self.isHelpful
    local baseFilter = self.baseFilter
    local tooltipAnchor = cfg.tooltipAnchor or "ANCHOR_TOP"
    local clickThrough = cfg.clickThrough == true
    local disableMouse = (cfg.disableMouse == true) or clickThrough
    local disableTooltip = cfg.disableTooltip == true

    local vertAnchor = (self.growthY == "DOWN") and "TOP" or "BOTTOM"
    local horizAnchor = (self.growthX == "LEFT") and "RIGHT" or "LEFT"
    local initialAnchor = vertAnchor .. horizAnchor

    local xMult = (self.growthX == "LEFT") and -1 or 1
    local yMult = (self.growthY == "UP") and 1 or -1

    for i = 1, self.maxIcons do
        local icon = CreateFrame("Button", (self:GetName() or "") .. "_" .. i, self)
        icon:SetSize(self.iconSize, self.iconSize)

        local col = (i - 1) % self.perRow
        local row = math.floor((i - 1) / self.perRow)
        local cellW = self.iconSize + 2 * self.iconBorderWidth
        local cellH = self.iconSize + 2 * self.iconBorderWidth
        icon:SetPoint(initialAnchor, self, initialAnchor,
            (col * (cellW + self.spacingX) + self.spacingX + self.iconBorderWidth) * xMult,
            (row * (cellH + self.spacingY) + self.spacingY + self.iconBorderWidth) * yMult)

        icon.Icon = icon:CreateTexture(nil, "ARTWORK")
        icon.Icon:SetAllPoints()

        if self.showPlaceholderIcon and self.placeholderIcon then
            icon.Placeholder = icon:CreateTexture(nil, "BACKGROUND")
            icon.Placeholder:SetAllPoints()
            icon.Placeholder:SetTexture(self.placeholderIcon)
            icon.Placeholder:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon.Placeholder:SetDesaturated(self.placeholderDesaturate)
            if self.placeholderColor then
                icon.Placeholder:SetVertexColor(unpack(self.placeholderColor))
            end
        end

        icon.Cooldown = CreateFrame("Cooldown", "$parentCD", icon, "CooldownFrameTemplate")
        icon.Cooldown:SetAllPoints()
        icon.Count = icon:CreateFontString(nil, "OVERLAY")
        icon:EnableMouse(not disableMouse)
        icon:SetScript("OnEnter", function(self)
            if disableTooltip then
                return
            end
            if self.auraInstanceID and self.auraUnit then
                GameTooltip:SetOwner(self, tooltipAnchor)
                if isHelpful then
                    GameTooltip:SetUnitBuffByAuraInstanceID(
                        self.auraUnit, self.auraInstanceID, baseFilter)
                else
                    GameTooltip:SetUnitDebuffByAuraInstanceID(
                        self.auraUnit, self.auraInstanceID, baseFilter)
                end
                GameTooltip:Show()
            end
        end)
        icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if isHelpful and not disableMouse then
            icon:RegisterForClicks("RightButtonUp")
            icon:SetScript("OnClick", function(self, mouseButton)
                if mouseButton == "RightButton" and self.auraInstanceID and self.auraUnit then
                    local unit = self.auraUnit
                    if unit == "player" or unit == "vehicle" then
                        addon:SecureCall(function()
                            local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, self.auraInstanceID)
                            if data and data.name then
                                CancelSpellByName(data.name)
                            end
                        end)
                    end
                end
            end)
        end

        addon:StyleAuraButton(icon,
            cfg.borderWidth or 1,
            cfg.borderColor or "000000FF",
            {
                showSwipe = cfg.showSwipe,
                showCooldownNumbers = cfg.showCooldownNumbers,
                showGlow = cfg.showGlow,
                glowColor = cfg.glowColor,
            })

        icon:Hide()
        self.icons[i] = icon
    end
end

function AuraFilterMixin:GetMonitoredUnits()
    local resolved = {}
    for _, token in ipairs(self.units) do
        local expander = UNIT_EXPANDERS[token]
        if expander then
            for _, unit in ipairs(expander()) do
                resolved[#resolved + 1] = unit
            end
        else
            resolved[#resolved + 1] = token
        end
    end
    return resolved
end

function AuraFilterMixin:UpdateUnits()
    self:UnregisterEvent("UNIT_AURA")

    self.currentUnits = self:GetMonitoredUnits()
    self.unitLookup = {}
    local existingUnits = {}
    for _, unit in ipairs(self.currentUnits) do
        if UnitExists(unit) then
            self.unitLookup[unit] = true
            existingUnits[#existingUnits + 1] = unit
        end
    end

    if #existingUnits == 1 then
        self:RegisterUnitEvent("UNIT_AURA", existingUnits[1])
    elseif #existingUnits == 2 then
        self:RegisterUnitEvent("UNIT_AURA", existingUnits[1], existingUnits[2])
    elseif #existingUnits > 2 then
        self:RegisterEvent("UNIT_AURA")
    end

    self:Refresh()
end

function AuraFilterMixin:OnEvent(event, unit)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "PLAYER_FOCUS_CHANGED"
        or event == "ARENA_OPPONENT_UPDATE" then
        self:UpdateUnits()
        return
    end

    if event == "UNIT_AURA" then
        if not self.unitLookup[unit] then
            return
        end
    end

    self:Refresh()
end

function AuraFilterMixin:MatchesFilter(unit, auraInstanceID)
    for _, excludeFilter in ipairs(self.excludeFilters) do
        local filtered = addon:SecureCall(
            C_UnitAuras.IsAuraFilteredOutByInstanceID,
            unit, auraInstanceID, excludeFilter)
        if filtered == false then
            return false
        end
    end

    if self.useBaseOnly then
        return true
    end
    for _, testFilter in ipairs(self.testFilters) do
        local filtered = addon:SecureCall(
            C_UnitAuras.IsAuraFilteredOutByInstanceID,
            unit, auraInstanceID, testFilter)
        if filtered == false then
            return true
        end
    end
    return false
end

function AuraFilterMixin:Refresh()
    local matched = {}

    for _, unit in ipairs(self.currentUnits or {}) do
        if UnitExists(unit) then
            local slots = { C_UnitAuras.GetAuraSlots(unit, self.baseFilter) }
            for i = 2, #slots do
                local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
                if data and self:MatchesFilter(unit, data.auraInstanceID) then
                    local idx = #matched + 1
                    local filtered = addon:SecureCall(
                        C_UnitAuras.IsAuraFilteredOutByInstanceID,
                        unit, data.auraInstanceID, self.priorityFilter)
                    matched[idx] = {
                        unit = unit,
                        aura = data,
                        order = idx,
                        isPriority = (filtered == false),
                    }
                end
            end
        end
    end

    table.sort(matched, function(a, b)
        if a.isPriority ~= b.isPriority then
            return a.isPriority
        end
        return a.order < b.order
    end)

    for i = 1, self.maxIcons do
        local icon = self.icons[i]
        local match = matched[i]
        if match then
            local aura = match.aura
            icon.auraInstanceID = aura.auraInstanceID
            icon.auraUnit = match.unit

            local iconSet = addon:SecureCall(function()
                icon.Icon:SetTexture(aura.icon)
                return true
            end)
            if not iconSet then
                icon.Icon:SetTexture(nil)
            end
            icon.Icon:SetDesaturated(false)
            icon.Icon:SetVertexColor(1, 1, 1, 1)
            if icon.Placeholder then
                icon.Placeholder:Hide()
            end

            icon.Count:Hide()

            icon.Cooldown:Show()
            addon:SecureCall(function()
                icon.Cooldown:SetCooldownFromExpirationTime(
                    aura.expirationTime, aura.duration)
                return true
            end)

            if icon.ProcGlow then
                icon.ProcGlow:Show()
                icon.ProcGlow.ProcLoop:Play()
            end

            icon:Show()
        else
            icon.auraInstanceID = nil
            icon.auraUnit = nil
            icon.Icon:SetTexture(nil)
            icon.Cooldown:Clear()
            icon.Cooldown:Hide()
            if icon.ProcGlow then
                icon.ProcGlow.ProcLoop:Stop()
                icon.ProcGlow:Hide()
            end
            if self.showPlaceholderIcon and icon.Placeholder then
                icon.Placeholder:Show()
                icon:Show()
            elseif icon.EditBackground and icon.EditBackground:IsShown() then
                if icon.Placeholder then
                    icon.Placeholder:Hide()
                end
                icon:Show()
            else
                if icon.Placeholder then
                    icon.Placeholder:Hide()
                end
                icon:Hide()
            end
        end
    end
end

function AuraFilterMixin:Destroy()
    self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
    for _, icon in ipairs(self.icons) do
        icon:Hide()
    end
    self:Hide()
end

function addon:CreateAuraFilter(cfg)
    local parent = cfg.parent or UIParent
    local anchorFrame = cfg.anchorFrame or _G[cfg.relativeTo] or parent
    local frame = CreateFrame("Frame", cfg.frameName, parent)

    frame:SetPoint(
        cfg.anchor or "CENTER",
        anchorFrame,
        cfg.relativePoint or "CENTER",
        cfg.offsetX or 0,
        cfg.offsetY or 0)

    if cfg.containerBackgroundColor then
        self:AddBackground(frame, { backgroundColor = cfg.containerBackgroundColor })
    end

    if cfg.containerBorderWidth and cfg.containerBorderColor then
        self:AddBorder(frame, {
            borderWidth = cfg.containerBorderWidth,
            borderColor = cfg.containerBorderColor,
        })
    end

    Mixin(frame, AuraFilterMixin)
    frame:Init(cfg)

    return frame
end

function addon:AddAuraFilter(frame, cfg)
    local localCfg = {}
    for k, v in pairs(cfg) do
        localCfg[k] = v
    end
    if not localCfg.units then
        localCfg.units = { frame.unit }
    end
    localCfg.parent = localCfg.parent or frame

    -- DEPRECATED: relativeToModule is deprecated. Use direct frame anchoring with calculated offsets instead.
    -- This logic remains for backwards compatibility with existing custom configs.
    if localCfg.relativeToModule then
        local ref = localCfg.relativeToModule
        if type(ref) == "table" then
            for _, key in ipairs(ref) do
                if frame[key] then
                    localCfg.anchorFrame = frame[key]
                    break
                end
            end
            localCfg.anchorFrame = localCfg.anchorFrame or frame
        else
            localCfg.anchorFrame = frame[ref] or frame
        end
    end

    local filter = self:CreateAuraFilter(localCfg)

    if localCfg.name then
        frame[localCfg.name] = filter
        addon:AttachPlaceholder(filter)
    end

    return filter
end

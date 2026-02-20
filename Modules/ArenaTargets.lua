local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

local enemyContainers = {}
local friendlyContainers = {}
local arenaListenerCreated = false

local MAX_ARENA_ENEMIES = 5
local FRIENDLY_UNITS = { "player", "party1", "party2" }

local function IsInArena()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "arena")
end

local function GetUnitClassColor(unit)
    if UnitExists(unit) then
        local _, classFilename = UnitClass(unit)
        if classFilename then
            local color = C_ClassColor.GetClassColor(classFilename)
            if color then
                return color.r, color.g, color.b
            end
        end
    end
    return nil
end

local function CreateIndicator(parent, width, height, borderWidth, borderColor)
    local indicator = CreateFrame("Frame", nil, parent)
    indicator:SetSize(width, height)
    indicator:SetFrameLevel(parent:GetFrameLevel() + 5)
    indicator:EnableMouse(false)

    local inner = indicator:CreateTexture(nil, "ARTWORK")
    inner:SetPoint("TOPLEFT", borderWidth, -borderWidth)
    inner:SetPoint("BOTTOMRIGHT", -borderWidth, borderWidth)
    inner:SetColorTexture(1, 1, 1, 1)
    indicator.Inner = inner

    addon:AddTextureBorder(indicator, borderWidth, borderColor)

    function indicator:SetColor(r, g, b)
        self.Inner:SetColorTexture(r, g, b, 1)
    end

    function indicator:SetVisibleFromBoolean(isMatch)
        self.Inner:SetAlphaFromBoolean(isMatch)
        self.borderTop:SetAlphaFromBoolean(isMatch)
        self.borderBottom:SetAlphaFromBoolean(isMatch)
        self.borderLeft:SetAlphaFromBoolean(isMatch)
        self.borderRight:SetAlphaFromBoolean(isMatch)
    end

    indicator:Hide()
    return indicator
end

local function ResolveAnchorFrame(frame, relativeToModule)
    local anchorFrame = frame
    if relativeToModule then
        local ref = relativeToModule
        if type(ref) == "table" then
            for _, key in ipairs(ref) do
                if frame[key] then
                    anchorFrame = frame[key]
                    break
                end
            end
        else
            anchorFrame = frame[ref] or frame
        end
    end
    return anchorFrame
end

local function BuildArenaIndicators(frame, cfg, parentContainer)
    local mode = cfg.mode or "enemy"
    local indicatorWidth = cfg.indicatorWidth or 10
    local indicatorHeight = cfg.indicatorHeight or 18
    local spacing = cfg.spacing or 2
    local edgeSpacing = cfg.edgeSpacing or 2
    local growDirection = cfg.growDirection or "DOWN"
    local borderWidth = cfg.borderWidth or 1
    local borderColor = cfg.borderColor or "000000FF"
    local maxIndicators = cfg.maxIndicators
        or (mode == "enemy" and MAX_ARENA_ENEMIES or #FRIENDLY_UNITS)

    local container = CreateFrame("Frame", nil, parentContainer)
    container:SetSize(1, 1)
    container:SetAllPoints(parentContainer)

    container.indicators = {}
    for i = 1, maxIndicators do
        local indicator = CreateIndicator(container, indicatorWidth, indicatorHeight, borderWidth, borderColor)
        indicator:ClearAllPoints()

        if i == 1 then
            local xInset = edgeSpacing + borderWidth
            local yInset = edgeSpacing + borderWidth

            if growDirection == "UP" then
                indicator:SetPoint("BOTTOMLEFT", parentContainer, "BOTTOMLEFT", xInset, yInset)
            elseif growDirection == "LEFT" then
                indicator:SetPoint("TOPRIGHT", parentContainer, "TOPRIGHT", -xInset, -yInset)
            else
                indicator:SetPoint("TOPLEFT", parentContainer, "TOPLEFT", xInset, -yInset)
            end
        else
            local prev = container.indicators[i - 1]
            if growDirection == "RIGHT" then
                indicator:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
            elseif growDirection == "LEFT" then
                indicator:SetPoint("RIGHT", prev, "LEFT", -spacing, 0)
            elseif growDirection == "UP" then
                indicator:SetPoint("BOTTOM", prev, "TOP", 0, spacing)
            elseif growDirection == "DOWN" then
                indicator:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
            end
        end

        container.indicators[i] = indicator
    end

    container.unit = parentContainer.unit
    container.mode = mode

    if mode == "enemy" then
        table.insert(enemyContainers, container)
    else
        table.insert(friendlyContainers, container)
    end

    function container:Activate()
        self.unit = parentContainer.unit
        self:Show()
    end

    function container:Deactivate()
        for _, ind in ipairs(self.indicators) do ind:Hide() end
        self:Hide()
    end

    container:Hide()
    return container
end

local function SetupArenaListener()
    if arenaListenerCreated then return end
    arenaListenerCreated = true

    local arenaListener = CreateFrame("Frame", nil, UIParent)
    arenaListener:RegisterUnitEvent("UNIT_TARGET",
        "arena1", "arena2", "arena3", "arena4", "arena5")
    arenaListener:RegisterEvent("ARENA_OPPONENT_UPDATE")
    arenaListener:RegisterEvent("PLAYER_ENTERING_WORLD")

    arenaListener:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            for _, c in ipairs(enemyContainers) do
                for _, ind in ipairs(c.indicators) do ind:Hide() end
            end
            for _, c in ipairs(friendlyContainers) do
                for _, ind in ipairs(c.indicators) do ind:Hide() end
            end
            return
        end

        local arenaIndex = tonumber(string.match(unit or "", "arena(%d+)"))
        if not arenaIndex then return end

        local unitTarget = unit .. "target"
        local r, g, b = GetUnitClassColor(unit)

        for _, c in ipairs(enemyContainers) do
            local indicator = c.indicators[arenaIndex]
            if indicator then
                if r and c.unit then
                    indicator:SetColor(r, g, b)
                    local isMatch = UnitIsUnit(unitTarget, c.unit)
                    indicator:Show()
                    indicator:SetVisibleFromBoolean(isMatch)
                else
                    indicator:Hide()
                end
            end
        end
    end)

    local friendlyListener = CreateFrame("Frame", nil, UIParent)
    friendlyListener:RegisterUnitEvent("UNIT_TARGET",
        "player", "party1", "party2")
    friendlyListener:RegisterEvent("GROUP_ROSTER_UPDATE")

    friendlyListener:SetScript("OnEvent", function(_, event, unit)
        if event == "GROUP_ROSTER_UPDATE" then
            for _, c in ipairs(friendlyContainers) do
                for i, friendlyUnit in ipairs(FRIENDLY_UNITS) do
                    local indicator = c.indicators[i]
                    if indicator then
                        local r, g, b = GetUnitClassColor(friendlyUnit)
                        if r then
                            indicator:SetColor(r, g, b)
                        end
                    end
                end
            end
            return
        end

        local unitIndex = nil
        if unit == "player" then
            unitIndex = 1
        elseif unit == "party1" then
            unitIndex = 2
        elseif unit == "party2" then
            unitIndex = 3
        end

        if not unitIndex then return end

        local unitTarget = unit .. "target"
        for _, c in ipairs(friendlyContainers) do
            local indicator = c.indicators[unitIndex]
            if indicator and c.unit then
                local isMatch = UnitIsUnit(unitTarget, c.unit)
                indicator:Show()
                indicator:SetVisibleFromBoolean(isMatch)
            end
        end
    end)
end

function addon:AddArenaTargets(frame, cfg, frameBorderWidth)
    frameBorderWidth = frameBorderWidth or 0

    local container = CreateFrame("Frame", nil, frame)
    
    local mode = cfg.mode or "enemy"
    local indicatorWidth = cfg.indicatorWidth or 10
    local indicatorHeight = cfg.indicatorHeight or 18
    local spacing = cfg.spacing or 2
    local edgeSpacing = cfg.edgeSpacing or 2
    local growDirection = cfg.growDirection or "DOWN"
    local borderWidth = cfg.borderWidth or 1
    local maxIndicators = cfg.maxIndicators
        or (mode == "enemy" and MAX_ARENA_ENEMIES or #FRIENDLY_UNITS)
    
    local containerWidth, containerHeight
    if growDirection == "DOWN" or growDirection == "UP" then
        containerWidth = indicatorWidth + (2 * borderWidth) + (2 * edgeSpacing)
        containerHeight = (indicatorHeight * maxIndicators)
            + (spacing * (maxIndicators - 1))
            + (2 * borderWidth)
            + (2 * edgeSpacing)
    else
        containerWidth = (indicatorWidth * maxIndicators)
            + (spacing * (maxIndicators - 1))
            + (2 * borderWidth)
            + (2 * edgeSpacing)
        containerHeight = indicatorHeight + (2 * borderWidth) + (2 * edgeSpacing)
    end
    
    container:SetSize(containerWidth, containerHeight)
    
    if cfg.containerBackgroundColor then
        local bg = container:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(container)
        local colorStr = cfg.containerBackgroundColor
        local r = tonumber(string.sub(colorStr, 1, 2), 16) / 255
        local g = tonumber(string.sub(colorStr, 3, 4), 16) / 255
        local b = tonumber(string.sub(colorStr, 5, 6), 16) / 255
        local a = tonumber(string.sub(colorStr, 7, 8), 16) / 255
        bg:SetColorTexture(r, g, b, a)
    end

    local anchorFrame = ResolveAnchorFrame(frame, cfg.relativeToModule)

    container:SetPoint(
        cfg.anchor or "TOPLEFT",
        anchorFrame,
        cfg.relativePoint or "TOPRIGHT",
        cfg.offsetX or 0,
        (cfg.offsetY or 0) + frameBorderWidth
    )

    container.unit = frame.unit
    hooksecurefunc(frame, "UpdateAllElements", function()
        container.unit = frame.unit
        if container.widget then
            container.widget.unit = frame.unit
        end
    end)

    container.widget = BuildArenaIndicators(frame, cfg, container)
    SetupArenaListener()

    local function UpdateVisibility()
        local inArena = IsInArena()
        if inArena then
            container.widget:Activate()
        else
            container.widget:Deactivate()
        end
    end

    local switcher = CreateFrame("Frame", nil, UIParent)
    switcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    switcher:SetScript("OnEvent", UpdateVisibility)

    C_Timer.After(0.2, UpdateVisibility)

    frame.ArenaTargets = container
end

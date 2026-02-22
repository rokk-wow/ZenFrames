local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local function IsInArena()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "arena")
end

local BLIZZARD_ICON_SIZE = 26

function addon:AddDRTracker(frame, cfg)
    local iconSize = cfg.iconSize or BLIZZARD_ICON_SIZE
    local iconBorderWidth = cfg.iconBorderWidth or 1
    local maxIcons = cfg.maxIcons or 6
    local perRow = cfg.perRow or maxIcons
    local growthX = cfg.growthX or "RIGHT"
    local growthY = cfg.growthY or "DOWN"
    local spacingX = cfg.spacingX or 2
    local spacingY = cfg.spacingY or 2
    local containerBorderWidth = cfg.containerBorderWidth or 0

    local trayScale = iconSize / BLIZZARD_ICON_SIZE
    local scaledBorderWidth = iconBorderWidth / trayScale
    local bR, bG, bB, bA = addon:HexToRGB(cfg.iconBorderColor or "000000FF")
    local scaledSpacing = spacingX / trayScale
    local cols = math.min(perRow, maxIcons)
    local rows = math.ceil(maxIcons / cols)
    local cellW = iconSize + 2 * iconBorderWidth
    local cellH = iconSize + 2 * iconBorderWidth
    local containerW = cols * cellW + math.max(0, cols - 1) * spacingX
    local containerH = rows * cellH + math.max(0, rows - 1) * spacingY
    local container = CreateFrame("Frame", nil, frame)
    container:SetSize(containerW, containerH)

    if cfg.containerBackgroundColor then
        local r, g, b, a = self:HexToRGB(cfg.containerBackgroundColor)
        local bg = container:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(container)
        bg:SetColorTexture(r, g, b, a)
    end

    self:AddTextureBorder(container, containerBorderWidth, cfg.containerBorderColor or "00000000")

    local anchorFrame = frame
    if cfg.relativeToModule then
        local ref = cfg.relativeToModule
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

    local anchor = cfg.anchor or "BOTTOMLEFT"
    local yCompensation = 0
    if anchor:find("TOP") then
        yCompensation = -containerBorderWidth
    elseif anchor:find("BOTTOM") then
        yCompensation = containerBorderWidth
    end

    container:SetPoint(
        anchor,
        anchorFrame,
        cfg.relativePoint or "BOTTOMLEFT",
        cfg.offsetX or 0,
        (cfg.offsetY or 0) + yCompensation
    )

    local unit = nil
    local arenaIndex = nil
    local capturedTray = nil
    local originalParent = nil
    local originalPoints = nil

    local function SavePoints(tray)
        local points = {}
        local numPoints = addon:SecureCall(tray.GetNumPoints, tray) or 0
        for i = 1, numPoints do
            local p1, p2, p3, p4, p5 = addon:SecureCall(tray.GetPoint, tray, i)
            if p1 then
                points[i] = { p1, p2, p3, p4, p5 }
            end
        end
        return points
    end

    local function RestorePoints(tray, points)
        tray:ClearAllPoints()
        for _, pt in ipairs(points) do
            tray:SetPoint(unpack(pt))
        end
    end

    local function EnsureIconBorder(child)
        if not child._drBorderTop then
            child._drBorderTop    = child:CreateTexture(nil, "OVERLAY", nil, 7)
            child._drBorderBottom = child:CreateTexture(nil, "OVERLAY", nil, 7)
            child._drBorderLeft   = child:CreateTexture(nil, "OVERLAY", nil, 7)
            child._drBorderRight  = child:CreateTexture(nil, "OVERLAY", nil, 7)
        end

        local t = child._drBorderTop
        t:SetColorTexture(bR, bG, bB, bA)
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", child, "TOPLEFT", 0, 0)
        t:SetPoint("BOTTOMRIGHT", child, "TOPRIGHT", 0, 0)
        t:SetHeight(scaledBorderWidth)
        t:Show()

        local b = child._drBorderBottom
        b:SetColorTexture(bR, bG, bB, bA)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", child, "BOTTOMLEFT", 0, 0)
        b:SetPoint("TOPRIGHT", child, "BOTTOMRIGHT", 0, 0)
        b:SetHeight(scaledBorderWidth)
        b:Show()

        local l = child._drBorderLeft
        l:SetColorTexture(bR, bG, bB, bA)
        l:ClearAllPoints()
        l:SetPoint("TOPRIGHT", child, "TOPLEFT", 0, 0)
        l:SetPoint("BOTTOMRIGHT", child, "BOTTOMLEFT", 0, 0)
        l:SetWidth(scaledBorderWidth)
        l:Show()

        local r = child._drBorderRight
        r:SetColorTexture(bR, bG, bB, bA)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", child, "TOPRIGHT", 0, 0)
        r:SetPoint("BOTTOMLEFT", child, "BOTTOMRIGHT", 0, 0)
        r:SetWidth(scaledBorderWidth)
        r:Show()
    end

    local ICON_ZOOM = 0.15
    local function ApplyIconBorders(tray)
        for _, child in ipairs({ tray:GetChildren() }) do
            if child.Icon and child:IsShown() then
                EnsureIconBorder(child)
                child.Icon:SetTexCoord(ICON_ZOOM, 1 - ICON_ZOOM, ICON_ZOOM, 1 - ICON_ZOOM)
            end
        end
    end

    local function CaptureTray()
        if capturedTray then return end
        if not arenaIndex then return end

        local memberFrame = _G["CompactArenaFrameMember" .. arenaIndex]
        local tray = memberFrame.SpellDiminishStatusTray

        originalParent = tray:GetParent()
        originalPoints = SavePoints(tray)

        tray:SetParent(container)
        tray:ClearAllPoints()

        local unitToken = "arena" .. arenaIndex
        if tray.SetUnit then
            tray:SetUnit(unitToken)
        end

        tray:SetScale(trayScale)

        local vertAnchor = (growthY == "DOWN") and "TOP" or "BOTTOM"
        local horizAnchor = (growthX == "LEFT") and "RIGHT" or "LEFT"
        local anchor = vertAnchor .. horizAnchor
        tray:SetPoint(anchor, container, anchor, 0, 0)

        container:SetFrameLevel(frame:GetFrameLevel() + 20)
        tray:SetFrameLevel(container:GetFrameLevel() + 1)
        tray:Show()

        ApplyIconBorders(tray)

        if not tray._zenFramesLayoutHooked then
            hooksecurefunc(tray, "RefreshTrayLayout", function(self)
                local items = {}
                for _, child in ipairs({ self:GetChildren() }) do
                    if child.Icon and child:IsShown() then
                        items[#items + 1] = child
                    end
                end

                for i, item in ipairs(items) do
                    item:ClearAllPoints()
                    if i == 1 then
                        if growthX == "LEFT" then
                            item:SetPoint("RIGHT", self, "RIGHT", -scaledBorderWidth, 0)
                        else
                            item:SetPoint("LEFT", self, "LEFT", scaledBorderWidth, 0)
                        end
                    else
                        local prev = items[i - 1]
                        if growthX == "LEFT" then
                            item:SetPoint("RIGHT", prev, "LEFT", -(scaledSpacing + 2 * scaledBorderWidth), 0)
                        else
                            item:SetPoint("LEFT", prev, "RIGHT", scaledSpacing + 2 * scaledBorderWidth, 0)
                        end
                    end
                end

                ApplyIconBorders(self)
                local n = #items
                if n > 0 then
                    local iconW = BLIZZARD_ICON_SIZE
                    local totalW = n * iconW + (n - 1) * (scaledSpacing + 2 * scaledBorderWidth) + 2 * scaledBorderWidth
                    local totalH = iconW + 2 * scaledBorderWidth
                    self:SetSize(totalW, totalH)
                end
            end)
            tray._zenFramesLayoutHooked = true
        end

        capturedTray = tray
    end

    local function ReleaseTray()
        if not capturedTray then return end

        capturedTray:SetParent(originalParent)
        if originalPoints then
            RestorePoints(capturedTray, originalPoints)
        end

        capturedTray = nil
        originalParent = nil
        originalPoints = nil
    end

    local function ShowDRTracker()
        if not container:IsShown() then
            container:Show()
        end
        CaptureTray()
    end

    local function HideDRTracker()
        ReleaseTray()
        if container:IsShown() then
            container:Hide()
        end
    end

    local function UpdateVisibility(event)
        local inArena = IsInArena()
        if inArena and arenaIndex then
            ShowDRTracker()
        elseif event == "PLAYER_ENTERING_WORLD" then
            HideDRTracker()
        end
    end

    container:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateVisibility("PLAYER_ENTERING_WORLD")
        elseif event == "ARENA_OPPONENT_UPDATE" then
            if IsInArena() and arenaIndex and not capturedTray then
                CaptureTray()
            end
        end
    end)

    container:RegisterEvent("PLAYER_ENTERING_WORLD")
    container:RegisterEvent("ARENA_OPPONENT_UPDATE")

    hooksecurefunc(frame, "UpdateAllElements", function()
        local newUnit = frame.unit
        if newUnit ~= unit then
            unit = newUnit
            if unit and unit:match("^arena(%d+)$") then
                arenaIndex = tonumber(unit:match("^arena(%d+)$"))
            else
                arenaIndex = nil
            end
        end
    end)

    unit = frame.unit
    if unit and unit:match("^arena(%d+)$") then
        arenaIndex = tonumber(unit:match("^arena(%d+)$"))
    end

    frame.DRTracker = container

    container:Hide()

    C_Timer.After(1, function()
        UpdateVisibility("INIT")
    end)
end

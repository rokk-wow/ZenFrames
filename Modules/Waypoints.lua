local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Waypoint queue — sequential mode with nearest-neighbor sort per zone
-- ---------------------------------------------------------------------------

local waypoints = {}
local currentIndex = 0
local UpdateControlBar

local function ParseWayLine(line)
    line = line:gsub(",", " ")
    local mapId, x, y, name = line:match("#(%d+)%s+([%d%.]+)%s+([%d%.]+)%s*(.*)")
    if not mapId then
        x, y, name = line:match("([%d%.]+)%s+([%d%.]+)%s*(.*)")
    end
    mapId = tonumber(mapId)
    x = tonumber(x)
    y = tonumber(y)
    if not x or not y then return nil end
    if name then name = strtrim(name) end
    if name == "" then name = nil end
    return { mapId = mapId, x = x, y = y, name = name }
end

local function ParseMultiline(text)
    local results = {}
    for line in text:gmatch("[^\r\n]+") do
        line = strtrim(line)
        line = line:gsub("^/way%s+", "")
        line = line:gsub("^/zfway%s+", "")
        if line ~= "" then
            local wp = ParseWayLine(line)
            if wp then
                results[#results + 1] = wp
            end
        end
    end
    return results
end

local function GetPlayerWorldPos()
    local mapId = C_Map.GetBestMapForUnit("player")
    if not mapId then return nil, nil, nil end
    local pos = C_Map.GetPlayerMapPosition(mapId, "player")
    if not pos then return mapId, nil, nil end
    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapId, pos)
    if not worldPos then return mapId, nil, nil end
    return mapId, worldPos.x, worldPos.y
end

local function WaypointWorldPos(wp)
    local mapId = wp.mapId or C_Map.GetBestMapForUnit("player")
    if not mapId then return nil, nil end
    local mapPos = CreateVector2D(wp.x / 100, wp.y / 100)
    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapId, mapPos)
    if not worldPos then return nil, nil end
    return worldPos.x, worldPos.y
end

local function DistanceSq(ax, ay, bx, by)
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

local function SortNearestNeighborForZone(list, zoneMapId, startWorldX, startWorldY)
    local zoneWps = {}
    local otherWps = {}

    for _, wp in ipairs(list) do
        if wp.mapId == zoneMapId or wp.mapId == nil then
            zoneWps[#zoneWps + 1] = wp
        else
            otherWps[#otherWps + 1] = wp
        end
    end

    local sorted = {}
    local used = {}
    local cx, cy = startWorldX, startWorldY

    while #sorted < #zoneWps do
        local bestIdx, bestDist = nil, math.huge
        for i, wp in ipairs(zoneWps) do
            if not used[i] then
                local wx, wy = WaypointWorldPos(wp)
                if wx and wy and cx and cy then
                    local d = DistanceSq(cx, cy, wx, wy)
                    if d < bestDist then
                        bestDist = d
                        bestIdx = i
                    end
                elseif not bestIdx then
                    bestIdx = i
                end
            end
        end
        if not bestIdx then break end
        used[bestIdx] = true
        sorted[#sorted + 1] = zoneWps[bestIdx]
        cx, cy = WaypointWorldPos(zoneWps[bestIdx])
    end

    for _, wp in ipairs(otherWps) do
        sorted[#sorted + 1] = wp
    end

    return sorted
end

local function ResortForCurrentZone()
    if #waypoints == 0 then return end

    local zoneMapId, wx, wy = GetPlayerWorldPos()
    if not zoneMapId then return end

    local remaining = {}
    for i = currentIndex, #waypoints do
        remaining[#remaining + 1] = waypoints[i]
    end

    remaining = SortNearestNeighborForZone(remaining, zoneMapId, wx, wy)

    local visited = {}
    for i = 1, currentIndex - 1 do
        visited[#visited + 1] = waypoints[i]
    end

    for _, wp in ipairs(remaining) do
        visited[#visited + 1] = wp
    end

    waypoints = visited
    currentIndex = math.max(currentIndex, 1)
end

local function SetActiveWaypoint(wp)
    if not wp then
        C_Map.ClearUserWaypoint()
        C_SuperTrack.SetSuperTrackedUserWaypoint(false)
        return
    end

    local mapId = wp.mapId or C_Map.GetBestMapForUnit("player")
    if not mapId then return end

    local mapPoint = UiMapPoint.CreateFromCoordinates(mapId, wp.x / 100, wp.y / 100)
    C_Map.SetUserWaypoint(mapPoint)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    local label = wp.name or string.format("%.1f, %.1f", wp.x, wp.y)
    local mapInfo = C_Map.GetMapInfo(mapId)
    local zoneName = mapInfo and mapInfo.name or tostring(mapId)
    addon:Info(string.format("Waypoint %d/%d — %s (%s)", currentIndex, #waypoints, label, zoneName))
end

local function AdvanceWaypoint()
    if #waypoints == 0 then
        addon:Info("No waypoints queued.")
        return
    end

    currentIndex = currentIndex + 1
    if currentIndex > #waypoints then
        addon:Info("All waypoints visited. Queue cleared.")
        waypoints = {}
        currentIndex = 0
        C_Map.ClearUserWaypoint()
        C_SuperTrack.SetSuperTrackedUserWaypoint(false)
        UpdateControlBar()
        return
    end

    SetActiveWaypoint(waypoints[currentIndex])
    UpdateControlBar()
end

local function GoBackWaypoint()
    if #waypoints == 0 then
        addon:Info("No waypoints queued.")
        return
    end

    if currentIndex <= 1 then
        addon:Info("Already at the first waypoint.")
        return
    end

    currentIndex = currentIndex - 1
    SetActiveWaypoint(waypoints[currentIndex])
    UpdateControlBar()
end

local function LoadWaypoints(list)
    waypoints = list
    currentIndex = 0

    local zoneMapId, wx, wy = GetPlayerWorldPos()
    if zoneMapId then
        waypoints = SortNearestNeighborForZone(waypoints, zoneMapId, wx, wy)
    end

    addon:Info(string.format("Route loaded — %d waypoint(s). First map pin added.", #waypoints))
    AdvanceWaypoint()
    UpdateControlBar()
end

local function ClearWaypoints()
    waypoints = {}
    currentIndex = 0
    C_Map.ClearUserWaypoint()
    C_SuperTrack.SetSuperTrackedUserWaypoint(false)
    addon:Info("Waypoints cleared.")
    UpdateControlBar()
end

local function PrintStatus()
    if #waypoints == 0 then
        addon:Info("No waypoints queued.")
        return
    end
    addon:Info(string.format("%d/%d waypoints remaining.", #waypoints - currentIndex, #waypoints))
    for i, wp in ipairs(waypoints) do
        local marker = (i == currentIndex) and " >> " or "    "
        local label = wp.name or string.format("%.1f, %.1f", wp.x, wp.y)
        local zone = wp.mapId and ("#" .. wp.mapId) or "current"
        addon:Info(string.format("%s%d. [%s] %s", marker, i, zone, label))
    end
end

-- ---------------------------------------------------------------------------
-- Dialog
-- ---------------------------------------------------------------------------

local waypointDialog

local function CreateWaypointDialog()
    if waypointDialog then return waypointDialog end

    waypointDialog = addon:CreateDialog({
        name = "ZenFramesWaypointDialog",
        title = "Waypoints",
        width = 380,
        height = 280,
        movable = true,
        clampedToScreen = true,
        showCloseButton = true,
        dismissOnEscape = true,
        footerButtons = {
            {
                text = "Load Route",
                onClick = function(dialog)
                    local text = dialog._waypointInput and dialog._waypointInput:GetText() or ""
                    local list = ParseMultiline(text)
                    if #list == 0 then
                        addon:Info("No valid waypoints found in input.")
                        return
                    end
                    LoadWaypoints(list)
                    addon:HideDialog(dialog)
                end,
            },
            {
                text = "Clear All",
                onClick = function(dialog)
                    ClearWaypoints()
                    if dialog._waypointInput then
                        dialog._waypointInput:SetText("")
                    end
                end,
            },
        },
    })

    local yOffset = waypointDialog._contentTop

    local _, newY = addon:DialogAddDescription(waypointDialog, yOffset,
        "Paste /way commands below (one per line):")
    yOffset = newY

    local scrollBg = CreateFrame("Frame", nil, waypointDialog, "BackdropTemplate")
    local padLeft = 12
    scrollBg:SetPoint("TOPLEFT", waypointDialog, "TOPLEFT", padLeft, yOffset - 4)
    scrollBg:SetPoint("RIGHT", waypointDialog, "RIGHT", -padLeft, 0)
    scrollBg:SetHeight(140)
    scrollBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    scrollBg:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    scrollBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local scroll = CreateFrame("ScrollFrame", "ZenFramesWaypointScroll", scrollBg, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", scrollBg, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", scrollBg, "BOTTOMRIGHT", -24, 6)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(waypointDialog._fontPath, 11, "OUTLINE")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetWidth(scroll:GetWidth() or 300)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    scroll:SetScrollChild(editBox)
    waypointDialog._waypointInput = editBox

    return waypointDialog
end

-- ---------------------------------------------------------------------------
-- Macro batching — accumulate rapid-fire /way calls within the same frame
-- ---------------------------------------------------------------------------

local pendingBatch = {}
local batchTimer = nil

local function FlushBatch()
    batchTimer = nil
    if #pendingBatch == 0 then return end
    local list = {}
    for _, wp in ipairs(pendingBatch) do
        list[#list + 1] = wp
    end
    wipe(pendingBatch)
    LoadWaypoints(list)
end

local function QueueWaypoint(wp)
    pendingBatch[#pendingBatch + 1] = wp
    if not batchTimer then
        batchTimer = C_Timer.After(0, FlushBatch)
    end
end

-- ---------------------------------------------------------------------------
-- Slash command handler
-- ---------------------------------------------------------------------------

local function HandleWayCommand(self, ...)
    local args = { ... }
    if #args == 0 then
        CreateWaypointDialog()
        addon:ShowDialog(waypointDialog, "standalone")
        return
    end

    local sub = args[1]:lower()
    if sub == "next" then
        AdvanceWaypoint()
        return
    end
    if sub == "back" then
        GoBackWaypoint()
        return
    end
    if sub == "clear" then
        ClearWaypoints()
        return
    end
    if sub == "list" then
        PrintStatus()
        return
    end

    local raw = table.concat(args, " ")
    local list = ParseMultiline(raw)
    if #list == 1 then
        QueueWaypoint(list[1])
    elseif #list > 1 then
        LoadWaypoints(list)
    else
        addon:Info("Could not parse waypoint. Format: /way #mapId x y name")
    end
end

-- ---------------------------------------------------------------------------
-- Zone change listener — re-sort when entering a new zone
-- ---------------------------------------------------------------------------

local zoneFrame

local function EnsureZoneListener()
    if zoneFrame then return end
    zoneFrame = CreateFrame("Frame")
    zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    zoneFrame:RegisterEvent("NAVIGATION_DESTINATION_REACHED")
    zoneFrame:SetScript("OnEvent", function(self, event)
        if event == "NAVIGATION_DESTINATION_REACHED" then
            if #waypoints > 0 and currentIndex >= 1 and currentIndex <= #waypoints then
                local wp = waypoints[currentIndex]
                local label = wp.name or string.format("%.1f, %.1f", wp.x, wp.y)
                addon:Info(string.format("Waypoint reached — %s", label))
                AdvanceWaypoint()
            end
            return
        end

        if #waypoints > 0 and currentIndex > 0 then
            ResortForCurrentZone()
            if currentIndex <= #waypoints then
                SetActiveWaypoint(waypoints[currentIndex])
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Control bar — top of screen
-- ---------------------------------------------------------------------------

local controlBar

function UpdateControlBar()
    if not controlBar then return end
    if #waypoints > 0 and currentIndex >= 1 and currentIndex <= #waypoints then
        local wp = waypoints[currentIndex]
        local label = wp.name or string.format("%.1f, %.1f", wp.x, wp.y)
        local mapId = wp.mapId or C_Map.GetBestMapForUnit("player")
        local mapInfo = mapId and C_Map.GetMapInfo(mapId)
        local zoneName = mapInfo and mapInfo.name or ""
        local titleText = string.format("Waypoint %d/%d — %s", currentIndex, #waypoints, label)
        if zoneName ~= "" then
            titleText = titleText .. " (" .. zoneName .. ")"
        end
        controlBar._title:SetText(titleText)
        local textWidth = controlBar._title:GetStringWidth()
        controlBar:SetWidth(math.max(120, textWidth + 24))
        controlBar:Show()
    else
        controlBar:Hide()
    end
end

local function CreateControlBar()
    if controlBar then return controlBar end

    local bar = CreateFrame("Frame", "ZenFramesWaypointBar", UIParent, "BackdropTemplate")
    bar:SetSize(120, 50)
    bar:SetPoint("TOP", UIParent, "TOP", 0, -10)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    bar:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    bar:SetBackdropBorderColor(0, 0, 0, 1)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", bar.StopMovingOrSizing)

    local fontPath = addon:FetchFont() or "Fonts\\FRIZQT__.TTF"

    local title = bar:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 13, "OUTLINE")
    title:SetPoint("TOP", bar, "TOP", 0, -4)
    title:SetText("")
    title:SetTextColor(0.8, 0.8, 0.8, 1)
    bar._title = title

    local btnSize = 22
    local spacing = 6
    local totalWidth = btnSize * 3 + spacing * 2
    local startX = -totalWidth / 2 + btnSize / 2

    local function CreateAtlasButton(parent, atlas, xOffset, onClick)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(btnSize, btnSize)
        btn:SetPoint("BOTTOM", parent, "BOTTOM", xOffset, 6)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAtlas(atlas)
        icon:SetAllPoints()
        btn._icon = icon

        btn:SetScript("OnEnter", function(self)
            self._icon:SetAlpha(1)
        end)
        btn:SetScript("OnLeave", function(self)
            self._icon:SetAlpha(0.7)
        end)
        icon:SetAlpha(0.7)

        btn:SetScript("OnClick", onClick)
        return btn
    end

    CreateAtlasButton(bar, "common-icon-offscreen", startX, function() GoBackWaypoint() end)
    CreateAtlasButton(bar, "common-icon-redx", startX + btnSize + spacing, function() ClearWaypoints() end)
    CreateAtlasButton(bar, "common-icon-forwardarrow", startX + (btnSize + spacing) * 2, function() AdvanceWaypoint() end)

    controlBar = bar
    bar:Hide()
    return bar
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeWaypoints()
    local cfg = self.config and self.config.extras and self.config.extras.waypoints
    if not cfg or not cfg.enabled then return end

    EnsureZoneListener()
    CreateControlBar()

    local useZfway = false
    if SlashCmdList["WAY"] or SlashCmdList["TOMTOM_WAY"] then
        useZfway = true
    end
    for key, val in pairs(_G) do
        if type(key) == "string" and key:match("^SLASH_") and val == "/way" then
            useZfway = true
            break
        end
    end

    if useZfway then
        self:RegisterSlashCommand("zfway", HandleWayCommand)
        addon:Info("/way is taken — use /zfway instead.")
    else
        self:RegisterSlashCommand("way", HandleWayCommand)
    end
    self:RegisterSlashCommand("zfwaynext", function() AdvanceWaypoint() end)
end

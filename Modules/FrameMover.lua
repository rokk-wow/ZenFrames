local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local unitConfigMap = {
    player = "player",
    target = "target",
    targettarget = "targetTarget",
    focus = "focus",
    focustarget = "focusTarget",
    pet = "pet",
}

--- Return the screen-space (x, y) of a given anchor point on a frame.
local function GetAnchorPosition(frame, point)
    local l, b, w, h = frame:GetRect()
    if not l then return 0, 0 end

    local x, y

    if point:find("LEFT") then
        x = l
    elseif point:find("RIGHT") then
        x = l + w
    else
        x = l + w / 2
    end

    if point:find("BOTTOM") then
        y = b
    elseif point:find("TOP") then
        y = b + h
    else
        y = b + h / 2
    end

    return x, y
end

--- Save a frame's offset to savedVars.data.framePositions.
function addon:SaveFramePosition(configKey, offsetX, offsetY)
    self.savedVars.data.framePositions = self.savedVars.data.framePositions or {}
    self.savedVars.data.framePositions[configKey] = {
        offsetX = offsetX,
        offsetY = offsetY,
    }
end

--- Reset all saved frame positions and reload.
function addon:ResetFramePositions()
    if self.savedVars and self.savedVars.data then
        self.savedVars.data.framePositions = nil
    end
    ReloadUI()
end

--- Recalculate offsets after a frame has been freely moved, re-anchor it, and save.
local function FinishMove(frame, configKey)
    frame:StopMovingOrSizing()

    local cfg = addon.config[configKey]
    local relFrame = _G[cfg.relativeTo] or UIParent

    local myX, myY = GetAnchorPosition(frame, cfg.anchor)
    local relX, relY = GetAnchorPosition(relFrame, cfg.relativePoint)

    local newOffsetX = math.floor(myX - relX + 0.5)
    local newOffsetY = math.floor(myY - relY + 0.5)

    -- Capture size before clearing (ClearAllPoints can invalidate size)
    local w, h = frame:GetSize()
    frame:ClearAllPoints()
    frame:SetSize(w, h)
    frame:SetPoint(cfg.anchor, relFrame, cfg.relativePoint, newOffsetX, newOffsetY)

    cfg.offsetX = newOffsetX
    cfg.offsetY = newOffsetY
    addon:SaveFramePosition(configKey, newOffsetX, newOffsetY)
end

--- Attach CTRL+SHIFT+drag to a unit frame.
function addon:AttachMover(frame, configKey)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local isMoving = false

    frame:HookScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and IsControlKeyDown() and IsShiftKeyDown() and not InCombatLockdown() then
            self:StartMoving()
            isMoving = true
        end
    end)

    frame:HookScript("OnMouseUp", function(self, button)
        if isMoving then
            isMoving = false
            FinishMove(self, configKey)
        end
    end)
end

--- Attach CTRL+SHIFT+drag on child oUF frames to move the parent container.
function addon:AttachGroupMover(container, configKey)
    container:SetMovable(true)
    container:SetClampedToScreen(true)

    local isMoving = false

    if container.frames then
        for _, child in ipairs(container.frames) do
            child:HookScript("OnMouseDown", function(self, button)
                if button == "LeftButton" and IsControlKeyDown() and IsShiftKeyDown() and not InCombatLockdown() then
                    container:StartMoving()
                    isMoving = true
                end
            end)

            child:HookScript("OnMouseUp", function(self, button)
                if isMoving then
                    isMoving = false
                    FinishMove(container, configKey)
                end
            end)
        end
    end
end

--- Wire up movers on all spawned unit frames and group containers.
function addon:SetupFrameMovers()
    for unit, configKey in pairs(unitConfigMap) do
        local frame = self.unitFrames[unit]
        if frame and self.config[configKey] and self.config[configKey].enabled then
            self:AttachMover(frame, configKey)
        end
    end

    if self.groupContainers then
        for configKey, container in pairs(self.groupContainers) do
            if self.config[configKey] and self.config[configKey].enabled then
                self:AttachGroupMover(container, configKey)
            end
        end
    end
end

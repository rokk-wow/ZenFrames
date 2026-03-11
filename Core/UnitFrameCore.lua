local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

addon.highlightUpdaters = {}

addon.pvpFriendlyProfiles = {
    blitz = true,
    battleground = true,
    epicBattleground = true,
}

addon.unitToConfigKeyMap = {
    player = "player",
    target = "target",
    targettarget = "targetTarget",
    focus = "focus",
    focustarget = "focusTarget",
    pet = "pet",
}

function addon:IsArenaInstance()
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
    if #self.highlightUpdaters == 0 then return end

    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        for _, fn in ipairs(addon.highlightUpdaters) do
            fn()
        end
    end)
end

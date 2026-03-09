local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Minimap Icon Collection (Addon Config Buttons)
-- ---------------------------------------------------------------------------

local blizzardFrames = {
    ["MinimapBackdrop"] = true,
    ["MinimapZoomIn"] = true,
    ["MinimapZoomOut"] = true,
    ["MiniMapTracking"] = true,
    ["MiniMapMailFrame"] = true,
    ["MiniMapMailBorder"] = true,
    ["MinimapCompassTexture"] = true,
    ["GameTimeFrame"] = true,
    ["TimeManagerClockButton"] = true,
    ["QueueStatusButton"] = true,
    ["MinimapCluster"] = true,
    ["AddonCompartmentFrame"] = true,
    ["ExpansionLandingPageMinimapButton"] = true,
}

local function IsAddonMinimapButton(frame)
    if not frame then return false end
    if not frame:IsObjectType("Button") and not frame:IsObjectType("Frame") then return false end

    local name = frame:GetName()
    if not name then return false end
    if blizzardFrames[name] then return false end

    if name:match("^LibDBIcon10_") then return true end
    if name:match("^MinimapButton") then return true end
    if name:match("Minimap") and frame:IsObjectType("Button") then return true end

    local width = frame:GetWidth()
    local height = frame:GetHeight()
    if width > 0 and width <= 40 and height > 0 and height <= 40 and frame:IsObjectType("Button") then
        return true
    end

    return false
end

local function CollectMinimapButtons()
    local buttons = {}
    local seen = {}

    local containers = { Minimap, MinimapBackdrop, MinimapCluster }
    for _, parent in ipairs(containers) do
        if parent then
            for _, child in ipairs({ parent:GetChildren() }) do
                local name = child:GetName()
                local key = name or tostring(child)
                if not seen[key] and IsAddonMinimapButton(child) then
                    seen[key] = true
                    buttons[#buttons + 1] = child
                end
            end
        end
    end

    table.sort(buttons, function(a, b)
        local nameA = a:GetName() or ""
        local nameB = b:GetName() or ""
        return nameA < nameB
    end)

    return buttons
end

local function RepositionMinimapButtons(cfg)
    local buttons = CollectMinimapButtons()
    if #buttons == 0 then return end

    local attachFrame = _G[cfg.attachTo]
    if not attachFrame then return end

    for i, button in ipairs(buttons) do
        button:SetParent(UIParent)

        local originalWidth = button:GetWidth()
        if originalWidth > 0 then
            local scale = cfg.size / originalWidth
            button:SetScale(scale)
        end

        button:ClearAllPoints()

        if i == 1 then
            button:SetPoint(cfg.anchorPoint, attachFrame, cfg.attachPoint, cfg.offsetX, cfg.offsetY)
        else
            button:SetPoint(cfg.anchorPoint, buttons[i - 1], cfg.attachPoint, cfg.spacing, 0)
        end

        button:SetFrameStrata("MEDIUM")
        button:Show()
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeMinimapAddonIcons()
    local cfg = self.config and self.config.extras and self.config.extras.minimapAddonIcons
    if not cfg or not cfg.enabled then return end

    C_Timer.After(3, function()
        RepositionMinimapButtons(cfg)
    end)
end

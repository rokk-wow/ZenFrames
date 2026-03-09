local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Dungeon Finder Eye (QueueStatusButton)
-- ---------------------------------------------------------------------------

local function RepositionEye(cfg)
    if InCombatLockdown() then return end

    local eye = QueueStatusButton
    if not eye then return end

    local attachFrame = _G[cfg.attachTo]
    if not attachFrame then return end

    local scale = cfg.size / 45
    eye:SetScale(scale)
    eye:ClearAllPoints()
    eye:SetPoint(cfg.anchorPoint, attachFrame, cfg.attachPoint, cfg.offsetX / scale, cfg.offsetY / scale)
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeDungeonFinderEye()
    local cfg = self.config and self.config.extras and self.config.extras.dungeonFinderEye
    if not cfg or not cfg.enabled then return end

    local eye = QueueStatusButton
    if not eye then return end

    eye:SetParent(UIParent)

    RepositionEye(cfg)

    hooksecurefunc(MicroMenu, "UpdateQueueStatusAnchors", function()
        RepositionEye(cfg)
    end)

    hooksecurefunc(MicroMenu, "Layout", function()
        RepositionEye(cfg)
    end)
end

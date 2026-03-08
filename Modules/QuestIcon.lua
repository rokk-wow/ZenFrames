local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Quest Objective Detection
-- ---------------------------------------------------------------------------

local function IsQuestObjectiveUnit(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if UnitIsPlayer(unit) or UnitIsDead(unit) then
        return false
    end

    if not UnitCanAttack("player", unit) then
        return false
    end

    if C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unit) then
        return true
    end

    if UnitIsQuestBoss and UnitIsQuestBoss(unit) then
        return true
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Nameplate Unit Resolution
-- ---------------------------------------------------------------------------

local function GetNameplateUnit(nameplate)
    if not nameplate then
        return nil
    end

    if nameplate.namePlateUnitToken then
        return nameplate.namePlateUnitToken
    end

    if nameplate.UnitFrame and nameplate.UnitFrame.unit then
        return nameplate.UnitFrame.unit
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- Quest Icon Management
-- ---------------------------------------------------------------------------

local function EnsureQuestIcon(nameplate, cfg)
    if not nameplate.ZenFrames_QuestIcon then
        local icon = nameplate:CreateTexture(nil, "OVERLAY")
        icon:SetAtlas(cfg.atlas)
        icon:SetSize(cfg.size, cfg.size)
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", nameplate, "LEFT", cfg.offsetX, cfg.offsetY)
        icon:Hide()
        nameplate.ZenFrames_QuestIcon = icon
    end

    return nameplate.ZenFrames_QuestIcon
end

local function UpdateQuestIconForUnit(unit, cfg)
    if not unit then return end

    local nameplate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end

    local icon = EnsureQuestIcon(nameplate, cfg)
    if IsQuestObjectiveUnit(unit) then
        icon:Show()
    else
        icon:Hide()
    end
end

local function UpdateAllVisibleQuestIcons(cfg)
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end

    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = GetNameplateUnit(nameplate)
        if unit then
            UpdateQuestIconForUnit(unit, cfg)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeQuestIcon()
    local cfg = self.config and self.config.extras and self.config.extras.questIcon
    if not cfg or not cfg.enabled then return end

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(eventTable, eventName, unit)
        UpdateQuestIconForUnit(unit, cfg)
    end)

    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(eventTable, eventName, unit)
        if not unit or not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end

        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate and nameplate.ZenFrames_QuestIcon then
            nameplate.ZenFrames_QuestIcon:Hide()
        end
    end)

    self:RegisterEvent("QUEST_LOG_UPDATE", function()
        UpdateAllVisibleQuestIcons(cfg)
    end)

    self:RegisterEvent("QUEST_ACCEPTED", function()
        UpdateAllVisibleQuestIcons(cfg)
    end)

    self:RegisterEvent("QUEST_REMOVED", function()
        UpdateAllVisibleQuestIcons(cfg)
    end)

    self:RegisterEvent("QUEST_TURNED_IN", function()
        UpdateAllVisibleQuestIcons(cfg)
    end)

    C_Timer.After(0.25, function()
        UpdateAllVisibleQuestIcons(cfg)
    end)
end

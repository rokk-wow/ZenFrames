-- ---------------------------------------------------------------------------
-- GearCheck — warns when gear set or talent loadout doesn't match zone rules
-- ---------------------------------------------------------------------------
local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon._gearCheckFrame = nil

function addon:GetEquippedGearSetName()
    local equipSetIDs = C_EquipmentSet.GetEquipmentSetIDs()
    if not equipSetIDs then return nil end
    for _, setID in ipairs(equipSetIDs) do
        local name, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
        if isEquipped then
            return name
        end
    end
    return nil
end

function addon:GetActiveLoadoutName()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID = GetSpecializationInfo(specIndex)
    local configID = C_ClassTalents.GetActiveConfigID()

    local savedFromSpec = specID and C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    local savedFromConfig = configID and C_ClassTalents.GetLastSelectedSavedConfigID(configID)

    local savedConfigID = savedFromSpec or savedFromConfig
    if not savedConfigID then return nil end
    local savedInfo = C_Traits.GetConfigInfo(savedConfigID)
    return savedInfo and savedInfo.name or nil
end

function addon:IsWarModeOn()
    return C_PvP.IsWarModeDesired()
end

function addon:FindGearCheckRule(zone, warMode)
    local cfg = self.config and self.config.extras and self.config.extras.gearCheck
    if not cfg or not cfg.rules then return nil end

    for _, rule in ipairs(cfg.rules) do
        if rule.zone == zone then
            if zone == "world" then
                if rule.warMode == warMode then
                    return rule
                end
            else
                return rule
            end
        end
    end
    return nil
end

function addon:RunGearCheck()
    local cfg = self.config and self.config.extras and self.config.extras.gearCheck
    if not cfg or not cfg.enabled then
        self:HideGearCheckWarning()
        return
    end

    local zone = self:GetCurrentZone()
    local warMode = self:IsWarModeOn()
    local rule = self:FindGearCheckRule(zone, warMode)

    if not rule then
        self:HideGearCheckWarning()
        return
    end

    local currentGearSet = self:GetEquippedGearSetName()
    local currentLoadout = self:GetActiveLoadoutName()

    local wrongGear = rule.gearSet and rule.gearSet ~= "" and currentGearSet ~= rule.gearSet
    local wrongLoadout = rule.loadout and rule.loadout ~= "" and currentLoadout ~= rule.loadout

    local messages = {}
    if wrongGear then
        messages[#messages + 1] = string.format(self:L("gearCheckWrongGearSet"), rule.gearSet)
    end
    if wrongLoadout then
        messages[#messages + 1] = string.format(self:L("gearCheckWrongLoadout"), rule.loadout)
    end

    if #messages > 0 then
        self:ShowGearCheckWarning(cfg, table.concat(messages, "\n"))
    else
        self:HideGearCheckWarning()
    end
end

function addon:ShowGearCheckWarning(cfg, message)
    if not self._gearCheckFrame then
        local container = CreateFrame("Frame", "ZenFramesGearCheckWarning", UIParent)
        container:SetSize(cfg.warningSize or 64, (cfg.warningSize or 64) + 30)
        container:SetPoint("TOP", UIParent, "TOP", 0, cfg.warningOffsetY or -150)
        container:SetFrameStrata("DIALOG")
        container:SetFrameLevel(100)

        local icon = container:CreateTexture(nil, "ARTWORK")
        icon:SetSize(cfg.warningSize or 64, cfg.warningSize or 64)
        icon:SetPoint("TOP", container, "TOP", 0, 0)
        icon:SetAtlas(cfg.warningAtlas or "icons_64x64_important")
        container.Icon = icon

        local fontPath = self:GetFontPath()
        local text = container:CreateFontString(nil, "OVERLAY")
        text:SetFont(fontPath or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        text:SetPoint("TOP", icon, "BOTTOM", 0, -6)
        text:SetTextColor(1, 0.8, 0, 1)
        text:SetJustifyH("CENTER")
        text:SetWidth(400)
        container.Text = text

        self._gearCheckFrame = container
    end

    self._gearCheckFrame.Text:SetText(message)
    self._gearCheckFrame:Show()
end

function addon:HideGearCheckWarning()
    if self._gearCheckFrame then
        self._gearCheckFrame:Hide()
    end
end

function addon:InitializeGearCheck()
    local cfg = self.config and self.config.extras and self.config.extras.gearCheck
    if not cfg or not cfg.enabled then return end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            addon:HideGearCheckWarning()
            return
        end
        if InCombatLockdown() then return end
        C_Timer.After(0.5, function()
            if InCombatLockdown() then return end
            addon:RunGearCheck()
        end)
    end)
end

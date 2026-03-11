local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:UpdateArenaFrameVisibility()
    local inArena = self:IsArenaInstance()

    if InCombatLockdown() then
        self._zfPendingArenaVisibilityUpdate = true
        return
    end

    self._zfPendingArenaVisibilityUpdate = false

    for unit, frame in pairs(self.unitFrames or {}) do
        local configKey = self.unitToConfigKeyMap[unit]
        local cfg = configKey and self.config and self.config[configKey]

        if frame and cfg and cfg.enabled then
            local shouldHide = cfg.hideInArena == true and inArena
            frame._zfHideInArenaActive = shouldHide

            if shouldHide then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end
end

function addon:EnsureArenaVisibilityEventFrame()
    if self._zfArenaVisibilityEventFrame then return end

    local arenaVisibilityEventFrame = CreateFrame("Frame")
    arenaVisibilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    arenaVisibilityEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    arenaVisibilityEventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    arenaVisibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    arenaVisibilityEventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if addon._zfPendingArenaVisibilityUpdate then
                addon:UpdateArenaFrameVisibility()
            end
            return
        end

        addon:UpdateArenaFrameVisibility()
    end)

    self._zfArenaVisibilityEventFrame = arenaVisibilityEventFrame
end

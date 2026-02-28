local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local DEFAULT_SPELL_ID = 336126

local function IsInArena()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "arena")
end

function addon:AddTrinket(frame, cfg)
    local size = cfg.iconSize
    local borderWidth = cfg.borderWidth

    local trinket = CreateFrame("Frame", nil, frame)
    trinket:SetSize(size, size)

    local anchorFrame = frame

    trinket:SetPoint(
        cfg.anchor,
        anchorFrame,
        cfg.relativePoint,
        cfg.offsetX,
        cfg.offsetY + borderWidth
    )

    local icon = trinket:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(trinket)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    trinket.Icon = icon

    local defaultTexture = C_Spell.GetSpellTexture(DEFAULT_SPELL_ID)
    if defaultTexture then
        icon:SetTexture(defaultTexture)
    end

    addon:AddTextureBorder(trinket, borderWidth, cfg.borderColor)

    local cooldown = CreateFrame("Cooldown", nil, trinket, "CooldownFrameTemplate")
    cooldown:SetAllPoints(trinket)
    cooldown:SetDrawEdge(false)
    cooldown:SetReverse(true)
    cooldown:SetDrawSwipe(cfg.showSwipe ~= false)
    cooldown.noCooldownCount = not (cfg.showCooldownNumbers ~= false)
    cooldown:SetHideCountdownNumbers(not (cfg.showCooldownNumbers ~= false))
    trinket.Cooldown = cooldown

    local cooldownDesaturate = cfg.cooldownDesaturate ~= false
    local cooldownAlpha = cfg.cooldownAlpha

    trinket.spellID = nil
    trinket.unit = nil

    local function SetSpellTexture(spellID)
        if spellID and spellID > 0 then
            trinket.spellID = spellID
            local tex = C_Spell.GetSpellTexture(spellID)
            if tex then
                icon:SetTexture(tex)
            end
        end
    end

    local function UpdateCooldown()
        local unit = trinket.unit
        if not unit then return end

        local spellID, startTimeMs, durationMs = addon:SecureCall(C_PvP.GetArenaCrowdControlInfo, unit)

        if spellID and spellID > 0 then
            SetSpellTexture(spellID)
        end

        local startTime = startTimeMs and (startTimeMs / 1000) or 0
        local duration = durationMs and (durationMs / 1000) or 0

        if duration > 0 then
            cooldown:SetCooldown(startTime, duration)
            if cooldownDesaturate then
                icon:SetDesaturated(true)
            end
            icon:SetAlpha(cooldownAlpha)
        else
            cooldown:Clear()
            icon:SetDesaturated(false)
            icon:SetAlpha(1)
        end
    end

    local function UpdateVisibility()
        if IsInArena() then
            trinket:Show()
        else
            trinket:Hide()
        end
    end

    local function RequestAndUpdate()
        if not IsInArena() then return end
        local unit = trinket.unit
        if not unit or not UnitExists(unit) then return end
        C_PvP.RequestCrowdControlSpell(unit)
        UpdateCooldown()
    end

    local function ResetState()
        trinket.spellID = nil
        if defaultTexture then
            icon:SetTexture(defaultTexture)
        end
        icon:SetDesaturated(false)
        icon:SetAlpha(1)
        cooldown:Clear()
    end

    trinket:SetScript("OnEvent", function(self, event, ...)
        if event == "ARENA_COOLDOWNS_UPDATE" then
            local unitTarget = ...
            if unitTarget and unitTarget == trinket.unit then
                UpdateCooldown()
            end
        elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
            local unitToken, rawSpellID = ...
            local spellID = addon:SecureCall(tonumber, rawSpellID)
            if unitToken and unitToken == trinket.unit then
                SetSpellTexture(spellID)
                UpdateCooldown()
            end
        elseif event == "PVP_MATCH_STATE_CHANGED" then
            local matchState = C_PvP.GetActiveMatchState()
            if matchState == Enum.PvPMatchState.StartUp then
                ResetState()
            end
            RequestAndUpdate()
        elseif event == "PLAYER_ENTERING_WORLD" then
            ResetState()
            UpdateVisibility()
            C_Timer.After(1, RequestAndUpdate)
        elseif event == "GROUP_ROSTER_UPDATE" then
            UpdateVisibility()
            RequestAndUpdate()
        end
    end)

    trinket:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    trinket:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    trinket:RegisterEvent("PVP_MATCH_STATE_CHANGED")
    trinket:RegisterEvent("PLAYER_ENTERING_WORLD")
    trinket:RegisterEvent("GROUP_ROSTER_UPDATE")

    hooksecurefunc(frame, "UpdateAllElements", function()
        trinket.unit = frame.unit
        RequestAndUpdate()
    end)

    trinket.unit = frame.unit

    frame.Trinket = trinket
    addon:AttachPlaceholder(trinket)

    trinket:Hide()

    C_Timer.After(1, function()
        UpdateVisibility()
        RequestAndUpdate()
    end)
end

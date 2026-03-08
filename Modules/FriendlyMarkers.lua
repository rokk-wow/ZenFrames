local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

addon.friendlyMarkerSettings = {
    iconSize = 40,
    borderSize = 64,
    iconWidth = 64,
    iconHeight = 64,
    classIconPath = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES",
    updateDelay = 0.1,
    defaultVerticalOffset = 40,
    defaultHighlightScale = 1.25,
    nameplateSizeOffsetMultiplier = 10,
    batchSize = 3,
    batchInterval = 0.03,
    nameplateQueue = {},
    queueTimer = nil,
    nameplateUpdateTimer = nil,
}

addon.friendlyMarkerUnitSpecs = {}

addon.friendlyMarkerTextures = {
    ["CovenantSanctum-Renown-DoubleArrow"]  = { rotation = math.pi / 2 },
    ["Azerite-PointingArrow"]               = { rotation = 0 },
    ["NPE_ArrowDown"]                       = { rotation = 0 },
    ["common-icon-forwardarrow"]            = { rotation = -math.pi / 2 },
    ["plunderstorm-nameplates-icon-2"]      = { rotation = 0 },
    ["charactercreate-icon-customize-body-selected"] = { rotation = 0 },
    ["housing-layout-room-orb-ring-highlight"]       = { rotation = 0 },
    ["plunderstorm-map-zoneYellow-hover"]   = { rotation = 0 },
    ["Customization_Fixture_Node_Selected"] = { rotation = 0 },
    ["honorsystem-icon-prestige-1"]         = { rotation = 0 },
    ["honorsystem-icon-prestige-2"]         = { rotation = 0 },
    ["honorsystem-icon-prestige-3"]         = { rotation = 0 },
    ["honorsystem-icon-prestige-4"]         = { rotation = 0 },
}

-- ---------------------------------------------------------------------------
-- Zone Check
-- ---------------------------------------------------------------------------

local function IsZoneEnabled(pmCfg)
    local zone = addon.currentZone
    if zone == "arena" then return pmCfg.enabledInArena end
    if zone == "battleground" then return pmCfg.enabledInBattleground end
    if zone == "world" then return pmCfg.enabledInWorld end
    return false
end

-- ---------------------------------------------------------------------------
-- Spec Cache
-- ---------------------------------------------------------------------------

local function RefreshUnitSpecs()
    local specs = addon.friendlyMarkerUnitSpecs
    local units = { "party1", "party2", "arena1", "arena2", "arena3" }

    for _, unit in ipairs(units) do
        if addon:SecureCall(UnitExists, unit) then
            local specID = nil

            if string.match(unit, "^arena%d+$") then
                local arenaIndex = tonumber(string.match(unit, "%d+"))
                specID = addon:SecureCall(GetArenaOpponentSpec, arenaIndex)
            else
                local raidIndex = addon:SecureCall(UnitInRaid, unit)
                if raidIndex then
                    local _, _, classID = addon:SecureCall(UnitClass, unit)
                    if classID then
                        local specIndex = addon:SecureCall(GetSpecialization, false, false, raidIndex)
                        if specIndex and specIndex > 0 then
                            specID = addon:SecureCall(GetSpecializationInfoForClassID, classID, specIndex)
                        end
                    end
                end
            end

            if specID then
                local _, specName, _, icon = addon:SecureCall(GetSpecializationInfoByID, specID)
                specs[unit] = { specID = specID, specName = specName, icon = icon }
            else
                specs[unit] = nil
            end
        else
            specs[unit] = nil
        end
    end
end

-- ---------------------------------------------------------------------------
-- Marker Position Calculation
-- ---------------------------------------------------------------------------

local function CalculateMarkerPosition(size, verticalOffset)
    local s = addon.friendlyMarkerSettings
    local currentNameplateSize = tonumber(GetCVar("nameplateSize")) or 1
    local nameplateSizeOffset = currentNameplateSize * s.nameplateSizeOffsetMultiplier
    local iconScale = size / 100
    local yOffset = verticalOffset + s.defaultVerticalOffset + nameplateSizeOffset
    return iconScale, yOffset
end

-- ---------------------------------------------------------------------------
-- Create UI Elements
-- ---------------------------------------------------------------------------

local function CreateClassIcon(nameplate)
    local s = addon.friendlyMarkerSettings
    if nameplate.ZF_FriendlyClassIcon then
        return nameplate.ZF_FriendlyClassIcon
    end

    local iconFrame = CreateFrame("Frame", nil, nameplate)
    iconFrame:SetMouseClickEnabled(false)
    iconFrame:SetAlpha(1)
    iconFrame:SetIgnoreParentAlpha(true)
    iconFrame:SetSize(s.iconSize, s.iconSize)
    iconFrame:SetFrameStrata("HIGH")
    iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, 0)

    iconFrame.glow = iconFrame:CreateTexture(nil, "BACKGROUND")
    iconFrame.glow:SetTexture("Interface/Masks/CircleMaskScalable")
    iconFrame.glow:SetSize(s.iconSize * s.defaultHighlightScale, s.iconSize * s.defaultHighlightScale)
    iconFrame.glow:SetPoint("CENTER", iconFrame)
    iconFrame.glow:SetBlendMode("ADD")
    iconFrame.glow:Hide()

    iconFrame.icon = iconFrame:CreateTexture(nil, "BORDER")
    iconFrame.icon:SetSize(s.iconSize, s.iconSize)
    iconFrame.icon:SetAllPoints(iconFrame)

    iconFrame.mask = iconFrame:CreateMaskTexture()
    iconFrame.mask:SetTexture("Interface/Masks/CircleMaskScalable")
    iconFrame.mask:SetSize(s.iconSize, s.iconSize)
    iconFrame.mask:SetAllPoints(iconFrame.icon)
    iconFrame.icon:AddMaskTexture(iconFrame.mask)

    iconFrame.border = iconFrame:CreateTexture(nil, "OVERLAY")
    iconFrame.border:SetAtlas("charactercreate-ring-metallight")
    iconFrame.border:SetSize(s.borderSize, s.borderSize)
    iconFrame.border:SetPoint("CENTER", iconFrame)

    iconFrame:Hide()
    nameplate.ZF_FriendlyClassIcon = iconFrame
    return iconFrame
end

local function CreateClassArrow(nameplate, width, height)
    if nameplate.ZF_FriendlyClassArrow then
        nameplate.ZF_FriendlyClassArrow:SetSize(height, width)
        nameplate.ZF_FriendlyClassArrow.icon:SetSize(width, height)
        nameplate.ZF_FriendlyClassArrow.glow:SetSize(width * 1.25, height * 1.25)
        return nameplate.ZF_FriendlyClassArrow
    end

    local arrowFrame = CreateFrame("Frame", nil, nameplate)
    arrowFrame:SetMouseClickEnabled(false)
    arrowFrame:SetAlpha(1)
    arrowFrame:SetIgnoreParentAlpha(true)
    arrowFrame:SetSize(height, width)
    arrowFrame:SetFrameStrata("HIGH")
    arrowFrame:SetPoint("CENTER", nameplate, "CENTER")

    arrowFrame.glow = arrowFrame:CreateTexture(nil, "BACKGROUND")
    arrowFrame.glow:SetSize(width * 1.25, height * 1.25)
    arrowFrame.glow:SetPoint("CENTER", arrowFrame, "CENTER")
    arrowFrame.glow:SetBlendMode("ADD")
    arrowFrame.glow:SetDesaturated(true)
    arrowFrame.glow:Hide()

    arrowFrame.icon = arrowFrame:CreateTexture(nil, "BORDER")
    arrowFrame.icon:SetSize(width, height)
    arrowFrame.icon:SetDesaturated(false)
    arrowFrame.icon:SetPoint("CENTER", arrowFrame, "CENTER")

    arrowFrame:Hide()
    nameplate.ZF_FriendlyClassArrow = arrowFrame
    return arrowFrame
end

local function CreateHealerMarker(nameplate, width, height)
    if nameplate.ZF_HealerMarker then
        nameplate.ZF_HealerMarker:SetSize(width, height)
        nameplate.ZF_HealerMarker.icon:SetSize(width, height)
        return nameplate.ZF_HealerMarker
    end

    local markerFrame = CreateFrame("Frame", nil, nameplate)
    markerFrame:SetMouseClickEnabled(false)
    markerFrame:SetAlpha(1)
    markerFrame:SetIgnoreParentAlpha(true)
    markerFrame:SetSize(width, height)
    markerFrame:SetFrameStrata("HIGH")
    markerFrame:SetPoint("CENTER", nameplate, "CENTER")

    markerFrame.icon = markerFrame:CreateTexture(nil, "OVERLAY")
    markerFrame.icon:SetSize(width, height)
    markerFrame.icon:SetPoint("CENTER", markerFrame, "CENTER")

    markerFrame:Hide()
    nameplate.ZF_HealerMarker = markerFrame
    return markerFrame
end

local function CreateCustomNameText(nameplate, markerFrame, fontSize)
    local s = addon.friendlyMarkerSettings
    if nameplate.ZF_CustomNameText then
        nameplate.ZF_CustomNameText:SetFont("Fonts\\ARIALN.TTF", fontSize, "OUTLINE")
        nameplate.ZF_CustomNameText:ClearAllPoints()
        if markerFrame then
            nameplate.ZF_CustomNameText:SetPoint("TOP", markerFrame, "BOTTOM", 0, -5)
        else
            local currentNameplateSize = tonumber(GetCVar("nameplateSize")) or 1
            local nameplateSizeOffset = currentNameplateSize * s.nameplateSizeOffsetMultiplier
            local verticalOffset = s.defaultVerticalOffset + nameplateSizeOffset
            nameplate.ZF_CustomNameText:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
        end
        return nameplate.ZF_CustomNameText
    end

    local nameText = nameplate:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\ARIALN.TTF", fontSize, "OUTLINE")
    nameText:SetJustifyH("CENTER")

    if markerFrame then
        nameText:SetPoint("TOP", markerFrame, "BOTTOM", 0, -5)
    else
        local currentNameplateSize = tonumber(GetCVar("nameplateSize")) or 1
        local nameplateSizeOffset = currentNameplateSize * s.nameplateSizeOffsetMultiplier
        local verticalOffset = s.defaultVerticalOffset + nameplateSizeOffset
        nameText:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
    end

    nameplate.ZF_CustomNameText = nameText
    return nameText
end

-- ---------------------------------------------------------------------------
-- Healthbar Visibility
-- ---------------------------------------------------------------------------

local function UpdateHealthbarVisibility(nameplate, unit, visible, friendlyCfg)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame then return end

    if unitFrame.healthBar then
        unitFrame.healthBar:SetAlpha(visible and 1 or 0)
    end
    if unitFrame.RaidTargetFrame then
        unitFrame.RaidTargetFrame:SetAlpha(visible and 1 or 0)
    end

    if not visible and unit then
        if unitFrame.name then
            unitFrame.name:SetAlpha(0)
        end

        local _, class = UnitClass(unit)
        local classColor = RAID_CLASS_COLORS[class]
        if class and classColor then
            local markerFrame = nameplate.ZF_FriendlyClassIcon or nameplate.ZF_FriendlyClassArrow or nameplate.ZF_HealerMarker
            local nameText = CreateCustomNameText(nameplate, markerFrame, friendlyCfg.customNameSize)
            nameText:SetText(UnitName(unit))
            nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
            nameText:Show()
        end
    else
        if nameplate.ZF_CustomNameText then
            nameplate.ZF_CustomNameText:Hide()
        end
        if unitFrame.name then
            unitFrame.name:SetAlpha(1)
        end
    end
end

local function ResetHealthbarVisibility(nameplate)
    if nameplate.ZF_CustomNameText then
        nameplate.ZF_CustomNameText:Hide()
    end

    local unitFrame = nameplate.UnitFrame
    if unitFrame then
        if unitFrame.healthBar then
            unitFrame.healthBar:SetAlpha(1)
        end
        if unitFrame.RaidTargetFrame then
            unitFrame.RaidTargetFrame:SetAlpha(1)
        end
        if unitFrame.name then
            unitFrame.name:SetAlpha(1)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Show Individual Marker Types
-- ---------------------------------------------------------------------------

local function ShowFriendlyClassFrame(nameplate, unit, friendlyCfg)
    local s = addon.friendlyMarkerSettings
    local _, class = UnitClass(unit)
    local classColor = RAID_CLASS_COLORS[class]
    if not class or not classColor then return end

    local iconScale, verticalOffset = CalculateMarkerPosition(friendlyCfg.markerSize, friendlyCfg.markerVerticalOffset)
    local markerWidth = 1.0 + (friendlyCfg.markerWidth * 0.15)
    local iconFrame = CreateClassIcon(nameplate)
    local specData = nil

    if friendlyCfg.specIcon then
        for _, partyUnit in ipairs({"party1", "party2"}) do
            if UnitIsUnit(unit, partyUnit) and addon.friendlyMarkerUnitSpecs[partyUnit] then
                specData = addon.friendlyMarkerUnitSpecs[partyUnit]
                break
            end
        end
    end

    if specData and specData.icon then
        iconFrame.icon:SetTexture(specData.icon)
        iconFrame.icon:SetTexCoord(0, 1, 0, 1)
    else
        iconFrame.icon:SetTexture(s.classIconPath)
        iconFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
    end

    iconFrame:SetSize(s.iconSize * markerWidth, s.iconSize)
    iconFrame.icon:SetSize(s.iconSize * markerWidth, s.iconSize)
    iconFrame.mask:SetSize(s.iconSize * markerWidth, s.iconSize)
    iconFrame.border:SetSize(s.borderSize * markerWidth, s.borderSize)
    iconFrame.border:SetDesaturated(true)
    iconFrame.border:SetVertexColor(classColor.r, classColor.g, classColor.b)
    iconFrame:SetScale(iconScale)
    iconFrame:ClearAllPoints()
    iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)

    if friendlyCfg.highlightTarget and UnitIsUnit(unit, "target") then
        local hlScale = friendlyCfg.highlightScale or s.defaultHighlightScale
        iconFrame.glow:SetSize(s.iconSize * hlScale, s.iconSize * hlScale)
        iconFrame.glow:SetVertexColor(0.973, 0.788, 0.020, 0.8)
        iconFrame.glow:Show()
    else
        iconFrame.glow:Hide()
    end

    iconFrame:Show()
end

local function ShowFriendlyArrowFrame(nameplate, unit, friendlyCfg)
    local s = addon.friendlyMarkerSettings
    local _, class = UnitClass(unit)
    local classColor = RAID_CLASS_COLORS[class]
    if not class or not classColor then return end

    local iconScale, verticalOffset = CalculateMarkerPosition(friendlyCfg.markerSize, friendlyCfg.markerVerticalOffset)
    local markerWidthMult = 1.0 + (friendlyCfg.markerWidth * 0.15)
    local atlas = friendlyCfg.markerTexture
    local styleInfo = addon.friendlyMarkerTextures[atlas]
    if not styleInfo then return end

    local rotation = styleInfo.rotation
    local width = s.iconWidth
    local height = s.iconHeight
    local isRotated90 = (rotation == math.pi / 2 or rotation == -math.pi / 2)
    local finalWidth = isRotated90 and width or (width * markerWidthMult)
    local finalHeight = isRotated90 and (height * markerWidthMult) or height
    local arrowFrame = CreateClassArrow(nameplate, finalWidth, finalHeight)

    arrowFrame.icon:SetAtlas(atlas)
    arrowFrame.icon:SetRotation(rotation)
    arrowFrame.icon:SetDesaturated(true)
    arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b)
    arrowFrame:SetScale(iconScale)
    arrowFrame:ClearAllPoints()
    arrowFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)

    if friendlyCfg.highlightTarget and UnitIsUnit(unit, "target") then
        local hlScale = friendlyCfg.highlightScale or s.defaultHighlightScale
        arrowFrame.glow:SetSize(finalWidth * hlScale, finalHeight * hlScale)
        arrowFrame.glow:SetAtlas(atlas)
        arrowFrame.glow:SetRotation(rotation)
        arrowFrame.glow:SetDesaturated(true)
        arrowFrame.glow:SetVertexColor(0.973, 0.788, 0.020, 0.7)
        arrowFrame.glow:Show()
    else
        arrowFrame.glow:Hide()
    end

    arrowFrame:Show()
end

local function ShowFriendlyHealerFrame(nameplate, unit, healerAtlas, friendlyCfg)
    local s = addon.friendlyMarkerSettings
    local iconScale, verticalOffset = CalculateMarkerPosition(friendlyCfg.markerSize, friendlyCfg.markerVerticalOffset)
    local markerWidthMult = 1.0 + (friendlyCfg.markerWidth * 0.15)
    local width = s.iconWidth * markerWidthMult
    local healerFrame = CreateHealerMarker(nameplate, width, s.iconHeight)

    healerFrame.icon:SetAtlas(healerAtlas)

    if healerAtlas == "UI-LFG-RoleIcon-Healer-Disabled" then
        local _, class = UnitClass(unit)
        if class then
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                healerFrame.icon:SetDesaturated(true)
                healerFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b)
            end
        end
    end

    healerFrame:SetScale(iconScale)
    healerFrame:ClearAllPoints()
    healerFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
    healerFrame:Show()
end

local function ShowEnemyHealerFrame(nameplate, unit, healerAtlas, enemyCfg)
    local s = addon.friendlyMarkerSettings
    local iconScale, verticalOffset = CalculateMarkerPosition(enemyCfg.markerSize, enemyCfg.markerVerticalOffset)
    local healerFrame = CreateHealerMarker(nameplate, s.iconWidth, s.iconHeight)

    healerFrame.icon:SetAtlas(healerAtlas)

    if healerAtlas == "UI-LFG-RoleIcon-Healer-Disabled" then
        local _, class = UnitClass(unit)
        if class then
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                healerFrame.icon:SetDesaturated(true)
                healerFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b)
            end
        end
    end

    healerFrame:SetScale(iconScale)
    healerFrame:ClearAllPoints()
    healerFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
    healerFrame:Show()
end

-- ---------------------------------------------------------------------------
-- Marker Display Logic
-- ---------------------------------------------------------------------------

local function GetHealerAtlas(unit, subCfg)
    if UnitGroupRolesAssigned(unit) ~= "HEALER" then return nil end
    local texture = subCfg.healerTexture
    if not texture or texture == "none" then return nil end
    return texture
end

local function ShowFriendlyMarker(nameplate, unit, friendlyCfg)
    local healerAtlas = GetHealerAtlas(unit, friendlyCfg)

    if healerAtlas then
        ShowFriendlyHealerFrame(nameplate, unit, healerAtlas, friendlyCfg)
    elseif friendlyCfg.classIcon or friendlyCfg.specIcon then
        ShowFriendlyClassFrame(nameplate, unit, friendlyCfg)
    elseif friendlyCfg.markerTexture and friendlyCfg.markerTexture ~= "none" then
        ShowFriendlyArrowFrame(nameplate, unit, friendlyCfg)
    end

    UpdateHealthbarVisibility(nameplate, unit, friendlyCfg.showHealthBars, friendlyCfg)
end

local function ShowArenaEnemyHealerMarker(nameplate, unit, enemyCfg)
    local healerAtlas = GetHealerAtlas(unit, enemyCfg)
    if healerAtlas then
        ShowEnemyHealerFrame(nameplate, unit, healerAtlas, enemyCfg)
    end
end

local function HideMarker(nameplate)
    if nameplate.ZF_FriendlyClassIcon then
        nameplate.ZF_FriendlyClassIcon:Hide()
    end
    if nameplate.ZF_FriendlyClassArrow then
        nameplate.ZF_FriendlyClassArrow:Hide()
    end
    if nameplate.ZF_HealerMarker then
        nameplate.ZF_HealerMarker:Hide()
    end
    ResetHealthbarVisibility(nameplate)
end

-- ---------------------------------------------------------------------------
-- Nameplate Processing
-- ---------------------------------------------------------------------------

local function UpdateNameplate(nameplate, pmCfg)
    HideMarker(nameplate)

    local unitFrame = nameplate and nameplate.UnitFrame
    local unit = unitFrame and unitFrame.unit
    if not unit then return end
    if not IsZoneEnabled(pmCfg) then return end

    local isHostilePlayer = UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and UnitIsEnemy("player", unit)
    local isFriendlyPlayer = UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitIsEnemy("player", unit)
    local inArena = addon.currentZone == "arena"

    if isHostilePlayer and inArena and pmCfg.enemyMarkers.enabled then
        ShowArenaEnemyHealerMarker(nameplate, unit, pmCfg.enemyMarkers)
    elseif isFriendlyPlayer and pmCfg.friendlyMarkers.enabled then
        ShowFriendlyMarker(nameplate, unit, pmCfg.friendlyMarkers)
    end
end

local function ProcessNameplateQueue(pmCfg)
    local s = addon.friendlyMarkerSettings
    local processed = 0

    for nameplate, _ in pairs(s.nameplateQueue) do
        if processed >= s.batchSize then break end

        if nameplate and nameplate.UnitFrame then
            UpdateNameplate(nameplate, pmCfg)
        end

        s.nameplateQueue[nameplate] = nil
        processed = processed + 1
    end

    if next(s.nameplateQueue) then
        s.queueTimer = C_Timer.NewTimer(s.batchInterval, function()
            ProcessNameplateQueue(pmCfg)
        end)
    else
        s.queueTimer = nil
    end
end

local function QueueNameplate(nameplate, pmCfg)
    local s = addon.friendlyMarkerSettings
    s.nameplateQueue[nameplate] = true

    if not s.queueTimer then
        s.queueTimer = C_Timer.NewTimer(s.batchInterval, function()
            ProcessNameplateQueue(pmCfg)
        end)
    end
end

local function RefreshAllNameplates(pmCfg)
    RefreshUnitSpecs()
    local nameplates = addon:SecureCall(C_NamePlate.GetNamePlates)
    for _, nameplate in ipairs(nameplates) do
        QueueNameplate(nameplate, pmCfg)
    end
end

local function HandleCvarUpdate(cvarName, pmCfg)
    local s = addon.friendlyMarkerSettings
    if cvarName == "nameplateSize" then
        if s.nameplateUpdateTimer then
            s.nameplateUpdateTimer:Cancel()
        end
        s.nameplateUpdateTimer = C_Timer.NewTimer(s.updateDelay, function()
            RefreshAllNameplates(pmCfg)
            s.nameplateUpdateTimer = nil
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeFriendlyMarkers()
    local pmCfg = self.config and self.config.extras and self.config.extras.playerMarkers
    if not pmCfg or not pmCfg.enabled then return end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("CVAR_UPDATE")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("UNIT_FACTION")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(0.5, function()
                HandleCvarUpdate("nameplateSize", pmCfg)
            end)
            return
        end

        if event == "CVAR_UPDATE" then
            local cvarName = ...
            HandleCvarUpdate(cvarName, pmCfg)
            return
        end

        if event == "NAME_PLATE_UNIT_ADDED" then
            local unit = ...
            if unit then
                local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
                if nameplate then
                    QueueNameplate(nameplate, pmCfg)
                end
            end
            return
        end

        if event == "NAME_PLATE_UNIT_REMOVED" then
            local unit = ...
            if unit then
                local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
                if nameplate then
                    HideMarker(nameplate)
                end
            end
            return
        end

        if event == "UNIT_FACTION" then
            local unit = ...
            if unit and string.match(unit, "nameplate") then
                RefreshAllNameplates(pmCfg)
            end
            return
        end

        RefreshAllNameplates(pmCfg)
    end)
end

-- ---------------------------------------------------------------------------
-- ObjectiveIcon — flag carrier, gem carrier, orb carrier indicator on unit frames
-- ---------------------------------------------------------------------------
local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.objectiveIconFrames = {}

local scanTicker
local SCAN_INTERVAL = 0.2
local currentBgName

local DEEPHAUL_RAVINE = "Deephaul Ravine"

local lastLoggedCarriers = {}
local lastLoggedBgName
local lastLoggedArenaState = ""

local ARENA_UNITS = {}
for i = 1, 5 do ARENA_UNITS[i] = "arena" .. i end

local function GetObjectiveTextures()
    local global = addon.config and addon.config.global
    if not global or not global.objectiveIcons then
        return nil
    end
    return global.objectiveIcons
end

local function ApplyColorFromHex(texture, hexColor)
    if not hexColor then return end
    local r, g, b, a = addon:HexToRGB(hexColor)
    texture:SetDesaturated(true)
    texture:SetVertexColor(r, g, b, a)
end

local function IsDeephaulRavine()
    return currentBgName == DEEPHAUL_RAVINE
end

local function ApplyClassificationTexture(icon, classification, textures)
    if not textures then return false end

    if classification == 0 or classification == 1 then
        icon:SetAtlas(textures.orb, false)
        if IsDeephaulRavine() then
            ApplyColorFromHex(icon, textures.gemColor)
        elseif classification == 0 then
            ApplyColorFromHex(icon, textures.hordeColor)
        else
            ApplyColorFromHex(icon, textures.allianceColor)
        end
        return true, false
    elseif classification == 2 then
        icon:SetAtlas(textures.orb, false)
        ApplyColorFromHex(icon, textures.allianceColor)
        return true, false
    elseif classification == 7 then
        icon:SetAtlas(textures.orb, false)
        ApplyColorFromHex(icon, textures.orbBlueColor)
        return true
    elseif classification == 8 then
        icon:SetAtlas(textures.orb, false)
        ApplyColorFromHex(icon, textures.orbGreenColor)
        return true
    elseif classification == 9 then
        icon:SetAtlas(textures.orb, false)
        ApplyColorFromHex(icon, textures.orbOrangeColor)
        return true
    elseif classification == 10 then
        icon:SetAtlas(textures.orb, false)
        ApplyColorFromHex(icon, textures.orbPurpleColor)
        return true
    end

    return false
end

function addon:AddObjectiveIcon(frame, cfg)
    local callHook = self.callHook or function() end
    callHook(self, "BeforeAddObjectiveIcon", frame, cfg)

    local size = cfg.iconSize or cfg.size or 20
    local borderWidth = tonumber(cfg.borderWidth) or 1

    local container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(size, size)
    container:SetPoint(
        cfg.anchor,
        cfg.relativeTo and _G[cfg.relativeTo] or frame,
        cfg.relativePoint,
        cfg.offsetX,
        cfg.offsetY
    )
    container:SetFrameStrata("TOOLTIP")
    container:SetFrameLevel(9999)
    container:SetIgnoreParentAlpha(true)

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(container)
    local br, bg2, bb, ba = self:HexToRGB(cfg.backgroundColor or "000000CC")
    bg:SetColorTexture(br, bg2, bb, ba)
    container.Background = bg

    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", container, "TOPLEFT", borderWidth, -borderWidth)
    icon:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderWidth, borderWidth)
    container.Icon = icon

    self:AddTextureBorder(container, borderWidth, cfg.borderColor or "000000FF")
    container._borderWidth = borderWidth

    container:Hide()

    frame.ObjectiveIcon = container
    addon:AttachPlaceholder(container)

    table.insert(addon.objectiveIconFrames, frame)

    callHook(self, "AfterAddObjectiveIcon", frame)
    return true
end

local function IsBattlegroundInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "pvp")
end

local function UpdateObjectiveIcons()
    if not IsBattlegroundInstance() then return end

    currentBgName = select(1, GetInstanceInfo())

    if currentBgName ~= lastLoggedBgName then
        lastLoggedBgName = currentBgName
        local hasMap = textures.carrierMap and textures.carrierMap[currentBgName] and true or false
        print("|cff00ccffOBJ|r bg=" .. tostring(currentBgName) .. " map=" .. tostring(hasMap))
    end

    local textures = GetObjectiveTextures()
    if not textures then return end

    local carrierSlots = {}
    local friendlyCarrierUnits = {}
    local carrierMap = textures.carrierMap and textures.carrierMap[currentBgName]
    local arenaDebugParts = {}
    if carrierMap and addon.GetRosterSlotByArenaUnit then
        for arenaIdx, classification in pairs(carrierMap) do
            local arenaUnit = ARENA_UNITS[arenaIdx]
            local exists = UnitExists(arenaUnit)
            local isPlayer = exists and UnitIsPlayer(arenaUnit)
            if exists and isPlayer then
                local isFriend = UnitIsFriend("player", arenaUnit)
                if isFriend then
                    friendlyCarrierUnits[arenaUnit] = classification
                    arenaDebugParts[arenaIdx] = arenaUnit .. " friendly"
                else
                    local slotIndex = addon:GetRosterSlotByArenaUnit(arenaUnit)
                    arenaDebugParts[arenaIdx] = arenaUnit .. " enemy slot=" .. tostring(slotIndex)
                    if slotIndex then
                        carrierSlots[slotIndex] = classification
                    end
                end
            else
                arenaDebugParts[arenaIdx] = arenaUnit .. (exists and " not-player" or " absent")
            end
        end
    end

    local arenaStateStr = table.concat(arenaDebugParts, " ")
    if arenaStateStr ~= lastLoggedArenaState then
        lastLoggedArenaState = arenaStateStr
        if arenaStateStr ~= "" then
            print("|cff00ccffOBJ|r arena: " .. arenaStateStr)
        end
    end

    local carrierChanged = false
    for slot, cls in pairs(carrierSlots) do
        if lastLoggedCarriers[slot] ~= cls then
            carrierChanged = true
            break
        end
    end
    for slot in pairs(lastLoggedCarriers) do
        if not carrierSlots[slot] then
            carrierChanged = true
            break
        end
    end
    if carrierChanged then
        local parts = {}
        for slot, cls in pairs(carrierSlots) do
            parts[#parts + 1] = "s" .. slot .. "=c" .. cls
        end
        if #parts == 0 then
            print("|cff00ccffOBJ|r carriers: none")
        else
            print("|cff00ccffOBJ|r carriers: " .. table.concat(parts, " "))
        end
        wipe(lastLoggedCarriers)
        for slot, cls in pairs(carrierSlots) do
            lastLoggedCarriers[slot] = cls
        end
    end

    for _, frame in ipairs(addon.objectiveIconFrames) do
        local container = frame.ObjectiveIcon
        if container then
            if frame:IsVisible() and frame.unit and UnitExists(frame.unit) then
                local classification

                local slotIndex = frame._zfEnemyFrameIndex
                if slotIndex then
                    classification = carrierSlots[slotIndex]
                else
                    for carrierUnit, cls in pairs(friendlyCarrierUnits) do
                        if UnitIsUnit(frame.unit, carrierUnit) then
                            classification = cls
                            break
                        end
                    end
                end

                if classification then
                    local applied, isFlag = ApplyClassificationTexture(container.Icon, classification, textures)
                    if applied then
                        if container.Background then
                            container.Background:SetShown(not isFlag)
                        end
                        addon:SetTextureBorderShown(container, not isFlag)
                        container:Show()
                    else
                        container:Hide()
                    end
                else
                    container:Hide()
                end
            else
                container:Hide()
            end
        end
    end
end

local function StartObjectiveScanner()
    if scanTicker then return end
    scanTicker = C_Timer.NewTicker(SCAN_INTERVAL, UpdateObjectiveIcons)
end

local function StopObjectiveScanner()
    if scanTicker then
        scanTicker:Cancel()
        scanTicker = nil
    end
    for _, frame in ipairs(addon.objectiveIconFrames) do
        local container = frame.ObjectiveIcon
        if container then
            container:Hide()
        end
    end
    wipe(lastLoggedCarriers)
    lastLoggedBgName = nil
    lastLoggedArenaState = ""
end

local scannerFrame = CreateFrame("Frame")
scannerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
scannerFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
scannerFrame:SetScript("OnEvent", function()
    if IsBattlegroundInstance() then
        StartObjectiveScanner()
    else
        StopObjectiveScanner()
    end
end)

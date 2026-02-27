local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Frame definitions: config key, localization key, default enabled
-- ---------------------------------------------------------------------------

local LEFT_COLUMN_FRAMES = {
    { configKey = "party",  locKey = "partyEnabled", defaultVisible = true },
    { configKey = "arena",  locKey = "arenaEnabled", defaultVisible = true },
    {
        configKey = "blitz",
        locKey = "blitzEnabled",
        defaultVisible = false,
        enabledPath = { "raid", "profiles", "blitz", "friendly", "enabled" },
        visibilityKeys = { "raid_blitz_friendly", "raid_blitz_enemy" },
    },
    {
        configKey = "battleground",
        locKey = "battlegroundEnabled",
        defaultVisible = false,
        enabledPath = { "raid", "profiles", "battleground", "friendly", "enabled" },
        visibilityKeys = { "raid_battleground_friendly", "raid_battleground_enemy" },
    },
    {
        configKey = "epicBattleground",
        locKey = "epicBattlegroundEnabled",
        defaultVisible = false,
        enabledPath = { "raid", "profiles", "epicBattleground", "friendly", "enabled" },
        visibilityKeys = { "raid_epicBattleground_friendly", "raid_epicBattleground_enemy" },
    },
    {
        configKey = "raid",
        locKey = "raidEnabled",
        defaultVisible = false,
        enabledPath = { "raid", "profiles", "pve", "friendly", "enabled" },
        visibilityKeys = { "raid_pve_friendly" },
    },
}

local RIGHT_COLUMN_FRAMES = {
    { configKey = "player",       locKey = "playerEnabled", defaultVisible = true },
    { configKey = "target",       locKey = "targetEnabled", defaultVisible = true },
    { configKey = "targetTarget", locKey = "targetTargetEnabled", defaultVisible = true },
    { configKey = "focus",        locKey = "focusEnabled", defaultVisible = true },
    { configKey = "focusTarget",  locKey = "focusTargetEnabled", defaultVisible = true },
    { configKey = "pet",          locKey = "petEnabled", defaultVisible = true },
}

-- ---------------------------------------------------------------------------
-- Visibility state (edit-mode only, not persisted)
-- ---------------------------------------------------------------------------

local visibilityState = {}
local initialEnabledState = {}
local dialog

local ROW_HEIGHT = 24
local CHECKBOX_SIZE = 24
local EYE_SIZE = 24
local EYE_VISIBLE_SIZE = EYE_SIZE + 2
local CONTROL_GAP = 6
local COLUMN_GAP = 24

local function ResetVisibilityState()
    for k in pairs(visibilityState) do
        visibilityState[k] = nil
    end
end

local function GetStoredOrDefaultVisibility(def)
    local stored = visibilityState[def.configKey]
    if stored ~= nil then
        return stored == true
    end

    return def.defaultVisible ~= false
end

local function CheckForChanges()
    if not dialog or not dialog._reloadButton then return end
    local changed = false
    for configKey, row in pairs(dialog._rows) do
        local current = row.checkbox:GetChecked()
        if current ~= initialEnabledState[configKey] then
            changed = true
            break
        end
    end
    if changed then
        dialog._reloadButton:Enable()
    else
        dialog._reloadButton:Disable()
    end
end

local function GetValueAtPath(root, path)
    local current = root
    for _, key in ipairs(path or {}) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[key]
    end
    return current
end

local function GetRowEnabled(def)
    if def.enabledPath then
        return GetValueAtPath(addon.config, def.enabledPath) == true
    end
    return addon.config[def.configKey] and addon.config[def.configKey].enabled == true
end

local function SetRowEnabled(def, checked)
    local isRaidProfileToggle = def and (
        def.configKey == "raid"
        or def.configKey == "blitz"
        or def.configKey == "battleground"
        or def.configKey == "epicBattleground"
    )

    if isRaidProfileToggle and checked then
        addon:SetOverride({ "raid", "enabled" }, true)
    end

    if def.enabledPath then
        addon:SetOverride(def.enabledPath, checked)
        return
    end

    addon:SetOverride({ def.configKey, "enabled" }, checked)
    addon:SetOverride({ def.configKey, "hideBlizzard" }, checked)
end

local RAID_VISIBILITY_GROUP = {
    raid = true,
    blitz = true,
    battleground = true,
    epicBattleground = true,
}

local function IsRaidVisibilityGroupKey(configKey)
    return RAID_VISIBILITY_GROUP[configKey] == true
end

local PARTY_ARENA_VISIBILITY_GROUP = {
    party = true,
    arena = true,
}

local function IsPartyArenaVisibilityGroupKey(configKey)
    return PARTY_ARENA_VISIBILITY_GROUP[configKey] == true
end

local function ApplyRowVisibility(def, row, isVisible)
    local visible = isVisible == true
    if row and row.eye and row.eye.icon then
        row.eye._visible = visible
        row.eye.icon:SetAtlas(visible and "GM-icon-visible" or "GM-icon-visibleDis")
        row.eye.icon:SetVertexColor(visible and 1 or 1, visible and 0.82 or 1, visible and 0 or 1, 1)
        row.eye.icon:SetSize(visible and EYE_VISIBLE_SIZE or EYE_SIZE, visible and EYE_VISIBLE_SIZE or EYE_SIZE)
    end

    visibilityState[def.configKey] = visible
    addon:EditModeToggleFrameVisibility(def.configKey, visible, def.visibilityKeys)
end

-- ---------------------------------------------------------------------------
-- Build dialog
-- ---------------------------------------------------------------------------

local function BuildDialog()
    if dialog then return dialog end

    addon:RefreshConfig()
    dialog = addon:CreateDialog({
        name = "ZenFramesEditModeDialog",
        title = "editModeDialogTitle",
        width = addon.DialogStyle and addon.DialogStyle.DIALOG_WIDTH_2_COL or 600,
        frameStrata = "TOOLTIP",
        frameLevel = 300,
        showCloseButton = true,
        onCloseClick = function()
            addon:DisableEditMode()
        end,
        leftIcon = {
            atlas = "mechagon-projects",
            size = 24,
            desaturated = true,
            onClick = function()
                addon:ShowEditModeSettingsDialog()
            end,
        },
    })
    addon._editModeDialog = dialog

    local y = dialog._contentTop

    local rows = {}

    local contentLeft = dialog._contentLeft or 38
    local contentWidth = dialog._contentWidth or (dialog:GetWidth() - 76)
    local columnWidth = math.floor((contentWidth - COLUMN_GAP) / 2)
    local rightColumnX = contentLeft + columnWidth + COLUMN_GAP

    local function AddColumnToggleRow(def, columnX, rowY)
        local isEnabled = GetRowEnabled(def)
        local isVisible = GetStoredOrDefaultVisibility(def)
        visibilityState[def.configKey] = isVisible

        local row = CreateFrame("Frame", nil, dialog)
        row:SetSize(columnWidth, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", dialog, "TOPLEFT", columnX, rowY)

        local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
        checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)
        checkbox:SetChecked(isEnabled)
        row.checkbox = checkbox

        local eye = CreateFrame("Button", nil, row)
        eye:SetSize(EYE_SIZE, EYE_SIZE)
        eye:SetPoint("LEFT", checkbox, "RIGHT", CONTROL_GAP, 0)

        local eyeIcon = eye:CreateTexture(nil, "ARTWORK")
        eyeIcon:SetSize(EYE_SIZE, EYE_SIZE)
        eyeIcon:SetPoint("CENTER", eye, "CENTER", 0, 0)
        eye.icon = eyeIcon
        eye._visible = isVisible
        eye.icon:SetAtlas(isVisible and "GM-icon-visible" or "GM-icon-visibleDis")
        row.eye = eye

        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetFont(dialog._fontPath, 12, "OUTLINE")
        label:SetTextColor(1, 1, 1)
        label:SetPoint("LEFT", eye, "RIGHT", CONTROL_GAP, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        label:SetJustifyH("LEFT")
        label:SetText(addon:L(def.locKey))
        row.label = label

        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            SetRowEnabled(def, checked)

            local r = rows[def.configKey]
            if checked then
                if IsRaidVisibilityGroupKey(def.configKey) then
                    for _, otherDef in ipairs(LEFT_COLUMN_FRAMES) do
                        if IsRaidVisibilityGroupKey(otherDef.configKey) then
                            local otherRow = rows[otherDef.configKey]
                            ApplyRowVisibility(otherDef, otherRow, otherDef.configKey == def.configKey)
                        end
                    end
                    local partyRow = rows.party
                    if partyRow and partyRow._def then
                        ApplyRowVisibility(partyRow._def, partyRow, false)
                    end
                    local arenaRow = rows.arena
                    if arenaRow and arenaRow._def then
                        ApplyRowVisibility(arenaRow._def, arenaRow, false)
                    end
                elseif IsPartyArenaVisibilityGroupKey(def.configKey) then
                    for _, otherDef in ipairs(LEFT_COLUMN_FRAMES) do
                        if IsRaidVisibilityGroupKey(otherDef.configKey) then
                            local otherRow = rows[otherDef.configKey]
                            ApplyRowVisibility(otherDef, otherRow, false)
                        end
                    end
                    ApplyRowVisibility(def, r, true)
                else
                    ApplyRowVisibility(def, r, true)
                end
            else
                ApplyRowVisibility(def, r, false)
            end

            CheckForChanges()
        end)

        eye:SetScript("OnClick", function(self)
            local r = rows[def.configKey]
            local makeVisible = not self._visible

            if makeVisible and IsRaidVisibilityGroupKey(def.configKey) then
                for _, otherDef in ipairs(LEFT_COLUMN_FRAMES) do
                    if IsRaidVisibilityGroupKey(otherDef.configKey) then
                        local otherRow = rows[otherDef.configKey]
                        ApplyRowVisibility(otherDef, otherRow, otherDef.configKey == def.configKey)
                    end
                end
                local partyRow = rows.party
                if partyRow and partyRow._def then
                    ApplyRowVisibility(partyRow._def, partyRow, false)
                end
                local arenaRow = rows.arena
                if arenaRow and arenaRow._def then
                    ApplyRowVisibility(arenaRow._def, arenaRow, false)
                end
            elseif makeVisible and IsPartyArenaVisibilityGroupKey(def.configKey) then
                for _, otherDef in ipairs(LEFT_COLUMN_FRAMES) do
                    if IsRaidVisibilityGroupKey(otherDef.configKey) then
                        local otherRow = rows[otherDef.configKey]
                        ApplyRowVisibility(otherDef, otherRow, false)
                    end
                end
                ApplyRowVisibility(def, r, true)
            else
                ApplyRowVisibility(def, r, makeVisible)
            end
        end)

        row._def = def
        rows[def.configKey] = row

        return rowY - ROW_HEIGHT
    end

    local leftY = y
    for _, def in ipairs(LEFT_COLUMN_FRAMES) do
        leftY = AddColumnToggleRow(def, contentLeft, leftY)
    end

    local rightY = y
    for _, def in ipairs(RIGHT_COLUMN_FRAMES) do
        rightY = AddColumnToggleRow(def, rightColumnX, rightY)
    end

    y = math.min(leftY, rightY)

    dialog._rows = rows

    local reloadBtn
    reloadBtn, y = addon:DialogAddButton(dialog, y - 8, "reloadUI", function()
        if addon.savedVars then
            addon.savedVars.data = addon.savedVars.data or {}
            addon.savedVars.data.resumeEditModeAfterReload = true
        end
        ReloadUI()
    end)
    reloadBtn.button:Disable()
    dialog._reloadButton = reloadBtn.button

    local credit = dialog:CreateFontString(nil, "OVERLAY")
    credit:SetFont(dialog._fontPath, 11, "OUTLINE")
    credit:SetPoint("TOP", dialog, "TOP", 0, y - 25)
    credit:SetTextColor(0.8, 0.8, 0.8)
    credit:SetText(addon:L("editModeAuthorCredit"))
    y = y - 34

    addon:DialogFinalize(dialog, y)

    return dialog
end

-- ---------------------------------------------------------------------------
-- Show / Hide
-- ---------------------------------------------------------------------------

function addon:ShowEditModeDialog()
    if InCombatLockdown() then return end

    -- Get position of any currently open dialog BEFORE building main dialog
    -- (BuildDialog returns singleton, so we need position before we get the frame)
    local centerX, centerY = self:GetOpenConfigDialogCenter(nil)

    local dlg = BuildDialog()
    self:HideOpenConfigDialogs(dlg)

    self:RefreshConfig()
    for configKey, row in pairs(dlg._rows) do
        local def = row._def
        local isEnabled = def and GetRowEnabled(def)
        local visible = true
        if def then
            visible = GetStoredOrDefaultVisibility(def)
        end

        row.checkbox:SetChecked(isEnabled)
        ApplyRowVisibility(def, row, visible)
        initialEnabledState[configKey] = isEnabled
    end

    dlg._reloadButton:Disable()

    if centerX and centerY then
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    else
        dlg:ClearAllPoints()
        dlg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    dlg:Show()
end

function addon:HideEditModeDialog()
    if InCombatLockdown() then return end

    self:HideEditModeSettingsDialog()
    self:HideAllEditModeSubDialogs()

    if dialog then
        dialog:Hide()
    end
    ResetVisibilityState()
end

-- ---------------------------------------------------------------------------
-- Toggle frame visibility in edit mode
-- ---------------------------------------------------------------------------

function addon:EditModeToggleFrameVisibility(configKey, visible, visibilityKeys)
    if InCombatLockdown() then return end

    local function SetFrameInteractive(frame, isVisible)
        if not frame then
            return
        end

        frame:SetAlpha(isVisible and 1 or 0)

        if frame.EnableMouse then
            frame:EnableMouse(isVisible)
        end

        if frame.SetMouseClickEnabled then
            frame:SetMouseClickEnabled(isVisible)
        end

        if frame._placeholder then
            frame._placeholder:EnableMouse(isVisible)
            frame._placeholder:SetAlpha(isVisible and 1 or 0)
        end

        if frame._textPins then
            for _, pin in pairs(frame._textPins) do
                if pin then
                    pin:SetAlpha(isVisible and 1 or 0)
                    if pin.EnableMouse then
                        pin:EnableMouse(isVisible)
                    end
                    if pin.SetMouseClickEnabled then
                        pin:SetMouseClickEnabled(isVisible)
                    end
                end
            end
        end

        for _, value in pairs(frame) do
            if type(value) == "table" and value._placeholder then
                value._placeholder:SetAlpha(isVisible and 1 or 0)
                if value._placeholder.EnableMouse then
                    value._placeholder:EnableMouse(isVisible)
                end
                if value._placeholder.SetMouseClickEnabled then
                    value._placeholder:SetMouseClickEnabled(isVisible)
                end
            end
        end
    end
    
    if self.unitFrames then
        for unit, frame in pairs(self.unitFrames) do
            local unitConfig = ({
                player = "player",
                target = "target",
                targettarget = "targetTarget",
                focus = "focus",
                focustarget = "focusTarget",
                pet = "pet",
            })[unit]
            if unitConfig == configKey then
                SetFrameInteractive(frame, visible)
            end
        end
    end

    if self.groupContainers then
        if visibilityKeys and #visibilityKeys > 0 then
            for _, key in ipairs(visibilityKeys) do
                local container = self.groupContainers[key]
                if container then
                    SetFrameInteractive(container, visible)
                    if container.frames then
                        for _, child in ipairs(container.frames) do
                            SetFrameInteractive(child, visible)
                        end
                    end
                end
            end
        else
            local container = self.groupContainers[configKey]
            if container then
                SetFrameInteractive(container, visible)
                if container.frames then
                    for _, child in ipairs(container.frames) do
                        SetFrameInteractive(child, visible)
                    end
                end
            end
        end
    end
end

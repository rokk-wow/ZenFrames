local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local infoDialog

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function FormatMemory(kb)
    if kb >= 1024 then
        return string.format("%.1f MB", kb / 1024)
    end
    return string.format("%.0f KB", kb)
end

local function GetTopAddonsByMemory(count)
    UpdateAddOnMemoryUsage()
    local addons = {}
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        local loaded = C_AddOns.IsAddOnLoaded(i)
        if loaded then
            local mem = GetAddOnMemoryUsage(i)
            addons[#addons + 1] = { name = name, memory = mem }
        end
    end
    table.sort(addons, function(a, b) return a.memory > b.memory end)

    local results = {}
    for i = 1, math.min(count, #addons) do
        results[i] = addons[i]
    end
    return results
end

local function GetZenFramesEntry()
    UpdateAddOnMemoryUsage()
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        if name == addonName then
            return {
                name = name,
                memory = GetAddOnMemoryUsage(i),
                loaded = C_AddOns.IsAddOnLoaded(i),
            }
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Dialog
-- ---------------------------------------------------------------------------

local function BuildInfoLines()
    local lines = {}

    local fps = GetFramerate()
    local latencyHome, latencyWorld = GetNetStats()
    lines[#lines + 1] = { header = "System" }
    lines[#lines + 1] = { label = "FPS", value = string.format("%.0f", fps) }
    lines[#lines + 1] = { label = "Latency (Home)", value = latencyHome .. " ms" }
    lines[#lines + 1] = { label = "Latency (World)", value = latencyWorld .. " ms" }

    local zfEntry = GetZenFramesEntry()
    if zfEntry and zfEntry.loaded then
        lines[#lines + 1] = { header = "ZenFrames" }
        lines[#lines + 1] = { label = "Memory", value = FormatMemory(zfEntry.memory) }

        local raidCfg = addon.config and addon.config.raid
        if raidCfg then
            lines[#lines + 1] = { label = "Raid Enabled", value = raidCfg.enabled and "Yes" or "No" }
        end

        local containerCount = 0
        if addon.groupContainers then
            for _ in pairs(addon.groupContainers) do
                containerCount = containerCount + 1
            end
        end
        lines[#lines + 1] = { label = "Group Containers", value = tostring(containerCount) }

        local unitFrameCount = 0
        if addon.unitFrames then
            for _ in pairs(addon.unitFrames) do
                unitFrameCount = unitFrameCount + 1
            end
        end
        lines[#lines + 1] = { label = "Unit Frames", value = tostring(unitFrameCount) }
    end

    lines[#lines + 1] = { header = "Top Addons by Memory" }
    local topAddons = GetTopAddonsByMemory(10)
    for i, entry in ipairs(topAddons) do
        lines[#lines + 1] = { label = entry.name, value = FormatMemory(entry.memory) }
    end

    return lines
end

local function PopulateDialog(dialog)
    if dialog._infoFontStrings then
        for _, fs in ipairs(dialog._infoFontStrings) do
            fs:Hide()
        end
    end
    dialog._infoFontStrings = {}

    local lines = BuildInfoLines()
    local yOffset = dialog._contentTop
    local padLeft = dialog._padding or 16
    local contentWidth = dialog:GetWidth() - 2 * padLeft
    local fontPath = dialog._fontPath
    local lineHeight = 16
    local headerHeight = 20
    local headerSpacing = 6
    local lineSpacing = 2

    for _, line in ipairs(lines) do
        if line.header then
            yOffset = yOffset - headerSpacing

            local header = dialog:CreateFontString(nil, "OVERLAY")
            header:SetFont(fontPath, 13, "OUTLINE")
            header:SetTextColor(0.9, 0.8, 0.5)
            header:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, yOffset)
            header:SetText(line.header)
            dialog._infoFontStrings[#dialog._infoFontStrings + 1] = header

            yOffset = yOffset - headerHeight

            local divider = dialog:CreateTexture(nil, "ARTWORK")
            divider:SetColorTexture(0.4, 0.4, 0.4, 0.6)
            divider:SetHeight(1)
            divider:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft, yOffset)
            divider:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -padLeft, yOffset)
            dialog._infoFontStrings[#dialog._infoFontStrings + 1] = divider

            yOffset = yOffset - 4
        else
            local label = dialog:CreateFontString(nil, "OVERLAY")
            label:SetFont(fontPath, 11, "OUTLINE")
            label:SetTextColor(0.8, 0.8, 0.8)
            label:SetPoint("TOPLEFT", dialog, "TOPLEFT", padLeft + 4, yOffset)
            label:SetText(line.label)
            dialog._infoFontStrings[#dialog._infoFontStrings + 1] = label

            local val = dialog:CreateFontString(nil, "OVERLAY")
            val:SetFont(fontPath, 11, "OUTLINE")
            val:SetTextColor(1, 1, 1)
            val:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -padLeft, yOffset)
            val:SetJustifyH("RIGHT")
            val:SetText(line.value)
            dialog._infoFontStrings[#dialog._infoFontStrings + 1] = val

            yOffset = yOffset - lineHeight - lineSpacing
        end
    end

    addon:DialogFinalize(dialog, yOffset)
end

local function CreateInfoDialog()
    if infoDialog then return infoDialog end

    infoDialog = addon:CreateDialog({
        name = "ZenFramesInfoDialog",
        title = "infoTitle",
        width = 340,
        height = 400,
        movable = true,
        clampedToScreen = true,
        showCloseButton = true,
        dismissOnEscape = true,
        footerButtons = {
            {
                text = "infoRefresh",
                onClick = function()
                    PopulateDialog(infoDialog)
                end,
            },
        },
    })

    PopulateDialog(infoDialog)
    return infoDialog
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function addon:InitializeInfo()
    local cfg = self.config and self.config.extras and self.config.extras.info
    if not cfg or not cfg.enabled then return end

    self:RegisterSlashCommand("zfinfo", function()
        CreateInfoDialog()
        PopulateDialog(infoDialog)
        addon:ShowDialog(infoDialog, "standalone")
    end)
end

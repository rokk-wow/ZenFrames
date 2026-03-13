local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- ---------------------------------------------------------------------------
-- Vendor Automation (Auto Sell Junk + Auto Repair)
-- ---------------------------------------------------------------------------

function addon:FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperRem = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copperRem)
end

function addon:InitializeVendor()
    local cfg = self.config and self.config.extras and self.config.extras.vendor
    if not cfg then return end
    if not cfg.autoSellJunk and not cfg.autoRepair then return end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("MERCHANT_SHOW")
    eventFrame:SetScript("OnEvent", function()
        if cfg.autoSellJunk then
            local totalPrice = 0
            for bag = 0, 4 do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue then
                        totalPrice = totalPrice + (info.stackCount * (info.sellPrice or 0))
                        C_Container.UseContainerItem(bag, slot)
                    end
                end
            end
            if totalPrice > 0 then
                addon:Info(addon:L("vendorSoldJunk") .. " " .. addon:FormatMoney(totalPrice))
            end
        end

        if cfg.autoRepair then
            local repairCost, canRepair = GetRepairAllCost()
            if canRepair and repairCost > 0 then
                if GetMoney() >= repairCost then
                    RepairAllItems()
                    addon:Info(addon:L("vendorRepaired") .. " " .. addon:FormatMoney(repairCost))
                else
                    addon:Info(addon:L("vendorNotEnoughMoney"))
                end
            end
        end
    end)
end

function addon:InitializeTabRebind()
    local cfg = self.config and self.config.extras
    if not cfg or not cfg.rebindTabInPvP then return end

    local savedKeys = {}

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function()
        if InCombatLockdown() then return end

        local zone = addon:GetCurrentZone()
        local isPvP = (zone == "arena" or zone == "battleground")

        if isPvP then
            local key1, key2 = GetBindingKey("TARGETNEARESTENEMY")
            if key1 or key2 then
                wipe(savedKeys)
                if key1 then savedKeys[#savedKeys + 1] = key1 end
                if key2 then savedKeys[#savedKeys + 1] = key2 end
                for _, key in ipairs(savedKeys) do
                    SetBinding(key, "TARGETNEARESTENEMYPLAYER")
                end
                SaveBindings(GetCurrentBindingSet())
            end
        else
            if #savedKeys > 0 then
                for _, key in ipairs(savedKeys) do
                    SetBinding(key, "TARGETNEARESTENEMY")
                end
                SaveBindings(GetCurrentBindingSet())
                wipe(savedKeys)
            end
        end
    end)
end

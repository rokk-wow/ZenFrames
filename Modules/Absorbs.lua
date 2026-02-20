local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddAbsorbs(frame, cfg)
    if not frame.Health then return end

    local Health = frame.Health

    local texturePath
    if cfg.texture then
        texturePath = addon:FetchStatusbar(cfg.texture)
    end

    local damageAbsorb = CreateFrame("StatusBar", nil, Health)
    damageAbsorb:SetPoint("TOP")
    damageAbsorb:SetPoint("BOTTOM")
    damageAbsorb:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
    damageAbsorb:SetWidth(Health:GetWidth())
    if texturePath then
        damageAbsorb:SetStatusBarTexture(texturePath)
    end
    damageAbsorb:SetStatusBarColor(1, 1, 1, cfg.opacity or 0.5)

    local overDamageAbsorbIndicator = Health:CreateTexture(nil, "OVERLAY")
    overDamageAbsorbIndicator:SetPoint("TOP")
    overDamageAbsorbIndicator:SetPoint("BOTTOM")
    overDamageAbsorbIndicator:SetPoint("LEFT", Health, "RIGHT")
    overDamageAbsorbIndicator:SetWidth(10)

    frame.HealthPrediction = {
        damageAbsorb = damageAbsorb,
        overDamageAbsorbIndicator = overDamageAbsorbIndicator,
        incomingHealOverflow = cfg.maxAbsorbOverflow or 1.0,
    }
end

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddHealth(frame, cfg)
    local Health = CreateFrame("StatusBar", cfg.frameName, frame)

    if cfg.anchor then
        Health:SetPoint(cfg.anchor, cfg.relativeTo and _G[cfg.relativeTo] or frame, cfg.relativePoint, cfg.offsetX or 0, cfg.offsetY or 0)
    else
        Health:SetPoint("TOPLEFT", frame, "TOPLEFT")
        Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    end

    Health:SetHeight(cfg.height or frame:GetHeight())
    Health:SetWidth(cfg.width or frame:GetWidth())

    if cfg.healthTexture then
        local texturePath = addon:FetchStatusbar(cfg.healthTexture, "health")
        if texturePath then
            Health:SetStatusBarTexture(texturePath)
        end
    end

    if cfg.color == "class" then
        Health.colorClass = true
        Health.colorReaction = true

        Health.PostUpdateColor = function(self, unit, color)
            if unit and unit:match("^party%d$") then
                local _, classToken = UnitClass(unit)
                local name = UnitName(unit) or "?"
            end
        end

        Health.UpdateColorArenaPreparation = function(self, specID)
            if not specID or specID == 0 then return end
            local classID = C_SpecializationInfo.GetClassIDFromSpecID(specID)
            if classID then
                local _, classToken = GetClassInfo(classID)
                if classToken then
                    local color = frame.colors and frame.colors.class[classToken]
                    if color then
                        self:GetStatusBarTexture():SetVertexColor(color:GetRGB())
                        return
                    end
                end
            end
            local color = frame.colors and frame.colors.reaction and frame.colors.reaction[2]
            if color then
                self:GetStatusBarTexture():SetVertexColor(color:GetRGB())
            end
        end
    elseif cfg.color == "reaction" then
        Health.colorReaction = true
    else
        local hexColor = cfg.color
        if type(hexColor) == "string" and (hexColor:match("^%x%x%x%x%x%x$") or hexColor:match("^%x%x%x%x%x%x%x%x$")) then
            local r, g, b, a = addon:HexToRGB(hexColor)
            Health:SetStatusBarColor(r, g, b, a)
        else
            Health.colorReaction = true
        end
    end

    frame.Health = Health
    addon:AddBackground(Health, cfg)
    addon:AddBorder(Health, cfg)
end

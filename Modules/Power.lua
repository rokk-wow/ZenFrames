local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddPower(frame, cfg)
    local Power = CreateFrame("StatusBar", cfg.frameName, frame)
    local borderWidth = cfg.borderWidth
    local requestedWidth = cfg.width or frame:GetWidth()
    local renderWidth = math.max(1, requestedWidth - (borderWidth * 2))

    Power:SetFrameLevel(frame:GetFrameLevel() + 5)
    Power:SetPoint(cfg.anchor, cfg.relativeTo and _G[cfg.relativeTo] or frame, cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    Power:SetHeight(cfg.height)
    Power:SetWidth(renderWidth)

    if cfg.powerTexture then
        local texturePath = addon:FetchStatusbar(cfg.powerTexture)
        if texturePath then
            Power:SetStatusBarTexture(texturePath)
        end
    end

    Power.colorPower = true
    Power.frequentUpdates = true

    local adjustHealth = cfg.adjustHealthbarHeight and frame.Health
    local healthOriginalHeight = adjustHealth and frame.Health:GetHeight()
    local powerHeight = cfg.height
    local onlyHealer = cfg.onlyHealer

    Power.PostUpdate = function(self, unit, cur, min, max)
        local safeMax = addon:SecureCall(tostring, max)
        local hasPower = safeMax == nil or safeMax == false or tonumber(safeMax) ~= 0

        if hasPower and onlyHealer then
            local role = UnitGroupRolesAssigned(unit)
            if role ~= "HEALER" then
                hasPower = false
            end
        end

        if hasPower then
            self:Show()
            if adjustHealth then
                frame.Health:SetHeight(healthOriginalHeight - powerHeight)
            end
        else
            self:Hide()
            if adjustHealth then
                frame.Health:SetHeight(healthOriginalHeight)
            end
        end
    end

    if onlyHealer then
        frame:RegisterEvent("GROUP_ROSTER_UPDATE", function(self)
            if self.Power and self.Power.PostUpdate then
                self.Power:PostUpdate(self.unit, 0, 0, UnitPowerMax(self.unit))
            end
        end, true)
    end

    frame.Power = Power
    addon:AddBackground(Power, cfg)
    addon:AddBorder(Power, cfg)
end

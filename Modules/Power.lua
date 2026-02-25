local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddPower(frame, cfg, parentBorderCfg)
    local Power = CreateFrame("StatusBar", cfg.frameName, frame)
    local borderWidth = parentBorderCfg and parentBorderCfg.borderWidth or cfg.borderWidth
    local borderColor = parentBorderCfg and parentBorderCfg.borderColor or cfg.borderColor
    local requestedWidth = cfg.width or frame:GetWidth()
    local renderWidth = math.max(1, requestedWidth)

    Power:SetFrameLevel(frame:GetFrameLevel() + 5)
    Power:SetPoint(cfg.anchor, cfg.relativeTo and _G[cfg.relativeTo] or frame, cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    Power:SetHeight(cfg.height)
    Power:SetWidth(renderWidth)

    if cfg.powerTexture then
        local texturePath = addon:FetchStatusbar(cfg.powerTexture, "power")
        if texturePath then
            Power:SetStatusBarTexture(texturePath)
        end
    end

    Power.colorPower = true
    Power.frequentUpdates = true

    local adjustHealth = cfg.adjustHealthbarHeight and frame.Health
    local powerHeight = cfg.height
    local onlyHealer = cfg.onlyHealer

    if adjustHealth then
        Power._healthOriginalHeight = frame.Health:GetHeight()
    end

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
            if adjustHealth and self._healthOriginalHeight then
                frame.Health:SetHeight(self._healthOriginalHeight - powerHeight)
            end
        else
            self:Hide()
            if adjustHealth and self._healthOriginalHeight then
                frame.Health:SetHeight(self._healthOriginalHeight)
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

    local topBorder = Power:CreateTexture(nil, "OVERLAY", nil, 7)
    local bR, bG, bB, bA = addon:HexToRGB(borderColor or "000000FF")
    topBorder:SetColorTexture(bR, bG, bB, bA)
    topBorder:SetPoint("BOTTOMLEFT", Power, "TOPLEFT", 0, 0)
    topBorder:SetPoint("BOTTOMRIGHT", Power, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(borderWidth or 1)
    Power._topBorder = topBorder
end

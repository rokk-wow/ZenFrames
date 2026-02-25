local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddCastbar(frame, cfg)
    local Castbar = CreateFrame("StatusBar", cfg.frameName, frame)
    Castbar:SetFrameLevel(frame:GetFrameLevel() + 5)
    Castbar:SetPoint(cfg.anchor, cfg.relativeTo and _G[cfg.relativeTo] or frame, cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    Castbar:SetHeight(cfg.height)
    Castbar:SetWidth(cfg.width or frame:GetWidth())

    if cfg.castbarTexture then
        local texturePath = addon:FetchStatusbar(cfg.castbarTexture, "castbar")
        if texturePath then
            Castbar:SetStatusBarTexture(texturePath)
        end
    end

    local gcfg = addon.config.global
    local r, g, b = addon:HexToRGB(gcfg.castbarColor)
    Castbar:SetStatusBarColor(r, g, b)

    local function applyCastColor(self)
        if self.empowering then
            local er, eg, eb = addon:HexToRGB(gcfg.castbarEmpowerColor)
            self:SetStatusBarColor(er, eg, eb)
        elseif self.channeling then
            local cr, cg, cb = addon:HexToRGB(gcfg.castbarChannelColor)
            self:SetStatusBarColor(cr, cg, cb)
        else
            local dr, dg, db = addon:HexToRGB(gcfg.castbarColor)
            self:SetStatusBarColor(dr, dg, db)
        end
    end

    Castbar.PostCastStart = function(self) applyCastColor(self) end
    Castbar.PostCastInterruptible = function(self) applyCastColor(self) end

    local Spark = Castbar:CreateTexture(nil, "OVERLAY")
    Spark:SetSize(20, cfg.height)
    Spark:SetBlendMode("ADD")
    Spark:SetPoint("CENTER", Castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
    Castbar.Spark = Spark

    do
        local fontPath = addon:GetFontPath()
        local Text = Castbar:CreateFontString(nil, "OVERLAY")
        Text:SetFont(fontPath, cfg.textSize, "OUTLINE")
        local align = cfg.textAlignment
        local padding = cfg.textPadding
        if align == "CENTER" then
            Text:SetPoint("CENTER", Castbar, "CENTER", 0, 0)
        elseif align == "RIGHT" then
            Text:SetPoint("RIGHT", Castbar, "RIGHT", -padding, 0)
        else
            Text:SetPoint("LEFT", Castbar, "LEFT", padding, 0)
        end
        Text:SetJustifyH(align)
        Text:SetShown(cfg.showSpellName == true)
        Castbar.Text = Text
    end

    do
        local Time = Castbar:CreateFontString(nil, "OVERLAY")
        local fontPath = addon:GetFontPath()
        Time:SetFont(fontPath, cfg.textSize, "OUTLINE")
        if cfg.textAlignment == "RIGHT" then
            Time:SetPoint("LEFT", Castbar, "LEFT", 8, 0)
        else
            Time:SetPoint("RIGHT", Castbar, "RIGHT", -4, 0)
        end
        Time:SetShown(cfg.showCastTime == true)
        Castbar.Time = Time
    end

    do
        local IconFrame = CreateFrame("Frame", nil, Castbar)
        local iconSize = cfg.height
        local bw = cfg.borderWidth or 1
        if cfg.iconPosition == "RIGHT" then
            IconFrame:SetPoint("LEFT", Castbar, "RIGHT", 2 + bw, 0)
        else
            IconFrame:SetPoint("RIGHT", Castbar, "LEFT", -(2 + bw), 0)
        end
        IconFrame:SetSize(iconSize, iconSize)

        local Icon = IconFrame:CreateTexture(nil, "ARTWORK")
        Icon:SetAllPoints(IconFrame)
        Icon:SetTexCoord(0.15, 0.85, 0.15, 0.85)

        addon:AddBackground(IconFrame, cfg)
        addon:AddBorder(IconFrame, cfg)

        IconFrame:SetShown(cfg.showIcon == true)
        Castbar.IconFrame = IconFrame
        Castbar.Icon = Icon
    end

    frame.Castbar = Castbar
    addon:AttachPlaceholder(Castbar)
    addon:AddBackground(Castbar, cfg)
    addon:AddBorder(Castbar, cfg)
end

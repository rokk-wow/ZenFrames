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

    if cfg.showSpellName then
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
        Castbar.Text = Text
    end

    if cfg.showCastTime then
        local Time = Castbar:CreateFontString(nil, "OVERLAY")
        local fontPath = addon:GetFontPath()
        Time:SetFont(fontPath, 10, "OUTLINE")
        Time:SetPoint("RIGHT", Castbar, "RIGHT", -4, 0)
        Castbar.Time = Time
    end

    if cfg.showIcon then
        local Icon = Castbar:CreateTexture(nil, "OVERLAY")
        local iconSize = cfg.height
        if cfg.iconPosition == "RIGHT" then
            Icon:SetPoint("LEFT", Castbar, "RIGHT", 2, 0)
        else
            Icon:SetPoint("RIGHT", Castbar, "LEFT", -2, 0)
        end
        Icon:SetSize(iconSize, iconSize)
        Castbar.Icon = Icon
    end

    frame.Castbar = Castbar
    addon:AttachPlaceholder(Castbar)
    addon:AddBackground(Castbar, cfg)
    addon:AddBorder(Castbar, cfg)
end

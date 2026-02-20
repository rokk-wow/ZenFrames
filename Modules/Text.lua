local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:GetFontPath(fontName)
    return self:FetchFont(fontName)
end

function addon:ResolveFontSize(size)
    if type(size) == "number" then
        return size
    end
    if type(size) == "string" then
        local resolved = self.config.global[size]
        if type(resolved) == "number" then
            return resolved
        end
    end
    return 14
end

function addon:AddText(frame, textConfigs)
    if not textConfigs then return end

    if not frame.TextOverlay then
        frame.TextOverlay = CreateFrame("Frame", nil, frame)
        frame.TextOverlay:SetAllPoints(frame)
        frame.TextOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    end

    frame.Texts = frame.Texts or {}

    for i, cfg in ipairs(textConfigs) do
        if cfg.enabled then
            local fs = frame.TextOverlay:CreateFontString(nil, "OVERLAY")

            local fontPath = self:GetFontPath(cfg.font)
            local fontSize = self:ResolveFontSize(cfg.size)
            fs:SetFont(fontPath, fontSize, cfg.outline or "OUTLINE")

            local parent = cfg.relativeTo and _G[cfg.relativeTo] or frame
            fs:SetPoint(cfg.anchor, parent, cfg.relativePoint, cfg.offsetX or 0, cfg.offsetY or 0)

            local justify = cfg.justifyH
            if not justify then
                if cfg.anchor == "LEFT" or cfg.anchor == "TOPLEFT" or cfg.anchor == "BOTTOMLEFT" then
                    justify = "LEFT"
                elseif cfg.anchor == "RIGHT" or cfg.anchor == "TOPRIGHT" or cfg.anchor == "BOTTOMRIGHT" then
                    justify = "RIGHT"
                else
                    justify = "CENTER"
                end
            end
            fs:SetJustifyH(justify)

            if justify == "LEFT" or justify == "RIGHT" then
                local parentWidth = parent:GetWidth()
                if parentWidth and parentWidth > 0 then
                    fs:SetWidth(parentWidth * 0.5)
                    fs:SetWordWrap(false)
                end
            end

            if cfg.color then
                local r, g, b, a = self:HexToRGB(cfg.color)
                fs:SetTextColor(r, g, b, a or 1)
            end

            if cfg.shadow then
                fs:SetShadowOffset(1, -1)
                fs:SetShadowColor(0, 0, 0, 1)
            end

            if cfg.format then
                frame:Tag(fs, cfg.format)
            end

            frame.Texts[i] = fs
        end
    end
end

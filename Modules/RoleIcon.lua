local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddRoleIcon(frame, cfg)
    local size = cfg.size or 12
    local container = CreateFrame("Frame", nil, frame)
    container:SetAllPoints(frame)
    container:SetFrameLevel(frame:GetFrameLevel() + 10)

    local icon = container:CreateTexture(nil, "OVERLAY")
    icon:SetSize(size, size)
    icon:SetPoint(
        cfg.anchor or "LEFT",
        cfg.relativeTo and _G[cfg.relativeTo] or frame,
        cfg.relativePoint or "LEFT",
        cfg.offsetX or 0,
        cfg.offsetY or 0
    )

    if cfg.desaturate then
        icon:SetDesaturated(true)
    end

    if cfg.color then
        local r, g, b = addon:HexToRGB(cfg.color)
        icon:SetVertexColor(r, g, b)
    end

    icon.Override = function(self)
        local role = UnitGroupRolesAssigned(self.unit)
        if role and role ~= "NONE" then
            local atlas = addon.config.global.roleIcons[role]
            if atlas then
                icon:SetAtlas(atlas, false)
                icon:SetAlpha(1)
                icon:Show()
                return
            end
        end
        if cfg.defaultIcon then
            icon:SetAtlas(cfg.defaultIcon, false)
            icon:SetAlpha(cfg.defaultAlpha or 0.5)
            icon:Show()
        else
            icon:Hide()
        end
    end

    frame.GroupRoleIndicator = icon
end

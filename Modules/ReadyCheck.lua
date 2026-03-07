local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
local oUF = ns.oUF

function addon:AddReadyCheck(frame, cfg)
    local size = cfg.size or 20

    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(size, size)
    icon:SetPoint("CENTER", frame, "CENTER", cfg.offsetX or 0, cfg.offsetY or 0)
    icon:SetAtlas(cfg.atlas or "common-icon-checkmark-yellow", false)

    icon.Override = function(self, event)
        local unit = self.unit
        local element = self.ReadyCheckIndicator
        local status = GetReadyCheckStatus(unit)

        if status then
            if status == "ready" then
                element:SetDesaturated(false)
            else
                element:SetDesaturated(true)
            end
            element:Show()
        elseif event ~= "READY_CHECK_FINISHED" then
            element:Hide()
        end

        if event == "READY_CHECK_FINISHED" then
            element.Animation:Play()
        end
    end

    frame.ReadyCheckIndicator = icon
end

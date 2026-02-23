local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local BORDER_R, BORDER_G, BORDER_B, BORDER_A = 0, 1, 0.596, 0.6
local BG_R, BG_G, BG_B, BG_A = 0, 1, 0.596, 0.1
local HOVER_BORDER_A = 1.0
local HOVER_BG_A = 0.6
local BORDER_WIDTH = 1
local PADDING = 4
local LEVEL_OFFSET = 50

local placeholderGroups = {}
local selectedOverlay = nil

-- Convert module key (camelCase) to frame property name (PascalCase)
-- Special handling for acronyms like drTracker -> DRTracker
local function GetModuleFrameName(moduleKey)
    if not moduleKey then return nil end
    
    -- Special cases for acronyms
    if moduleKey == "drTracker" then
        return "DRTracker"
    end
    
    -- Default: uppercase first letter only
    return moduleKey:sub(1, 1):upper() .. moduleKey:sub(2)
end

local function GetConfigPath(overlay)
    local path = overlay._configKey or ""
    if overlay._moduleKey then
        path = path .. "." .. overlay._moduleKey
    end
    return path
end

local function HighlightOverlay(overlay)
    overlay._bg:SetColorTexture(BG_R, BG_G, BG_B, HOVER_BG_A)
    for _, b in ipairs(overlay._borders) do
        b:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, HOVER_BORDER_A)
    end
end

local function UnhighlightOverlay(overlay)
    overlay._bg:SetColorTexture(BG_R, BG_G, BG_B, BG_A)
    for _, b in ipairs(overlay._borders) do
        b:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
    end
end

local function RegisterPlaceholder(overlay)
    local path = GetConfigPath(overlay)
    if not placeholderGroups[path] then
        placeholderGroups[path] = {}
    end
    placeholderGroups[path][overlay] = true
end

local function UnregisterPlaceholder(overlay)
    local path = GetConfigPath(overlay)
    if placeholderGroups[path] then
        placeholderGroups[path][overlay] = nil
    end
end

-- Helper function to update position after drag or nudge
local function UpdatePlaceholderPosition(overlay)
    if not overlay._configKey then return end
    
    local parent = overlay:GetParent()
    if not parent then return end
    
    local cfg = addon.config[overlay._configKey]
    local isAuraFilter = false
    local auraFilterIndex = nil
    
    -- Check if this is an auraFilter (they're stored in arrays)
    if overlay._moduleKey and cfg.modules and cfg.modules.auraFilters then
        for i, filter in ipairs(cfg.modules.auraFilters) do
            if filter.name == overlay._moduleKey then
                cfg = filter
                isAuraFilter = true
                auraFilterIndex = i
                break
            end
        end
    end
    
    -- If not an auraFilter, check regular modules
    if not isAuraFilter and overlay._moduleKey and cfg.modules and cfg.modules[overlay._moduleKey] then
        cfg = cfg.modules[overlay._moduleKey]
    end

    local relativeFrame
    local anchorPoint = cfg.anchor
    local relativePoint = cfg.relativePoint
    
    if cfg.relativeTo then
        relativeFrame = _G[cfg.relativeTo]
    else
        relativeFrame = parent:GetParent()
    end

    if anchorPoint and relativeFrame and relativePoint then
        local parentLeft, parentBottom = parent:GetLeft(), parent:GetBottom()
        local parentRight = parent:GetRight()
        local parentTop = parent:GetTop()

        local relativeLeft, relativeBottom = relativeFrame:GetLeft(), relativeFrame:GetBottom()
        local relativeRight = relativeFrame:GetRight()
        local relativeTop = relativeFrame:GetTop()

        local parentX, parentY
        if anchorPoint:find("LEFT") then
            parentX = parentLeft
        elseif anchorPoint:find("RIGHT") then
            parentX = parentRight
        else
            parentX = (parentLeft + parentRight) / 2
        end

        if anchorPoint:find("TOP") then
            parentY = parentTop
        elseif anchorPoint:find("BOTTOM") then
            parentY = parentBottom
        else
            parentY = (parentTop + parentBottom) / 2
        end

        local relativeX, relativeY
        if relativePoint:find("LEFT") then
            relativeX = relativeLeft
        elseif relativePoint:find("RIGHT") then
            relativeX = relativeRight
        else
            relativeX = (relativeLeft + relativeRight) / 2
        end

        if relativePoint:find("TOP") then
            relativeY = relativeTop
        elseif relativePoint:find("BOTTOM") then
            relativeY = relativeBottom
        else
            relativeY = (relativeTop + relativeBottom) / 2
        end

        local newOffsetX = math.floor((parentX - relativeX) + 0.5)
        local newOffsetY = math.floor((parentY - relativeY) + 0.5)

        if isAuraFilter then
            addon:SetOverride({overlay._configKey, "modules", "auraFilters", auraFilterIndex, "offsetX"}, newOffsetX)
            addon:SetOverride({overlay._configKey, "modules", "auraFilters", auraFilterIndex, "offsetY"}, newOffsetY)
        elseif overlay._moduleKey then
            addon:SetOverride({overlay._configKey, "modules", overlay._moduleKey, "offsetX"}, newOffsetX)
            addon:SetOverride({overlay._configKey, "modules", overlay._moduleKey, "offsetY"}, newOffsetY)
        else
            addon:SetOverride({overlay._configKey, "offsetX"}, newOffsetX)
            addon:SetOverride({overlay._configKey, "offsetY"}, newOffsetY)
        end

        addon.config = addon:GetConfig()

        parent:ClearAllPoints()
        parent:SetPoint(anchorPoint, relativeFrame, relativePoint, newOffsetX, newOffsetY)
        
        -- If this is a group frame module (party/arena), update all instances
        if overlay._moduleKey and not isAuraFilter and (overlay._configKey == "party" or overlay._configKey == "arena") then
            local unitFrame = parent:GetParent()
            if unitFrame then
                local container = unitFrame:GetParent()
                if container and container.frames then
                    -- Convert module key to PascalCase to access frame property (e.g., "trinket" -> "Trinket", "drTracker" -> "DRTracker")
                    local moduleName = GetModuleFrameName(overlay._moduleKey)
                    
                    for _, frame in ipairs(container.frames) do
                        local module = frame[moduleName]
                        if module and module ~= parent then
                            -- Determine the anchor frame for this module instance
                            local moduleAnchorFrame = frame
                            -- DEPRECATED: relativeToModule is deprecated but supported for backwards compatibility
                            if cfg.relativeToModule then
                                local ref = cfg.relativeToModule
                                if type(ref) == "table" then
                                    for _, key in ipairs(ref) do
                                        if frame[key] then
                                            moduleAnchorFrame = frame[key]
                                            break
                                        end
                                    end
                                else
                                    moduleAnchorFrame = frame[ref] or frame
                                end
                            end
                            
                            local moduleRelativeFrame = cfg.relativeTo and _G[cfg.relativeTo] or moduleAnchorFrame
                            
                            module:ClearAllPoints()
                            module:SetPoint(anchorPoint, moduleRelativeFrame, relativePoint, newOffsetX, newOffsetY)
                        end
                    end
                end
            end
        end
        
        -- If this is a group frame auraFilter (party/arena), update all instances
        if isAuraFilter and (overlay._configKey == "party" or overlay._configKey == "arena") then
            local unitFrame = parent:GetParent()
            if unitFrame then
                local container = unitFrame:GetParent()
                if container and container.frames then
                    -- For auraFilters, the moduleKey is the filter name
                    for _, frame in ipairs(container.frames) do
                        local filter = frame[overlay._moduleKey]
                        if filter and filter ~= parent then
                            -- Determine the anchor frame for this filter instance
                            local filterAnchorFrame = frame
                            -- DEPRECATED: relativeToModule is deprecated but supported for backwards compatibility
                            if cfg.relativeToModule then
                                local ref = cfg.relativeToModule
                                if type(ref) == "table" then
                                    for _, key in ipairs(ref) do
                                        if frame[key] then
                                            filterAnchorFrame = frame[key]
                                            break
                                        end
                                    end
                                else
                                    filterAnchorFrame = frame[ref] or frame
                                end
                            end
                            
                            local filterRelativeFrame = cfg.relativeTo and _G[cfg.relativeTo] or filterAnchorFrame
                            
                            filter:ClearAllPoints()
                            filter:SetPoint(anchorPoint, filterRelativeFrame, relativePoint, newOffsetX, newOffsetY)
                        end
                    end
                end
            end
        end
    end
end

function addon:AttachPlaceholder(element)
    if not element or element._placeholder then return end

    function element:ShowPlaceholder(configKey, moduleKey)
        if InCombatLockdown() then return end
        
        if not self._placeholder then
            local overlay = CreateFrame("Frame", nil, self)
            overlay:SetPoint("TOPLEFT", self, "TOPLEFT", -PADDING, PADDING)
            overlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", PADDING, -PADDING)
            overlay:SetFrameLevel(self:GetFrameLevel() + LEVEL_OFFSET)

            local bg = overlay:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(overlay)
            bg:SetColorTexture(BG_R, BG_G, BG_B, BG_A)

            local border = overlay:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
            border:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
            border:SetHeight(BORDER_WIDTH)
            border:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            local borderBottom = overlay:CreateTexture(nil, "BORDER")
            borderBottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
            borderBottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
            borderBottom:SetHeight(BORDER_WIDTH)
            borderBottom:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            local borderLeft = overlay:CreateTexture(nil, "BORDER")
            borderLeft:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
            borderLeft:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
            borderLeft:SetWidth(BORDER_WIDTH)
            borderLeft:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            local borderRight = overlay:CreateTexture(nil, "BORDER")
            borderRight:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
            borderRight:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
            borderRight:SetWidth(BORDER_WIDTH)
            borderRight:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)

            overlay:EnableMouse(false)
            overlay:SetFrameStrata("BACKGROUND")

            overlay._bg = bg
            overlay._borders = { border, borderBottom, borderLeft, borderRight }

            overlay:SetScript("OnEnter", function(self)
                local path = GetConfigPath(self)
                local group = placeholderGroups[path]
                if group then
                    for o in pairs(group) do
                        HighlightOverlay(o)
                    end
                else
                    HighlightOverlay(self)
                end
            end)

            overlay:SetScript("OnLeave", function(self)
                local path = GetConfigPath(self)
                local group = placeholderGroups[path]
                if group then
                    for o in pairs(group) do
                        UnhighlightOverlay(o)
                    end
                else
                    UnhighlightOverlay(self)
                end
            end)

            overlay:SetScript("OnMouseDown", function(self, button)
                if InCombatLockdown() then return end
                
                if button == "LeftButton" and self._configKey then
                    addon:ShowEditModeSubDialog(self._configKey, self._moduleKey)
                    
                    -- Deselect previously selected overlay
                    if selectedOverlay and selectedOverlay ~= self then
                        selectedOverlay:EnableKeyboard(false)
                        selectedOverlay:SetPropagateKeyboardInput(true)
                    end
                    
                    -- Set this as the selected overlay for keyboard input
                    selectedOverlay = self
                    self:EnableKeyboard(true)
                    self:SetPropagateKeyboardInput(false)
                    
                    local parent = self:GetParent()
                    if parent and not InCombatLockdown() then
                        parent:SetMovable(true)
                        parent:StartMoving()
                    end
                end
            end)

            overlay:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    local parent = self:GetParent()
                    if parent and parent:IsMovable() then
                        parent:StopMovingOrSizing()
                        parent:SetMovable(false)
                        
                        UpdatePlaceholderPosition(self)
                    end
                end
            end)

            overlay:SetScript("OnKeyDown", function(self, key)
                if InCombatLockdown() then
                    self:SetPropagateKeyboardInput(true)
                    return
                end
                
                if key == "ESCAPE" then
                    -- Deselect on escape
                    self:EnableKeyboard(false)
                    self:SetPropagateKeyboardInput(true)
                    if selectedOverlay == self then
                        selectedOverlay = nil
                    end
                    return
                end
                
                -- Handle arrow keys for nudging
                local dx, dy = 0, 0
                local distance = IsShiftKeyDown() and 10 or 1
                
                if key == "UP" then
                    dy = distance
                elseif key == "DOWN" then
                    dy = -distance
                elseif key == "LEFT" then
                    dx = -distance
                elseif key == "RIGHT" then
                    dx = distance
                else
                    -- Not an arrow key, let it propagate
                    self:SetPropagateKeyboardInput(true)
                    return
                end
                
                -- Nudge the frame
                local parent = self:GetParent()
                if parent and not InCombatLockdown() then
                    local point, relativeTo, relativePoint, xOfs, yOfs = parent:GetPoint(1)
                    if point and relativeTo and relativePoint then
                        parent:ClearAllPoints()
                        parent:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + dx, (yOfs or 0) + dy)
                        
                        UpdatePlaceholderPosition(self)
                    end
                end
                
                -- Prevent keyboard input from propagating for arrow keys
                self:SetPropagateKeyboardInput(false)
            end)

            self._placeholder = overlay
        end

        local overlay = self._placeholder
        overlay._configKey = configKey
        overlay._moduleKey = moduleKey
        overlay:SetFrameStrata("DIALOG")
        overlay:EnableMouse(true)
        overlay:EnableKeyboard(false)
        overlay:SetPropagateKeyboardInput(true)

        RegisterPlaceholder(overlay)

        -- Only override Hide on non-secure frames to avoid taint
        if not self._savedHide and not self:IsProtected() then
            self._savedHide = self.Hide
            self.Hide = function() end
        end

        self:Show()
        overlay:Show()
    end

    function element:HidePlaceholder()
        if self._placeholder then
            UnregisterPlaceholder(self._placeholder)
            self._placeholder:SetFrameStrata("BACKGROUND")
            self._placeholder:EnableMouse(false)
            self._placeholder:EnableKeyboard(false)
            self._placeholder:SetPropagateKeyboardInput(true)
            if selectedOverlay == self._placeholder then
                selectedOverlay = nil
            end
            self._placeholder:Hide()
        end

        if self._savedHide then
            self.Hide = self._savedHide
            self._savedHide = nil
        end
    end
end

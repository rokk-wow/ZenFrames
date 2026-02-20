-- LibSAdCore - Simple Addon Core Library
-- LibSAdCore integrates the following libraries:
-- * LibStub      
-- * LibCompress      
-- * LibSerialize
-- Thank you to all the authors and contributors who make WoW addon iteration and development possible.
-- LibSAdCore is freely offered forward to any developer who wants to fork, branch, embed or in any way
-- use this code for further development.

local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2
local LibStub = _G[LIBSTUB_MAJOR]

-- SAdCore Version
local SADCORE_MAJOR, SADCORE_MINOR = "SAdCore-1", 26

if not LibStub or LibStub.minor < LIBSTUB_MINOR then
    LibStub = LibStub or {
        libs = {},
        minors = {}
    }
    _G[LIBSTUB_MAJOR] = LibStub
    LibStub.minor = LIBSTUB_MINOR

    function LibStub:NewLibrary(major, minor)
        assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
        minor = assert(tonumber(strmatch(minor, "%d+")), "Minor version must either be a number or contain a number.")

        local oldminor = self.minors[major]
        if oldminor and oldminor >= minor then
            return nil
        end
        self.minors[major], self.libs[major] = minor, self.libs[major] or {}
        return self.libs[major], oldminor
    end

    function LibStub:GetLibrary(major, silent)
        if not self.libs[major] and not silent then
            error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
        end
        return self.libs[major], self.minors[major]
    end

    function LibStub:IterateLibraries()
        return pairs(self.libs)
    end

    setmetatable(LibStub, {
        __call = LibStub.GetLibrary
    })
end

--[[============================================================================
    LibCompress - Simple base64 encoding
==============================================================================]]
local LIBCOMPRESS_MAJOR, LIBCOMPRESS_MINOR = "LibCompress", 1
local LibCompress = LibStub:NewLibrary(LIBCOMPRESS_MAJOR, LIBCOMPRESS_MINOR)
if LibCompress then
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local b64lookup = {}
    for i = 1, #b64chars do
        b64lookup[b64chars:sub(i, i)] = i - 1
    end

    function LibCompress:Encode(data)
        if type(data) ~= "string" then
            return nil, "Data must be a string"
        end

        return ((data:gsub('.', function(x)
            local r, b = '', x:byte()
            for i = 8, 1, -1 do
                r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
            end
            return r
        end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if #x < 6 then
                return ''
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
            end
            return b64chars:sub(c + 1, c + 1)
        end) .. ({'', '==', '='})[#data % 3 + 1])
    end

    function LibCompress:Decode(data)
        if type(data) ~= "string" then
            return nil, "Data must be a string"
        end

        data = string.gsub(data, '[^' .. b64chars .. '=]', '')
        return (data:gsub('.', function(x)
            if x == '=' then
                return ''
            end
            local r, f = '', b64lookup[x]
            for i = 6, 1, -1 do
                r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
            end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if #x ~= 8 then
                return ''
            end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
            end
            return string.char(c)
        end))
    end

    function LibCompress:Compress(data)
        return self:Encode(data)
    end

    function LibCompress:Decompress(data)
        return self:Decode(data)
    end

    function LibCompress:GetAddonEncodeTable()
        local tbl = {}
        function tbl:Encode(str)
            return (str:gsub("%z", "\001\001"))
        end
        function tbl:Decode(str)
            return (str:gsub("\001\001", "\000"))
        end
        return tbl
    end
end

--[[============================================================================
    LibSerialize - Simple table serialization
==============================================================================]]
local LIBSERIALIZE_MAJOR, LIBSERIALIZE_MINOR = "LibSerialize", 1
local LibSerialize = LibStub:NewLibrary(LIBSERIALIZE_MAJOR, LIBSERIALIZE_MINOR)
if LibSerialize then
    local serialize_simple

    local function serialize_value(v)
        local tv = type(v)
        if tv == "string" then
            return string.format("%q", v)
        elseif tv == "number" or tv == "boolean" then
            return tostring(v)
        elseif tv == "table" then
            return serialize_simple(v)
        else
            return "nil"
        end
    end

    serialize_simple = function(tbl)
        local result = {}
        result[1] = "{"
        local first = true

        for k, v in pairs(tbl) do
            if not first then
                table.insert(result, ",")
            end
            first = false

            if type(k) == "string" then
                table.insert(result, "[")
                table.insert(result, string.format("%q", k))
                table.insert(result, "]=")
            elseif type(k) == "number" then
                table.insert(result, "[")
                table.insert(result, tostring(k))
                table.insert(result, "]=")
            else
                first = true
                table.remove(result)
            end

            if type(k) == "string" or type(k) == "number" then
                table.insert(result, serialize_value(v))
            end
        end

        table.insert(result, "}")
        return table.concat(result)
    end

    function LibSerialize:Serialize(data)
        if type(data) ~= "table" then
            return nil, "Data must be a table"
        end

        local success, result = pcall(serialize_simple, data)
        if not success then
            return nil, result
        end

        return result
    end

    function LibSerialize:Deserialize(str)
        if not str or str == "" then
            return nil, "Empty string"
        end

        local sanitized = str:gsub("\r", ""):gsub("\n", ""):gsub("%s+", " ")
        local func, err = loadstring("return " .. sanitized)
        if not func then
            return nil, "Parse error: " .. tostring(err)
        end

        local success, result = pcall(func)
        if not success then
            return nil, "Execution error: " .. tostring(result)
        end

        return result
    end
end

--[[============================================================================
    SAdCore - Simple Addon Core
==============================================================================]]

local SAdCore, oldminor = LibStub:NewLibrary(SADCORE_MAJOR, SADCORE_MINOR)
if not SAdCore then
    return
end

SAdCore.addons = SAdCore.addons or {}
SAdCore.prototype = SAdCore.prototype or {}

local addon = SAdCore.prototype
local function callHook(addonInstance, hookName, ...)
    local hook = addonInstance[hookName]
    if hook then
        return hook(addonInstance, ...)
    end
    return ...
end

local function getCoreLocaleString(key)
    local clientLocale = GetLocale()
    local locale = SAdCore.prototype.locale[clientLocale] or SAdCore.prototype.locale.enEN
    return locale and locale[key] or key
end

function SAdCore:GetAddon(addonName)
    if not self.addons[addonName] then
        local newAddon = {
            addonName = addonName,
            core = self,
            locale = {},
            sadCore = {}
        }
        setmetatable(newAddon, {
            __index = self.prototype
        })
        self.addons[addonName] = newAddon

        local addonInstance = newAddon
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
            if loadedAddon == addonInstance.addonName then
                addonInstance.sadCore = addonInstance.sadCore or {}
                
                local hasError = not addonInstance.sadCore.savedVarsGlobalName or
                                 not addonInstance.sadCore.savedVarsPerCharName or
                                 not addonInstance.sadCore.compartmentFuncName or
                                 (addonInstance.sadCore.savedVarsGlobalName and not string.find(addonInstance.sadCore.savedVarsGlobalName, addonInstance.addonName, 1, true)) or
                                 (addonInstance.sadCore.savedVarsPerCharName and not string.find(addonInstance.sadCore.savedVarsPerCharName, addonInstance.addonName, 1, true)) or
                                 (addonInstance.sadCore.compartmentFuncName and not string.find(addonInstance.sadCore.compartmentFuncName, addonInstance.addonName, 1, true))

                if hasError then
                    addon._coreInfo(getCoreLocaleString("core_errorConfigHelp1"))
                    addon._coreInfo(getCoreLocaleString("core_errorConfigHelp2"))
                    addon._coreInfo(getCoreLocaleString("core_errorConfigExample") .. " '" .. addonInstance.addonName .. "':")
                    addon._coreInfo("  addon.sadCore.savedVarsGlobalName = '" .. addonInstance.addonName .. "_Settings_Global'")
                    addon._coreInfo("  addon.sadCore.savedVarsPerCharName = '" .. addonInstance.addonName .. "_Settings_Char'")
                    addon._coreInfo("  addon.sadCore.compartmentFuncName = '" .. addonInstance.addonName .. "_Compartment_Func'")
                    error(string.format("%s: %s - %s", getCoreLocaleString("core_SAdCore"), addonInstance.addonName,
                        getCoreLocaleString("core_errorConfigHelp1")))
                    return
                end

                _G[addonInstance.sadCore.savedVarsGlobalName] = _G[addonInstance.sadCore.savedVarsGlobalName] or {}
                _G[addonInstance.sadCore.savedVarsPerCharName] = _G[addonInstance.sadCore.savedVarsPerCharName] or {}

                local savedVarsGlobal = _G[addonInstance.sadCore.savedVarsGlobalName]
                local savedVarsPerChar = _G[addonInstance.sadCore.savedVarsPerCharName]

                addonInstance:_Initialize(savedVarsGlobal, savedVarsPerChar)

                _G[addonInstance.sadCore.compartmentFuncName] = function()
                    addonInstance:OpenSettings()
                end

                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
    return self.addons[addonName]
end

do -- Initialize

    function addon:_Initialize(savedVarsGlobal, savedVarsPerChar)
        callHook(self, "BeforeInitialize", savedVarsGlobal, savedVarsPerChar)

        self.sadCore = self.sadCore or {}
        self.sadCore.panels = self.sadCore.panels or {}
        self.sadCore.panelOrder = self.sadCore.panelOrder or {}
        self.apiVersion = select(4, GetBuildInfo())

        local clientLocale = GetLocale()

        for localeKey, prototypeLocale in pairs(SAdCore.prototype.locale) do
            if not self.locale[localeKey] then
                self.locale[localeKey] = prototypeLocale
            else
                local userLocale = self.locale[localeKey]
                self.locale[localeKey] = {}
                for key, value in pairs(prototypeLocale) do
                    self.locale[localeKey][key] = value
                end
                for key, value in pairs(userLocale) do
                    self.locale[localeKey][key] = value
                end
            end
        end

        self.localization = self.locale[clientLocale] or self.locale.enEN

        self.sadCore.config = self.sadCore.config or {
            retryDelay = .1,
            retryMaxAttempts = 50
        }

        self.sadCore.ui = self.sadCore.ui or {
            spacing = {
                panelTop = -25,
                panelBottom = 20,
                headerHeight = 60,
                controlHeight = 38,
                buttonHeight = 50,
                descriptionPadding = 6,
                contentLeft = 10,
                contentRight = -10,
                controlLeft = 30,
                controlRight = -10,
                textInset = 17
            },
            dialog = {
                defaultWidth = 500,
                titleHeight = 40,
                buttonHeight = 50,
                contentPadding = 20,
                titleOffset = -15,
                contentTop = -40,
                contentBottom = 50,
                buttonSize = {
                    width = 100,
                    height = 25
                },
                buttonOffset = 15,
                initialYOffset = -10
            },
            dropdown = {
                width = 150
            },
            slider = {
                width = 205
            },
            backdrop = {
                edgeSize = 2,
                insets = {
                    left = 2,
                    right = 2,
                    top = 2,
                    bottom = 2
                }
            }
        }

        self.currentZone = self:GetCurrentZone()
        self.previousZone = nil

        local handleZoneChangeCallback = function(event, ...)
            self:_HandleZoneChange()
        end

        self:RegisterEvent("PLAYER_ENTERING_WORLD", handleZoneChangeCallback)
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA", handleZoneChangeCallback)
        self:RegisterEvent("PVP_MATCH_ACTIVE", handleZoneChangeCallback)
        self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", handleZoneChangeCallback)
        self:RegisterEvent("ARENA_OPPONENT_UPDATE", handleZoneChangeCallback)
        self:RegisterEvent("PVP_MATCH_INACTIVE", handleZoneChangeCallback)
        self:RegisterEvent("PLAYER_ROLES_ASSIGNED", handleZoneChangeCallback)

        self.author = self.author or "SAdCore Framework"
        self:_InitializeSavedVariables(savedVarsGlobal, savedVarsPerChar)

        if self.Initialize then
            self:Initialize()
        end

        self.LibSerialize = LibStub("LibSerialize")
        self.LibCompress = LibStub("LibCompress")

        self:_InitializeSettingsPanel()

        self:_InitializeCombatQueue()
        self:_InitializeReleaseNotes()

        local returnValue = true
        callHook(self, "AfterInitialize", returnValue)

        self.initialized = true

        return returnValue
    end

    function addon:_InitializeSavedVariables(savedVarsGlobal, savedVarsPerChar)
        savedVarsGlobal, savedVarsPerChar = callHook(self, "BeforeInitializeSavedVariables", savedVarsGlobal,
            savedVarsPerChar)

        if savedVarsGlobal then
            self.savedVarsGlobal = savedVarsGlobal
            self.savedVarsGlobal.main = self.savedVarsGlobal.main or {}
        else
            self.savedVarsGlobal = {}
            self.savedVarsGlobal.main = {}
        end

        if savedVarsPerChar then
            self.savedVarsChar = savedVarsPerChar
            self.savedVarsChar.main = self.savedVarsChar.main or {}
        else
            self.savedVarsChar = {}
            self.savedVarsChar.main = {}
        end

        if self.sadCore and self.sadCore.savedVarsGlobalName then
            _G[self.sadCore.savedVarsGlobalName] = self.savedVarsGlobal
        end
        if self.sadCore and self.sadCore.savedVarsPerCharName then
            _G[self.sadCore.savedVarsPerCharName] = self.savedVarsChar
        end

        self.savedVars = (self.savedVarsChar.useCharacterSettings) and self.savedVarsChar or self.savedVarsGlobal

        local returnValue = true
        callHook(self, "AfterInitializeSavedVariables", returnValue)
        return returnValue
    end

    function addon:_Setup(savedVarsGlobal, savedVarsPerChar, compartmentFuncName)
        local addonInstance = self
        savedVarsGlobal, savedVarsPerChar, compartmentFuncName =
            callHook(self, "BeforeSetup", savedVarsGlobal, savedVarsPerChar, compartmentFuncName)

        self.setupConfig = {
            savedVarsGlobal = savedVarsGlobal,
            savedVarsPerChar = savedVarsPerChar,
            compartmentFuncName = compartmentFuncName
        }

        if not self.setupEventFrame then
            self.setupEventFrame = CreateFrame("Frame")
            self.setupEventFrame:RegisterEvent("ADDON_LOADED")
            self.setupEventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
                if loadedAddon == addonInstance.addonName then
                    addonInstance:_Initialize(addonInstance.setupConfig.savedVarsGlobal,
                        addonInstance.setupConfig.savedVarsPerChar)

                    if addonInstance.setupConfig.compartmentFuncName then
                        _G[addonInstance.setupConfig.compartmentFuncName] = function()
                            addonInstance:OpenSettings()
                        end
                    end

                    self:UnregisterEvent("ADDON_LOADED")
                    addonInstance.setupEventFrame = nil
                end
            end)
        end

        local returnValue = true
        callHook(self, "AfterSetup", returnValue)
        return returnValue
    end
end

do -- Registration functions

        function addon:AddSettingsPanel(panelKey, panelConfig)
        panelKey, panelConfig = callHook(self, "BeforeAddSettingsPanel", panelKey, panelConfig)

        if panelKey == "main" then
            assert(panelConfig.controls, "Main panel must have a 'controls' table.")
            
            self.sadCore.panels = self.sadCore.panels or {}
            self.sadCore.panels.main = self.sadCore.panels.main or {}
            self.sadCore.panels.main.controls = panelConfig.controls
            
            local returnValue = true
            callHook(self, "AfterAddSettingsPanel", returnValue)
            return returnValue
        end

        assert(not self.sadCore.panels[panelKey], string.format("Panel '%s' already exists. Each panel key must be unique.", panelKey))

        self.sadCore.panels = self.sadCore.panels or {}
        self.sadCore.panelOrder = self.sadCore.panelOrder or {}
        self.sadCore.panels[panelKey] = panelConfig
        
        local alreadyTracked = false
        for _, key in ipairs(self.sadCore.panelOrder) do
            if key == panelKey then
                alreadyTracked = true
                break
            end
        end
        
        if not alreadyTracked then
            table.insert(self.sadCore.panelOrder, panelKey)
        end

        local returnValue = true
        callHook(self, "AfterAddSettingsPanel", returnValue)
        return returnValue
    end

    function addon:RegisterEvent(eventName, callback)
        local addonInstance = self
        eventName, callback = callHook(self, "BeforeRegisterEvent", eventName, callback)

        if self.eventFrame == nil then
            self.eventFrame = CreateFrame("Frame", nil, UIParent)
            self.eventCallbacks = {}
            self.eventFrame:SetScript("OnEvent", function(self, event, ...)
                local eventCallback = addonInstance.eventCallbacks[event]
                if eventCallback then
                    eventCallback(addonInstance, event, ...)
                end
            end)
        end

        self.eventFrame:RegisterEvent(eventName)
        self.eventCallbacks[eventName] = callback

        local returnValue = true
        callHook(self, "AfterRegisterEvent", returnValue)
        return returnValue
    end

    function addon:RegisterFrameEvent(eventName, callback)
        local addonInstance = self
        eventName, callback = callHook(self, "BeforeRegisterFrameEvent", eventName, callback)

        EventRegistry:RegisterCallback(eventName, function(...)
            callback(addonInstance, ...)
        end)

        local returnValue = true
        callHook(self, "AfterRegisterFrameEvent", returnValue)
        return returnValue
    end

    function addon:RegisterSlashCommand(command, callback)
        command, callback = callHook(self, "BeforeRegisterSlashCommand", command, callback)

        local commandName = command:upper()
        local commandString = "/" .. command:lower()
        self:_CreateSlashCommand(commandName, commandString, callback)

        local returnValue = true
        callHook(self, "AfterRegisterSlashCommand", returnValue)
        return returnValue
    end

    function addon:_CreateSlashCommand(commandName, commandString, callback)
        local addonInstance = self
        callHook(self, "BeforeCreateSlashCommand", commandName, commandString, callback)

        _G["SLASH_" .. commandName .. "1"] = commandString
        SlashCmdList[commandName] = function(message)
            local params = {}
            if message and message ~= "" then
                for param in message:gmatch("%S+") do
                    table.insert(params, param)
                end
            end
            callback(addonInstance, unpack(params))
        end

        local returnValue = true
        callHook(self, "AfterCreateSlashCommand", returnValue)
        return returnValue
    end
end

do -- Zone Management

    addon.zones = {"arena", "battleground", "dungeon", "raid", "world"}

    function addon:GetCurrentZone()
        callHook(self, "BeforeGetCurrentZone")

        local zoneName = "world"
        local instanceName, instanceType = GetInstanceInfo()

        if instanceType == "arena" then
            zoneName = "arena"
        elseif instanceType == "pvp" then
            zoneName = "battleground"
        elseif instanceType == "party" then
            zoneName = "dungeon"
        elseif instanceType == "raid" then
            zoneName = "raid"
        else
            zoneName = "world"
        end

        local returnValue = zoneName
        callHook(self, "AfterGetCurrentZone", returnValue)
        return returnValue
    end

    function addon:_HandleZoneChange()
        callHook(self, "BeforeHandleZoneChange")

        if not self.initialized then
            local returnValue = false
            callHook(self, "AfterHandleZoneChange", returnValue)
            return returnValue
        end

        local currentZone = self:GetCurrentZone()

        if currentZone == self.previousZone and self.previousZone ~= nil then
            local returnValue = false
            callHook(self, "AfterHandleZoneChange", returnValue)
            return returnValue
        end

        self.previousZone = self.currentZone
        self.currentZone = currentZone

        callHook(self, "OnZoneChange", currentZone)

        local returnValue = true
        callHook(self, "AfterHandleZoneChange", returnValue, self.currentZone)
        return returnValue
    end
end

do -- Settings Panels

    function addon:_ConfigureMainSettings()
        callHook(self, "BeforeConfigureMainSettings")

        local footerControls = {{
            type = "header",
            name = "core_debuggingHeader"
        }, {
            type = "checkbox",
            name = "core_enableDebugging",
            default = false
        }, {
            type = "header",
            name = "core_profile"
        }, {
            type = "checkbox",
            name = "core_useCharacterSettings",
            default = false,
            onValueChange = function(addonInstance, value)
                addonInstance:Debug("useCharacterSettings onValueChange called with value: " .. tostring(value) ..
                                        " (type: " .. type(value) .. ")")
                addonInstance:_UpdateActiveSettings(value)
            end,
            skipRefresh = true
        }, {
            type = "inputBox",
            name = "core_loadSettings",
            buttonText = "core_loadSettingsButton",
            sessionOnly = true,
            onClick = function(addonInstance, inputText, editBox)
                addonInstance:_ImportSettings(inputText)
                editBox:SetText("")
            end
        }, {
            type = "button",
            name = "core_shareSettings",
            onClick = function()
                self:_ExportSettings()
            end
        }, {
            type = "divider"
        }, {
            type = "description",
            name = "author",
            onClick = function()
                self:_ShowDialog({
                    title = "core_authorTitle",
                    controls = {{
                        type = "inputBox",
                        name = "core_authorName",
                        default = self.author,
                        highlightText = true
                    }}
                })
            end
        }, {
            type = "divider"
        }, {
            type = "button",
            name = "core_showReleaseNotes",
            onClick = function()
                self:ShowReleaseNotes()
            end
        }}

        local main = {}
        main.title = self.addonName
        main.controls = {}

        if self.sadCore.panels.main and self.sadCore.panels.main.controls then
            for _, control in ipairs(self.sadCore.panels.main.controls) do
                table.insert(main.controls, control)
            end
        end

        for _, control in ipairs(footerControls) do
            table.insert(main.controls, control)
        end

        self.sadCore.panels.main = main

        local returnValue = true
        callHook(self, "AfterConfigureMainSettings", returnValue)
        return returnValue
    end

    function addon:_InitializeDefaultSettings()
        callHook(self, "BeforeInitializeDefaultSettings")

        if not self.sadCore.panels then
            callHook(self, "AfterInitializeDefaultSettings", false)
            return false
        end

        self.savedVars.data = self.savedVars.data or {}

        for panelKey, panelConfig in pairs(self.sadCore.panels) do
            self.savedVars[panelKey] = self.savedVars[panelKey] or {}
            
            if panelConfig.controls then
                for _, controlConfig in ipairs(panelConfig.controls) do
                    local controlName = controlConfig.name
                    local controlDefault = controlConfig.default
                    
                    if controlName and controlDefault ~= nil and self.savedVars[panelKey][controlName] == nil then
                        self.savedVars[panelKey][controlName] = controlDefault
                    end
                end
            end
        end

        local returnValue = true
        callHook(self, "AfterInitializeDefaultSettings", returnValue)
        return returnValue
    end

    function addon:_InitializeSettingsPanel()
        callHook(self, "BeforeInitializeSettingsPanel")

        self:_ConfigureMainSettings()
        self:_InitializeDefaultSettings()

        self.settingsPanels = {}
        self.mainSettingsPanel = self:_BuildMainSettingsPanel()
        self.settingsCategory = Settings.RegisterCanvasLayoutCategory(self.mainSettingsPanel, self.addonName)
        Settings.RegisterAddOnCategory(self.settingsCategory)
        self.settingsPanels["main"] = self.mainSettingsPanel

        for _, panelKey in ipairs(self.sadCore.panelOrder) do
            local panelConfig = self.sadCore.panels[panelKey]
            local childPanel = self:_BuildChildSettingsPanel(panelKey)
            if childPanel then
                local categoryName = self:L(panelConfig.title or panelKey)
                Settings.RegisterCanvasLayoutSubcategory(self.settingsCategory, childPanel, categoryName)
                self.settingsPanels[panelKey] = childPanel
            end
        end

        local returnValue = true
        callHook(self, "AfterInitializeSettingsPanel", returnValue)
        return returnValue
    end

    function addon:_BuildSettingsPanelHelper(panelKey, config)
        panelKey, config = callHook(self, "BeforeBuildSettingsPanelHelper", panelKey, config)

        if not config then
            callHook(self, "AfterBuildSettingsPanelHelper", false)
            return false
        end

        local panel = self:_CreateSettingsPanel(panelKey)
        local titleText = panelKey == "main" and self.addonName or self:L(config.title)
        panel.Title:SetText(titleText)
        panel.controlRefreshers = {}

        local content = panel.ScrollFrame.Content
        local yOffset = self.sadCore.ui.spacing.panelTop

        if config.controls then
            for _, controlConfig in ipairs(config.controls) do
                local control, newYOffset = self:_AddControl(content, yOffset, panelKey, controlConfig)
                if control and control.refresh then
                    table.insert(panel.controlRefreshers, control.refresh)
                end
                yOffset = newYOffset
            end
        end

        content:SetHeight(math.abs(yOffset) + self.sadCore.ui.spacing.panelBottom)

        callHook(self, "AfterBuildSettingsPanelHelper", panel)
        return panel
    end

    function addon:_BuildMainSettingsPanel()
        callHook(self, "BeforeBuildMainSettingsPanel")

        local panel = self:_BuildSettingsPanelHelper("main", self.sadCore.panels.main)

        callHook(self, "AfterBuildMainSettingsPanel", panel)
        return panel
    end

    function addon:_BuildChildSettingsPanel(panelKey)
        panelKey = callHook(self, "BeforeBuildChildSettingsPanel", panelKey)

        local panel = self:_BuildSettingsPanelHelper(panelKey, self.sadCore.panels[panelKey])

        callHook(self, "AfterBuildChildSettingsPanel", panel)
        return panel
    end

    function addon:_CreateSettingsPanel(panelKey)
        panelKey = callHook(self, "BeforeCreateSettingsPanel", panelKey)

        local panel = CreateFrame("Frame", self.addonName .. "_" .. panelKey .. "_Panel")
        panel.panelKey = panelKey

        panel.Title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
        panel.Title:SetPoint("TOPLEFT", 7, -22)
        panel.Title:SetJustifyH("LEFT")
        panel.Title:SetTextColor(1, 1, 1)

        panel.HorizontalLine = panel:CreateTexture(nil, "ARTWORK")
        panel.HorizontalLine:SetSize(0, 1)
        panel.HorizontalLine:SetPoint("TOPLEFT", panel.Title, "BOTTOMLEFT", 0, -8)
        panel.HorizontalLine:SetPoint("TOPRIGHT", -30, -63)
        panel.HorizontalLine:SetColorTexture(0.25, 0.25, 0.25, 1)

        panel.ScrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        panel.ScrollFrame:SetPoint("TOPLEFT", 0, -28)
        panel.ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        panel.ScrollFrame.Content = CreateFrame("Frame", nil, panel.ScrollFrame)
        panel.ScrollFrame.Content:SetSize(600, 1)
        panel.ScrollFrame:SetScrollChild(panel.ScrollFrame.Content)

        panel:SetScript("OnShow", function(self)
            if self.controlRefreshers then
                for _, refreshFunc in ipairs(self.controlRefreshers) do
                    refreshFunc()
                end
            end
        end)

        callHook(self, "AfterCreateSettingsPanel", panel)
        return panel
    end
end

do -- Controls

    function addon:_AddHeader(parent, yOffset, panelKey, name)
        parent, yOffset, panelKey, name = callHook(self, "BeforeAddHeader", parent, yOffset, panelKey, name)

        local header = CreateFrame("Frame", nil, parent)
        header:SetHeight(50)
        header:SetPoint("TOPLEFT", self.sadCore.ui.spacing.contentLeft, yOffset)
        header:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.contentRight, yOffset)

        header.Title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        header.Title:SetPoint("BOTTOMLEFT", 7, 4)
        header.Title:SetJustifyH("LEFT")
        header.Title:SetJustifyV("BOTTOM")
        header.Title:SetText(self:L(name))

        local newYOffset = yOffset - self.sadCore.ui.spacing.headerHeight
        callHook(self, "AfterAddHeader", header, newYOffset)
        return header, newYOffset
    end

    function addon:_AddCheckbox(parent, yOffset, panelKey, name, defaultValue, onValueChange, skipRefresh, sessionOnly)
        local addonInstance = self
        parent, yOffset, panelKey, name, defaultValue, onValueChange, skipRefresh, sessionOnly = callHook(self,
            "BeforeAddCheckbox", parent, yOffset, panelKey, name, defaultValue, onValueChange, skipRefresh, sessionOnly)

        local getValue, setValue

        if sessionOnly == true then
            local tempValue = defaultValue
            getValue = function()
                return tempValue
            end
            setValue = function(value)
                tempValue = value
                if onValueChange then
                    onValueChange(addonInstance, value)
                end
            end
        elseif name == "core_useCharacterSettings" then
            getValue = function()
                return self.savedVarsChar.useCharacterSettings
            end
            setValue = function(value)
                self.savedVarsChar.useCharacterSettings = value
                if onValueChange then
                    onValueChange(addonInstance, value)
                end
            end
            if getValue() == nil then
                self.savedVarsChar.useCharacterSettings = defaultValue
            end
        else
            self.savedVars[panelKey] = self.savedVars[panelKey] or {}
            if self.savedVars[panelKey][name] == nil then
                self.savedVars[panelKey][name] = defaultValue
            end

            getValue = function()
                self.savedVars[panelKey] = self.savedVars[panelKey] or {}
                return self.savedVars[panelKey][name]
            end

            setValue = function(value)
                self.savedVars[panelKey] = self.savedVars[panelKey] or {}
                self.savedVars[panelKey][name] = value
                if onValueChange then
                    onValueChange(addonInstance, value)
                end
            end
        end

        local checkbox = CreateFrame("Frame", nil, parent)
        checkbox:SetHeight(32)
        checkbox:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        checkbox:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)

        checkbox.Text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        checkbox.Text:SetSize(205, 0)
        checkbox.Text:SetPoint("LEFT", 17, 0)
        checkbox.Text:SetJustifyH("LEFT")
        checkbox.Text:SetWordWrap(false)
        checkbox.Text:SetText(self:L(name))

        checkbox.CheckBox = CreateFrame("CheckButton", nil, checkbox)
        checkbox.CheckBox:SetSize(26, 26)
        checkbox.CheckBox:SetPoint("LEFT", 215, 0)
        checkbox.CheckBox:SetMotionScriptsWhileDisabled(true)
        checkbox.CheckBox:SetNormalAtlas("checkbox-minimal")
        checkbox.CheckBox:SetPushedAtlas("checkbox-minimal")
        checkbox.CheckBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        checkbox.CheckBox:GetCheckedTexture():SetAtlas("checkmark-minimal")
        checkbox.CheckBox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
        checkbox.CheckBox:GetDisabledCheckedTexture():SetAtlas("checkmark-minimal-disabled")

        local currentValue = getValue()
        if currentValue == nil then
            currentValue = defaultValue
        end
        checkbox.CheckBox:SetChecked(currentValue)

        if onValueChange then
            onValueChange(addonInstance, currentValue)
        end

        checkbox.CheckBox:SetScript("OnClick", function(checkboxFrame)
            setValue(checkboxFrame:GetChecked())
        end)

        if not skipRefresh then
            checkbox.refresh = function()
                local value = getValue()
                if value == nil then
                    value = defaultValue
                end
                checkbox.CheckBox:SetChecked(value)
            end
        end

        local tooltipKey = name .. "Tooltip"
        local tooltipText = addonInstance:L(tooltipKey)
        if tooltipText ~= "[" .. tooltipKey .. "]" then
            checkbox.CheckBox:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(addonInstance:L(name), 1, 1, 1)
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            checkbox.CheckBox:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        local newYOffset = yOffset - self.sadCore.ui.spacing.controlHeight
        callHook(self, "AfterAddCheckbox", checkbox, newYOffset)
        return checkbox, newYOffset
    end

    function addon:_AddDropdown(parent, yOffset, panelKey, name, defaultValue, options, onValueChange, skipRefresh,
        sessionOnly)
        local addonInstance = self
        parent, yOffset, panelKey, name, defaultValue, options, onValueChange, skipRefresh, sessionOnly = callHook(self,
            "BeforeAddDropdown", parent, yOffset, panelKey, name, defaultValue, options, onValueChange, skipRefresh,
            sessionOnly)

        local currentValue = defaultValue

        if sessionOnly ~= true then
            self.savedVars[panelKey] = self.savedVars[panelKey] or {}
            if self.savedVars[panelKey][name] == nil then
                self.savedVars[panelKey][name] = defaultValue
            end
            currentValue = self.savedVars[panelKey][name]
        end

        local dropdown = CreateFrame("Frame", nil, parent)
        dropdown:SetHeight(32)
        dropdown:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        dropdown:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)

        dropdown.Text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropdown.Text:SetSize(205, 0)
        dropdown.Text:SetPoint("LEFT", 17, 0)
        dropdown.Text:SetJustifyH("LEFT")
        dropdown.Text:SetWordWrap(false)
        dropdown.Text:SetText(self:L(name))

        dropdown.Dropdown = CreateFrame("Frame", nil, dropdown, "UIDropDownMenuTemplate")
        dropdown.Dropdown:SetPoint("LEFT", 200, 3)
        UIDropDownMenu_SetWidth(dropdown.Dropdown, self.sadCore.ui.dropdown.width)

        local initializeFunc = function(dropdownFrame, level)
            local savedValue = (sessionOnly ~= true) and addonInstance.savedVars[panelKey][name] or currentValue
            for _, option in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = addonInstance:L(option.label)
                info.value = option.value
                
                if option.icon then
                    info.icon = option.icon
                    
                    local atlasInfo = C_Texture.GetAtlasInfo(option.icon)
                    if atlasInfo then
                        info.iconInfo = {
                            tCoordLeft = atlasInfo.leftTexCoord,
                            tCoordRight = atlasInfo.rightTexCoord,
                            tCoordTop = atlasInfo.topTexCoord,
                            tCoordBottom = atlasInfo.bottomTexCoord,
                            tSizeX = atlasInfo.width,
                            tSizeY = atlasInfo.height,
                            tFitDropDownSizeX = false  -- Don't stretch to fit
                        }
                    else
                        info.iconInfo = {
                            tCoordLeft = 0,
                            tCoordRight = 1,
                            tCoordTop = 0,
                            tCoordBottom = 1,
                            tSizeX = 16,
                            tSizeY = 16,
                            tFitDropDownSizeX = false
                        }
                    end
                end
                
                info.func = function(self)
                    if sessionOnly ~= true then
                        addonInstance.savedVars[panelKey][name] = self.value
                    else
                        currentValue = self.value
                    end
                    UIDropDownMenu_SetSelectedValue(dropdown.Dropdown, self.value)
                    UIDropDownMenu_Initialize(dropdown.Dropdown, initializeFunc)
                    if onValueChange then
                        onValueChange(addonInstance, self.value)
                    end
                end
                info.checked = (savedValue == option.value)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(dropdown.Dropdown, initializeFunc)
        UIDropDownMenu_SetSelectedValue(dropdown.Dropdown, currentValue or defaultValue)
        
        local selectedValue = currentValue or defaultValue
        for _, option in ipairs(options) do
            if option.value == selectedValue then
                UIDropDownMenu_SetText(dropdown.Dropdown, addonInstance:L(option.label))
                break
            end
        end

        if onValueChange then
            onValueChange(addonInstance, currentValue or defaultValue)
        end

        if not skipRefresh and sessionOnly ~= true then
            dropdown.refresh = function()
                addonInstance.savedVars[panelKey] = addonInstance.savedVars[panelKey] or {}
                local value = addonInstance.savedVars[panelKey][name]
                if value == nil then
                    value = defaultValue
                end
                UIDropDownMenu_SetSelectedValue(dropdown.Dropdown, value)
                
                for _, option in ipairs(options) do
                    if option.value == value then
                        UIDropDownMenu_SetText(dropdown.Dropdown, addonInstance:L(option.label))
                        break
                    end
                end
            end
        end

        local tooltipKey = name .. "Tooltip"
        local tooltipText = addonInstance:L(tooltipKey)
        if tooltipText ~= "[" .. tooltipKey .. "]" then
            dropdown.Dropdown:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(addonInstance:L(name), 1, 1, 1)
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            dropdown.Dropdown:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        local newYOffset = yOffset - self.sadCore.ui.spacing.controlHeight
        callHook(self, "AfterAddDropdown", dropdown, newYOffset)
        return dropdown, newYOffset
    end

    function addon:_AddSlider(parent, yOffset, panelKey, name, defaultValue, minValue, maxValue, step, onValueChange,
        skipRefresh, sessionOnly)
        local addonInstance = self
        parent, yOffset, panelKey, name, defaultValue, minValue, maxValue, step, onValueChange, skipRefresh, sessionOnly =
            callHook(self, "BeforeAddSlider", parent, yOffset, panelKey, name, defaultValue, minValue, maxValue, step,
                onValueChange, skipRefresh, sessionOnly)

        local currentValue = defaultValue

        if sessionOnly ~= true then
            self.savedVars[panelKey] = self.savedVars[panelKey] or {}
            if self.savedVars[panelKey][name] == nil then
                self.savedVars[panelKey][name] = defaultValue
            end
            currentValue = self.savedVars[panelKey][name]
        end

        local slider = CreateFrame("Frame", nil, parent)
        slider:SetHeight(32)
        slider:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        slider:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)

        slider.Text = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slider.Text:SetSize(205, 0)
        slider.Text:SetPoint("LEFT", 17, 0)
        slider.Text:SetJustifyH("LEFT")
        slider.Text:SetWordWrap(false)
        slider.Text:SetText(self:L(name))

        slider.Value = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slider.Value:SetPoint("LEFT", 430, 0)
        slider.Value:SetJustifyH("LEFT")

        slider.Slider = CreateFrame("Slider", nil, slider, "MinimalSliderWithSteppersTemplate")
        slider.Slider:SetSize(205, 22)
        slider.Slider:SetPoint("LEFT", 215, 0)

        local steps = (maxValue - minValue) / step
        slider.Slider:Init(currentValue or defaultValue, minValue, maxValue, steps)
        slider.Slider:SetWidth(self.sadCore.ui.slider.width)

        local function updateValue(value)
            if value == 0 then
                value = 0
            end
            slider.Value:SetText(string.format("%.0f", value))
        end
        updateValue(currentValue or defaultValue)

        if onValueChange then
            onValueChange(addonInstance, currentValue or defaultValue)
        end

        slider.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            if sessionOnly ~= true then
                addonInstance.savedVars[panelKey][name] = value
            else
                currentValue = value
            end
            updateValue(value)
            if onValueChange then
                onValueChange(addonInstance, value)
            end
        end)

        if not skipRefresh and sessionOnly ~= true then
            slider.refresh = function()
                addonInstance.savedVars[panelKey] = addonInstance.savedVars[panelKey] or {}
                local value = addonInstance.savedVars[panelKey][name]
                if value == nil then
                    value = defaultValue
                end
                slider.Slider:SetValue(value)
                updateValue(value)
            end
        end

        local tooltipKey = name .. "Tooltip"
        local tooltipText = addonInstance:L(tooltipKey)
        if tooltipText ~= "[" .. tooltipKey .. "]" then
            slider.Slider:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(addonInstance:L(name), 1, 1, 1)
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            slider.Slider:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        local newYOffset = yOffset - self.sadCore.ui.spacing.controlHeight
        callHook(self, "AfterAddSlider", slider, newYOffset)
        return slider, newYOffset
    end

    function addon:_AddButton(parent, yOffset, panelKey, name, onClick)
        local addonInstance = self
        parent, yOffset, panelKey, name, onClick = callHook(self, "BeforeAddButton", parent, yOffset, panelKey, name,
            onClick)

        local button = CreateFrame("Frame", nil, parent)
        button:SetHeight(40)
        button:SetPoint("TOPLEFT", self.sadCore.ui.spacing.contentLeft, yOffset)
        button:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.contentRight, yOffset)

        button.Button = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
        button.Button:SetSize(120, 22)
        button.Button:SetPoint("LEFT", 35, 0)
        button.Button:SetText(self:L(name))

        button.Button:SetScript("OnClick", function(self)
            if onClick then
                onClick(addonInstance)
            end
        end)

        local tooltipKey = name .. "Tooltip"
        local tooltipText = addonInstance:L(tooltipKey)
        if tooltipText ~= "[" .. tooltipKey .. "]" then
            button.Button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(addonInstance:L(name), 1, 1, 1)
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            button.Button:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        local newYOffset = yOffset - self.sadCore.ui.spacing.buttonHeight
        callHook(self, "AfterAddButton", button, newYOffset)
        return button, newYOffset
    end

    function addon:_AddColorPicker(parent, yOffset, panelKey, name, defaultValue, onValueChange, skipRefresh, sessionOnly)
        local addonInstance = self
        parent, yOffset, panelKey, name, defaultValue, onValueChange, skipRefresh, sessionOnly = callHook(self,
            "BeforeAddColorPicker", parent, yOffset, panelKey, name, defaultValue, onValueChange, skipRefresh,
            sessionOnly)

        local currentValue = defaultValue

        if sessionOnly ~= true then
            self.savedVars[panelKey] = self.savedVars[panelKey] or {}
            if self.savedVars[panelKey][name] == nil then
                self.savedVars[panelKey][name] = defaultValue
            end
            currentValue = self.savedVars[panelKey][name]
        end

        local colorPicker = CreateFrame("Frame", nil, parent)
        colorPicker:SetHeight(32)
        colorPicker:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        colorPicker:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)

        colorPicker.Text = colorPicker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        colorPicker.Text:SetSize(205, 0)
        colorPicker.Text:SetPoint("LEFT", 17, 0)
        colorPicker.Text:SetJustifyH("LEFT")
        colorPicker.Text:SetWordWrap(false)
        colorPicker.Text:SetText(self:L(name))

        colorPicker.ColorSwatch = CreateFrame("Button", nil, colorPicker)
        colorPicker.ColorSwatch:SetSize(26, 26)
        colorPicker.ColorSwatch:SetPoint("LEFT", 215, 0)

        colorPicker.ColorSwatch.Background = colorPicker.ColorSwatch:CreateTexture(nil, "BACKGROUND")
        colorPicker.ColorSwatch.Background:SetColorTexture(1, 1, 1, 1)
        colorPicker.ColorSwatch.Background:SetAllPoints()

        colorPicker.ColorSwatch.Color = colorPicker.ColorSwatch:CreateTexture(nil, "ARTWORK")
        local hexValue = currentValue or defaultValue
        local r, g, b, a = self:HexToRGB(hexValue)
        colorPicker.ColorSwatch.Color:SetColorTexture(r, g, b, a)
        colorPicker.ColorSwatch.Color:SetPoint("TOPLEFT", 2, -2)
        colorPicker.ColorSwatch.Color:SetPoint("BOTTOMRIGHT", -2, 2)

        colorPicker.ColorSwatch.Border = colorPicker.ColorSwatch:CreateTexture(nil, "BORDER")
        colorPicker.ColorSwatch.Border:SetColorTexture(0, 0, 0, 1)
        colorPicker.ColorSwatch.Border:SetAllPoints()
        colorPicker.ColorSwatch.Border:SetDrawLayer("BORDER", 0)

        local function updateColor(hexColor)
            local r, g, b, a = self:HexToRGB(hexColor)
            colorPicker.ColorSwatch.Color:SetColorTexture(r, g, b, a)
            if sessionOnly ~= true then
                self.savedVars[panelKey][name] = hexColor
            else
                currentValue = hexColor
            end
            if onValueChange then
                onValueChange(addonInstance, hexColor)
            end
        end

        if onValueChange then
            onValueChange(addonInstance, currentValue or defaultValue)
        end

        colorPicker.ColorSwatch:SetScript("OnClick", function(self)
            local r, g, b, a = addonInstance:HexToRGB((sessionOnly ~= true) and addonInstance.savedVars[panelKey][name] or
                                                          currentValue or defaultValue)

            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function()
                    local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    local newA = ColorPickerFrame:GetColorAlpha()
                    local hexColor = addonInstance:RgbToHex(newR, newG, newB, newA)
                    updateColor(hexColor)
                end,
                cancelFunc = function()
                    updateColor(addonInstance:RgbToHex(r, g, b, a))
                end,
                opacityFunc = function()
                    local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    local newA = ColorPickerFrame:GetColorAlpha()
                    local hexColor = addonInstance:RgbToHex(newR, newG, newB, newA)
                    updateColor(hexColor)
                end,
                r = r,
                g = g,
                b = b,
                opacity = a,
                hasOpacity = true
            })
        end)

        if not skipRefresh and sessionOnly ~= true then
            colorPicker.refresh = function()
                self.savedVars[panelKey] = self.savedVars[panelKey] or {}
                local value = self.savedVars[panelKey][name]
                if value == nil then
                    value = defaultValue
                end
                local r, g, b, a = self:HexToRGB(value)
                colorPicker.ColorSwatch.Color:SetColorTexture(r, g, b, a)
            end
        end

        local tooltipKey = name .. "Tooltip"
        local tooltipText = self:L(tooltipKey)
        if tooltipText ~= "[" .. tooltipKey .. "]" then
            colorPicker.ColorSwatch:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(addonInstance:L(name), 1, 1, 1)
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            colorPicker.ColorSwatch:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        local newYOffset = yOffset - self.sadCore.ui.spacing.controlHeight
        callHook(self, "AfterAddColorPicker", colorPicker, newYOffset)
        return colorPicker, newYOffset
    end

    function addon:_AddDescription(parent, yOffset, panelKey, name, onClick)
        local addonInstance = self
        parent, yOffset, panelKey, name, onClick = callHook(self, "BeforeAddDescription", parent, yOffset, panelKey,
            name, onClick)

        local frame = CreateFrame("Frame", nil, parent)
        frame:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        frame:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)
        frame:SetHeight(32)

        local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontString:SetPoint("LEFT", self.sadCore.ui.spacing.textInset, 0)
        fontString:SetPoint("RIGHT", -self.sadCore.ui.spacing.textInset, 0)
        fontString:SetJustifyH("LEFT")
        fontString:SetJustifyV("TOP")
        fontString:SetWordWrap(true)
        fontString:SetText(self:L(name))
        fontString:SetTextColor(1, 1, 1, 1)

        local stringHeight = fontString:GetStringHeight()
        frame:SetHeight(math.max(32, stringHeight))

        if onClick then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseDown", function(self)
                onClick(addonInstance)
            end)
            frame:SetScript("OnEnter", function(self)
                fontString:SetTextColor(1, 0.82, 0, 1)
            end)
            frame:SetScript("OnLeave", function(self)
                fontString:SetTextColor(1, 1, 1, 1)
            end)
        end

        local newYOffset = yOffset - math.max(32, stringHeight) - self.sadCore.ui.spacing.descriptionPadding
        callHook(self, "AfterAddDescription", frame, newYOffset)
        return frame, newYOffset
    end

    function addon:_AddDivider(parent, yOffset, panelKey)
        parent, yOffset, panelKey = callHook(self, "BeforeAddDivider", parent, yOffset, panelKey)

        paddingTop = 0
        paddingBottom = 20
        local totalHeight = paddingTop + paddingBottom

        local frame = CreateFrame("Frame", nil, parent)
        frame:SetHeight(totalHeight)
        frame:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        frame:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)

        frame.Line = frame:CreateTexture(nil, "ARTWORK")
        frame.Line:SetHeight(1)
        frame.Line:SetPoint("LEFT", 10, -paddingTop)
        frame.Line:SetPoint("RIGHT", -10, -paddingTop)
        frame.Line:SetColorTexture(0, 0, 0, 0.25)

        local newYOffset = yOffset - totalHeight
        callHook(self, "AfterAddDivider", frame, newYOffset)
        return frame, newYOffset
    end

    function addon:_AddInputBox(parent, yOffset, panelKey, name, default, highlightText, buttonText, onClick,
        onValueChange, sessionOnly)
        local addonInstance = self
        parent, yOffset, panelKey, name, default, highlightText, buttonText, onClick, onValueChange, sessionOnly =
            callHook(self, "BeforeAddInputBox", parent, yOffset, panelKey, name, default, highlightText, buttonText,
                onClick, onValueChange, sessionOnly)

        local control = CreateFrame("Frame", nil, parent)
        control:SetHeight(32)
        control:SetPoint("TOPLEFT", self.sadCore.ui.spacing.controlLeft, yOffset)
        control:SetPoint("TOPRIGHT", self.sadCore.ui.spacing.controlRight, yOffset)

        control.Text = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        control.Text:SetSize(205, 0)
        control.Text:SetPoint("LEFT", 17, 0)
        control.Text:SetJustifyH("LEFT")
        control.Text:SetWordWrap(false)
        control.Text:SetText(self:L(name))

        control.EditBox = CreateFrame("EditBox", nil, control)
        control.EditBox:SetSize(220, 22)
        control.EditBox:SetPoint("LEFT", 218, 0)
        control.EditBox:SetAutoFocus(false)
        control.EditBox:SetFontObject("ChatFontNormal")

        control.EditBox.Background = control.EditBox:CreateTexture(nil, "BACKGROUND")
        control.EditBox.Background:SetAllPoints(control.EditBox)
        control.EditBox.Background:SetColorTexture(0, 0, 0, 0.5)

        control.Button = CreateFrame("Button", nil, control, "UIPanelButtonTemplate")
        control.Button:SetSize(60, 22)
        control.Button:SetPoint("LEFT", control.EditBox, "RIGHT", 8, 0)

        local shouldPersist = sessionOnly ~= true

        if shouldPersist then
            self.savedVars[panelKey] = self.savedVars[panelKey] or {}
            if self.savedVars[panelKey][name] == nil then
                self.savedVars[panelKey][name] = default
            end

            control.EditBox:SetScript("OnTextChanged", function(self, userInput)
                if userInput then
                    local newValue = self:GetText()
                    addonInstance.savedVars[panelKey][name] = newValue
                    if onValueChange then
                        onValueChange(addonInstance, newValue)
                    end
                end
            end)
        else
            control.EditBox:SetScript("OnTextChanged", function(self, userInput)
                if userInput then
                    local newValue = self:GetText()
                    if onValueChange then
                        onValueChange(addonInstance, newValue)
                    end
                end
            end)
        end

        if buttonText then
            control.Button:SetText(buttonText)

            if onClick then
                control.Button:SetScript("OnClick", function(self)
                    local inputText = control.EditBox:GetText()
                    onClick(addonInstance, inputText, control.EditBox)
                end)
            end

            local tooltipKey = name .. "Tooltip"
            local tooltipText = addonInstance:L(tooltipKey)
            if tooltipText ~= "[" .. tooltipKey .. "]" then
                control.Button:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(buttonText, 1, 1, 1)
                    GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                    GameTooltip:Show()
                end)
                control.Button:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
            end
        else
            control.Button:Hide()
        end

        control.EditBox.Background:SetAllPoints(control.EditBox)
        control.EditBox:SetFontObject(GameFontHighlight)
        control.EditBox:SetTextColor(1, 1, 1, 1)
        control.EditBox:SetTextInsets(5, 5, 0, 0)
        control.EditBox:SetMultiLine(false)
        control.EditBox:SetAutoFocus(false)
        control.EditBox:Show()
        control.EditBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        control.EditBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)

        control.EditBox:SetScript("OnShow", function(self)
            if shouldPersist then
                local savedValue = addonInstance.savedVars[panelKey][name]
                if savedValue and self:GetText() == "" then
                    self:SetText(savedValue)
                    self:SetCursorPosition(0)
                end
            end
            if highlightText then
                self:HighlightText()
            end
        end)

        if shouldPersist then
            local initialValue = self.savedVars[panelKey][name] or default
            if initialValue then
                control.EditBox:SetText(initialValue)
                control.EditBox:SetCursorPosition(0)
            end

            if onValueChange then
                onValueChange(addonInstance, initialValue)
            end

            control.refresh = function()
                local value = addonInstance.savedVars[panelKey][name] or default
                if value then
                    control.EditBox:SetText(value)
                    control.EditBox:SetCursorPosition(0)
                end
            end
        else
            if default then
                control.EditBox:SetText(default)
                control.EditBox:SetCursorPosition(0)
            end
        end

        local newYOffset = yOffset - self.sadCore.ui.spacing.controlHeight
        callHook(self, "AfterAddInputBox", control, newYOffset)
        return control, newYOffset
    end

    function addon:_ShowDialog(dialogOptions)
        local addonInstance = self
        dialogOptions = callHook(self, "BeforeShowDialog", dialogOptions)

        self:Debug("ShowDialog called")
        local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

        local uiCfg = self.sadCore.ui
        local width = dialogOptions.width or uiCfg.dialog.defaultWidth
        dialog:SetWidth(width)
        dialog:SetPoint("CENTER")
        dialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = uiCfg.backdrop.edgeSize,
            insets = uiCfg.backdrop.insets
        })
        dialog:SetBackdropColor(0, 0, 0, 1)
        dialog:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        dialog:SetFrameStrata("DIALOG")
        dialog:EnableMouse(true)

        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, uiCfg.dialog.titleOffset)
        title:SetText(self:L(dialogOptions.title))

        local content = CreateFrame("Frame", nil, dialog)
        content:SetPoint("TOPLEFT", uiCfg.spacing.contentLeft, uiCfg.dialog.contentTop)
        content:SetPoint("BOTTOMRIGHT", uiCfg.spacing.contentRight, uiCfg.dialog.contentBottom)

        local yOffset = uiCfg.dialog.initialYOffset
        local inputBoxControls = {}
        if dialogOptions.controls then
            for _, controlConfig in ipairs(dialogOptions.controls) do
                local control, newYOffset = self:_AddControl(content, yOffset, "dialog", controlConfig)
                if controlConfig.type == "inputBox" and controlConfig.highlightText and control then
                    table.insert(inputBoxControls, control)
                end
                yOffset = newYOffset
            end
        end

        local contentHeight = math.abs(yOffset) + uiCfg.dialog.contentPadding
        local calculatedHeight = uiCfg.dialog.titleHeight + contentHeight + uiCfg.dialog.buttonHeight

        local height = dialogOptions.height or calculatedHeight
        dialog:SetHeight(height)

        local closeButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        closeButton:SetSize(uiCfg.dialog.buttonSize.width, uiCfg.dialog.buttonSize.height)
        closeButton:SetPoint("BOTTOM", 0, uiCfg.dialog.buttonOffset)
        closeButton:SetText(self:L("core_close"))
        closeButton:SetScript("OnClick", function()
            dialog:Hide()
            if dialogOptions.onClose then
                dialogOptions.onClose()
            end
        end)

        dialog:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                closeButton:Click()
            end
        end)

        dialog:Show()

        if #inputBoxControls > 0 then
            local firstControl = inputBoxControls[1]
            if firstControl.EditBox then
                C_Timer.After(0, function()
                    firstControl.EditBox:SetFocus()
                    firstControl.EditBox:HighlightText()
                end)
            end
        end

        callHook(self, "AfterShowDialog", dialog)
        return dialog
    end

    function addon:_AddControl(parent, yOffset, panelKey, controlConfig)
        parent, yOffset, panelKey, controlConfig = callHook(self, "BeforeAddControl", parent, yOffset, panelKey,
            controlConfig)

        local controlType = controlConfig.type

        if controlType == "header" then
            local control, newYOffset = self:_AddHeader(parent, yOffset, panelKey, controlConfig.name)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "checkbox" then
            local control, newYOffset = self:_AddCheckbox(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.default, controlConfig.onValueChange, controlConfig.skipRefresh, controlConfig.sessionOnly)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "dropdown" then
            local control, newYOffset = self:_AddDropdown(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.default, controlConfig.options, controlConfig.onValueChange, controlConfig.skipRefresh,
                controlConfig.sessionOnly)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "slider" then
            local control, newYOffset = self:_AddSlider(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.default, controlConfig.min, controlConfig.max, controlConfig.step,
                controlConfig.onValueChange, controlConfig.skipRefresh, controlConfig.sessionOnly)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "button" then
            local control, newYOffset = self:_AddButton(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.onClick)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "description" then
            local control, newYOffset = self:_AddDescription(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.onClick)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "inputBox" then
            local buttonText = controlConfig.buttonText and self:L(controlConfig.buttonText) or nil
            local control, newYOffset = self:_AddInputBox(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.default, controlConfig.highlightText, buttonText, controlConfig.onClick,
                controlConfig.onValueChange, controlConfig.sessionOnly)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "colorPicker" then
            local control, newYOffset = self:_AddColorPicker(parent, yOffset, panelKey, controlConfig.name,
                controlConfig.default, controlConfig.onValueChange, controlConfig.skipRefresh, controlConfig.sessionOnly)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        elseif controlType == "divider" then
            local control, newYOffset = self:_AddDivider(parent, yOffset, panelKey)
            callHook(self, "AfterAddControl", control, newYOffset)
            return control, newYOffset

        else
            self:Debug("Unknown control type: " .. tostring(controlType))
            callHook(self, "AfterAddControl", false, yOffset)
            return false, yOffset
        end
    end
end

do -- Utility Functions

    function addon:Retry(func, initialWait)
        func, initialWait = callHook(self, "BeforeRetry", func, initialWait)

        if type(func) ~= "function" then
            self:Error(self:L("core_retryRequiresFunction"))
            callHook(self, "AfterRetry", false)
            return false
        end

        local addonInstance = self
        local retryDelay = self.sadCore.config.retryDelay or 0.1
        local retryMaxAttempts = self.sadCore.config.retryMaxAttempts or 50
        local currentAttempt = 0

        local function attemptExecution()
            currentAttempt = currentAttempt + 1
            
            local success, result = pcall(func, addonInstance)
            
            if not success then
                addonInstance:Debug("Retry attempt " .. currentAttempt .. " failed with error: " .. tostring(result))
                if currentAttempt < retryMaxAttempts then
                    C_Timer.After(retryDelay, attemptExecution)
                else
                    addonInstance:Debug("Retry max attempts (" .. retryMaxAttempts .. ") reached")
                    callHook(addonInstance, "AfterRetry", false)
                end
                return
            end

            if result == true then
                addonInstance:Debug("Retry succeeded on attempt " .. currentAttempt)
                callHook(addonInstance, "AfterRetry", true)
                return
            end

            if currentAttempt < retryMaxAttempts then
                addonInstance:Debug("Retry attempt " .. currentAttempt .. " returned " .. tostring(result) .. ", retrying...")
                C_Timer.After(retryDelay, attemptExecution)
            else
                addonInstance:Debug("Retry max attempts (" .. retryMaxAttempts .. ") reached without success")
                callHook(addonInstance, "AfterRetry", false)
            end
        end

        if initialWait and type(initialWait) == "number" and initialWait > 0 then
            C_Timer.After(initialWait, attemptExecution)
        else
            attemptExecution()
        end

        callHook(self, "AfterRetry", true)
        return true
    end

    function addon:GetValue(panel, settingName)
        panel, settingName = callHook(self, "BeforeGetValue", panel, settingName)

        if not panel or not settingName then
            callHook(self, "AfterGetValue", nil)
            return nil
        end

        local savedValue = nil
        if self.savedVars and self.savedVars[panel] then
            savedValue = self.savedVars[panel][settingName]
        end

        local controlConfig = nil
        if self.sadCore and self.sadCore.panels and self.sadCore.panels[panel] then
            local panelConfig = self.sadCore.panels[panel]
            if panelConfig.controls then
                for _, control in ipairs(panelConfig.controls) do
                    if control.name == settingName then
                        controlConfig = control
                        break
                    end
                end
            end
        end

        if not controlConfig then
            callHook(self, "AfterGetValue", savedValue)
            return savedValue
        end

        local defaultValue = controlConfig.default
        local controlType = controlConfig.type

        if controlType == "checkbox" then
            if type(savedValue) == "boolean" then
                callHook(self, "AfterGetValue", savedValue)
                return savedValue
            elseif type(defaultValue) == "boolean" then
                callHook(self, "AfterGetValue", defaultValue)
                return defaultValue
            else
                callHook(self, "AfterGetValue", nil)
                return nil
            end

        elseif controlType == "dropdown" then
            if controlConfig.options and type(controlConfig.options) == "table" then
                if savedValue ~= nil then
                    for _, option in ipairs(controlConfig.options) do
                        if option.value == savedValue then
                            callHook(self, "AfterGetValue", savedValue)
                            return savedValue
                        end
                    end
                end
                if defaultValue ~= nil then
                    for _, option in ipairs(controlConfig.options) do
                        if option.value == defaultValue then
                            callHook(self, "AfterGetValue", defaultValue)
                            return defaultValue
                        end
                    end
                end
            end
            callHook(self, "AfterGetValue", nil)
            return nil

        elseif controlType == "slider" then
            local minValue = controlConfig.min
            local maxValue = controlConfig.max
            
            if type(savedValue) == "number" and minValue and maxValue then
                local clampedValue = math.max(minValue, math.min(maxValue, savedValue))
                callHook(self, "AfterGetValue", clampedValue)
                return clampedValue
            elseif type(defaultValue) == "number" and minValue and maxValue then
                local clampedDefault = math.max(minValue, math.min(maxValue, defaultValue))
                callHook(self, "AfterGetValue", clampedDefault)
                return clampedDefault
            else
                callHook(self, "AfterGetValue", nil)
                return nil
            end

        elseif controlType == "colorPicker" then
            if type(savedValue) == "string" and savedValue:match("^#%x%x%x%x%x%x%x?%x?$") then
                callHook(self, "AfterGetValue", savedValue)
                return savedValue
            elseif type(defaultValue) == "string" and defaultValue:match("^#%x%x%x%x%x%x%x?%x?$") then
                callHook(self, "AfterGetValue", defaultValue)
                return defaultValue
            else
                callHook(self, "AfterGetValue", nil)
                return nil
            end

        elseif controlType == "inputBox" then
            if type(savedValue) == "string" then
                callHook(self, "AfterGetValue", savedValue)
                return savedValue
            elseif savedValue == nil and defaultValue ~= nil then
                callHook(self, "AfterGetValue", defaultValue)
                return defaultValue
            else
                callHook(self, "AfterGetValue", nil)
                return nil
            end

        else
            if savedValue ~= nil then
                callHook(self, "AfterGetValue", savedValue)
                return savedValue
            else
                callHook(self, "AfterGetValue", defaultValue)
                return defaultValue
            end
        end
    end

    function addon:SetValue(panel, settingName, value)
        panel, settingName, value = callHook(self, "BeforeSetValue", panel, settingName, value)

        if not panel or not settingName then
            callHook(self, "AfterSetValue", false)
            return false
        end

        self.savedVars = self.savedVars or {}
        self.savedVars[panel] = self.savedVars[panel] or {}
        self.savedVars[panel][settingName] = value

        self:_RefreshSettingsPanels()

        callHook(self, "AfterSetValue", true)
        return true
    end

    function addon:HexToRGB(hex)
        hex = hex:gsub("#", "")
        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        local a = 1
        if #hex == 8 then
            a = tonumber(hex:sub(7, 8), 16) / 255
        end
        return r, g, b, a
    end

    function addon:RgbToHex(r, g, b, a)
        r = math.floor(r * 255 + 0.5)
        g = math.floor(g * 255 + 0.5)
        b = math.floor(b * 255 + 0.5)
        if a then
            a = math.floor(a * 255 + 0.5)
            return string.format("#%02X%02X%02X%02X", r, g, b, a)
        end
        return string.format("#%02X%02X%02X", r, g, b)
    end

    function addon:OpenSettings()
        callHook(self, "BeforeOpenSettings")

        if InCombatLockdown() then
            self:Error(self:L("core_cannotOpenInCombat"))
            callHook(self, "AfterOpenSettings", false)
            return false
        end

        if type(Settings) == "table" and type(Settings.OpenToCategory) == "function" then
            if self.settingsCategory and self.settingsCategory.ID then
                Settings.OpenToCategory(self.settingsCategory.ID)
            end
        end

        local returnValue = true
        callHook(self, "AfterOpenSettings", returnValue)
        return returnValue
    end

    function addon:L(key)
        key = callHook(self, "BeforeL", key)

        if not key then
            callHook(self, "AfterL", "")
            return ""
        end

        key = key:gsub(" ", "_")
        key = key:gsub("[^%w_]", "")

        if key == "author" then
            callHook(self, "AfterL", self.author)
            return self.author
        end
        if not self.localization then
            local returnValue = "[" .. key .. "]"
            callHook(self, "AfterL", returnValue)
            return returnValue
        end
        local result = self.localization[key] or ("[" .. key .. "]")
        callHook(self, "AfterL", result)
        return result
    end

    function addon:_coreInfo(text)
        print("\124cffDB09FE" .. "SAdCore" .. ": " .. "\124cffBAFF1A" .. tostring(text))
    end

    function addon:_coreDebug(text)
        if self.savedVars and self.savedVars.main and self.savedVars.main.core_enableDebugging then
            print("\124cffDB09FE" .. "SAdCore" .. " Debug: " .. "\124cffBAFF1A" .. tostring(text))
        end
    end

    function addon:Info(text)
        text = callHook(self, "BeforeInfo", text)

        print("\124cffDB09FE" .. self.addonName .. ": " .. "\124cffBAFF1A" .. tostring(text))

        local returnValue = true
        callHook(self, "AfterInfo", returnValue)
        return returnValue
    end

    function addon:Error(text)
        text = callHook(self, "BeforeError", text)

        print("\124cffDB09FE" .. self.addonName .. ": " .. "\124cffBAFF1A" .. tostring(text))

        local returnValue = true
        callHook(self, "AfterError", returnValue)
        return returnValue
    end

    function addon:Debug(text)
        text = callHook(self, "BeforeDebug", text)

        if self.savedVars and self.savedVars.main and self.savedVars.main.core_enableDebugging then
            print("\124cffDB09FE" .. self.addonName .. " Debug: " .. "\124cffBAFF1A" .. tostring(text))
        end

        local returnValue = true
        callHook(self, "AfterDebug", returnValue)
        return returnValue
    end

    function addon:Dump(value, name)
        value, name = callHook(self, "BeforeDump", value, name)
        
        DevTools_Dump(value, name or self.addonName)
        
        local returnValue = true
        callHook(self, "AfterDump", returnValue)
        return returnValue
    end

    function addon:_RefreshSettingsPanels()
        callHook(self, "BeforeRefreshSettingsPanels")

        if self.settingsPanels then
            for panelKey, panel in pairs(self.settingsPanels) do
                if panel and panel.controlRefreshers then
                    for _, refreshFunc in ipairs(panel.controlRefreshers) do
                        refreshFunc()
                    end
                end
            end
        end

        local returnValue = true
        callHook(self, "AfterRefreshSettingsPanels", returnValue)
        return returnValue
    end

    function addon:_UpdateActiveSettings(useCharacter)
        useCharacter = callHook(self, "BeforeUpdateActiveSettings", useCharacter)
        self:Debug("UpdateActiveSettings called with: " .. tostring(useCharacter) .. " (type: " .. type(useCharacter) ..
                       ")")
        self:Debug("savedVarsChar exists: " .. tostring(self.savedVarsChar ~= nil) .. ", savedVarsGlobal exists: " ..
                       tostring(self.savedVarsGlobal ~= nil))

        self.savedVars = useCharacter and self.savedVarsChar or self.savedVarsGlobal

        local profileType = useCharacter and "Character" or "Global"
        self:Debug("Profile switched to: " .. profileType)
        self:_RefreshSettingsPanels()

        local returnValue = true
        callHook(self, "AfterUpdateActiveSettings", returnValue)
        return returnValue
    end

    function addon:_ExportSettings()
        callHook(self, "BeforeExportSettings")

        local exportData = self.savedVars

        local LibSerialize = self.LibSerialize
        local LibCompress = self.LibCompress
        local success, serialized = pcall(function()
            return LibSerialize:Serialize(exportData)
        end)
        if not success or not serialized then
            self:Debug("Serialize failed.")
            callHook(self, "AfterExportSettings", false)
            return false
        end
        local encoded = LibCompress:Encode(serialized)
        if not encoded then
            self:Debug("Encode failed.")
            callHook(self, "AfterExportSettings", false)
            return false
        end

        self:Debug(encoded)

        self:_ShowDialog({
            title = "core_shareSettingsTitle",
            controls = {{
                type = "inputBox",
                name = "core_shareSettingsLabel",
                default = encoded,
                highlightText = true
            }}
        })

        callHook(self, "AfterExportSettings", encoded)
        return encoded
    end

    function addon:_ImportSettings(serializedString)
        serializedString = callHook(self, "BeforeImportSettings", serializedString)

        if not serializedString or serializedString == "" then
            self:error(self:L("importStringEmpty"))
            callHook(self, "AfterImportSettings", false)
            return false
        end

        serializedString = serializedString:match("^%s*(.-)%s*$")
        self:Debug("Import string length after trim: " .. #serializedString)

        local LibSerialize = self.LibSerialize
        local LibCompress = self.LibCompress

        self:Debug("Decoding import string...")
        local decoded = LibCompress:Decode(serializedString)
        if not decoded then
            self:Error(self:L("core_importDecodeFailed"))
            self:Debug("Decode returned nil - invalid base64 string")
            callHook(self, "AfterImportSettings", false)
            return false
        end
        self:Debug("Decode successful. Decoded length: " .. #decoded)

        self:Debug("Deserializing...")
        local data, err = LibSerialize:Deserialize(decoded)
        if not data then
            self:Error(self:L("core_importDeserializeFailed") .. ": " .. tostring(err))
            self:Debug("Deserialization failed. Error: " .. tostring(err))
            callHook(self, "AfterImportSettings", false)
            return false
        end
        self:Debug("Deserialization successful")

        if type(data) ~= "table" then
            self:Error(self:L("core_importInvalidData"))
            self:Debug("Data is not a table. Type: " .. type(data))
            callHook(self, "AfterImportSettings", false)
            return false
        end

        self:Debug("Data is a table, checking contents...")

        if type(data) ~= "table" then
            self:Error(self:L("core_importInvalidData"))
            self:Debug("data is not a table. Type: " .. type(data))
            callHook(self, "AfterImportSettings", false)
            return false
        end

        self:Debug("Clearing current settings and importing...")
        for key in pairs(self.savedVars) do
            self.savedVars[key] = nil
        end

        for key, value in pairs(data) do
            self.savedVars[key] = value
        end

        self:Info(self:L("core_importSuccess"))
        self:_RefreshSettingsPanels()

        callHook(self, "AfterImportSettings", true)
        return true
    end

end

do -- Release Notes

    function addon:_InitializeReleaseNotes()
        callHook(self, "BeforeInitializeReleaseNotes")

        if not self.sadCore.releaseNotes then
            callHook(self, "AfterInitializeReleaseNotes", false)
            return false
        end

        self.savedVarsGlobal.viewedReleaseNotes = self.savedVarsGlobal.viewedReleaseNotes or {}

        local currentVersion = self.sadCore.releaseNotes.version
        local viewedVersion = self.savedVarsGlobal.viewedReleaseNotes[self.addonName]

        if currentVersion and currentVersion ~= viewedVersion then
            self:ShowReleaseNotes(true)
            self.savedVarsGlobal.viewedReleaseNotes[self.addonName] = currentVersion
        end

        local returnValue = true
        callHook(self, "AfterInitializeReleaseNotes", returnValue)
        return returnValue
    end

    function addon:ShowReleaseNotes(delay)
        callHook(self, "BeforeShowReleaseNotes")

        if not self.sadCore.releaseNotes then
            self:Info(self:L("core_noReleaseNotes"))
            callHook(self, "AfterShowReleaseNotes", false)
            return false
        end

        if not self.sadCore.releaseNotes.notes then
            callHook(self, "AfterShowReleaseNotes", false)
            return false
        end

        local function displayNotes()
            local version = self.sadCore.releaseNotes.version or "Unknown"
            self:Info(self:L("core_releaseNotesTitle") .. " " .. version)
            
            local noteNumber = 1
            for _, noteKey in ipairs(self.sadCore.releaseNotes.notes) do
                local localizedNote = self:L(noteKey)
                self:Info(noteNumber .. ". " .. localizedNote)
                noteNumber = noteNumber + 1
            end
        end

        if delay then
            C_Timer.After(1, function()
                displayNotes()
            end)
        else
            displayNotes()
        end

        local returnValue = true
        callHook(self, "AfterShowReleaseNotes", returnValue)
        return returnValue
    end
end

do -- Combat Queue System

    function addon:_InitializeCombatQueue()
        callHook(self, "BeforeInitializeCombatQueue")

        self.combatQueue = self.combatQueue or {}

        if not self.combatQueueFrame then
            self.combatQueueFrame = CreateFrame("Frame")
            local addonInstance = self

            self.combatQueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            self.combatQueueFrame:SetScript("OnEvent", function(frame, event)
                if event == "PLAYER_REGEN_ENABLED" then
                    addonInstance:_ProcessCombatQueue()
                end
            end)
        end

        local returnValue = true
        callHook(self, "AfterInitializeCombatQueue", returnValue)
        return returnValue
    end

    function addon:CombatSafe(func)
        callHook(self, "BeforeCombatSafe", func)

        if type(func) ~= "function" then
            self:Error(self:L("core_combatSafeRequiresFunction"))
            callHook(self, "AfterCombatSafe", false)
            return false
        end

        local addonInstance = self
        C_Timer.After(0.1, function()
            if InCombatLockdown() then
                table.insert(addonInstance.combatQueue, {
                    func = func,
                    args = {}
                })
                addonInstance:Debug(addonInstance:L("core_actionQueuedForCombat"))
                callHook(addonInstance, "AfterCombatSafe", false)
                return false
            end

            local success, result = pcall(func, addonInstance)
            if success then
                callHook(addonInstance, "AfterCombatSafe", result)
                return result
            end

            addonInstance:Error(addonInstance:L("core_combatSafeFunctionError") .. ": " .. tostring(result))
            callHook(addonInstance, "AfterCombatSafe", false)
            return false
        end)

        callHook(self, "AfterCombatSafe", true)
        return true
    end

    function addon:SecureCall(func, ...)
        callHook(self, "BeforeSecureCall", func)

        if type(func) ~= "function" then
            self:Error(self:L("core_secureCallRequiresFunction"))
            callHook(self, "AfterSecureCall", false)
            return false
        end

        if not self.secretTestFrame then
            self.secretTestFrame = CreateFrame("EditBox")
            self.secretTestFrame:Hide()
        end

        local success, ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16, ret17, ret18, ret19, ret20 = pcall(func, ...)

        if not success then
            callHook(self, "AfterSecureCall", nil)
            return nil
        end

        local function makeSafe(value)
            if value == nil then
                return nil
            end

            local isSafe = pcall(function()
                local str = tostring(value)
                self.secretTestFrame:SetText(str)
            end)

            self.secretTestFrame:ClearFocus()

            return isSafe and value or false
        end

        local safeRet1 = makeSafe(ret1)
        local safeRet2 = makeSafe(ret2)
        local safeRet3 = makeSafe(ret3)
        local safeRet4 = makeSafe(ret4)
        local safeRet5 = makeSafe(ret5)
        local safeRet6 = makeSafe(ret6)
        local safeRet7 = makeSafe(ret7)
        local safeRet8 = makeSafe(ret8)
        local safeRet9 = makeSafe(ret9)
        local safeRet10 = makeSafe(ret10)
        local safeRet11 = makeSafe(ret11)
        local safeRet12 = makeSafe(ret12)
        local safeRet13 = makeSafe(ret13)
        local safeRet14 = makeSafe(ret14)
        local safeRet15 = makeSafe(ret15)
        local safeRet16 = makeSafe(ret16)
        local safeRet17 = makeSafe(ret17)
        local safeRet18 = makeSafe(ret18)
        local safeRet19 = makeSafe(ret19)
        local safeRet20 = makeSafe(ret20)

        callHook(self, "AfterSecureCall", safeRet1, safeRet2, safeRet3, safeRet4, safeRet5, safeRet6, safeRet7, safeRet8, safeRet9, safeRet10, safeRet11, safeRet12, safeRet13, safeRet14, safeRet15, safeRet16, safeRet17, safeRet18, safeRet19, safeRet20)
        return safeRet1, safeRet2, safeRet3, safeRet4, safeRet5, safeRet6, safeRet7, safeRet8, safeRet9, safeRet10, safeRet11, safeRet12, safeRet13, safeRet14, safeRet15, safeRet16, safeRet17, safeRet18, safeRet19, safeRet20
    end

    function addon:_ProcessCombatQueue()
        callHook(self, "BeforeProcessCombatQueue")

        if not self.combatQueue or #self.combatQueue == 0 then
            callHook(self, "AfterProcessCombatQueue", true)
            return true
        end

        local queueCount = #self.combatQueue
        self:Debug("Processing queued actions: " .. queueCount)

        local processedCount = 0
        local failedCount = 0

        while #self.combatQueue > 0 do
            local action = table.remove(self.combatQueue, 1)
            local success, result = pcall(action.func, self, unpack(action.args))

            if success then
                processedCount = processedCount + 1
            else
                failedCount = failedCount + 1
                self:Error(self:L("core_queuedActionFailed") .. ": " .. tostring(result))
            end
        end

        if processedCount > 0 then
            self:Debug("Processed actions: " .. processedCount)
        end

        if failedCount > 0 then
            self:Debug("Failed actions: " .. failedCount)
        end

        local returnValue = true
        callHook(self, "AfterProcessCombatQueue", returnValue)
        return returnValue
    end

    function addon:_ClearCombatQueue()
        callHook(self, "BeforeClearCombatQueue")

        local queueCount = #self.combatQueue
        self.combatQueue = {}

        if queueCount > 0 then
            self:Debug("Cleared queued actions: " .. queueCount)
        end

        local returnValue = true
        callHook(self, "AfterClearCombatQueue", returnValue)
        return returnValue
    end

end

do -- Localization
    SAdCore.prototype.locale = SAdCore.prototype.locale or {}

    SAdCore.prototype.locale.enEN = {
        core_SAdCore = "SAdCore",
        core_close = "Close",
        core_debuggingHeader = "Debugging",
        core_profile = "Profile",
        core_enableDebugging = "Enable Debugging",
        core_enableDebuggingTooltip = "Enable debug messages in the chat window.",
        core_useCharacterSettings = "Use Character Specific Settings",
        core_characterSpecificSettingsTooltip = "When enabled, settings will be saved per character instead of account-wide.",
        core_loadSettings = "Load Settings from String",
        core_loadSettingsTooltip = "Paste an exported settings string and click Load to import settings.",
        core_loadSettingsButton = "Load",
        core_shareSettings = "Share",
        core_shareSettingsTooltip = "Export your current settings as a string that can be shared with others.",
        core_shareSettingsTitle = "Share Settings",
        core_shareSettingsLabel = "Press CTRL + C to Copy",
        core_importDecodeFailed = "Decode failed.",
        core_importDeserializeFailed = "Deserialize failed.",
        core_importInvalidData = "Invalid data structure.",
        core_importSuccess = "Settings imported successfully.",
        core_tagline = "Simple Addons—Bare minimum addons for bare minimum brains.",
        core_authorTitle = "Author",
        core_authorName = "Press CTRL + C to Copy",
        core_errorConfigHelp1 = "SavedVariables configuration error detected.",
        core_errorConfigHelp2 = "All variable names must contain the addon name to ensure uniqueness across all addons.",
        core_errorConfigExample = "Example configuration for addon",
        core_cannotOpenInCombat = "Cannot open settings while in combat.",
        core_combatSafeRequiresFunction = "CombatSafe requires a function as parameter",
        core_combatSafeFunctionError = "Combat safe function error",
        core_actionQueuedForCombat = "Action queued for after combat",
        core_queuedActionFailed = "Combat safe queued action failed",
        core_secureCallRequiresFunction = "SecureCall requires a function as parameter",
        core_retryRequiresFunction = "Retry requires a function as parameter",
        core_releaseNotesTitle = "Release Notes for Version",
        core_noReleaseNotes = "No release notes available.",
        core_showReleaseNotes = "Release Notes",
        core_showReleaseNotesTooltip = "Display the latest release notes for this addon.",
    }

    -- Spanish
    SAdCore.prototype.locale.esES = {
        core_SAdCore = "SAdCore",
        core_close = "Cerrar",
        core_debuggingHeader = "Depuración",
        core_profile = "Perfil",
        core_enableDebugging = "Habilitar Depuración",
        core_enableDebuggingTooltip = "Habilitar mensajes de depuración en la ventana de chat.",
        core_useCharacterSettings = "Usar Configuración Específica del Personaje",
        core_characterSpecificSettingsTooltip = "Cuando está habilitado, la configuración se guardará por personaje en lugar de para toda la cuenta.",
        core_loadSettings = "Cargar Configuración desde Cadena",
        core_loadSettingsTooltip = "Pega una cadena de configuración exportada y haz clic en Cargar para importar la configuración.",
        core_loadSettingsButton = "Cargar",
        core_shareSettings = "Compartir",
        core_shareSettingsTooltip = "Exporta tu configuración actual como una cadena que se puede compartir con otros.",
        core_shareSettingsTitle = "Compartir Configuración",
        core_shareSettingsLabel = "Presiona CTRL + C para Copiar",
        core_importDecodeFailed = "Error al decodificar.",
        core_importDeserializeFailed = "Error al deserializar.",
        core_importInvalidData = "Estructura de datos inválida.",
        core_importSuccess = "Configuración importada exitosamente.",
        core_tagline = "Simple Addons—Addons mínimos para mentes mínimas.",
        core_authorTitle = "Autor",
        core_authorName = "Presiona CTRL + C para Copiar",
        core_errorConfigHelp1 = "Se detectó un error de configuración de SavedVariables.",
        core_errorConfigHelp2 = "Todos los nombres de variables deben contener el nombre del addon para garantizar la unicidad entre todos los addons.",
        core_errorConfigExample = "Ejemplo de configuración para el addon",
        core_cannotOpenInCombat = "No se puede abrir la configuración durante el combate.",
        core_combatSafeRequiresFunction = "CombatSafe requiere una función como parámetro",
        core_combatSafeFunctionError = "Error en función protegida contra combate",
        core_actionQueuedForCombat = "Acción en cola para después del combate",
        core_queuedActionFailed = "Acción en cola falló",
        core_secureCallRequiresFunction = "SecureCall requiere una función como parámetro",
        core_retryRequiresFunction = "Retry requiere una función como parámetro",
        core_releaseNotesTitle = "Notas de la Versión",
        core_noReleaseNotes = "No hay notas de versión disponibles.",
        core_showReleaseNotes = "Notas de Versión",
        core_showReleaseNotesTooltip = "Mostrar las últimas notas de versión de este addon.",
    }

    SAdCore.prototype.locale.esMX = SAdCore.prototype.locale.esES

    -- Portuguese
    SAdCore.prototype.locale.ptBR = {
        core_SAdCore = "SAdCore",
        core_close = "Fechar",
        core_debuggingHeader = "Depuração",
        core_profile = "Perfil",
        core_enableDebugging = "Habilitar Depuração",
        core_enableDebuggingTooltip = "Habilitar mensagens de depuração na janela de chat.",
        core_useCharacterSettings = "Usar Configurações Específicas do Personagem",
        core_characterSpecificSettingsTooltip = "Quando habilitado, as configurações serão salvas por personagem em vez de para toda a conta.",
        core_loadSettings = "Carregar Configurações da String",
        core_loadSettingsTooltip = "Cole uma string de configurações exportada e clique em Carregar para importar as configurações.",
        core_loadSettingsButton = "Carregar",
        core_shareSettings = "Compartilhar",
        core_shareSettingsTooltip = "Exporte suas configurações atuais como uma string que pode ser compartilhada com outros.",
        core_shareSettingsTitle = "Compartilhar Configurações",
        core_shareSettingsLabel = "Pressione CTRL + C para Copiar",
        core_importDecodeFailed = "Falha na decodificação.",
        core_importDeserializeFailed = "Falha na desserialização.",
        core_importInvalidData = "Estrutura de dados inválida.",
        core_importSuccess = "Configurações importadas com sucesso.",
        core_tagline = "Simple Addons—Addons mínimos para mentes mínimas.",
        core_authorTitle = "Autor",
        core_authorName = "Pressione CTRL + C para Copiar",
        core_errorConfigHelp1 = "Erro de configuração de SavedVariables detectado.",
        core_errorConfigHelp2 = "Todos os nomes de variáveis devem conter o nome do addon para garantir exclusividade entre todos os addons.",
        core_errorConfigExample = "Exemplo de configuração para o addon",
        core_cannotOpenInCombat = "Não é possível abrir as configurações durante o combate.",
        core_combatSafeRequiresFunction = "CombatSafe requer uma função como parâmetro",
        core_combatSafeFunctionError = "Erro na função protegida contra combate",
        core_actionQueuedForCombat = "Ação enfileirada para depois do combate",
        core_queuedActionFailed = "Ação enfileirada falhou",
        core_secureCallRequiresFunction = "SecureCall requer uma função como parâmetro",
        core_retryRequiresFunction = "Retry requer uma função como parâmetro",
        core_releaseNotesTitle = "Notas de Versão",
        core_noReleaseNotes = "Nenhuma nota de versão disponível.",
        core_showReleaseNotes = "Notas de Versão",
        core_showReleaseNotesTooltip = "Exibir as últimas notas de versão deste addon.",
    }

    -- French
    SAdCore.prototype.locale.frFR = {
        core_SAdCore = "SAdCore",
        core_close = "Fermer",
        core_debuggingHeader = "Débogage",
        core_profile = "Profil",
        core_enableDebugging = "Activer le Débogage",
        core_enableDebuggingTooltip = "Activer les messages de débogage dans la fenêtre de chat.",
        core_useCharacterSettings = "Utiliser les Paramètres Spécifiques au Personnage",
        core_characterSpecificSettingsTooltip = "Lorsqu'activé, les paramètres seront sauvegardés par personnage au lieu de pour tout le compte.",
        core_loadSettings = "Charger les Paramètres depuis une Chaîne",
        core_loadSettingsTooltip = "Collez une chaîne de paramètres exportée et cliquez sur Charger pour importer les paramètres.",
        core_loadSettingsButton = "Charger",
        core_shareSettings = "Partager",
        core_shareSettingsTooltip = "Exportez vos paramètres actuels sous forme de chaîne pouvant être partagée avec d'autres.",
        core_shareSettingsTitle = "Partager les Paramètres",
        core_shareSettingsLabel = "Appuyez sur CTRL + C pour Copier",
        core_importDecodeFailed = "Échec du décodage.",
        core_importDeserializeFailed = "Échec de la désérialisation.",
        core_importInvalidData = "Structure de données invalide.",
        core_importSuccess = "Paramètres importés avec succès.",
        core_tagline = "Simple Addons—Addons minimaux pour esprits minimaux.",
        core_authorTitle = "Auteur",
        core_authorName = "Appuyez sur CTRL + C pour Copier",
        core_errorConfigHelp1 = "Erreur de configuration de SavedVariables détectée.",
        core_errorConfigHelp2 = "Tous les noms de variables doivent contenir le nom de l'addon pour garantir l'unicité entre tous les addons.",
        core_errorConfigExample = "Exemple de configuration pour l'addon",
        core_cannotOpenInCombat = "Impossible d'ouvrir les paramètres en combat.",
        core_combatSafeRequiresFunction = "CombatSafe nécessite une fonction comme paramètre",
        core_combatSafeFunctionError = "Erreur de fonction sécurisée contre le combat",
        core_actionQueuedForCombat = "Action mise en file d'attente pour après le combat",
        core_queuedActionFailed = "Action en file d'attente échouée",
        core_secureCallRequiresFunction = "SecureCall nécessite une fonction comme paramètre",
        core_retryRequiresFunction = "Retry nécessite une fonction comme paramètre",
        core_releaseNotesTitle = "Notes de Version pour la Version",
        core_noReleaseNotes = "Aucune note de version disponible.",
        core_showReleaseNotes = "Notes de Version",
        core_showReleaseNotesTooltip = "Afficher les dernières notes de version de cet addon.",
    }

    -- German
    SAdCore.prototype.locale.deDE = {
        core_SAdCore = "SAdCore",
        core_close = "Schließen",
        core_debuggingHeader = "Debugging",
        core_profile = "Profil",
        core_enableDebugging = "Debugging aktivieren",
        core_enableDebuggingTooltip = "Debug-Nachrichten im Chatfenster aktivieren.",
        core_useCharacterSettings = "Charakterspezifische Einstellungen verwenden",
        core_characterSpecificSettingsTooltip = "Wenn aktiviert, werden die Einstellungen pro Charakter statt account-weit gespeichert.",
        core_loadSettings = "Einstellungen aus Zeichenfolge laden",
        core_loadSettingsTooltip = "Fügen Sie eine exportierte Einstellungs-Zeichenfolge ein und klicken Sie auf Laden, um die Einstellungen zu importieren.",
        core_loadSettingsButton = "Laden",
        core_shareSettings = "Teilen",
        core_shareSettingsTooltip = "Exportieren Sie Ihre aktuellen Einstellungen als Zeichenfolge, die mit anderen geteilt werden kann.",
        core_shareSettingsTitle = "Einstellungen teilen",
        core_shareSettingsLabel = "Drücken Sie STRG + C zum Kopieren",
        core_importDecodeFailed = "Dekodierung fehlgeschlagen.",
        core_importDeserializeFailed = "Deserialisierung fehlgeschlagen.",
        core_importInvalidData = "Ungültige Datenstruktur.",
        core_importSuccess = "Einstellungen erfolgreich importiert.",
        core_tagline = "Simple Addons—Minimale Addons für minimale Köpfe.",
        core_authorTitle = "Autor",
        core_authorName = "Drücken Sie STRG + C zum Kopieren",
        core_errorConfigHelp1 = "SavedVariables-Konfigurationsfehler erkannt.",
        core_errorConfigHelp2 = "Alle Variablennamen müssen den Addon-Namen enthalten, um Eindeutigkeit über alle Addons hinweg zu gewährleisten.",
        core_errorConfigExample = "Beispielkonfiguration für Addon",
        core_cannotOpenInCombat = "Einstellungen können im Kampf nicht geöffnet werden.",
        core_combatSafeRequiresFunction = "CombatSafe benötigt eine Funktion als Parameter",
        core_combatSafeFunctionError = "Kampfsichere Funktionsfehler",
        core_actionQueuedForCombat = "Aktion für nach dem Kampf in Warteschlange gestellt",
        core_queuedActionFailed = "Warteschlangenaktion fehlgeschlagen",
        core_secureCallRequiresFunction = "SecureCall benötigt eine Funktion als Parameter",
        core_retryRequiresFunction = "Retry benötigt eine Funktion als Parameter",
        core_releaseNotesTitle = "Versionshinweise für Version",
        core_noReleaseNotes = "Keine Versionshinweise verfügbar.",
        core_showReleaseNotes = "Versionshinweise",
        core_showReleaseNotesTooltip = "Zeige die neuesten Versionshinweise für dieses Addon.",
    }

    -- Russian
    SAdCore.prototype.locale.ruRU = {
        core_SAdCore = "SAdCore",
        core_close = "Закрыть",
        core_debuggingHeader = "Дебаггинг",
        core_profile = "Профиль",
        core_enableDebugging = "Включить отладку",
        core_enableDebuggingTooltip = "Включить отладочные сообщения в окне чата.",
        core_useCharacterSettings = "Использовать настройки персонажа",
        core_characterSpecificSettingsTooltip = "Когда включено, настройки сохраняются для каждого персонажа отдельно, а не для всей учетной записи.",
        core_loadSettings = "Загрузить настройки из строки",
        core_loadSettingsTooltip = "Вставьте экспортированную строку настроек и нажмите Загрузить для импорта.",
        core_loadSettingsButton = "Загрузить",
        core_shareSettings = "Поделиться",
        core_shareSettingsTooltip = "Экспортировать текущие настройки в виде строки, которой можно поделиться с другими.",
        core_shareSettingsTitle = "Поделиться настройками",
        core_shareSettingsLabel = "Нажмите CTRL + C для копирования",
        core_importDecodeFailed = "Ошибка декодирования.",
        core_importDeserializeFailed = "Ошибка десериализации.",
        core_importInvalidData = "Неверная структура данных.",
        core_importSuccess = "Настройки успешно импортированы.",
        core_tagline = "Simple Addons—Минимальные аддоны для минимальных умов.",
        core_authorTitle = "Автор",
        core_authorName = "Нажмите CTRL + C для копирования",
        core_errorConfigHelp1 = "Обнаружена ошибка конфигурации SavedVariables.",
        core_errorConfigHelp2 = "Все имена переменных должны содержать имя аддона для обеспечения уникальности среди всех аддонов.",
        core_errorConfigExample = "Пример конфигурации для аддона",
        core_cannotOpenInCombat = "Невозможно открыть настройки в бою.",
        core_combatSafeRequiresFunction = "CombatSafe требует функцию в качестве параметра",
        core_combatSafeFunctionError = "Ошибка защищенной от боя функции",
        core_actionQueuedForCombat = "Действие поставлено в очередь после боя",
        core_queuedActionFailed = "Действие из очереди не выполнено",
        core_secureCallRequiresFunction = "SecureCall требует функцию в качестве параметра",
        core_retryRequiresFunction = "Retry требует функцию в качестве параметра",
        core_releaseNotesTitle = "Примечания к версии",
        core_noReleaseNotes = "Нет доступных примечаний к версии.",
        core_showReleaseNotes = "Примечания к версии",
        core_showReleaseNotesTooltip = "Показать последние примечания к версии для этого аддона.",
    }
end

local addonName, ns = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local MEDIA_PATH = "Interface\\AddOns\\" .. addonName .. "\\Media\\"

local bundledFonts = {
    ["DorisPP"] = MEDIA_PATH .. "Fonts\\DorisPP.ttf",
}

local bundledStatusbars = {
    ["Diagonal"]    = MEDIA_PATH .. "Statusbar\\Diagonal.tga",
    ["Minimalist"]  = MEDIA_PATH .. "Statusbar\\Minimalist.tga",
    ["Smooth"]      = MEDIA_PATH .. "Statusbar\\Smooth.tga",
}

local defaults = {
    font      = bundledFonts["DorisPP"],
    statusbar = bundledStatusbars["Smooth"],
}

if LSM then
    for name, path in pairs(bundledFonts) do
        LSM:Register(LSM.MediaType.FONT, name, path)
    end
    for name, path in pairs(bundledStatusbars) do
        LSM:Register(LSM.MediaType.STATUSBAR, name, path)
    end
end

function addon:FetchMedia(mediaType, key)
    if not key then
        return defaults[mediaType]
    end

    if LSM then
        local path = LSM:Fetch(mediaType, key, true)
        if path then return path end
    end

    local bundled
    if mediaType == "font" then
        bundled = bundledFonts
    elseif mediaType == "statusbar" then
        bundled = bundledStatusbars
    end

    if bundled then
        if bundled[key] then return bundled[key] end
        for name, path in pairs(bundled) do
            if name:lower() == key:lower() then
                return path
            end
        end
    end

    return defaults[mediaType]
end

function addon:FetchFont(fontName)
    local name = fontName

    if not name or type(self.config.global[name]) == "number" then
        name = self.config.global.font
    end

    return self:FetchMedia("font", name)
end

function addon:FetchStatusbar(key)
    return self:FetchMedia("statusbar", key)
end

function addon:HasLSM()
    return LSM ~= nil
end

function addon:ListMedia(mediaType)
    if LSM then
        return LSM:List(mediaType)
    end

    local bundled
    if mediaType == "font" then
        bundled = bundledFonts
    elseif mediaType == "statusbar" then
        bundled = bundledStatusbars
    end

    if not bundled then return {} end

    local list = {}
    for name in pairs(bundled) do
        list[#list + 1] = name
    end
    table.sort(list)
    return list
end

function addon:MediaDropdownOptions(mediaType)
    local list = self:ListMedia(mediaType)
    local options = {}
    for _, name in ipairs(list) do
        local locKey = name:gsub(" ", "_"):gsub("[^%w_]", "")
        if self.localization then
            self.localization[locKey] = name
        end
        options[#options + 1] = { value = name, label = name }
    end
    return options
end

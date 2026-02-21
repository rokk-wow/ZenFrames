local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:GetDefaultConfig()
    return {
        global = {
            font = "DorisPP",
            
            refreshDelay = 0.1,

            manaColor = "2482ff",
            rageColor = "ff0000",
            focusColor = "ff8000",
            energyColor = "ffff00",
            runicPowerColor = "00d4ff",
            lunarPowerColor = "4d85e6",
            comboPointColor = "ffaa00",
            runesColor = "00d4ff",

            hostileColor = "ff0000",
            neutralColor = "ffff00",
            friendlyColor = "00ff00",

            highlightColor = "ffbb00",

            castbarColor = "ffbb00",
            castbarChannelColor = "ffbb00",
            castbarNonInterruptibleColor = "888888",
            castbarEmpowerColor = "5588dd",

            dispelColors = {
                Magic   = "ff00ffFF",
                Curse   = "990099ff",
                Disease = "bbcc00FF",
                Poison  = "00cc00FF",
                Bleed   = "CC0000FF",
                Enrage  = "FF3300FF",
                default = "FFFFFFFF",
            },

            roleIcons = {
                TANK = "RaidFrame-Icon-MainTank",
                HEALER = "icons_64x64_heal",
                DAMAGER = "RaidFrame-Icon-MainAssist",
            },

            specAbbrevById = {
                -- Warrior
                [71] = "ARMS",
                [72] = "FURY",
                [73] = "PROT",
                -- Paladin
                [65] = "HOLY",
                [66] = "PROT",
                [70] = "RET",
                -- Hunter
                [253] = "BM",
                [254] = "MM",
                [255] = "SV",
                -- Rogue
                [259] = "ASSA",
                [260] = "OUTL",
                [261] = "SUB",
                -- Priest
                [256] = "DISC",
                [257] = "HOLY",
                [258] = "SPRIEST",
                -- Death Knight
                [250] = "BDK",
                [251] = "FDK",
                [252] = "UDK",
                -- Shaman
                [262] = "ELE",
                [263] = "ENH",
                [264] = "RESTO",
                -- Mage
                [62] = "ARC",
                [63] = "FIRE",
                [64] = "FROST",
                -- Warlock
                [265] = "AFF",
                [266] = "DEMO",
                [267] = "DESTRO",
                -- Monk
                [268] = "BREW",
                [269] = "WW",
                [270] = "MW",
                -- Druid
                [102] = "BAL",
                [103] = "FERAL",
                [104] = "GUARD",
                [105] = "RESTO",
                -- Demon Hunter
                [577] = "HAVOC",
                [581] = "VENG",
                -- Evoker
                [1467] = "DEV",
                [1468] = "PRES",
                [1473] = "AUG",
            },
        },
        player = {
            enabled = true,
            hideBlizzard = true,
            frameName = "frmdPlayerFrame",
            anchor = "TOPRIGHT",
            relativeTo = "UIParent",
            relativePoint = "BOTTOM",
            offsetX = -178,
            offsetY = 163,
            width = 203,
            height = 41,
            backgroundColor = "00000088",
            borderWidth = 2,
            borderColor = "000000FF",

            modules = {
                health = {
                    enabled = true,
                    frameName = "frmdPlayerHealthbar",
                    anchor = "TOP",
                    relativeTo = "frmdPlayerFrame",
                    relativePoint = "TOP",
                    texture = "smooth",
                    height = 41,
                    offsetX = 0,
                    offsetY = 0,
                    color = "class",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "BOTTOMLEFT",
                        relativeTo = "frmdPlayerFrame",
                        relativePoint = "TOPLEFT",
                        offsetX = 0,
                        offsetY = -7,
                        size = 14,
                        color = "FFFFFF",
                        format = "[name:medium]",
                    },
                    {
                        enabled = true,
                        anchor = "BOTTOMRIGHT",
                        relativeTo = "frmdPlayerFrame",
                        relativePoint = "TOPRIGHT",
                        offsetX = 2,
                        offsetY = -7,
                        size = 14,
                        color = "FFFFFF",
                        format = "[perhp]% / [maxhp:short]",
                    },
                },
                power = {
                    enabled = true,
                    frameName = "frmdPlayerPowerbar",
                    anchor = "BOTTOM",
                    relativeTo = "frmdPlayerFrame",
                    relativePoint = "BOTTOM",
                    texture = "minimalist",
                    height = 12,
                    adjustHealthbarHeight = true,
                    offsetX = 0,
                    offsetY = 0,
                    borderWidth = 1,
                    borderColor = "000000FF",
                },
                castbar = {
                    enabled = true,
                    frameName = "frmdPlayerCastbar",
                    anchor = "BOTTOM",
                    relativeTo = "MainActionBar",
                    relativePoint = "TOP",
                    width = 332,
                    height = 30,
                    offsetX = 0,
                    offsetY = 10,
                    texture = "smooth",
                    showSpellName = true,
                    textAlignment = "CENTER",
                    showIcon = false,
                    iconPosition = "LEFT",
                    showCastTime = false,
                    backgroundColor = "00000088",
                    borderWidth = 2,
                    borderColor = "000000FF",
                },
                auraFilters = {
                    {
                        name = "StaticPlayerBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        disableMouse = false,
                        frameName = "frmdStaticPlayerBuffs",
                        anchor = "TOPRIGHT",
                        relativeTo = "UIParent",
                        relativePoint = "TOP",
                        offsetX = -100,
                        offsetY = 0,
                        iconSize = 20,
                        spacingX = 2,
                        spacingY = 2,
                        maxIcons = 21,
                        perRow = 21,
                        growthX = "LEFT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "ActivePlayerBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"RAID_IN_COMBAT"},
                        excludeSubFilters = {"NOT_CANCELABLE"},
                        disableMouse = false,
                        frameName = "frmdActivePlayerBuffs",
                        anchor = "TOPRIGHT",
                        relativeTo = "frmdStaticPlayerBuffs",
                        relativePoint = "BOTTOMRIGHT",
                        offsetX = 0,
                        offsetY = -10,
                        iconSize = 30,
                        spacingX = 2,
                        spacingY = 2,
                        maxIcons = 30,
                        perRow = 15,
                        growthX = "LEFT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "ActivePlayerDebuffs",
                        enabled = true,
                        baseFilter = "HARMFUL",
                        disableMouse = false,
                        frameName = "frmdActivePlayerDebuffs",
                        anchor = "TOPRIGHT",
                        relativeTo = "frmdActivePlayerBuffs",
                        relativePoint = "BOTTOMRIGHT",
                        offsetX = 0,
                        offsetY = -10,
                        iconSize = 42,
                        spacingX = 2,
                        spacingY = 2,
                        maxIcons = 11,
                        perRow = 11,
                        growthX = "LEFT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "FF0000FF",
                    },
                },
                absorbs = {
                    enabled = true,
                    opacity = .5,
                    maxAbsorbOverflow = 1.0,
                    texture = "Diagonal",
                },
                combatIndicator = {
                    enabled = true,
                    atlasTexture = "titleprestige-prestigeicon",
                    size = 30,
                    strata = "LOW",
                    anchor = "CENTER",
                    relativeTo = "MainActionBar",
                    relativePoint = "CENTER",
                    offsetX = 0,
                    offsetY = 44,
                },
                restingIndicator = {
                    enabled = true,
                    atlasTexture = "plunderstorm-nameplates-icon-2",
                    size = 36,
                    strata = "LOW",
                    anchor = "CENTER",
                    relativeTo = "MainActionBar",
                    relativePoint = "CENTER",
                    offsetX = 0,
                    offsetY = 44,
                },
            },
        },
        target = {
            enabled = true,
            hideBlizzard = true,
            frameName = "frmdTargetFrame",
            anchor = "TOPLEFT",
            relativeTo = "UIParent",
            relativePoint = "BOTTOM",
            offsetX = 178,
            offsetY = 163,
            width = 203,
            height = 41,
            backgroundColor = "00000088",
            borderWidth = 2,
            borderColor = "000000FF",
            modules = {
                health = {
                    enabled = true,
                    frameName = "frmdTargetHealth",
                    anchor = "TOP",
                    relativeTo = "frmdTargetFrame",
                    relativePoint = "TOP",
                    texture = "smooth",
                    height = 41,
                    offsetX = 0,
                    offsetY = 0,
                    color = "class",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "BOTTOMLEFT",
                        relativeTo = "frmdTargetFrame",
                        relativePoint = "TOPLEFT",
                        offsetX = 0,
                        offsetY = -7,
                        size = 14,
                        color = "FFFFFF",
                        format = "[name:medium]",
                    },
                    {
                        enabled = true,
                        anchor = "BOTTOMRIGHT",
                        relativeTo = "frmdTargetFrame",
                        relativePoint = "TOPRIGHT",
                        offsetX = 2,
                        offsetY = -7,
                        size = 14,
                        color = "FFFFFF",
                        format = "[perhp]% / [maxhp:short]",
                    },
                },
                power = {
                    enabled = true,
                    frameName = "frmdTargetPowerbar",
                    anchor = "BOTTOM",
                    relativeTo = "frmdTargetFrame",
                    relativePoint = "BOTTOM",
                    texture = "minimalist",
                    height = 12,
                    adjustHealthbarHeight = true,
                    offsetX = 0,
                    offsetY = 0,
                    borderWidth = 1,
                    borderColor = "000000FF",
                },
                castbar = {
                    enabled = true,
                    frameName = "frmdTargetCastbar",
                    anchor = "TOP",
                    relativeTo = "frmdTargetFrame",
                    relativePoint = "BOTTOM",
                    height = 20,
                    offsetX = 0,
                    offsetY = 0,
                    texture = "smooth",
                    showSpellName = true,
                    textAlignment = "LEFT",
                    showIcon = false,
                    iconPosition = "RIGHT",
                    showCastTime = false,
                    backgroundColor = "00000088",
                    borderWidth = 2,
                    borderColor = "000000FF",
                },
                auraFilters = {
                    {
                        name = "StaticTargetBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        excludeSubFilters = {"CANCELABLE"},
                        disableMouse = false,
                        frameName = "frmdStaticTargetBuffs",
                        anchor = "TOPLEFT",
                        relativeTo = "UIParent",
                        relativePoint = "TOP",
                        offsetX = 100,
                        offsetY = 0,
                        iconSize = 20,
                        spacingX = 2,
                        spacingY = 2,
                        maxIcons = 21,
                        perRow = 21,
                        growthX = "RIGHT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "ActiveTargetBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"CANCELABLE"},
                        disableMouse = false,
                        frameName = "frmdActiveTargetBuffs",
                        anchor = "TOPLEFT",
                        relativeTo = "frmdStaticTargetBuffs",
                        relativePoint = "BOTTOMLEFT",
                        offsetX = 0,
                        offsetY = -10,
                        iconSize = 30,
                        spacingX = 2,
                        spacingY = 2,
                        maxIcons = 30,
                        perRow = 15,
                        growthX = "RIGHT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "ActiveTargetDebuffs",
                        enabled = true,
                        baseFilter = "HARMFUL",
                        disableMouse = false,
                        frameName = "frmdActiveTargetDebuffs",
                        anchor = "TOPLEFT",
                        relativeTo = "frmdActiveTargetBuffs",
                        relativePoint = "BOTTOMLEFT",
                        offsetX = 0,
                        offsetY = -10,
                        iconSize = 42,
                        spacingX = 2,
                        spacingY = 2,
                        maxIcons = 11,
                        perRow = 11,
                        growthX = "RIGHT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "FF0000FF",
                    },
                },
                absorbs = {
                    enabled = true,
                    opacity = .5,
                    maxAbsorbOverflow = 1.0,
                    texture = "Diagonal",
                },
            },
        },
        targetTarget = {
            enabled = true,
            hideBlizzard = true,
            frameName = "frmdTargetTargetFrame",
            anchor = "TOPLEFT",
            relativeTo = "frmdTargetFrame",
            relativePoint = "TOPRIGHT",
            offsetX = 10,
            offsetY = 0,
            width = 93,
            height = 21,
            backgroundColor = "00000088",
            borderWidth = 2,
            borderColor = "000000FF",
            modules = {
                health = {
                    enabled = true,
                    color = "class",
                    texture = "smooth",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "LEFT",
                        relativeTo = "frmdTargetTargetFrame",
                        relativePoint = "LEFT",
                        offsetX = 3,
                        offsetY = 0,
                        size = 11,
                        color = "FFFFFF",
                        format = "[name:short]",
                    },
                },
            },
        },
        focus = {
            enabled = true,
            hideBlizzard = true,
            frameName = "frmdFocusFrame",
            anchor = "TOPRIGHT",
            relativeTo = "frmdPlayerFrame",
            relativePoint = "TOPLEFT",
            offsetX = -10,
            offsetY = 0,
            width = 93,
            height = 21,
            backgroundColor = "00000088",
            borderWidth = 2,
            borderColor = "000000FF",
            modules = {
                health = {
                    enabled = true,
                    color = "class",
                    texture = "smooth",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "LEFT",
                        relativeTo = "frmdFocusFrame",
                        relativePoint = "LEFT",
                        offsetX = 3,
                        offsetY = 0,
                        size = 11,
                        color = "FFFFFF",
                        format = "[name:short]",
                    },
                },
            },
        },
        focusTarget = {
            enabled = true,
            hideBlizzard = true,
            frameName = "frmdFocusTargetFrame",
            anchor = "TOPLEFT",
            relativeTo = "frmdFocusFrame",
            relativePoint = "BOTTOMLEFT",
            offsetX = 0,
            offsetY = 0,
            width = 75,
            height = 20,
            backgroundColor = "00000088",
            borderWidth = 2,
            borderColor = "000000FF",
            modules = {
                health = {
                    enabled = true,
                    color = "class",
                    texture = "smooth",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "LEFT",
                        relativeTo = "frmdFocusTargetFrame",
                        relativePoint = "LEFT",
                        offsetX = 3,
                        offsetY = 0,
                        size = 11,
                        color = "FFFFFF",
                        format = "[name:short]",
                    },
                },
            },
        },
        pet = {
            enabled = true,
            hideBlizzard = true,
            frameName = "frmdPetFrame",
            anchor = "TOPLEFT",
            relativeTo = "PlayerFrame",
            relativePoint = "TOPRIGHT",
            offsetX = 10,
            offsetY = 200,
            width = 93,
            height = 29,
            borderWidth = 2,
            borderColor = "000000FF",
            modules = {
                health = {
                    enabled = true,
                    color = "class",
                    texture = "smooth",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "CENTER",
                        relativeTo = "frmdPetFrame",
                        relativePoint = "CENTER",
                        offsetX = 3,
                        offsetY = 0,
                        size = 11,
                        color = "FFFFFF",
                        format = "[name:short]",
                    },
                },
            },
        },
        party = {
            enabled = true,
            hideBlizzard = true,

            frameName = "frmdPartyContainer",
            anchor = "TOPRIGHT",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offsetX = -350,
            offsetY = 150,
            containerBackgroundColor = "00000000",
            containerBorderWidth = 0,
            containerBorderColor = "00000000",

            maxUnits = 5,
            perRow = 1,
            spacingX = 0,
            spacingY = -1,
            growthX = "RIGHT",
            growthY = "DOWN",

            unitWidth = 150,
            unitHeight = 60,
            unitBackgroundColor = "00000088",
            unitBorderWidth = 2,
            unitBorderColor = "000000FF",
            highlightSelected = true,

            modules = {
                health = {
                    enabled = true,
                    color = "class",
                    texture = "smooth",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "TOPLEFT",
                        relativePoint = "TOPLEFT",
                        offsetX = 14,
                        offsetY = -6,
                        size = 11,
                        color = "FFFFFF",
                        format = "[name:short]",
                    },
                    {
                        enabled = true,
                        anchor = "TOPRIGHT",
                        relativePoint = "TOPRIGHT",
                        offsetX = 0,
                        offsetY = -6,
                        size = 11,
                        color = "FFFFFF",
                        format = "[spec]",
                    },
                },
                power = {
                    enabled = true,
                    anchor = "BOTTOM",
                    relativePoint = "BOTTOM",
                    texture = "minimalist",
                    height = 12,
                    adjustHealthbarHeight = true,
                    onlyHealer = true,
                    offsetX = 0,
                    offsetY = 0,
                    borderWidth = 1,
                    borderColor = "000000FF",
                },
                roleIcon = {
                    enabled = true,
                    size = 12,
                    desaturate = true,
                    color = "FFFFFF",
                    anchor = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    offsetX = 1,
                    offsetY = -5,
                    defaultIcon = "common-button-square-gray-up",
                    defaultAlpha = 0.5,
                },
                dispelHighlight = {
                    enabled = true,
                    borderWidth = 4,
                },
                trinket = {
                    enabled = true,
                    frameBorderWidth = 2,
                    iconSize = 36,
                    iconBorderWidth = 1,
                    iconBorderColor = "000000FF",
                    anchor = "TOPRIGHT",
                    relativePoint = "TOPLEFT",
                    offsetX = -6,
                    offsetY = 0,
                    showSwipe = true,
                    showCooldownNumbers = true,
                    cooldownDesaturate = true,
                    cooldownAlpha = 0.5,
                },
                castbar = {
                    enabled = true,
                    anchor = "BOTTOMLEFT",
                    relativePoint = "BOTTOMRIGHT",
                    width = 124,
                    height = 18,
                    offsetX = 23,
                    offsetY = 2,
                    texture = "smooth",
                    showSpellName = true,
                    textSize = 9,
                    textPadding = 2,
                    textAlignment = "LEFT",
                    showIcon = false,
                    showCastTime = false,
                    backgroundColor = "00000088",
                    borderWidth = 1,
                    borderColor = "000000FF",
                },
                arenaTargets = {
                    enabled = true,
                    anchor = "TOPLEFT",
                    relativePoint = "TOPRIGHT",
                    offsetX = 2,
                    offsetY = 0,
                    mode = "enemy",
                    indicatorWidth = 10,
                    indicatorHeight = 16,
                    spacing = 4,
                    growDirection = "DOWN",
                    maxIndicators = 3,
                    borderWidth = 1,
                    borderColor = "000000FF",
                    containerBackgroundColor = "00000000",
                },
                auraFilters = {
                    {
                        name = "PartyPlayerBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"RAID_IN_COMBAT"},
                        excludeSubFilters = {"NOT_CANCELABLE"},
                        disableMouse = true,
                        relativeToModule = "Health",
                        anchor = "BOTTOMRIGHT",
                        relativePoint = "BOTTOMRIGHT",
                        offsetX = 0,
                        offsetY = 2,
                        iconSize = 20,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 6,
                        perRow = 6,
                        growthX = "LEFT",
                        growthY = "UP",
                        showSwipe = true,
                        showCooldownNumbers = false,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "PartyDebuffs",
                        enabled = true,
                        baseFilter = "HARMFUL",
                        disableMouse = true,
                        anchor = "BOTTOMRIGHT",
                        relativePoint = "BOTTOMLEFT",
                        offsetX = -4,
                        offsetY = 0,
                        iconSize = 18,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 6,
                        perRow = 6,
                        growthX = "LEFT",
                        growthY = "UP",
                        showSwipe = true,
                        showCooldownNumbers = false,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "PartyCrowdControl",
                        enabled = true,
                        baseFilter = "HARMFUL",
                        subFilters = {"CROWD_CONTROL"},
                        disableMouse = true,
                        relativeToModule = "ArenaTargets",
                        anchor = "TOPLEFT",
                        relativePoint = "TOPRIGHT",
                        offsetX = 2,
                        offsetY = 0,
                        iconSize = 36,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 1,
                        perRow = 1,
                        growthX = "RIGHT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                        showGlow = true,
                        glowColor = "FF0000",
                        placeholderIcon = "spell_shaman_hex",
                        placeholderDesaturate = true,
                        placeholderColor = "FFFFFF88"
                    },
                    {
                        name = "PartyDefensives",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"BIG_DEFENSIVE", "EXTERNAL_DEFENSIVE"},
                        disableMouse = true,
                        relativeToModule = {"PartyCrowdControl", "ArenaTargets"},
                        anchor = "TOPLEFT",
                        relativePoint = "TOPRIGHT",
                        offsetX = 2,
                        offsetY = 0,
                        iconSize = 36,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 1,
                        perRow = 1,
                        growthX = "RIGHT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                        showGlow = true,
                        glowColor = "00ff98",
                        placeholderIcon = "inv_shield_04",
                        placeholderDesaturate = true,
                        placeholderColor = "FFFFFF88"
                    },
                    {
                        name = "PartyImportantBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"IMPORTANT"},
                        disableMouse = true,
                        relativeToModule = {"PartyDefensives", "PartyCrowdControl", "ArenaTargets"},
                        anchor = "TOPLEFT",
                        relativePoint = "TOPRIGHT",
                        offsetX = 2,
                        offsetY = 0,
                        iconSize = 36,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 1,
                        perRow = 1,
                        growthX = "RIGHT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMLEFT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                        showGlow = true,
                        glowColor = "11aaee",
                        placeholderIcon = "spell_holy_avenginewrath",
                        placeholderDesaturate = true,
                        placeholderColor = "FFFFFF88"
                    },
                },

            },
        },
        arena = {
            enabled = true,
            hideBlizzard = true,

            frameName = "frmdArenaContainer",
            anchor = "TOPLEFT",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offsetX = 350,
            offsetY = 150,
            containerBackgroundColor = "00000000",
            containerBorderWidth = 0,
            containerBorderColor = "00000000",

            maxUnits = 3,
            perRow = 1,
            spacingX = 0,
            spacingY = -1,
            growthX = "LEFT",
            growthY = "DOWN",

            unitWidth = 150,
            unitHeight = 60,
            unitBackgroundColor = "00000088",
            unitBorderWidth = 2,
            unitBorderColor = "000000FF",
            highlightSelected = true,

            modules = {
                health = {
                    enabled = true,
                    color = "class",
                    texture = "smooth",
                },
                text = {
                    {
                        enabled = true,
                        anchor = "TOPLEFT",
                        relativePoint = "TOPLEFT",
                        offsetX = 14,
                        offsetY = -6,
                        size = 11,
                        color = "FFFFFF",
                        format = "[name:short]",
                    },
                    {
                        enabled = true,
                        anchor = "TOPRIGHT",
                        relativePoint = "TOPRIGHT",
                        offsetX = 0,
                        offsetY = -6,
                        size = 11,
                        color = "FFFFFF",
                        format = "[spec]",
                    },
                },
                power = {
                    enabled = true,
                    anchor = "BOTTOM",
                    relativePoint = "BOTTOM",
                    texture = "minimalist",
                    height = 12,
                    adjustHealthbarHeight = true,
                    onlyHealer = true,
                    offsetX = 0,
                    offsetY = 0,
                    borderWidth = 1,
                    borderColor = "000000FF",
                },
                roleIcon = {
                    enabled = true,
                    size = 12,
                    desaturate = true,
                    color = "FFFFFF",
                    anchor = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    offsetX = 1,
                    offsetY = -5,
                    defaultIcon = "common-button-square-gray-up",
                    defaultAlpha = 0.5,
                },
                dispelHighlight = {
                    enabled = true,
                    borderWidth = 4,
                },
                trinket = {
                    enabled = true,
                    frameBorderWidth = 2,
                    iconSize = 36,
                    iconBorderWidth = 1,
                    iconBorderColor = "000000FF",
                    anchor = "TOPLEFT",
                    relativePoint = "TOPRIGHT",
                    offsetX = 6,
                    offsetY = 0,
                    showSwipe = true,
                    showCooldownNumbers = true,
                    cooldownDesaturate = true,
                    cooldownAlpha = 0.5,
                },
                castbar = {
                    enabled = true,
                    anchor = "BOTTOMRIGHT",
                    relativePoint = "BOTTOMLEFT",
                    width = 124,
                    height = 18,
                    offsetX = -23,
                    offsetY = 2,
                    texture = "smooth",
                    showSpellName = true,
                    textSize = 9,
                    textPadding = 2,
                    textAlignment = "LEFT",
                    showIcon = false,
                    showCastTime = false,
                    backgroundColor = "00000088",
                    borderWidth = 1,
                    borderColor = "000000FF",
                },
                arenaTargets = {
                    enabled = true,
                    anchor = "TOPRIGHT",
                    relativePoint = "TOPLEFT",
                    offsetX = -2,
                    offsetY = 0,
                    mode = "friendly",
                    indicatorWidth = 10,
                    indicatorHeight = 16,
                    spacing = 4,
                    growDirection = "DOWN",
                    maxIndicators = 3,
                    borderWidth = 1,
                    borderColor = "000000FF",
                    containerBackgroundColor = "00000000",
                },
                auraFilters = {
                    {
                        name = "ArenaPlayerBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"RAID_IN_COMBAT"},
                        excludeSubFilters = {"NOT_CANCELABLE"},
                        disableMouse = true,
                        relativeToModule = "Health",
                        anchor = "BOTTOMLEFT",
                        relativePoint = "BOTTOMLEFT",
                        offsetX = 0,
                        offsetY = 2,
                        iconSize = 20,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 6,
                        perRow = 6,
                        growthX = "RIGHT",
                        growthY = "UP",
                        showSwipe = true,
                        showCooldownNumbers = false,
                        tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "ArenaDebuffs",
                        enabled = true,
                        baseFilter = "HARMFUL",
                        disableMouse = true,
                        anchor = "BOTTOMLEFT",
                        relativePoint = "BOTTOMRIGHT",
                        offsetX = 4,
                        offsetY = 0,
                        iconSize = 18,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 6,
                        perRow = 6,
                        growthX = "RIGHT",
                        growthY = "UP",
                        showSwipe = true,
                        showCooldownNumbers = false,
                        tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                    },
                    {
                        name = "ArenaCrowdControl",
                        enabled = true,
                        baseFilter = "HARMFUL",
                        subFilters = {"CROWD_CONTROL"},
                        disableMouse = true,
                        relativeToModule = {"ArenaTargets"},
                        anchor = "TOPRIGHT",
                        relativePoint = "TOPLEFT",
                        offsetX = -2,
                        offsetY = 0,
                        iconSize = 36,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 1,
                        perRow = 1,
                        growthX = "LEFT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                        showGlow = true,
                        glowColor = "FF0000",
                        placeholderIcon = "spell_shaman_hex",
                        placeholderDesaturate = true,
                        placeholderColor = "FFFFFF88"
                    },
                    {
                        name = "ArenaDefensives",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"BIG_DEFENSIVE", "EXTERNAL_DEFENSIVE"},
                        disableMouse = true,
                        relativeToModule = {"ArenaCrowdControl", "ArenaTargets"},
                        anchor = "TOPRIGHT",
                        relativePoint = "TOPLEFT",
                        offsetX = -2,
                        offsetY = 0,
                        iconSize = 36,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 1,
                        perRow = 1,
                        growthX = "LEFT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                        showGlow = true,
                        glowColor = "00ff98",
                        placeholderIcon = "inv_shield_04",
                        placeholderDesaturate = true,
                        placeholderColor = "FFFFFF88"
                    },
                    {
                        name = "ArenaImportantBuffs",
                        enabled = true,
                        baseFilter = "HELPFUL",
                        subFilters = {"IMPORTANT"},
                        disableMouse = true,
                        relativeToModule = {"ArenaDefensives", "ArenaCrowdControl", "ArenaTargets"},
                        anchor = "TOPRIGHT",
                        relativePoint = "TOPLEFT",
                        offsetX = -2,
                        offsetY = 0,
                        iconSize = 36,
                        spacingX = 2,
                        spacingY = 0,
                        maxIcons = 1,
                        perRow = 1,
                        growthX = "LEFT",
                        growthY = "DOWN",
                        showSwipe = true,
                        showCooldownNumbers = true,
                        tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
                        containerBackgroundColor = "00000000",
                        containerBorderWidth = 0,
                        containerBorderColor = "00000000",
                        iconBorderWidth = 1,
                        iconBorderColor = "000000FF",
                        showGlow = true,
                        glowColor = "11aaee",
                        placeholderIcon = "spell_holy_avenginewrath",
                        placeholderDesaturate = true,
                        placeholderColor = "FFFFFF88"
                    },
                },
                drTracker = {
                    enabled = true,
                    relativeToModule = {"ArenaImportantBuffs", "ArenaDefensives", "ArenaCrowdControl", "ArenaTargets"},
                    anchor = "TOPRIGHT",
                    relativePoint = "TOPLEFT",
                    offsetX = -4,
                    offsetY = 0,
                    iconSize = 36,
                    iconBorderWidth = 1,
                    iconBorderColor = "000000FF",
                    spacingX = 2,
                    spacingY = 2,
                    maxIcons = 4,
                    perRow = 4,
                    growthX = "LEFT",
                    growthY = "DOWN",
                    showSwipe = true,
                    showCooldownNumbers = true,
                    containerBackgroundColor = "00000000",
                    containerBorderWidth = 0,
                    containerBorderColor = "00000000",
                },
            },
        },
        auraFilterDebug = {
            enabled = false,
            friendlyUnits = { "player" },
            hostileUnits = { "target" },
        },
    }
end

local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local moduleToggleMap = {
    player                = "playerEnabled",
    target                = "targetEnabled",
    targetTarget          = "targetTargetEnabled",
    focus                 = "focusEnabled",
    focusTarget           = "focusTargetEnabled",
    pet                   = "petEnabled",
    party                 = "partyEnabled",
    arena                 = "arenaEnabled",
}

local styleAppliesTo = { "player", "target", "targetTarget", "focus", "focusTarget", "pet" }
local largeFrameKeys = { "player", "target" }
local smallFrameKeys = { "targetTarget", "focus", "focusTarget", "pet" }

local function applySavedFramePositions(cfg, savedVars)
    local positions = savedVars and savedVars.data and savedVars.data.framePositions
    if not positions then return end

    for configKey, pos in pairs(positions) do
        if cfg[configKey] then
            cfg[configKey].offsetX = pos.offsetX
            cfg[configKey].offsetY = pos.offsetY
        end
    end
end

function addon:GetCustomConfig()
    local customConfig = self.savedVars and self.savedVars.data and self.savedVars.data.customConfig
    if customConfig then
        local cfg = deepCopy(customConfig)
        applySavedFramePositions(cfg, self.savedVars)
        return cfg
    end
    return nil
end

function addon:GetConfig()
    local cfg = deepCopy(self:GetDefaultConfig())

    for configKey, settingName in pairs(moduleToggleMap) do
        local val = self:GetValue("modules", settingName)
        if val ~= nil then
            cfg[configKey].enabled = val
            cfg[configKey].hideBlizzard = val
        end
    end

    local font         = self:GetValue("style", "font")
    local healthTex    = self:GetValue("style", "healthTexture")
    local powerTex     = self:GetValue("style", "powerTexture")
    local castbarTex   = self:GetValue("style", "castbarTexture")
    local absorbTex    = self:GetValue("style", "absorbTexture")
    local largeLeft    = self:GetValue("style", "largeFrameLeftText")
    local largeRight   = self:GetValue("style", "largeFrameRightText")
    local smallText    = self:GetValue("style", "smallFrameText")
    local partyLeft    = self:GetValue("style", "partyFrameLeftText")
    local partyRight   = self:GetValue("style", "partyFrameRightText")
    local arenaLeft    = self:GetValue("style", "arenaFrameLeftText")
    local arenaRight   = self:GetValue("style", "arenaFrameRightText")

    if font then
        cfg.global.font = font
    end

    for _, key in ipairs(styleAppliesTo) do
        local modules = cfg[key] and cfg[key].modules
        if modules then
            if modules.health and healthTex then
                modules.health.texture = healthTex
            end
            if modules.power and powerTex then
                modules.power.texture = powerTex
            end
            if modules.castbar and castbarTex then
                modules.castbar.texture = castbarTex
            end
            if modules.absorbs and absorbTex then
                modules.absorbs.texture = absorbTex
            end
        end
    end

    for _, key in ipairs(largeFrameKeys) do
        local textCfg = cfg[key] and cfg[key].modules and cfg[key].modules.text
        if textCfg then
            if textCfg[1] and largeLeft then
                textCfg[1].format = largeLeft
            end
            if textCfg[2] and largeRight then
                textCfg[2].format = largeRight
            end
        end
    end

    for _, key in ipairs(smallFrameKeys) do
        local textCfg = cfg[key] and cfg[key].modules and cfg[key].modules.text
        if textCfg and textCfg[1] and smallText then
            textCfg[1].format = smallText
        end
    end

    local partyTextCfg = cfg.party and cfg.party.modules and cfg.party.modules.text
    if partyTextCfg then
        if partyTextCfg[1] and partyLeft then
            partyTextCfg[1].format = partyLeft
        end
        if partyTextCfg[2] and partyRight then
            partyTextCfg[2].format = partyRight
        end
    end

    local arenaTextCfg = cfg.arena and cfg.arena.modules and cfg.arena.modules.text
    if arenaTextCfg then
        if arenaTextCfg[1] and arenaLeft then
            arenaTextCfg[1].format = arenaLeft
        end
        if arenaTextCfg[2] and arenaRight then
            arenaTextCfg[2].format = arenaRight
        end
    end

    local moduleOverrides = {
        { panelKey = "party", configKey = "party", module = "trinket",      enableSetting = "partyTrinketEnabled" },
        { panelKey = "party", configKey = "party", module = "arenaTargets", enableSetting = "partyArenaTargetsEnabled" },
        { panelKey = "party", configKey = "party", module = "castbar",      enableSetting = "partyCastbarEnabled" },
        { panelKey = "arena", configKey = "arena", module = "trinket",      enableSetting = "arenaTrinketEnabled" },
        { panelKey = "arena", configKey = "arena", module = "arenaTargets", enableSetting = "arenaArenaTargetsEnabled" },
        { panelKey = "arena", configKey = "arena", module = "castbar",      enableSetting = "arenaCastbarEnabled" },
        { panelKey = "arena", configKey = "arena", module = "drTracker",    enableSetting = "arenaDRTrackerEnabled" },
    }

    for _, mo in ipairs(moduleOverrides) do
        local val = self:GetValue(mo.panelKey, mo.enableSetting)
        if val ~= nil then
            local mod = cfg[mo.configKey] and cfg[mo.configKey].modules and cfg[mo.configKey].modules[mo.module]
            if mod then
                mod.enabled = val
            end
        end
    end

    local filterOverrides = {
        { panelKey = "party",  filterName = "PartyCrowdControl",    enableSetting = "partyCrowdControlEnabled",    glowSetting = "partyCrowdControlGlow",       colorSetting = "partyCrowdControlGlowColor" },
        { panelKey = "party",  filterName = "PartyDefensives",      enableSetting = "partyDefensivesEnabled",      glowSetting = "partyDefensivesGlow",         colorSetting = "partyDefensivesGlowColor" },
        { panelKey = "party",  filterName = "PartyImportantBuffs",  enableSetting = "partyImportantBuffsEnabled",  glowSetting = "partyImportantBuffsGlow",     colorSetting = "partyImportantBuffsGlowColor" },
        { panelKey = "arena",  filterName = "ArenaCrowdControl",    enableSetting = "arenaCrowdControlEnabled",    glowSetting = "arenaCrowdControlGlow",       colorSetting = "arenaCrowdControlGlowColor" },
        { panelKey = "arena",  filterName = "ArenaDefensives",      enableSetting = "arenaDefensivesEnabled",      glowSetting = "arenaDefensivesGlow",         colorSetting = "arenaDefensivesGlowColor" },
        { panelKey = "arena",  filterName = "ArenaImportantBuffs",  enableSetting = "arenaImportantBuffsEnabled",  glowSetting = "arenaImportantBuffsGlow",     colorSetting = "arenaImportantBuffsGlowColor" },
    }

    for _, override in ipairs(filterOverrides) do
        local configKey = override.panelKey
        local filters = cfg[configKey] and cfg[configKey].modules and cfg[configKey].modules.auraFilters
        if filters then
            for _, filterCfg in ipairs(filters) do
                if filterCfg.name == override.filterName then
                    local enableVal = self:GetValue(override.panelKey, override.enableSetting)
                    if enableVal ~= nil then
                        filterCfg.enabled = enableVal
                    end
                    local glowVal = self:GetValue(override.panelKey, override.glowSetting)
                    if glowVal ~= nil then
                        filterCfg.showGlow = glowVal
                    end
                    local colorVal = self:GetValue(override.panelKey, override.colorSetting)
                    if colorVal then
                        filterCfg.glowColor = colorVal:gsub("^#", "")
                    end
                    break
                end
            end
        end
    end

    applySavedFramePositions(cfg, self.savedVars)

    return cfg
end

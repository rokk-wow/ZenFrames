local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:GetDefaultConfig_Global()
    return {
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

        borderWidth = 2,
        borderColor = "000000FF",
        outOfRangeOpacity = 0.25,
        font = "DorisPP",
        healthTexture = "smooth",
        powerTexture = "minimalist",
        absorbTexture = "Diagonal",
        castbarTexture = "smooth",

        dispelColors = {
            Magic   = "ff00ffFF",
            Curse   = "990099ff",
            Disease = "bbcc00FF",
            Poison  = "00cc00FF",
            Bleed   = "CC0000FF",
            Enrage  = "FF3300FF",
            default = "FFFFFFFF",
        },

        dispelTextures = {
            Magic   = "icons_64x64_magic",
            Curse   = "icons_64x64_curse",
            Disease = "icons_64x64_disease",
            Poison  = "icons_64x64_poison",
            Bleed   = "icons_64x64_bleed",
            Enrage  = "icons_64x64_enrage",
            default = "icons_64x64_deadly",
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

        objectiveIcons = {
            allianceFlag = "AllianceEmblem",
            hordeFlag = "HordeEmblem",
            orb = "worldquest-Capstone-questmarker-epic-supertrack",
            gemColor = "db0000",
            orbBlueColor = "0068f5",
            orbGreenColor = "20d04c",
            orbOrangeColor = "f0a400",
            orbPurpleColor = "dd0af0",
        },

        bgTeamSizes = {
            ["Warsong Gulch"] = 10,
            ["Arathi Basin"] = 15,
            ["Deephaul Ravine"] = 10,
            ["Alterac Valley"] = 40,
            ["Eye of the Storm"] = 15,
            ["Isle of Conquest"] = 40,
            ["The Battle for Gilneas"] = 10,
            ["Battle for Wintergrasp"] = 40,
            ["Ashran"] = 35,
            ["Twin Peaks"] = 10,
            ["Temple of Kotmogu"] = 10,
            ["Seething Shore"] = 10,
            ["Deepwind Gorge"] = 15,
            ["Slayer's Rise"] = 40,
        },
    }
end

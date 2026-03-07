local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

function addon:GetDefaultConfig()
    local units = self:GetDefaultConfig_Units()

    local config = {
        global = self:GetDefaultConfig_Global(),

        player = units.player,
        target = units.target,
        targetTarget = units.targetTarget,
        focus = units.focus,
        focusTarget = units.focusTarget,
        pet = units.pet,

        party = self:GetDefaultConfig_Party(),
        arena = self:GetDefaultConfig_Arena(),
        boss = self:GetDefaultConfig_Boss(),

        raid = {
            enabled = false,

            routing = {
                usePartyWhenGroupSizeAtOrBelow = 5,

                raid = {
                    minRaidSize = 6,
                    profile = "raid",
                },

                pvp = {
                    blitz = {
                        minRaidSize = 6,
                        -- maxRaidSize = 8,
                        profile = "blitz",
                    },
                    battleground = {
                        minRaidSize =99,
                        -- minRaidSize = 9,
                        -- maxRaidSize = 25,
                        profile = "battleground",
                    },
                    epicBattleground = {
                        minRaidSize =99,
                        -- minRaidSize = 26,
                        profile = "epicBattleground",
                    },
                },
            },

            profiles = {
                raid = self:GetDefaultConfig_Raid(),
                blitz = self:GetDefaultConfig_Blitz(),
                battleground = self:GetDefaultConfig_Battleground(),
                epicBattleground = self:GetDefaultConfig_EpicBattleground(),
            },
        },

        auraFilterDebug = {
            enabled = false,
            friendlyUnits = { "player" },
            hostileUnits = { "target" },
        },

        extras = self:GetDefaultConfig_Extras(),
    }

    return config
end
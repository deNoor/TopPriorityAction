local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Common
---@field Spells table<string, Spell>
---@field Items table<string, Item>
---@field PlayerActions table<string, PlayerAction>
---@field Commands table<string, Cmd>

---@type Common
local Common = {
    Spells = {
        Gcd = {
            Id = 61304,
        },
        AutoAttack = {
            Id = 6603,
        },
        AutoShot = {
            Id = 75,
        },
        GrievousWound = {
            Id = 240559,
            Debuff = 240559,
        },
        GashFrenzy = {
            Id = 378020,
            Debuff = 378020,
        },
        NecroticPitch = {
            Id = 153692,
            Debuff = 153692,
        },
    },
    Items = {
        Healthstone = {
            Id = 5512,
        },
    },
    PlayerActions = {
        EnterKey = {
            Key = "Enter",
            Icon = 0,
            Id = 0,
            Name = "Enter"
        },
        JumpKey = {
            Key = "Space",
            Icon = 0,
            Id = 0,
            Name = "Space"
        },
    },
    Commands = {
        CustomKey = {
            Name = "CustomKey",
        },
    },
}

-- attach to addon
addon.Common = Common
